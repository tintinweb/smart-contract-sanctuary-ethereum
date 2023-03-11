/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

contract Library {

    // state variables
   
    address public owner = payable (msg.sender);
    mapping (address => uint) public books;
    uint public cost = 2 wei;

    constructor() {
        owner = msg.sender;
        books[owner] = 1000;
    }

    function getLibraryAvailability() public view returns (uint) {
        return books[owner];
    }

    function restock(uint _n) public {
        require(msg.sender == owner, "Only the owner can restock.");
        books[owner] += _n;
    }

    function purchase(uint _n) public payable {
        require(msg.value >= _n *cost, "Not enough money to buy the books");
        require(books[owner] >= _n, "Not enough books in stock");
        books[msg.sender] += _n;
        books[owner] -= _n;
        
    }
}