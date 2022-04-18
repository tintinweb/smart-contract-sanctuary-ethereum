/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract MyContract {

    string[] public city;
    string[] public city_type;
    function testStr(string[] memory _city, string[] memory _type) external {
        city = _city;
        city_type = _type;
    }

}