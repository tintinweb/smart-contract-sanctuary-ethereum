// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Bank {
    address public owner;
    mapping(address => uint256) private balances;

    event Deposit(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, uint256 amount);

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"not owner");
        _;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() public payable {
        require(msg.value > 0, "Amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0 , "Insufficient balance");
        balances[msg.sender] = 0;
        (bool success,) = payable(msg.sender).call{value:balance}("");
        require(success, "Withdrawal failed");
        emit Withdrawal(msg.sender, balance);
    }

    function withdrawAll() public onlyOwner {
        uint b = address(this).balance;
        (bool success,) = payable(owner).call{value:b}("");
        require(success, "WithdrawAll failed");
        emit Withdrawal(msg.sender, b);
    }

    function getBalance(address account) public view returns (uint256) {
        return balances[account];
    }
}