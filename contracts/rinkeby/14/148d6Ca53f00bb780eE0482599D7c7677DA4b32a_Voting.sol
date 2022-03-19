// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Voting {
    struct Voter {
        bool canVote;
        bool isVoted;
        address votedPresident;
    }

    struct PresidentialCandidate {
        bytes32 name;
        uint256 voteCount;
        bool isPresident;
    }

    mapping(address => Voter) public voters;
    mapping(address => PresidentialCandidate) public presidentialCandidates;
    address[] public presidentialCandidatesAddress;

    address public administrator;

    constructor() {
        administrator = msg.sender;
    }

    // ADD VOTERS
    function addVoters(bytes20[] memory voterAddresses)
        public
        returns (uint256)
    {
        require(msg.sender == administrator, "You are not authorized!");
        uint256 voters_created = 0;
        for (uint256 i = 0; i < voterAddresses.length; i++) {
            address voterAddress = address(voterAddresses[i]);
            if (voters[voterAddress].canVote || voters[voterAddress].isVoted)
                continue;
            Voter memory newVoter;
            newVoter.canVote = true;
            newVoter.isVoted = false;
            voters[voterAddress] = newVoter;
            voters_created += 1;
        }
        return voters_created;
    }

    // ADD PRES CANDIDATES
    // VOTE
    // CHECKWINNER
}