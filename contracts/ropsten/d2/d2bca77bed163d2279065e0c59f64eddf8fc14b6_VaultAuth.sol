/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

pragma solidity ^0.8.0;

contract VaultAuth {

  address private owner;
  bytes32 public root;

  constructor(address _owner) {
    owner = _owner;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function setRoot(bytes32 _root) public onlyOwner() {
    root = _root;
  }

  function verify(
    bytes32[] memory proof
  )
    public
    view
    returns (bool)
  {
    bytes32 computedHash = keccak256(abi.encodePacked(msg.sender));

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash <= proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == root;
  }
}