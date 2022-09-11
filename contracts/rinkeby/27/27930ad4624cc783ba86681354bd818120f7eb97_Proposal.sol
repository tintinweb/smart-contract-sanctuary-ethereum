/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

/**
* @title Proposal
* @dev Allow users to vote on a proposal for option1 or option2. The user has to pay a fee to vote
* and can only vote one time on a proposal.
*/
contract Proposal {
    event VoteCasted(uint256 indexed proposalId, address indexed from, uint256 vote);

    // stores the votes of the users for a proposal. This variable is internal
    mapping(uint256 => mapping(address => uint256)) internal votes; // 0: didn't vote, 1: voted for Leadership, 2: voted for User Experience
    // Id of the current proposal. Initial value is 0. This variable can be accessed externally
    uint256 public proposalId;
    // amount of votes for 'Leadership' for the current proposal. This variable can be accessed externally
    uint256 public votesForLeadership;
    // amount of votes for 'UserExperience' for the current proposal. This variable can be accessed externally
    uint256 public votesForUserExperience;
    // fee required to perform the vote. This variable can be accessed externally
    uint256 public constant VOTE_FEE = 0.0001 ether; // 1000 gwei

    /**
    * @dev Performs a vote for the current proposal.
    * @param _vote integer representation of the vote
    */
    function vote(uint256 _vote) external payable {
        require(_vote == 1 || _vote == 2, "Can only vote with 1 (Leadership) or 2 (UserExperience)");
        require(votes[proposalId][msg.sender] == 0, "Ya has votado antes");
        require(msg.value == VOTE_FEE, "Debes enviar 0.0001 ETH de fee para votar");

        votes[proposalId][msg.sender] = _vote;

        if (_vote == 1) {
            votesForLeadership++;
        } else {
            votesForUserExperience++;
        }

        emit VoteCasted(proposalId, msg.sender, _vote);
    }
    
    /**
    * @dev Returns the vote of the user for the current proposal.
    * @param _user address of the user
    * @return integer representation of the vote 
    */
    function getVote(address _user) external view returns(uint256) {
        return votes[proposalId][_user];
    }

    /**
    * @dev Clean the current vote state and creates a new proposal.
    * This method is useful for developers to start a new proposal for testing purposes.
    */
    function clean() external {
        proposalId++;
        votesForLeadership = 0;
        votesForUserExperience = 0;
    }
}