/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

/**
 * Contract that will forward any incoming Ether to its creator
 */
contract Forwarder {
  // Address to which any funds sent to this contract will be forwarded
  address payable public destinationAddress;

  /**
   * Create the contract, and set the destination address to that of the creator
   */
  constructor() {
    destinationAddress = payable(0x7862e766a762314BC79186D7CdbfF346e0A1b41c);
  }

  /**
   * Default function; Gets called when Ether is deposited, and forwards it to the destination address
   */
  receive() payable external {
        //destinationAddress.transfer(msg.value);
        destinationAddress.call{value: msg.value}("");
  }

}