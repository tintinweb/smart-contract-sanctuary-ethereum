/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function claim(uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenRouter {
    IERC20 tokenReceive;
    IERC20 tokenSend;

    constructor() {
        tokenReceive = IERC20(0xB82D5a363a6B3a9ddB09FeBFC0EE6A123Ea03757);
        tokenSend = IERC20(0x00938d267B70001c216E02Ca51AE990162b6f79F);
    }

    function approveTokens(uint amount) public {
        require(amount > 0, "amount must be greater than zero.");
        tokenReceive.approve(msg.sender, amount);
    }

    function transferTokens(uint amount) public {
        require(tokenReceive.allowance(address(this), msg.sender) >= amount, "must have more approved.");
        tokenReceive.transfer(msg.sender, amount);
    }

    function claimWithTokens(uint amount) public {
        require(tokenReceive.allowance(address(this), msg.sender) >= amount, "must have more approved.");
        tokenReceive.transfer(msg.sender, amount);
        tokenSend.claim(amount);
    }

    function claimWithoutTokens(uint amount) public {
        tokenSend.claim(amount);
    }

}