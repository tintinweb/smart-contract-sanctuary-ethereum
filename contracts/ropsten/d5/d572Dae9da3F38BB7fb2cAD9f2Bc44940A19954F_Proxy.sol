pragma solidity ^0.8.6;

contract Proxy {

  bytes32 private constant _OWNER_SLOT = 0x88adb49ea8abc2bb46e32738badcecbad2a2cb53bc2f4f7f1af7507bb78d1075;
  bytes32 private constant _SMARTCONTRACTWITHLOGIC_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  constructor() {
    bytes32 slot = _OWNER_SLOT;
    address _admin = msg.sender;
    assembly {
      sstore(slot, _admin)
    }
  }

  function admin() public view returns (address owner) {
    bytes32 slot = _OWNER_SLOT;
    assembly {
      owner := sload(slot)
    }
  }

  function SMARTCONTRACTWITHLOGIC() public view returns (address contractwithlogic) {
    bytes32 slot = _SMARTCONTRACTWITHLOGIC_SLOT;
    assembly {
      contractwithlogic := sload(slot)
    }
  }

  function upgrade(address newContract) external {
    require(msg.sender == admin(), 'You must be an owner only');
    bytes32 slot = _SMARTCONTRACTWITHLOGIC_SLOT;
    assembly {
      sstore(slot, newContract)
    }
  }


  fallback() external payable {
    assembly {
      let _target := sload(_SMARTCONTRACTWITHLOGIC_SLOT)
      calldatacopy(0x0, 0x0, calldatasize())
      let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)
      returndatacopy(0x0, 0x0, returndatasize())
      switch result case 0 {revert(0, 0)} default {return (0, returndatasize())}
    }
  }
}