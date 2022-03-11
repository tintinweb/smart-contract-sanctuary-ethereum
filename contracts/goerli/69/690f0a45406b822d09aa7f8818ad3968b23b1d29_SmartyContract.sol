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

    event Deposit(address indexed from, address indexed to, int value);

    function mint (address reciever, uint amount) public {
        balances[reciever] += amount;
        emit Deposit(address(0), reciever, int(amount));
    }

    function transfer (address reciever, uint amount) public {        
        require(balances[msg.sender] >= amount, "Not enough tokens habibi!");

        balances[msg.sender] -= amount;
        balances[reciever] += amount;

        emit Deposit(msg.sender, reciever, int(amount));
    }

    function burn (uint amount) public {
        require(balances[msg.sender] > amount, "Not enough tokens to burn habibi!");

        balances[msg.sender] -= amount;
        int intAmt = int(amount);
        intAmt = intAmt - intAmt - intAmt;

        emit Deposit(address(0), msg.sender, intAmt);
    }

    function balanceOf (address user) public view returns (uint) {
        return balances[user];
    }

}