// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @title OnChainPricing
/// @author Alex the Entreprenerd @ BadgerDAO
/// @dev Always returns 0 making all cowswap trades go through (for testnet bruh)
contract UselessPricer {

    struct Quote {
        string name;
        uint256 amountOut;
    }
    

    /// @dev View function for testing the routing of the strategy
    function findOptimalSwap(address tokenIn, address tokenOut, uint256 amountIn) external view returns (Quote memory) {
        return Quote("fake", 0);
    }
}