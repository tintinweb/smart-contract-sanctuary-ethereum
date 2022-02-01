/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


/** 
 * @title PTBallot
 * @dev Implements publically viewable party designation and time limitation to the Remix delegate voting contract
 */

contract PTBallot {
   
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted candidate
    }

    struct Candidate {
        // If you can limit the length to a certain number of bytes, 
        // always use one of bytes1 to bytes32 because they are much cheaper
        bytes32 name;   // short name (up to 32 bytes)
        bytes32 party; // party name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    address public chairperson;

    uint public expirationDate;

    mapping(address => Voter) private voters;

    Candidate[] public candidates;

    /** 
     * @dev Create a new ballot to choose one of 'candidateNames'.
     * @dev Limits amountOfDays to uint8 (0-255) to limit the max ballot timelength.
     * @param candidateNames names of candidates
     * @param candidateParties names of parties
     * @param amountOfDays number of days ballot is open
    
     */
    constructor(bytes32[] memory candidateNames, bytes32[] memory candidateParties, address chairAddress, uint8 amountOfDays) {
        require(candidateNames.length == candidateParties.length);
        require(amountOfDays != 0);
        chairperson = chairAddress;
        voters[chairperson].weight = 1;

        expirationDate = block.timestamp + (amountOfDays * 1 days);

        for (uint i = 0; i < candidateNames.length; i++) {
            // 'Candidate({...})' creates a temporary
            // Candidate object and 'candidates.push(...)'
            // appends it to the end of 'candidates'.
            candidates.push(Candidate({
                name: candidateNames[i],
                party: candidateParties[i],
                voteCount: 0
            }));
        }
    }


    //@dev: modifier to restrict voting functions unless the ballot is within the expirationDate;
    modifier isNotExpired() 
    {
        require(block.timestamp < expirationDate);
            _;
    }
        
    
    /** 
     * @dev Give 'voter' the right to vote on this ballot. May only be called by 'chairperson'.
     * @param voter address of voter
     */
    function giveRightToVote(address voter) public isNotExpired {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    /**
     * @dev Delegate your vote to the voter 'to'.
     * @param to address to which vote is delegated
     */
    function delegate(address to) public isNotExpired {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // We found a loop in the delegation, not allowed.
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            // If the delegate already voted,
            // directly add to the number of votes
            candidates[delegate_.vote].voteCount += sender.weight;
        } else {
            // If the delegate did not vote yet,
            // add to her weight.
            delegate_.weight += sender.weight;
        }
    }

    /**
     * @dev Give your vote (including votes delegated to you) to candidate 'candidates[candidate].name'.
     * @param candidate index of candidate in the candidates array
     */
    function vote(uint candidate) public isNotExpired {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = candidate;

        // If 'candidate' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        candidates[candidate].voteCount += sender.weight;
    }

    /** 
     * @dev Computes the winning candidate taking all previous votes into account.
     * @return winningCandidate_ index of winning candidate in the candidates array
     */
    function winningCandidate() public view
            returns (uint winningCandidate_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < candidates.length; p++) {
            if (candidates[p].voteCount > winningVoteCount) {
                winningVoteCount = candidates[p].voteCount;
                winningCandidate_ = p;
            }
        }
    }

    /** 
     * @dev Calls winningCandidate() function to get the index of the winner contained in the candidates array and then
     * @return winnerName_ the name of the winner
     * @return winnerParty_ the party of the winner
     */
    function winnerDetails() public view
            returns (bytes32 winnerName_, bytes32 winnerParty_)
    {
        winnerName_ = candidates[winningCandidate()].name;
        winnerParty_ = candidates[winningCandidate()].party;
    }
    

    /** 
     * @dev Gets the time left for a ballot by subtracting the expiration date from the current date.
     * @return endDate_ the time left, in days, before the ballot expires

     */
     function ballotEndDate() public view
            returns (uint endDate_)
    {
        endDate_ = expirationDate - block.timestamp;
    }
}