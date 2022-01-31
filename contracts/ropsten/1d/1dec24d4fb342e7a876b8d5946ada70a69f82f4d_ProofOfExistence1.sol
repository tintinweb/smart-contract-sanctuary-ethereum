/**
 *Submitted for verification at Etherscan.io on 2022-01-29
*/

pragma solidity ^0.5.0;

contract ProofOfExistence1 {
      // state
      bytes32 public proof;

      // calculate and store the proof for a document
      // *transactional function*
      function notarize(string memory document) public {
        proof = proofFor(document);
      }

      // helper function to get a document's sha256
      // *read-only function*
      function proofFor(string memory document) public pure returns (bytes32) {
        return sha256(abi.encodePacked(document));
      }

}