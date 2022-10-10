// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ABDKMath64x64.sol";

library Math {
    function min(uint256 a, uint256 b) external pure returns (uint256) {
        if (a > b) return b;
        return a;
    }

    function max(uint256 a, uint256 b) external pure returns (uint256) {
        if (a > b) return a;
        return b;
    }

    function logX64(uint256 x) external pure returns (int128) {
        return ABDKMath64x64.log_2(ABDKMath64x64.fromUInt(x));
    }
}