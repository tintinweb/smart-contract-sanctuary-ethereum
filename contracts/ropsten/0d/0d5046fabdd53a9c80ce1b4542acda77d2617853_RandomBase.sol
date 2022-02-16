/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

pragma solidity ^0.8.0;


contract ETHReceiver {

    event Balance(uint256 roundNumber);

    uint256 public counter;

    function testSend() public payable {
        emit Balance(address(this).balance);
        counter += msg.value;
    }

    function vrf() public view returns (bytes32 result) {
        uint[1] memory bn;
        bn[0] = block.number;
        assembly {
        let memPtr := mload(0x40)
        if iszero(staticcall(not(0), 0xff, bn, 0x20, memPtr, 0x20)) {
            invalid()
        }
        result := mload(memPtr)
        }
  }

}

contract RandomBase {

  uint256 private seedNonce;

  function vrf() public view returns (bytes32 result) {
    uint[1] memory bn;
    bn[0] = block.number;
    assembly {
      let memPtr := mload(0x40)
      if iszero(staticcall(not(0), 0xff, bn, 0x20, memPtr, 0x20)) {
        invalid()
      }
      result := mload(memPtr)
    }
  }

  function random() public view returns (uint256 rand) {
    rand = uint256(keccak256(abi.encode(vrf(), seedNonce)));
    
    return rand;
  }

  function incSeed() public returns (uint256 seed) {
      seedNonce++;
      seed = seedNonce;
  }
}