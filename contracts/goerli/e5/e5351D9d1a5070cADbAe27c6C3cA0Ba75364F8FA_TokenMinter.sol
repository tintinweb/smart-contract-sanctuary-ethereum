/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20Minter {
    function mint(address account, uint256 amount) external returns (bool);
}

contract TokenMinter {
    
    IERC20Minter public token;
    
    constructor(address tokenAddress) {
        token = IERC20Minter(tokenAddress);
    }
  
    function mint(address account, uint256 amount) public returns (bool) {
        token.mint(account, amount);
        return true;
    }    
}