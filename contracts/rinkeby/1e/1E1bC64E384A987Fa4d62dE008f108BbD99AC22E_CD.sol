// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract CD {
    address public _owner;
    function getA() public view returns(address){
        return _owner;
    }
}