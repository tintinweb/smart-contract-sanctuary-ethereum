// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract test_integrritywith_unity {
    uint256 myTotal =0;

    function addtotal(uint8 _myArg, uint8 _oneMore) public {
        myTotal = myTotal + _myArg+ _oneMore;
        
    }
    function show()public view returns(uint256) {
        return myTotal;
    }   
}