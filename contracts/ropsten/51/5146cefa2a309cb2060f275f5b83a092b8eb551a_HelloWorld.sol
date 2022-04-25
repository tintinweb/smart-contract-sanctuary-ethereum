/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * this is a submission for ZKU (May 2022 Cohort)
 */

contract HelloWorld {
  // this is the stored number, will start on 0 by default
  uint256 public theNumber;
  
  /**
   * This function will store the number submitted by a user and
   * store it in contract public variable theNumber
   */
  function storeNumber(uint256 _number) external {
    theNumber = _number;
  }

  function retrieveNumber() external view returns(uint256) {
    return theNumber;
  }
}