/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITokenizedVotes{
    function getPastVotes(address, uint) external view returns(uint);
}

contract TokenizedBallot{
    
    uint public referenceBlock;
    ITokenizedVotes public tokenContract;

    struct Proposal{
        bytes32 name;
        uint voteCount;
    }

    Proposal[] public proposals;
    mapping (address => uint) public votePowerSpent;

    constructor(bytes32[] memory proposalNames, ITokenizedVotes _tokenContract, uint _referenceBlock){
        for (uint256 i = 0; i < proposalNames.length; i++) {    
            proposals.push(Proposal({voteCount:0 , name: proposalNames[i]}));
        }
        tokenContract = _tokenContract;
        referenceBlock = _referenceBlock;
    }

    function vote(uint proposal , uint amount) public{
        uint votingPower = votePower(msg.sender);
        require(votingPower >= amount, "Tried to vote more than your vote power");
        votePowerSpent[msg.sender] += amount;
        proposals[proposal].voteCount += amount;
    }

    function votePower(address account)public view returns(uint256 _votePower){
        _votePower = tokenContract.getPastVotes(account,referenceBlock) - votePowerSpent[account];
    }

    function winningProposal() public view returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() external view
            returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }

}