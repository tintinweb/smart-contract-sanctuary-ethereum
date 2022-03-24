// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract MockGelatoGasPriceOracle {
    uint256 public gasPrice;

    constructor(uint256 _gasPrice) {
        gasPrice = _gasPrice;
    }

    function setGasPrice(uint256 _newGasPrice) external {
        gasPrice = _newGasPrice;
    }

    function latestAnswer() external view returns (int256) {
        return int256(gasPrice);
    }
}