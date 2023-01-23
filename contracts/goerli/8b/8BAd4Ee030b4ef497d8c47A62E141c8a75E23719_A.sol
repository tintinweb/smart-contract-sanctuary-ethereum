/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.0 ;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */

 contract A{
    address public owner;
    constructor(address sender){
        owner=sender;
    }
 }