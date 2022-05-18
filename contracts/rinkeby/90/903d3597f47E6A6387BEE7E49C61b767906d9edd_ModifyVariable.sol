/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract ModifyVariable {
    string public x;

    constructor(string memory _x) {
        x = _x;
    }

    function modifyToHelloWorld() public {
        x = "Hello World";
    }
}