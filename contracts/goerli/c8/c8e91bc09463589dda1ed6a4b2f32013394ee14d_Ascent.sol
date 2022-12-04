// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

contract Ascent {
    uint256 public immutable low;
    uint256 public immutable high;
    uint256 public immutable slope;
    uint256 public immutable maxApy;
    uint256 public immutable baseApy;

    constructor(
        uint256 _low,
        uint256 _high,
        uint256 _maxApy,
        uint256 _baseApy
    ) {
        baseApy = _baseApy;
        maxApy = _maxApy;
        low = _low;
        high = _high;
        slope = ((maxApy - baseApy) * 1e18) / (_high + _low);
    }

    function getStrike(uint256 spot) public returns (uint256) {
        return spot - (spot * low) / 1e18;
    }

    function getBarrier(uint256 spot) public returns (uint256) {
        return spot + (spot * low) / 1e18;
    }

    function getValue(uint256 spot, uint256 price) public returns (uint256) {
        uint256 strike = getStrike(spot);
        uint256 barrier = getBarrier(spot);
        if (price <= strike || price >= barrier) {
            return (baseApy * spot) / 1e18;
        } else {
            uint256 payoffPer = baseApy + ((price - strike) * slope) / 1e18;
            return (payoffPer * spot) / 1e18;
        }
    }

    function getMaxPayoff(uint256 spot) public returns (uint256) {
        return (maxApy * spot) / 1e18;
    }
}