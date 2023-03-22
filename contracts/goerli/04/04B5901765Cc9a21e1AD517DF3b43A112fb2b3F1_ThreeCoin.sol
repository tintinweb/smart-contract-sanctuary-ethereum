/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

// SPDX-License-Identifier: MIT

// Specify the version of Solidity to use
pragma solidity ^0.8.0;

// Define the contract
contract ThreeCoin {
    
    // Declare state variables for each coin
    uint public coin1Balance;
    uint public coin2Balance;
    uint public coin3Balance;
    
    // Declare events for each coin
    event Coin1Sent(address sender, address recipient, uint amount);
    event Coin2Sent(address sender, address recipient, uint amount);
    event Coin3Sent(address sender, address recipient, uint amount);
    
    // Constructor function
    constructor() {
        coin1Balance = 0;
        coin2Balance = 0;
        coin3Balance = 0;
    }
    
    // Function to send coin1 to a recipient
    function sendCoin1(address recipient, uint amount) public {
        require(amount <= coin1Balance, "Not enough coin1 balance.");
        coin1Balance -= amount;
        emit Coin1Sent(msg.sender, recipient, amount);
    }
    
    // Function to send coin2 to a recipient
    function sendCoin2(address recipient, uint amount) public {
        require(amount <= coin2Balance, "Not enough coin2 balance.");
        coin2Balance -= amount;
        emit Coin2Sent(msg.sender, recipient, amount);
    }
    
    // Function to send coin3 to a recipient
    function sendCoin3(address recipient, uint amount) public {
        require(amount <= coin3Balance, "Not enough coin3 balance.");
        coin3Balance -= amount;
        emit Coin3Sent(msg.sender, recipient, amount);
    }
    
    // Function to get the balance of coin1
    function getCoin1Balance() public view returns (uint) {
        return coin1Balance;
    }
    
    // Function to get the balance of coin2
    function getCoin2Balance() public view returns (uint) {
        return coin2Balance;
    }
    
    // Function to get the balance of coin3
    function getCoin3Balance() public view returns (uint) {
        return coin3Balance;
    }
    
    // Function to add to the balance of coin1
    function addToCoin1Balance(uint amount) public {
        coin1Balance += amount;
    }
    
    // Function to add to the balance of coin2
    function addToCoin2Balance(uint amount) public {
        coin2Balance += amount;
    }
    
    // Function to add to the balance of coin3
    function addToCoin3Balance(uint amount) public {
        coin3Balance += amount;
    }
    
}