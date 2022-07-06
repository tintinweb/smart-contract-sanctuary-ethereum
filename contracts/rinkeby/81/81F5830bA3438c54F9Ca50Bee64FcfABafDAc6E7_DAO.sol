//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//This replicates the function that the Open Sea Store front has. In other words, it allows us to check
//balances of users who hold tokens in our DAO contract
interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract DAO {
    address public owner;
    uint256 nextProposal; //Every proposal will have a unique ID and we will keep track of them here
    uint256[] public validTokens; //Allows us to keep track of tokens that can be used for proposals and voting.
    IdaoContract daoContract;

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656);
        validTokens = [
            115608924051595165787345743206419760503893266853941309518323037221784182063144
        ];
    }

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint256 deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxVotes; //this is just the .length of the address[] canVote array
        mapping(address => bool) voteStatus; //prevents casting more than 1 vote on a proposal
        bool countConducted; //lets us know if votes have been counted yet. if not, voting deadline has not yet passed
        bool passed; //compares votesUp vs votesDown
    }

    mapping(uint256 => proposal) public Proposals; //maps proposalID to Proposal Struct

    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    event proposalCount(uint256 id, bool passed);

    function checkProposalEligibility(address _proposerAddress)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < validTokens.length; i++) {
            if (daoContract.balanceOf(_proposerAddress, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    //checkVoteEligibility takes the proposalID and address voter as inputs
    function checkVoteEligibility(uint256 _id, address _voter)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
            if (Proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    //The input _canVote here is the array of addresses we want to give permission to vote on this proposal
    function createProposal(
        string memory _description,
        address[] memory _canVote
    ) public {
        require(
            checkProposalEligibility(msg.sender),
            "Only NFT holders can put forth Proposals"
        );
        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;
        emit proposalCreated(
            nextProposal,
            _description,
            _canVote.length,
            msg.sender
        );
        nextProposal++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(
            checkVoteEligibility(_id, msg.sender),
            "You can not vote on this Proposal"
        );
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "You have already voted on this Proposal"
        );
        require(
            block.number <= Proposals[_id].deadline,
            "The deadline has passed for this Proposal"
        );

        proposal storage p = Proposals[_id];
        if (_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }
        p.voteStatus[msg.sender] = true;
        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner Can Count Votes");
        require(Proposals[_id].exists, "This Proposal Does Not Exist");
        require(
            block.number > Proposals[_id].deadline,
            "Voting Has Not Concluded"
        );
        require(!Proposals[_id].countConducted, "Count Already Conducted");

        proposal storage p = Proposals[_id];

        if (Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner Can Add Token");
        validTokens.push(_tokenId);
    }
}