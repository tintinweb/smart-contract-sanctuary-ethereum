// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Ledger {
    string public name;
    uint public totalBalance;
    mapping(address => uint) public balances;

    constructor(string memory _name) {
        name = _name;
    }

    function deposit() public payable {
        require(msg.value > 0, "Must deposit more than 0");
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
    }

    // function withdraw(uint _amount) public {
    //     require(balances[msg.sender] >= _amount, "You not enough fund");

    //     balances[msg.sender] -= _amount;
    //     totalBalance -= _amount;

    //     payable(msg.sender).transfer(_amount);
    // }

    // function balance() public view returns (uint) {
    //     return address(this).balance;
    // }
}