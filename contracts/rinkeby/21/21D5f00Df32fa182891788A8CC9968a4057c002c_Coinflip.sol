/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Coinflip {
    
    uint public coins;

    constructor() {
        coins = 0;
    }

    function random(uint seed) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % 100;
    } 

    function flip(string memory _face) public payable{
        coins += 1;
        uint randomValue = random(coins);
        require(
            keccak256(bytes(_face)) == keccak256(bytes("heads")) || keccak256(bytes(_face)) == keccak256(bytes("tails")), 
            "Coin must be heads or tails"
        );
        if (keccak256(bytes(_face)) == keccak256(bytes("heads"))) {
            if (randomValue < 50) {
                address payable winner = payable(msg.sender);
                winner.transfer(msg.value*2);
            }
        } else if (keccak256(bytes(_face)) == keccak256(bytes("tails"))) {
            if (randomValue > 50) {
                address payable winner = payable(msg.sender);
                winner.transfer(msg.value*2);
            }
        }
    } 
}