/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract sendKappas {

    string private whatsTheWord;
    uint256 private whatsTheNum;
    uint256 private numSetTimes;
    uint256 private stringSetTimes;

    constructor(string memory _startString, uint256 _startNum) public {
        whatsTheWord = _startString;
        whatsTheNum = _startNum;
        numSetTimes = 0;
        stringSetTimes = 0;
    }

    function setNum(uint256 _number) public {
        whatsTheNum = _number;
        numSetTimes += 1;
    }

    function setString(string memory _string) public {
        whatsTheWord = _string;
        stringSetTimes += 1;
    }


}