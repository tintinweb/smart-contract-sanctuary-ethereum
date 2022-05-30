// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Ledger{
    string public name;
    uint256 public totalBalance;
    mapping(address => uint) public balance;
    constructor (string memory _name){
        name = _name;
    }
    function deposit() public payable{
        require(msg.value > 0, "value must be greater than 0");
        balance[msg.sender] += msg.value;
        totalBalance += msg.value;
    }

    function withdraw(uint _amount) public payable{
        require(balance[msg.sender] >= _amount, "Not enough amount");
        balance[msg.sender] -= _amount;
        totalBalance -=  _amount;

        payable(msg.sender).transfer(_amount);
    }
    
    function transfer(address _to) public payable{
        require(balance[msg.sender] >= msg.value, "Not enough amount");

        balance[msg.sender] -= msg.value;
        balance[_to] += msg.value;
        payable(_to).transfer(msg.value);
    }
    
}