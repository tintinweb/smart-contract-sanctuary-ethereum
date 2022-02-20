// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./CallerByConstructor.sol";

contract DeployCallerByConstructor {
  CallerByConstructor callerByConstructor;
  constructor() {
      
  }

  function deployTheOtherThing(address add) external payable {
    callerByConstructor = (new CallerByConstructor){value: msg.value}(add);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Original.sol";
contract CallerByConstructor {
    Original original;

    event MsgSenderViaConstructor(address addr);
    event TxOriginViaConstructor(address addr);
    
    constructor(address callerAddress) payable {
        original = Original(callerAddress);
        getMsgSender();
        getTxOrigin();
    }
    
    function getMsgSender() public payable {
        emit MsgSenderViaConstructor(original.returnMsgSender{value:msg.value}());
    }
    

    function getTxOrigin() public payable {
        emit TxOriginViaConstructor(original.returnTxOrigin{value:msg.value}());
    }

}

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