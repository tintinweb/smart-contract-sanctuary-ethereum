/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract WhiteList {
    string[] private whiteList;

    constructor(string[] memory _whiteList) {
        whiteList = _whiteList;
    }

    function getWhiteList() public view returns (string[] memory) {
        return whiteList;
    }

    function setWhiteList(string[] memory _whiteList) public {
        whiteList = _whiteList;
    }
}