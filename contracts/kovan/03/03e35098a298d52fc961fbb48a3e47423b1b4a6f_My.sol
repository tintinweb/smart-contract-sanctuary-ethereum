/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract My {

    string[] city;
    function testStr(string[] memory _city) external {
        city = _city;
    }

}