// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

contract MockCurveGauge {
    function minter() external pure returns (address) {
        return address(0);
    }

    function balanceOf(address) external view returns (uint256) {
        return 0;
    }
}