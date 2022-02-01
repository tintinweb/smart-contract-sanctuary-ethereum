/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Counter {

    uint count;
    
    constructor() {
        count=0;
    }


    function incrementCount() public {
        count +=1;
    }

    function getCount() public view returns (uint){
        return count;
    }
}