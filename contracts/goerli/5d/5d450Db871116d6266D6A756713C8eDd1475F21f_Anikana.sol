// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ValidatorSmartContractInterface.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract Anikana is ValidatorSmartContractInterface, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // @param currentQueen save current Queen is currenctly in tenure
    Queen public currentQueen;

    // @param queenList save queen List from past to present
    Queen[] public queenList;

    // @param currentQueenVoting Save election information to remove the current queen
    QueenVoting public currentQueenVoting;

    // @param queenVotingList save all election information to recall the queen so far and retrieved by voting sequence number
    mapping(uint256 => QueenVoting) public queenVotingList;

    // @param indexQueenVoting count the number of votes
    Counters.Counter public indexQueenVoting;

    // @param isQueenVoting save new queen election status
    bool public isQueenVoting = false;

    // @param currentQueenDismissVoting save new queen election status
    QueenDismissVoting public currentQueenDismissVoting;

    // @param queenDismissVotingList save election state to create new queen election new queen
    mapping(uint256 => QueenDismissVoting) public queenDismissVotingList;

    // @param queenDismissVotingList save election state to create new queen election new queen
    Counters.Counter public indexQueenDismissVoting;

    // @param currentKnightList store all the knight's information so far and retrieve it with the knight's id of array
    mapping(uint256 => Knight) public currentKnightList;

    // @param knightList store the knight's information in its entirety and retrieve it by the knight's id
    Knight[] public knightList;

    // @param isNeedToAppointNewKnight Status of adding a new knight to the Knight List and current Knight array
    bool public isNeedToAppointNewKnight = false;

    // @param validatorCandidateList store all information including currentKinght and currentQueen and validatorCandidate
    ValidatorCandidate[] public validatorCandidateList;

    // @param validatorCandidateRequestList Store all information of the normal node that sends the request as a ValidatorCandidate
    mapping(uint256 => ValidatorCandidateRequest) public validatorCandidateRequestList;
        
    // @param indexValidatorCandidateRequest count the number of times normal node send the request as a ValidatorCandidate
    Counters.Counter public indexValidatorCandidateRequest;

    // @param feeToBecomeValidator required fee to be promoted to validatorCandidate
    uint256 private feeToBecomeValidator;

    // @param anikanaTokenAddress address token anikana
    IERC20 private anikanaTokenAddress;

    // @param QUEEN_TERM_PERIOD status initial og knight - queen - validatorCandidate
    uint256 private QUEEN_TERM_PERIOD = 1;

    // @param END_TERN_QUEEN to limit queen =>> APPLY FOR GOERLI TESTNET <<==
    uint256 private END_TERN_QUEEN = 5256000;

    // @param ANMPoolAddress
    address private ANMPoolAddress;

    // @param Number Knight
    uint256 constant NUMBER_KNIGHT = 12;

    // @param Number Validator
    uint256 constant NUMBER_VALIDATOR = 13;

    // @title Mapping to ActionRequest
    mapping(address => ActionRequest[]) private statusRequestList;

    // @title Event Knight is trust Queen
    // @param Address of Knight
    event AlertAmountTrustlessQueen(address indexed _knightAddrr);

    // @title Event Knight is voting to dismiss Queen
    // @param Address of Knight
    event AlertVotingToOrganizationForQueenDismissVote(
        address indexed _knightAddress,
        string _message
    );

    // @title Event validator candidate being elected as Queen
    // @param Address of Validator Candidate, address of Queen
    event AlertQueenDismissVoting(
        address indexed _validatorCandidate,
        address _queenAddres,
        string _message
    );

    // @title Event Queen appoints a new Knight
    // @param Address of Knight, address of current Queen, time Queen appoints a new Knight, Term of current Queen
    event AlertAddNewKnight(
        address indexed _knightAddr,
        address _queenTermNoAddr,
        uint256 _timeAddNewQueen,
        uint256 _queenTermNo
    );

    /*
    @param Address of Queen
    @param Total reward for the term 
    @param Block Queen is elected up
    @param Block Queen's term expires or is dismissed
    @param Term of current Queen
    @param Count the number of terms
    */
    struct Queen {
        address queenAddr;
        uint256 totalRewards;
        uint256 startTermBlock;
        uint256 endTermBlock;
        uint256 termNo;
        uint256 countTerm;
    }

    /**
    @param Address of Knight
    @param Knight's number in the array currentKnightlist
    @param Knight's number in the array knightlist
    @param Total reward for the term 
    @param Block Queen appointed Knights
    @param Block Queen dismissed Knight
    @param The term that Queen appoints Knight
    @param Array of validator candidates approved by Knight
    @param Trust or distrust Queen
    */
    struct Knight {
        address knightAddr;
        uint256 index;
        uint256 termNo;
        uint256 totalRewards;
        uint256 startTermBlock;
        uint256 endTermBlock;
        uint256 queenTermNo;
        address[] appointedValidatorCandidateList;
        bool isTrustQueen;
    }

    /**
    @param Address of Validator Candidate
    @param Knight's number in the array currentKnightlist
    @param Knight's number in the array knightlist
    @param Block Knight approved for Validator Candidate
    @param Block Validator Candidate no longer exists
    @param Amount to pay when request as validator Candidate
    */
    struct ValidatorCandidate {
        address validatorCandidateAddr;
        uint256 knightNo;
        uint256 knightTermNo;
        uint256 startTermBlock;
        uint256 endTermBlock;
        uint256 paidCoin;
    }

    /**
    @param Index of QueenVoting
    @param Term of Queen
    @param Block started
    @param Block ended
    @param List Address Knight voted Queen
    */
    struct QueenVoting {
        uint256 index;
        uint256 termNo;
        uint256 startVoteBlock;
        uint256 endVoteBlock;
        mapping(address => address[]) proposedList;
    }

    /**
    @param Index of QueenDismissVoting
    @param Term of Queen
    @param Block Knight dismissed Queen
    @param List Address Knight dismissed Queen
    */
    struct QueenDismissVoting {
        uint256 index;
        uint256 termNo;
        uint256 dismissBlock;
        address[] queenTrustlessList;
    }

    // @param Status of Request
    //@param Time has request started
    struct ActionRequest {
        StatusRequest statusRequest;
        uint256 timeRequestStart;
    }

    /**
    @param Status Validator Candidate requested
    @param Knight's number in the array currentKnightlist
    @param Knight's number in the array knightlist
    @param Block Requested
    @param Block Request has been approved
    @param Amount to pay when request as validator Candidate
    @param Address requester
    */
    struct ValidatorCandidateRequest {
        Status status;
        uint256 knightNo;
        uint256 knightTermNo;
        uint256 createdBlock;
        uint256 endBlock;
        uint256 paidCoin;
        address requester;
    }

    /**
    @param Validator candidate has been approved
    @param Validator candidate has been rejected
    @param Knight appointed 
    @param Knight dismissed
    @param Queen appointed Knight
    @param Queen dismissed Knight
    */
    enum StatusRequest {
        ValidatorCandidateApproved,
        ValidatorCandidateRejected,
        KnightAppoint,
        KnightDismiss,
        QueenAppoint,
        QueenDismiss
    }

    /**
     @param Validator has been requested
     @param Validator has been canceled
     @param Knight has been approved
     @param Knight has been rejected
    */
    enum Status {
        Requested,
        Canceled,
        Approved,
        Rejected
    }

    //@title Address ANM Pool
    modifier onlyANMPool() {
        require(
            _msgSender() == address(ANMPoolAddress),
            "ONLY POOL CAN CALL FUNCTION, PLEASE CHECK YOUR ADDRESS."
        );
        _;
    }

    // @title Address of current Queen
    modifier onlyQueen() {
        require(
            _msgSender() == currentQueen.queenAddr,
            "ONLY QUEEN CALL FUNCTION, PLEASE CHECK YOUR ADDRESS."
        );
        _;
    }
    
    // @title Check Normal node
    modifier onlyNormalNode() {
        require(
            !isValidator(_msgSender()),
            "ADDRESS USER IS NOT A NORMAL NODE, CANNOT REQUEST AS VALIDATOR."
        );
        _;
    }

    // @title The number of knights is always 12
    modifier onlyIndexKnight(uint256 _idKnight) {
        require(
            _idKnight <= NUMBER_KNIGHT && _idKnight > 0,
            "ID OF KNIGHIT NOT EXIST."
        );
        _;
    }

    // @title Only Knight
    modifier onlyKnight() {
        require(
            isKnight(_msgSender()),
            "ONLY KNIGHT CAN CALL, PLEASE CHECK YOUR ADDRESS."
        );
        _;
    }

    // @title The status is voting or not
    modifier onlyQueenVotingNotNow() {
        require(
            !isQueenVoting,
            "QUEEN HAS BEEN DISMISSED, YOU CANNOT TAKE THIS ACTION."
        );
        _;
    }

    // @title Init 1 Queen and 12 Knight
    // @param Addresses
    constructor(
        address[] memory initialKnight,
        address[] memory initialValdators
    ) public {
        require(initialKnight.length > 0, "NO INITIAL QUEEN ACCOUNTS");
        currentQueen = Queen(
            initialKnight[0],
            0,
            block.number,
            block.number + END_TERN_QUEEN,
            QUEEN_TERM_PERIOD,
            QUEEN_TERM_PERIOD
        );

        queenList.push(currentQueen);

        validatorCandidateList.push(
            ValidatorCandidate(currentQueen.queenAddr, 1, 0, block.number, 0, 0)
        );

        for (uint256 i = 1; i < initialKnight.length; i++) {

            address[] memory appointedValidatorListTemporary;
            currentKnightList[i] = Knight(
                initialKnight[i],
                i,
                i.sub(1),
                0,
                block.number,
                0,
                QUEEN_TERM_PERIOD,
                appointedValidatorListTemporary,
                true
            );

            if (i == 1) {
                initializeAppointedValidatorCandidateList(
                    i,
                    currentQueen.queenAddr,
                    i,
                    i.sub(1),
                    StatusRequest.QueenAppoint
                );
            }

            initializeAppointedValidatorCandidateList(
                i,
                currentKnightList[i].knightAddr,
                i,
                i.sub(1),
                StatusRequest.KnightAppoint
            );

            knightList.push(currentKnightList[i]);
            
            validatorCandidateList.push(
                ValidatorCandidate(
                    currentKnightList[i].knightAddr,
                    currentKnightList[i].index,
                    currentKnightList[i].termNo,
                    block.number,
                    0,
                    0
                )
            );
        }
    }

    // @title Distribute Reward by ANM Pool, call by from ANM address
    // @param Address of validator, total rewards
    function distributeRewards(address _validatorAddr, uint256 _reward)
        external
        onlyANMPool
    {
        require(
            isValidator(_validatorAddr),
            "ONLY VALIDATOR CANDIDATE CAN CALL THIS FUNCTION"
        );

        uint256 balanceOfSender = anikanaTokenAddress.balanceOf(_msgSender());
        require(balanceOfSender >= _reward, "BALANCE INSURANCE");
        require(
            address(anikanaTokenAddress) != address(0),
            "TOKEN ADDRESS ANIKANA NOT SET."
        );

        uint256 allowaneOfSender = anikanaTokenAddress.allowance(
            _msgSender(),
            address(this)
        );
        require(
            allowaneOfSender >= _reward,
            "BALANCE ALLOWANCE OF POOL ADDRESS INSURANCE."
        );

        tranferTokenAnikanaToContract(_reward);
        
        if(checkAndUpdateQueenVotingFlag()){
            if (checkQueenExists()) {
                updateTotalRewardOfValidator(_validatorAddr, _reward);
            } else {
                isQueenVoting = true;
                anikanaTokenAddress.burn(_reward);
            }
            return;
        }

        if(!checkAndUpdateQueenVotingFlag()){
            anikanaTokenAddress.burn(_reward);
            return;
        }
    }

    // @title Create request to become validator
    // @param Index of Knight
    function createRequestValidator(uint256 _idKnight)
        external
        onlyNormalNode
        onlyIndexKnight(_idKnight)
    {
        require(
            !checkStatusValidatorCandidateRequest(),
            "THERE IS AN ACTIVE REQUEST, PENDING, CAN'T CREATE A NEW REQUEST."
        );

        require(feeToBecomeValidator > 0, "FEE TO BE COME VALIDATOR NOT SET.");

        require(
            address(anikanaTokenAddress) != address(0),
            "TOKEN ANIKANA NOT SET."
        );

        TransferHelper.safeTransferFrom(
            address(anikanaTokenAddress),
            _msgSender(),
            address(this),
            feeToBecomeValidator
        );

        indexValidatorCandidateRequest.increment();
        
        validatorCandidateRequestList[indexValidatorCandidateRequest.current()] = 
            ValidatorCandidateRequest(
                Status.Requested,
                _idKnight,
                currentKnightList[_idKnight].termNo,
                block.number,
                0,
                feeToBecomeValidator,
                _msgSender()
            );
    }

    // @title Cancel Request to become validator
    function cancelRequestValidator() external onlyNormalNode {
        uint256 indexOfRequest = getIndexOfValidatorCandidateRequest(
            _msgSender()
        );

        require(
            validatorCandidateRequestList[indexOfRequest].createdBlock > 0 &&
                validatorCandidateRequestList[indexOfRequest].status !=
                Status.Rejected,
            "REQUEST NOT EXIST OR REQUEST HAS BEEN DENIED."
        );

        TransferHelper.safeTransfer(
            address(anikanaTokenAddress),
            _msgSender(),
            feeToBecomeValidator
        );

        validatorCandidateRequestList[indexOfRequest].status = Status.Rejected;
        validatorCandidateRequestList[indexOfRequest].endBlock = block.number;
    }

    // @title Knight vote Dismiss Queen
    // @param Approve to dismiss Queen or not?
    function votingToOrganizationForQueenDismissVote(bool _isApprove)
        external
        onlyKnight
        onlyQueenVotingNotNow
    {
        if (
            checkQueenExists()
        ) {
            setStatusIsTrustQueen(_isApprove);
            // @test // Set >= 9 => default  ==> set >= 4 to test so fast
            if (currentQueenDismissVoting.queenTrustlessList.length >= 9) {
                currentQueenDismissVoting.dismissBlock = block.number;
                queenDismissVotingList[indexQueenDismissVoting.current()] = currentQueenDismissVoting;
                QueenDismissVoting memory queenDismissVotingEmpty;
                currentQueenDismissVoting = queenDismissVotingEmpty;
                isQueenVoting = true;
            }
            emit AlertVotingToOrganizationForQueenDismissVote(
                _msgSender(),
                "VOTING TO ORGANIZATION FOR QUEEN DISMISS VOTE SUCCESSED"
            );
        } else {
            isQueenVoting = true;
            revert("QUEEN'S TERM HAS EXPIRED, YOU CANNOT PERFORM THIS ACTION.");
        }
    }

    // @title Elect new queen instead, delete old queen
    // @param Address of validator candidate
    function queenVoting(address _validatorCandidaterAddress)
        external
        onlyKnight
    {
        if (!checkAndUpdateQueenVotingFlag()) {
            if (
                checkQueenExists()
            ) {
                isQueenVoting = true;
            } else {
                emit AlertQueenDismissVoting(
                    _validatorCandidaterAddress,
                    currentQueen.queenAddr,
                    "THERE IS NO QUEEN VOTE YET"
                );
            }
        }

        require(
            !(checkTitleAddress(_validatorCandidaterAddress) == 4),
            "CAN'T VOTE FOR NORMAL NODE"
        );

        if (currentQueenVoting.startVoteBlock == 0 || currentQueenVoting.endVoteBlock != 0) {
            indexQueenVoting.increment();
            currentQueenVoting.index = indexQueenVoting.current();
            currentQueenVoting.termNo = currentQueen.termNo;
            currentQueenVoting.startVoteBlock = block.number;
        }
        
        checkKnightVoteForQueenDismiss(_validatorCandidaterAddress);
        removeElementProposedNewQueen(_validatorCandidaterAddress);

        currentQueenVoting.proposedList[_validatorCandidaterAddress].push(
            _msgSender()
        );

        appointedNewQueen(_validatorCandidaterAddress);
    }

    // @title Appoint new knight, only Queen can call this function
    // @param Address of new Validator Candidate
    function appointedNewKnight(address _newValidatorCandidaterAddress)
        external
        onlyQueen
    {
        require(
            checkTitleAddress(_newValidatorCandidaterAddress) == 3,
            "ONLY VALIDATOR CANDIDATE CAN RELACE NEW KNIGHT"
        );

        require(
            isNeedToAppointNewKnight,
            "CHECK APPOINT NEW KNIGHT MUST BE TRUE"
        );

        for (uint256 i = 1; i <= NUMBER_KNIGHT; i++) {
            if (currentKnightList[i].startTermBlock == 0) {
                addStatusRequestList(
                    _newValidatorCandidaterAddress,
                    StatusRequest.KnightAppoint
                );

                address[] memory appointedValidatorListTemporary;

                currentKnightList[i] = Knight(
                    _newValidatorCandidaterAddress,
                    i,
                    knightList.length,
                    0,
                    block.number,
                    0,
                    currentQueen.termNo,
                    appointedValidatorListTemporary,
                    true
                );

                knightList.push(currentKnightList[i]);

                emit AlertAddNewKnight(
                    _newValidatorCandidaterAddress,
                    currentQueen.queenAddr,
                    block.number,
                    currentQueen.termNo
                );
                
                break;
            }
        }
    }

    /*
     @title Appoint and Dismiss Knight
     @param Index of Knight
     @param Address of Validator Candidate
     */
    function appointAndDismissKnight(
        uint256 _idKnight,
        address _addressValidatorCandidate
    ) external onlyQueen onlyQueenVotingNotNow {
        require(
            checkTitleAddress(_addressValidatorCandidate) == 3,
            "ONLY VALIDATE CANDIDATE CAN CALL"
        );
        
        if (
            checkQueenExists()
        ) {
            appointKnight(_idKnight, _addressValidatorCandidate);
        } else {
            isQueenVoting = true;
            revert("QUEEN'S TERM HAS EXPIRED.");
        }
    }

     /*
     @title Approve And Reject Request Validator
     @param Address of Validator Candidate
     @param Approve and Reject request of validator
    */
    function approveAndRejectRequestValidator(
        address _validatorCandidateAddresss,
        bool isApprove
    ) external onlyKnight {
        uint256 indexOfRequest = getIndexOfValidatorCandidateRequest(
            _validatorCandidateAddresss
        );

        require(
            !checkStatusValidatorCandidateRequestFromKnight(indexOfRequest),
            "REQUEST BECOME TO VALIDATOR IS NOT AVAILABLE."
        );

        (uint256 _indexKnightInCurrentKnight, uint256 _indexKnightInKnightList) = 
            getPositionOfKnightInKnightListandCurrentKnight(_msgSender());

        require(
            validatorCandidateRequestList[indexOfRequest].knightNo ==
                _indexKnightInCurrentKnight,
            "KNIGHTNO OF VALIDATORREQUEST IS INVALID."
        );

        if (isApprove) {
            approveRequestValidator(
                _indexKnightInCurrentKnight,
                _indexKnightInKnightList,
                indexOfRequest
            );
            
            addStatusRequestList(
                _validatorCandidateAddresss,
                StatusRequest.ValidatorCandidateApproved
            );
        } else {
            rejectRequestValidator(indexOfRequest);

            addStatusRequestList(
                _validatorCandidateAddresss,
                StatusRequest.ValidatorCandidateRejected
            );
        }

        validatorCandidateRequestList[indexOfRequest].endBlock = block.number;
    }

    function checkAndUpdateQueenVotingFlag() public view returns(bool) {
        return isQueenVoting;
    }
    
    function checkQueenExists() public view returns(bool) {
        if (currentQueen.endTermBlock > block.number) {
            return true;
        }
        return false;
    }

    // @title Check number vote dismiss Queen
    // return Validator candidate's address has been chosen as queen
    function checkThenNumberOfVotes() public view returns (address) {
        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (currentQueenVoting.proposedList[validatorCandidateList[i].validatorCandidateAddr].length >= 2) {
                uint256 countNumberKnightDismissQueen;

                for (uint256 j = 0;j < currentQueenVoting.proposedList[validatorCandidateList[i].validatorCandidateAddr].length;j++) {
                    if (currentQueenVoting.proposedList[validatorCandidateList[i].validatorCandidateAddr][j] != address(0)) {
                        countNumberKnightDismissQueen++;
                        if (countNumberKnightDismissQueen >= 6) {
                            return validatorCandidateList[i].validatorCandidateAddr;
                        }
                    }
                }
            }
        }

        return address(0);
    }

    // @title Check Knight vote Dismiss Queen
    // @param Address of Validator Candidate
    function checkKnightVoteForQueenDismiss(address _validatorCandidaterAddress)
        public
    {
        if (currentQueenVoting.proposedList[_validatorCandidaterAddress].length > 0) {
            for (uint256 i = 0; i < currentQueenVoting.proposedList[_validatorCandidaterAddress].length; i++) {
                if (currentQueenVoting.proposedList[_validatorCandidaterAddress][i] == _msgSender()) {
                    revert("VALIDATOR CANDIDATE PARTICIPATED IN THE ELECTION");
                }
            }
        }
    }

    // @title Remove proposed new Queen
    // @param Address of Validator Candidate
    function removeElementProposedNewQueen(address _validatorCandidaterAddress)
        internal
    {
        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (currentQueenVoting.proposedList[validatorCandidateList[i].validatorCandidateAddr].length > 0 && 
               validatorCandidateList[i].validatorCandidateAddr != _validatorCandidaterAddress
            ) {
                for (uint256 j = 0; j < currentQueenVoting.proposedList[validatorCandidateList[i].validatorCandidateAddr].length; j++) {
                    if (currentQueenVoting.proposedList[validatorCandidateList[i].validatorCandidateAddr][j] == _msgSender()) {
                        currentQueenVoting.proposedList[validatorCandidateList[i].validatorCandidateAddr][j] = 
                        currentQueenVoting.proposedList[validatorCandidateList[i].validatorCandidateAddr]
                            [
                                currentQueenVoting.proposedList[validatorCandidateList[i].validatorCandidateAddr].length.sub(1)
                            ];
                        currentQueenVoting.proposedList[validatorCandidateList[i].validatorCandidateAddr].pop();
                        break;
                    }
                }
            }
        }
    }

    /*
     @title Queen Appointed Knight
     @param Index of Knight
     @param Address of Validator Candidate
    */
    function appointKnight(
        uint256 _idKnight,
        address _addressValidatorCandidate
    ) internal onlyIndexKnight(_idKnight) {
        ( , uint256 _indexKnightInKnightList) 
            = getPositionOfKnightInKnightListandCurrentKnight(getAddressOfKnightFromIndexKnight(_idKnight));

        knightList[_indexKnightInKnightList].endTermBlock = block.number;
        addStatusRequestList(getAddressOfKnightFromIndexKnight(_idKnight),StatusRequest.KnightDismiss);
        addStatusRequestList(
            _addressValidatorCandidate,
            StatusRequest.KnightAppoint
        );

        currentKnightList[_idKnight] = Knight(
            _addressValidatorCandidate,
            _idKnight,
            knightList.length,
            0,
            block.number,
            0,
            currentQueen.termNo.add(1),
            currentKnightList[_idKnight].appointedValidatorCandidateList,
            true
        );
        knightList.push(currentKnightList[_idKnight]);
    }

    /*
     @title Approved validator's request
     @param Knight's number in the array currentKnightlist
     @param Knight's number in the array knightlist
     @param Index of request 
    */
    function approveRequestValidator(
        uint256 _knightNo,
        uint256 _knightTermNo,
        uint256 _indexRequest
    ) internal {
        validatorCandidateList.push(
            ValidatorCandidate(
                validatorCandidateRequestList[_indexRequest].requester,
                _knightNo,
                _knightTermNo,
                block.number,
                0,
                0
            )
        );

        currentKnightList[_knightNo].appointedValidatorCandidateList.push(
            validatorCandidateRequestList[_indexRequest].requester
        );

        knightList[_knightTermNo].appointedValidatorCandidateList.push(
            validatorCandidateRequestList[_indexRequest].requester
        );

        anikanaTokenAddress.burn(feeToBecomeValidator);
        validatorCandidateRequestList[_indexRequest].status = Status.Approved;
    }

    /*
     @title Returns the addresses that voted dismissQueen
     return addresses that voted dismissQueen
    */
    function getListAddressQueenTrustlessList()
        public
        view
        returns (address[] memory)
    {
        return currentQueenDismissVoting.queenTrustlessList;
    }

    /*
     @title Returns list address Queen dismiss voting
     @param Knight's index list votes to dismiss queen 
     */
    function getListAddressQueenDismissVotingList(
        uint256 _indexQueenDismissVotingList
    ) public view returns (address[] memory) {
        return
            queenDismissVotingList[_indexQueenDismissVotingList].queenTrustlessList;
    }

    // @title Returns the address that voted Queen
    // @param Address of Validator Candidate
    function getListAddressProposedList(address _validatorCandidaterAddress)
        public
        view
        returns (address[] memory)
    {
        return currentQueenVoting.proposedList[_validatorCandidaterAddress];
    }

    // @title Returns the addresses that voted Queen
    // @param Address of Validator Candidate
    function getList1AddressProposedList(address _validatorCandidaterAddress)
        public
        view
        returns (address[] memory)
    {
        return queenVotingList[1].proposedList[_validatorCandidaterAddress];
    }

    // @title Knight rejected validator's request
    // @param index Request
    function rejectRequestValidator(uint256 _indexRequest) internal {
        TransferHelper.safeTransfer(
            address(anikanaTokenAddress),
            validatorCandidateRequestList[_indexRequest].requester,
            feeToBecomeValidator
        );
        validatorCandidateRequestList[_indexRequest].status = Status.Rejected;
    }

    // @title Returns the address of the current Knight in the array knightList
    // @param index of Knight in the array currentKnightList
    function getAddressOfKnightFromIndexKnight(uint256 indexKnight)
        public
        view
        returns (address)
    {
        for (uint256 i = 1; i <= knightList.length; i++) {
            if (currentKnightList[i].index == indexKnight) {
                return currentKnightList[i].knightAddr;
            }
        }
    }

    // @title Set fee to become validator candidate
    // @param Fee To Become Validator
    function setFeeToBecomeValidatorCandidate(uint256 _feeToBecomeVakidator)
        public
        onlyQueen
    {    
        feeToBecomeValidator = _feeToBecomeVakidator;
    }

    // @title Set address anikana token
    // @param Address of ANM Token
    function setAnikanaTokenAddress(address _anikanaTokenAddress)
        public
        onlyQueen
    {
        require(address(anikanaTokenAddress) == address(0), "ANIKANA TOKEN ADDRESS SETED, JUST SET ONLY ONE");
        anikanaTokenAddress = IERC20(_anikanaTokenAddress);
    }

    // @title Set ANMPool address
    // param address of ANM pool
    function setANMpool(address _ANMPoolAddress) public onlyQueen {
        require(ANMPoolAddress == address(0), "ANM POOL ADDRESS MUST, JUST SET ONLY ONE");
        ANMPoolAddress = _ANMPoolAddress;
    }

    // @title Check status request of validator candidate when request to knight
    // @param Index of request
    function checkStatusValidatorCandidateRequestFromKnight(
        uint256 indexOfRequest
    ) public view returns (bool) {
        (uint256 _indexKnightInCurrentKnight,) = 
            getPositionOfKnightInKnightListandCurrentKnight(_msgSender());
        if (
            validatorCandidateRequestList[indexOfRequest].knightNo == _indexKnightInCurrentKnight &&
            validatorCandidateRequestList[indexOfRequest].status != Status.Rejected &&
            validatorCandidateRequestList[indexOfRequest].status != Status.Approved &&
            validatorCandidateRequestList[indexOfRequest].createdBlock != 0
        ) {
            return false;
        }
        return true;
    }

    // @title Returns the index of validator candidate in the array
    // @param Address of Validator Candidate
    function getIndexOfValidatorCandidate(address _addressValidatorCandidate)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (
                validatorCandidateList[i].validatorCandidateAddr == _addressValidatorCandidate
            ) {
                return i;
            }
        }
    }

    // @title Count the number of Validator Candidate in the array
    // return number of Validator Candidate
    function countNumberValidatorCandiadate() public view returns (uint256) {
        uint256 numberValidatorCandiadate;
        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (
                !isValidator(validatorCandidateList[i].validatorCandidateAddr)
            ) {
                numberValidatorCandiadate++;
            }
        }
        return numberValidatorCandiadate;
    }

    // @title Check status of Queen
    // return True or False
    function isValidator(address _validatorAddress) public view returns (bool) {
        if (
            checkTitleAddress(_validatorAddress) == 1 ||
            checkTitleAddress(_validatorAddress) == 2
        ) {
            return true;
        }
        return false;
    }

    // @title Check 1 address has any position
    // @param Address
    // return Number to determine the title of the address
    function checkTitleAddress(address _validatorCandidateAddress) public view returns (uint256) {
        require(_validatorCandidateAddress != address(0), "ADDRESS MUST BE DIFFERENT 0");
        if (isQueen(_validatorCandidateAddress)) return 1;
        if (isKnight(_validatorCandidateAddress)) return 2;
        if (isValidatorCandidate(_validatorCandidateAddress)) return 3;
        return 4;
    }

    // @title Return status request of Validator Candidate
    // @param Address of Validator Candidate 
    function getStatusRequestOfVaidatorCandidate(
        address _validatorCandidateAddress
    ) public view returns (ActionRequest[] memory) {
        return statusRequestList[_validatorCandidateAddress];
    }

    // @title Add status request list
    // @param Address of requester
    // @param Status of request
    function addStatusRequestList(
        address _ownerRequest,
        StatusRequest _statusRequest
    ) internal {
        statusRequestList[_ownerRequest].push(ActionRequest(_statusRequest, block.number));
    }

    // @title Return the fee payable to become validator
    function getFeeBeComeToValidatorCandidate() public view returns (uint256) {
        return feeToBecomeValidator;
    }

    // @title Returns the address, time start term and time end term of Queen
    function getInfoCurrentQueen()
        public
        view
        returns (
            address,
            uint256,
            uint256
        )
    {
        return (
            currentQueen.queenAddr,
            currentQueen.startTermBlock,
            currentQueen.endTermBlock
        );
    }

    // @title Check if an address is a Validator Candidate or not
    // @param Address of Validator Candidate
    // return true or false
    function isValidatorCandidate(address _validatorCandidateAddress) internal view returns (bool) {
        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (_validatorCandidateAddress == validatorCandidateList[i].validatorCandidateAddr &&
               !isValidator(_validatorCandidateAddress)
               ) {
                return true;
            }
            return false;
        }
    }

    // @title Returns the address, its index is in the array knightList, block.number it is set as Knight
    function getInfoCurrentKnightList()
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        address[] memory knightAddress = new address[](NUMBER_KNIGHT);
        uint256[] memory knightIndex = new uint256[](NUMBER_KNIGHT);
        uint256[] memory knightStartTermBlock = new uint256[](NUMBER_KNIGHT);

        for (uint256 i = 0; i < knightList.length; i++) {
            if (
                currentKnightList[i + 1].knightAddr == knightList[i].knightAddr
            ) {
                uint256 indexKnightArray = currentKnightList[i + 1].index.sub(1);
                knightAddress[indexKnightArray] = currentKnightList[i + 1].knightAddr;
                knightIndex[indexKnightArray] = currentKnightList[i + 1].index;
                knightStartTermBlock[indexKnightArray] = currentKnightList[i + 1].startTermBlock;
            }
        }
        return (knightAddress, knightIndex, knightStartTermBlock);
    }

    // @title Returns the address, its index is in the array knightList, block.number it is set as Validator Candidate
    function getInfoCurrentValidatorCandidate()
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 countNumberValidator = countNumberValidatorCandiadate();
        address[] memory validatorCandidateAddress = new address[](countNumberValidator);
        uint256[] memory validatorCandidateIndex = new uint256[](countNumberValidator);
        uint256[] memory validatorCandidateStartTermBlock = new uint256[](countNumberValidator);
        uint256 countIndexValidatorCandidate;

        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (!isValidator(validatorCandidateList[i].validatorCandidateAddr)) {
                validatorCandidateAddress[countIndexValidatorCandidate] = 
                   validatorCandidateList[i].validatorCandidateAddr;

                validatorCandidateIndex[countIndexValidatorCandidate] = 
                   validatorCandidateList[i].knightNo;

                validatorCandidateStartTermBlock[countIndexValidatorCandidate] = 
                   validatorCandidateList[i].startTermBlock;

                countIndexValidatorCandidate++;
            }
        }
        return (
            validatorCandidateAddress,
            validatorCandidateIndex,
            validatorCandidateStartTermBlock
        );
    }

    // @title Returns a list of addresses and indexes of Knights that have been requested
    // @param Index of Knight
    function getPendingRequestList(uint256 _idKnight)
        public
        view
        onlyIndexKnight(_idKnight)
        returns (address[] memory, uint256[] memory)
    {
        uint256 amountRequestPending;
        for (uint256 i = 1; i <= indexValidatorCandidateRequest.current(); i++) {
            if (
                validatorCandidateRequestList[i].status == Status.Requested &&
                validatorCandidateRequestList[i].knightNo == _idKnight
            ) amountRequestPending++;
        }

        address[] memory addressPendingRequestList = new address[](amountRequestPending);
        uint256[] memory startPendingRequestList = new uint256[](amountRequestPending);
        uint256 indexPendingRequest;

        for (uint256 i = 1; i <= indexValidatorCandidateRequest.current(); i++) {
            if (
                validatorCandidateRequestList[i].status == Status.Requested &&
                validatorCandidateRequestList[i].knightNo == _idKnight
            ) {
                addressPendingRequestList[indexPendingRequest] = validatorCandidateRequestList[i].requester;
                startPendingRequestList[indexPendingRequest] = validatorCandidateRequestList[i].createdBlock;
                indexPendingRequest++;
            }
        }
        return (addressPendingRequestList, startPendingRequestList);
    }

    // @title Return the number of requests, the block that made the request, the block that was requested, the index of knigh
    // @param index of Knight
    function getApproveRequestListOfKnight(uint256 _idKnight)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 amountAppointedValidatorCandidateListOfKnight = 
        currentKnightList[_idKnight].appointedValidatorCandidateList.length;

        uint256[] memory dateRequestListBecomeValidatorCandidate = 
            new uint256[](amountAppointedValidatorCandidateListOfKnight);
        uint256[] memory dateApproveListBecomeValidatorCandidate = 
            new uint256[](amountAppointedValidatorCandidateListOfKnight);
        uint256[] memory knightNoOfValidatorCandidate = 
            new uint256[](amountAppointedValidatorCandidateListOfKnight);

        for (uint256 i = 0; i < amountAppointedValidatorCandidateListOfKnight; i++) {
            for (uint256 j = 1; j <= indexValidatorCandidateRequest.current();j++) {
                if (
                    currentKnightList[_idKnight].appointedValidatorCandidateList[i] ==
                    validatorCandidateRequestList[j].requester
                ) {
                    dateRequestListBecomeValidatorCandidate[i] = validatorCandidateRequestList[j].createdBlock;
                    dateApproveListBecomeValidatorCandidate[i] = validatorCandidateRequestList[j].endBlock;
                    knightNoOfValidatorCandidate[i] = validatorCandidateRequestList[j].knightNo;
                    break;
                }
            }
        }
        return (
            currentKnightList[_idKnight].appointedValidatorCandidateList,
            dateRequestListBecomeValidatorCandidate,
            dateApproveListBecomeValidatorCandidate,
            knightNoOfValidatorCandidate
        );
    }

    // @title Return the index of the current queen in the array queen list
    // @param Address of Queen
    function getIndexQueenOfQueenList(address _queenAddress)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < queenList.length; i++) {
            if (_queenAddress == queenList[i].queenAddr) {
                return i;
            }
        }
    }

    // @title Return index of the knight in knightList
    // @param Address of Knight
    function getPositionOfKnightInKnightListandCurrentKnight(
        address _knightAddress
    ) public view returns (uint256, uint256) {
        uint256 _indexKnightInCurrentKnight;
        uint256 _indexKnightInKnightList;

        for (uint256 i = 0; i < knightList.length; i++) {
            if (knightList[i].knightAddr == _knightAddress) {
                _indexKnightInKnightList = i;
                break;
            }
        }

        for (uint256 i = 0; i < knightList.length; i++) {
            if (currentKnightList[i + 1].knightAddr == _knightAddress) {
                _indexKnightInCurrentKnight = i + 1;
                break;
            }
        }

        return (_indexKnightInCurrentKnight, _indexKnightInKnightList);
    }

    // @title Return index of the requested validator candidate
    // @param Address of validator candidate
    function getIndexOfValidatorCandidateRequest(
        address _validatorCandidateAddresss
    ) public view returns (uint256) {
        for (uint256 i = indexValidatorCandidateRequest.current(); i > 0; i--) {
            if (
                validatorCandidateRequestList[i].requester == _validatorCandidateAddresss
            ) {
                return i;
            }
        }
    }

    // @title Check status request of validator candidate
    function checkStatusValidatorCandidateRequest() public view returns (bool) {
        for (uint256 i = 1; i <= NUMBER_KNIGHT; i++) {
            for (uint256 j = indexValidatorCandidateRequest.current(); j > 0; j--) {
                if (
                    validatorCandidateRequestList[j].requester == _msgSender() &&
                    validatorCandidateRequestList[j].status != Status.Rejected &&
                    validatorCandidateRequestList[j].createdBlock != 0
                ) {
                    return true;
                }
            }
        }
        return false;
    }

    // @title Check if an address is a knight or not
    // @param Address of Knight
    function isKnight(address _knightAddress) internal view returns (bool) {
        for (uint256 i = 1; i <= NUMBER_KNIGHT; i++) {
            if (_knightAddress == currentKnightList[i].knightAddr) return true;
        }
        return false;
    }

    function isQueen(address _queenAddress) internal view returns (bool) {
        if(_queenAddress == currentQueen.queenAddr){
            return true;
        }
        return false;
    }

    // @title Initialize appointed validator candidateList
    // @param index appointed
    // @param Address of Validator Candidate
    // @param Knight's number in the array currentKnightlist
    // @param Knight's number in the array knightlist
    // @param Status of request
    function initializeAppointedValidatorCandidateList(
        uint256 _indexAppointed,
        address _validatorCandidateAddress,
        uint256 _knightNo,
        uint256 _knightTermNo,
        StatusRequest _statusRequest
    ) internal {
        addStatusRequestList(_validatorCandidateAddress, _statusRequest);
        currentKnightList[_indexAppointed].appointedValidatorCandidateList.push(_validatorCandidateAddress);
        indexValidatorCandidateRequest.increment();
        validatorCandidateRequestList[indexValidatorCandidateRequest.current()] = ValidatorCandidateRequest
        (
            Status.Approved,
            _knightNo,
            _knightTermNo,
            block.number,
            block.number,
            0,
            _validatorCandidateAddress
        );
    }

    // @title Update reward received after distribute reward
    // @param Address of Validator Candidate
    // @param total reward
    function updateTotalRewardOfValidator(
        address _validatorAddr,
        uint256 _reward
    ) internal {
        uint256 valueTransferForQueen = _reward.div(6);
        uint256 valueTransferForKnight = _reward.sub(valueTransferForQueen);

        TransferHelper.safeTransfer(
            address(anikanaTokenAddress),
            address(_validatorAddr),
            valueTransferForKnight
        );

        TransferHelper.safeTransfer(
            address(anikanaTokenAddress),
            address(currentQueen.queenAddr),
            valueTransferForQueen
        );

        if (isQueen(_validatorAddr)) {
            currentQueen.totalRewards += _reward;
        } else {
            currentQueen.totalRewards += valueTransferForQueen;
            (uint256 _indexKnightInCurrentKnight, ) = 
                getPositionOfKnightInKnightListandCurrentKnight(_validatorAddr);
            currentKnightList[_indexKnightInCurrentKnight].totalRewards += valueTransferForKnight;
        }
    }

    function tranferTokenAnikanaToContract(uint256 _amount) internal {
        TransferHelper.safeTransferFrom(
            address(anikanaTokenAddress),
            _msgSender(),
            address(this),
            _amount
        );
    }

    // @title Set status knight Trust Queen
    // @param status true or false
    function setStatusIsTrustQueen(bool _isTrustQueen) internal {
        (uint256 _indexKnightInCurrentKnight, ) = 
            getPositionOfKnightInKnightListandCurrentKnight(_msgSender());

        require(
            currentKnightList[_indexKnightInCurrentKnight].isTrustQueen !=
                _isTrustQueen,
            "THIS STATUS IS ALREADY EXIST"
        );

        if (currentQueenDismissVoting.dismissBlock != 0 || currentQueenDismissVoting.termNo == 0) {
            indexQueenDismissVoting.increment();
            currentQueenDismissVoting.termNo = currentQueen.termNo;
        }

        if (!_isTrustQueen) {
            currentKnightList[_indexKnightInCurrentKnight].isTrustQueen = false;
            currentQueenDismissVoting.queenTrustlessList.push(_msgSender());
        } else {
            currentKnightList[_indexKnightInCurrentKnight].isTrustQueen = true;

            for (uint256 i = 0; i < currentQueenDismissVoting.queenTrustlessList.length; i++) {
                if (_msgSender() == currentQueenDismissVoting.queenTrustlessList[i]) {
                    currentQueenDismissVoting.queenTrustlessList[i] = currentQueenDismissVoting.queenTrustlessList[
                        currentQueenDismissVoting.queenTrustlessList.length.sub(1)
                    ];
                    currentQueenDismissVoting.queenTrustlessList.pop();
                    break;
                }
            }
        }

        if (currentQueenDismissVoting.queenTrustlessList.length == 3) {
            emit AlertAmountTrustlessQueen(_msgSender());
        }
    }

    // @title Appointed new Queen
    // @param Address of Validator Candidate
    function appointedNewQueen(address _validatorCandidaterAddress) internal {
        if (checkThenNumberOfVotes() == address(0)) {
            emit AlertQueenDismissVoting(
                _validatorCandidaterAddress,
                currentQueen.queenAddr,
                "VOTE QUEEN DISMISS SUCCESSED"
            );
        } else {
            if (checkTitleAddress(_validatorCandidaterAddress) == 1) {
                require(
                    currentQueen.countTerm <= 2,
                    "NOT APPOINTED FOR THREE CONSECUTIVE TERMS"
                );
            }
            
            updateNewQueen();
            updateCurrentQueenVoting();

            if (!isKnight(_validatorCandidaterAddress)) {
                isNeedToAppointNewKnight = false;
                isQueenVoting = false;

                emit AlertQueenDismissVoting(
                    _validatorCandidaterAddress,
                    currentQueen.queenAddr,
                    "PROCESS QUEEN DISMISS VOTING SUCCESSED"
                );
            } else {
                (uint256 _indexKnightInCurrentKnight, uint256 _indexKnightInKnightList) = 
                    getPositionOfKnightInKnightListandCurrentKnight(_validatorCandidaterAddress);

                delete currentKnightList[_indexKnightInCurrentKnight];

                knightList[_indexKnightInKnightList].endTermBlock = block.number;
                isNeedToAppointNewKnight = true;

                emit AlertQueenDismissVoting(
                    _validatorCandidaterAddress,
                    currentQueen.queenAddr,
                    "PROCESS QUEEN DISMISS NOT YET SUCCESS"
                );
            }
        }
    }

    // @title Update the current Queen in the ongoing vote
    function updateCurrentQueenVoting() internal {
        queenVotingList[indexQueenVoting.current()].index = currentQueenVoting.index;
        queenVotingList[indexQueenVoting.current()].termNo = currentQueenVoting.termNo;
        queenVotingList[indexQueenVoting.current()].startVoteBlock = currentQueenVoting.startVoteBlock;
        queenVotingList[indexQueenVoting.current()].endVoteBlock = block.number;

        currentQueenVoting.index = 0;
        currentQueenVoting.termNo = 0;
        currentQueenVoting.startVoteBlock = 0;

        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (currentQueenVoting.proposedList[validatorCandidateList[i].validatorCandidateAddr].length > 0) {

                for (uint256 j = 0; j < currentQueenVoting.proposedList[validatorCandidateList[i].validatorCandidateAddr].length; j++) {
                    queenVotingList[indexQueenVoting.current()].proposedList[validatorCandidateList[i].validatorCandidateAddr]
                        .push(currentQueenVoting.proposedList[validatorCandidateList[i].validatorCandidateAddr][j]);
                }

                delete currentQueenVoting.proposedList[validatorCandidateList[i].validatorCandidateAddr];
            }
        }
    }

    // @title Update new Queen
    function updateNewQueen() internal {
        Queen memory queenCurrentTemporary = currentQueen;
        uint256 totalRewardsForNewQueen;
        uint256 countTermForNewQueen = 1;

        if (checkTitleAddress(checkThenNumberOfVotes()) == 1) {
            totalRewardsForNewQueen = currentQueen.totalRewards;
            countTermForNewQueen = currentQueen.countTerm.add(1);
        } else {
            if (checkTitleAddress(checkThenNumberOfVotes()) == 2) {
                (uint256 _indexKnightInCurrentKnight, ) = 
                   getPositionOfKnightInKnightListandCurrentKnight(checkThenNumberOfVotes());
                totalRewardsForNewQueen = currentKnightList[_indexKnightInCurrentKnight].totalRewards;
            }
        }

        addStatusRequestList(
            currentQueen.queenAddr,
            StatusRequest.QueenDismiss
        );

        addStatusRequestList(
            checkThenNumberOfVotes(),
            StatusRequest.QueenAppoint
        );

        currentQueen = Queen(
            checkThenNumberOfVotes(),
            totalRewardsForNewQueen,
            block.number,
            block.number + END_TERN_QUEEN,
            currentQueen.termNo.add(1),
            countTermForNewQueen
        );

        queenList[getIndexQueenOfQueenList(currentQueen.queenAddr)].endTermBlock = block.number;
        queenList[getIndexQueenOfQueenList(currentQueen.queenAddr)].countTerm = 0;
        queenList.push(currentQueen);
        isQueenVoting = false;
    }

    // @title Return all address validator
    function getValidators() external view override returns (address[] memory) {
        address[] memory validators = new address[](NUMBER_VALIDATOR);
        for (uint256 i = 0; i < NUMBER_VALIDATOR; i++) {
            validators[i] = validatorCandidateList[i].validatorCandidateAddr;
        }
        return validators;
    }
}