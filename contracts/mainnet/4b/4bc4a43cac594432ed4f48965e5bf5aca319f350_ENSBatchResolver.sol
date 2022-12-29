/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

abstract contract Registry {
  function resolver(bytes32 node) external view virtual returns (address);
}

abstract contract Resolver {
  function addr(bytes32 node) external view virtual returns (address);
}

contract ENSBatchResolver {
  address immutable defaultRegistry = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;

  function batchResolveWithENSRegistry(bytes32[] calldata names) public view returns (address[] memory) {
    return batchResolveWithCustomRegistry(Registry(defaultRegistry), names);
  }

  function batchResolveWithCustomRegistry(Registry registry, bytes32[] calldata names)
    public
    view
    returns (address[] memory)
  {
    address[] memory addressList = new address[](names.length);
    for (uint256 i = 0; i < names.length; i++) {
      bytes32 currentName = names[i];

      address resolver = registry.resolver(currentName);

      if (resolver == address(0)) {
        addressList[i] = address(0);
      } else {
        addressList[i] = Resolver(resolver).addr(currentName);
      }
    }

    return addressList;
  }

  // to support receiving ETH by default
  receive() external payable {}

  fallback() external payable {}
}