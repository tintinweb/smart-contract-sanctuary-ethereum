/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: GPL-3.0
// File: contracts/NftProjectName.sol



pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

/** 
 * @title NftProjectName
 * @dev Implements voting process along with vote delegation
 */
contract NftProjectName {
   
    struct Voter {
        bool voted;  // if true, that person already voted
        uint8 vote;   // index of the voted proposal
    }

    struct Proposal {
        string name; // proposal name
        string shortDescription; // short description of proposal
        uint8 voteCount; // number of accumulated votes
    }

    address public creator;

    bool public votingOpen;

    Proposal[] public proposals;

    mapping(address => Voter) private voters;

    address payable[] private participantAddresses;
    
    string public winnerProposal;
    
    address payable public winnerAddress;

    uint256 public reward;

    event Winner(address indexed winnerAddress, string indexed winnerProposal);

    /**
     * @dev Create a new ballot to choose one of project proposals
     */
    constructor() {
        creator = msg.sender;
        votingOpen = false;
    }

    /**
     * @dev If voting is open, accept and register name proposals. 
     * Required one ether to participate
     * @param _projectNameProposal name of proposal
     */
    function sendProposal(string memory _projectNameProposal, string memory _optionalProposalDescr) public payable {
        // One ether required to register your proposal
        require(msg.value == 1000000000000000000, "Didn\'t send enough quantity (1 ether)");
        reward++;

        // Voter reference
        participantAddresses.push(payable(msg.sender));

        // Add proposal to list
        proposals.push(Proposal({
            name: _projectNameProposal,
            shortDescription: _optionalProposalDescr,
            voteCount: 0
        }));
    }

    /**
     * @dev Do not accept more proposals. So, it's time to vote!! Only sender can do this.
     */
     function closeProposalPeriod() public {
        require(msg.sender == creator, "Only creator can close proposal period");
        require(proposals.length > 0, "Cannot close proposal time, there are no proposals");
        votingOpen = true;
    }

    /**
     * @dev Vote a project proposal, indicating its ID. You cannot vote your proposal
     * @param _proposalId ID of proposal
     */
    function voteProjectName(uint8 _proposalId) public {
        // Control votes out of voting period time
        require(votingOpen == true, "The voting period is not currently open");
      
        // Voter reference
        Voter storage sender = voters[msg.sender];

        // A sender can only vote once
        require(!sender.voted, "You have already voted");

        // A voter cannot vote on their own proposal
        require(participantAddresses[_proposalId] != msg.sender, "You cannot vote your own proposal");

        // Add vote 
        proposals[_proposalId].voteCount++;

        // Register user vote
        sender.voted = true;
        sender.vote = _proposalId;
    }
  
    /**
     * @dev Decide which proposal is the winner
     */
    function winningDecision() public payable {
        // Voting must be open 
        require(votingOpen == true, "The voting period is not currently open");

        // Iterate over the proposals
        // `winningProposal` is the index of the proposal with the most votes
        uint8 winningVoteCount;
        uint8 winningProposal;
        for (uint8 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal = p;
            }
        }

        // Winning proposal must have at least one vote
        require(proposals[winningProposal].voteCount > 0, "Winning proposal must have at least one vote");

        // Assign winners (storage variables)
        winnerAddress = participantAddresses[winningProposal];
        winnerProposal = proposals[winningProposal].name;

        // Transfer all ethers accumulated to the winner
        winnerAddress.transfer(reward * 1000000000000000000);
        
        // Reset voting global variables
        reward = 0;
        votingOpen = false;

        // Emit event with the winner
        emit Winner(winnerAddress, winnerProposal);
    }

    /**
     * @dev Obtain current proposal list/tuple
     */
    function getProposalList() public view returns (Proposal[] memory) {
        Proposal [] memory proposalList = new Proposal[](proposals.length);
        for (uint8 i = 0; i < proposals.length; i++) {
            Proposal memory proposal = proposals[i];
            proposalList[i] = proposal;
        }
        return proposalList;
    }   
}