/**
 *Submitted for verification at Etherscan.io on 2022-10-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Counter {
   uint public counter;

    uint public immutable interval;
   uint public lastTimeStamp;

   constructor(uint updateInterval) {
     interval = updateInterval;
     lastTimeStamp = block.timestamp;

     counter = 0;
   }

   function incrementCounter() external {
        if ((block.timestamp - lastTimeStamp) > interval ) {
           lastTimeStamp = block.timestamp;
           counter = counter + 1;
       }
   }
}