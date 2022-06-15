/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// contract VotingFactory {
//     Voting[] public votings;

//     function createVoting(address[] memory proposalAddresses) public {
//         Voting newVoting = new Voting(
//             proposalAddresses,
//             msg.sender,
//             block.timestamp
//         );
//         votings.push(newVoting);
//     }

//     function getVotings() public view returns (Voting[] memory) {
//         return votings;
//     }
// }

contract Voting {
    struct Voter {
        bool voted;
        uint256 proposalIndex;
    }

    struct Proposal {
        address payable _address;
        uint256 voteCount;
    }

    Proposal[] public proposals;
    address public owner;
    mapping(address => Voter) public voters;
    uint256 public createdTime;
    uint256 public stepTime = 5 minutes;
    Proposal public winner;

    constructor(address[] memory proposalAddresses) {
        owner = msg.sender;
        createdTime = block.timestamp;

        for (uint256 i = 0; i < proposalAddresses.length; i++) {
            proposals.push(
                Proposal({
                    _address: payable(proposalAddresses[i]),
                    voteCount: 0
                })
            );
        }
    }

    function vote(uint256 _proposalIndex) public payable {
        require(
            block.timestamp < (createdTime + stepTime),
            "This voting has ended"
        );
        require(msg.value >= .01 ether);
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.proposalIndex = _proposalIndex;

        proposals[_proposalIndex].voteCount++;
    }

    function completeVoting() public {
        // require(voters[msg.sender],"You aren't voter");
        require(voters[msg.sender].voted, "You aren't voter"); //Голосование может закрыть только тот, кто проголосовал
        // require(
        //     block.timestamp >= (createdTime + stepTime),
        //     "Voting time not finished yet"
        // );

        uint256 winningVoteCount = 0;
        uint256 winningProposalId;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposalId = p;
            }
        }
        proposals[winningProposalId]._address.transfer(
            (address(this).balance * 9) / 10
        );
        winner = proposals[winningProposalId];
    }

    function withdrawCommission() public {
        require(
            msg.sender == owner,
            "You are not owner, and you do not have permissions"
        );
        payable(owner).transfer(address(this).balance);
    }

    function getProposals() public view returns (Proposal[] memory) {
        return proposals;
    }

    function getWinner() public view returns (Proposal memory) {
        return winner;
    }
    // function getVoters(address _voterAddress) public view returns(Voter ) {
    //     return voters[_voterAddress]
    // }
}