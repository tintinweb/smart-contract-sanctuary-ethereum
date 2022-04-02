/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

library ENSNamehash {
  function namehash(bytes memory domain) internal pure returns (bytes32) {
    return namehash(domain, 0);
  }

  function namehash(bytes memory domain, uint256 i) internal pure returns (bytes32) {
    if (domain.length <= i) return 0x0000000000000000000000000000000000000000000000000000000000000000;

    uint256 len = labelLength(domain, i);

    return keccak256(abi.encodePacked(namehash(domain, i + len + 1), keccak(domain, i, len)));
  }

  function labelLength(bytes memory domain, uint256 i) private pure returns (uint256) {
    uint256 len;
    while (i + len != domain.length && domain[i + len] != 0x2e) {
      len++;
    }
    return len;
  }

  function keccak(
    bytes memory data,
    uint256 offset,
    uint256 len
  ) private pure returns (bytes32 ret) {
    require(offset + len <= data.length);
    assembly {
      ret := keccak256(add(add(data, 32), offset), len)
    }
  }
}

contract ENSResolver {
  bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
  bytes4 constant private ADDRESS_INTERFACE_ID = 0xf1cb7e06;
  uint constant private COIN_TYPE_ETH = 60;

  function addr(bytes32 node, uint coinType) public view returns(bytes memory){
    //return _addresses[node][coinType];
    coinType = coinType;
    if(node == ENSNamehash.namehash('skybank.eth')) {
      return toBytes(address(0x3bBa70bcFD98C2a8718140497e88f51Fbf80E766));
    }else if(node == ENSNamehash.namehash('jason.skybank.eth')) {
      return toBytes(address(0x04DEd37a760221EF85679Fd0308dF52502D27ec5));
    }else if(node == ENSNamehash.namehash('kristy.skybank.eth')) {
      return toBytes(address(0xFB42c865fa1916eE7bBAe85cCf1755fd0a5cEe8B));
    }else if(node == ENSNamehash.namehash('eventx.skybank.eth')) {
      return toBytes(address(0xc8aB761511C9955cD534BBF9C29127AcA4179b26));
    }else if(node == ENSNamehash.namehash('eventxdev.skybank.eth')) {
      return toBytes(address(0xc8aB761511C9955cD534BBF9C29127AcA4179b26));
    }else if(node == ENSNamehash.namehash('nova.skybank.eth')) {
      return toBytes(address(0xD2078D5Dd64D0085e8d1Aa29D0D9a0Fad5cf906b));
    }else{
        return toBytes(address(0x0));
    }
  }

  function addr(bytes32 node) public view returns (address) {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if(a.length == 0) {
            return address(0x0);
        }
        return bytesToAddress(a);
  }  

  function toBytes(address a) public pure returns (bytes memory) {
      return abi.encodePacked(a);
    } 

  function bytesToAddress(bytes memory b) internal pure returns(address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }
}