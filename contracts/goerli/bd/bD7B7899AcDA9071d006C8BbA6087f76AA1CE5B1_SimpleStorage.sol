// // SPDX-License-Identifier: MIT
// pragma solidity >=0.7.0 <0.9.0;


// contract HelloWorld {

//     string public message;

//     //constructor(string memory initialMessage) public {
//     //    message = initialMessage;
//     //}


//     function updateMessage(string memory newMessage) public {
//         message = newMessage;
//     }

//     function getMessage() public view returns (string memory) {
//         return message;
//     }
// }
// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.7.3;

// Defines a contract named `SimpleStorage`.
// A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Ethereum blockchain. Learn more: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract SimpleStorage {

   // Declares a state variable `message` of type `string`.
   // State variables are variables whose values are permanently stored in contract storage. The keyword `public` makes variables accessible from outside a contract and creates a function that other contracts or clients can call to access the value.
   string[] public message;

   // Similar to many class-based object-oriented languages, a constructor is a special function that is only executed upon contract creation.
   // Constructors are used to initialize the contract's data. Learn more:https://solidity.readthedocs.io/en/v0.5.10/contracts.html#constructors
   constructor(string memory initMessage) {

      // Accepts a string argument `initMessage` and sets the value into the contract's `message` storage variable).
      message.push(initMessage);
   }

   // A public function that accepts a string argument and updates the `message` storage variable.
   function update(string memory newMessage) public {
      message.push(newMessage);
   }

    function getMessage() public view returns (string[] memory) {
        string[] memory current_message = message;
        return current_message;
    }
}