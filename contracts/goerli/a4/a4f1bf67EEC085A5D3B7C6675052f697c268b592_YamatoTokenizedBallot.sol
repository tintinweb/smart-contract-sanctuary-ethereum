/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IYamato {
    function getPastVotes(address account, uint256 blockNumber) external view returns(uint256);
}

contract YamatoTokenizedBallot {
    struct Proposal {
        bytes32 name;   
        uint voteCount; 
    }
    uint256 public blockTarget;
    IYamato public tokenContract;
    Proposal[] public proposals;
    address public owner;

    mapping(address => uint256) public votingPowerSpent;

    constructor(bytes32[] memory proposalNames, address _tokenContract, uint256 _blockTarget ) {
        owner = msg.sender;
        tokenContract = IYamato(_tokenContract);
        blockTarget = _blockTarget;
        for (uint i = 0; i < proposalNames.length; i++) {

            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Error only Owner can call this function");
        _;
    }

    function vote(uint proposal, uint256 amount) external {
        // Check if that person is able to vote
        require(votingPower(msg.sender) >= amount);
        votingPowerSpent[msg.sender] += amount;
        proposals[proposal].voteCount += amount;
    } 

    function votingPower(address account) public view returns(uint256){
        return tokenContract.getPastVotes(account, blockTarget) -
        votingPowerSpent[account] ;
    }


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

    function winnerName() external view
            returns (bytes32 winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }

    function setSnapshotBlock(uint256 newTargetBlock) public onlyOwner() {
        require(newTargetBlock >= 0 && newTargetBlock < block.number); 
            blockTarget = newTargetBlock;
    }

}