// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Proxy {
  address implementation_;
  address public admin;

  constructor(address impl) {
    implementation_ = impl;
    admin = msg.sender;
  }

  receive() external payable {}

  function setImplementation(address newImpl) public {
    require(msg.sender == admin);
    implementation_ = newImpl;
  }

  function implementation() public view returns (address impl) {
    impl = implementation_;
  }

  function transferOwnership(address newOwner) external {
    require(msg.sender == admin);
    admin = newOwner;
  }

  function _delegate(address implementation__) internal virtual {
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), implementation__, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())

      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  function _implementation() internal view returns (address) {
    return implementation_;
  }

  fallback() external payable virtual {
    _delegate(_implementation());
  }
}