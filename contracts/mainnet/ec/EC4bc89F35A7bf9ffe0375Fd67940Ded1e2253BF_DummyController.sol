// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IStrategy {
    function withdrawAll() external returns (uint256);
}

/**
 * @title DummyController Contract
 * @author gosuto.eth
 * @notice Prentends to be a controller, returning treasury ops as a vault for
 * any asset requested.
 */
contract DummyController {
    constructor(){}

    function vaults(address asset) external returns (address) {
        return 0x042B32Ac6b453485e357938bdC38e0340d4b9276;
    }

    function sweepStratToTrops(address strategy) external {
        IStrategy(strategy).withdrawAll();
    }
}