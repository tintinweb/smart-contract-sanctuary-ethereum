/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Main Contract
contract ContractNFT {
    // Variable Private
    string private _name;
    uint private _balance;
    
    constructor(string memory name, uint balance) {
        require(balance>0, "balance greater zero (money>0)");
        _name = name;
        _balance = balance;
    }
    
    // READ: Get Balance
    function getBalance() public view returns(uint balance) {
        return _balance;
    }

    // WRITE: Deposite
    function deposite(uint amount) public {
        _balance += amount;
    }
}