/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BHWallet {
    address payable public owner;
    mapping(address => uint) public balances;

    event Transfer(address indexed from, address indexed to, uint value);
    event Deposit(address indexed from, uint value);
    event Withdrawal(address indexed to, uint value);
    event ChangeBalance(string action, address indexed to, uint value);
    event ChangeOwner(address indexed oldOwner, address indexed newOwner);

    constructor() {
        owner = payable(msg.sender);
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(address _to, uint _amount) external {
        require(msg.sender == owner, "caller is not the owner");
        require(balances[_to] >= _amount, "account not enough balance");
        require(
            address(this).balance >= _amount,
            "contract not enough balance"
        );
        balances[_to] -= _amount;
        payable(_to).transfer(_amount);
        emit Withdrawal(_to, _amount);
    }

    function addBalance(address _to, uint _amount) public {
        require(msg.sender == owner, "caller is not the owner");
        balances[_to] += _amount;
        emit ChangeBalance("Add", msg.sender, _amount);
    }

    function removeBalance(address to, uint _amount) public {
        require(msg.sender == owner, "caller is not the owner");
        balances[to] -= _amount;
        emit ChangeBalance("Remove", to, _amount);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function getBalances(address _to) external view returns (uint) {
        return balances[_to];
    }

    function changeOwner(address _to) public {
        require(msg.sender == owner, "caller is not the owner");
        owner = payable(_to);
        emit ChangeOwner(msg.sender, _to);
    }

    fallback() external payable {
        deposit();
    }

    receive() external payable {
        deposit();
    }
}