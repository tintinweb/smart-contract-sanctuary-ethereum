// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract BoxV3 {
    uint public val;
    address public owner;
    uint public start; 

    // function initialize(uint _val) external {
    //     val = _val;
    // }

    function initialize(uint _val) external {
        owner = msg.sender;
        val = _val;
        start = block.timestamp;
    }
}