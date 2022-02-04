/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract MyFirstContract {

    string private name;
    uint private age;

    function setName(string memory newName) public {
        name = newName;
    }

    function getName () public view returns (string memory) {
        return name;
    }

    function setAge(uint256 newAge) public {
        age = newAge;
    }

    function getAge () public view returns (uint256) {
        return age;
    }
}