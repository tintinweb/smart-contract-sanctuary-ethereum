// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract DAO {

    mapping (address=>bool) public investors;
    mapping (address=>uint) public shares;
    mapping(uint256=>InvestmentProposal) proposals;
    mapping(address=>mapping(uint256=>bool)) votes;
    uint256 public totalShares;
    uint256 public availableFunds; // the funds available in the contract
    uint256 public contributionEnd;
    uint256 public voteTime;
    uint256 proposalId;
    uint256 public quorum;
    address public admin;

    struct InvestmentProposal {
        uint256 id;
        string name;
        uint256 votes;
        address payable to;
        uint256 amount;
        uint256 end;
        bool executed;
    }

    constructor (uint256 _end,uint256 _voteTime,uint256 _quorum) {
        contributionEnd=block.timestamp+_end;
        admin = msg.sender;
        voteTime=_voteTime;
        quorum=_quorum;
    }

    fallback() external payable {
        availableFunds+=msg.value;
    }

    function invest() payable external {
        require(block.timestamp<=contributionEnd,"Can only invest before end time");
        investors[msg.sender]=true;
        shares[msg.sender]+=msg.value;
        totalShares+=msg.value;
        availableFunds+=msg.value;
    }

    function redeemShare(uint256 amount) external {
        require(shares[msg.sender]>=amount,"Dont have enough shares");
        require(availableFunds>=amount,"Not enough funds available");
        shares[msg.sender]-=amount;
        payable(msg.sender).transfer(amount);
        availableFunds-=amount; 
    }

    function transferShares(uint256 amount,address to) external {
        require(shares[msg.sender]>=amount,"Dont have enough shares");
        shares[msg.sender]-=amount;
        shares[to]+=amount;
        investors[to]=true;

    }

    function createProposal(string memory name,uint256 amount,address payable to) external onlyInvestor(){
        require(availableFunds>=amount,"Amount too big");
        proposals[proposalId]=InvestmentProposal(proposalId,name,0,to,amount,block.timestamp+voteTime,false);
        availableFunds-=amount;
        proposalId++;
    }

    function vote(uint256 id) external onlyInvestor() {
        require(votes[msg.sender][id]==false,"Can only vote once");
        require(proposals[id].executed==false,"Already executed");
        require(block.timestamp<=proposals[id].end,"Proposal voting time has ended");
        votes[msg.sender][id]=true;
        proposals[id].votes+=shares[msg.sender];
       
    }

    function executeProposal (uint256 id) external onlyAdmin() {
        InvestmentProposal storage proposal = proposals[id];
        require(proposal.executed==false,"Already executed");
        require(proposal.end<=block.timestamp,"Can only execute after a proposal ends");
        require((proposal.votes / totalShares)*100 >= quorum,"Not enough votes");
        _transferEther(proposal.amount,proposal.to);
        proposal.executed=true;
    }

    function _transferEther(uint256 amount,address payable to) internal {
        to.transfer(amount);
    }

    modifier onlyInvestor() {
        require(investors[msg.sender],"Can only called by investor");
        _;
    }

    modifier onlyAdmin(){
        require(msg.sender==admin,"Only admin allowed");
        _;
    }


}