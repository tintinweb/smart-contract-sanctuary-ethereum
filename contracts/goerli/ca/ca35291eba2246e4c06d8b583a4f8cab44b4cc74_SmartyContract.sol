/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract SmartyContract {

    string private name;

    constructor(string memory _name) {
        name = _name;   
    }

    mapping(address => uint) private balances;

    event Transfer(address indexed from, address indexed to, uint value);

    function mint (address reciever, uint amount) public {
        balances[reciever] += amount;
        emit Transfer(address(0), reciever, amount);
    }

    function transfer (address reciever, uint amount) public {        
        require(balances[msg.sender] >= amount, "Not enough tokens habibi!");

        balances[msg.sender] -= amount;
        balances[reciever] += amount;

        emit Transfer(msg.sender, reciever, amount);
    }

    function burn (uint amount) public {
        require(balances[msg.sender] >= amount, "Not enough tokens to burn habibi!");

        balances[msg.sender] -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }

    function balanceOf (address user) public view returns (uint) {
        return balances[user];
    }

    function getName() public view returns (string memory) {
        return name;
    }

}