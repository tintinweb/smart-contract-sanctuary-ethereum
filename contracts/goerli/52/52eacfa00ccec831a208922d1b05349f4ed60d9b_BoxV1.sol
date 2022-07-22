/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract BoxV1 {
    uint size;

    function initialize(uint _size) public{
        size = _size;
    }

    function increment() public {
        size++;
    }

    function decrement() public {
        size--;
    }

    function getSize() public view returns(uint) {return size;}
}