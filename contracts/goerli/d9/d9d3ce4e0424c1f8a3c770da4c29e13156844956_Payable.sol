/**
 *Submitted for verification at Etherscan.io on 2022-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Payable {
    // 1. Payable address can receive Ether
    address payable public owner;

    // 2. Payable constructor can receive Ether
    constructor() payable {
        owner = payable(msg.sender);
    }

    // 3. Function to deposit Ether into this contract.
    function deposit() public payable {}

    // 4. Call this function along with some Ether.
    // The function will throw an error since this function is not payable.
    function notPayable() public {}

    // 5. Function to withdraw all Ether from this contract.
    function withdraw() public {
        uint amount = address(this).balance;
        owner.transfer(amount);
    }

    // 6. Function to transfer Ether from this contract to address from input
    function transfer(address payable _to, uint _amount) public {
        _to.transfer(_amount);
    }

    function getBalance(address a1) public payable returns(uint){
        return address(a1).balance;
    }
}