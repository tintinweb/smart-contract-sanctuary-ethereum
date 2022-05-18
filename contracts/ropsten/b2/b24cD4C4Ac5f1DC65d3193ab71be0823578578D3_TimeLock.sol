// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TimelockController.sol";

contract TimeLock is TimelockController {
    constructor(
        uint256 _minDelay,
        address[] memory _proposers,
        address[] memory _executors
    ) TimelockController(_minDelay, _proposers, _executors) {}
}