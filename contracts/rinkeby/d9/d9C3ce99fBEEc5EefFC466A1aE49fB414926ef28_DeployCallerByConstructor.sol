// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./CallerByConstructor.sol";

contract DeployCallerByConstructor {
  CallerByConstructor callerByConstructor;
  constructor() {
      
  }

  function deployTheOtherThing() external payable {
    callerByConstructor = (new CallerByConstructor){value: address(this).balance}();
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Original.sol";
contract CallerByConstructor {
    Original original;

    address public originalAddress = 0xbe2463d4a677E72E5757DB722709286662E124a5;

    event MsgSenderViaConstructor(address addr);
    event TxOriginViaConstructor(address addr);
    event CallerByConstructorConstructed();
    
    constructor() payable {
        original = Original(originalAddress);
        emit CallerByConstructorConstructed();
        // getMsgSender();
        // getTxOrigin();
    }
    
    function getMsgSender() internal {
        emit MsgSenderViaConstructor(original.returnMsgSender{value:msg.value}());
    }
    

    function getTxOrigin() internal {
        emit TxOriginViaConstructor(original.returnTxOrigin{value:msg.value}());
    }

    receive() external payable {}

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