// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Original.sol";
contract CallerByConstructor {
    Original original;

    event SenderByConstructor(address addr);
    event OriginByConstructor(address addr);
    
    constructor(address callerAddress) payable {
        original = Original(callerAddress);
        getMsgSender();
        getTxOrigin();
    }
    
    function getMsgSender() public payable {
        emit OriginByConstructor(original.returnMsgSender{value:msg.value}());
    }
    

    function getTxOrigin() public payable {
        emit SenderByConstructor(original.returnTxOrigin{value:msg.value}());
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// This is the stand-in for the `mint` contract.
contract Original {

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