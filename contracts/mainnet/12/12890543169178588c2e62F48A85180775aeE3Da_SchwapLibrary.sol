// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

library SchwapLibrary {
    function getPair(
        address tokenA,
        address tokenB
    )
        public
        pure
        returns (address)
    {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == token1 || token0 == address(0)) {
            return address(0);
        }
        return address(uint160(uint256(keccak256(abi.encodePacked(token0, token1)))));
    }
}