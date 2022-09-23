/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract lec22 {
    event ContryIndexName(uint _index, string name);
    string[] private countryList = ["KOREA","USA","CHINA","JAPAN"];

    function forLoopEvents() public {
        for(uint i = 0; i < countryList.length; i++){
            emit ContryIndexName(i, countryList[i]);
        }
    }
}