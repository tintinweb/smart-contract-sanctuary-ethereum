pragma solidity ^0.8.6;

contract Proxy {

  //two assembly memory slots locations
  bytes32 private constant _OWNER_SLOT = 0x88adb49ea8abc2bb46e32738badcecbad2a2cb53bc2f4f7f1af7507bb78d1075;  //private key to metamask wallet account (ganache3)
  bytes32 private constant _SMARTCONTRACTWITHLOGIC_SLOT = 0x00000000000000000000000062830175Ce101c4f645bbfdf36c19D4cff8E7f6d;
/* 0x62830175Ce101c4f645bbfdf36c19D4cff8E7f6d; //token address ? (no)    // anyway try */
/* 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc    // their sample */
/* 0xb9ad5cfe3bc6517b50e14101a96fe330bf1928591af46e9e1004adaa84144116    //my txn hash (plant_v1) */

  constructor() {
    bytes32 slot = _OWNER_SLOT;
    address _admin = msg.sender;
    assembly {
    //allows you to store a value in storage
      sstore(slot, _admin)
    }
  }


  //address of the owner
  function admin() public view returns (address owner) {
    bytes32 slot = _OWNER_SLOT;
    assembly {
      //read a value in storage
      owner := sload(slot)
    }
  }


  //address of the contract with business logic
  function SMARTCONTRACTWITHLOGIC() public view returns (address contractwithlogic) {
    bytes32 slot = _SMARTCONTRACTWITHLOGIC_SLOT;
    assembly {
      contractwithlogic := sload(slot)
    }
  }


  //function used to change the address of the contract containing business logic
  function upgrade(address newContract) external {
    //verify the sender is the admin
    require(msg.sender == admin(), 'You must be an owner only');
    bytes32 slot = _SMARTCONTRACTWITHLOGIC_SLOT;
    assembly {
      //store in memory the new address
      sstore(slot, newContract)
    }
  }


//user calls a function that does not exist in this contract so the fallback function is called
//assembly is used


  fallback() external payable {
    assembly {
      //get the address of the contract that contains business logic
      //save address in temporary memory
      let _target := sload(_SMARTCONTRACTWITHLOGIC_SLOT)
      //copy the function call in memory
      //first parameter is the memory slot we want to copy the function call to
      //second parameter is the memory slot we want to copy from
      //third parameter is the size we want to copy which is all data
      calldatacopy(0x0, 0x0, calldatasize())
      //forward the call to the smart contract that contains the business logic
      //specify the gas, address of contract, function we want to call and size
      //if the call is successful it will be stored in the bool result
      let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)
      //copy the return data into memory
      returndatacopy(0x0, 0x0, returndatasize())
      //if the result is 0 and failed then revert
      switch result case 0 {revert(0, 0)} default {return (0, returndatasize())}
    }
  }
}