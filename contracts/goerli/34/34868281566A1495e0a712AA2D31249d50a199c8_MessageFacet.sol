// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MessageFacet {
  // Create unique namepsace for specific storage slot.
  // Make sure to use unique naming convention in the format
  // of <variable name>.<unique facet>
  bytes32 internal constant NAMESPACE = keccak256("message.facet");

  // For storage we can use a struct to contain the format of the storage
  struct Storage {
    string message;
  }

  // Create an internal function for retrieving the storage slot associated to this facet
  function getStorage() internal pure returns (Storage storage s) {
    bytes32 position = NAMESPACE;
    assembly {
      s.slot := position
    }
  }

  // Create getter and setter methods for the facet storage
  function setMessage(string calldata _msg) external {
    Storage storage s = getStorage();
    s.message = _msg;
  }

  function getMessage() external view returns (string memory) {
    return getStorage().message;
  }
}