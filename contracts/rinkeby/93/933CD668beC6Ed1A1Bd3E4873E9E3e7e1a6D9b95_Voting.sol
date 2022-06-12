//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Voting {
    
    ///STRUCTURES

    struct candidate {
        address addr;
        uint votes;
    }

    struct voting {
        candidate[] candidates;
        mapping (address => bool) voters;
        uint creationTime;
        uint prizePull;
        bool finished;

    }

    uint comission;
    address owner;
    voting[] votings;

    ///MODIFIEERS

    modifier ownerOnly {
        require(owner == msg.sender, "You are not an owner");
        _;
    }

    ///EVENTS

    event votingCreated (
        uint vID,
        uint creationTime
    );

    event votingFinished (
        uint vID,
        uint prize
    );

    event voted (
        uint vID,
        uint candidate
    );

    event transfered (
        uint value
    );

    ///FUNCTIONS

    constructor () {
        owner = msg.sender;
    }

    function createVoting (address[] memory _candidates)
    external
    ownerOnly
    {
        votings.push();

        voting storage v = votings[votings.length-1];
        v.creationTime = block.timestamp;

        for (uint i; i<_candidates.length; ++i){
            v.candidates.push();
            v.candidates[i].addr = _candidates[i];
        }

        emit votingCreated(votings.length-1, v.creationTime);
    }

    function vote (uint _vID, uint _cID)
    external
    payable
    {
        require(votings[_vID].voters[msg.sender] == false, "You have already voted");
        votings[_vID].candidates[_cID].votes += 1;
        votings[_vID].voters[msg.sender] = true;
        votings[_vID].prizePull += 100000000000000000;
        
        emit voted (_vID, _cID);
    }

    function endVoting (uint _vID)
    external
    {
        require(block.timestamp >= votings[_vID].creationTime + 259200, "Can't be finished yet"); ///3*24*60*60
        require(votings[_vID].finished == false, "Voting is already ended");

        uint maxVotes;
        uint winnersNumber;
        uint winnerID;
        uint prize;

        comission = votings[_vID].prizePull *1/10;
        prize = votings[_vID].prizePull *9/10;

        for (uint i; i < votings[_vID].candidates.length; ++i) {                            /// предполагая что победитель 1 ищем его id 
            if (votings[_vID].candidates[i].votes > maxVotes){
                maxVotes = votings[_vID].candidates[i].votes;
                winnerID = i;
                winnersNumber = 1;
            }
        else if (votings[_vID].candidates[i].votes == maxVotes){
            winnersNumber += 1;         /// победитель не один значит увеличиваем их количество
        }
        }

        if (winnersNumber == 1){
            payable(votings[_vID].candidates[winnerID].addr).transfer(prize);         /// если один переводим ему 90 процентов
        }

        else if (winnersNumber > 1){                                                                    
           prize = (prize)*(1/winnersNumber);                              
           for (uint i; i < votings[_vID].candidates.length; ++i) {
                
                if (votings[_vID].candidates[i].votes == maxVotes){
                    winnerID = i;
                    payable(votings[_vID].candidates[winnerID].addr).transfer(prize);
                }
            }
        }
        
        votings[_vID].finished = true;
        emit votingFinished(_vID, prize);
    }

    function transferComission(address payable _to)
    external
    ownerOnly
    {
        if (comission == 0) revert ("Not enough balance");
        _to.transfer(comission);
        emit transfered(comission);
        comission = 0;
    }

    function info(uint _vID)
    external
    view
    returns(address [] memory) {
        
        address[] memory _candidates = new address[](votings[_vID].candidates.length);
        

        for (uint i; i < votings[_vID].candidates.length; ++i) {
            _candidates[i] = votings[_vID].candidates[i].addr;
    }
        return (_candidates);
    }

    function cinfo(uint _vID, uint _cID)
    external
    view
    returns(uint) {
        return(votings[_vID].candidates[_cID].votes);
    }

}