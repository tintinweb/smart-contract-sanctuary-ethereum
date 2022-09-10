/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract GetNum {
    constructor() {
    }

    event NewEvent(address who, uint value);

    function getNum() public view returns(uint) {
        return 10;
    }


    function emitEvent(uint _value) public {
        emit NewEvent(msg.sender, _value);
    }
}