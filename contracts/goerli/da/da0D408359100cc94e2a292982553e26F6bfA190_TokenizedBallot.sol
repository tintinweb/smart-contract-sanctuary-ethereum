// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IMyERC20Votes {
    function getPastVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256);
}

error NotEnoughVotingPower(uint256 required, uint256 inControl);

contract TokenizedBallot {
    struct Proposal {
        bytes32 name;
        uint256 voteCount;
    }
    IMyERC20Votes public immutable tokenContract;
    uint256 public targetBlockNumber;
    Proposal[] public proposals;

    mapping(address => uint256) public votingPowerSpent;

    constructor(
        bytes32[] memory proposalNames,
        address _tokenContractAddress,
        uint256 _targetBlockNumber
    ) {
        tokenContract = IMyERC20Votes(_tokenContractAddress);
        targetBlockNumber = _targetBlockNumber;
        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    function vote(uint256 proposal, uint256 amount) external {
        uint256 _votingPower = votingPower(msg.sender);
        if (_votingPower < amount)
            revert NotEnoughVotingPower(amount, _votingPower);
        votingPowerSpent[msg.sender] += amount;
        proposals[proposal].voteCount += amount;
    }

    function votingPower(address account) public view returns (uint256) {
        return
            tokenContract.getPastVotes(account, targetBlockNumber) -
            votingPowerSpent[account];
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