// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import './Piza.sol';

contract PizzaV2 is Pizza {

    function refillSlice() external {
        slices += 1;
    }

    function pizzaVersion() external pure returns (uint256) {
        return 2;
    }
}