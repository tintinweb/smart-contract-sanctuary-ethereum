// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Atm {

    // Declare state variables of the contract
    uint256 bankBalances;

    // Allow the owner to deposit money into the account
    function deposit(uint256 amount) public {
        bankBalances += amount;
    }
    function getBalance() public view returns (uint256) {
        return bankBalances;
    }
}