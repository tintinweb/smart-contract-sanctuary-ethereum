//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract BoxV4 {
    uint256 public val;
    address public sender;
    address public origin;

    // constructor(uint _val) {
    //     val = _val;
    // }

    // function initialize(uint _val) external {
    //     val = _val;
    // }

    function inc() external {
        val++;
    }

    function readSender() external {
        sender = msg.sender;
    }

    function readOrigin() external {
        origin = tx.origin;
    }
}