/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

pragma solidity ^0.8.9;


contract Hash {
    function hashTransaction(address sender, uint256 qty, string memory nonce) public view returns(bytes32) {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, qty, nonce)))
          );
          
          return hash;
    }
}