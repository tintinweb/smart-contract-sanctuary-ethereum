/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract ModifyVariable {
    uint public x;
    string public s;

    constructor(uint _x, string memory _s) {
        x = _x;
        s = _s;
    }

    function modifyToLeet() public {
        x = 1337;
    }

    function modifyString() public {
        s = 'Hello World!';
    }
}