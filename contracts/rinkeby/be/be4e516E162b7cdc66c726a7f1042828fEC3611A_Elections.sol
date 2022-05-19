//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Elections {
    enum Sects {
        MARONITE,
        GREEK_CATHOLIC,
        GREEK_ORTHODOX,
        SUNNI,
        CHIITE
    }
    enum Regions {
        BEIRUT,
        MOUNT_LEBANON,
        NORTH,
        SOUTH,
        BEKAA
    }

    struct Candidate {
        uint256 candidateId;
        string name;
        Sects sect;
        Regions region;
    }
    Candidate[] public candidates;
    mapping(uint256 => uint256) public candidateToVoteCount;

    function runForCandidate(
        string memory name,
        Sects sect,
        Regions region
    ) public {
        uint256 id;
        if (candidates.length > 0) {
            id = candidates[candidates.length - 1].candidateId + 1;
        } else {
            id = 1;
        }
        Candidate memory candidate = Candidate(id, name, sect, region);
        candidates.push(candidate);
        candidateToVoteCount[id] = 0;
    }

    function viewCandidates() public view returns (Candidate[] memory) {
        return candidates;
    }

    function vote(string memory name) public {
        uint256 id = getCandidateId(name);
        require(
            id != 0,
            "Cannot find selected candidate. Pleae check spelling"
        );
        candidateToVoteCount[id] += 1;
    }

    function getCandidateId(string memory name)
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < candidates.length; i++) {
            string memory _name = candidates[i].name;
            if (keccak256(bytes(_name)) == keccak256(bytes(name))) {
                return candidates[i].candidateId;
            }
        }
        return 0;
    }

    function getWinner() public view returns (uint256, string memory) {
        uint256 highestVoteCount = 0;
        uint256 winnerId;
        string memory winnerName;
        for (uint256 i = 0; i < candidates.length; i++) {
            uint256 candidateId = candidates[i].candidateId;
            if (candidateToVoteCount[candidateId] > highestVoteCount) {
                highestVoteCount = candidateToVoteCount[candidateId];
                winnerId = candidateId;
                winnerName = candidates[i].name;
            }
        }
        return (winnerId, winnerName);
    }

    function getAllWinners() public view returns (uint256[] memory) {
        uint256[] memory winners;
        for (uint256 i = 0; i < uint256(Regions.BEKAA); i++) {
            uint256 highestVoteCount = 0;
            uint256 winnerId;
            for (uint256 j = 0; j < candidates.length; j++) {
                if (uint256(candidates[j].region) == i) {
                    uint256 candidateId = candidates[j].candidateId;
                    if (candidateToVoteCount[candidateId] > highestVoteCount) {
                        highestVoteCount = candidateToVoteCount[candidateId];
                        winnerId = candidateId;
                        winners[i] = winnerId;
                    }
                }
            }
        }
        return winners;
    }
}