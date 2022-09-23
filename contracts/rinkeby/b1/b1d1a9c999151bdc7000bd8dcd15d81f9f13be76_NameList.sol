/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity ^0.8.0;

contract NameList {

    string[] saaray;

    function pushName(string memory s) public {
        saaray.push(s);
    }

    function Lengtharray() public view returns(uint) {
        return saaray.length;
    }

    function GetName(uint _n) public view returns(string memory) {
        return saaray[_n-1];
    }
}