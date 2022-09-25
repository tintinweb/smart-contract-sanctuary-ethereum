/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.7;



contract SimpleCounter {

    uint256 private counter;

    constructor(){
        counter = 0;
    }

    function increment() external returns (uint256){
        counter++;
        return counter;
    }

    function get_increment() view public returns (uint256){
        return counter;
    }

}