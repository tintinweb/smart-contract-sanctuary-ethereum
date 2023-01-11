// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

struct TokenIdentifier {
  address collection;
  uint256 id;
}

library TokenIdentifierLibrary {
  // Compute the hash of an auction state object.
  function hash(TokenIdentifier calldata identifier)
      public
      pure
      returns (bytes32)
  {
      return keccak256(abi.encode(identifier));
  }
}