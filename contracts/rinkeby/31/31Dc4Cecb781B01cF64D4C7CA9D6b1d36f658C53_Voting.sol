// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Voting{
    
    struct candidate {
        address addr;
        uint votes;
    }

    struct voting {
       uint maxVotes;
       uint endTime;
       candidate[] candidates;
       uint prizePull;
       mapping (address => bool) voters;
       bool reasonable;
    }

    uint public comission;
    address public owner;
    voting[] votings;

    modifier ownerOnly {
        require (owner == msg.sender, "You are not an owner");
        _;
    }

    modifier votable (uint _vID) {
        require(votings[_vID].voters[msg.sender] == false, "You have already voted");
        require(votings[_vID].endTime > block.timestamp, "Voting has already finished");
        require(msg.value == 0.01 ether, "Transfer 0.01 ETH to vote");
        _;
    }

    modifier endable (uint _vID) {
        require(votings[_vID].endTime < block.timestamp, "Cant be finished");
        require(votings[_vID].reasonable == true, "Nobody has voted");
        _;
    }

    event votingCreated(uint vID);
    event voted(uint vID, uint cID);
    event votingFinished(uint vID);
    event transfered(address _to);


    constructor () {
        owner = msg.sender;
    }

    

    function createVoting(address[] memory _candidates) external ownerOnly {
        
        votings.push();

        voting storage v = votings[votings.length-1];
        v.endTime = block.timestamp + 3 minutes;

        for (uint i; i < _candidates.length; ++i) {
            v.candidates.push();
            v.candidates[i].addr = _candidates[i];
        }

        emit votingCreated(votings.length-1);
    }

    function vote (uint _vID, uint _cID) external payable votable(_vID) {

        votings[_vID].candidates[_cID].votes += 1;
        votings[_vID].voters[msg.sender] = true;
        votings[_vID].prizePull += 0.009 ether;
        votings[_vID].reasonable = true;
        comission += 0.01 ether;
        emit voted (_vID, _cID);
    }

    function endVoting (uint _vID) external payable endable(_vID) {
        bool canBeEnded;
        uint winnerID;
        

        for (uint i; i < votings[_vID].candidates.length; ++i) {
            if (votings[_vID].candidates[i].votes > votings[_vID].maxVotes){
                votings[_vID].maxVotes = votings[_vID].candidates[i].votes;
                winnerID = i;
                canBeEnded = true;
            }
            else if (votings[_vID].candidates[i].votes == votings[_vID].maxVotes){
                canBeEnded = false;
                break;
            }
        }

        if (canBeEnded == true) {
            payable(votings[_vID].candidates[winnerID].addr).transfer(votings[_vID].prizePull);
            emit votingFinished(_vID);
        }
        else {
            votings[_vID].endTime += 1 days;
        }

    }

    function transfer (address payable _to) external payable ownerOnly {
        require (comission > 0, "Cant transfer null value");
        _to.transfer(comission);
        comission = 0;
        emit transfered(_to);

    }

    function candidateInfo (uint _vID, uint _cID) external view returns(uint votes) {
        return(votings[_vID].candidates[_cID].votes);
    }


    function comissionInfo () external view returns (uint _comission) {
        return (comission);
    }

    function endInfo (uint _vID) external view returns (uint _endTime) {
        return (votings[_vID].endTime);
    }

}