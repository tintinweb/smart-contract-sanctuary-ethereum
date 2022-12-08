// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;
contract MagicNumber {
   //Signal to Web3, UI listening - an event happened-.
   event UpdatedMessages(uint8 oldNUM, uint8 newNUM);
   uint8 public magicNUM = 0;
   constructor(uint8 initNUM) {
      magicNUM = initNUM;
   }
   function updateNUM(uint8 newNUM) public {
      uint8 oldNUM = magicNUM;
      magicNUM = newNUM;
      emit UpdatedMessages(oldNUM, newNUM);
   }
}//~:)~