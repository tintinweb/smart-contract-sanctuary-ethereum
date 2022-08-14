/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.0;

/** 
 * @title Claim ownership of the contract below to complete this level
 * @dev Implement one time hackable smart contract (Switch)
 */
contract Switch {
  address public owner;

  modifier onlyOwner {
    require(
      msg.sender == owner,
      "caller is not the owner"
    );
    _;
  }

  constructor() {
    owner = msg.sender;
  }
  
  // Changes the ownership of the contract. Can only be called by the owner
  function changeOwnership(address _owner) public onlyOwner {
    owner = _owner;
  }

  // Allows the owner to delegate the change of ownership to a different address by providing the owner's signature
  function changeOwnership(uint8 v, bytes32 r, bytes32 s) public {
    require(ecrecover(generateHash(owner), v, r, s) != address(0), "signer is not the owner");
    owner = msg.sender;
  }
  
  // Generates a hash compatible with EIP-191 signatures 
  function generateHash(address _addr) private pure returns (bytes32) {
    bytes32 addressHash = keccak256(abi.encodePacked(_addr));
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", addressHash));
  }
}