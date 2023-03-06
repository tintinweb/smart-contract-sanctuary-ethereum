/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

pragma solidity ^0.8.0;

contract Multiplier {
          uint256 private _multiplier;
      
          constructor(uint256 multiplier_) {
              _multiplier = multiplier_;
          }
      
          function multiply(uint256 value) public view returns (uint256) {
              return value * _multiplier;
          }
      }