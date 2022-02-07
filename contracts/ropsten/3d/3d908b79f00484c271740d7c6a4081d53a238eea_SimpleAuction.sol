/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract SimpleAuction {
   uint storedData;

   function set(uint x) public{
       storedData = x;
   }
    
    function get() public view returns (uint){
        return storedData;
    }
}