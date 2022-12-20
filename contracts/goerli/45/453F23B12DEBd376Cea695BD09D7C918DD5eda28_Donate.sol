// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Donate {
    event EthDonationEvent(uint256 amount, address indexed receiver);
    event TokenDonationEvent(uint256 amount, address indexed receiver, IERC20 indexed token);

    function donateEth(uint256 amount, address receiver) public payable {
        require(msg.value == amount);

        (bool success, ) = receiver.call{value: amount}("");
        require(success, "Failed to send Ether");
        emit EthDonationEvent(amount, receiver);
    }

    function donateErc20(uint256 amount, address receiver, IERC20 token) public {
        require(token.allowance(msg.sender, address(this)) >= amount, "Token allowance is too low");

        bool sent = token.transferFrom(msg.sender, receiver, amount);
        require(sent, "Failed to send tokens");
        emit TokenDonationEvent(amount, receiver, token);
    }

    receive() external payable {}
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}