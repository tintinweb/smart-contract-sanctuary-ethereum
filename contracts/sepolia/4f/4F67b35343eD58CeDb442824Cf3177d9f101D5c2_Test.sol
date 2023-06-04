/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract Test {

    event TestEvent (string name, address sender, uint256 timestamp);

    function testEvent (string calldata _name) public {

        emit TestEvent(_name, msg.sender, block.timestamp);
    }
}