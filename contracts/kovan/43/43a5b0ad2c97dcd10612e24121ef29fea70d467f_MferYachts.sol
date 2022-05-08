/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: MIT
// File: contracts/MferYachts.sol

pragma solidity >=0.7.0 <0.9.0;

contract MferYachts{
    
  address private constant payoutAddress = 0xC7b20cF25cec4b6565C326764C5521ee9382dF2C;

  function withdraw() public{
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(payoutAddress).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}