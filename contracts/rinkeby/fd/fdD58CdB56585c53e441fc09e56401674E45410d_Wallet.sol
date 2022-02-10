// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Wallet {
    address payable public owner;

    constructor() {
        owner = payable (msg.sender);
    }

    fallback() external payable {
    }

    receive() external payable {
    }

function withdraw() external {
    require(msg.sender == owner, "Only owner can withdraw funds");

    owner.transfer(address(this).balance);
} 

function getBalance() external view returns (uint256) {
    return address(this).balance;
}

function withdrawToken(address token) external {
    require(msg.sender == owner, "Only owner can withdraw funds");
   uint256 tokenAmount = IERC20(token).balanceOf(address(this));
   IERC20(token).transfer(owner, tokenAmount);

}
}