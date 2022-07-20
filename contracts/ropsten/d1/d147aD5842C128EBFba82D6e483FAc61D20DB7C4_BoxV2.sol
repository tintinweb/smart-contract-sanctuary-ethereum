//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


contract BoxV2 {
    uint public val;

    // constructor(uint _val) {
    //     val = _val;
    // }

    // function initialize(uint _val) external {
    //     val = _val;
    // }

    function inc() external{
        val++;
    }



    function readSender() external view returns (address) {
        return msg.sender;
    }

    function readOrigin () external view returns (address) {
        return tx.origin;
    }
}