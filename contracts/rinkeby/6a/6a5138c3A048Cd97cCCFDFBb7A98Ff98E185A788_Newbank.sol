//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Newbank {
    uint public liquidity;
    string public name;
    mapping(address => uint) _balances;
    event Deposit(address indexed owner, uint amount);
    event Withdraw(address indexed owner, uint amount);

    constructor(string memory _name) public {
        name = _name;
    }

    function deposit() public payable {
        require(msg.value > 0, "insufficient fund for deposit");

        _balances[msg.sender] += msg.value;
        liquidity += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) public {
        require(amount > 0 && _balances[msg.sender] >= amount);

        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        liquidity -= amount;
        emit Withdraw(msg.sender, amount);
    }

    function balance() public view returns(uint) {
        return _balances[msg.sender];
    }

    function trackbalance(address owner) public view returns(uint) {
        return _balances[owner];
    }
}