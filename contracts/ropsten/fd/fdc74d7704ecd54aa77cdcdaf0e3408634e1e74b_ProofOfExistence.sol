/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;contract ProofOfExistence {
  address owner = msg.sender;  //---define an event---
  event Document(address from, string text, bool valid);  //---store the hash of the strings---  
  mapping (bytes32 => bool) private proofs;
  //--------------------------------------------------
  // Store a proof of existence in the contract state
  //--------------------------------------------------
  function storeProof(bytes32 proof) private {
    // use the hash as the key
    proofs[proof] = true;
  }
  
  //----------------------------------------------
  // Calculate and store the proof for a document
  //----------------------------------------------
  function notarize(string memory document) public {
    require(msg.sender == owner, 
      'Only the owner of this contract can notarize a string');
    // call storeProof() with the hash of the string
    storeProof(proofFor(document));
  }
  
  //--------------------------------------------
  // Helper function to get a document's sha256
  //--------------------------------------------
  // Takes in a string and returns the hash of the string
  function proofFor(string memory document) private pure 
  returns (bytes32) {
    // converts the string into bytes array and then hash it
    return sha256(bytes(document));
  }
  
  //----------------------------------------
  // Check if a document has been notarized
  //----------------------------------------
  function checkDocument(string memory document) public payable {
    require(msg.value == 100 wei, 
      'This service requires a fee of 100 wei');    // transfer the money received to the owner
    payable(owner).transfer(msg.value);    // fire the Document event to return the result
    emit Document(msg.sender, document, proofs[proofFor(document)]);
  }}