/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Event {
    event Log (string message, uint value);
    event Message (address indexed sender, uint val);

    function example() external {
        emit Log ("hello", 123);
        emit Message (msg.sender,456);
    }

    event Message (address indexed _to, address indexed _from, string message);

    function sendMessage (address _to, string calldata message) external {
        emit Message (msg.sender, _to, message);
    }
}