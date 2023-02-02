/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract HelloWorld {
    string public message;
    uint public number;

    constructor(string memory initialMessage, uint initialNumber) {
        message = initialMessage;
        number = initialNumber;
    }

    function updateMessage(string memory newMessage) public {
        message = newMessage;
    }

    function updateNumber(uint newNumber) public {
        number = newNumber;
    }
}