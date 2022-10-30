/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;



contract buyToken {
    
    uint counter = 5;

    function returnCounter()public view returns(uint){
        return counter;
    }

    function increment()public{
        counter ++;
        
    }

    function decrement()public{
        counter --;
    }

    function multi()public{
        counter = counter * 2;
    }

    function multiplyCounter()public{
        counter = counter * counter;
    }
}