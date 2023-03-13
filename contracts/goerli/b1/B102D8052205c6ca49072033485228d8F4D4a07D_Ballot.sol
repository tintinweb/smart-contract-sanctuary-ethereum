/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File contracts/TokenizedBallot.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
/// @title Voting with delegation.


interface IMyToken {
    function getPastVotes(address account, uint256 blockNumber) external view returns(uint256);    
}

contract Ballot {

    // This is a type for a single proposal.
    struct Proposal {
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    // A dynamically-sized array of `Proposal` structs.
    uint256 public blockTarget;
    IMyToken public tokenContract;
    Proposal[] public proposals;
    mapping(address => uint256) public votingPowerSpent;

    /// Create a new ballot to choose one of `proposalNames`.
    constructor(bytes32[] memory proposalNames, address _tokenContract, uint256 _blockTarget) {
        tokenContract = IMyToken(_tokenContract);
        blockTarget = _blockTarget;

        for (uint i = 0; i < proposalNames.length; i++) {
            // `Proposal({...})` creates a temporary
            // Proposal object and `proposals.push(...)`
            // appends it to the end of `proposals`.
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    /// Give your vote (including votes delegated to you)
    /// to proposal `proposals[proposal].name`.
    
    function vote(uint256 proposal, uint256 amount) external {
        //check if that person is able to vote
        require(votingPower(msg.sender) >= amount);
        votingPowerSpent[msg.sender] += amount;
        proposals[proposal].voteCount += amount;
    }

    function votingPower(address account) public view returns(uint256) {
        return tokenContract.getPastVotes(account, blockTarget) - votingPowerSpent[account];

    }
    
    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
    function winningProposal() public view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // Calls winningProposal() function to get the index
    // of the winner contained in the proposals array and then
    // returns the name of the winner
    function winnerName() external view
            returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
}