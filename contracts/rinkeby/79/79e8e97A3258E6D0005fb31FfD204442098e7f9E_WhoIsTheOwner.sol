/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


contract WhoIsTheOwner {
    mapping(address => uint) public balances;
    address public owner;

    constructor() payable {
        owner = msg.sender;
        balances[msg.sender] = msg.value;
    }

    // if you deposit more than the current owner
    function renounceOwnership() public {
        require(balances[msg.sender] > balances[owner], "Not enough balance");
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Only owner can change ownership");
        owner = newOwner;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint bal = balances[msg.sender];

        balances[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }
}