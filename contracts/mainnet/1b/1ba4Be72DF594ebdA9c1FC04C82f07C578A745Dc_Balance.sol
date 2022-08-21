// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external view returns (uint256);
}

contract Balance {
    constructor() {

    }

    function tokenBalance(address token, address owner) public view returns (uint256, uint256) {
        ERC20 Token = ERC20(token);
        return (Token.balanceOf(owner), Token.decimals());
    }

    function ethBalance(address owner) public view returns (uint256) {
        return owner.balance;
    }
}