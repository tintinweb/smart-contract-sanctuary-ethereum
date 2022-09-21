// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface DaoInterface {
    function balanceof(address, uint256) external view returns (uint256);
}

contract Dao {
    address public owner; // people can see who is thw owner of the dao smart contract
    uint256 nextProposal; // tracking of all proposal that community will raise
    uint256[] public validToken; // array which tell people or community that token is valid for vote and
    // only those can vote which has that specific token
    DaoInterface DaoContract;

    //26103710527787570589715339012700882498594913234942383717802006175351283122177
    //0x2953399124F0cBB46d2CbACD8A89cF0599974963
    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        DaoContract = DaoInterface(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validToken = [
            26103710527787570589715339012700882498594913234942383717802006175351283122177
        ];
        //this means that those who want to vote in their wallet they need validtoken = nft
    }

    struct Proposal {
        //extra feature you can add proposal name
        uint256 id; //id of each proposal
        bool exit; //verifying already proposal if it is already exit then exit will false and proposal will not raise
        string description; // description of proposal
        uint deadline; // deadline for vote
        uint256 votesUp; //how many votes our in favour
        uint256 votesDown; // how many votes our against
        address[] canVotes; //addresses of all the member which hold validtoken
        uint256 maxvotes; // how many votes does proposal is get (length)
        mapping(address => bool) voteStatus; // if person has already vote then voteStatus become true so he cant vote another time
        bool counConducted; // owner count the proposal for cast this is final wheater propsal need to passed or not
        bool passed; // proposal passed then true other wise fale
    }
    mapping(uint256 => Proposal) public Proposals; // basically it is proposal id and mapp into proposal
    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxvotes,
        address proposer /*who is making proposal*/
    );
    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor /*favour or against*/
    );
    event proposalCount(uint256 id, bool passed);

    ///@dev this function checkProposalEligibility will check wheather the persion is eligibale to make proposal or not
    /// if it consist any of our token than it is eligibale else not

    function checkProposalEligibility(address _proposalist)
        private
        view
        returns (bool)
    {
        for (uint i = 0; i < validToken.length; i++) {
            if (DaoContract.balanceof(_proposalist, validToken[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter)
        private
        view
        returns (bool)
    {
        for (uint i = 0; i < Proposals[_id].canVotes.length; i++) {
            //Proposals is mapping if we give Proposal id then it will give which Proposal it is
            // and in that proposal canVotes is array of all address or voter whom has token and length is for indexing
            if (Proposals[_id].canVotes[i] == _voter) {
                // if canVotes has address equal to _voter than eligibale for vote
                return true;
            }
        }
        return false;
    }

    function createProposal(
        string memory _discribtion,
        address[] memory _canVotes
    ) public {
        require(
            checkProposalEligibility(msg.sender),
            "only NFT holder can createProposal"
        );
        Proposal storage newProposal = Proposals[nextProposal]; //creating new proposal of type Proposal temporary thats why we store it into strorage
        newProposal.id = nextProposal;
        newProposal.exit = true;
        newProposal.description = _discribtion;
        newProposal.deadline = block.number + 100; // current blocknumber + 100 blocks (or we can set by making setfunc how long this proposal will go)
        newProposal.canVotes = _canVotes;
        newProposal.maxvotes = _canVotes.length;
        emit proposalCreated(
            nextProposal,
            _discribtion,
            _canVotes.length,
            msg.sender //those who call this function
        );
        nextProposal++; //so all proposal get unique id
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        //extra vote -> favor or against
        require(Proposals[_id].exit, "Proposal does not exit");
        require(
            checkVoteEligibility(_id, msg.sender),
            "you are not eligible for vote"
        );
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "you already voted on this proposal"
        );
        require(
            block.number <= Proposals[_id].deadline,
            "deadline has passed for this proposal"
        ); //current block number should not be grater than deadline block
        Proposal storage p = Proposals[_id];
        if (_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }
        p.voteStatus[msg.sender] = true;
        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner);
        require(Proposals[_id].exit, "Proposal does not exit");
        require(
            block.number > Proposals[_id].deadline,
            "voting is not complete"
        );
        require(!Proposals[_id].counConducted, "count is already cnducted");
        Proposal storage p = Proposals[_id];
        if (Proposals[_id].votesUp > Proposals[_id].votesDown) {
            p.passed = true;
        }
        p.counConducted = true;
        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner can add token id");
        validToken.push(_tokenId);
    }
}