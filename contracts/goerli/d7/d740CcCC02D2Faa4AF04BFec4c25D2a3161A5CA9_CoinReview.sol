// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract CoinReview {

 // address mapping to get Wei and check balance
 mapping (address => bool) public addressesMapping;

 // event for when a new ipfs hash have been received
 event ipfsHashReceived(string ipfsHash);

 // receives 1 Wei and keeps balance
 receive() external payable {
  // check if the amount is 1 Wei
  require(msg.value == 1 wei, "Needs 1 Wei");
  // check that the address didn't already pay
  require(addressesMapping[msg.sender] != true, "Already paid");
  // the address paid 1 Wei
  addressesMapping[msg.sender] = true;
 }

 // store the ipfs hash if not already present and if 1 Wei have been paid
 function setIpfsHash(string memory _ipfsHash) public {
  // check if the address already have balance
  require(addressesMapping[msg.sender] == true, "Not paid 1 Wei");
  // reset the balance to 0 (false)
  addressesMapping[msg.sender] = false;
  // emit the event that a new ipfs hash have been received
  emit ipfsHashReceived(_ipfsHash);
 }

}