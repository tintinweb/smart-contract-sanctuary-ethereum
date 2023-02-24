/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Gamble {
    uint256 public constant price = 10; // Price you have to pay for gambling
    address public owner; // The owner of the contract
    //uint256 private seed; //
    uint256 private constant chance = 10;


    constructor() payable {
        owner = msg.sender;
    }

    function play() public payable {
        require(msg.value == price, "Bet amount does not match required amount");
        require(address(this).balance >= msg.value * 2, "The Gamble machine is bankrupt please try again later");

        uint256 random = getRandomNumber();

        // obviously unfair odds because the casino has to win :D
        if (random > 8) {
            uint256 winnings = msg.value * 2;
            payable(msg.sender).transfer(winnings);
        }
    }


    // function to generate random int from internet
    function getRandomNumber() private view returns (uint256) {
        uint256 rand = block.timestamp + block.difficulty + uint256(keccak256(abi.encodePacked(msg.sender)));
        return (rand % chance) + 1;
    }


    // Owner wants to get rich from this contract so we need to be able to withdraw
    function withdrawFunds() public {
        require(msg.sender == owner, "You are not the contract owner");
        payable(msg.sender).transfer(address(this).balance);
    }
}