/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// File: Game.sol

/*
 * @title: 
 * @author: Anthony (fps) https://github.com/fps8k .
 * @dev: 
*/


contract Game
{
    // To prevent people from sending multiple eth.

    mapping(address => bool) public sent;

    uint8 count;




    /*
    * @dev:
    *
    * Anyone can play.
    * 14th person to send eth wins all the money in the contract.
    *
    * It's a gamble.
    */
    function play() public payable
    {
        require(msg.sender != address(0), "Invalid address");
        require(count < 14, "Game over");
        require(!sent[msg.sender], "You have played already.");

        // This guy is number 1.

        sent[msg.sender] = true;
        count ++;

        if (count == 14)
            payable(msg.sender).transfer(address(this).balance);

    }
}