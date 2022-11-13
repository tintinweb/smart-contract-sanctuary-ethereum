/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IMyToken {
    function getPastVotes(address, uint256) external view returns (uint256);
}

contract TokenizedBallot {
    struct Proposal {
        bytes32 name;
        uint256 voteCount;
    }

    Proposal[] public proposals;
    IMyToken public tokenContract;
    uint256 public targetBlockNumber;

    mapping(address => uint256) votingPowerSpent;

    constructor(
        bytes32[] memory proposalNames,
        address _tokenContractAddress,
        uint256 _targetBlockNumber
    ) {
        tokenContract = IMyToken(_tokenContractAddress);
        targetBlockNumber = _targetBlockNumber;
        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    function vote(uint256 proposal, uint256 amount) external {
        require(votingPower(msg.sender) >= amount, "Not enough voting power!");
        votingPowerSpent[msg.sender] += amount;
        proposals[proposal].voteCount += amount;
    }

    function votingPower(address account) public view returns (uint256) {
        uint256 votePower = tokenContract.getPastVotes(account, targetBlockNumber) -
            votingPowerSpent[account];
        return votePower;
    }

    function winningProposal() public view returns (uint256 winningProposalIndex) {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposalIndex = p;
            }
        }
    }

    function winnerName() public view returns (bytes32 winnerProposalName) {
        winnerProposalName = proposals[winningProposal()].name;
    }

    function testWithArray(bytes32[] memory param) public {}
}