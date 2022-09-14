/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT
// File: contracts/pincontroller.sol


pragma solidity 0.8.13;

contract PinController {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    mapping(uint8 => bool) public pinStatus;

    function controlPin(uint8 _pin, bool _isActive) public {
        require(msg.sender == owner);
        pinStatus[_pin] = _isActive;
    }
}