/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract HelloToken {
  
    // Begin: state variables
    address private creator;
    address private lastCaller;
    string private message;
    uint private totalGas;
    // End: state variables

    // Begin: constructor
    constructor() {
        /*
          We can use the special variable `tx` which gives us information
          about the current transaction.

          `tx.origin` returns the sender of the transaction.
          `tx.gasprice` returns how much we pay for the transaction
        */
        creator = tx.origin;
        totalGas = tx.gasprice;
        message = 'Hello token';
    }
    // End: constructor

    // Begin: getters
    function getMessage() public view returns(string memory) {
        return message;
    }

    function getLastCaller() public view returns(address) {
        return lastCaller;
    }

    function getCreator() public view returns(address) {
        return creator;
    }

    function getTotalGas() public view returns(uint) {
        return totalGas;
    }
    // End: getters

    // Being: setters
    function setMessage(string memory newMessage) public {
        message = newMessage;
        lastCaller = tx.origin;
        totalGas += tx.gasprice;
    }
    // End: setters
}