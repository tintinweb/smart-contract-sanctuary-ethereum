/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract VotingSystem {
    struct Verificator {
        uint nik;
        string name;
        string role;
        int latitude;
        int longitude;
    }

    struct Voter {
        uint nik;
        string name;
        int latitude;
        int longitude;
        bool voted; // is this person has voted?
        Verificator[] verificators;
    }

    struct Candidate {
        uint nik;
        string name;
        Voter[] voters;
    } 

    mapping(uint => Verificator) internal verificators;
    mapping(uint => Candidate) internal candidates;
    mapping(uint => Voter) internal voters;

    function vote(
        uint _voternik,
        uint _candidatenik,
        int _latitude,
        int _longitude
        // Verificator[] memory _verifiers
    ) public {
        voters[_voternik].voted = true;
        voters[_voternik].latitude = _latitude;
        voters[_voternik].longitude = _longitude;
        // voters[_voternik].verificators = _verifiers;
        candidates[_candidatenik].voters.push(voters[_voternik]);
    }

    function registerVerificator(
        uint _nik,
        string memory _name,
        string memory _role,
        int _latitude,
        int _longitude
    ) public {
        verificators[_nik].nik = _nik;
        verificators[_nik].name = _name;
        verificators[_nik].role = _role;
        verificators[_nik].latitude = _latitude;
        verificators[_nik].longitude = _longitude;
    }

    function registerCandidate(
        uint _nik,
        string memory _name
    ) public {
        candidates[_nik].nik = _nik;
        candidates[_nik].name = _name;
    }

    function registerVoter(
        uint _nik,
        string memory _name,
        int _latitude,
        int _longitude
    ) public {
        voters[_nik].nik = _nik;
        voters[_nik].name = _name;
        voters[_nik].latitude = _latitude;
        voters[_nik].longitude = _longitude;
        voters[_nik].longitude = _longitude;
        voters[_nik].voted = false;
    }

    function getResultOf(uint _candidatenik) public view returns(uint) {
        return candidates[_candidatenik].voters.length;
    }
}