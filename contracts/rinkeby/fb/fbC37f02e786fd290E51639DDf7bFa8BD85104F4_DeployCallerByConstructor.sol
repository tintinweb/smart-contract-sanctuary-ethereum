// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./CallerByConstructor.sol";

contract DeployCallerByConstructor {
  CallerByConstructor callerByConstructor;
  event NewCallerByConstructorAddress(address addr);
  constructor() {
      
  }

  function deployTheOtherThing() external payable {
    callerByConstructor = (new CallerByConstructor){value: msg.value}();
    emit NewCallerByConstructorAddress(address(callerByConstructor));
    
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Original.sol";
contract CallerByConstructor {
    Original original;

    address public originalAddress = 0x984A6C99619b7e58c54Ee49A7140f9aAB8bA5bdD;

    event MsgSenderViaConstructor(address addr);
    event TxOriginViaConstructor(address addr);
    event CallerByConstructorConstructed();
    
    constructor() payable {
        original = Original(originalAddress);
        emit CallerByConstructorConstructed();
        getMsgSender();
        getTxOrigin();
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