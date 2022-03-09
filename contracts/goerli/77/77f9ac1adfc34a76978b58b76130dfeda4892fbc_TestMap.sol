/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract TestMap {


    mapping(address => string) userNames;
    mapping(address => uint8) userAges;


    function namaUndZeitalter(address add, string memory name, uint8 age) public {
        userNames[add] = name;
        userAges[add] = age;
    }

    function getUser(address add) public view returns (string memory, uint8) {
        return (userNames[add], userAges[add]);
    }

}