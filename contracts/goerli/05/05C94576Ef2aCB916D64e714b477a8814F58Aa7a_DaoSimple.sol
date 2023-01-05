// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface MyNFT {
        function balanceOf(address) external view returns (uint256);
        function amountMintedNFT() external  view returns (uint num);
    }

contract DaoSimple {
    uint256 public nextProposal;
    MyNFT daoContract;

    constructor( address nft_contract){
        nextProposal = 1;
        daoContract = MyNFT(nft_contract);
    }

    struct proposal{
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
        address initiator;
    }

    mapping(uint256 => proposal) public Proposals;

    event proposalCreated(
        uint256 id,
        string description,
        address proposer
    );

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    event proposalCount(
        uint256 id,
        bool passed
    );

// NFT holdre can vore
    function checkNftHolder(address _proposalist) private view returns (bool){
        if(daoContract.balanceOf(_proposalist) != 0){
            return true;  
        }
        return false;
    }

    function createProposal(string memory _description, uint _time) public {
        require(checkNftHolder(msg.sender), "Only NFT holders can put Proposals");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + _time;
        newProposal.maxVotes = daoContract.amountMintedNFT();
         newProposal.initiator = msg.sender;

        emit proposalCreated(nextProposal, _description, msg.sender);
        nextProposal++;
    }


    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(checkNftHolder(msg.sender), "Only Nft-holder can vote on this Proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(block.timestamp <= Proposals[_id].deadline, "The deadline has passed for this Proposal");

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        }else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
        
    }

    function countVotes(uint256 _id) public {
        require(checkNftHolder(msg.sender), "Only NFT-holder Can Count Votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(block.timestamp > Proposals[_id].deadline, "Voting has finished yet");
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];
        
        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;            
        }
        p.countConducted = true;
        emit proposalCount(_id, p.passed);
    }

}