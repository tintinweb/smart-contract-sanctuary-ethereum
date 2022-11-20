/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract Alantest {
    uint public value;
    
    function create (uint y) public {
        value = y;
    }

    function addend (uint y) public {
        value = value+y;
    }
    function minus (uint y) public {
        if (y<value){
            value = value-y;
    }
    }
    function show() public view returns(uint){
       return value;
    }

}