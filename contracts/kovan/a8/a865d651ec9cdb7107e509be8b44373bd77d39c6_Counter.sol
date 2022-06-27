/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Counter {
    int public count = 0;
    
    function increment() public returns(int) {
        count += 1;
        return count;
    }

    function decrement() public returns(int) {
        count -= 1;
        return count;
    }   
}