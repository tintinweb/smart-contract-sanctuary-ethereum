/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract A{
    uint public abc;

    function setABC(uint _abc) public{
        abc=_abc;
    }

    function setABC()public{
        abc=10;
    }
    function getABC()public view returns(uint){
        return abc;
    }
}

contract B{
    A a;

    constructor(address _ad){
        a=A(_ad);
    }

    function setABC(uint _abc) public{
        a.setABC(_abc);
    }

    function getABC()public view returns(uint){
        return a.getABC();
    }
}