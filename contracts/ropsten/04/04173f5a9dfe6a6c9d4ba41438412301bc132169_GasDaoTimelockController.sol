// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../TimelockController.sol";

contract GasDaoTimelockController is TimelockController {
    constructor(uint256 minDelay,
        address[] memory proposers,
        address[] memory executors)
       TimelockController(minDelay, proposers, executors)
    {}
    
}