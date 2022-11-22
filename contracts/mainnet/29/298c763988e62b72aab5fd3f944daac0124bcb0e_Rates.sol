// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

library Rates {
    function convertDefault(uint256 _amount, uint256 _exchangeRate, uint8 _decimals) public pure returns (uint256) {
        return _amount * _exchangeRate / 10 ** _decimals;
    }

    function convertInverse(uint256 _amount, uint256 _exchangeRate, uint8 _decimals) public pure returns (uint256) {
        return 10 ** _decimals * _amount / _exchangeRate;
    }
}