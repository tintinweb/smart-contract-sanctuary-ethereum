/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract Test {
   address public owner;

   constructor() {
        owner = msg.sender;
    }

    function generateRandom(
        uint256 seed,
        uint256 salt,
        uint256 sugar
    ) public view onlyOwner returns (uint8) {
        bytes32 bHash = blockhash(block.number - 1);
        uint8 randomNumber = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, bHash, seed, salt, sugar))) % 100);
        return randomNumber;
    }

        modifier onlyOwner() {
            require(msg.sender == owner, "Ownable: caller is not the owner");
            _;
        }
         function setOwner(address newOwner) external onlyOwner {
             require(newOwner != address(0),"invalid address");
             owner = newOwner;
         } 
}