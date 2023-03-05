/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract GuessingGame {

    uint256 number;

    function pick_new()
    public
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.prevrandao +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));

        number = (seed - ((seed / 1000) * 1000));
    }

    constructor() {
        pick_new();
    }

    function guess_num(uint256 guess) public view returns (string memory){
        if (number > guess) {
            return "Go Higher";
        } else if (number < guess) {
            return "Go Lower";
        } else {
            return "Correct Guess!";
        }
    }
}