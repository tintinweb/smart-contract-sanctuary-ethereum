/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

/**
 * @title Voting contract
 * @author cheriaa akram
 */
contract Voting {
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint16 votedProposalId;
    }

    struct Proposal {
        string description;
        uint32 voteCount;
    }

    mapping(address => Voter) public _voterlist;
    address[] public _votersAddress;

    Proposal[] public _proposallist;
    WorkflowStatus public _workflow;

    uint16 public proposalId = 0;
    uint16 public _winningProposalId=0;


    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint16 proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted(address voter, uint16 proposalId);
    event VotesTallied();
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );

    /**
     * @dev Register voter in the mapping _voterlist
     * @param _address Voter address
     */
   function RegisterVoter(address _address) public  {
        require(
            _workflow == WorkflowStatus.RegisteringVoters,
            "The status is not correct : Must be RegisteringVoters"
        );
        require(
            _address != address(0),
            "address is  0! Please check address input"
        );
        require(
            _voterlist[_address].isRegistered == false,
            "This address is already registered"
        );
        _voterlist[_address].isRegistered = true;
        _votersAddress.push(_address);
        emit VoterRegistered(_address);
    }

    function getVotersAddress()
        public view    returns (address[] memory)
    {
        return _votersAddress;
    }
    function getProposalList() public view returns (Proposal[] memory) {
        return _proposallist;
    }
     function getStatus() public view returns (WorkflowStatus) {
        return _workflow;
    }

    /**
     * @dev Register a new proposal
     * @param _description The proposal description
     */
    function RegisterProposal(string memory _description) public {
        require(
            _workflow == WorkflowStatus.ProposalsRegistrationStarted,
            "The status is not correct : Must be ProposalsRegistrationStarted"
        );
        _proposallist.push(Proposal(_description, 0));
        proposalId++;
        emit ProposalRegistered(proposalId);
    }

    /**
     * @dev Add a vote in favor of this _proposalId
     * @param _proposalId Proposal identifier
     */
    function AddVote(uint16 _proposalId) public {
        require(
            _workflow == WorkflowStatus.VotingSessionStarted,
            "The status is not correct : Must be VotingSessionStarted"
        );
        require(
            _voterlist[msg.sender].isRegistered == true,
            "The voter is not registered"
        );
        require(
            _voterlist[msg.sender].hasVoted == false,
            "The voter has already voted"
        );

         require(_proposalId<proposalId  , "The proposition does not exist!");
        _proposallist[_proposalId].voteCount++;

        _voterlist[msg.sender].votedProposalId = _proposalId;
        _voterlist[msg.sender].hasVoted = true;

        emit Voted(msg.sender, _proposalId);
    }

    /**
     * @dev Get the winning proposal
     * We take the the first one in the list in case of equality
     * Set _winningProposalId with the index of winning _proposallist
     */
    function WinningProposal() public  {
        uint32 _winningVoteCount = 0;

        require(
            _workflow == WorkflowStatus.VotingSessionEnded,
            "The status is not correct : Must be VotingSessionEnded"
        );
        for (uint16 i = 0; i <_proposallist.length; i++) {
            if (_proposallist[i].voteCount > _winningVoteCount) {
                _winningVoteCount = _proposallist[i].voteCount;
                _winningProposalId = i;
            }
        }

        _workflow = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionEnded,
            WorkflowStatus.VotesTallied
        );
        emit VotesTallied();
    }

    /**
     * @dev Get proposal winner information
     * @return _proposallist[_winningProposalId] Proposal proposal
     */
    function Winner() public view returns (Proposal memory) {
        require(
            _workflow == WorkflowStatus.VotesTallied,
            "Result is not ready!"
        );
        return _proposallist[_winningProposalId];
    }

    /**
     * @dev Get proposal by id
     * @return Proposal proposal
     */
    function GetProposal(uint16 _proposalId)
        public
        view
        returns (Proposal memory)
    {
        return _proposallist[_proposalId-1];
    }

    /**
     * @dev Start proposal period
     */
    function ProposalStart() public  {
        require(
            _workflow == WorkflowStatus.RegisteringVoters,
            "The status is not correct : Must be RegisteringVoters"
        );
        _workflow = WorkflowStatus.ProposalsRegistrationStarted;

        emit WorkflowStatusChange(
            WorkflowStatus.RegisteringVoters,
            WorkflowStatus.ProposalsRegistrationStarted
        );
        emit ProposalsRegistrationStarted();
    }

    /**
     * @dev End proposal period
     */
    function ProposalEnd() public  {
        require(
            _workflow == WorkflowStatus.ProposalsRegistrationStarted,
            "The status is not correct : Must be ProposalsRegistrationStarted"
        );
        _workflow = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationStarted,
            WorkflowStatus.ProposalsRegistrationEnded
        );
        emit ProposalsRegistrationEnded();
    }

    /**
     * @dev Start vote period
     */
    function VoteStart() public  {
        require(
            _workflow == WorkflowStatus.ProposalsRegistrationEnded,
            "The status is not correct : Must be ProposalsRegistrationEnded"
        );
        _workflow = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationEnded,
            WorkflowStatus.VotingSessionStarted
        );
        emit VotingSessionStarted();
    }

    /**
     * @dev End vote period
     */
    function VoteEnd() public  {
        require(
            _workflow == WorkflowStatus.VotingSessionStarted,
            "The status is not correct : Must be VotingSessionStarted"
        );
        _workflow = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.VotingSessionStarted,
            WorkflowStatus.VotingSessionEnded
        );
        emit VotingSessionEnded();
    }
}