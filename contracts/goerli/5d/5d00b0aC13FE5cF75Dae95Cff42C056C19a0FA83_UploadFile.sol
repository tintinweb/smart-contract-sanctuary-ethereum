// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// Defines a contract named `UploadFile`.
// A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Ethereum blockchain. Learn more: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract UploadFile {

   //Emitted when update function is called
   //Smart contract events are a way for your contract to communicate that something happened on the blockchain to your app front-end, which can be 'listening' for certain events and take action when they happen.
   event UpdatedFile(string oldFile, string newFile);

   // Declares a state variable `file` of type `string`.
   // State variables are variables whose values are permanently stored in contract storage. The keyword `public` makes variables accessible from outside a contract and creates a function that other contracts or clients can call to access the value.
   string public file;

   // Similar to many class-based object-oriented languages, a constructor is a special function that is only executed upon contract creation.
   // Constructors are used to initialize the contract's data. Learn more:https://solidity.readthedocs.io/en/v0.5.10/contracts.html#constructors
   constructor(string memory initFile) {

      // Accepts a string argument `initFile` and sets the value into the contract's `file` storage variable).
      file = initFile;
   }

   // A public function that accepts a string argument and updates the `file` storage variable.
   function update(string memory newFile) public {
      string memory oldFile = file;
      file = newFile;
      emit UpdatedFile(oldFile, newFile);
   }
}