/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: GPL-3.0
// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity ^0.8.0;

// Defines a contract named `RandomNumber`.
// A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Ethereum blockchain. Learn more: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract RandomNumber {
   uint public randnumber;

   // Similar to many class-based object-oriented languages, a constructor is a special function that is only executed upon contract creation.
   // Constructors are used to initialize the contract's data. Learn more:https://solidity.readthedocs.io/en/v0.5.10/contracts.html#constructors
   constructor(uint range) {
      randNumber(range);
   }

   // A public function that accepts a string argument and updates the `message` storage variable.
   function randNumber(uint range) public {
      randnumber = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % range;
   }
}