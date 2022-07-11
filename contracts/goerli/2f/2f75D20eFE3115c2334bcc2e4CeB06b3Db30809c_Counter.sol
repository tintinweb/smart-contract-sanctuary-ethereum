/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Counter {
    uint public count = 0;

    //get count 
    function getCount() public view returns(uint){
        return count;
    }

    //increment count
    function incrementCount() public {
        count += 1;
    }

    //decrement count
    function decrementCount() public {
        count -= 1;
    }
}