/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract BoxV2 {
    uint size;

    function initialize(uint _size) public{
        size = _size;
    }

    function incrementByTwo() public {
        size+=2;
    }

    function decrement() public {
        size-=2;
    }
    function incBy(uint i) public {
        size+=i;
    }

    function getSize() public view returns(uint) {return size;}

}