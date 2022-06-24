/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title HelloScSD2
 * @dev Kacikalin
 */

 contract HelloScSD2 {

     string public sttr="Helllooo";

     function killFunction() public {
        selfdestruct(payable(msg.sender));
     }
 }