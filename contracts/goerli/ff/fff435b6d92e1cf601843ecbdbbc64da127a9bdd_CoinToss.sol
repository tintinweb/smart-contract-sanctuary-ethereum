/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CoinToss {

    address payable public owner;
    uint256 ticketPrice= 1000000000000000; //0.001 ETH
    
    constructor() {
        owner = payable(msg.sender);
    }

    function buyChance() public payable {
        require(msg.value == ticketPrice, "You need to spend exactly 0.001 ETH to buy a chance!");
    }

    function claim() payable public {
        payable(msg.sender).transfer(3 * ticketPrice);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        
        _;
    }

    function deposit() payable public {
        
    }

    function withdraw() payable onlyOwner public {
        owner.transfer(address(this).balance);
    }

    function getBalance() view onlyOwner public returns (uint256) {
        return address(this).balance;
    }

}