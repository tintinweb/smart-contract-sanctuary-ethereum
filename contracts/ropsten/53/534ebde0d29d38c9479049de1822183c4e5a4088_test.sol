/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract test{
    event set(uint varr);
    
    uint var1;

    function setvar(uint a) public{
        var1 = a;
        emit set(var1);
    }
    function getvar() public view returns(uint){
        return var1;
    }
}