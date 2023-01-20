/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice Defines a contract named `HelloWorld`
 * @dev A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Ethereum blockchain. Learn more: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
 */
contract HelloWorld {
    /**
     * @notice Emitted when update function is called
     * @dev Smart contract events are a way for your contract to communicate that something happened on the blockchain to your app front-end, which can be 'listening' for certain events and take action when they happen.
     * @param oldStr the previous string
     * @param newStr the latest string
     */
    event UpdatedMessages(string oldStr, string newStr);

    /**
     * @notice Declares a state variable `message` of type `string`.
     * @dev State variables are variables whose values are permanently stored in contract storage. The keyword `public` makes variables accessible from outside a contract and creates a function that other contracts or clients can call to access the value.
     */
    string public message;

    /**
     * @notice Similar to many class-based object-oriented languages, a constructor is a special function that is only executed upon contract creation.
     * @dev Constructors are used to initialize the contract's data. Learn more:https://solidity.readthedocs.io/en/v0.5.10/contracts.html#constructors
     * @param initMessage the initial message
     */
    constructor(string memory initMessage) {
        // Accepts a string argument `initMessage` and sets the value into the contract's `message` storage variable).
        message = initMessage;
    }

    /**
     * @notice A public function that accepts a string argument and updates the `message` storage variable.
     * @param newMessage the new message to be persisted on the contract
     */
    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}