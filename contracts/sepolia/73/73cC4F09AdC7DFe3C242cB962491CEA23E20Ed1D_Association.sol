// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Meeting.sol";
import "./Donation.sol";

contract Association {
    /*
     *Founding Protocol
     */
    string public foundingProtocolIPFSHash;

    /*
     * Approval of Association by Founders
     */

    bool public isRunning;
    address[] founders;
    mapping(address => bool) public foundersMapping;
    mapping(address => bool) public founderApproved;

    modifier onlyFounder() {
        require(foundersMapping[msg.sender]);
        _;
    }

    modifier onlyIfAssociationIsRunning() {
        require(isRunning, "Association not running");
        _;
    }

    uint256 public founderApprovedCounter;

    function approveAssociation() public onlyFounder {
        require(!founderApproved[msg.sender], "");
        require(!isRunning, "");
        founderApproved[msg.sender] = true;
        founderApprovedCounter += 1;

        if (founderApprovedCounter == founders.length) {
            isRunning = true;
        }
    }

    /*
     *  Statute
     */
    string public nameOfAssociation;
    string public purposeOfAssocation;

    mapping(string => uint256) public statuteData;
    string[] public statuteDataKeys;
    uint256 public membershipFeeDueDate;

    function getStatuteData(string memory _str) public view returns (uint256) {
        return statuteData[_str];
    }

    /*
     *  Make Donations
     */
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    uint256 tokenValue = 100;
    Donation donationContract;

    /*
     *  Creating Association
     */

    constructor(
        address _donationContract,
        address[] memory _boardMembers,
        address[] memory _generalMembers,
        string memory _foundingProtocolIPFSHash,
        string memory _nameOfAssociation,
        string memory _purposeOfAssocation,
        uint256 _numMaxBoardMembers,
        uint256 _meetingDuration,
        uint256 _durationTillGeneralMeetingStart,
        uint256 _durationTillBoardMeetingStart
    ) {
        require(_boardMembers.length <= _numMaxBoardMembers, "");
        require((_boardMembers.length + _generalMembers.length) >= 1, "");
        require(
            keccak256(abi.encodePacked(_nameOfAssociation)) !=
                keccak256(abi.encodePacked("")),
            ""
        );
        require(
            keccak256(abi.encodePacked(_purposeOfAssocation)) !=
                keccak256(abi.encodePacked("")),
            ""
        );
        //require(_generalMeetingDuration >= 86400, "");
        //require(_boardMeetingDuration >= 86400, "");

        amountAuthorizedBoardMembers = 0;
        amountAuthorizedMembers = 0;
        isRunning = false;
        founderApprovedCounter = 0;

        foundingProtocolIPFSHash = _foundingProtocolIPFSHash;

        nameOfAssociation = _nameOfAssociation;
        purposeOfAssocation = _purposeOfAssocation;

        statuteData["minPercentageChairmanVote"] = 50;
        statuteDataKeys.push("minPercentageChairmanVote");

        statuteData["minPercentageBoardMeeting"] = 50;
        statuteDataKeys.push("minPercentageBoardMeetingVote");

        statuteData["minPercentageStatuteVote"] = 75;
        statuteDataKeys.push("minPercentageStatuteVote");

        statuteData["minPercentageLiquidationVote"] = 75;
        statuteDataKeys.push("minPercentageLiquidationVote");

        statuteData["minPercentagePurposeVote"] = 100;
        statuteDataKeys.push("minPercentagePurposeVote");

        statuteData["minPercentageNewMemberVote"] = 50;
        statuteDataKeys.push("minPercentageNewMemberVote");

        statuteData["minAmountQuorumGeneralMeeting"] = 1;
        statuteDataKeys.push("minPercentQuorumGeneralMeeting");

        statuteData["minAmountQuorumBoardMeeting"] = 1;
        statuteDataKeys.push("minPercentQuorumBoardMeeting");

        statuteData["minPercentageConfirmationForGM"] = 10;
        statuteDataKeys.push("minPercentageConfirmationForGM");

        statuteData["numMaxBoardMembers"] = _numMaxBoardMembers;
        statuteDataKeys.push("numMaxBoardMembers");

        statuteData["generalMeetingDuration"] = _meetingDuration;
        statuteDataKeys.push("generalMeetingDuration");

        statuteData["boardMeetingDuration"] = _meetingDuration;
        statuteDataKeys.push("boardMeetingDuration");

        statuteData[
            "durationTillGeneralMeetingStart"
        ] = _durationTillGeneralMeetingStart;
        statuteDataKeys.push("durationTillGeneralMeetingStart");

        statuteData[
            "durationTillBoardMeetingStart"
        ] = _durationTillBoardMeetingStart;
        statuteDataKeys.push("durationTillBoardMeetingStart");

        statuteData["membershipFee"] = 2000000000000000;
        statuteDataKeys.push("membershipFee");

        statuteData["membershipPaymentInterval"] = 2419200; //4 Wochen
        statuteDataKeys.push("membershipPaymentInterval");

        membershipFeeDueDate =
            block.timestamp +
            statuteData["membershipPaymentInterval"];

        for (uint256 i = 0; i < _generalMembers.length; i++) {
            addMember(_generalMembers[i]);
            founders.push(_generalMembers[i]);
            foundersMapping[_generalMembers[i]] = true;
        }

        for (uint256 i = 0; i < _boardMembers.length; i++) {
            addMember(_boardMembers[i]);
            addBoardMember(_boardMembers[i]);
            founders.push(_boardMembers[i]);
            foundersMapping[_boardMembers[i]] = true;
        }

        donationContract = Donation(_donationContract);
    }

    /*
    *  End Creation of Association

    *  Start Member Management Logic
    */

    struct Member {
        address memberAddress;
        uint256 TimeOfNextFee;
        bool paid;
    }

    mapping(address => bool) public boardMemberMapping;
    mapping(address => bool) public memberMapping;
    mapping(address => Member) public memberStructMapping;

    address[] public members;
    address[] public boardMembers;

    uint256 public amountAuthorizedMembers;
    uint256 public amountAuthorizedBoardMembers;

    modifier onlyMember() {
        require(isMember(msg.sender), "");
        _;
    }

    modifier memberHasPaidFee() {
        require(hasPaidFee(msg.sender), "");
        _;
    }

    function isBoardMember(address addr) public view returns (bool) {
        if (boardMemberMapping[addr]) return true;
        else return false;
    }

    function isMember(address addr) public view returns (bool) {
        if (memberMapping[addr]) return true;
        else return false;
    }

    function hasPaidFee(address _addr) public view returns (bool) {
        return (memberStructMapping[_addr].TimeOfNextFee >
            membershipFeeDueDate);
    }

    /*function becomeMember() onlyIfAssociationIsRunning external {
        require(memberMapping[msg.sender] != true, 'sender is already a member');
        
        
        
    }*/

    function payMembershipFee()
        external
        payable
        onlyIfAssociationIsRunning
        onlyMember
    {
        require(!hasPaidFee(msg.sender), "");
        require(msg.value >= statuteData["membershipFee"], "");
        memberStructMapping[msg.sender].paid = true;
        memberStructMapping[msg.sender].TimeOfNextFee += statuteData[
            "membershipPaymentInterval"
        ];
        amountAuthorizedMembers += 1;
        if (boardMemberMapping[msg.sender]) {
            amountAuthorizedBoardMembers += 1;
        }

        incomes.push(Income(msg.sender, msg.value, block.timestamp, true));
    }

    function addMember(address _newMember) private {
        require(memberMapping[_newMember] != true, "");
        memberMapping[_newMember] = true;
        Member memory m = Member(_newMember, membershipFeeDueDate, false);
        memberStructMapping[_newMember] = m;
        members.push(m.memberAddress);
    }

    function addBoardMember(address _newBoardMember) private {
        require(memberMapping[_newBoardMember], "");
        require(!boardMemberMapping[_newBoardMember], "");
        boardMemberMapping[_newBoardMember] = true;
        boardMembers.push(_newBoardMember);
    }

    function checkAllMembersFeePayments() internal onlyIfAssociationIsRunning {
        if (block.timestamp >= membershipFeeDueDate) {
            amountAuthorizedBoardMembers = 0;
            amountAuthorizedMembers = 0;
            for (uint256 i = 0; i < members.length; i++) {
                if (
                    memberStructMapping[members[i]].TimeOfNextFee <
                    block.timestamp
                ) {
                    memberStructMapping[members[i]].paid = false;
                } else {
                    memberStructMapping[members[i]].paid = true;
                    amountAuthorizedMembers += 1;
                    if (boardMemberMapping[members[i]]) {
                        amountAuthorizedBoardMembers += 1;
                    }
                }
            }
            membershipFeeDueDate += statuteData["membershipPaymentInterval"];
        }
    }

    function endMembership() public onlyMember {
        memberMapping[msg.sender] = false;
        boardMemberMapping[msg.sender] = false;
        if (memberStructMapping[msg.sender].paid) {
            amountAuthorizedMembers -= 1;
            if (boardMemberMapping[msg.sender]) {
                amountAuthorizedBoardMembers -= 1;
            }
        }
        delete (memberStructMapping[msg.sender]);
    }

    function getTotalNumberMembers() public view returns (uint256) {
        return members.length;
    }

    struct NewMemberProposal {
        address newMember;
    }

    mapping(address => NewMemberProposal) public NewMemberProposalMapping;

    function becomeNewMember(
        string memory _description
    ) public onlyIfAssociationIsRunning {
        require(memberMapping[msg.sender] != true, "");
        Meeting m = createMeeting(Meeting.VOTINGTYPE.NEWMEMBER, _description);
        NewMemberProposalMapping[address(m)] = NewMemberProposal(msg.sender);
        m.setProposedNewMember(msg.sender);
    }

    /*
     *  End Member Management Logic
     */

    /*
     *Treasury Start
     */

    struct Income {
        address spender;
        uint256 amount;
        uint256 timeOfIncome;
        bool feePayment;
    }

    struct Expense {
        address receiver;
        uint256 amount;
        uint256 timeOfExpense;
        address boardMeeting;
    }

    Income[] public incomes;
    Expense[] public expenses;

    function deposit() public payable {
        incomes.push(Income(msg.sender, msg.value, block.timestamp, false));
    }

    function transferEther(
        address payable _to,
        uint256 _amount,
        address meeting
    ) private {
        _to.transfer(_amount);
        expenses.push(Expense(_to, _amount, block.timestamp, meeting));
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /*
     *Treasury Functions End
     */

    /*
     *  Start Meeting Logic
     */

    struct MeetingStruct {
        string description;
        address proposer;
        uint256 expiry;
        Meeting.VOTINGTYPE votingType;
        bool alreadyExecuted;
    }

    Meeting[] public meetings;

    mapping(address => MeetingStruct) public meetingRegister;
    mapping(address => bool) public meetingRegistry;

    /*
     * Board Member Appointment/Dismissal
     */

    struct BoardMemberProposal {
        address proposedBoardMember;
    }

    mapping(address => BoardMemberProposal) public BoardMemberProposalMapping;

    modifier noBoardMemberVotingRunning() {
        if (meetings.length >= 1) {
            for (uint256 i = meetings.length - 1; i >= 0; i--) {
                MeetingStruct memory currentMeeting = meetingRegister[
                    address(meetings[i])
                ];
                if (
                    currentMeeting.votingType ==
                    Meeting.VOTINGTYPE.APPOINTBOARDMEMBER
                ) {
                    require(currentMeeting.expiry < block.timestamp, "");
                    break;
                }
            }
        }
        _;
    }

    function proposeBoardMemberAppointment(
        string memory _description,
        address _proposedBoardMember
    )
        public
        onlyIfAssociationIsRunning
        noBoardMemberVotingRunning
        onlyMember
        memberHasPaidFee
    {
        require(!boardMemberMapping[_proposedBoardMember], "");
        require(boardMembers.length < statuteData["numMaxBoardMembers"], "");
        Meeting m = createMeeting(
            Meeting.VOTINGTYPE.APPOINTBOARDMEMBER,
            _description
        );
        BoardMemberProposalMapping[address(m)] = BoardMemberProposal(
            _proposedBoardMember
        );
        m.setProposedBoardMember(_proposedBoardMember);
    }

    function proposeBoardMemberDismissal(
        string memory _description,
        address _proposedBoardMember
    ) public onlyIfAssociationIsRunning onlyMember memberHasPaidFee {
        require(boardMemberMapping[_proposedBoardMember], "");
        Meeting m = createMeeting(
            Meeting.VOTINGTYPE.DISMISSBOARDMEMBER,
            _description
        );
        BoardMemberProposalMapping[address(m)] = BoardMemberProposal(
            _proposedBoardMember
        );
        m.setProposedBoardMember(_proposedBoardMember);
    }

    /*
     * Purpose Change
     */
    struct PurposeChangeProposal {
        string proposedPurposeChange;
    }

    mapping(address => PurposeChangeProposal)
        public PurposeChangeProposalMapping;

    function proposePurposeChange(
        string memory _description,
        string memory _proposedNewPurpose
    ) public onlyIfAssociationIsRunning onlyMember memberHasPaidFee {
        Meeting m = createMeeting(
            Meeting.VOTINGTYPE.PURPOSECHANGE,
            _description
        );
        PurposeChangeProposalMapping[address(m)] = PurposeChangeProposal(
            _proposedNewPurpose
        );
        m.setProposedPurpose(_proposedNewPurpose);
    }

    /*
     *Statute Change
     */
    struct StatuteProposal {
        uint256 statutePart;
        uint256 proposedValue;
    }

    mapping(address => StatuteProposal) StatuteProposalMapping;

    function proposeStatuteChange(
        string memory _description,
        uint256 _proposedStatuteData,
        uint256 _proposedNewValue
    ) external onlyIfAssociationIsRunning onlyMember memberHasPaidFee {
        Meeting m = createMeeting(
            Meeting.VOTINGTYPE.STATUTECHANGE,
            _description
        );
        StatuteProposalMapping[address(m)] = StatuteProposal(
            _proposedStatuteData,
            _proposedNewValue
        );
        m.setProposedStatute(_proposedStatuteData, _proposedNewValue);
    }

    /*
     *  BoardMeeting
     */
    struct BoardMeetingProposal {
        address receiver;
        uint256 amountInWei;
    }

    mapping(address => BoardMeetingProposal) boardMeetingProposalMapping;

    function proposeBoardMeeting(
        string memory _description,
        address _to,
        uint256 _amountInWei
    ) external onlyIfAssociationIsRunning memberHasPaidFee {
        require(isBoardMember(msg.sender), "is not board member");
        Meeting m = createMeeting(
            Meeting.VOTINGTYPE.BOARDMEETING,
            _description
        );
        boardMeetingProposalMapping[address(m)] = BoardMeetingProposal(
            _to,
            _amountInWei
        );
        m.setProposedBoardMeeting(_to, _amountInWei);
    }

    /*
     *  Liquidation
     */

    struct DissolutionProposal {
        uint256 TimeOfProposing;
        bool success;
    }

    mapping(address => DissolutionProposal) DissolutionProposalMapping;

    function proposeDissolution(
        string memory _description
    ) external onlyMember memberHasPaidFee {
        Meeting m = createMeeting(Meeting.VOTINGTYPE.LIQUIDATION, _description);
        DissolutionProposalMapping[address(m)] = DissolutionProposal(
            block.timestamp,
            false
        );
    }

    event newMeeting(MeetingStruct newMeeting);
    event executedMeetingDecision(MeetingStruct executedMeeting);

    function createMeeting(
        Meeting.VOTINGTYPE _votingType,
        string memory _description
    ) private returns (Meeting) {
        uint256 timeTillMeetingStartsInSeconds = block.timestamp +
            statuteData["durationTillBoardMeetingStart"];
        uint256 timeTillMeetingExpireInSeconds = timeTillMeetingStartsInSeconds +
                statuteData["generalMeetingDuration"];
        checkAllMembersFeePayments();
        Meeting m = new Meeting(
            _votingType,
            _description,
            timeTillMeetingStartsInSeconds,
            timeTillMeetingExpireInSeconds
        );
        meetings.push(m);
        MeetingStruct memory newM = MeetingStruct(
            _description,
            msg.sender,
            timeTillMeetingExpireInSeconds,
            _votingType,
            false
        );
        meetingRegister[address(m)] = newM;
        meetingRegistry[address(m)] = true;
        emit newMeeting(newM);
        return m;
    }

    modifier isMeeting() {
        require(meetingRegistry[msg.sender], "");
        _;
    }

    modifier notExecuted() {
        require(!meetingRegister[msg.sender].alreadyExecuted, "");
        _;
    }

    function endMeeting(
        Meeting.VOTINGTYPE votingType
    ) public isMeeting notExecuted {
        if (votingType == Meeting.VOTINGTYPE.BOARDMEETING) {
            BoardMeetingProposal memory proposal = boardMeetingProposalMapping[
                msg.sender
            ];
            transferEther(
                payable(proposal.receiver),
                proposal.amountInWei,
                msg.sender
            );
        } else if (votingType == Meeting.VOTINGTYPE.STATUTECHANGE) {
            string memory statutePart = statuteDataKeys[
                StatuteProposalMapping[msg.sender].statutePart
            ];
            statuteData[statutePart] = StatuteProposalMapping[msg.sender]
                .proposedValue;
        } else if (votingType == Meeting.VOTINGTYPE.APPOINTBOARDMEMBER) {
            boardMemberMapping[
                BoardMemberProposalMapping[msg.sender].proposedBoardMember
            ] = true;
            amountAuthorizedBoardMembers += 1;
        } else if (votingType == Meeting.VOTINGTYPE.DISMISSBOARDMEMBER) {
            boardMemberMapping[
                BoardMemberProposalMapping[msg.sender].proposedBoardMember
            ] = false;
            amountAuthorizedBoardMembers -= 1;
        } else if (votingType == Meeting.VOTINGTYPE.PURPOSECHANGE) {
            purposeOfAssocation = PurposeChangeProposalMapping[msg.sender]
                .proposedPurposeChange;
        } else if (votingType == Meeting.VOTINGTYPE.LIQUIDATION) {
            liquidateAssociation(msg.sender);
        } else if (votingType == Meeting.VOTINGTYPE.NEWMEMBER) {
            addMember(NewMemberProposalMapping[msg.sender].newMember);
        }

        meetingRegister[msg.sender].alreadyExecuted = true;
        emit executedMeetingDecision(meetingRegister[msg.sender]);
    }

    function liquidateAssociation(address meeting) private {
        uint256 balance = getBalance();
        checkAllMembersFeePayments();
        uint256 balanceChunk = balance / amountAuthorizedMembers;
        for (uint256 i = 0; i < members.length; i++) {
            if (memberStructMapping[members[i]].paid) {
                transferEther(
                    payable(address(members[i])),
                    balanceChunk,
                    meeting
                );
            }
        }
        isRunning = true;
    }

    /*
     *End Meeting Logic
     */

    /*
     *Donation & DONA TOKEN Logic
     */

    function donate() public payable {
        // Ensure that the contract has enough balance to transfer tokens
        addressToAmountFunded[msg.sender] = msg.value;
        funders.push(msg.sender);
        // Transfer tokens from the contract to the caller
        uint256 tokenAmt = msg.value / tokenValue;
        donationContract.disburseDonaToken(msg.sender, tokenAmt);
    }

    function getFundersList() public view returns (address[] memory) {
        return funders;
    }

    function getFundedAmount(address _address) public view returns (uint256) {
        return addressToAmountFunded[_address];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./DonaToken.sol";
import "./TaxAuthority.sol";

contract Donation {
    DONA donaToken;
    TaxAuthority taxAuthority;

    constructor(address _taxAuthority, address _donaTokenAddress) {
        donaToken = DONA(_donaTokenAddress);
        taxAuthority = TaxAuthority(_taxAuthority);
    }

    function disburseDonaToken(address _donator, uint256 _tokenValue) external {
        require(
            taxAuthority.isAddressRegistered(msg.sender),
            "Address not Registered with Tax Authority"
        );
        if (
            keccak256(
                abi.encodePacked(
                    taxAuthority
                        .getOrganisationTaxDetails(msg.sender)
                        .taxCategory
                )
            ) == keccak256(abi.encodePacked("CharitableOrganisations"))
        ) {
            donaToken.mint(_donator, _tokenValue);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Association.sol";

contract Meeting {
    Association A;
    address public associationAddress;

    struct Voter {
        bool voted;
        bool votedYes;
        bool votedNo;
    }

    mapping(address => Voter) public voters;

    enum VOTINGTYPE {
        BOARDMEETING,
        STATUTECHANGE,
        APPOINTBOARDMEMBER,
        DISMISSBOARDMEMBER,
        PURPOSECHANGE,
        LIQUIDATION,
        NEWMEMBER
    }
    VOTINGTYPE public votingType;

    string public votingDescription;
    uint256 public voteYesCounter;
    uint256 public voteNoCounter;
    uint256 public abstentionsCounter;
    uint256 public totalVotes;
    uint256 public timeTillVotingExpiresInSeconds;
    uint256 public timeTillVotingStartsInSeconds;

    bool public confirmed;
    uint256 public confirmationCounter;
    mapping(address => bool) public confirmers;

    constructor(
        VOTINGTYPE _votingType,
        string memory _votingDescription,
        uint256 _timeTillVotingStartsInSeconds,
        uint256 _timeTillMeetingExpiresInSeconds
    ) {
        A = Association(msg.sender);
        associationAddress = msg.sender;
        votingDescription = _votingDescription;
        votingType = _votingType;
        confirmationCounter = 0;
        voteYesCounter = 0;
        voteNoCounter = 0;
        timeTillVotingExpiresInSeconds = _timeTillMeetingExpiresInSeconds;
        timeTillVotingStartsInSeconds = _timeTillVotingStartsInSeconds;

        if (A.boardMemberMapping(address(tx.origin))) {
            confirmed = true;
        } else {
            confirmed = false;
        }
    }

    modifier onlyAssociation() {
        require(
            msg.sender == associationAddress,
            "only association authorized."
        );
        _;
    }

    modifier onlyAuhorizedMember() {
        if (votingType == VOTINGTYPE.BOARDMEETING) {
            require(A.isBoardMember(msg.sender), "sender is no board member.");
        } else {
            require(A.isMember(msg.sender), "sender is no member.");
        }
        _;
    }

    modifier onlyWithinVotingTime() {
        require(
            block.timestamp >= timeTillVotingStartsInSeconds,
            "Voting has not started"
        );
        require(
            block.timestamp <= timeTillVotingExpiresInSeconds,
            "Voting Time is over"
        );
        _;
    }

    modifier votingIsOver() {
        if (votingType == VOTINGTYPE.BOARDMEETING) {
            if (A.amountAuthorizedBoardMembers() == totalVotes) {
                _;
            } else {
                require(
                    (block.timestamp > timeTillVotingExpiresInSeconds) ||
                        (totalVotes == A.amountAuthorizedBoardMembers()),
                    "Voting is not over yet."
                );
                _;
            }
        } else {
            if (A.amountAuthorizedMembers() == totalVotes) {
                _;
            } else {
                require(
                    (block.timestamp > timeTillVotingExpiresInSeconds) ||
                        (totalVotes == A.amountAuthorizedMembers()),
                    "Voting is not over yet."
                );
                _;
            }
        }
    }

    modifier isConfirmed() {
        require(confirmed, "Proposal not confirmed.");
        _;
    }

    modifier notVoted() {
        require(!voters[msg.sender].voted, "Already voted.");
        _;
    }

    /*
     *NEWMEMBER
     */

    function setProposedNewMember(address _nm) public onlyAssociation {
        proposedNewMember = _nm;
    }

    address public proposedNewMember;

    /*
     * APPOINTBOARDMEMBER
     */
    function setProposedBoardMember(address _pbm) public onlyAssociation {
        proposedCandidate.candidateAdress = _pbm;
        proposedCandidate.approved = false;
    }

    Candidate public proposedCandidate;

    struct Candidate {
        address candidateAdress;
        bool approved;
    }

    modifier isApproved() {
        if (votingType == VOTINGTYPE.APPOINTBOARDMEMBER) {
            require(
                proposedCandidate.approved,
                "Candidate has not confirmed Voting ."
            );
        }
        _;
    }

    /*
     *CHANGE PURPOSE
     */
    function setProposedPurpose(string memory _pp) public onlyAssociation {
        proposedPurpose = _pp;
    }

    string public proposedPurpose;

    /*
     *Change Statute
     */
    struct ProposedStatute {
        uint256 statutePart;
        uint256 proposedValue;
    }

    function setProposedStatute(uint256 _sp, uint256 _pv)
        public
        onlyAssociation
    {
        proposedStatute.statutePart = _sp;
        proposedStatute.proposedValue = _pv;
    }

    ProposedStatute public proposedStatute;

    /*
     *Board Meeting
     */
    struct ProposedBoardMeeting {
        address receiver;
        uint256 amountInWei;
    }

    function setProposedBoardMeeting(address _rec, uint256 _amountInWei)
        public
        onlyAssociation
    {
        proposedBoardMeeting.receiver = _rec;
        proposedBoardMeeting.amountInWei = _amountInWei;
    }

    ProposedBoardMeeting public proposedBoardMeeting;

    function approveVoting() external {
        require(
            msg.sender == proposedCandidate.candidateAdress,
            "only Candidate authorized."
        );
        proposedCandidate.approved = true;
    }

    function confirmProposal() external onlyAuhorizedMember {
        require(!confirmed, "Proposal already confirmed.");
        require(!confirmers[msg.sender], "you already confirmed");
        confirmationCounter++;
        confirmers[msg.sender] = true;
        if (
            confirmationCounter >
            calcPercentOf(
                uint256(A.getStatuteData("minPercentageConfirmationForGM")),
                A.getTotalNumberMembers()
            )
        ) {
            confirmed = true;
        }
    }

    function calcPercentOf(uint256 perc, uint256 ofNum)
        private
        pure
        returns (uint256)
    {
        return (ofNum * perc) / 100;
    }

    function voteYes()
        external
        onlyAuhorizedMember
        onlyWithinVotingTime
        isConfirmed
        isApproved
        notVoted
    {
        voters[msg.sender].votedYes = true;
        voters[msg.sender].votedNo = false;
        voters[msg.sender].voted = true;
        voteYesCounter++;
        totalVotes++;
    }

    function voteNo()
        external
        onlyAuhorizedMember
        onlyWithinVotingTime
        isConfirmed
        isApproved
        notVoted
    {
        voters[msg.sender].votedYes = false;
        voters[msg.sender].votedNo = true;
        voters[msg.sender].voted = true;
        voteNoCounter++;
        totalVotes++;
    }

    function containVote()
        external
        onlyAuhorizedMember
        onlyWithinVotingTime
        isConfirmed
        isApproved
        notVoted
    {
        voters[msg.sender].votedYes = false;
        voters[msg.sender].votedNo = false;
        voters[msg.sender].voted = true;
        abstentionsCounter++;
        totalVotes++;
    }

    function executeResultOfMeeting()
        external
        onlyAuhorizedMember
        votingIsOver
    {
        if (votingType == VOTINGTYPE.BOARDMEETING) {
            require(
                totalVotes >=
                    uint256(A.getStatuteData("minAmountQuorumBoardMeeting")),
                "Quroum not reached."
            );
            require(
                voteYesCounter >=
                    calcPercentOf(
                        uint256(
                            A.getStatuteData("minPercentageBoardMemberVote")
                        ),
                        totalVotes
                    ),
                "Not enough voted Yes."
            );
        } else {
            require(
                totalVotes >=
                    uint256(A.getStatuteData("minAmountQuorumGeneralMeeting")),
                "Quorum not reached."
            );
            if (
                votingType == VOTINGTYPE.APPOINTBOARDMEMBER ||
                votingType == VOTINGTYPE.DISMISSBOARDMEMBER
            ) {
                require(
                    voteYesCounter >=
                        calcPercentOf(
                            uint256(
                                A.getStatuteData("minPercentageChairmanVote")
                            ),
                            totalVotes
                        ),
                    "Not enough voted Yes."
                );
            } else if (votingType == VOTINGTYPE.PURPOSECHANGE) {
                require(
                    voteYesCounter >=
                        calcPercentOf(
                            uint256(
                                A.getStatuteData("minPercentagePurposeVote")
                            ),
                            A.amountAuthorizedMembers()
                        ),
                    "Not enough voted Yes."
                );
            } else if (votingType == VOTINGTYPE.STATUTECHANGE) {
                require(
                    voteYesCounter >=
                        calcPercentOf(
                            uint256(
                                A.getStatuteData("minPercentageStatuteVote")
                            ),
                            totalVotes
                        ),
                    "Not enough voted Yes."
                );
            } else if (votingType == VOTINGTYPE.LIQUIDATION) {
                require(
                    voteYesCounter >=
                        calcPercentOf(
                            uint256(
                                A.getStatuteData("minPercentageLiquidationVote")
                            ),
                            totalVotes
                        ),
                    "Not enough voted Yes."
                );
            } else if (votingType == VOTINGTYPE.NEWMEMBER) {
                require(
                    voteYesCounter >=
                        calcPercentOf(
                            uint256(
                                A.getStatuteData("minPercentageNewMemberVote")
                            ),
                            totalVotes
                        ),
                    "Not enough voted Yes."
                );
            }
        }
        A.endMeeting(votingType);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract TaxAuthority {
    // Mapping from address to Tax Category and Tax Rate
    struct taxInfo {
        string taxCategory;
        uint256 taxRate;
    }
    taxInfo txinf;
    mapping(address => taxInfo) registeredOrganisations;
    address[] public registeredAddresses;
    string[] availableTaxCategories;
    mapping(string => uint256) public taxClass;

    uint256 public registerFee;

    constructor(uint256 _registerFee) {
        registerFee = _registerFee;
        availableTaxCategories = [
            "Trade",
            "Manufacturing",
            "Construction",
            "AgricultureFishing",
            "Forestry",
            "Mining",
            "Services",
            "SmallBusinesses",
            "CharitableOrganisations",
            "GoodsServices"
        ];
        taxClass["Trade"] = 19;
        taxClass["Manufacturing"] = 19;
        taxClass["Construction"] = 19;
        taxClass["AgricultureFishing"] = 19;
        taxClass["Forestry"] = 19;
        taxClass["Mining"] = 19;
        taxClass["Services"] = 19;
        taxClass["SmallBusinesses"] = 16;
        taxClass["CharitableOrganisations"] = 0;
        taxClass["GoodsServices"] = 7;
    }

    // Function to register a contract
    function register(
        string memory _category,
        address _address
    ) public payable returns (uint256) {
        require(msg.value == registerFee, "Incorrect fee");
        require(!isAddressRegistered(_address), "Address already Registered");
        txinf = taxInfo(_category, taxClass[_category]);
        registeredOrganisations[_address] = txinf;
        registeredAddresses.push(_address);
        return taxClass[_category];
    }

    function getTaxCategories() public view returns (string[] memory) {
        return availableTaxCategories;
    }

    function getTaxRates(
        string memory _category
    ) public view returns (uint256) {
        return taxClass[_category];
    }

    function getRegisteredAddresses() public view returns (address[] memory) {
        return registeredAddresses;
    }

    function getOrganisationTaxDetails(
        address _address
    ) public view returns (taxInfo memory) {
        return registeredOrganisations[_address];
    }

    function isAddressRegistered(address _address) public view returns (bool) {
        for (uint256 i = 0; i < registeredAddresses.length; i++) {
            if (registeredAddresses[i] == _address) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DONA is ERC20 {
    address private owner;

    // Initialize the contract with an initial supply of 1000 DONA
    constructor() ERC20("DONA", "DT") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
library SafeMath {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}