/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IMyToken {
    function getPastVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256);
}

contract Ballot {
    struct Proposal {
        bytes32 name;
        uint256 voteCount;
    }

    IMyToken public tokenContract;
    Proposal[] public proposals;
    uint256 public targetBlockNumber;
    mapping(address => uint256) public votingPowerSpent;

    constructor(
        bytes32[] memory proposalNames,
        address _tokenContract,
        uint256 _targetBlockNumber
    ) {
        tokenContract = IMyToken(_tokenContract);
        targetBlockNumber = _targetBlockNumber;
        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    function vote(uint256 proposal, uint256 amount) external {
        require(
            (votingPower(msg.sender) - votingPowerSpent[msg.sender]) >= amount
        );
        proposals[proposal].voteCount += amount;
        votingPowerSpent[msg.sender] += amount;
    }

    function votingPower(address account) public view returns (uint256) {
        return tokenContract.getPastVotes(account, targetBlockNumber);
    }

    function winningProposal() public view returns (uint256 winningProposal_) {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}