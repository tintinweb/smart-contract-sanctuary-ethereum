// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract IERC20 {
    function balanceOf(address account) external view virtual returns (uint256);
}

contract GetTokenBalances {
    struct TokenBalance {
        address token;
        uint256 balance;
    }

    function getBalances(address wallet, address[] memory tokens)
        external
        view
        returns (TokenBalance[] memory)
    {
        //Create an empty array of TokenBalances datatype
        TokenBalance[] memory balances = new TokenBalance[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenBalance = IERC20(tokens[i]).balanceOf(wallet);

            balances[i] = TokenBalance(tokens[i], tokenBalance);
        }
        return balances;
    }
}