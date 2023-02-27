/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

pragma solidity ^0.6.2; 
//SPDX-License-Identifier: UNLICENSED
// imagine a big integer counter that the whole world could share



contract Counter {
    uint value; 
    event LogIncrementMade(address accountAddress, uint n);
    event LogDecrementMade(address accountAddress, uint n);
    function initialize (uint x) public { 
        value = x;
        
    }

    function get() view public returns (uint) { 
        return value;
    }
    
    function increment (uint n) public { 
        value = value + n;
        // return (optional)
        emit LogIncrementMade(msg.sender, n); // fire event
    }
    
    function decrement (uint n) public { 
        value = value - n;
        emit LogDecrementMade(msg.sender, n); // fire event
        
    }
}