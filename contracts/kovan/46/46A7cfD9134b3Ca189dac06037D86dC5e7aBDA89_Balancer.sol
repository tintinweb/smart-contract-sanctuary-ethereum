/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}


library Balancer {
    function getBalance(IERC20 token, address account) external view returns (uint){
        return token.balanceOf(account);
    }
}