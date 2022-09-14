// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Interfaces/IMultiLogicProxy.sol";
import "./AggregatorV3Interface.sol";
import "./OwnableUpgradeableVersionable.sol";
import "./OwnableUpgradeableAdminable.sol";
import "./LogicUpgradeable.sol";

contract StorageV2 is LogicUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //struct
    struct DepositStruct {
        mapping(address => uint256) amount;
        mapping(address => int256) tokenTime; // 1: flag, 0: BNB
        uint256 iterate;
        uint256 balanceBLID;
        mapping(address => uint256) depositIterate;
    }

    struct EarnBLID {
        uint256 allBLID;
        uint256 timestamp;
        uint256 usd;
        uint256 tdt;
        mapping(address => uint256) rates;
    }

    struct BoostInfo{
        uint256 blidDeposit;
        uint256 rewardDebt;
    }

    /*** events ***/

    event Deposit(address depositor, address token, uint256 amount);
    event Withdraw(address depositor, address token, uint256 amount);
    event UpdateTokenBalance(uint256 balance, address token);
    event TakeToken(address token, uint256 amount);
    event ReturnToken(address token, uint256 amount);
    event AddEarn(uint256 amount);
    event UpdateBLIDBalance(uint256 balance);
    event InterestFee(address depositor, uint256 amount);
    event SetBLID(address blid);
    event AddToken(address token, address oracle);
    event SetMultiLogicProxy(address multiLogicProxy);
    event SetBoostInfo(uint256 maxBlidPerUSD, uint256 blidPerBlock, uint256 maxBlid);
    event DepositBLID(address depositor, uint256 amount);
    event WithdrawBLID(address depositor, uint256 amount);
    event ClaimBoostBLID(address depositor, uint256 amount);
    event SetExpenseAddress(address expenseAddress);

    function __Initialize() public initializer {
        LogicUpgradeable.initialize();
        PausableUpgradeable.__Pausable_init();
    }

    mapping(uint256 => EarnBLID) private earnBLID;
    uint256 private countEarns;
    uint256 private countTokens;
    mapping(uint256 => address) private tokens;
    mapping(address => uint256) private tokenBalance;
    mapping(address => address) private oracles;
    mapping(address => bool) private tokensAdd;
    mapping(address => DepositStruct) private deposits;
    mapping(address => uint256) private tokenDeposited;
    mapping(address => int256) private tokenTime;
    uint256 private reserveBLID;
    address public multiLogicProxy;
    address private BLID;
    mapping(address => mapping(uint256 => uint256))
        public accumulatedRewardsPerShare;
    mapping(address => BoostInfo) public userBoosts;//for test change private
    uint256 public maxBlidPerUSD;
    uint256 public blidPerBlock;
    uint256 public initBlidPerBlock;
    uint256 public maxBlidPerBlock;
    uint256 public accBlidPerShare;
    uint256 public lastRewardBlock;
    uint256 public totalSupplyBLID;
    address public expenseAddress;

    receive() external payable {}

    /*** modifiers ***/

    modifier isUsedToken(address _token) {
        require(tokensAdd[_token], "E1");
        _;
    }

    modifier onlyMultiLogicProxy() {
        require(msg.sender == multiLogicProxy, "E8");
        _;
    }

    modifier isBLIDToken(address _token) {
        require(BLID == _token, "E1");
        _;        
    }

    /*** User function ***/

    /**
     * @notice Deposit amount of token  to Strategy  and receiving earned tokens.
     * @param amount amount of token
     * @param token address of token
     */
    function deposit(uint256 amount, address token)
        external
        payable
        isUsedToken(token)
        whenNotPaused
    {
        require(amount > 0, "E3");
        uint8 decimals;

        if (token == address(0)) {
            require(msg.value >= amount, "E9");
            decimals = 18;
        } else {
            decimals = AggregatorV3Interface(token).decimals();
        }

        DepositStruct storage depositor = deposits[msg.sender];

        if (token != address(0)) {
            IERC20Upgradeable(token).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
        }

        uint256 amountExp18 = amount * 10**(18 - decimals);
        if (depositor.tokenTime[address(1)] == 0) {
            depositor.iterate = countEarns;
            depositor.depositIterate[token] = countEarns;
            depositor.tokenTime[address(1)] = 1;
            depositor.tokenTime[token] += int256(
                block.timestamp * (amountExp18)
            );
        } else {
            interestFee();
            if (depositor.depositIterate[token] == countEarns) {
                depositor.tokenTime[token] += int256(
                    block.timestamp * (amountExp18)
                );
            } else {
                depositor.tokenTime[token] = int256(
                    depositor.amount[token] *
                        earnBLID[countEarns - 1].timestamp +
                        block.timestamp *
                        (amountExp18)
                );

                depositor.depositIterate[token] = countEarns;
            }
        }
        depositor.amount[token] += amountExp18;

        tokenTime[token] += int256(block.timestamp * (amountExp18));
        tokenBalance[token] += amountExp18;
        tokenDeposited[token] += amountExp18;

        IMultiLogicProxy(multiLogicProxy).setLogicTokenAvailable(
            amountExp18,
            token,
            1
        );

        emit UpdateTokenBalance(tokenBalance[token], token);
        emit Deposit(msg.sender, token, amountExp18);
    }

    /**
     * @notice Deposit BLID token for boosting.
     * @param amount amount of token
     */
    function depositBLID(uint256 amount)
        external
        whenNotPaused
    {
        require(amount > 0, "E3");
        BoostInfo storage userBoost = userBoosts[msg.sender];
        uint256 usdDepositAmount = 1000000000000000000;//balanceOf(msg.sender);

        require(usdDepositAmount >  0 && 
            userBoost.blidDeposit + amount < usdDepositAmount * maxBlidPerUSD, "E11");
        
        claimBoostRewardBLID();

        IERC20Upgradeable(BLID).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        userBoost.blidDeposit += amount;
        totalSupplyBLID += amount;

        userBoost.rewardDebt = userBoost.blidDeposit * accBlidPerShare / 1e12;

        if (maxBlidPerBlock < totalSupplyBLID * blidPerBlock / 1e18) {
            blidPerBlock = maxBlidPerBlock / totalSupplyBLID * 1e18;
        }

        emit DepositBLID(msg.sender, amount);
    }

    /**
     * @notice Withdraw amount of token  from Strategy and receiving earned tokens.
     * @param amount Amount of token
     * @param token Address of token
     */
    function withdraw(uint256 amount, address token)
        external
        isUsedToken(token)
        whenNotPaused
    {
        uint8 decimals;

        if (token == address(0)) {
            decimals = 18;
        } else {
            decimals = AggregatorV3Interface(token).decimals();
        }

        uint256 countEarns_ = countEarns;
        uint256 amountExp18 = amount * 10**(18 - decimals);
        DepositStruct storage depositor = deposits[msg.sender];
        require(depositor.amount[token] >= amountExp18 && amount > 0, "E4");
        if (amountExp18 > tokenBalance[token]) {
            uint256 requireReturnAmount = amount -
                (tokenBalance[token] / (10**(18 - decimals)));
            IMultiLogicProxy(multiLogicProxy).releaseToken(
                requireReturnAmount,
                token
            );
            interestFee();

            if (token == address(0)) {
                require(address(this).balance >= amount, "E9");
                _send(payable(msg.sender), amount);
            } else {
                IERC20Upgradeable(token).safeTransferFrom(
                    multiLogicProxy,
                    address(this),
                    requireReturnAmount
                );
                IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
            }

            tokenDeposited[token] -= amountExp18;
            tokenTime[token] -= int256(block.timestamp * (amountExp18));
            tokenBalance[token] = 0;
            IMultiLogicProxy(multiLogicProxy).setLogicTokenAvailable(
                amount,
                token,
                0
            );
        } else {
            interestFee();
            if (token == address(0)) {
                _send(payable(msg.sender), amount);
            } else {
                IERC20Upgradeable(token).safeTransfer(msg.sender, amount);
            }
            tokenTime[token] -= int256(block.timestamp * (amountExp18));

            tokenBalance[token] -= amountExp18;
            tokenDeposited[token] -= amountExp18;
            IMultiLogicProxy(multiLogicProxy).setLogicTokenAvailable(
                amount,
                token,
                0
            );
        }
        if (depositor.depositIterate[token] == countEarns_) {
            depositor.tokenTime[token] -= int256(
                block.timestamp * (amountExp18)
            );
        } else {
            depositor.tokenTime[token] =
                int256(
                    depositor.amount[token] *
                        earnBLID[countEarns_ - 1].timestamp
                ) -
                int256(block.timestamp * (amountExp18));
            depositor.depositIterate[token] = countEarns_;
        }
        depositor.amount[token] -= amountExp18;

        emit UpdateTokenBalance(tokenBalance[token], token);
        emit Withdraw(msg.sender, token, amountExp18);
    }


    /**
     * @notice WithDraw BLID token for boosting.
     * @param amount amount of token
     */
    function withDrawBLID(uint256 amount)
        external
        whenNotPaused
    {
        require(amount > 0, "E3");
        BoostInfo storage userBoost = userBoosts[msg.sender];
        require(amount <= userBoost.blidDeposit, "E12" );

        claimBoostRewardBLID();

        IERC20Upgradeable(BLID).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        userBoost.blidDeposit -= amount;
        totalSupplyBLID -= amount;
        
        userBoost.rewardDebt = userBoost.blidDeposit * accBlidPerShare / 1e12;

        if (maxBlidPerBlock > totalSupplyBLID * initBlidPerBlock / 1e18) {
            blidPerBlock = initBlidPerBlock;
        }

        emit WithdrawBLID(msg.sender, amount);

    }

    /**
     * @notice Claim BLID to msg.sender
     */
    function interestFee() public {
        uint256 balanceUser = balanceEarnBLID(msg.sender);
        require(reserveBLID >= balanceUser, "E5");
        IERC20Upgradeable(BLID).safeTransfer(msg.sender, balanceUser);
        DepositStruct storage depositor = deposits[msg.sender];
        depositor.balanceBLID = balanceUser;
        depositor.iterate = countEarns;
        //unchecked is used because a check was made in require
        unchecked {
            depositor.balanceBLID = 0;
            reserveBLID -= balanceUser;
        }

        emit UpdateBLIDBalance(reserveBLID);
        emit InterestFee(msg.sender, balanceUser);
    }

    /**
     * @notice Claim Boosting Reward BLID to msg.sender
     */
    function claimBoostRewardBLID()
        public
    {
        updateAccBlidperShare();
        BoostInfo storage userBoost = userBoosts[msg.sender];
        uint256 claimAmount;
        if (userBoost.blidDeposit > 0) {
            claimAmount = ((userBoost.blidDeposit * accBlidPerShare) / 1e12) - userBoost.rewardDebt;
            if (claimAmount > 0) {
                safeBlidTransfer(msg.sender, claimAmount);
                userBoost.rewardDebt += claimAmount;
            }
        }

        emit ClaimBoostBLID(msg.sender, claimAmount);
    }

    /*** Owner functions ***/

    /**
     * @notice Set blid in contract
     * @param _blid address of BLID
     */
    function setBLID(address _blid) external onlyOwner {
        BLID = _blid;

        emit SetBLID(_blid);
    }

    /**
     * @notice Set blid in contract
     * @param _expenseaddress address of expense
     */
    function setExpenseAddress(address _expenseaddress) external onlyOwner {
        expenseAddress = _expenseaddress;

        emit SetExpenseAddress(expenseAddress);
    }    

    /**
     * @notice Set boosting parameters
     * @param _maxBlidperUSD max value of BLID per USD
     * @param _blidperBlock blid per Block
     * @param _maxBlidperBlock max blid per Block
     */
    function setBoostingInfo(
        uint256 _maxBlidperUSD,
        uint256 _blidperBlock,
        uint256 _maxBlidperBlock
    ) external onlyOwner {

        if (totalSupplyBLID != 0) {
            require(_blidperBlock * totalSupplyBLID / 1e18 < _maxBlidperBlock, "E13");
            updateAccBlidperShare();
        }

        maxBlidPerUSD = _maxBlidperUSD;
        blidPerBlock = _blidperBlock;
        initBlidPerBlock = _blidperBlock;
        maxBlidPerBlock = _maxBlidperBlock;

        emit SetBoostInfo(_maxBlidperUSD, _blidperBlock, _maxBlidperBlock);
    }    

    /**
     * @notice Triggers stopped state.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Returns to normal state.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Update AccumulatedRewardsPerShare for token, using once after update contract
     * @param token Address of token
     */
    function updateAccumulatedRewardsPerShare(address token)
        external
        onlyOwner
    {
        require(accumulatedRewardsPerShare[token][0] == 0, "E7");
        uint256 countEarns_ = countEarns;
        for (uint256 i = 0; i < countEarns_; i++) {
            updateAccumulatedRewardsPerShareById(token, i);
        }
    }

    /**
     * @notice Add token and token's oracle
     * @param _token Address of Token
     * @param _oracles Address of token's oracle(https://docs.chain.link/docs/binance-smart-chain-addresses/
     */
    function addToken(address _token, address _oracles) external onlyOwner {
        require(_token != address(1) && _oracles != address(1));
        require(!tokensAdd[_token], "E6");
        oracles[_token] = _oracles;
        tokens[countTokens++] = _token;
        tokensAdd[_token] = true;

        emit AddToken(_token, _oracles);
    }

    /**
     * @notice Set MultiLogicProxy in contract(only for upgradebale contract,use only whith DAO)
     * @param _multiLogicProxy Address of MultiLogicProxy Contract
     */
    function setMultiLogicProxy(address _multiLogicProxy) external onlyOwner {
        multiLogicProxy = _multiLogicProxy;

        emit SetMultiLogicProxy(_multiLogicProxy);
    }

    /*** MultiLogicProxy function ***/

    /**
     * @notice Transfer amount of token from Storage to Logic Contract.
     * @param amount Amount of token
     * @param token Address of token
     */
    function takeToken(uint256 amount, address token)
        external
        onlyMultiLogicProxy
        isUsedToken(token)
    {
        uint8 decimals;

        if (token == address(0)) {
            decimals = 18;
        } else {
            decimals = AggregatorV3Interface(token).decimals();
        }

        uint256 amountExp18 = amount * 10**(18 - decimals);

        if (token == address(0)) {
            _send(payable(multiLogicProxy), amount);
        } else {
            IERC20Upgradeable(token).safeTransfer(multiLogicProxy, amount);
        }
        tokenBalance[token] = tokenBalance[token] - amountExp18;

        emit UpdateTokenBalance(tokenBalance[token], token);
        emit TakeToken(token, amountExp18);
    }

    /**
     * @notice Transfer amount of token from Storage to Logic Contract.
     * @param amount Amount of token
     * @param token Address of token
     */
    function returnToken(uint256 amount, address token)
        external
        onlyMultiLogicProxy
        isUsedToken(token)
    {
        uint8 decimals;

        if (token == address(0)) {
            require(address(this).balance >= amount, "E9");
            decimals = 18;
        } else {
            decimals = AggregatorV3Interface(token).decimals();
        }

        uint256 amountExp18 = amount * 10**(18 - decimals);

        if (token != address(0)) {
            IERC20Upgradeable(token).safeTransferFrom(
                multiLogicProxy,
                address(this),
                amount
            );
        }

        tokenBalance[token] = tokenBalance[token] + amountExp18;

        emit UpdateTokenBalance(tokenBalance[token], token);
        emit ReturnToken(token, amountExp18);
    }

    /**
     * @notice Claim all BLID(from strategy and boost) for user
     */
    function claimAllRewardBLID()
        external
    {
        interestFee();
        claimBoostRewardBLID();
    }    

    /**
     * @notice Take amount BLID from Logic contract  and distributes earned BLID
     * @param amount Amount of distributes earned BLID
     */
    function addEarn(uint256 amount) external onlyMultiLogicProxy {
        IERC20Upgradeable(BLID).safeTransferFrom(
            multiLogicProxy,
            address(this),
            amount
        );
        reserveBLID += amount;
        int256 _dollarTime = 0;
        uint256 countTokens_ = countTokens;
        uint256 countEarns_ = countEarns;
        EarnBLID storage thisEarnBLID = earnBLID[countEarns_];
        for (uint256 i = 0; i < countTokens_; i++) {
            address token = tokens[i];
            AggregatorV3Interface oracle = AggregatorV3Interface(
                oracles[token]
            );
            thisEarnBLID.rates[token] = (uint256(oracle.latestAnswer()) *
                10**(18 - oracle.decimals()));

            // count all deposited token in usd
            thisEarnBLID.usd +=
                tokenDeposited[token] *
                thisEarnBLID.rates[token];

            // convert token time to dollar time
            _dollarTime += tokenTime[token] * int256(thisEarnBLID.rates[token]);
        }
        require(_dollarTime != 0);
        thisEarnBLID.allBLID = amount;
        thisEarnBLID.timestamp = block.timestamp;
        thisEarnBLID.tdt = uint256(
            (int256(((block.timestamp) * thisEarnBLID.usd)) - _dollarTime) /
                (1 ether)
        ); // count delta of current token time and all user token time

        for (uint256 i = 0; i < countTokens_; i++) {
            address token = tokens[i];
            tokenTime[token] = int256(tokenDeposited[token] * block.timestamp); // count curent token time
            updateAccumulatedRewardsPerShareById(token, countEarns_);
        }
        thisEarnBLID.usd /= (1 ether);
        countEarns++;

        emit AddEarn(amount);
        emit UpdateBLIDBalance(reserveBLID);
    }

    /*** External function ***/

    /**
     * @notice Counts the number of accrued СSR
     * @param account Address of Depositor
     */
    function _upBalance(address account) external {
        deposits[account].balanceBLID = balanceEarnBLID(account);
        deposits[account].iterate = countEarns;
    }

    /***  Public View function ***/

    /**
     * @notice update Accumulated BLID per share
     */
    function updateAccBlidperShare() public {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 passedblockcount = block.number - lastRewardBlock;
        uint256 blidSupply = totalSupplyBLID;
        
        if (blidSupply == 0){
            lastRewardBlock = block.number;
            return;
        }

        accBlidPerShare = accBlidPerShare + (passedblockcount * blidPerBlock * 1e12 / blidSupply);
        lastRewardBlock = block.number;
    }

    /**
     * @notice Return earned blid
     * @param account Address of Depositor
     */
    function balanceEarnBLID(address account) public view returns (uint256) {
        DepositStruct storage depositor = deposits[account];
        if (depositor.tokenTime[address(1)] == 0 || countEarns == 0) {
            return 0;
        }
        if (countEarns == depositor.iterate) return depositor.balanceBLID;

        uint256 countTokens_ = countTokens;
        uint256 sum = 0;
        uint256 depositorIterate = depositor.iterate;
        for (uint256 j = 0; j < countTokens_; j++) {
            address token = tokens[j];
            //if iterate when user deposited
            if (depositorIterate == depositor.depositIterate[token]) {
                sum += getEarnedInOneDepositedIterate(
                    depositorIterate,
                    token,
                    account
                );
                sum += getEarnedInOneNotDepositedIterate(
                    depositorIterate,
                    token,
                    account
                );
            } else {
                sum += getEarnedInOneNotDepositedIterate(
                    depositorIterate - 1,
                    token,
                    account
                );
            }
        }

        return sum + depositor.balanceBLID;
    }


    /**
     * @notice Return usd balance of account
     * @param account Address of Depositor
     */
    function balanceOf(address account) public view returns (uint256) {
        uint256 countTokens_ = countTokens;
        uint256 sum = 0;
        for (uint256 j = 0; j < countTokens_; j++) {
            address token = tokens[j];
            AggregatorV3Interface oracle = AggregatorV3Interface(
                oracles[token]
            );

            sum += ((deposits[account].amount[token] *
                uint256(oracle.latestAnswer()) *
                10**(18 - oracle.decimals())) / (1 ether));
        }
        return sum;
    }

    /*** External View function ***/

    /**
     * @notice Return sums of all distribution BLID.
     */
    function getBLIDReserve() external view returns (uint256) {
        return reserveBLID;
    }

    /**
     * @notice Return deposited usd
     */
    function getTotalDeposit() external view returns (uint256) {
        uint256 countTokens_ = countTokens;
        uint256 sum = 0;
        for (uint256 j = 0; j < countTokens_; j++) {
            address token = tokens[j];
            AggregatorV3Interface oracle = AggregatorV3Interface(
                oracles[token]
            );
            sum +=
                (tokenDeposited[token] *
                    uint256(oracle.latestAnswer()) *
                    10**(18 - oracle.decimals())) /
                (1 ether);
        }
        return sum;
    }

    /**
     * @notice Returns the balance of token on this contract
     */
    function getTokenBalance(address token) external view returns (uint256) {
        return tokenBalance[token];
    }

    /**
     * @notice Return deposited token from account
     */
    function getTokenDeposit(address account, address token)
        external
        view
        returns (uint256)
    {
        return deposits[account].amount[token];
    }

    /**
     * @notice Return true if _token  is in token list
     * @param _token Address of Token
     */
    function _isUsedToken(address _token) external view returns (bool) {
        return tokensAdd[_token];
    }

    /**
     * @notice Return count distribution BLID token.
     */
    function getCountEarns() external view returns (uint256) {
        return countEarns;
    }

    /**
     * @notice Return data on distribution BLID token.
     * First return value is amount of distribution BLID token.
     * Second return value is a timestamp when  distribution BLID token completed.
     * Third return value is an amount of dollar depositedhen  distribution BLID token completed.
     */
    function getEarnsByID(uint256 id)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (earnBLID[id].allBLID, earnBLID[id].timestamp, earnBLID[id].usd);
    }

    /**
     * @notice Return amount of all deposited token
     * @param token Address of Token
     */
    function getTokenDeposited(address token) external view returns (uint256) {
        return tokenDeposited[token];
    }

    /**
     * @notice Return all added tokens
     */
    function getUsedTokens() external view returns (address[] memory) {
        uint256 countTokens_ = countTokens;
        address[] memory ret = new address[](countTokens_);
        for (uint256 i = 0; i < countTokens_; i++) {
            ret[i] = tokens[i];
        }
        return ret;
    }

    /**
     * @notice Return pending BLID amount for boost to see on frontend
     */

    function getBoostingClaimableBLID(address user) external view returns (uint256) {
        
        BoostInfo storage userBoost = userBoosts[user];
        uint256 blidSupply = totalSupplyBLID;
        uint256 _accBLIDpershare = accBlidPerShare;
        if (block.number > lastRewardBlock && blidSupply != 0) {
            uint256 passedblockcount = block.number - lastRewardBlock;
            _accBLIDpershare = accBlidPerShare + 
                (passedblockcount * blidPerBlock * 1e12 / blidSupply);
        }
        return ((userBoost.blidDeposit * _accBLIDpershare) / 1e12) - userBoost.rewardDebt;
    }    

    /*** Internal Function ***/

    // Safe blid transfer function, just in case if rounding error causes pool to not have enough BLIDs.
    function safeBlidTransfer(address _to, uint256 _amount) internal {
        IERC20Upgradeable(BLID).safeTransferFrom(expenseAddress, _to, _amount);
    }    

    /*** Prvate Function ***/

    /**
     * @notice Count accumulatedRewardsPerShare
     * @param token Address of Token
     * @param id of accumulatedRewardsPerShare
     */
    function updateAccumulatedRewardsPerShareById(address token, uint256 id)
        private
    {
        EarnBLID storage thisEarnBLID = earnBLID[id];
        //unchecked is used because if id = 0 then  accumulatedRewardsPerShare[token][id-1] equal zero
        unchecked {
            accumulatedRewardsPerShare[token][id] =
                accumulatedRewardsPerShare[token][id - 1] +
                ((thisEarnBLID.allBLID *
                    (thisEarnBLID.timestamp - earnBLID[id - 1].timestamp) *
                    thisEarnBLID.rates[token]) / thisEarnBLID.tdt);
        }
    }

    /**
     * @notice Count user rewards in one iterate, when he  deposited
     * @param token Address of Token
     * @param depositIterate iterate when deposit happened
     * @param account Address of Depositor
     */
    function getEarnedInOneDepositedIterate(
        uint256 depositIterate,
        address token,
        address account
    ) private view returns (uint256) {
        EarnBLID storage thisEarnBLID = earnBLID[depositIterate];
        DepositStruct storage thisDepositor = deposits[account];
        return
            (// all distibution BLID multiply to
            thisEarnBLID.allBLID *
                // delta of  user dollar time and user dollar time if user deposited in at the beginning distibution
                uint256(
                    int256(
                        thisDepositor.amount[token] *
                            thisEarnBLID.rates[token] *
                            thisEarnBLID.timestamp
                    ) -
                        thisDepositor.tokenTime[token] *
                        int256(thisEarnBLID.rates[token])
                )) /
            //div to delta of all users dollar time and all users dollar time if all users deposited in at the beginning distibution
            thisEarnBLID.tdt /
            (1 ether);
    }

    /**
     * @notice Send ETH to address
     * @param _to target address to receive ETH
     * @param amount ETH amount (wei) to be sent
     */
    function _send(address payable _to, uint256 amount) private {
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "E10");
    }

    /*** Private View Function ***/

    /**
     * @notice Count user rewards in one iterate, when he was not deposit
     * @param token Address of Token
     * @param depositIterate iterate when deposit happened
     * @param account Address of Depositor
     */
    function getEarnedInOneNotDepositedIterate(
        uint256 depositIterate,
        address token,
        address account
    ) private view returns (uint256) {
        return
            ((accumulatedRewardsPerShare[token][countEarns - 1] -
                accumulatedRewardsPerShare[token][depositIterate]) *
                deposits[account].amount[token]) / (1 ether);
    }


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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IMultiLogicProxy {
    function releaseToken(uint256 amount, address token) external;

    function takeToken(uint256 amount, address token) external;

    function addEarn(uint256 amount, address blidToken) external;

    function returnToken(uint256 amount, address token) external;

    function setLogicTokenAvailable(
        uint256 amount,
        address token,
        uint256 deposit_withdraw
    ) external;

    function getTokenBalance(address _token, address _logicAddress)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256 answer);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract OwnableUpgradeableVersionable is OwnableUpgradeable {
    string private _version;
    string private _purpose;

    event UpgradeVersion(string version, string purpose);

    function getVersion() external view returns (string memory) {
        return _version;
    }

    function getPurpose() external view returns (string memory) {
        return _purpose;
    }

    /**
    * @notice Set version and purpose
    * @param version Version string, ex : 1.2.0
    * @param purpose Purpose string
    */
    function upgradeVersion(string memory version, string memory purpose)
        external
        onlyOwner
    {
        require(bytes(version).length != 0, "OV1");

        _version = version;
        _purpose = purpose;

        emit UpgradeVersion(version, purpose);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract OwnableUpgradeableAdminable is OwnableUpgradeable {
    address private _admin;

    event SetAdmin(address admin);

    modifier onlyAdmin() {
        require(msg.sender == _admin, "OA1");
        _;
    }

    modifier onlyOwnerAndAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "OA2");
        _;
    }

    /**
     * @notice Set admin
     * @param newAdmin Addres of new admin
     */
    function setAdmin(address newAdmin) external onlyOwner {
        _admin = newAdmin;
        emit SetAdmin(newAdmin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./OwnableUpgradeableVersionable.sol";
import "./OwnableUpgradeableAdminable.sol";

abstract contract LogicUpgradeable is
    Initializable,
    OwnableUpgradeableVersionable,
    OwnableUpgradeableAdminable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}