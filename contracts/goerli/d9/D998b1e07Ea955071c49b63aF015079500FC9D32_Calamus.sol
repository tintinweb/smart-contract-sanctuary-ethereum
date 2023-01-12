// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IPlatformFee.sol";
import "./ICalamus.sol";
import "./Types.sol";
import "./CarefulMath.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";

contract Calamus is Initializable, OwnableUpgradeable, ICalamus, IPlatformFee, ReentrancyGuardUpgradeable, CarefulMath, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;
    uint256 public nextStreamId;
    uint32 constant private DENOMINATOR = 10000;

    mapping (address => uint256) public ownerToStreams;
    mapping (address => uint256) public recipientToStreams;
    mapping (uint256 => Types.Stream) public streams;
    mapping (address => uint256) private contractFees;
    mapping (address => uint32) private withdrawFeeAddresses;
    address[] private withdrawAddresses;

    EnumerableMapUpgradeable.AddressToUintMap addressFees;
    uint32 public rateFee;

    mapping (address => address[]) private availableTokens;
    mapping (address => mapping (address => uint256)) private userTokenBalance;
    mapping (address => mapping (address => uint256)) private lockedUserTokenBalance;

    address private systemAddress;

    function initialize(uint32 initialFee) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        rateFee = initialFee;
        nextStreamId = 1;
    }

    modifier isAllowAddress(address allowAddress) {
        require(allowAddress != address(0x00), "Address 0");
        require(allowAddress != address(this), "address(this)");
        _;
    }

    modifier streamExists(uint256 streamId) {
        require(streams[streamId].streamId >= 0, "stream does not exist");
        _;
    }



    function setRateFee(uint32 newRateFee) public override onlyOwner {
        rateFee = newRateFee;
        emit SetRateFee(newRateFee);
    }

    function deltaOf(uint256 streamId) public view streamExists(streamId) returns (uint256 delta) {
        Types.Stream memory stream = streams[streamId];
        if (block.timestamp <= stream.startTime) return 0;
        if (block.timestamp < stream.stopTime) return block.timestamp - stream.startTime;
        return stream.stopTime - stream.startTime;
    }

    struct FeeVars {
        bool exists;
        uint256 value;
    }

    function feeOf(address userAddress, address tokenAddress) external view returns (uint256 fee) {
        return _feeOf(userAddress, tokenAddress);
    }

    function _feeOf(address userAddress, address tokenAddress) private view returns (uint256 fee) {
        FeeVars memory vars;
        (vars.exists, vars.value) = addressFees.tryGet(userAddress);
        if (vars.exists) {
            return vars.value;
        }
        (vars.exists, vars.value) = addressFees.tryGet(tokenAddress);
        if (vars.exists) {
            return vars.value;
        }
        return uint256(rateFee);
    }

    struct BalanceOfLocalVars {
        MathError mathErr;
        uint256 recipientBalance;
        uint256 releaseTimes;
        uint256 withdrawalAmount;
        uint256 senderBalance;
    }

    function balanceOf(uint256 streamId, address who) public override view streamExists(streamId) returns (uint256 balance) {
        Types.Stream memory stream = streams[streamId];
        BalanceOfLocalVars memory vars;

        uint256 delta = deltaOf(streamId);
        (vars.mathErr, vars.releaseTimes) = divUInt(delta, stream.releaseFrequency);
        uint256 duration = stream.stopTime - stream.startTime;

        if (delta == duration) {
            vars.recipientBalance = stream.releaseAmount;
        } else if (vars.releaseTimes > 0 && vars.mathErr == MathError.NO_ERROR) {
            (vars.mathErr, vars.recipientBalance) = mulUInt(stream.releaseFrequency * vars.releaseTimes, stream.releaseAmount);
            if (vars.mathErr == MathError.NO_ERROR) {
                vars.recipientBalance /= duration;
            } else {
                (vars.mathErr, vars.recipientBalance) = mulUInt(stream.releaseFrequency * vars.releaseTimes, stream.releaseAmount / duration);
            }
        }

        if (stream.vestingAmount > 0 && delta > 0) {
            vars.recipientBalance += stream.vestingAmount;
        }

        require(vars.mathErr == MathError.NO_ERROR, "recipient balance calculation error");

        /*
         * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
         * We have to subtract the total amount withdrawn from the amount of money that has been
         * streamed until now.
         */
        uint256 totalRelease = stream.releaseAmount + stream.vestingAmount;
        if (totalRelease > stream.remainingBalance) {
            (vars.mathErr, vars.withdrawalAmount) = subUInt(totalRelease, stream.remainingBalance);
            assert(vars.mathErr == MathError.NO_ERROR);
            (vars.mathErr, vars.recipientBalance) = subUInt(vars.recipientBalance, vars.withdrawalAmount);
            /* `withdrawalAmount` cannot and should not be bigger than `recipientBalance`. */
            assert(vars.mathErr == MathError.NO_ERROR);
        }

        if (who == stream.recipient) return vars.recipientBalance;
        if (who == stream.sender) {
            (vars.mathErr, vars.senderBalance) = subUInt(stream.remainingBalance, vars.recipientBalance);
            /* `recipientBalance` cannot and should not be bigger than `remainingBalance`. */
            assert(vars.mathErr == MathError.NO_ERROR);
            return vars.senderBalance;
        }
        return 0;
    }

    struct CreateStreamLocalVars {
        MathError mathErr;
        uint256 duration;
        uint256 vestingAmount;
    }

    function _validateGeneralInfo(Types.StreamGeneral memory generalInfo,  uint256 blockTimestamp, CreateStreamLocalVars memory vars) internal pure {
        require(generalInfo.startTime >= blockTimestamp, "start time before block.timestamp");
        require(generalInfo.stopTime > generalInfo.startTime, "stop time before the start time");

        require(generalInfo.vestingRelease <= DENOMINATOR, "vesting release is too much");
        require(generalInfo.releaseFrequency > 0, "release frequency is zero");
        (vars.mathErr, vars.duration) = subUInt(generalInfo.stopTime, generalInfo.startTime);
        /* `subUInt` can only return MathError.INTEGER_UNDERFLOW but we know `stopTime` is higher than `startTime`. */
        if (vars.mathErr != MathError.NO_ERROR) {
            revert("Math Error!");
        }
        require(vars.duration >= generalInfo.releaseFrequency, "Duration is smaller than frequency");
    }

    function _validateRecipient(
        Types.Recipient memory recipient,
        address addressZero,
        address addressThis,
        address sender
    ) internal pure {
        require(recipient.recipient != addressZero, "Address 0");
        require(recipient.recipient != addressThis, "address(this)");
        require(recipient.recipient != sender, "is sender");
        require(recipient.releaseAmount > 0, "releaseAmount=0");
    }

    function _validateAllStreams(
        Types.StreamGeneral memory generalInfo,
        Types.Recipient[] memory recipients,
        address correctTokenAddress,
        CreateStreamLocalVars memory vars
    ) internal view {
        require(recipients.length > 0, "!Stream.length");
        Types.Recipient memory recipient;
        uint256 blockTimestamp = block.timestamp;
        address addressZero = address(0);
        address addressThis = address(this);
        address sender = msg.sender;
        uint256 totalAmount = 0;
        _validateGeneralInfo(
            generalInfo,
            blockTimestamp,
            vars
        );
        for (uint i=0; i < recipients.length; i++) {
            recipient= recipients[i];
            _validateRecipient(
                recipient,
                addressZero,
                addressThis,
                sender
            );
            totalAmount += recipient.releaseAmount;
        }

        uint256 totalReleaseAmountIncludeFee = _getAmountIncludedFee(
            sender,
            generalInfo.tokenAddress,
            totalAmount
        );

        require(
            (userTokenBalance[msg.sender][correctTokenAddress] - lockedUserTokenBalance[msg.sender][correctTokenAddress]) >= totalReleaseAmountIncludeFee,
            "balance-lockedAmount<totalReleaseAmountIncludeFee"
        );
    }


    function _createBatchStreams(Types.StreamGeneral memory generalInfo, Types.Recipient[] memory recipients) internal {
        CreateStreamLocalVars memory vars;

        address correctTokenAddress = (generalInfo.tokenAddress == address(this)) ? address(0) : generalInfo.tokenAddress;

        _validateAllStreams(generalInfo, recipients, correctTokenAddress, vars);

        Types.RecipientResponse[] memory recipientsResponse = new Types.RecipientResponse[](recipients.length);

        Types.Stream memory stream;

        Types.Recipient memory recipient;

        address sender = msg.sender;

        uint totalReleaseAmount = 0;

        for (uint i=0; i < recipients.length; i++) {
            recipient = recipients[i];
            totalReleaseAmount += recipient.releaseAmount;

            (vars.mathErr, vars.vestingAmount) = mulUInt(recipient.releaseAmount, generalInfo.vestingRelease);

            assert(vars.mathErr == MathError.NO_ERROR);

            vars.vestingAmount /= DENOMINATOR;

            stream = Types.Stream(
                nextStreamId + i,
                sender,
                recipient.releaseAmount - vars.vestingAmount,
                recipient.releaseAmount,
                generalInfo.startTime,
                generalInfo.stopTime,
                vars.vestingAmount,
                generalInfo.releaseFrequency,
                generalInfo.transferPrivilege,
                generalInfo.cancelPrivilege,
                recipient.recipient,
                correctTokenAddress,
                1
            );
            streams[nextStreamId + i] = stream;

            recipientsResponse[i] = Types.RecipientResponse(
                nextStreamId + i,
                recipient.recipient,
                stream.releaseAmount
            );
        }


        uint256 totalReleaseAmountIncludeFee = _getAmountIncludedFee(
            sender,
            generalInfo.tokenAddress,
            totalReleaseAmount
        );

        contractFees[correctTokenAddress] += totalReleaseAmountIncludeFee - totalReleaseAmount;

        lockedUserTokenBalance[sender][correctTokenAddress] += totalReleaseAmount;

        userTokenBalance[sender][correctTokenAddress] -= totalReleaseAmountIncludeFee - totalReleaseAmount;

        ownerToStreams[sender] += recipients.length;

        recipientToStreams[recipient.recipient] += recipients.length;

        /* Increment the next stream id. */
        nextStreamId += recipients.length;
        Types.StreamGeneralResponse memory generalInfoResponse = Types.StreamGeneralResponse(
            sender,
            correctTokenAddress,
            generalInfo.startTime,
            generalInfo.stopTime,
            generalInfo.vestingRelease,
            generalInfo.releaseFrequency,
            generalInfo.transferPrivilege,
            generalInfo.cancelPrivilege
        );
        emit BatchStreams(
            generalInfoResponse,
            recipientsResponse
        );
    }

    function _getAmountIncludedFee(address sender, address tokenAddress, uint256 amount) internal view returns (uint256) {
        uint256 fee = _feeOf(sender, tokenAddress);
        uint256 amountIncludedFee = (amount * (DENOMINATOR + fee) / DENOMINATOR);
        return amountIncludedFee;
    }

    function _transferFrom(address tokenAddress, uint256 releaseAmount) internal {
        IERC20Upgradeable(tokenAddress).transferFrom(msg.sender, address(this), releaseAmount);
    }

    function _transfer(address tokenAddress, address to, uint256 amount) internal {
        IERC20Upgradeable(tokenAddress).transfer(to, amount);
    }

    function getOwnerToStreams(address owner) public view returns (Types.Stream[] memory) {
        uint256 streamCount = 0;
        Types.Stream[] memory filterStreams = new Types.Stream[](ownerToStreams[owner]);

        for (uint i=1; i < nextStreamId; i++) {
            if (streams[i].sender == owner) {
                filterStreams[streamCount] = streams[i];
                streamCount++;
            }
        }
        return filterStreams;
    }

    function getRecipientToStreams(address recipient) public view returns (Types.Stream[] memory) {
        uint256 streamCount = 0;
        Types.Stream[] memory filterStreams = new Types.Stream[](recipientToStreams[recipient]);

        for (uint i=1; i < nextStreamId; i++) {
            if (streams[i].recipient == recipient) {
                filterStreams[streamCount] = streams[i];
                streamCount++;
            }
        }
        return filterStreams;
    }

    function withdrawFromStream(uint256 streamId, uint256 amount)
    public
    override
    whenNotPaused
    nonReentrant
    streamExists(streamId)
    {
        Types.Stream memory stream = streams[streamId];
        require(amount > 0, "amount=0");
        require(stream.status == 1, "!active");
        require(stream.recipient == msg.sender, "!recipient");
        uint256 balance = balanceOf(streamId, stream.recipient);
        require(balance >= amount, "balance<amount");

        streams[streamId].remainingBalance -= amount;

        if (streams[streamId].remainingBalance == 0) {
            streams[streamId].status = 3;
        }

        userTokenBalance[stream.sender][stream.tokenAddress] -= amount;
        lockedUserTokenBalance[stream.sender][stream.tokenAddress] -= amount;


        if (stream.tokenAddress != address(0x00)) {
            _transfer(stream.tokenAddress, stream.recipient, amount );
        } else {
            payable(stream.recipient).transfer(amount);
        }

        emit WithdrawFromStream(streamId, stream.recipient, amount);
    }

    function _checkCancelPermission(Types.Stream memory stream) internal view returns (bool) {
        address sender = msg.sender;
        address streamSender = stream.sender;
        address recipient = stream.recipient;
        if (stream.cancelPrivilege == 0) {
            return (sender == recipient);
        } else if (stream.cancelPrivilege == 1) {
            return (sender == streamSender);
        } else if (stream.cancelPrivilege == 2) {
            return true;
        } else if (stream.cancelPrivilege == 3) {
            return false;
        } else {
            return false;
        }
    }

    function _checkTransferPermission(Types.Stream memory stream) internal view returns (bool) {
        address sender = msg.sender;
        address streamSender = stream.sender;
        address recipient = stream.recipient;
        if (stream.transferPrivilege == 0) {
            return (sender == recipient);
        } else if (stream.transferPrivilege == 1) {
            return (sender == streamSender);
        } else if (stream.transferPrivilege == 2) {
            return true;
        } else if (stream.transferPrivilege == 3) {
            return false;
        } else {
            return false;
        }
    }

    function cancelStream(uint256 streamId)
    public
    override
    whenNotPaused
    nonReentrant
    streamExists(streamId)
    {
        Types.Stream memory stream = streams[streamId];
        require(stream.status == 1, "!active");
        require(_checkCancelPermission(stream), "!permission");
        uint256 senderBalance = balanceOf(streamId, stream.sender);
        uint256 recipientBalance = balanceOf(streamId, stream.recipient);

        streams[streamId].status = 2;

        IERC20Upgradeable token = IERC20Upgradeable(stream.tokenAddress);

        if (recipientBalance > 0) {
            streams[streamId].remainingBalance -= recipientBalance;
            userTokenBalance[stream.sender][stream.tokenAddress] -= recipientBalance;
            lockedUserTokenBalance[stream.sender][stream.tokenAddress] -= recipientBalance;

            if (stream.tokenAddress != address(0x00)) {

                token.transfer(stream.recipient, recipientBalance);

            } else {

                payable(stream.recipient).transfer(recipientBalance);

            }

        }

        emit CancelStream(streamId, stream.sender, stream.recipient, senderBalance, recipientBalance);
    }

    function _changeStreamRecipient(uint256 streamId, address newRecipient) internal {
        Types.Stream memory stream = streams[streamId];
        recipientToStreams[stream.recipient] -= 1;
        recipientToStreams[newRecipient] += 1;
        streams[streamId].recipient = newRecipient;
    }

    function transferStream(uint256 streamId, address newRecipient)
    public
    override
    whenNotPaused
    nonReentrant
    streamExists(streamId) {
        Types.Stream memory stream = streams[streamId];
        require(stream.status == 1, "!active");
        require(_checkTransferPermission(stream), "!permission");
        require(newRecipient != stream.recipient, "New=Old");
        require(newRecipient != address(0x00), "Address 0");
        require(newRecipient != address(this), "address(this)");
        require(newRecipient != msg.sender, "recipient=sender");
        uint256 recipientBalance = balanceOf(streamId, stream.recipient);

        _changeStreamRecipient(streamId, newRecipient);

        if (recipientBalance > 0) {
            streams[streamId].remainingBalance -= recipientBalance;
            userTokenBalance[stream.sender][stream.tokenAddress] -= recipientBalance;
            lockedUserTokenBalance[stream.sender][stream.tokenAddress] -= recipientBalance;

            if (stream.tokenAddress != address(0x00)) {

                _transfer(stream.tokenAddress, stream.recipient, recipientBalance );

            } else {

                payable(stream.recipient).transfer(recipientBalance);

            }
        }

        emit TransferStream(streamId, stream.sender, newRecipient, recipientBalance);
    }
    
    function topupStream(uint256 streamId, uint256 amount)
        public
        override
        whenNotPaused
        nonReentrant
        streamExists(streamId)
    {
        Types.Stream memory stream = streams[streamId];

        uint256 amountIncludeFee = _getAmountIncludedFee(
            msg.sender,
            stream.tokenAddress == address(0x00) ? address(this) : stream.tokenAddress,
            amount
        );

        require((userTokenBalance[msg.sender][stream.tokenAddress] - lockedUserTokenBalance[msg.sender][stream.tokenAddress]) >= amountIncludeFee, "balance-lockedAmount<amountIncludeFee" );

        require(stream.status == 1, "!active");
        require(stream.sender == msg.sender, "!permission");
        require(amount > 0, "Amount=0");
        require(block.timestamp < stream.stopTime, "Ended");

        streams[streamId].releaseAmount += amount;
        streams[streamId].remainingBalance += amount;
        streams[streamId].stopTime =
            stream.stopTime +
            (amount * (stream.stopTime - stream.startTime)) /
            stream.releaseAmount;

        contractFees[stream.tokenAddress] += amountIncludeFee - amount;
        userTokenBalance[msg.sender][stream.tokenAddress] -= amountIncludeFee - amount;
        lockedUserTokenBalance[msg.sender][stream.tokenAddress] += amount;

        emit TopupStream(streamId, amount, streams[streamId].stopTime);
    }

    function addWithdrawFeeAddress(address allowAddress, uint32 percentage) public override onlyOwner isAllowAddress(allowAddress) {
        require(percentage > 0, "Percentage=0");
        withdrawFeeAddresses[allowAddress] = percentage;
        withdrawAddresses.push(allowAddress);
        emit AddWithdrawFeeAddress(allowAddress, percentage);
    }

    function removeWithdrawFeeAddress(address allowAddress) public override onlyOwner returns(bool) {
        uint32 percentage = withdrawFeeAddresses[allowAddress];
        if (percentage > 0) {
            delete withdrawFeeAddresses[allowAddress];
            for (uint32 i = 0; i < withdrawAddresses.length; i++) {
                if (withdrawAddresses[i] == allowAddress) {
                    delete withdrawAddresses[i];
                    break;
                }
            }
            emit RemoveWithdrawFeeAddress(allowAddress);
            return true;
        }
        return false;
    }

    function getWithdrawFeeAddresses() public override view onlyOwner returns(Types.WithdrawFeeAddress[] memory) {

        Types.WithdrawFeeAddress[] memory addresses = new Types.WithdrawFeeAddress[](withdrawAddresses.length);

        for (uint32 i=0; i< withdrawAddresses.length; i++ ) {
            addresses[i] = Types.WithdrawFeeAddress(
                withdrawAddresses[i],
                withdrawFeeAddresses[withdrawAddresses[i]]
            );
        }
        return addresses;
    }

    function isAllowWithdrawingFee(address allowAddress) public override view onlyOwner returns (bool) {
        uint32 percentage = withdrawFeeAddresses[allowAddress];
        if (percentage > 0) {
            return true;
        }
        return false;
    }

    function getContractFee(address tokenAddress) public override view returns(uint256) {
        if (tokenAddress == address(this)) {
            return contractFees[address(0)];
        }
        return contractFees[tokenAddress];
    }

    function withdrawFee(address to, address tokenAddress, uint256 amount) public override whenNotPaused nonReentrant onlyOwner  returns(bool) {
        uint256 feeBalance = contractFees[(tokenAddress == address(this))? address(0x00) : tokenAddress];

        require(isAllowWithdrawingFee(to), "!allowing");
        require(to != address(this), "address(this)");
        require(feeBalance >= amount, "feeBalance < amount");

        uint256 allowAmount = (feeBalance * withdrawFeeAddresses[to] / 100);
        require(amount <= allowAmount, "amount > allowAmount");
        if (tokenAddress != address(this)) {

            _transfer(tokenAddress, to, amount );

        } else {
            payable(to).transfer(amount);
        }
        emit WithdrawFee(tokenAddress, to, amount);
        return true;
    }

    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }

    function addWhitelistAddress(address whitelistAddress, uint256 fee) public onlyOwner {
        addressFees.set(whitelistAddress, fee);
    }

    function removeWhitelistAddress(address whitelistAddress) public onlyOwner {
        addressFees.remove(whitelistAddress);
    }

    function deposit(address tokenAddress, uint256 amount) external payable whenNotPaused nonReentrant {
        require(amount > 0, "Amount<=0");
        require(tokenAddress != address(0x00), "Address 0");
        address correctTokenAddress = (tokenAddress == address(this)) ? address(0x00) : tokenAddress;
        userTokenBalance[msg.sender][correctTokenAddress] += amount;

        bool checkTokenExist = false;
        address[] memory tokens = availableTokens[msg.sender];
        for(uint i=0; i < tokens.length; i++) {
            if (tokens[i] == correctTokenAddress) {
                checkTokenExist = true;
            }
        }

        if (!checkTokenExist) {
            availableTokens[msg.sender].push(correctTokenAddress);
        }

        if (tokenAddress != address(this)) {
            _transferFrom(tokenAddress, amount);
        }

        emit Deposit(msg.sender, tokenAddress, amount);
    }

    function withdrawFromBalance(address tokenAddress, uint256 amount) external whenNotPaused nonReentrant {
        address correctTokenAddress = (tokenAddress == address(this)) ? address(0) : tokenAddress;
        require(userTokenBalance[msg.sender][correctTokenAddress] > 0, "balance=0");
        require(userTokenBalance[msg.sender][correctTokenAddress] - lockedUserTokenBalance[msg.sender][correctTokenAddress] >= amount, "Available balance < amount");
        userTokenBalance[msg.sender][correctTokenAddress] -= amount;
        if (tokenAddress != address(this)) {

            _transfer(correctTokenAddress, msg.sender, amount );

        } else {
            payable(msg.sender).transfer(amount);
        }

        emit WithdrawFromBalance(msg.sender, amount);

    }

    function batchStreams(Types.StreamGeneral memory generalInfo, Types.Recipient[] memory recipients) external whenNotPaused nonReentrant {
        _createBatchStreams(generalInfo, recipients);
    }

    function getUserTokenBalance(address tokenAddress) external view returns (uint256) {
        address correctTokenAddress = (tokenAddress == address(this)) ? address(0x00) : tokenAddress;
        uint256 balance = userTokenBalance[msg.sender][correctTokenAddress];
        return balance;
    }

    function getAllUserTokenBalance() external view returns (Types.TokenBalance[] memory) {
        address[] memory tokens = availableTokens[msg.sender];
        Types.TokenBalance[] memory tokenBalances = new Types.TokenBalance[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            tokenBalances[i] = Types.TokenBalance(
                tokens[i],
                userTokenBalance[msg.sender][tokens[i]]
            );
        }
        return tokenBalances;
    }

    function getUserLockedTokenBalance(address tokenAddress) external view returns (uint256) {
        address correctTokenAddress = (tokenAddress == address(this)) ? address(0x00) : tokenAddress;
        uint256 balance = lockedUserTokenBalance[msg.sender][correctTokenAddress];
        return balance;
    }

    function getAllUserLockedTokenBalance() external view returns (Types.TokenBalance[] memory) {
        address[] memory tokens = availableTokens[msg.sender];
        Types.TokenBalance[] memory tokenBalances = new Types.TokenBalance[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            tokenBalances[i] = Types.TokenBalance(
                tokens[i],
                lockedUserTokenBalance[msg.sender][tokens[i]]
            );
        }
        return tokenBalances;
    }

    function getDueDateStreams() public view whenNotPaused returns (Types.Stream[] memory) {
        require(msg.sender == systemAddress, "!system address");
        return _getDueDateStreams();
    }
    function _getDueDateStreams() internal view returns (Types.Stream[] memory) {
        uint currentTimeStamp = block.timestamp;
        Types.Stream memory currentStream;
        Types.Stream[] memory dueStreams = new Types.Stream[](nextStreamId);
        uint count = 0;
        for (uint i=1; i < nextStreamId; i++) {
            currentStream = streams[i];
            if (currentStream.status == 1 && currentStream.stopTime < currentTimeStamp && currentStream.remainingBalance > 0 ) {
                dueStreams[i] = streams[i];
                dueStreams[i].streamId = i;
                count += 1;
            }
        }
        Types.Stream[] memory correctDueDateStreams = new Types.Stream[](count);
        count = 0;
        for (uint i=0; i < nextStreamId; i++) {
            if (dueStreams[i].streamId != 0) {
                correctDueDateStreams[count] = dueStreams[i];
                count += 1;
            }

        }

        return correctDueDateStreams;
    }

    function doAutoWithdraw(uint256[] memory streamIds) external {
        require(msg.sender == systemAddress, "!system address");
        if (streamIds.length > 0) {
            Types.Stream memory stream;
            for(uint i=0; i < streamIds.length; i++) {
                uint streamId = streamIds[i];
                stream = streams[streamId];

                if (userTokenBalance[stream.sender][stream.tokenAddress] >= stream.remainingBalance && lockedUserTokenBalance[stream.sender][stream.tokenAddress] >= stream.remainingBalance) {

                    userTokenBalance[stream.sender][stream.tokenAddress] -= stream.remainingBalance;

                    lockedUserTokenBalance[stream.sender][stream.tokenAddress] -= stream.remainingBalance;

                }

                streams[streamId].remainingBalance = 0;
                streams[streamId].status = 3;
                if (stream.tokenAddress != address(0x00)) {
                    _transfer(stream.tokenAddress, stream.recipient, stream.remainingBalance );
                } else {
                    payable(stream.recipient).transfer(stream.remainingBalance);
                }
            }

            emit DoAutoWithdraw(msg.sender, streamIds);
        }
    }

    function getSystemAddress() external view onlyOwner returns (address) {
        return systemAddress;
    }

    function setSystemAddress(address newSystemAddress) external onlyOwner {
        require(systemAddress != newSystemAddress, "New=Old");
        systemAddress = newSystemAddress;
        emit SetSystemAddress(msg.sender, newSystemAddress);
    }

    function batchTransfer(address tokenAddress, address[] calldata recipients, uint256[] calldata values) external whenNotPaused nonReentrant {
        address correctTokenAddress = (tokenAddress == address(this)) ? address(0) : tokenAddress;
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            total += values[i];
        }
        uint256 totalAmountIncludeFee = _getAmountIncludedFee(
            msg.sender,
            tokenAddress,
            total
        );
        require(
            (userTokenBalance[msg.sender][correctTokenAddress] - lockedUserTokenBalance[msg.sender][correctTokenAddress]) >= totalAmountIncludeFee,
            "balance-lockedAmount<totalAmountIncludeFee"
        );
        contractFees[correctTokenAddress] += totalAmountIncludeFee - total;
        userTokenBalance[msg.sender][correctTokenAddress] -= totalAmountIncludeFee;

        if (tokenAddress == address(this)) {
            for (uint256 i = 0; i < recipients.length; i++) {
                payable(recipients[i]).transfer(values[i]);
            }
        } else {
            for (uint256 i = 0; i < recipients.length; i++) {
                _transfer(correctTokenAddress, recipients[i], values[i]);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Types {

    struct StreamRequest {
        uint256 releaseAmount;
        address recipient;
        uint256 startTime;
        uint256 stopTime;
        uint32 vestingRelease;
        uint256 releaseFrequency;
        uint8 transferPrivilege;
        uint8 cancelPrivilege;
        address tokenAddress;
    }

    struct Recipient {
        address recipient;
        uint256 releaseAmount;
    }

    struct RecipientResponse {
        uint256 streamId;
        address recipient;
        uint256 releaseAmount;
    }

    struct StreamGeneral {
        address tokenAddress;
        uint256 startTime;
        uint256 stopTime;
        uint32 vestingRelease;
        uint256 releaseFrequency;
        uint8 transferPrivilege;
        uint8 cancelPrivilege;
    }


    struct StreamGeneralResponse {
        address sender;
        address tokenAddress;
        uint256 startTime;
        uint256 stopTime;
        uint32 vestingRelease;
        uint256 releaseFrequency;
        uint8 transferPrivilege;
        uint8 cancelPrivilege;
    }


    struct StreamResponse {
        uint256 streamId;
        address sender;
        address recipient;
        uint256 releaseAmount;
        uint256 startTime;
        uint256 stopTime;
        uint32 vestingRelease;
        uint256 releaseFrequency;
        uint8 transferPrivilege;
        uint8 cancelPrivilege;
        address tokenAddress;
    }

    struct Stream {
        uint256 streamId;
        address sender;
        uint256 releaseAmount;
        uint256 remainingBalance;
        uint256 startTime;
        uint256 stopTime; 
        uint256 vestingAmount;
        uint256 releaseFrequency;
        uint8 transferPrivilege;
        uint8 cancelPrivilege;
        address recipient;
        address tokenAddress;
        uint8 status;
    }

    struct Fee {
        address tokenAddress;
        uint256 fee;
    }

    struct WithdrawFeeAddress {
        address allowAddress;
        uint32 percentage;
    }

    struct AvailableToken {
        address tokenAddress;
        bool exist;
    }

    struct TokenBalance {
        address tokenAddress;
        uint256 balance;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Types.sol";
pragma abicoder v2;

interface IPlatformFee {
    event WithdrawFee(address tokenAddress, address to, uint256 amount);
    event SetRateFee(uint32 rateFee);
    event AddWithdrawFeeAddress(address allowAddress, uint32 percentage);
    event RemoveWithdrawFeeAddress(address allowAddress);
    function setRateFee(uint32 rateFee) external;
    function getContractFee(address tokenAddress) external view returns(uint256);
    function withdrawFee(address to, address tokenAddress, uint256 amount) external returns (bool);
    function addWithdrawFeeAddress(address allowAddress, uint32 percentage) external ;
    function removeWithdrawFeeAddress(address allowAddress) external returns (bool) ;
    function getWithdrawFeeAddresses() external view returns(Types.WithdrawFeeAddress[] memory);
    function isAllowWithdrawingFee(address allowAddress) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Types.sol";

interface ICalamus {
    /**
     * @notice Emits when a stream is successfully created.
     */
    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 releaseAmount,
        uint256 startTime,
        uint256 stopTime,
        uint32 vestingRelease,
        uint256 releaseFrequency,
        uint8 transferPrivilege,
        uint8 cancelPrivilege,
        address tokenAddress
    );

    /**
     * @notice Emits when the recipient of a stream withdraws a portion or all their pro rata share of the stream.
     */
    event WithdrawFromStream(
        uint256 indexed streamId,
        address indexed recipient,
        uint256 amount
    );

    /**
     * @notice Emits when a stream is successfully cancelled and tokens are transferred back on a pro rata basis.
     */
    event CancelStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance
    );

    /**
     * @notice Emits when a stream is successfully transfered and tokens are transferred back on a pro rata basis.
     */
    event TransferStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed newRecipient,
        uint256 recipientBalance
    );


    /**
     * @notice Emits when a stream is successfully topuped.
     */
    event TopupStream(
        uint256 indexed streamId,
        uint256 amount,
        uint256 stopTime
    );

    /**
    * @notice Emits when an user deposit an amount of token.
    */
    event Deposit(
        address indexed sender,
        address indexed tokenAddress,
        uint256 amount
    );

    /**
     * @notice Emits when streams were created
     */
    event BatchStreams(
        Types.StreamGeneralResponse generalInfo,
        Types.RecipientResponse[] recipientsResponse
    );

    /**
     * @notice Emits when withdraw from balance
     */
    event WithdrawFromBalance(address indexed sender, uint256 amount);

    /**
     * @notice Emits when change system address were created
     */
    event SetSystemAddress(address indexed sender, address indexed systemAddress);

    /**
     * @notice Emits when do auto withdraw
     */
    event DoAutoWithdraw(address indexed sender, uint256[] streamIds);

    function balanceOf(uint256 streamId, address who)
        external
        view
        returns (uint256 balance);

    function withdrawFromStream(uint256 streamId, uint256 funds) external;

    function cancelStream(uint256 streamId) external;

    function transferStream(uint256 streamId, address newRecipient) external;

    function topupStream(uint256 streamId, uint256 amount) external;

    function deposit(address tokenAddress, uint256 amount) external payable;

    function withdrawFromBalance(address tokenAddress, uint256 amount) external;

    function batchStreams(Types.StreamGeneral memory generalInfo, Types.Recipient[] memory recipients) external;

    function getAllUserTokenBalance() external returns (Types.TokenBalance[] memory);

    function getUserTokenBalance(address tokenAddress) external returns (uint256);

    function getUserLockedTokenBalance(address tokenAddress) external returns (uint256);

    function getAllUserLockedTokenBalance() external returns (Types.TokenBalance[] memory);

    function doAutoWithdraw(uint256[] memory streamIds) external;

    function setSystemAddress(address systemAddress) external;

    function getSystemAddress() external returns (address);

    function batchTransfer(address tokenAddress, address[] calldata recipients, uint256[] calldata values) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
  * @title Careful Math
  * @author Compound
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;

import "./EnumerableSetUpgradeable.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMapUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSetUpgradeable.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}