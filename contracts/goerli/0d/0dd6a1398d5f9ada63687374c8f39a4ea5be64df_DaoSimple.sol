/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/*
   ______  ______               ______     ______  
 .' ___  ||_   _ `.           .' ____ \  .' ___  | 
/ .'   \_|  | | `. \  ______  | (___ \_|/ .'   \_| 
| |         | |  | | |______|  _.____`. | |        
\ `.___.'\ _| |_.' /          | \____) |\ `.___.'\ 
 `.____ .'|______.'            \______.' `.____ .' 
   ChubiDuracell                 smart contract
                    V2
*/

interface MyNFT {
        function balanceOf(address) external view returns (uint256);
        function amountMintedNFT() external  view returns (uint num);
    }

contract DaoSimple {
    uint256 public nextProposal;
    MyNFT nftContract;

    constructor( address nft_contract){
        nextProposal = 1;
        nftContract = MyNFT(nft_contract);
    }
// enum Status{Exists, CountConducted, Passed}
    struct proposal{
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
        address initiator;
        address target; //Contract to triger
        bytes funcExecute;  // func in this sc
        uint256 ethToSend;  // if func required to send ETH
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

// VerifyCallResult
    event Execute(
        uint256 id,
        bool done,
        bytes returndata
    );


    

// NFT holdre can vore
    function checkNftHolder(address _proposalist) private view returns (bool){
        if(nftContract.balanceOf(_proposalist) != 0){
            return true;  
        }
        return false;
    }

    function createProposal(string memory _description, uint _time, address _target, uint256 _ethValue, bytes memory _funcExecute) public {
        require(checkNftHolder(msg.sender), "Only NFT holders can put Proposals");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + _time;
        //newProposal.maxVotes = nftContract.amountMintedNFT();
        newProposal.initiator = msg.sender;
        newProposal.target = _target;
        newProposal.funcExecute = _funcExecute;
        newProposal.ethToSend = _ethValue;


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

    function finish(uint256 _id) public {
        require(checkNftHolder(msg.sender), "Only NFT-holder Can Count Votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(isItFinished(_id), "Voting is not finished yet");
        require(!Proposals[_id].countConducted, "Count already conducted");
   
        proposal storage p = Proposals[_id];
        
        if(Proposals[_id].votesDown < Proposals[_id].votesUp && _quorumReached(_id)){
            p.passed = true;
            _execute(_id, p.target, p.ethToSend, p.funcExecute); //After auction is done execute func            
        }
        p.countConducted = true;
        emit proposalCount(_id, p.passed);
    }
//----------------------------------------------
   function _execute(uint256 _id, address _target, uint256 _value, bytes memory _calldata) private {
            (bool success, bytes memory returndata) = _target.call{value: _value}(_calldata);
            emit Execute(_id, success, returndata);
        }

        //DEV
    function isItFinished(uint _id) public view returns(bool){
        return block.timestamp >= Proposals[_id].deadline;
    }

    
//---------------------QUORUM-------------------------
    uint public quorum; //Amount of NFT holder that votes on propsal

// Who should be an owner? Contract it self?
     function setQuorum(uint _quorum) public {
         require(_quorum <= nftContract.amountMintedNFT(), "There are not enough mined NFT to set this quorum");
         quorum = _quorum;
     }
     function _quorumReached(uint256 _id) public view returns (bool){
         return Proposals[_id].votesUp + Proposals[_id].votesDown >= quorum;
     }

     //Add func to cancel >>>> Proposals[_id].exists = false ???

    receive() external payable { }
    fallback() external payable { }
}