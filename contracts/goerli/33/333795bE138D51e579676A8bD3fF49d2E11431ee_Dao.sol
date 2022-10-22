// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/*Errors*/
error Dao__NoVoterExist();
error Dao__YouCannotVote();
error Dao__ProposalDoesnotExisit();
error Dao__YouHaveAlreadyVotedOnThisProposal();
error Dao__OnlyOwnerCanCountVotes();
error Dao__CountAlreadyConducted();
error Dao__OnlyOwnerCanAccess();

contract Dao {
    /*State Variable*/
    address public owner;
    uint256 nextProposal;

    /*Storage*/
    address[] private s_Voterslist;
    uint256[] private s_Proposallist;
    uint256[] private s_ApprovedProposallist;

    /*Mapping*/
    mapping(uint256 => proposal) public Proposals;
    mapping(uint256 => bool) public Approved_Proposals;

    /*Events*/
    event Proposalcreated(
        uint256 indexed id,
        string name,
        string proposal_url,
        address proposer,
        uint256 amount,
        address wallet_address
    );

    event Proposalvote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    event proposalCount(uint256 indexed id, bool passed);

    event Votersadd(address indexed voteraddress);

    event Voterremove(uint256 indexed Index);

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Dao__OnlyOwnerCanAccess();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
    }

    struct proposal {
        uint256 id;
        uint256 amount;
        address wallet_address;
        bool exists;
        string name;
        string proposal_url;
        mapping(address => bool) voteStatus;
        uint256 votesUp;
        uint256 votesDown;
        bool countConducted;
        bool passed;
    }

    function AddVoters(address Voter) public onlyOwner {
        s_Voterslist.push(Voter);

        emit Votersadd(Voter);
    }

    function RemoveVoters(uint256 index) public onlyOwner {
        if (s_Voterslist.length < 1) {
            revert Dao__NoVoterExist();
        }
        s_Voterslist[index] = s_Voterslist[s_Voterslist.length - 1];
        s_Voterslist.pop();

        emit Voterremove(index);
    }

    function Totalvoters() public view returns (address[] memory) {
        return s_Voterslist;
    }

    function TotalProposal() public view onlyOwner returns (uint256[] memory) {
        return s_Proposallist;
    }

    function ApprovedProposal() public view returns (uint256[] memory) {
        return s_ApprovedProposallist;
    }

    function checkVoterEligibility(address Voter_address)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < s_Voterslist.length; i++) {
            if (s_Voterslist[i] == Voter_address) {
                return true;
            }
        }
        return false;
    }

    function CreateProposal(
        string memory _name,
        string memory _proposal_url,
        uint256 _amount,
        address _wallet_address
    ) public {
        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.name = _name;
        newProposal.amount = _amount;
        newProposal.proposal_url = _proposal_url;
        newProposal.wallet_address = _wallet_address;
        s_Proposallist.push(nextProposal);

        emit Proposalcreated(
            nextProposal,
            _name,
            _proposal_url,
            msg.sender,
            _amount,
            _wallet_address
        );
        nextProposal++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        //Checks
        if (checkVoterEligibility(msg.sender) == false) {
            revert Dao__YouCannotVote();
        }

        if (!Proposals[_id].exists) {
            revert Dao__ProposalDoesnotExisit();
        }
        //MAY BE ERROR HERE.
        if (!Proposals[_id].voteStatus[msg.sender] == true) {
            revert Dao__YouHaveAlreadyVotedOnThisProposal();
        }

        proposal storage p = Proposals[_id];

        if (_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit Proposalvote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    function GetProposal(uint256 _id)
        public
        view
        returns (
            string memory name,
            string memory url,
            uint256 amount,
            address wallet_add
        )
    {
        proposal storage new_Proposal = Proposals[_id];
        return (
            new_Proposal.name,
            new_Proposal.proposal_url,
            new_Proposal.amount,
            new_Proposal.wallet_address
        );
    }

    function CountVotes(uint256 _id) public {
        //Checks
        if (msg.sender != owner) {
            revert Dao__OnlyOwnerCanCountVotes();
        }

        if (!Proposals[_id].exists) {
            revert Dao__ProposalDoesnotExisit();
        }

        if (!Proposals[_id].countConducted) {
            revert Dao__CountAlreadyConducted();
        }

        proposal storage p = Proposals[_id];

        if (Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed = true;
        }

        p.countConducted = true;

        if (p.passed == true) {
            Approved_Proposals[_id] = true;
            s_ApprovedProposallist.push(_id);
        }

        emit proposalCount(_id, p.passed);
    }
}