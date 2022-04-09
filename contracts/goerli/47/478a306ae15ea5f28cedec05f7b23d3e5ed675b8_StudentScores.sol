/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract StudentScores {
    mapping(string => uint) scores;
    string[] studentnames;

    function addScore(string memory name, uint score ) public {
        scores[name] = score;
        studentnames.push(name);
    }

    function getScore(string memory name) public view returns(uint) {
        return scores[name];
    }

    function clearScores() public {
        while(studentnames.length > 0) {
            scores[studentnames[studentnames.length-1]] = 0;
            studentnames.pop();
        }
    }
}