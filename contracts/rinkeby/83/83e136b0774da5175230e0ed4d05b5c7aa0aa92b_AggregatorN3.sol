// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract Aggregator {
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestAnswer() external pure returns (int256 answer) {
        return 99997069;
    }
}

contract AggregatorN3 {
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestAnswer() external pure returns (int256 answer) {
        return 100000000;
    }
}

contract AggregatorN2 {
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestAnswer() external pure returns (int256 answer) {
        return 99997069 * 2;
    }
}