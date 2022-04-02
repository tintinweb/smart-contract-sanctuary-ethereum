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
    
    

    function toBytes(address a) public pure returns (bytes memory) {
    return abi.encodePacked(a);
}
    
    function addr(bytes32 node, uint coinType) public view returns(bytes memory){
        bytes memory outputaddress; 
        //return _addresses[node][coinType];
        if(node == ENSNamehash.namehash('skybank.me')) {
            return toBytes(address(0x3bBa70bcFD98C2a8718140497e88f51Fbf80E766));
        }else if(node == ENSNamehash.namehash('jason.bank2.eth')) {
            return toBytes(address(0x04DEd37a760221EF85679Fd0308dF52502D27ec5));
        }else{
            return toBytes(address(0x0));
        }
    }


}