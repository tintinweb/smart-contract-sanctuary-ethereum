// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract ClientDub {
    uint256 public number;

    address public GatewayDubAddress;

    constructor(address _gatewayAddress) {
        GatewayDubAddress = _gatewayAddress;
    }

   function SetNum(uint256 newNumber) public {
        number = newNumber;
    } 
}