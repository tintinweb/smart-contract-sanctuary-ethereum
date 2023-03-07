// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract Assessment_1_Solution {

	  function solution(address addr) external view returns(uint256){
        uint256 size;
     
        assembly {
            size := extcodesize(addr)
        }

        return size;
      }
}