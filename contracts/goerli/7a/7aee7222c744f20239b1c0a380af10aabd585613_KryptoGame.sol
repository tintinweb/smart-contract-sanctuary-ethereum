/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract KryptoGame {
    mapping(address => int256) public playerPoints;
    uint256 public pointstoWin = 1e10;
    uint256 public prize;
    bool public status;
    address public winner;
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
        status = true;
        prize += msg.value;
    }
    
    modifier onlyowner() {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    function getPrizePool() public view returns (uint) {
        return address(this).balance;
    }

    function addPoints(int256 _points) public {
        require(status == true, "Game is over.");
        require(_points <= 10, "Only allow to add less than 10 points!");
        playerPoints[msg.sender] += _points;
    }

    function winTheGame() public {
        require(uint256(playerPoints[msg.sender]) >= pointstoWin, "Not yet.");
        winner = msg.sender;
        status = false;
        payable(msg.sender).transfer(address(this).balance);
    }

    function BOMB() public onlyowner {
        selfdestruct(owner);
    }
}