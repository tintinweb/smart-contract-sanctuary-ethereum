/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: GPL-3.0
// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.8.0;

// Defines a contract named `RandomNumber`.
// A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Ethereum blockchain. Learn more: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract Quayso {
   uint public range;
   uint public randnumber;

   //Emitted when update function is called
   //Smart contract events are a way for your contract to communicate that something happened on the blockchain to your app front-end, which can be 'listening' for certain events and take action when they happen.
   event SoDaQuay(uint randNumber, uint luckyNumber);

   // Similar to many class-based object-oriented languages, a constructor is a special function that is only executed upon contract creation.
   // Constructors are used to initialize the contract's data. Learn more:https://solidity.readthedocs.io/en/v0.5.10/contracts.html#constructors
   constructor() {
      range = 1000;
      // randNumber(range);
   }

   // A public function that accepts a string argument and updates the `message` storage variable.
   function quayso(uint yourluckynumber) public returns(uint) {
      randnumber = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % range;

      emit SoDaQuay(randnumber, yourluckynumber);
      
      return randnumber;
   }
}