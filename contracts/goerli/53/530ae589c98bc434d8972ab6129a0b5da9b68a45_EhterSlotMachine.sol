/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: MIT
// v10: ready for deployment and validation.

pragma solidity ^0.8.0;

contract EhterSlotMachine {
    address owner;
    mapping (address => uint256) balances;
    uint winChance; 
    
    constructor()  {
        owner = msg.sender;
        winChance = 45;     
    }

    receive() external payable
    {
        balances[msg.sender] += msg.value;
    }

    function Withdraw() external {
        require(balances[msg.sender] > 0, "Error.  Insufficient balance under your account.");
        require(address(this).balance >= balances[msg.sender], "Error. Insufficient balance under game.");
        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    function Play(uint256 amount) public {    

        require(amount <= balances[msg.sender], "Error. Insufficient balance under your account.");
        require(amount <= balances[owner] / 20, "Error. Please reduce your PLAY amount.");

        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100 + 1;       

       if (randomNumber > winChance) {
            balances[msg.sender] -= amount;     
            balances[owner] += amount;
            emit BidLoss(msg.sender, "You Lose", amount, balances[msg.sender]);
        } else {          
            balances[msg.sender] += amount;      
            balances[owner] -= amount;
            emit BidWin(msg.sender, "You Win", amount, balances[msg.sender]);
        }
    }


    function Balance(address useraddress ) public view returns (uint256) {
        require(balances[useraddress] > 0, "Error.  Insufficient balance or account not exist.");
        return balances[useraddress];
    }


    event BidWin(address indexed bidder, string result, uint256 winAmount, uint256 balances);
    event BidLoss (address indexed bidder, string result, uint256 amount, uint256 balances);
}