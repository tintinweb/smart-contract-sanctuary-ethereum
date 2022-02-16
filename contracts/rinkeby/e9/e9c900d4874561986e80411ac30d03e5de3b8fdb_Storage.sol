/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    int public age;

    string public name;

    function setAge(int ageValue) public {
        age = ageValue;
    }

    function getAge() public view returns (int) {
        return age;
    }

    function setName(string memory nameValue) public {
        name = nameValue;
    }

    function getName() public view returns (string memory) {
        return name;
    }


}