// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "./ERC20.sol";

contract AcuityRPC {

    function getAccountBalances(address[] calldata accounts)
        view
        external
        returns (uint[] memory values)
    {
        values = new uint[](accounts.length);

        for (uint i = 0; i != accounts.length; i++) {
            values[i] = accounts[i].balance;
        }
    }

    function getStaticTokenMetadata(ERC20 token)
        view
        external
        returns (string memory name, string memory symbol, uint decimals)
    {
        name = token.name();
        symbol = token.symbol();
        decimals = token.decimals();
    }

    function getTokenAccountBalances(ERC20 token, address[] calldata accounts)
        view
        external
        returns (uint[] memory values)
    {
        values = new uint[](accounts.length);

        for (uint i = 0; i != accounts.length; i++) {
            values[i] = token.balanceOf(accounts[i]);
        }
    }

    function getAccountTokenBalances(address account, ERC20[] calldata tokens)
        view
        external
        returns (uint[] memory values)
    {
        values = new uint[](tokens.length);

        for (uint i = 0; i != tokens.length; i++) {
            values[i] = tokens[i].balanceOf(account);
        }
    }

    function getAccountTokenAllowances(address account, address spender, ERC20[] calldata tokens)
        view
        external
        returns (uint[] memory values)
    {
        values = new uint[](tokens.length);

        for (uint i = 0; i != tokens.length; i++) {
            values[i] = tokens[i].allowance(account, spender);
        }
    }

}