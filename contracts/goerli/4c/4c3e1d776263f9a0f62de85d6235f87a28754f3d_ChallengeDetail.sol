// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC721Receiver.sol";
import "./ExerciseSupplementNFT.sol";
import "./TransferHelper.sol";
import "./IERC1155.sol";

contract ChallengeDetail is IERC721Receiver{
    using SafeMath for uint256;

    /** @param ChallengeState currentState of challenge:
         1 : in processs
         2 : success
         3 : failed
         4 : gave up
         5 : closed
    */
    enum ChallengeState{
        PROCESSING,
        SUCCESS,
        FAILED,
        GAVE_UP,
        CLOSED
    }

    /** @dev securityAddress address to verify app signature.
    */

    address constant private securityAddress = 0x9A266044a5e5010C101169766F9cC7BE18bB111e;
    
    /** @dev returnedNFTWallet received NFT when Success
    */
    address constant private returnedNFTWallet = 0x1B224b4da437d26d0b47c185A58163D1319335B2;

    /** @dev erc20ListAddress list address of erc-20 contract.
    */
    address[] private erc20ListAddress;

    /** @dev erc721Address address of erc-721 contract.
    */
    address[] public erc721Address;

    /** @dev sponsor sponsor of challenge.
    */
    address payable public sponsor;

    /** @dev challenger challenger of challenge.
    */
    address payable public challenger;

    /** @dev feeAddress feeAddress of challenge.
    */
    address payable private feeAddress;

    /** @dev awardReceivers list of receivers when challenge success and fail, start by success list.
    */
    address payable[] private awardReceivers;

    /** @dev awardReceiversApprovals list of award for receivers when challenge success and fail, start by success list.
    */
    uint256[] private awardReceiversApprovals;

    /** @dev historyData number of steps each day in challenge.
    */
    uint256[] historyData;

    /** @dev historyDate date in challenge.
    */
    uint256[] historyDate;

    /** @dev index index to split array receivers.
    */
    uint256 private index;

    uint256 public indexNft;

    /** @dev totalReward total reward receiver can receive in challenge.
    */
    uint256 public totalReward;

    /** @dev gasFee coin for challenger transaction fee. Transfer for challenger when create challenge.
    */
    uint256 private gasFee;

    /** @dev serverSuccessFee coin for sever when challenge success.
    */
    uint256 private serverSuccessFee;

    /** @dev serverFailureFee coin for sever when challenge fail.
    */
    uint256 private serverFailureFee;

    /** @dev duration duration of challenge from start to end time.
    */
    uint256 public duration;

    /** @dev startTime startTime of challenge.
    */
    uint256 public startTime;

    /** @dev endTime endTime of challenge.
    */
    uint256 public endTime;

    /** @dev dayRequired number of day which challenger need to finish challenge.
    */
    uint256 public dayRequired;

    /** @dev goal number of steps which challenger need to finish in day.
    */
    uint256 public goal;

    /** @dev currentStatus currentStatus of challenge.
    */
    uint256 currentStatus;

    /** @dev sumAwardSuccess sumAwardSuccess of challenge.
    */
    uint256 sumAwardSuccess;

    /** @dev sumAwardFail sumAwardFail of challenge.
    */
    uint256 sumAwardFail;

    /** @dev sequence submit daily result count number of challenger.
    */
    uint256 sequence;

    /** @dev allowGiveUp challenge allow give up or not.
    */
    bool[] public allowGiveUp;

    /** @dev isFinished challenge finish or not.
    */
    bool public isFinished;

    /** @dev isSuccess challenge success or not.
    */
    bool public isSuccess;

    /** @dev choiceAwardToSponsor all award will go to sponsor wallet when challenger give up or not.
    */
    bool private choiceAwardToSponsor;

    /** @dev selectGiveUpStatus challenge need be give up one time.
    */
    bool selectGiveUpStatus;

    /** @dev approvalSuccessOf get amount of coin an `address` can receive when ckhallenge success.
    */
    mapping(address => uint256) private approvalSuccessOf;

    /** @dev approvalFailOf get amount of coin an `address` can receive when challenge fail.
    */
    mapping(address => uint256) private approvalFailOf;

    /** @dev stepOn get step on a day.
    */
    mapping(uint256 => uint256) private stepOn;

    /** @dev verifyMessage keep track and reject double secure message.
    */
    mapping(string => bool) private verifyMessage;

    ChallengeState private stateInstance;

    uint256[] private awardReceiversPercent;
    
    mapping(address => uint256[]) private awardTokenReceivers;

    uint256[] private listBalanceAllToken;

    uint256[] private amountTokenToReceiverList;

    uint256 public totalBalanceBaseToken; 

    address public createByToken;

    event SendDailyResult(uint256 indexed currentStatus);
    event FundTransfer(address indexed to, uint256 indexed valueSend);
    event GiveUp(address indexed from);
    event CloseChallenge(bool indexed challengeStatus);

    /**
     * @dev Action should be called in challenge time.
     */
    modifier onTime() {
        require(block.timestamp >= startTime, "Challenge has not started yet");
        require(block.timestamp <= endTime, "Challenge was finished");
        _;
    }

    /**
     * @dev Action should be called in required time.
     */
    modifier onTimeSendResult() {
        require(block.timestamp <= endTime.add(2 days), "Challenge was finished");
        require(block.timestamp >= startTime, "Challenge has not started yet");
        _;
    }

    /**
     * @dev Action should be called after challenge finish.
     */
    modifier afterFinish() {
        require(block.timestamp > endTime.add(2 days), "Challenge has not finished yet");
        _;
    }

    /**
     * @dev Action should be called when challenge is running.
     */
    modifier available() {
        require(!isFinished, "Challenge was finished");
        _;
    }

    /**
     * @dev Action should be called when challenge was allowed give up.
     */
    modifier canGiveUp() {
        require(allowGiveUp[0], "Can not give up");
        _;
    }

    /**
     * @dev User only call give up one time.
     */
    modifier notSelectGiveUp() {
        require(!selectGiveUpStatus, "This challenge was give up");
        _;
    }

    /**
     * @dev Action only called from stakeholders.
     */
    modifier onlyStakeHolders() {
        require(msg.sender == challenger || msg.sender == sponsor, "Only stakeholders can call this function");
        _;
    }

    /**
     * @dev Action only called from challenger.
     */
    modifier onlyChallenger() {
        require(msg.sender == challenger, "Only challenger can call this function");
        _;
    }

    /**
     * @dev verify app signature.
     */
    modifier verifySignature(string memory message, uint8 v, bytes32 r, bytes32 s) {
        require(securityAddress == verifyString(message, v, r, s), "Cant send");
        _;
    }

    /**
     * @dev verify double sending message.
     */
    modifier rejectDoubleMessage(string memory message) {
        require(!verifyMessage[message], "Cant send");
        _;
    }

    /**
     * @dev verify challenge success or not before close.
     */
    modifier availableForClose() {
        require(!isSuccess && !isFinished, "Cant call");
        _;
    }

    /**
     * @dev update balance Matic and token  
     */
    modifier updateAwardSuccessOrFail() {
        uint256 coinNativeBalance = address(this).balance;

        if(coinNativeBalance > 0) {
            serverSuccessFee = coinNativeBalance.mul(2).div(100);
            serverFailureFee = coinNativeBalance.mul(2).div(100);

            for (uint256 i = 0; i < index; i++) {
                approvalSuccessOf[awardReceivers[i]] = awardReceiversPercent[i].mul(coinNativeBalance).div(100);
                sumAwardSuccess = awardReceiversPercent[i].mul(coinNativeBalance).div(100);
            }
            
            for (uint256 i = index; i < awardReceivers.length; i++) {
                approvalFailOf[awardReceivers[i]] = awardReceiversPercent[i].mul(coinNativeBalance).div(100);
                sumAwardFail = awardReceiversPercent[i].mul(coinNativeBalance).div(100);
            }
        }
        _;
    }

    /**
     * @dev The Challenge constructor.
     * @param _stakeHolders : 0-sponsor, 1-challenger, 2-fee address
     * @param _primaryRequired : 0-duration, 1-start, 2-end, 3-goal
     * @param _awardReceivers : list receivers address
     * @param _index : index slpit receiver array
     * @param _allowGiveUp : challenge allow give up or not // true is token -- false is coin
     * @param _gasData : 0-gas for sever success, 1-gas for sever fail, 2-coin for challenger transaction fee
     * @param _allAwardToSponsorWhenGiveUp : transfer all award back to sponsor or not
     */
    constructor(
        address payable[] memory _stakeHolders,
        address _createByToken,
        address[] memory _erc721Address,
        uint256[] memory _primaryRequired,
        address payable[] memory _awardReceivers,
        uint256 _index,
        bool[] memory _allowGiveUp,
        uint256[] memory _gasData,
        bool _allAwardToSponsorWhenGiveUp,
        uint256[] memory _awardReceiversPercent,
        uint256 _totalAmount
    )
    payable
    {   
        require(_allowGiveUp.length == 3, "Invalid allow give up");

        if(_allowGiveUp[1]) {
            require(msg.value == _totalAmount, "Invalid award");
        }

        uint256 i;

        require(_index > 0, "Invalid value");

        _totalAmount = _totalAmount.sub(_gasData[2]);

        uint256[] memory awardReceiversApprovalsTamp = new uint256[](_awardReceiversPercent.length);

        for(uint256 j = 0; j < _awardReceiversPercent.length; j++) {
           awardReceiversApprovalsTamp[j] = _awardReceiversPercent[j].mul(_totalAmount).div(100);
        }

        require(_awardReceivers.length == awardReceiversApprovalsTamp.length, "Invalid lists");

        for (i = 0; i < _index; i++) {
            require(awardReceiversApprovalsTamp[i] > 0, "Invalid value0");
            approvalSuccessOf[_awardReceivers[i]] = awardReceiversApprovalsTamp[i];
            sumAwardSuccess = sumAwardSuccess.add(awardReceiversApprovalsTamp[i]);
        }

        for (i = _index; i < _awardReceivers.length; i++) {
            require(awardReceiversApprovalsTamp[i] > 0, "Invalid value1");
            approvalFailOf[_awardReceivers[i]] = awardReceiversApprovalsTamp[i];
            sumAwardFail = sumAwardFail.add(awardReceiversApprovalsTamp[i]);
        }

        sponsor = _stakeHolders[0];
        challenger = _stakeHolders[1];
        feeAddress = _stakeHolders[2];
        erc721Address = _erc721Address;
        erc20ListAddress = ExerciseSupplementNFT(erc721Address[0]).getErc20ListAddress();
        duration = _primaryRequired[0];
        startTime = _primaryRequired[1];
        endTime = _primaryRequired[2];
        goal = _primaryRequired[3];
        dayRequired = _primaryRequired[4];
        stateInstance = ChallengeState.PROCESSING;
        awardReceivers = _awardReceivers;
        awardReceiversApprovals = awardReceiversApprovalsTamp;
        awardReceiversPercent = _awardReceiversPercent;
        index = _index;
        serverSuccessFee = _totalAmount.mul(2).div(100);
        serverFailureFee = _totalAmount.mul(2).div(100);
        gasFee = _gasData[2];
        createByToken = _createByToken;
        tranferCoinNative(challenger, gasFee);
        emit FundTransfer(challenger, gasFee);
        totalReward = _totalAmount;
        allowGiveUp = _allowGiveUp;
        if (_allowGiveUp[0] && _allAwardToSponsorWhenGiveUp) choiceAwardToSponsor = true;
    }

    /**
    *@dev function to be able to accept native currency of the network.
    */
    receive() external payable {
        if(isFinished) {
            tranferCoinNative(payable(msg.sender), msg.value);
        }
    }

    /**
     * @dev Send daily result to challenge with security message and signature app.
     */
    function sendDailyResult(uint256[] memory _day, uint256[] memory _stepIndex, string memory message, uint8 v, bytes32 r, bytes32 s)
    public
    available
    onTimeSendResult
    onlyChallenger
    verifySignature(message, v, r, s)
    rejectDoubleMessage(message)
    {
        verifyMessage[message] = true;
        
        for (uint256 i = 0; i < _day.length; i++) {
            require(stepOn[_day[i]] == 0, "This day's data had already updated");
            stepOn[_day[i]] = _stepIndex[i];
            historyDate.push(_day[i]);
            historyData.push(_stepIndex[i]);
            if (_stepIndex[i] >= goal && currentStatus < dayRequired) {
                currentStatus = currentStatus.add(1);
            }
        }

        sequence = sequence.add(_day.length);

        if (sequence.sub(currentStatus) > duration.sub(dayRequired)){
            stateInstance = ChallengeState.FAILED;
            transferToListReceiverFail();
        } else {
            if (currentStatus >= dayRequired) {
                stateInstance = ChallengeState.SUCCESS;
                transferToListReceiverSuccess();
            }
        }

        emit SendDailyResult(currentStatus);
    }


    /**
     * @dev private funtion for verify message and singer.
     */
    function verifyString(string memory message, uint8 v, bytes32 r, bytes32 s) private pure returns(address signer)
    {
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            length:= mload(message)
            lengthOffset:= add(header, 57)
        }
        require(length <= 999999, "Not provided");
        uint256 lengthLength = 0;
        uint256 divisor = 100000;
        while (divisor != 0) {
            uint256 digit = length / divisor;
            if (digit == 0) {
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;
            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        assembly {
            mstore(header, lengthLength)
        }
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }

    /**
     * @dev give up challenge.
     */
    function giveUp() external canGiveUp notSelectGiveUp onTime available onlyStakeHolders {
        updateRewardSuccessAndfail();

        uint256 amount = address(this).balance.mul(98).div(100);

        if (choiceAwardToSponsor) {
            tranferCoinNative(sponsor, amount);
            for(uint256 i = 0; i < erc20ListAddress.length; i++) {
                if(getBalanceTokenOfContract(erc20ListAddress[i], address(this)) > 0) {                  
                    TransferHelper.safeTransfer(
                        erc20ListAddress[i],
                        sponsor,
                        listBalanceAllToken[i].mul(98).div(100)
                    );
                }
            }
            
            // emit FundTransfer(sponsor, amount);
        } else {
            uint256 amountToReceiverList = amount.mul(currentStatus).div(dayRequired);

            tranferCoinNative(sponsor, amount.sub(amountToReceiverList));

            for(uint256 i = 0; i < erc20ListAddress.length; i++) {
                uint256 amountTokenToReceiver;
                uint256 totalTokenRewardSubtractFee = listBalanceAllToken[i].mul(98).div(100);
            
                if(getBalanceTokenOfContract(erc20ListAddress[i], address(this)) > 0) {
                    amountTokenToReceiver = totalTokenRewardSubtractFee.mul(currentStatus).div(dayRequired);
                    uint256 amountNativeToSponsor = totalTokenRewardSubtractFee.sub(amountTokenToReceiver);
                    TransferHelper.safeTransfer(
                        erc20ListAddress[i],
                        sponsor,
                        amountNativeToSponsor
                    );
                    amountTokenToReceiverList.push(amountTokenToReceiver);
                }
            }

            for (uint256 i = 0; i < index; i++) {
                tranferCoinNative(
                    awardReceivers[i], 
                    approvalSuccessOf[awardReceivers[i]].mul(amountToReceiverList).div(amount)
                );

                for(uint256 j = 0; j < erc20ListAddress.length; j++) {
                    if(getBalanceTokenOfContract(erc20ListAddress[j], address(this)) > 0) {
                        uint256 amountTokenTmp = awardTokenReceivers[erc20ListAddress[j]][i]
                            .mul(amountTokenToReceiverList[j])
                            .div(listBalanceAllToken[j].mul(98).div(100));

                        TransferHelper.safeTransfer(
                            erc20ListAddress[j],
                            awardReceivers[i],
                            amountTokenTmp
                        );
                    }
                }
            }
        }

        transferNFTWhenFailed(erc721Address[0]);

        tranferCoinNative(feeAddress, serverFailureFee);
        // emit FundTransfer(feeAddress, serverFailureFee);
        isFinished = true;
        selectGiveUpStatus = true;
        stateInstance = ChallengeState.GAVE_UP;
        // emit GiveUp(msg.sender);
    }

    /**
     * @dev Close challenge.
     */
    function closeChallenge() external onlyStakeHolders afterFinish availableForClose
    {
        stateInstance = ChallengeState.CLOSED;
        transferToListReceiverFail();
    }

    /**
     * @dev Private function for transfer all award to receivers when challenge success.
     */
    function transferToListReceiverSuccess() private {  

        updateRewardSuccessAndfail();

        tranferCoinNative(feeAddress, serverSuccessFee);

        // emit FundTransfer(feeAddress, serverSuccessFee);

        for (uint256 i = 0; i < index; i++) {

            tranferCoinNative(awardReceivers[i], approvalSuccessOf[awardReceivers[i]]);

            for(uint256 j = 0; j < erc20ListAddress.length; j++) {
                if(getBalanceTokenOfContract(erc20ListAddress[j], address(this)) > 0) {
                    TransferHelper.safeTransfer(
                        erc20ListAddress[j],
                        awardReceivers[i],
                        awardTokenReceivers[erc20ListAddress[j]][i]
                    );
                }
            }
        }

        if(allowGiveUp[2]) {    
            address currentAddressNftUse;       
            (currentAddressNftUse, indexNft) = ExerciseSupplementNFT(erc721Address[0]).safeMintSpecialNft(
                goal,
                duration,
                createByToken,
                totalReward,
                awardReceiversPercent[0],
                address(awardReceivers[0]),
                address(challenger)
            );
            erc721Address.push(currentAddressNftUse);
        }

        address[] memory erc721AddressList = ExerciseSupplementNFT(erc721Address[0]).getNftListAddress();
        for(uint256 j = 0; j < erc721AddressList.length; j++) {
            if(ExerciseSupplementNFT(erc721Address[0]).typeNfts(erc721AddressList[j])) {
                for(uint256 i = 0; i < getIndexToken(erc721AddressList[j]); i++) {
                    if(getOwnerOfNft(erc721AddressList[j], i) == address(this)) {
                        TransferHelper.safeTransferFrom(
                            erc721AddressList[j],
                            address(this),
                            challenger,
                            i
                        );
                    }
                }
            } else {
                for(uint256 i = 0; i < getIndexToken(erc721AddressList[j]); i++) {
                    if(IERC1155(erc721AddressList[j]).balanceOf(address(this), i) > 0) {
                        TransferHelper.safeTransferNFT1155(
                            erc721AddressList[j],
                            address(this),
                            challenger,
                            i,
                            IERC1155(erc721AddressList[j]).balanceOf(address(this), i),
                            "ChallengeApp"
                        );
                    }
                }
            }
        }
        isSuccess = true;
        isFinished = true;
    }

    /**
     * @dev Private function for transfer all award to receivers when challenge fail.
     */
    function transferToListReceiverFail() private {
        updateRewardSuccessAndfail();
                
        tranferCoinNative(feeAddress, serverFailureFee);

        // emit FundTransfer(feeAddress, serverFailureFee);

        for (uint256 i = index; i < awardReceivers.length; i++) {

            tranferCoinNative(awardReceivers[i], approvalFailOf[awardReceivers[i]]);

            for(uint256 j = 0; j < erc20ListAddress.length; j++) {
                if(getBalanceTokenOfContract(erc20ListAddress[j], address(this)) > 0) {
                    TransferHelper.safeTransfer(
                        erc20ListAddress[j],
                        awardReceivers[i],
                        awardTokenReceivers[erc20ListAddress[j]][i]
                    );
                }
            }
        }

        transferNFTWhenFailed(erc721Address[0]);

        isFinished = true;
    }

    function getIndexToken(address _erc721Address) private view returns(uint256) {
        return ExerciseSupplementNFT(_erc721Address).nextTokenIdToMint();
    }

    function getOwnerOfNft(address _erc721Address, uint256 _index) private view returns(address) {
        return ExerciseSupplementNFT(_erc721Address).ownerOf(_index);
    }

    /**
     * @dev get balance of challenge.
     */
    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    /**
     * @dev get history of challenge.
     */
    function getChallengeHistory() external view returns(uint256[] memory date, uint256[] memory data) {
        return (historyDate, historyData);
    }

    /**
     * @dev get state of challenge.
     */
    function getState() external view returns (ChallengeState) {
        return stateInstance;
    }

    function tranferCoinNative(address payable from, uint256 value) private {
        if(getContractBalance() >= value) {
            TransferHelper.saveTransferEth(
                from,
                value
            );
        }
    }

    function transferNFTWhenFailed(address _erc721Address) private {
        address[] memory erc721AddressList = ExerciseSupplementNFT(_erc721Address).getNftListAddress();
        for(uint256 j = 0; j < erc721AddressList.length; j++) {
            if(ExerciseSupplementNFT(_erc721Address).typeNfts(erc721AddressList[j])) {
                if(ExerciseSupplementNFT(erc721AddressList[j]).balanceOf(address(this)) > 0) {
                    if(compareStrings(ExerciseSupplementNFT(erc721AddressList[j]).symbol(), "ESPLNFT")) {
                        for(uint256 i = 0; i < getIndexToken(erc721AddressList[j]); i++) {
                            address receiver = ExerciseSupplementNFT(erc721AddressList[j]).getHistoryNFT(i, address(this));
                            if(getOwnerOfNft(erc721AddressList[j], i) == address(this)) {
                                TransferHelper.safeTransferFrom(
                                    erc721AddressList[j],
                                    address(this),
                                    receiver,
                                    i
                                );
                            }
                        }
                    } else {
                        for(uint256 i = 0; i < getIndexToken(erc721AddressList[j]); i++) {
                            if(getOwnerOfNft(erc721AddressList[j], i) == address(this)) {
                                TransferHelper.safeTransferFrom(
                                    erc721AddressList[j],
                                    address(this),
                                    returnedNFTWallet,
                                    i
                                );
                            }
                        }
                    }
                }           
            } else {
                for(uint256 i = 0; i < getIndexToken(erc721AddressList[j]); i++) {
                    if(IERC1155(erc721AddressList[j]).balanceOf(address(this), i) > 0) {
                        TransferHelper.safeTransferNFT1155(
                            erc721AddressList[j],
                            address(this),
                            returnedNFTWallet,
                            i,
                            IERC1155(erc721AddressList[j]).balanceOf(address(this), i),
                            "ChallengeApp"
                        );
                    }
                } 
            }
        }
    }

    /**
     * @dev first update balance of Matic/token in smart contract
     */
    function updateRewardSuccessAndfail() private updateAwardSuccessOrFail{
        totalBalanceBaseToken = getContractBalance();

        for(uint256 i = 0; i < erc20ListAddress.length; i++) {
            listBalanceAllToken.push(
                ERC20(erc20ListAddress[i]).balanceOf(address(this))
            );

            if(getBalanceTokenOfContract(erc20ListAddress[i], address(this)) > 0) {
                for(uint256 j = 0; j < awardReceiversPercent.length; j++) {
                    awardTokenReceivers[erc20ListAddress[i]].push(
                        awardReceiversPercent[j].mul(ERC20(erc20ListAddress[i]).balanceOf(address(this))).div(100)
                    );
                }
                TransferHelper.safeTransfer(
                    erc20ListAddress[i],
                    feeAddress,
                    listBalanceAllToken[i].mul(2).div(100)
                );
            }
        }
    }

    function getBalanceTokenOfContract(address _erc20Address, address _fromAddress) private view returns(uint256) {
        return ERC20(_erc20Address).balanceOf(_fromAddress);
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function allContractERC20() external view returns(address[] memory) {
        return erc20ListAddress;
    }

    /**
     * @dev get information of challenge.
     */
    function getChallengeInfo() external view returns(uint256 challengeCleared, uint256 challengeDayRequired, uint256 daysRemained) {
        return (
            currentStatus,
            dayRequired,
            dayRequired.sub(currentStatus)
        );
    }

    function getAwardReceiversPercent() public view returns(uint256[] memory) {
        return (awardReceiversPercent);
    }

    function getBalanceToken() public view returns(uint256[] memory) {
        return listBalanceAllToken;
    }

    function getAwardReceiversAtIndex(uint256 _index, bool _isAddressSuccess) public view returns(address) {
        if(!_isAddressSuccess) {
            return awardReceivers[_index.add(index)];
        }
        return awardReceivers[_index];
    }

    /**
     * @dev onERC721Received.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
    /**
     * @dev onERC1155Received.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}