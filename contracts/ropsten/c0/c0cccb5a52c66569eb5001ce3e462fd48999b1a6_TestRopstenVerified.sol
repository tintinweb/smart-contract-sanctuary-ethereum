/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title HelloScSD2
 * @dev Kacikalin
 */

 contract TestRopstenVerified {

     uint public v2;

     function set(uint value) public {
         v2=value;
     }
     function get() public view returns (uint) {
         return v2;
     }

     function killFunctionverified() public {
        selfdestruct(payable(msg.sender));
     }
 }