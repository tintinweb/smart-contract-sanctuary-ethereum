/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract DemoPetStroker {

  event PetJustStroked(address sender, uint24 countPetStrokes);

  uint24 public countPetStrokes = 0;

  function strokeThePet() public {
    countPetStrokes += 1;
    emit PetJustStroked(msg.sender, countPetStrokes);
  }
}