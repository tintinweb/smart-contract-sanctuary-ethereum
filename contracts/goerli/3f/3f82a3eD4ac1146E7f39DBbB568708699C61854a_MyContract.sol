/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// create interface with balanceOf() function to  check token balance of Ethereum address
interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract MyContract {
    // we need to display result as token address with its balance, hence create a new data structure that contains both
    struct TokenBalance {
        address token;
        uint256 balance;
    }

    // input: wallet address, array of token contract address
    // output: TokenBalance object with token and balance
    function getBalances(
        address walletAddress,
        address[] calldata tokenAddress
    ) external view returns (TokenBalance[] memory) {
        TokenBalance[] memory amount = new TokenBalance[](tokenAddress.length);

        // iterate through all token addresses to get respective token address and balance
        for (uint256 i = 0; i < tokenAddress.length; i++) {
            ERC20 erc20 = ERC20(tokenAddress[i]);
            address token = tokenAddress[i];
            uint256 balance = erc20.balanceOf(address(walletAddress));
            amount[i] = TokenBalance(token, balance);
        }
        return amount;
    }
}