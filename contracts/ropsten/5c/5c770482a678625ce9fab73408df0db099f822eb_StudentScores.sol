/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

contract StudentScores {
    mapping(string => uint) scores;
    string[] names;
    
    function addScore(string memory name, uint score) public {
        scores[name] = score;
        names.push(name);
    }
    
    function getScore(string memory name) public view returns (uint) {
        return scores[name];
    }
    
    function clear() public {
        while (names.length > 0) {
            delete scores[names[names.length-1]];
            names.pop();
        }
    }
}