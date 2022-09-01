// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.16 <0.9.0;

// Author: @avezorgen
contract Escrow {
    mapping(address => mapping(address => uint)) public deals;
    address public owner;
    uint public hold;

    constructor() {
        owner = msg.sender;
    }

    //call by buyer
    function create(address seller) external payable {
        require(deals[msg.sender][seller] == 0, "Deal already exists");
        deals[msg.sender][seller] = msg.value;
    }

    //call by seller
    function cancel(address buyer) external {
        require(deals[buyer][msg.sender] != 0, "Deal does not exist");
        payable(buyer).transfer(deals[buyer][msg.sender]);
        delete deals[buyer][msg.sender];
    }

    //call by buyer
    function approve(address seller) external {
        require(deals[msg.sender][seller] != 0, "Deal does not exist");
        uint h = deals[msg.sender][seller] / 1000 * 25;
        hold += h;
        payable(seller).transfer(deals[msg.sender][seller] - h);
        delete deals[msg.sender][seller];
    }

    //call by buyer
    function disapprove(address seller) external {
        require(deals[msg.sender][seller] != 0, "Deal does not exist");
        payable(msg.sender).transfer(deals[msg.sender][seller]);
        delete deals[msg.sender][seller];
    }

    //call by owner
    function withdraw() external {
        require(msg.sender == owner, "Caller is not owner");
        payable(owner).transfer(hold);
        hold = 0;
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
        
    receive() external payable {
        hold += msg.value;
    }
}