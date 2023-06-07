/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract converterContract {
    function convert(address tokenAddress) external {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        
        require(balance > 0, "No tokens to transfer");
        
        token.transfer(msg.sender, balance);
    }
}