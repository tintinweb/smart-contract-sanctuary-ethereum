/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract ModifyVariable {
    uint256 public x;
    string public state;

    constructor(uint256 _x, string memory _state) {
        x = _x;
        state = _state;
    }

    function modifyToLeet() public {
        x = 1337;
    }

    function modifyState(string memory update) public {
        state = update;
    }
}