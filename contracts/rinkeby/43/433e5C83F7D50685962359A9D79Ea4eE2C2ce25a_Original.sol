// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// This is the stand-in for the `mint` contract.
contract Original {

    uint256 someOtherNumber = 1;
    event OriginalMsgSender(address addr);
    event OriginalTxOrigin(address addr);

    function returnMsgSender() public payable returns(address) {
      emit OriginalMsgSender(msg.sender);
      return msg.sender;
    }
    
    function returnTxOrigin() public payable returns(address) {
      emit OriginalTxOrigin(tx.origin);
      return tx.origin;
    }
    
    constructor() {
        
    }
}