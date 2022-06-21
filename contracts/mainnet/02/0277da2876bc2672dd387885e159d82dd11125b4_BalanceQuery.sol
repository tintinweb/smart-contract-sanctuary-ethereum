/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint256);
}

contract BalanceQuery {
    function getBalances(address[] calldata accounts, address[] calldata tokens)
        external
        view
        returns (uint256[][] memory balances, uint256[] memory decimals)
    {
        // Allocate memory
        balances = new uint256[][](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            balances[i] = new uint256[](tokens.length + 1);
        }

        decimals = new uint256[](tokens.length + 1);

        for (uint256 i = 0; i < accounts.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                if (isContract(tokens[j])) {
                    try IERC20(tokens[j]).balanceOf(accounts[i]) returns (uint256 balance) {
                        balances[i][j] = balance;
                    } catch (bytes memory) {
                        balances[i][j] = 0;
                    }
                } else {
                    balances[i][j] = 0;
                }
            }
            balances[i][tokens.length] = accounts[i].balance;
        }

        for (uint256 j = 0; j < tokens.length; j++) {
            if (isContract(tokens[j])) {
                try IERC20(tokens[j]).decimals() returns (uint256 decimals_) {
                    decimals[j] = decimals_;
                } catch (bytes memory) {
                    decimals[j] = 0;
                }
            } else {
                decimals[j] = 0;
            }
        }
        decimals[tokens.length] = 18; // Ethereum is 18 decimals
    }

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}