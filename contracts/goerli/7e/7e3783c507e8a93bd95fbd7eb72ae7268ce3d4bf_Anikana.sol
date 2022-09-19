// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ValidatorSmartContractInterface.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract Anikana is ValidatorSmartContractInterface, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // @param currentQueen save current Queen is currently in tenure
    Queen public currentQueen;
    // @param queenList save queen List from past to present
    Queen[] public queenList;
    // @param currentQueenVoting Save election information to remove the current queen
    QueenVoting public currentQueenVoting;
    /*
    @param queenVotingList save all election information to recall the queen so far and
    retrieved by voting sequence number
    */
    mapping(uint256 => QueenVoting) public queenVotingList;
    // @param indexQueenVoting count the number of votes
    Counters.Counter public indexQueenVoting;
    // @param isQueenVoting save new queen election status
    bool public isQueenVoting;
    // @param currentQueenDismissVoting save new queen election status
    QueenDismissVoting public currentQueenDismissVoting;
    // @param queenDismissVotingList save election state to create new queen election new queen
    mapping(uint256 => QueenDismissVoting) public queenDismissVotingList;
    // @param queenDismissVotingList save election state to create new queen election new queen
    Counters.Counter public indexQueenDismissVoting;
    /*
     @param currentKnightList store all the knight's information so far and retrieve it with the
    knight's id of array
    */
    mapping(uint256 => Knight) public currentKnightList;
    // @param knightList store the knight's information in its entirety and retrieve it by the knight's id
    Knight[] public knightList;
    // @param isNeedToAppointNewKnight Status of adding a new knight to the Knight List and current Knight array
    bool public isNeedToAppointNewKnight;
    // @param validatorCandidateList store all information including currentKinght and currentQueen and validatorCandidate
    ValidatorCandidate[] public validatorCandidateList;
    // @param validatorCandidateRequestList Store all information of the normal node that sends the request as a ValidatorCandidate
    mapping(uint256 => ValidatorCandidateRequest)
        public validatorCandidateRequestList;
    // @param indexValidatorCandidateRequest count the number of times normal node send the request as a ValidatorCandidate
    Counters.Counter public indexValidatorCandidateRequest;
    // @param feeToBecomeValidator required fee to be promoted to validatorCandidate
    uint256 private feeToBecomeValidator = 100 ether;
    // @param anikanaAddress address token anikana
    IERC20 private anikanaAddress =
        IERC20(0x251413D794D145090DC7978A07C2d81716285ad6);
    // @param status initial og knight - queen - validatorCandidate
    uint256 private termStart = 1;
    // @param blockSpace to limit queen =>> APPLY FOR GOERLI TESTNET <<==
    uint256 private blockSpace = 5256000;
    //
    event AlertAmountTrustlessQueen(address indexed _knightAddrr);
    event AlertVotingToOrganizationForQueenDismissVote(
        address indexed _knightAddress,
        string _message
    );
    event AlertQueenDismissVoting(
        address indexed _validatorCandidate,
        address _queenAddres,
        string _message
    );
    event AlertAddNewKnight(
        address indexed _knightAddr,
        address _queenTermNoAddr,
        uint256 _timeAddNewQueen,
        uint256 _queenTermNo
    );

    struct Queen {
        address queenAddr;
        uint256 totalRewards;
        uint256 startTermBlock;
        uint256 endTermBlock;
        uint256 termNo;
        uint256 countTerm;
    }

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

    struct ValidatorCandidate {
        address validatorCandidateAddr;
        uint256 knightNo;
        uint256 knightTermNo;
        uint256 startTermBlock;
        uint256 endTermBlock;
        uint256 paidCoin;
    }

    struct QueenVoting {
        uint256 index;
        uint256 termNo;
        uint256 startVoteBlock;
        uint256 endVoteBlock;
        mapping(address => address[]) proposedList;
    }

    struct QueenDismissVoting {
        uint256 index;
        uint256 termNo;
        uint256 dismissBlock;
        address[] queenTrustlessList;
    }

    struct ValidatorCandidateRequest {
        Status status;
        uint256 knightNo;
        uint256 knightTermNo;
        uint256 createdBlock;
        uint256 endBlock;
        uint256 paidCoin;
        address requester;
    }

    enum Status {
        Requested,
        Canceled,
        Approved,
        Rejected
    }

    modifier onlyPool() {
        require(
            _msgSender() == address(owner()),
            "ONLY POOL CALL FUNCTION, PLEASE CHECK YOUR ADDRESS."
        );
        _;
    }

    modifier onlyQueen() {
        require(
            _msgSender() == currentQueen.queenAddr,
            "ONLY QUEEN CALL FUNCTION, PLEASE CHECK YOUR ADDRESS."
        );
        _;
    }

    modifier onlyNormalNode() {
        require(
            !checkNormalNode(_msgSender()),
            "ADDRESS USER IS NOT A NORMAL NODE, CANNOT REQUEST AS VALIDATOR."
        );
        _;
    }

    modifier onlyIndexKnight(uint256 _idKnight) {
        require(
            _idKnight <= countNumberKnight() && _idKnight > 0,
            "ID OF KNIGHIT NOT EXIST."
        );
        _;
    }

    modifier onlyKnight() {
        require(
            isKnight(_msgSender()),
            "ONLY KNIGHT CAN CALL, PLEASE CHECK YOUR ADDRESS."
        );
        _;
    }

    modifier onlyQueenVotingNotNow() {
        require(
            !isQueenVoting,
            "QUEEN HAS BEEN DISMISSED, YOU CANNOT TAKE THIS ACTION."
        );
        _;
    }

    modifier voteOnlyOnce(address _validatorCandidaterAddress) {
        require(
            _validatorCandidaterAddress != _msgSender(),
            "KNIGHT CAN'T VOTE FOR HIMSELF, PLEASE CHECK YOUR ADDRESS."
        );
        _;
    }

    //
    constructor(
        address[] memory initialKnight,
        address[] memory initialValdators
    ) public {
        require(initialKnight.length > 0, "NO INITIAL QUEEN ACCOUNTS");
        currentQueen = Queen(
            initialKnight[0],
            0,
            block.number,
            block.number + blockSpace,
            termStart,
            termStart
        );
        queenList.push(currentQueen);
        validatorCandidateList.push(
            ValidatorCandidate(currentQueen.queenAddr, 0, 0, block.number, 0, 0)
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
                termStart,
                appointedValidatorListTemporary,
                true
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

    function distributeRewards(address _validatorAddr, uint256 _reward)
        external
        onlyPool
    {
        require(
            checkTitleAddress(_validatorAddr) == 1 ||
                checkTitleAddress(_validatorAddr) == 2,
            "ONLY VALIDATOR CAN CALL THIS FUNCTION"
        );
        require(
            checkStatusOfValidatorAddress(_validatorAddr),
            "ADDRESS VALIDATOR DON'T NOT EXIST."
        );
        uint256 balanceOfSender = anikanaAddress.balanceOf(_msgSender());
        require(balanceOfSender >= _reward, "BALANCE INSURANCE");
        require(
            address(anikanaAddress) != address(0),
            "TOKEN ANIKANA NOT SET."
        );
        if (isQueenVoting == false) {
            if (currentQueen.endTermBlock > block.number) {
                updateTotalRewardOfValidator(_validatorAddr, _reward);
            } else {
                isQueenVoting = true;
                TransferHelper.safeTransferFrom(
                    address(anikanaAddress),
                    _msgSender(),
                    address(this),
                    _reward
                );
                anikanaAddress.burn(_reward);
            }
        } else {
            TransferHelper.safeTransferFrom(
                address(anikanaAddress),
                _msgSender(),
                address(this),
                _reward
            );
            anikanaAddress.burn(_reward);
        }
    }

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
            address(anikanaAddress) != address(0),
            "TOKEN ANIKANA NOT SET."
        );
        TransferHelper.safeTransferFrom(
            address(anikanaAddress),
            _msgSender(),
            address(this),
            feeToBecomeValidator
        );
        indexValidatorCandidateRequest.increment();
        validatorCandidateRequestList[
            indexValidatorCandidateRequest.current()
        ] = ValidatorCandidateRequest(
            Status.Requested,
            _idKnight,
            currentKnightList[_idKnight].termNo,
            block.number,
            0,
            feeToBecomeValidator,
            _msgSender()
        );
    }

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
            address(anikanaAddress),
            _msgSender(),
            feeToBecomeValidator
        );
        validatorCandidateRequestList[indexOfRequest].status = Status.Rejected;
        validatorCandidateRequestList[indexOfRequest].endBlock = block.number;
    }

    function votingToOrganizationForQueenDismissVote(bool _isApprove)
        external
        onlyKnight
        onlyQueenVotingNotNow
    {
        if (
            block.number.sub(currentQueen.startTermBlock) <=
            currentQueen.endTermBlock
        ) {
            setStatusIsTrustQueen(_isApprove);
            // @test // Set >= 9 => default  ==> set >= 4 to test so fast
            if (currentQueenDismissVoting.queenTrustlessList.length >= 4) {
                currentQueenDismissVoting.dismissBlock = block.number;
                queenDismissVotingList[
                    indexQueenDismissVoting.current()
                ] = currentQueenDismissVoting;
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

    function setStatusIsTrustQueen(bool _isTrustQueen) internal {
        (
            uint256 _indexKnightInCurrentKnight,

        ) = getPositionOfKnightInKnightListandCurrentKnight(_msgSender());
        require(
            currentKnightList[_indexKnightInCurrentKnight].isTrustQueen !=
                _isTrustQueen,
            "THIS STATUS IS ALREADY EXIST"
        );
        if (
            currentQueenDismissVoting.dismissBlock != 0 ||
            currentQueenDismissVoting.termNo == 0
        ) {
            indexQueenDismissVoting.increment();
            currentQueenDismissVoting.termNo = currentQueen.termNo;
        }
        if (!_isTrustQueen) {
            currentKnightList[_indexKnightInCurrentKnight].isTrustQueen = false;
            currentQueenDismissVoting.queenTrustlessList.push(_msgSender());
        } else {
            currentKnightList[_indexKnightInCurrentKnight].isTrustQueen = true;
            for (
                uint256 i = 0;
                i < currentQueenDismissVoting.queenTrustlessList.length;
                i++
            ) {
                if (
                    _msgSender() ==
                    currentQueenDismissVoting.queenTrustlessList[i]
                ) {
                    currentQueenDismissVoting.queenTrustlessList[
                            i
                        ] = currentQueenDismissVoting.queenTrustlessList[
                        currentQueenDismissVoting.queenTrustlessList.length.sub(
                            1
                        )
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

    function queenDismissVoting(address _validatorCandidaterAddress)
        external
        onlyKnight
        voteOnlyOnce(_validatorCandidaterAddress)
    {
        if (!isQueenVoting) {
            if (
                block.number.sub(currentQueen.startTermBlock) >=
                currentQueen.endTermBlock
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
        if (
            currentQueenVoting.startVoteBlock == 0 ||
            currentQueenVoting.endVoteBlock != 0
        ) {
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
        for (uint256 i = 1; i <= countNumberKnight(); i++) {
            if (currentKnightList[i].startTermBlock == 0) {
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
                (
                    uint256 _indexKnightInCurrentKnight,
                    uint256 _indexKnightInKnightList
                ) = getPositionOfKnightInKnightListandCurrentKnight(
                        _validatorCandidaterAddress
                    );
                delete currentKnightList[_indexKnightInCurrentKnight];
                knightList[_indexKnightInKnightList].endTermBlock = block
                    .number;
                isNeedToAppointNewKnight = true;
                emit AlertQueenDismissVoting(
                    _validatorCandidaterAddress,
                    currentQueen.queenAddr,
                    "PROCESS QUEEN DISMISS NOT YET SUCCESS"
                );
            }
        }
    }

    function updateCurrentQueenVoting() internal {
        queenVotingList[indexQueenVoting.current()].index = currentQueenVoting
            .index;
        queenVotingList[indexQueenVoting.current()].termNo = currentQueenVoting
            .termNo;
        queenVotingList[indexQueenVoting.current()]
            .startVoteBlock = currentQueenVoting.startVoteBlock;
        queenVotingList[indexQueenVoting.current()].endVoteBlock = block.number;
        currentQueenVoting.index = 0;
        currentQueenVoting.termNo = 0;
        currentQueenVoting.startVoteBlock = 0;
        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (
                currentQueenVoting
                    .proposedList[
                        validatorCandidateList[i].validatorCandidateAddr
                    ]
                    .length > 0
            ) {
                for (
                    uint256 j = 0;
                    j <
                    currentQueenVoting
                        .proposedList[
                            validatorCandidateList[i].validatorCandidateAddr
                        ]
                        .length;
                    j++
                ) {
                    queenVotingList[indexQueenVoting.current()]
                        .proposedList[
                            validatorCandidateList[i].validatorCandidateAddr
                        ]
                        .push(
                            currentQueenVoting.proposedList[
                                validatorCandidateList[i].validatorCandidateAddr
                            ][j]
                        );
                }
                delete currentQueenVoting.proposedList[
                    validatorCandidateList[i].validatorCandidateAddr
                ];
            }
        }
    }

    function updateNewQueen() internal {
        Queen memory queenCurrentTemporary = currentQueen;
        uint256 totalRewardsForNewQueen;
        uint256 countTermForNewQueen = 1;
        if (checkTitleAddress(checkThenNumberOfVotes()) == 1) {
            totalRewardsForNewQueen = currentQueen.totalRewards;
            countTermForNewQueen = currentQueen.countTerm.add(1);
        } else {
            if (checkTitleAddress(checkThenNumberOfVotes()) == 2) {
                (
                    uint256 _indexKnightInCurrentKnight,

                ) = getPositionOfKnightInKnightListandCurrentKnight(
                        checkThenNumberOfVotes()
                    );
                totalRewardsForNewQueen = currentKnightList[
                    _indexKnightInCurrentKnight
                ].totalRewards;
            }
        }
        currentQueen = Queen(
            checkThenNumberOfVotes(),
            totalRewardsForNewQueen,
            block.number,
            0,
            currentQueen.termNo.add(1),
            countTermForNewQueen
        );
        queenList[getIndexQueenOfQueenList(currentQueen.queenAddr)]
            .endTermBlock = block.number;
        queenList[getIndexQueenOfQueenList(currentQueen.queenAddr)]
            .countTerm = 0;
        queenList.push(currentQueen);
        isQueenVoting = false;
    }

    function checkThenNumberOfVotes() public view returns (address) {
        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (
                currentQueenVoting
                    .proposedList[
                        validatorCandidateList[i].validatorCandidateAddr
                    ]
                    .length >= 2
            ) {
                uint256 countNumberKnightDismissQueen;
                for (
                    uint256 j = 0;
                    j <
                    currentQueenVoting
                        .proposedList[
                            validatorCandidateList[i].validatorCandidateAddr
                        ]
                        .length;
                    j++
                ) {
                    if (
                        currentQueenVoting.proposedList[
                            validatorCandidateList[i].validatorCandidateAddr
                        ][j] != address(0)
                    ) {
                        countNumberKnightDismissQueen++;
                        if (countNumberKnightDismissQueen >= 6) {
                            return
                                validatorCandidateList[i]
                                    .validatorCandidateAddr;
                        }
                    }
                }
            }
        }
        return address(0);
    }

    function checkKnightVoteForQueenDismiss(address _validatorCandidaterAddress)
        public
    {
        if (
            currentQueenVoting
                .proposedList[_validatorCandidaterAddress]
                .length > 0
        ) {
            for (
                uint256 i = 0;
                i <
                currentQueenVoting
                    .proposedList[_validatorCandidaterAddress]
                    .length;
                i++
            ) {
                if (
                    currentQueenVoting.proposedList[
                        _validatorCandidaterAddress
                    ][i] == _msgSender()
                ) {
                    revert("VALIDATOR CANDIDATE PARTICIPATED IN THE ELECTION");
                }
            }
        }
    }

    function removeElementProposedNewQueen(address _validatorCandidaterAddress)
        internal
    {
        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (
                currentQueenVoting
                    .proposedList[
                        validatorCandidateList[i].validatorCandidateAddr
                    ]
                    .length >
                0 &&
                validatorCandidateList[i].validatorCandidateAddr !=
                _validatorCandidaterAddress
            ) {
                for (
                    uint256 j = 0;
                    j <
                    currentQueenVoting
                        .proposedList[
                            validatorCandidateList[i].validatorCandidateAddr
                        ]
                        .length;
                    j++
                ) {
                    if (
                        currentQueenVoting.proposedList[
                            validatorCandidateList[i].validatorCandidateAddr
                        ][j] == _msgSender()
                    ) {
                        currentQueenVoting.proposedList[
                            validatorCandidateList[i].validatorCandidateAddr
                        ][j] = currentQueenVoting.proposedList[
                            validatorCandidateList[i].validatorCandidateAddr
                        ][
                                currentQueenVoting
                                    .proposedList[
                                        validatorCandidateList[i]
                                            .validatorCandidateAddr
                                    ]
                                    .length
                                    .sub(1)
                            ];
                        currentQueenVoting
                            .proposedList[
                                validatorCandidateList[i].validatorCandidateAddr
                            ]
                            .pop();
                        break;
                    }
                }
            }
        }
    }

    function approveAndRejectRequestValidator(
        uint256 indexOfRequest,
        bool isApprove
    ) external onlyKnight {
        require(
            !checkStatusValidatorCandidateRequestFromKnight(indexOfRequest),
            "REQUEST BECOME TO VALIDATOR IS NOT AVAILABLE."
        );
        (
            uint256 _indexKnightInCurrentKnight,
            uint256 _indexKnightInKnightList
        ) = getPositionOfKnightInKnightListandCurrentKnight(_msgSender());
        require(
            validatorCandidateRequestList[indexOfRequest].knightNo ==
                _indexKnightInCurrentKnight,
            "KNIGHTNO OF VALIDATORREQUEST IS INVALID."
        );
        isApprove
            ? approveRequestValidator(
                _indexKnightInCurrentKnight,
                _indexKnightInKnightList,
                indexOfRequest
            )
            : rejectRequestValidator(indexOfRequest);
        validatorCandidateRequestList[indexOfRequest].endBlock = block.number;
    }

    function appointAndDismissKnight(
        uint256 _idKnight,
        address _addressValidatorCandidate
    ) external onlyQueen onlyQueenVotingNotNow {
        require(
            checkTitleAddress(_addressValidatorCandidate) == 3,
            "ONLY VALIDATE CANDIDATE CAN CALL"
        );
        if (
            block.number.sub(currentQueen.startTermBlock) <=
            currentQueen.endTermBlock
        ) {
            appointKnight(_idKnight, _addressValidatorCandidate);
        } else {
            isQueenVoting = true;
            revert("QUEEN'S TERM HAS EXPIRED.");
        }
    }

    function appointKnight(
        uint256 _idKnight,
        address _addressValidatorCandidate
    ) internal onlyIndexKnight(_idKnight) {
        (
            ,
            uint256 _indexKnightInKnightList
        ) = getPositionOfKnightInKnightListandCurrentKnight(
                getAddressOfKnightFromIndexKnight(_idKnight)
            );
        knightList[_indexKnightInKnightList].endTermBlock = block.number;
        dismissKnight(_idKnight, _addressValidatorCandidate);
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

    function dismissKnight(
        uint256 _idKnight,
        address _addressValidatorCandidate
    ) internal {
        validatorCandidateList[
            getIndexOfValidatorCandidate(_addressValidatorCandidate)
        ] = ValidatorCandidate(
            getAddressOfKnightFromIndexKnight(_idKnight),
            _idKnight,
            currentKnightList[_idKnight].termNo,
            block.number,
            0,
            0
        );
    }

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
        anikanaAddress.burn(feeToBecomeValidator);
        validatorCandidateRequestList[_indexRequest].status = Status.Approved;
    }

    function getListAddressQueenTrustlessList()
        public
        view
        returns (address[] memory)
    {
        return currentQueenDismissVoting.queenTrustlessList;
    }

    function getListAddressQueenDismissVotingList(
        uint256 _indexQueenDismissVotingList
    ) public view returns (address[] memory) {
        return
            queenDismissVotingList[_indexQueenDismissVotingList]
                .queenTrustlessList;
    }

    function getListAddressProposedList(address _validatorCandidaterAddress)
        public
        view
        returns (address[] memory)
    {
        return currentQueenVoting.proposedList[_validatorCandidaterAddress];
    }

    function getList1AddressProposedList(address _validatorCandidaterAddress)
        public
        view
        returns (address[] memory)
    {
        return queenVotingList[1].proposedList[_validatorCandidaterAddress];
    }

    function rejectRequestValidator(uint256 _indexRequest) internal {
        TransferHelper.safeTransfer(
            address(anikanaAddress),
            validatorCandidateRequestList[_indexRequest].requester,
            feeToBecomeValidator
        );
        validatorCandidateRequestList[_indexRequest].status = Status.Rejected;
    }

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

    function setFeeToBecomeValidatorCandidate(uint256 _feeToBecomeVakidator)
        public
        onlyQueen
    {
        feeToBecomeValidator = _feeToBecomeVakidator;
    }

    function checkStatusValidatorCandidateRequestFromKnight(
        uint256 indexOfRequest
    ) public view returns (bool) {
        (
            uint256 _indexKnightInCurrentKnight,

        ) = getPositionOfKnightInKnightListandCurrentKnight(_msgSender());
        if (
            validatorCandidateRequestList[indexOfRequest].knightNo ==
            _indexKnightInCurrentKnight &&
            validatorCandidateRequestList[indexOfRequest].status !=
            Status.Rejected &&
            validatorCandidateRequestList[indexOfRequest].status !=
            Status.Approved &&
            validatorCandidateRequestList[indexOfRequest].createdBlock != 0
        ) {
            return false;
        }
        return true;
    }

    function getIndexOfValidatorCandidate(address _addressValidatorCandidate)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (
                validatorCandidateList[i].validatorCandidateAddr ==
                _addressValidatorCandidate
            ) {
                return i;
            }
        }
    }

    function countNumberKnight() public view returns (uint256) {
        uint256 numberCurrentKnight;
        for (uint256 i = 0; i < knightList.length; i++) {
            if (
                currentKnightList[i + 1].knightAddr == knightList[i].knightAddr
            ) {
                numberCurrentKnight++;
            }
        }
        return numberCurrentKnight;
    }

    function countNumberValidatorCandiadate() public view returns (uint256) {
        uint256 numberValidatorCandiadate;
        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (
                !checkStatusOfValidatorAddress(
                    validatorCandidateList[i].validatorCandidateAddr
                )
            ) {
                numberValidatorCandiadate++;
            }
        }
        return numberValidatorCandiadate;
    }

    function checkStatusOfValidatorAddress(address _validatorAddress)
        public
        view
        returns (bool)
    {
        for (uint256 i = 1; i <= countNumberKnight(); i++) {
            if (
                _validatorAddress == currentKnightList[i].knightAddr ||
                _validatorAddress == currentQueen.queenAddr
            ) {
                return true;
            }
        }
        return false;
    }

    function checkTitleAddress(address _address) public view returns (uint256) {
        require(_address != address(0), "ADDRESS MUST BE DIFFERENT 0");
        if (_address == currentQueen.queenAddr) return 1;
        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (isKnight(_address)) return 2;
            if (_address == validatorCandidateList[i].validatorCandidateAddr)
                return 3;
        }
        return 4;
    }

    function checkNormalNode(address _addressOfUser)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < queenList.length; i++) {
            if (_addressOfUser == currentQueen.queenAddr) {
                return true;
            }
        }
        for (uint256 i = 0; i < knightList.length; i++) {
            if (_addressOfUser == currentKnightList[i + 1].knightAddr) {
                return true;
            }
        }
        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (
                _addressOfUser ==
                validatorCandidateList[i].validatorCandidateAddr ||
                _addressOfUser == address(0)
            ) {
                return true;
            }
        }
        return false;
    }

    function getFeeBeComeToValidatorCandidate() public view returns (uint256) {
        return feeToBecomeValidator;
    }

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

    function getInfoCurrentKnightList()
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        address[] memory knightAddress = new address[](countNumberKnight());
        uint256[] memory knightIndex = new uint256[](countNumberKnight());
        uint256[] memory knightStartTermBlock = new uint256[](
            countNumberKnight()
        );
        for (uint256 i = 0; i < knightList.length; i++) {
            if (
                currentKnightList[i + 1].knightAddr == knightList[i].knightAddr
            ) {
                uint256 indexKnightArray = currentKnightList[i + 1].index.sub(
                    1
                );
                knightAddress[indexKnightArray] = currentKnightList[i + 1]
                    .knightAddr;
                knightIndex[indexKnightArray] = currentKnightList[i + 1].index;
                knightStartTermBlock[indexKnightArray] = currentKnightList[
                    i + 1
                ].startTermBlock;
            }
        }
        return (knightAddress, knightIndex, knightStartTermBlock);
    }

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
        address[] memory validatorCandidateAddress = new address[](
            countNumberValidator
        );
        uint256[] memory validatorCandidateIndex = new uint256[](
            countNumberValidator
        );
        uint256[] memory validatorCandidateStartTermBlock = new uint256[](
            countNumberValidator
        );

        uint256 countIndexValidatorCandidate;
        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            if (
                !checkStatusOfValidatorAddress(
                    validatorCandidateList[i].validatorCandidateAddr
                )
            ) {
                validatorCandidateAddress[
                    countIndexValidatorCandidate
                ] = validatorCandidateList[i].validatorCandidateAddr;
                validatorCandidateIndex[
                    countIndexValidatorCandidate
                ] = validatorCandidateList[i].knightNo;
                validatorCandidateStartTermBlock[
                    countIndexValidatorCandidate
                ] = validatorCandidateList[i].startTermBlock;
                countIndexValidatorCandidate++;
            }
        }
        return (
            validatorCandidateAddress,
            validatorCandidateIndex,
            validatorCandidateStartTermBlock
        );
    }

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

    function getIndexOfValidatorCandidateRequest(
        address _validatorCandidateAddresss
    ) public view returns (uint256) {
        for (uint256 i = indexValidatorCandidateRequest.current(); i > 0; i--) {
            if (
                validatorCandidateRequestList[i].requester ==
                _validatorCandidateAddresss
            ) {
                return i;
            }
        }
    }

    function checkStatusValidatorCandidateRequest() public view returns (bool) {
        for (uint256 i = 1; i <= countNumberKnight(); i++) {
            for (
                uint256 j = indexValidatorCandidateRequest.current();
                j > 0;
                j--
            ) {
                if (
                    validatorCandidateRequestList[j].requester ==
                    _msgSender() &&
                    validatorCandidateRequestList[j].status !=
                    Status.Rejected &&
                    validatorCandidateRequestList[j].createdBlock != 0
                ) {
                    return true;
                }
            }
        }
        return false;
    }

    function isKnight(address _knightAddress) internal view returns (bool) {
        for (uint256 i = 1; i <= countNumberKnight(); i++) {
            if (_knightAddress == currentKnightList[i].knightAddr) return true;
        }
        return false;
    }

    function updateTotalRewardOfValidator(
        address _validatorAddr,
        uint256 _reward
    ) internal {
        TransferHelper.safeTransferFrom(
            address(anikanaAddress),
            _msgSender(),
            address(this),
            _reward
        );
        uint256 valueTransferForQueen = _reward.div(6);
        uint256 valueTransferForKnight = _reward.sub(valueTransferForQueen);
        uint256 allowaneOfSender = anikanaAddress.allowance(
            _msgSender(),
            address(this)
        );
        require(
            allowaneOfSender >= _reward,
            "BALANCE ALLOWANCE OF POOL ADDRESS INSURANCE."
        );
        TransferHelper.safeTransfer(
            address(anikanaAddress),
            address(_validatorAddr),
            valueTransferForKnight
        );
        TransferHelper.safeTransfer(
            address(anikanaAddress),
            address(currentQueen.queenAddr),
            valueTransferForQueen
        );
        if (_validatorAddr == currentQueen.queenAddr) {
            currentQueen.totalRewards += _reward;
            queenList[getIndexQueenOfQueenList(currentQueen.queenAddr)]
                .totalRewards += _reward;
        } else {
            currentQueen.totalRewards += valueTransferForQueen;
            queenList[getIndexQueenOfQueenList(currentQueen.queenAddr)]
                .totalRewards += valueTransferForQueen;
            (
                uint256 _indexKnightInCurrentKnight,
                uint256 _indexKnightInKnightList
            ) = getPositionOfKnightInKnightListandCurrentKnight(_validatorAddr);
            currentKnightList[_indexKnightInCurrentKnight]
                .totalRewards += valueTransferForKnight;
            knightList[_indexKnightInKnightList]
                .totalRewards += valueTransferForKnight;
        }
    }

    function getValidators() external view override returns (address[] memory) {
        address[] memory validators = new address[](
            validatorCandidateList.length
        );
        for (uint256 i = 0; i < validatorCandidateList.length; i++) {
            validators[i] = validatorCandidateList[i].validatorCandidateAddr;
        }
        return validators;
    }
}