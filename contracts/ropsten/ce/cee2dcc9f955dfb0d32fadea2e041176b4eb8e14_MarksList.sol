/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MarksList {
 
    enum Grades { A, B, C, D, FAIL }
    struct Marks {
        uint cid;
        string code;
        Grades grade;
    }

    mapping(uint => mapping(string => Marks)) public marks;

    constructor() {
    }

    function addMarks(uint _cid, string memory _code, Grades _grade) public returns (Marks memory) {
        // Marks memory tempMarks = Marks(_cid, _code, _grade);
        marks[_cid][_code] = Marks(_cid, _code, _grade);
        return marks[_cid][_code];
    }

    function findMarks(uint _cid, string memory _code) public view returns (Marks memory) {
        return marks[_cid][_code];
    }
}