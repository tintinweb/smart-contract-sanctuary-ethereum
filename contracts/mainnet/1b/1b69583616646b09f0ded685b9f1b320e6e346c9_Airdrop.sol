// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

contract Airdrop {
    function transferMany(
        IERC20 erc20,
        address[] calldata tos,
        uint256[] calldata amounts
    ) external {
        unchecked {
            uint256 num = tos.length;
            for (uint256 i; i < num; ++i)
                erc20.transferFrom(tx.origin, tos[i], amounts[i]);
        }
    }
}