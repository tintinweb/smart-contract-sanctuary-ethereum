/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract B {
  struct highscoreStd {
        string name;
        uint number;
        uint score;
    }

    highscoreStd[] public highscoreStds;

    function setHighscoreStd(string memory _name, uint _number, uint _score) public {
        highscoreStds.push(highscoreStd(_name, _number, _score));
    }

    function getHighscoreStd(uint _n) public view returns (highscoreStd memory) {
        return highscoreStds[_n-1];
    }
}