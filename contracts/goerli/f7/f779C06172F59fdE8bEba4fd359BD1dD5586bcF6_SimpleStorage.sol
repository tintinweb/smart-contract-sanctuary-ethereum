/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

pragma solidity ^0.5.7;

      contract SimpleStorage {
          uint storedData;
      
          function set(uint x) public {
              storedData = x;
          }
      
          function get() public view returns (uint) {
              return storedData;
          }
      }