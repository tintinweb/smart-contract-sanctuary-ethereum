// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SomeToken {
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint _amount) public payable {
        require(balances[msg.sender] >= _amount);
        require(getBalance() >= _amount);
        (bool send, ) = msg.sender.call{value: _amount}("");
        require(send, "Failed to send Ether");
        balances[msg.sender] = _amount;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}