/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

pragma solidity >=0.4.21 <=0.6.0; 
// imagine a big integer counter that the whole world could share
contract Counter {
    uint value; 
    function initialize (uint x) public { 
        value = x;
        
    }

    function get() view public returns (uint) { 
        return value;
    }
    
    function increment (uint n) public { 
        value = value + n;
        // return (optional)
    }
    
    function decrement (uint n) public { 
        value = value - n;
        
    }
}