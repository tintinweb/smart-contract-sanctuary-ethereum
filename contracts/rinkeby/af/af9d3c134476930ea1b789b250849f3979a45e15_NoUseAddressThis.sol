/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract NoUseAddressThis {
    address public owner;
    constructor(){
        owner = address(this);
    }
}