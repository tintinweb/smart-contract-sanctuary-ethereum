/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error NotOwner();

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Crowdfunding {
    ERC20 public payment;
    address owner;
    address[] participants;
    mapping(address => uint256) public allocations;

    constructor(address _payment) {
        payment = ERC20(_payment);
        owner = msg.sender;
    }

    function depositTokens(uint256 _amount) public {
        payment.transferFrom(msg.sender, address(this), _amount);
        if (allocations[msg.sender] == 0) participants.push(msg.sender);
        allocations[msg.sender] += _amount;
    }

    function withdrawalTokens() public onlyOwner {
        uint balance = payment.balanceOf(address(this));
        payment.transfer(owner, balance);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }
}