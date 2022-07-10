// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ElimuDisperse {
    /**
     * Disperse ERC-20 tokens to multiple addresses.
     */
    function disperseToken(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            total += values[i];
        }
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], values[i]));
        }
    }
}