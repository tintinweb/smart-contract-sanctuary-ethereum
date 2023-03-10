// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    struct Vote {
        uint256 grade;
        string name;
    }

    Vote[] public votes;

    mapping(string => uint256) public nameToVote;

    function addVote(string memory _name, uint256 _grade) public {
        votes.push(Vote(_grade, _name));
        nameToVote[_name] = _grade;
    }

    function getVote(string memory _name) public view returns (uint256) {
        return nameToVote[_name];
    }
}