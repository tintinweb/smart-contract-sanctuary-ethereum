/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.6;
pragma abicoder v2;

// WARNING: DO NOT USE THIS PRICE CHECKER UNLESS YOU KNOW WHAT YOU ARE DOING!
// WARNING: DO NOT USE THIS PRICE CHECKER UNLESS YOU KNOW WHAT YOU ARE DOING!
// WARNING: DO NOT USE THIS PRICE CHECKER UNLESS YOU KNOW WHAT YOU ARE DOING!

// File: IPriceChecker.sol

interface IPriceChecker {
    function checkPrice(
        uint256 _amountIn,
        address _fromToken,
        address _toToken,
        uint256 _feeAmount,
        uint256 _minOut,
        bytes calldata _data
    ) external view returns (bool);
}

// File: AlwaysAcceptPriceChecker.sol

// WARNING: DO NOT USE THIS PRICE CHECKER UNLESS YOU KNOW WHAT YOU ARE DOING!
contract AlwaysAcceptPriceChecker is IPriceChecker {
    function checkPrice(
        uint256,
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bool) {
        return true;
    }
}