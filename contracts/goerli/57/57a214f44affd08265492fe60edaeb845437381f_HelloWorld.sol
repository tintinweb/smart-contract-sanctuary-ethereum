/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract HelloWorld {
    uint256 public age = 18;
    string public name = "Kim & Kim";
    address public deployer;

    constructor () {
        deployer = msg.sender;
    }

    function SetName(string memory newName) public{
        require(msg.sender == deployer, "You're not authorized");
        name = newName;
    }

    // function SetAge(uint256 newAge) public {
    //     age = newAge;
    // }

    // function SetAllData(string memory newName, uint256 newAge) public {
    //     name = newName;
    //     age = newAge;
    // }
}