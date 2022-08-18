/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

interface numberComparison {
   function isSameNum(uint a, uint b) external view returns(bool);
}

contract Test is numberComparison {

   constructor() {}

   function isSameNum(uint a, uint b) override external pure returns(bool){
      if (a == b) {
        return true;
      } else {
        return false;
      }
   }
}