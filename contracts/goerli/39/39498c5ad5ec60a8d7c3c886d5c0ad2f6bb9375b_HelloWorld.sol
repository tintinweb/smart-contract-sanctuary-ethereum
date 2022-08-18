/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract HelloWorld {
  string public message;

  constructor(string memory initialMessage) {
    message = initialMessage;
  }

  function updateMessage(string memory newMessage) public {
    message = newMessage;
  }
}