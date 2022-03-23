/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

// TODO
// only owner for reveal
// onion layer (array of commitments, )

contract CommitReveal {
    /// ============ Types ============

    // Possible votes (and Hidden before votes are revealed)
    enum Candidates {
        Hidden,
        A,
        B
    }

    // A cryptographic committment to a certain vote
    struct VoteCommit {
        bytes32 commitment;
        Candidates candidates;
    }

    /// ============ Immutable storage ============

    uint256 public immutable voteDeadline = 1648123200; // Vote phase ends Mar 24, 2022 @ 12PM UTC
    uint256 public immutable revealDeadline = 1642665600; // Reveal phase ends Jan 20, 2022
    uint256 public immutable totalCandidates = 8; // total number of candidates for election

    /// ============ Mutable storage ============

    // Tracks vote commitments
    mapping(address => VoteCommit) public votes;

    // Tracks voters that voted
    mapping(address => bool) private checkVoter;
    address[] public voters;

    /// ============ Events ============

    event Vote(address indexed voter, bytes32 commitment);
    event Reveal(address indexed voter, Candidates ballot);

    constructor() {}

    /// ============ Functions ============

    function castHiddenVote(bytes32 commitment) external {
        // Ensure vote is placed before vote deadline
        // require(
        //     block.timestamp <= voteDeadline,
        //     "Cannot vote past vote deadline."
        // );

        // Ensure wallet is registered to vote
        // require(
        //     msg.sender <check>,
        //     "You are not registered to vote"
        // );

        // Store the commitment for the commit-reveal scheme
        votes[msg.sender] = VoteCommit(commitment, Candidates.Hidden);

        // Save voter address
        if (checkVoter[msg.sender] != true) {
            voters.push(msg.sender);
            checkVoter[msg.sender] = true;
        }

        // Emit Vote event
        emit Vote(msg.sender, commitment);
    }

    function reveal(bytes32 blindingFactor) external {
        // Ensure reveal is before reveal deadline
        // require(
        //     block.timestamp <= revealDeadline,
        //     "Cannot reveal past reveal deadline."
        // );

        // Check all voters votes
        for (uint i = 0; i < voters.length; i++) {
           
            // Get voter address
            address voterAddress = voters[i];

            // Retrieve VoteCommit struct
            VoteCommit storage vote = votes[voterAddress];

            // calculate its candidate
            if (keccak256(abi.encodePacked(voterAddress, uint8(21), blindingFactor)) == vote.commitment) {
                // vote.candidates = Candidates.A;
                emit Reveal(voterAddress, Candidates.B);
                emit Reveal(voterAddress, Candidates.A);

            } else if (keccak256(abi.encodePacked(voterAddress, uint8(12), blindingFactor)) == vote.commitment) {
                // vote.candidates = Candidates.B;                
                emit Reveal(voterAddress, Candidates.A);
                emit Reveal(voterAddress, Candidates.B);

            } else {
                // vote.candidates = Candidates.Hidden;
                emit Reveal(voterAddress, Candidates.Hidden);
            }
        }        
    }
}