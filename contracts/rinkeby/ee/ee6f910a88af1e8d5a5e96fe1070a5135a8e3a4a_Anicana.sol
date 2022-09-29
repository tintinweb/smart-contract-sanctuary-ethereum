// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ValidatorSmartContractInterface.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./IKnightsOfTheRoundTable.sol";

contract Anicana is ValidatorSmartContractInterface, IKnightsOfTheRoundTable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // @param currentQueen saves current Queen
    Queen public currentQueen;

    // @param queenList saves list off all queens so far
    Queen[] public queenList;

    // @param queenVotingList saves all of queen votings to retrieve a voting by the sequence number
    mapping(uint256 => QueenVoting) public queenVotingList;

    // @param indexQueenVoting counts the number of votes in a queen voting
    Counters.Counter public indexQueenVoting;

    // @param isQueenVoting saves queen voting status flag
    bool public isQueenVoting = false;

    // @param currentQueenDismissVoting saves current queen dismissed voting
    QueenDismissVoting public currentQueenDismissVoting;

    // @param queenDismissVotingList saves all of queen dismissed voting so far
    mapping(uint256 => QueenDismissVoting) public queenDismissVotingList;

    // @param queenDismissVotingList counts the number of votes in a queen dismissed voting
    Counters.Counter public indexQueenDismissVoting;

    // @param currentKnightList saves 12 current knight information and can retrieve one by the knight's id of array
    mapping(uint256 => Knight) public currentKnightList;

    // @param knightList saves all of knight information so far and can retrieve one by the knight's id
    Knight[] public knightList;

    // @param isNeedToAppointNewKnight if a knight become the queen, it will lack a knight, so need to approint a new one. This flag shows that status.
    bool public isNeedToAppointNewKnight = false;

    // @param validatorCandidateList saves list of validator candidates
    ValidatorCandidate[] public validatorCandidateList;

    // @param validatorCandidateRequestList saves all of validator candidate requests
    mapping(uint256 => ValidatorCandidateRequest) public validatorCandidateRequestList;
        
    // @param indexValidatorCandidateRequest counts times of validator candidate requests that a normal node has sent
    Counters.Counter public indexValidatorCandidateRequest;

    // @param feeToBecomeValidatorCandidate saves the fee that a normal node has to pay when sending validator candidate request. This value is set by current queen.
    uint256 private feeToBecomeValidatorCandidate;

    // @param animaTokenAddress saves address of Anima token
    IERC20 private animaTokenAddress;

    // @param FIRST_TERM
    uint256 private FIRST_TERM = 1;

    // @param QUEEN_TERM_PERIOD_BY_BLOCK_NUMBER 2x365x24x60x60 (second) / 3 (second per block)
    uint256 private QUEEN_TERM_PERIOD_BY_BLOCK_NUMBER = 21024000;

    // @param ANMPoolAddress saves ANMPool address
    address private ANMPoolAddress;

    // @param Number Knight
    uint256 constant KNIGHT_NUMBER = 12;

    // @param Number Validator
    uint256 constant VALIDATOR_NUMBER = 13;

    // @param Dismiss number: notify level
    uint256 constant QUEEN_DISMISS_NOTIFY_LEVEL = 3;

    // @param Dismiss number: dimiss level
    uint256 constant QUEEN_DISMISS_DISMISS_LEVEL = 9;

    // @param Required vote number to become new queen
    uint256 constant REQUIRED_VOTE_NUMBER_TO_BECOME_NEW_QUEEN = 6;

    // @param Required vote number to become new queen
    uint256 constant MAX_CONSECUTIVE_TERM = 2;
    
    // @title Mapping to StatusRequest
    mapping(address => StatusRequestAndTime[]) private statusRequestList;

    StatusAppointAndDismiss[] private statusAppointAndDismiss;

    mapping(address => QueenVotingHistory[]) private queenVotingHistory;

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
        uint256 countConsecutiveTerm;
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
        address[] candidateList;
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
    struct StatusRequestAndTime {
        StatusRequest statusRequest;
        uint256 timeRequestStart;
    }

    struct StatusAppointAndDismiss {
        address knightAddress;
        uint256 assignNumber;
        uint256 blockCreate;
        bool appointAndDismiss;
    }

    struct QueenVotingHistory {
        address queenAddress;
        uint256 startTermBlock;
        uint256 endTermBlock;
        uint256 voteNumber;
        bool statusVote;
    }
    
    // @param Award
    // @param Time receive award
    struct RewardHistory{
        uint256 Award;
        uint256 timeReceiveAward;
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

    /*
    @title Event Knight is voting to dismiss Queen
    @param Address of Knight
    */
    event AlertQueenVoting(
        address indexed _knightAddress,
        string _message
    );

    /*
    @title Event validator candidate being elected as Queen
    @param Address of Validator Candidate, address of Queen
    */
    event AlertQueenVoting(
        address indexed _validatorCandidate,
        address _queenAddres,
        string _message
    );
    /*
    @title Event Queen appoints a new Knight
    @param Address of Knight, address of current Queen, time Queen appoints a new Knight, Term of current Queen
    */
    event AlertAddNewKnight(
        address indexed _knightAddr,
        address _queenTermNoAddr,
        uint256 _timeAddNewQueen,
        uint256 _queenTermNo
    );

    /*
    @title Event distribution reward
    @param _ANMPoolAddress address of ANM pool
    @param _validatorAddr validator address
    @param _reward reward distribution
    */
    event AlertDistributeRewards(
        address indexed _ANMPoolAddress,
        address _validatorAddr, 
        uint256 _reward
    );
    /*
    @title Event create request to validator of normal node
    @param _ANMPoolAddress address of ANM pool
    @param _validatorAddr validator address
    */
    event AlertCreateRequestValidator(
        address indexed normalAddress,
        uint256 _idKnight
    );
    
    /*
    @title event cancal request to validator of normal node
    @param _ANMPoolAddress address of ANM pool
    @param _idKnight index knight address
    @param _validatorAddr validator address
    */
    event AlertCancelRequestValidator(
        address indexed queenAddress,
        uint256 _idKnight,
        address  _addressValidatorCandidate
    );
    
    /*
    @title event appoint and dismiss knight
    @param _ANMPoolAddress address of ANM pool
    @param _validatorAddr validator address
    */
    event AlertAppointAndDismissKnight(
        address indexed queenAddress,
        address _addressValidatorCandidate,
        uint256 _idKnight
    );

    /*
     @title event appoint and reject normal become to validater
     @param _knightAddress kngiht address
     @param _validatorCandidateAddresss validator candidate address
     @param _isApprove status appoint and reject
    */
    event AlertApproveAndRejectRequestValidator(
        address indexed _knightAddress,
        address _validatorCandidateAddresss,
        bool _isApprove
    );
    

   // @title check caller is ANMPool or not
    modifier onlyANMPool() {
        require(
            _msgSender() == address(ANMPoolAddress),
            "ONLY THE ANMPOOL CAN CALL THIS FUNCTION."
        );
        _;
    }

    // @title check caller is current Queen or not
    modifier onlyQueen() {
        require(
            isQueen(_msgSender()),
            "ONLY THE QUEEN CAN CALL THIS FUNCTION, PLEASE CHECK YOUR ACCOUNT."
        );
        _;
    }
    
    // @title check caller is a normal node or not
    modifier onlyNormalNode() {
        require(
            isNormalNode(_msgSender()),
            "ONLY NORMAL NODE CAN CALL THIS FUNCTION, PLEASE CHECK YOUR ACCOUNT."
        );
        _;
    }

    // @title check knightIndex is from 1 to 12 or not
    modifier onlyIndexKnight(uint256 _idKnight) {
        require(
            _idKnight <= KNIGHT_NUMBER && _idKnight >= 1,
            "THIS INDEX IS NOT TRUE"
        );
        _;
    }

    // @title  check caller is a knight or not
    modifier onlyKnight() {
        require(
            isKnight(_msgSender()),
            "ONLY A KNIGHT CAN CALL THIS FUNCTION, PLEASE CHECK YOUR ACCOUNT."
        );
        _;
    }

    // @title  check is there queen voting now or not
    modifier onlyQueenVotingNotNow()
    {
        // update value of isQueenVoting
        checkAndUpdateQueenVotingFlag();

        require(
            !isQueenVoting,
            "THE QUEEN VOTING IS HAPPENING NOW."
        );
        _;
    }

    // @code 1.1. Initialization
    // @title Get input from the genesis file to initialize Anicana contract
    // @param Addresses
    constructor(address[] memory initialAccounts, address[] memory initialValdators)
        public
    {
        require(initialAccounts.length > 0, "NO INITIAL QUEEN ACCOUNT.");

        // init a queen
        currentQueen = Queen(
            initialAccounts[0],
            0,
            block.number,
            block.number + QUEEN_TERM_PERIOD_BY_BLOCK_NUMBER,
            FIRST_TERM,
            FIRST_TERM
        );
        queenList.push(currentQueen);

        validatorCandidateList.push(
            ValidatorCandidate(currentQueen.queenAddr, 1, 0, block.number, 0, 0)
        );

        // init 12 knights
        for (uint256 i = 1; i < initialAccounts.length; i++) {
            address[] memory appointedValidatorListTemporary;
            currentKnightList[i] = Knight(
                initialAccounts[i],
                i,
                i.sub(1),
                0,
                block.number,
                0,
                FIRST_TERM,
                appointedValidatorListTemporary,
                true
            );

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

        // Add: handle for the queen
        initializeAppointedValidatorCandidateList(
            1,
            currentQueen.queenAddr,
            1,
            0,
            StatusRequest.QueenAppoint
        );
    }

    // @title Return all address validator
    function getValidators() external view override returns (address[] memory) {
        address[] memory validators = new address[](VALIDATOR_NUMBER);
        for (uint256 i = 0; i < VALIDATOR_NUMBER; i++) {
            validators[i] = validatorCandidateList[i].validatorCandidateAddr;
        }
        return validators;
    }

    // @code 2.0. Distribute Reward
    // @title Distribute Reward
    // @param Address of validator, total rewards
    function distributeRewards(address _validatorAddr, uint256 _reward)
        external
        override
        onlyANMPool
    {
        require(
            isValidator(_validatorAddr),
            "THE ADDRESS IS NOT A VALIDATOR ADDRESS."
        );

        require(
            address(animaTokenAddress) != address(0),
            "ANIMA TOKEN ADDRESS HAS NOT BEEN SET."
        );

        // check ballance
        uint256 balanceOfSender = animaTokenAddress.balanceOf(_msgSender());
        require(
            balanceOfSender >= _reward,
            "INSUFFICIENT BALANCE."
        );

        // check allowance
        uint256 allowaneOfSender = animaTokenAddress.allowance(
            _msgSender(),
            address(this)
        );
        require(
            allowaneOfSender >= _reward,
            "INSURANCE BALANCE ALLOWANCE."
        );

        // withdraw reward from ANMPool to Anicana Contract
        TransferHelper.safeTransferFrom(
            address(animaTokenAddress),
            _msgSender(),
            address(this),
            _reward
        );

        checkAndUpdateQueenVotingFlag();

        if(isQueenVoting){
            animaTokenAddress.burn(_reward);
            return;
        }
        
        sendRewardAndUpdateTotalReward(_validatorAddr, _reward);
        
        emit AlertDistributeRewards(
            _msgSender(),
            _validatorAddr,
            _reward
        );
    }

    // @code 5.0. Normal node sends a validator candidate request
    // @title Create request to become validator
    // @param Index of Knight
    function createRequestValidator(uint256 _idKnight)
        external
        onlyNormalNode
        onlyIndexKnight(_idKnight)
    {
        require(
            !isExitedActiveValidatorCandidateRequest(0),
            "THERE IS AN ACTIVE REQUEST WAIT TO PROCESS, CAN'T CREATE A NEW OTHER REQUEST."
        );

        require(
            feeToBecomeValidatorCandidate > 0, 
            "FEE TO BECOME VALIDATOR CANDIDATE HAS NOT BEEN SET."
        );

        require(
            address(animaTokenAddress) != address(0),
            "ANIMA TOKEN ADDRESS HAS NOT BEEN SET."
        );

        // check ballance
        uint256 balanceOfSender = animaTokenAddress.balanceOf(_msgSender());

        require(
            balanceOfSender >= feeToBecomeValidatorCandidate,
            "TRANSFER AMOUNT EXCEEDS BALANCE."
        );

        require(
            address(animaTokenAddress) != address(0),
            "TOKEN ADDRESS ANIMA NOT BEEN SET."
        );

        // check allowance
        uint256 allowaneOfSender = animaTokenAddress.allowance(
            _msgSender(),
            address(this)
        );
        require(
            allowaneOfSender >= feeToBecomeValidatorCandidate,
            "TRANSFER AMOUNT EXCEEDS ALLOWANCE BALANCE."
        );

        // withdraw user token
        TransferHelper.safeTransferFrom(
            address(animaTokenAddress),
            _msgSender(),
            address(this),
            feeToBecomeValidatorCandidate
        );

        // create new one then add to request list
        indexValidatorCandidateRequest.increment();
        validatorCandidateRequestList[indexValidatorCandidateRequest.current()] = 
            ValidatorCandidateRequest(
                Status.Requested,
                _idKnight,
                currentKnightList[_idKnight].termNo,
                block.number,
                0,
                feeToBecomeValidatorCandidate,
                _msgSender()
            );
       
        // event create request validator
        emit AlertCreateRequestValidator(
            _msgSender(),
            _idKnight
        );    
    }

    // @title Normal node cancels its validator candidate request 
    function cancelRequestValidator(uint256 indexOfRequest)
        external
        onlyNormalNode
    {
        require(
            isExitedActiveValidatorCandidateRequest(indexOfRequest),
            "REQUEST NOT EXIST OR REQUEST HAS BEEN PROCESSED."
        );

        // send back money to user
        TransferHelper.safeTransfer(
            address(animaTokenAddress),
            _msgSender(),
            feeToBecomeValidatorCandidate
        );

        // update request status
        validatorCandidateRequestList[indexOfRequest].status = Status.Canceled;
        validatorCandidateRequestList[indexOfRequest].endBlock = block.number;

        // event create request to validator of normal node
        emit AlertCreateRequestValidator(
            _msgSender(),
            indexOfRequest
        );
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
            isValidatorCandidate(_addressValidatorCandidate),
            "THE ADDRESS IS NOT A VALIDATOR CANDIDATE."
        );

        require(
            _idKnight >= 1 && _idKnight <= KNIGHT_NUMBER,
            "THIS KNIGHT DOES NOT EXIST."
        );
        
        checkAndUpdateQueenVotingFlag();
        if (isQueenVoting) {
            revert("QUEEN'S TERM HAS EXPIRED.");
        }

        appointNewKnight(_idKnight, _addressValidatorCandidate);

        // event appoint and dismiss knight
        emit AlertAppointAndDismissKnight(
            currentQueen.queenAddr,
            _addressValidatorCandidate,
            _idKnight
        );
    }

    /*
     @title Approve And Reject Request Validator
     @param indexOfRequest id of request
     @param Approve and Reject request of validator
    */
    function approveAndRejectRequestValidator(
        uint256 indexOfRequest,
        bool isApprove
    )
        external
        onlyKnight
    {
        // check request by id
        require(
            isExitedActiveValidatorCandidateRequestToKnight(indexOfRequest),
            "VALIDATOR CANDIDATE REQUEST IS NOT ACTIVE OR REQUESTED KNIGHT IS NOT TRUE."
        );
        
        // get index of knight in current knight list and knight list
        (uint256 _indexKnightInCurrentKnight, uint256 _indexKnightInKnightList) = 
            getPositionOfKnightInKnightListandCurrentKnight(_msgSender());
        
        checkAndUpdateQueenVotingFlag();
        if (isQueenVoting) {
            revert("QUEEN'S TERM HAS EXPIRED.");
        }

        if (isApprove) {
            // approve normal node to validator candiate  
            approveRequestValidator(
                _indexKnightInCurrentKnight,
                _indexKnightInKnightList,
                indexOfRequest
            );

            // add status request when validator candidate appointed    
            addStatusRequestList(
                validatorCandidateRequestList[indexOfRequest].requester,
                StatusRequest.ValidatorCandidateApproved
            );
        } else {
            // reject normal node to validator candiate      
            rejectRequestValidator(indexOfRequest);

            // add status request when validator candidate dismiss  
            addStatusRequestList(
                validatorCandidateRequestList[indexOfRequest].requester,
                StatusRequest.ValidatorCandidateRejected
            );
        }

        // set endBlock for validator candidate request list
        validatorCandidateRequestList[indexOfRequest].endBlock = block.number;

        // event appoint and reject normal become to validater
        emit AlertApproveAndRejectRequestValidator(
            _msgSender(),
            validatorCandidateRequestList[indexOfRequest].requester,
            isApprove
        );
    }

    // @code 4.2. Knight: Queen Dismiss Voting
    // @title Knight vote Dismiss Queen
    // @param Approve to dismiss Queen or not?
    function queenDismissVoting(bool _isTrust)
        external
        onlyKnight
        onlyQueenVotingNotNow
    {
        (uint256 _indexKnightInCurrentKnight, ) = 
            getPositionOfKnightInKnightListandCurrentKnight(_msgSender());

        require(
            currentKnightList[_indexKnightInCurrentKnight].isTrustQueen != _isTrust,
            "THIS STATUS IS ALREADY EXISTED."
        );

        // initialise
        if (currentQueenDismissVoting.dismissBlock != 0 || currentQueenDismissVoting.termNo == 0) {
            indexQueenDismissVoting.increment();
            currentQueenDismissVoting.termNo = currentQueen.termNo;
        }

        setStatusIsTrustQueen(_isTrust, _indexKnightInCurrentKnight);
        // QUEEN_DISMISS_DISMISS_LEVEL
        if (currentQueenDismissVoting.queenTrustlessList.length >= 4) {

            // turn on flag isQueenVoting
            isQueenVoting = true;

            // dismiss queen
            executeQueenDismiss();

            // update current vote then add it into the list
            currentQueenDismissVoting.dismissBlock = block.number;
            queenDismissVotingList[indexQueenDismissVoting.current()] = currentQueenDismissVoting;

            // set default current queen dismissvoting
            QueenDismissVoting memory queenDismissVotingTemporary;
            currentQueenDismissVoting = queenDismissVotingTemporary;

            // reset status is trust knight in current knight list
            for(uint256 i = 1; i <= KNIGHT_NUMBER; i++) {
                currentKnightList[i].isTrustQueen = true;
            }
        }

        emit AlertQueenVoting(
            _msgSender(),
            "VOTED SUCESSFULL."
        );
    }

    // @code 4.0. queenVoting
    // @title Elect new queen instead, delete old queen
    // @param Address of validator candidate
    function queenVoting(address _validatorCandidaterAddress)
        external
        onlyKnight
    {
        checkAndUpdateQueenVotingFlag();

        if(!isQueenVoting) {
            emit AlertQueenVoting(
                _validatorCandidaterAddress,
                currentQueen.queenAddr,
                "THERE IS NO QUEEN VOTING NOW"
            );

            return;
        }

        require(
            isValidatorCandidate(_validatorCandidaterAddress),
            "CAN'T VOTE FOR NORMAL NODE."
        );

        if (
            _validatorCandidaterAddress == currentQueen.queenAddr &&
            currentQueen.countConsecutiveTerm >= MAX_CONSECUTIVE_TERM) 
        {
            revert("PROPOSED ADDRESS IS DOING 2ND CONSECUTIVE TERM, CAN NOT VOTE FOR 3ND TERM.");
        }

        require(
            !isNeedToAppointNewKnight,
            "IN THE PROCESS OF VOTING FOR A NEW KNIGHT."
        );
        
        // initilise
        if (queenVotingList[indexQueenVoting.current()].startVoteBlock == 0) {
            indexQueenVoting.increment();
            queenVotingList[indexQueenVoting.current()].index = indexQueenVoting.current();
            queenVotingList[indexQueenVoting.current()].termNo = currentQueen.termNo;
            queenVotingList[indexQueenVoting.current()].startVoteBlock = block.number;
        }

        QueenVoting storage currentQueenVoting = queenVotingList[indexQueenVoting.current()];

         // add informastion for queen voting history
        queenVotingHistory[_msgSender()].push(
            QueenVotingHistory(
                currentQueen.queenAddr,
                currentQueen.startTermBlock,
                currentQueen.endTermBlock,
                currentQueenVoting.proposedList[_validatorCandidaterAddress].length,
                true
            )
        );
        
        // not allow a knight vote for the same validator candidate more than 1 times
        for (uint256 i = 0; i < currentQueenVoting.proposedList[_validatorCandidaterAddress].length; i++) {
            if (currentQueenVoting.proposedList[_validatorCandidaterAddress][i] == _msgSender()) {
                revert("YOU CAN NOT VOTE FOR THE SAME ACCOUNT MORE THAN 1 TIME.");
            }
        }

        // remove old record from the list if the Knight has voted before
        for(uint256 i = 0; i < currentQueenVoting.candidateList.length; i++) {
            for (uint256 j = 0; j < currentQueenVoting.proposedList[currentQueenVoting.candidateList[i]].length; j++) {
                if (currentQueenVoting.proposedList[currentQueenVoting.candidateList[i]][j] == _msgSender()) {
                    currentQueenVoting.proposedList[currentQueenVoting.candidateList[i]][j] = 
                    currentQueenVoting.proposedList[currentQueenVoting.candidateList[i]][
                        currentQueenVoting.proposedList[currentQueenVoting.candidateList[i]].length.sub(1)
                    ];
                    currentQueenVoting.proposedList[currentQueenVoting.candidateList[i]].pop();
                    break;
                }
            }
        }

        // add vote to the list
        currentQueenVoting.proposedList[_validatorCandidaterAddress].push(
            _msgSender()
        );

        // check status propose in candidate list
        bool statusCandidateAddressIfExits = false;
        for(uint256 i = 0; i < currentQueenVoting.candidateList.length; i++) {
            if(_validatorCandidaterAddress == currentQueenVoting.candidateList[i]) {
                statusCandidateAddressIfExits = true;
                break;
            }
        }
        // add propose queen to candidateList
        if(!statusCandidateAddressIfExits) {
            currentQueenVoting.candidateList.push(_validatorCandidaterAddress);
        }

        for(uint256 i = 0; i < currentQueenVoting.candidateList.length; i++) {
             if(currentQueenVoting.proposedList[currentQueenVoting.candidateList[i]].length == 0) {
                currentQueenVoting.candidateList[i] = currentQueenVoting.candidateList[
                    currentQueenVoting.candidateList.length.sub(1)
                ];
                currentQueenVoting.candidateList.pop();
            }
        }

        checkVoteNumberAndAppointNewQueen(_validatorCandidaterAddress);

        emit AlertQueenVoting(
            _validatorCandidaterAddress,
            currentQueen.queenAddr,
            "VOTE QUEEN DISMISS SUCCESSED"
        );
    }

    // @title Appoint new knight, only Queen can call this function
    // @param Address of new Validator Candidate
    function appointKnightInQueenVotingProcess(
        uint256 _indexOfKnight,
        address _newValidatorCandidaterAddress
    )
        external
        onlyQueen
        onlyIndexKnight(_indexOfKnight)
    {
        require(
            isNeedToAppointNewKnight,
            "CHECK APPOINT NEW KNIGHT FOR QUEENVOTING MUST BE ACTIVATE."
        );

        require(
            currentKnightList[_indexOfKnight].startTermBlock != 0,
            "INDEX OF KNIGHT IS INVALID."
        );

        require(
            isValidatorCandidateExceptQueenAndKnight(_newValidatorCandidaterAddress),
            "ONLY VALIDATOR CANDIDATE (EXCEPT QUEEN AND KNIGHTS) CAN RELACE NEW KNIGHT."
        );

        // add new knight to current knight list 
        currentKnightList[_indexOfKnight] = Knight(
            _newValidatorCandidaterAddress,
            _indexOfKnight,
            knightList.length,
            0,
            block.number,
            0,
            currentQueen.termNo,
            currentKnightList[_indexOfKnight].appointedValidatorCandidateList,
            true
        );
        // add new knight to knight list
        knightList.push(currentKnightList[_indexOfKnight]);

        // update system flag
        isNeedToAppointNewKnight = false;
        isQueenVoting = false;

        // add status request wheen knight appoint
        addStatusRequestList(
            _newValidatorCandidaterAddress,
            StatusRequest.KnightAppoint
        );

        emit AlertAddNewKnight(
            _newValidatorCandidaterAddress,
            currentQueen.queenAddr,
            block.number,
            currentQueen.termNo
        );
    }
    
    // @title Set fee to become validator candidate
    // @param Fee To Become Validator
    function setFeeToBecomeValidatorCandidate(uint256 _feeToBecomeVakidatorCandidate)
        public
        onlyQueen
    {    
        feeToBecomeValidatorCandidate = _feeToBecomeVakidatorCandidate;
    }

    // @title Set address Anicana token
    // @param Address of ANM Token
    function setAnicanaTokenAddress(address _animaTokenAddress)
        public
        onlyQueen
    {
        require(
            address(animaTokenAddress) == address(0), 
            "ANIMA TOKEN ADDRESS HAS BEEN SET, JUST SET ONLY ONE."
        );

        animaTokenAddress = IERC20(_animaTokenAddress);
    }

    // @title Set ANMPool address
    // param address of ANM pool
    function setANMpool(address _ANMPoolAddress) public onlyQueen {
        require(
            ANMPoolAddress == address(0), 
            "ANM POOL HAS BEEN SET, JUST SET ONLY ONE."
        );

        ANMPoolAddress = _ANMPoolAddress;
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
        // add status request
        addStatusRequestList(_validatorCandidateAddress, _statusRequest);
        
        // link a validator candidate to the knight who has appointed it
        
        currentKnightList[_indexAppointed].appointedValidatorCandidateList.push(_validatorCandidateAddress);

        // add new one into validator candidate request list
        indexValidatorCandidateRequest.increment();

        // add new validator candidate request
        validatorCandidateRequestList[indexValidatorCandidateRequest.current()] = ValidatorCandidateRequest(
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
    function sendRewardAndUpdateTotalReward(
        address _validatorAddr,
        uint256 _reward
    ) internal {
        uint256 valueTransferForQueen = _reward.div(6);
        uint256 valueTransferForKnight = _reward.sub(valueTransferForQueen);
        
        // send reward to knight
        TransferHelper.safeTransfer(
            address(animaTokenAddress),
            address(_validatorAddr),
            valueTransferForKnight
        );
        
        // send reward to queen
        TransferHelper.safeTransfer(
            address(animaTokenAddress),
            address(currentQueen.queenAddr),
            valueTransferForQueen
        );

        if (!isQueen(_validatorAddr)) {
            // update reward for queen
            currentQueen.totalRewards += valueTransferForQueen;

            // update reward for knight
            (uint256 _indexKnightInCurrentKnight, ) = 
                getPositionOfKnightInKnightListandCurrentKnight(_validatorAddr);
            currentKnightList[_indexKnightInCurrentKnight].totalRewards += valueTransferForKnight;
        } else {
            currentQueen.totalRewards += _reward;
        }
    }

    // @title Set status knight Trust Queen
    // @param status true or false
    function setStatusIsTrustQueen(
        bool _isTrustQueen,
        uint256 _indexKnightInCurrentKnight
    ) internal {   
        if (!_isTrustQueen) {
            currentKnightList[_indexKnightInCurrentKnight].isTrustQueen = false;
            currentQueenDismissVoting.queenTrustlessList.push(_msgSender());

            return;
        }

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

        return;
    }

    // @title Appointed new Queen
    // @param Address of Validator Candidate
    function checkVoteNumberAndAppointNewQueen(address _validatorCandidaterAddress)
        internal
    {   
        //REQUIRED_VOTE_NUMBER_TO_BECOME_NEW_QUEEN
        if (queenVotingList[indexQueenVoting.current()].proposedList[_validatorCandidaterAddress].length < 2) {
            emit AlertQueenVoting(
                _validatorCandidaterAddress,
                currentQueen.queenAddr,
                "VOTE QUEEN DISMISS SUCCESSED"
            );

            return;
        }

        
        // find the validator candidate's address to replace the knight when the candidate is a knight
        // set trigger when the new queen is the address of the old forget 
        if (isKnight(_validatorCandidaterAddress)) {
            (uint256 _indexKnightInCurrentKnight, uint256 _indexKnightInKnightList) = 
                getPositionOfKnightInKnightListandCurrentKnight(_validatorCandidaterAddress);

            // delete current knight and update knight list     
            delete currentKnightList[_indexKnightInCurrentKnight];
            knightList[_indexKnightInKnightList].endTermBlock = block.number;

            // activate trigger prepare add new knight    
            isNeedToAppointNewKnight = true;

            // event queen voting has not been completed
            emit AlertQueenVoting(
                _validatorCandidaterAddress,
                currentQueen.queenAddr,
                "QUEEN VOTING IS SUCCESS, BUT QUEEN NEED TO APPOINT A NEW KNIGHT."
            );

            // update information of queen appointed and queen dismissed
            updateNewQueen(_validatorCandidaterAddress);

            return;
        } 

        // update information of queen appointed and queen dismissed
        updateNewQueen(_validatorCandidaterAddress);

        isQueenVoting = false;

        //  event queen voting successful
        emit AlertQueenVoting(
            _validatorCandidaterAddress,
            currentQueen.queenAddr,
            "QUEEN VOTING IS SUCCESS."
        );  
    }

    // @title Update new Queen
    function updateNewQueen(address _newQueen)
        internal
    {
        // temporary variable to store the current queen's information
        Queen memory queenCurrentTemporary = currentQueen;

        // total reward of queen after update
        uint256 totalRewardsForNewQueen;

        // set default count consecutive term of new queen
        uint256 countConsecutiveTermForNewQueen = 1;
        
        // update old queen
        queenList[getIndexQueenOfQueenList(currentQueen.queenAddr)].endTermBlock = block.number;

        if (_newQueen == queenList[queenList.length.sub(1)].queenAddr) {
            // update countConsecutiveTerm for current queen
            countConsecutiveTermForNewQueen = 2;

        } else {
            // add status request wheen queen dismiss
            addStatusRequestList(
                currentQueen.queenAddr,
                StatusRequest.QueenDismiss
            );
        }

        // add status request while the queen appoints
        addStatusRequestList(
            _newQueen,
            StatusRequest.QueenAppoint
        );
        
        // updatte new queen
        currentQueen = Queen(
            _newQueen,
            0,
            block.number,
            block.number + QUEEN_TERM_PERIOD_BY_BLOCK_NUMBER,
            currentQueen.termNo.add(1),
            countConsecutiveTermForNewQueen
        );
        
        // add new queen to queen list
        queenList.push(currentQueen);
    }

    // @title Add status request list
    // @param Address of requester
    // @param Status of request
    function addStatusRequestList(
        address _ownerRequest,
        StatusRequest _statusRequest
    ) internal {
        statusRequestList[_ownerRequest].push(
            StatusRequestAndTime(_statusRequest, block.number)
        );
    }

    // @title check if an address is queen or not
    // @param Address of Queen
    function isQueen(address _queenAddress) public view returns (bool) {
        if (checkTitleAddress(_queenAddress) == 1) {
            return true;
        }

        return false;
    }

    // @title check if an address is a knight or not
    // @param Address of Knight
    function isKnight(address _knightAddress) public view returns (bool) {
        if (checkTitleAddress(_knightAddress) == 2) {
            return true;
        }

        return false;
    }

    // @title check status of Validator
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

    // @title Check if an address is a Validator Candidate or not
    // @param Address of Validator Candidate
    // return true or false
    function isValidatorCandidate(address _validatorCandidateAddress)
        public
        view
        returns (bool)
    {
        if (
            checkTitleAddress(_validatorCandidateAddress) == 1 ||
            checkTitleAddress(_validatorCandidateAddress) == 2 ||
            checkTitleAddress(_validatorCandidateAddress) == 3
        ) {
            return true;
        }

        return false;
    }

    // @title Check if an address is a Validator Candidate except Queen, Knight or not
    // @param Address of Validator Candidate
    // return true or false
    function isValidatorCandidateExceptQueenAndKnight(address _validatorAddress)
        public
        view
        returns (bool)
    {
        if (checkTitleAddress(_validatorAddress) == 3) {
            return true;
        }

        return false;
    }

    // @title Check if an address is a normal node or not
    // @param Address
    // return true or false
    function isNormalNode(address _address)
        public
        view
        returns (bool)
    {
        if (checkTitleAddress(_address) == 4) {
            return true;
        }

        return false;
    }

    // @title checkAndUpdateQueenVotingFlag check/set status queen voting 
    function checkAndUpdateQueenVotingFlag() internal  {
        if (isQueenVoting == true) {
            return;
        }

        if (currentQueen.endTermBlock < block.number) {
            // update system flag
            isQueenVoting = true;

            // dismiss queen
            executeQueenDismiss();

            return;
        }

        return;
    }

    /*
     @title Queen Dismiss
     @param Index of Knight
     @param Address of Validator Candidate
    */
    function executeQueenDismiss() internal {
        // set queen end time in queen list 
        queenList[getIndexQueenOfQueenList(currentQueen.queenAddr)].endTermBlock = block.number;
      
        //set default value for current queen
        Queen memory queen;
        currentQueen = queen;
    }

    /*
     @title Queen Appointed Knight
     @param Index of Knight
     @param Address of Validator Candidate
    */
    function appointNewKnight(
        uint256 _idKnight,
        address _addressValidatorCandidate
    ) internal onlyIndexKnight(_idKnight) 
    {
        // get index of knight in knight list
        ( , uint256 _indexKnightInKnightList) 
            = getPositionOfKnightInKnightListandCurrentKnight(
                currentKnightList[_idKnight].knightAddr
            );
        
        // set end time for knight of knight list
        knightList[_indexKnightInKnightList].endTermBlock = block.number;

        // add status request wheen knight dismiss
        addNewStatusAppointAndDismiss(
            currentKnightList[_idKnight].knightAddr,
            _idKnight,
            block.number,
            false,
            StatusRequest.KnightDismiss
        );
        
        // add new knight to current knight list
        currentKnightList[_idKnight] = Knight(
            _addressValidatorCandidate,
            _idKnight,
            knightList.length.sub(1),
            0,
            block.number,
            0,
            currentQueen.termNo,
            currentKnightList[_idKnight].appointedValidatorCandidateList,
            true
        );

        // add new knight to knight list
        knightList.push(currentKnightList[_idKnight]);

        // add status request when knight appointed
        addNewStatusAppointAndDismiss(
            _addressValidatorCandidate,
            _idKnight,
            block.number,
            true,
            StatusRequest.KnightAppoint
        );        
    }

    //@title add new status appoint/dismiss of knight and status request of normal node
    function addNewStatusAppointAndDismiss(
        address _knightAddress, 
        uint256 _assignNumber, 
        uint256 _blockCreate, 
        bool _appointAndDismiss,
        StatusRequest _statusRequest
    ) internal { 
        // add new status appoint and dismiss of knight
        statusAppointAndDismiss.push(
            StatusAppointAndDismiss(
                _knightAddress,
                _assignNumber,
                _blockCreate,
                _appointAndDismiss
            )
        );
       // status request of normal node
        addStatusRequestList(
            _knightAddress,
            StatusRequest.KnightAppoint
        );
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
        // add new validator candidate to validator candidate list
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
        
        // add address normal node to appointed validator candidate list 
        currentKnightList[_knightNo].appointedValidatorCandidateList.push(
            validatorCandidateRequestList[_indexRequest].requester
        );

        // burn token that user deposited
        animaTokenAddress.burn(validatorCandidateRequestList[_indexRequest].paidCoin);

        // set approve status from validator candidate requestList
        validatorCandidateRequestList[_indexRequest].status = Status.Approved;
    }

    // @title Knight rejected validator's request
    // @param index Request
    function rejectRequestValidator(uint256 _indexRequest)
        internal
    {
        // deposit the requested number of tokens when making the request 
        TransferHelper.safeTransfer(
            address(animaTokenAddress),
            validatorCandidateRequestList[_indexRequest].requester,
            validatorCandidateRequestList[_indexRequest].paidCoin
        );
        
        // set status rejected in validator candidate requestList
        validatorCandidateRequestList[_indexRequest].status = Status.Rejected;
    }
     
    //@title get stutus appoint and dismiss of knight
    function getStatusAppointAndDismiss() 
        public
        view 
        returns(StatusAppointAndDismiss[] memory) 
    {
        return statusAppointAndDismiss;
    }

    //@title get the knight's past voting information
    function getKnightVoteHistory() 
       public
       view
       onlyKnight
       returns (QueenVotingHistory[] memory)  
    {
        return queenVotingHistory[_msgSender()];
    }

    /*
     @title Returns the addresses that voted dismissQueen
     return addresses that voted dismissQueen
    */
    function getTotalTrustlessNumberAndQueenTrustlessStatus()
        public
        view
        onlyKnight
        returns (address[] memory, bool)
    {
        for(uint256 i = 0; i < currentQueenDismissVoting.queenTrustlessList.length; i++){
            if(_msgSender() == currentQueenDismissVoting.queenTrustlessList[i]){
                return (currentQueenDismissVoting.queenTrustlessList, false);
            }
        }
        return (currentQueenDismissVoting.queenTrustlessList, true);
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

    // @title get current list address proposed list
    function getCurrentListAddressProposedList(uint256 _indexQueenVoting, address _validatorAddrress)
        public
        view
        returns (address[] memory)
    {   
       
        return queenVotingList[_indexQueenVoting].proposedList[_validatorAddrress];
    }

    // @title get the information of candidates who can become queen
    function getCurrentCandidateListInVoteNewQueen() 
        public 
        view 
        returns(address[] memory) 
    {
        return queenVotingList[indexQueenVoting.current()].candidateList;
    }

    //@title Returns the addresses that voted Queen
    //@param Address of Validator Candidate
    function getListAddressProposedListFromIndexVoting(
        address _validatorCandidaterAddress,
        uint256 _indexQueenVoting
    )
        public
        view
        returns (address[] memory)
    {
        return queenVotingList[_indexQueenVoting].proposedList[_validatorCandidaterAddress];
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

        return 0;
    }

    // @title check validator candidate request is active or not?
    // @param Index of request
    function isExitedActiveValidatorCandidateRequestToKnight(
        uint256 indexOfRequest
    ) public view returns (bool) {
        (uint256 _indexKnightInCurrentKnight,) = 
            getPositionOfKnightInKnightListandCurrentKnight(_msgSender());

        if (
            validatorCandidateRequestList[indexOfRequest].knightNo == _indexKnightInCurrentKnight &&
            validatorCandidateRequestList[indexOfRequest].status == Status.Requested
        ) {
            return true;
        }

        return false;
    }

    // @title Count the number of Validator Candidate in the array
    // return number of Validator Candidate
    function countNumberValidatorCandiadate() public view returns (uint256) {
        uint256 numberValidatorCandiadate = 0;
        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (
                !isValidator(validatorCandidateList[i].validatorCandidateAddr)
            ) {
                numberValidatorCandiadate++;
            }
        }

        return numberValidatorCandiadate;
    }
    
    // @title Check title of an address
    // @param Address
    // return Number to determine the title of the address
    function checkTitleAddress(address _address)
        public
        view
        returns (uint256) 
    {
        require(
            _address != address(0), 
            "ADDRESS MUST BE DIFFERENT 0."
        );

        // check queen
        if (_address == currentQueen.queenAddr) {
            return 1;
        }

        // check knight
        for (uint256 i = 1; i <= KNIGHT_NUMBER; i++) {
            if (_address == currentKnightList[i].knightAddr) {
                return 2;
            }
        }

        // check validator candidate
        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (_address == validatorCandidateList[i].validatorCandidateAddr) {
                return 3;
            }
        }

        // normal node
        return 4;
    }

    // @title Return status request of Validator Candidate
    // @param Address of Validator Candidate 
    function getStatusRequestOfVaidatorCandidate(
        address _validatorCandidateAddress
    ) public view returns (StatusRequestAndTime[] memory) {
        return statusRequestList[_validatorCandidateAddress];
    }

    // @title Return the fee payable to become validator
    function getFeeBeComeToValidatorCandidate() public view returns (uint256) {
        return feeToBecomeValidatorCandidate;
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
        address[] memory knightAddress = new address[](KNIGHT_NUMBER);
        uint256[] memory knightIndex = new uint256[](KNIGHT_NUMBER);
        uint256[] memory knightStartTermBlock = new uint256[](KNIGHT_NUMBER);

        for(uint i = 1; i <= KNIGHT_NUMBER; i++) {
            knightAddress[i-1] = currentKnightList[i].knightAddr;
            knightIndex[i-1] = currentKnightList[i].index;
            knightStartTermBlock[i-1] = currentKnightList[i].startTermBlock;
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
    //@title count number validator candidate    
        uint256 countNumberValidator = countNumberValidatorCandiadate();
    
        address[] memory validatorCandidateAddress = new address[](countNumberValidator);
        uint256[] memory validatorCandidateIndex = new uint256[](countNumberValidator);
        uint256[] memory validatorCandidateStartTermBlock = new uint256[](countNumberValidator);

    //@title count index validator candidate and diffirent validator
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
        
        // count number pending request
        for (uint256 i = 1; i <= indexValidatorCandidateRequest.current(); i++) {
            if (
                validatorCandidateRequestList[i].status == Status.Requested &&
                validatorCandidateRequestList[i].knightNo == _idKnight
            ) {
                amountRequestPending++;
            } 
        }

        address[] memory addressPendingRequestList = new address[](amountRequestPending);
        uint256[] memory startPendingRequestList = new uint256[](amountRequestPending);

        // index pending request 
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
    function getApprovedRequestsKnight(uint256 _idKnight)
        public
        view
        onlyIndexKnight(_idKnight)
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 amountApproveRequestsKnight = currentKnightList[_idKnight].appointedValidatorCandidateList.length;

        uint256[] memory dateRequestsBecomeValidatorCandidate = new uint256[](amountApproveRequestsKnight);
        uint256[] memory dateBecomeValidatorCandidate = new uint256[](amountApproveRequestsKnight);
        uint256[] memory knightNoOfValidatorCandidate = new uint256[](amountApproveRequestsKnight);

        for (uint256 i = 0; i < amountApproveRequestsKnight; i++) {
            for (uint256 j = 1; j <= indexValidatorCandidateRequest.current();j++) {
                if (
                    currentKnightList[_idKnight].appointedValidatorCandidateList[i] == validatorCandidateRequestList[j].requester
                ) {
                    dateRequestsBecomeValidatorCandidate[i] = validatorCandidateRequestList[j].createdBlock;
                    dateBecomeValidatorCandidate[i] = validatorCandidateRequestList[j].endBlock;
                    knightNoOfValidatorCandidate[i] = validatorCandidateRequestList[j].knightNo;
                    break;
                }
            }
        }
        return (
            currentKnightList[_idKnight].appointedValidatorCandidateList,
            dateRequestsBecomeValidatorCandidate,
            dateBecomeValidatorCandidate,
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
    function getPositionOfKnightInKnightListandCurrentKnight(address _knightAddress)
        public
        view
        returns (uint256, uint256)
    {
        uint256 _indexKnightInCurrentKnight;
        uint256 _indexKnightInKnightList;

        // get index of knight in current knight list
        for (uint256 i = 1; i <= KNIGHT_NUMBER; i++) {
            if (currentKnightList[i].knightAddr == _knightAddress) {
                _indexKnightInCurrentKnight = i;
                break;
            }
        }
        
        // get index of knight in knight list
        for (uint256 i = 0; i < knightList.length; i++) {
            if (knightList[i].knightAddr == _knightAddress) {
                _indexKnightInKnightList = i;
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
        
        // get current index of validator request
        for (uint256 i = indexValidatorCandidateRequest.current(); i >= 1; i--) {
            if (
                validatorCandidateRequestList[i].requester == _validatorCandidateAddresss
            ) {
                return i;
            }
        }
    }

    // @title check validator candidate request is active or not?
    function isExitedActiveValidatorCandidateRequest(uint256 indexOfRequest)
        public
        view
        returns (bool) 
    {
        // if indexOfRequest has value, find corresponding record then check
        if (indexOfRequest != 0) {
            if (
                validatorCandidateRequestList[indexOfRequest].requester == _msgSender() &&
                validatorCandidateRequestList[indexOfRequest].status == Status.Requested
            ) {
                return true;
            } else {
                return false;
            }
        }

        // if indexOfRequest is 0, find all records of sender then check
        for (uint256 j = indexValidatorCandidateRequest.current(); j >= 1; j--) {
            if (
                validatorCandidateRequestList[j].requester == _msgSender() &&
                validatorCandidateRequestList[j].status == Status.Requested
            ) {
                return true;
            }
        }
        
        return false;
    }
}