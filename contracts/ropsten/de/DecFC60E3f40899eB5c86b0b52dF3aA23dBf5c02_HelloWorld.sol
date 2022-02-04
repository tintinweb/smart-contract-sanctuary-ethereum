/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.7.3;

// Defines a contract named `HelloWorld`.
// A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Ethereum blockchain. Learn more: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract HelloWorld {

   //Emitted when update function is called
   //Smart contract events are a way for your contract to communicate that something happened on the blockchain to your app front-end, which can be 'listening' for certain events and take action when they happen.
   event UpdatedAmount(uint256 oldAmount, uint256 newAmount);

   event UpdatedMessages(string oldStr, string newStr);

   event UpdateMint(bool oldMint, bool newMint);

   // Declares a state variable `message` of type `string`.
   // State variables are variables whose values are permanently stored in contract storage. The keyword `public` makes variables accessible from outside a contract and creates a function that other contracts or clients can call to access the value.
   string public message;

   bool public mint;

   uint256 public amount;

   // Similar to many class-based object-oriented languages, a constructor is a special function that is only executed upon contract creation.
   // Constructors are used to initialize the contract's data. Learn more:https://solidity.readthedocs.io/en/v0.5.10/contracts.html#constructors
   constructor(string memory initMessage, bool initMint) {

      // Accepts a string argument `initMessage` and sets the value into the contract's `message` storage variable).
      message = initMessage;
      mint = initMint;
   }

   // A public function that accepts a string argument and updates the `message` storage variable.
   function update(string memory newMessage) public {
      string memory oldMsg = message;
      message = newMessage;
      emit UpdatedMessages(oldMsg, newMessage);
   }

   // A public function that accepts a string argument and updates the `message` storage variable.
   function toggle_sale(bool newMint) public {
      bool oldMint = mint;
      mint = newMint;
      emit UpdateMint(oldMint, newMint);
   }

   function mint_that_crap(uint256 newAmount) public {

       uint256 oldAmount = amount;
      amount = newAmount;
      emit UpdatedAmount(oldAmount, newAmount);

       

   }
}