/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract GuessTheRandomNumber {
    constructor() payable{}
    
    function guess(uint _guess) public {
        uint answer = uint(
            keccak256(abi.encodePacked(blockhash(block.number-1),block.timestamp))
        );

        if(_guess == answer){
            (bool sent,) = msg.sender.call{value: 0.0001 ether}("");
            require(sent,"Failed to send Ether");
        }
    }
}