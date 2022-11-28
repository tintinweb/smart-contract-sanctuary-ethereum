/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

//contracts/Proxy.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract Proxy  {
  address public implementation;

  constructor(address _implementation) {
    implementation = _implementation;
  }

  function getImplementation() external view returns (address) {
    return implementation;
  }

  function setImplementation(address _implementation) external {
    implementation = _implementation;
  }

  fallback() external {
    address _impl = implementation;
    assembly {
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas(), _impl, 0, calldatasize(), 0, 0)
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
}