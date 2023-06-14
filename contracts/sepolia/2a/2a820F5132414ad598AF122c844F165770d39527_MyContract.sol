// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    uint private num = 0;

    function value() public view returns(uint256){
        return num;
    }

    function increment() public {
        num++ ;
    }

    function decrement() public {
        num-- ;
    }
}