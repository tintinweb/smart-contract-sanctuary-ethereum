/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {
    // private variable
    string _name;
    uint256 _balance;

    constructor(string memory name, uint256 balance) {
        // require(balance > 0, "balance must greater than zero");
        _name = name;
        _balance = balance;
    }

    // function type: Pure, View, Payable
    // Pure: Don't pay gas for view information
    // function getBank() public pure returns (string memory bank) {
    //     return "Kasikorn Thai";
    // }

    // View: Don't pay gas for view information
    function getBalance() public view returns (uint256 balance) {
        return _balance;
    }

    // Payable: Pay gas for mining because variable has change, system will proof transaction again.
    // function deposite(uint256 amount) public {
    //     _balance += amount;
    // }
}