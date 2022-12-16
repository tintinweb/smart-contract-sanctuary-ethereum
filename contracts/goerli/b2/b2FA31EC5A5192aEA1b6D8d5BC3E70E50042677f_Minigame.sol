/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Minigame {
    address private owner;
    uint256 public startTime;
    uint256 public endTime;

    // Modifiers
    modifier isOngoing() {
        require(block.timestamp < endTime, 'This auction is closed.');
        _;
    }
    modifier notOngoing() {
        require(block.timestamp >= endTime, 'This auction is still open.');
        _;
    }
    modifier isOwner() {
        require(msg.sender == owner, 'Only owner can perform task.');
        _;
    }
    modifier notOwner() {
        require(msg.sender != owner, 'Owner is not allowed to bid.');
        _;
    }

    // event SM_send_data(address _wallet, string _id);
    event SM_send_number(uint256 _num1, uint256 _num2, uint256 _num3);

    constructor () {
        owner = msg.sender;
        startTime = block.timestamp;
        endTime = block.timestamp + 3 hours;
    }

    function rollDices() public payable {
        uint randomHash1 = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        uint randomHash2 = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) + 3;
        uint randomHash3 = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) + 5;
        uint256 winningNumber1 = randomHash1 % 6 + 1;
        uint256 winningNumber2 = randomHash2 % 6 + 1;
        uint256 winningNumber3 = randomHash3 % 6 + 1;
        emit SM_send_number(winningNumber1, winningNumber2, winningNumber3);
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw(address payable _to, uint amount) public {
        _to.transfer(amount);
    }
}