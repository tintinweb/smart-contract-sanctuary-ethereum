/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.22;

contract randomNumber {
   
    function renderHelloWorld () public pure returns (string) {
   return 'helloWorld';
 }

 function GetRandomNumber() public view returns(uint256) {
    uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)) +
        block.number
    )));

    return (seed - ((seed / 100) * 100));
}
}