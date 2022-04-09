/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title randAverageCalc
 * @dev Implements voting process along with vote delegation
 */
contract randAverageCalc {
   
    uint[] arr;
    uint256 total;
    uint256 average;

    function randGenerator() public returns(uint){
        for(uint i=0; i<15; i++){
            arr[i] = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, arr)));
            total += arr[i];
        }

        return total/15;
    }
}