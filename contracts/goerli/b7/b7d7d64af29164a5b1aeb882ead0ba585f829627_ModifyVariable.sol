/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract ModifyVariable {
    uint256 public x;
    string public name;

    constructor(uint256 aNumber, string memory aName) {
        x = aNumber;
        name = aName;
    }

    function modifyToLeet() public {
        x = 1337;
    }

    function changeName(string memory aName) public {
        name = aName;
    }
}