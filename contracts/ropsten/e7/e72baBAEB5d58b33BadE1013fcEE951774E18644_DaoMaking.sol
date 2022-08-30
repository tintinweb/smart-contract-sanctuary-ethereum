/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;
// creating a Dao SC
contract DaoMaking {
    address public Owner;
    uint256 nextProposal;
    mapping(address => uint256) public Voters_balance;

    // defining params during contract deployment
    constructor() {
        Owner = msg.sender;
        nextProposal = 1;
    }

    // creating datatype for contract functions
    struct proposal {
        uint256 id;
        uint256 votesup;
        uint256 votesdown;
        uint256 maxvotes;
        uint256 deadline;
        bool exists;
        bool count_Conduct;
        address[] Voters;
        bool passed;
        mapping(address => bool) votestatus;
        string proposal_Description;
    }

    proposal proposal_data;

    mapping(uint256 => proposal) public Proposal_Id;

    // checking either address is Smart contract or EOA
    function checkAddress(address _addr) public view returns (bool) {
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }
        if (length > 0) {
            return true;
        }
        return false;
    }

    //Using modifier for security to ensure only EOA can interact
    modifier verifyAddress() {
        require(!checkAddress(msg.sender), "Contract not allowed to Interact");
        require(msg.sender != address(0), "Null Address not allowed");
        _;
    }

    // function to recieve funds for providing Dao Governance membership
    receive() external payable verifyAddress {
        require(
            msg.value >= 1e5,
            "Minimum amount threshold not met to become a voting member"
        );
        proposal_data.Voters.push(msg.sender);
        Voters_balance[msg.sender] += msg.value;
    }

    // checking number of eligible voters
    function Eligible_voters() public view returns (uint256) {
        return proposal_data.Voters.length;
    }

    // checking eligibility to create proposals
    function proposal_creation_eligiblity(address proposing)
        public
        view
        returns (bool)
    {
        if (Voters_balance[proposing] >= 1e5) {
            return true;
        }
        return false;
    }

    // checking eligibility to vote on proposals
    function Voters_eligiblity(uint256 _id, address voter_)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < Proposal_Id[_id].Voters.length; i++) {
            if (Proposal_Id[_id].Voters[i] == voter_) {
                return true;
            }
        }
        return false;
    }

    // creating log record for any proposal created
    event Proposal_creation(
        uint256 id,
        string proposal_Description,
        uint256 maxvotes,
        address proposer
    );

    // function for creatingf proposal with defining conditions i.e., time duration and number of voters
    function Create_Proposal(string memory _description)
        public
        verifyAddress
    {
        require(
            proposal_creation_eligiblity(msg.sender),
            "Only members can create Proposal"
        );
        proposal storage Proposal_new = Proposal_Id[nextProposal];
        Proposal_new.id = nextProposal;
        Proposal_new.exists = true;
        Proposal_new.proposal_Description = _description;
        Proposal_new.deadline = block.timestamp + 3 minutes;
        // only those voters are eligible who are members of Dao during proposal creation and excluding those who became members after creation of proposal
        Proposal_new.Voters = proposal_data.Voters;
        Proposal_new.maxvotes = proposal_data.Voters.length;

        emit Proposal_creation(
            nextProposal,
            _description,
            proposal_data.Voters.length,
            msg.sender
        );
        // after proposal creation it will be assigned next integer value
        nextProposal++;
    }

    // Event to record number of votes casted
    event new_Votes(
        uint256 votesup,
        uint256 votesdown,
        address voter,
        uint256 proposal,
        bool voted_favour
    );

    // function defining voting system on proposal
    function Proposal_Votes(uint256 _id, bool _vote) public verifyAddress {
        require(Proposal_Id[_id].exists, "Proposal Not Exist");
        require(
            Voters_eligiblity(_id, msg.sender),
            "You are not eligible to Vote"
        );
        require(
            !Proposal_Id[_id].votestatus[msg.sender],
            "You have already casted your Vote"
        );
        require(
            block.timestamp <= Proposal_Id[_id].deadline,
            "Voting time has ended for this Proposal"
        );

        proposal storage Proposal_cast = Proposal_Id[_id];

        // condition defining like voting in favour will increase count and vice versa
        (_vote == true ? Proposal_cast.votesup++ : Proposal_cast.votesdown++);

        Proposal_cast.votestatus[msg.sender] = true;

        emit new_Votes(
            Proposal_cast.votesup,
            Proposal_cast.votesdown,
            msg.sender,
            _id,
            _vote
        );
    }

    // event to record counting of votes
    event Proposal_VoteCount(uint256 id, bool passed);

    // function to check vote casted and either proposal is passed or rejected
    function Countvotes(uint256 _id) public {
        require(
            proposal_creation_eligiblity(msg.sender),
            "Only Proposer can count Votes"
        );
        require(Proposal_Id[_id].exists, "Proposal not Exists");
        require(
            block.timestamp > Proposal_Id[_id].deadline,
            "Wait for voting to End"
        );
        require(!Proposal_Id[_id].count_Conduct, "Count already Conducted");

        proposal storage count_proposal = Proposal_Id[_id];

        // condition either proposal is passed or rejected
        if (Proposal_Id[_id].votesup > Proposal_Id[_id].votesdown) {
            count_proposal.passed = true;
        }

        count_proposal.count_Conduct = true;

        emit Proposal_VoteCount(_id, count_proposal.passed);
    }

    // function to withdraw funds after a proposal is passed
    function withdraw() external {
        payable(Owner).transfer(address(this).balance);
    }
}