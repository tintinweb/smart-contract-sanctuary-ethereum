/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.16;

contract Counter {
    
    uint private _count; 

    function count() view public returns (uint count_) {
        return _count;
    }

    function getcount(uint anothernumber) pure public returns (uint count_) {
        return anothernumber;
    }

    function increment() public {
        _count++;
    }

    function decrement() public {
        _count--;
    }


}