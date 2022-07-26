/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

abstract contract ReverseRegistrar {
  function node(address addr) public pure virtual returns (bytes32);
}

abstract contract ENS {
  function resolver(bytes32 node) public view virtual returns (address);
}

abstract contract Resolver {
  function name(bytes32 node) public view virtual returns (string memory);
}

contract ReverseResolution {
  ENS ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

  ReverseRegistrar reverseRegistrar =
    ReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);

  function getEns(address _address) public view returns (string memory) {
    bytes32 node = reverseRegistrar.node(_address);
    Resolver resolver = Resolver(ens.resolver(node));
    return resolver.name(node);
  }
}