/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERCProxy {
  function proxyType() external pure returns (uint256 proxyTypeId);

  function implementation() external view returns (address codeAddr);
}



abstract contract Proxy is IERCProxy {

  function delegatedFwd(address _dst) internal {
    address _implementation =_dst;

    require(_implementation != address(0x0), "MISSING_IMPLEMENTATION");
    assembly {

      calldatacopy(0, 0, calldatasize())

      let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

      returndatacopy(0, 0, returndatasize())

      switch result
      case 0 {revert(0, returndatasize())}
      default {return (0, returndatasize())}
    }

  }

  function proxyType() external virtual override pure returns (uint256 proxyTypeId) {
    // Upgradeable proxy
    proxyTypeId = 2;
  }

  function implementation() external virtual override view returns (address);
}



contract UpgradableProxy is Proxy {
  event ProxyUpdated(address indexed _new, address indexed _old);
  event ProxyOwnerUpdate(address _new, address _old);

  bytes32 constant IMPLEMENTATION_SLOT = keccak256("matic.network.proxy.implementation");
  bytes32 constant OWNER_SLOT = keccak256("matic.network.proxy.owner");


  fallback() external payable {
    delegatedFwd(loadImplementation());
  }

  receive() external payable {
    delegatedFwd(loadImplementation());
  }

  function implementation() external override view returns (address) {
    return loadImplementation();
  }

  function loadImplementation() internal view returns(address) {
    address _impl;
    bytes32 position = IMPLEMENTATION_SLOT;
    assembly {
      _impl := sload(position)
    }
    return _impl;
  }

  function updateImplementation(address _newProxyTo) public  {

    setImplementation(_newProxyTo);
  }


  function setImplementation(address _newProxyTo) private {
    bytes32 position = IMPLEMENTATION_SLOT;
    assembly {
      sstore(position, _newProxyTo)
    }
  }

  function isContract(address _target) public view returns (bool) {
    if (_target == address(0)) {
      return false;
    }

    uint256 size;
    assembly {
      size := extcodesize(_target)
    }
    return size > 0;
  }
}


contract RootChainManagerProxy is UpgradableProxy {

}