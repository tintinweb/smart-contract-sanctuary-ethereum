/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/Election.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Election {
    uint public idenCandidates = 0;
    uint public idenAmphoras = 0;
    uint public counter = 0;    

    struct Candidate {
        uint identyfier;
        string group;
        uint voteCount;
        bool valid;
    }

    struct Vote {
        uint counter;
        string code;
        address addr;
    }

    struct Amphora {
        string name;
        address addr;   
        bool valid;     
    }

    constructor(){
        newCandidate("APP");
    }

    event ballot(uint _choise, string _code);
    event addedAmphora(string _name);
    event addedCandidate(string _group);

    mapping (address => Amphora) public amphoras;
    Candidate[] public candidates;
    mapping (uint => Vote) public votes;

    function newCandidate(string memory _group) public {
        candidates.push(Candidate(idenCandidates + 1, _group, 0, true));
        idenCandidates++;
        emit addedCandidate(_group);
    }

    function newAmphora(string memory _name, address _addrr) public {
        amphoras[_addrr] = Amphora(_name, _addrr, true);
        idenAmphoras++;
        emit addedAmphora(_name);
    }

    function validateAmphora(address _from) public view returns (bool) {
        bool result = false;

        if(amphoras[_from].valid) result = true;

        return result;
    } 

    function validateOption(uint16 _option) private returns (bool) {
        bool result = false;

        if(candidates[_option-1].valid) {
            candidates[_option-1].voteCount++;
            result = true;
        }
        
        return result;
    }

    function voting(uint16 _option, string memory _code) public {
        require(validateAmphora(msg.sender), "Usted esta ingresando desde una Amfora no registrada");

        require(validateOption(_option), "La opcion que usted eligio no es valida");

        votes[counter] = Vote(counter + 1, _code, msg.sender);
        counter ++;
        emit ballot(_option, _code);
    }    

    function getCandidates(uint id) public view returns (Candidate memory) {
        return candidates[id];
    }

    //0x5FbDB2315678afecb367f032d93F642f64180aa3
}