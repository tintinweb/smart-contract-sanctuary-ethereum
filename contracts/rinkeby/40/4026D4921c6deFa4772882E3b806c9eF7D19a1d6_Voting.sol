//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

contract Voting {

    struct Candidates {
        uint256 candidateId;
        address candidateAddress;
        string  name;
        string  websiteLink;
    }

    address public admin = address(0x6E9a78ec2B32e1129fEe558D71861806c478AA1A);
    Candidates[] public candidates;
    address [] public voters;
    address [] public votersVoted;
    bool public isActive;

    mapping (uint256 => uint256) public votesReceived;

    uint256 count = 1;

    function transferAdmin(address _newAdmin) external {
        require(msg.sender == admin, "Only admin can start vote");
        admin = _newAdmin;
    }

    function startVote() external {
        require(msg.sender == admin, "Only admin can start vote");
        isActive = true;
    }

    function stopVote() external {
        require(msg.sender == admin, "Only admin can stop vote");
        isActive = true;
    }

    function addVoter(address _voter) external {
        require(msg.sender == admin, "Only admin can add voter");
        voters.push(_voter);
    }

    function addCandidate(string memory _candidateName, address _candidateAddress, string memory _candidateWebsite) external {
        require(msg.sender == admin);
        Candidates memory candidate = Candidates(
            count,
            _candidateAddress,
            _candidateName,
            _candidateWebsite
        );
        candidates.push(candidate);
        count += 1;
    }

    function isValidVoter(address _voterAddress) public view returns(bool) {
        for(uint256 i = 0; i < voters.length; i++) {
            if(voters[i] == _voterAddress) {
                return true;
            }
        }
        return false;
    }

    function isValidCandidate(uint256 _candidateId) public view returns(bool) {
        for(uint256 i = 0; i < candidates.length; i++) {
            if(candidates[i].candidateId == _candidateId) {
                return true;
            }
        }
        return false;
    }

    function vote(uint256 _candidateId) public {
        require(isValidVoter(msg.sender), "Not a valid voter");
        require(isValidCandidate(_candidateId), "Not a valid candidate");
        if(votesReceived[_candidateId] == 0) {
            votesReceived[_candidateId] = 1;
        } else {
            votesReceived[_candidateId] += 1;
        }
    }

    function whoIsWinner() public view returns(uint256) {
        require(!isActive, "Winner is declared only after election ends");

        uint256 max = 0;
        uint256 winnerId = 0;
        for(uint256 i = 0; i < candidates.length; i++) {
            if(votesReceived[candidates[i].candidateId] > max) {
                max = votesReceived[candidates[i].candidateId];
                winnerId = candidates[i].candidateId;
            }
        }

        return winnerId;
    }
}