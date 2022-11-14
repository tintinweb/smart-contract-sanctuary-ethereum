/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Counters{
    
    uint256 count;
    event Incremented(uint256 from,uint256 to);

    constructor() {
        count=0;
    }

    function increment() public {
        emit Incremented(count,count+1);

        count+=1;
    }
    function getCount() public view returns (uint256) {
        return count;
    }
    
}