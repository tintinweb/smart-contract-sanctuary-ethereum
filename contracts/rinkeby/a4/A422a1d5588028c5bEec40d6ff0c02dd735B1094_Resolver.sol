/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

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

contract Resolver {
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant private ADDRESS_INTERFACE_ID = 0xf1cb7e06;
    uint constant private COIN_TYPE_ETH = 60;

    

    /**
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    //function setAddr(bytes32 node, address a) external authorised(node) {
        //setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
      //  return '0x0';
    //}

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    //function addr(bytes32 node) public view returns (address payable) {
        //bytes memory a = addr(node, COIN_TYPE_ETH);
        //if(a.length == 0) {
        //    return address(0);
        //}
        //return bytesToAddress(a);
        //return '0x0';
    //}

    //function setAddr(bytes32 node, uint coinType, bytes memory a) public authorised(node) {
        //emit AddressChanged(node, coinType, a);
        //if(coinType == COIN_TYPE_ETH) {
        //    emit AddrChanged(node, bytesToAddress(a));
        //}
        //_addresses[node][coinType] = a;
    //    return '0x0';
    //}


    
    function addr(bytes32 node, uint coinType) public view returns(bytes memory) {
        //return _addresses[node][coinType];
        if(node == ENSNamehash.namehash('skybank.me')) {
            return '0x3bba70bcfd98c2a8718140497e88f51fbf80e766';
        }else if(node == ENSNamehash.namehash('jason.bank2.eth')) {
            return '0x3bba70bcfd98c2a8718140497e88f51fbf80e767';
        }else{
            return '0x0';
        }
    }

   // function supportsInterface(bytes4 interfaceID) public pure returns(bool) {
   //     //return interfaceID == ADDR_INTERFACE_ID || interfaceID == ADDRESS_INTERFACE_ID || super.supportsInterface(interfaceID);
   //     return interfaceID;
   // }
}