/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

//SPDX-License-Identifier : MIT

pragma solidity >=0.8.2 <0.9.0;

contract testIncrement {

uint public x = 1;

    function getData (uint _x) public {
        x = _x ;
    }

    function increment () public returns(uint) {
        return x++;
    }

      function decrement () public returns(uint) {
        return x--;
    }

}