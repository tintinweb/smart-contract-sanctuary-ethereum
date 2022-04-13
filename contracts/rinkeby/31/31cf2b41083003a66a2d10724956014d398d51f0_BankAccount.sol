/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Ownable {
    
    // All veriables will be here
    address owner;

    // constructor is run upon contract being deployed and is only run once
    constructor() {
        owner = msg.sender;
    }

    // Modifiers are used to store a specific parameters that will be called
    // multiple times in a contract. Allowing you to only have to write it once.
    modifier onlyOwner() {
        require(msg.sender == owner, "YOU MUST BE THE OWNER TO DO THAT. SORRY!");
        _;
    }
}

contract BankAccount is Ownable {

    // variables are declared
    uint private balance = 20;
    string private firstName = "Micheal";
    string private lastName = "Leverton";

    // returns balance variable
    function Balance() external view returns (uint) {
        return balance;
    }

    // allows a person to change the variable firstName
    function setfirstName(string memory _firstName) external onlyOwner {
        firstName = _firstName;
    }

    // returns the string variable firstName
    function getfirstName() external view returns (string memory) {
        return firstName;
    }

    // allows a person to change the variable lastName
    function setlastName(string memory _lastName) external onlyOwner {
        firstName = _lastName;
    }

    // returns the string variable lastName
    function getlastName() external view returns (string memory) {
        return lastName;
    }

    // allows a person to add amount to current balance variable
    function Deposit(uint _balance) external onlyOwner {
        balance = balance + _balance;
    }

   // allows a person to subtracts amount from the current balance variable
    function Withdrawl(uint _balance) external onlyOwner {
        balance = balance - _balance;
    }
    
}