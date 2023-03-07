// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract Assessment_2_Solution {

	  function solution(uint256 n) external {
        assembly {
          sstore(3,n)
       }
    }
}