// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    mapping(address => uint) public balances;

    event Deposit(address indexed _from, uint _value);
    event Withdrawal(address indexed _from, uint _value);

    function deposit() public payable {
        require(msg.value > 0);
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint _value) public {
        require(_value <= balances[msg.sender]);
        require(_value > 0);
        balances[msg.sender] -= _value;
        payable(msg.sender).transfer(_value);
        emit Withdrawal(msg.sender, _value);
    }

    function checkBalance() public view returns (uint) {
        return balances[msg.sender];
    }
}