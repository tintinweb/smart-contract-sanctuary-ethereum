/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;
 interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function balanceOf(address tokenOwner) external view returns (uint balance);

    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract Wallet {

    function balances(address user, address[] memory tokens) external view returns (uint[] memory) {
        uint[] memory Balances = new uint[](tokens.length);

        for (uint i = 0; i < tokens.length; i++) {
            if(tokens[i] != address(0x0)) { 
                Balances[i] = IERC20(address(tokens[i])).balanceOf(user);
            } 
            else {
                Balances[i] = user.balance;
            }
        }
        return Balances;
    }
 }