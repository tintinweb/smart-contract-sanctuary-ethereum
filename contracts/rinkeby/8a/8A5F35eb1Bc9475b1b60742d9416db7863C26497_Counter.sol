// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

error CounterError();


abstract contract CounterPrimitive {

    uint256 public i;

    function increment() virtual external {
        i = i + 1;
    }

}


contract Counter is CounterPrimitive {
    
    function incrementBy(uint256 a) virtual external returns(bool){
        i = i + a;
    }

    function incrementWithReturn() virtual external returns(bool) {
        i = i + 1;
    }

    function fail() virtual external {
        if(i==0) revert CounterError();

        i = i + 1;
    }

}