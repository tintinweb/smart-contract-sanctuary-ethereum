/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

//SPDX-License-Identifier: UNLICENSED
//store a string
//retrieve a string
//Deployed the contract in Javascript

pragma solidity ^0.8.7;

contract simplestorage {

        uint256 _storedNumber;

    function set(uint256 data) public {
        _storedNumber = data;

    } 
    function get() public view returns (uint256){
        return _storedNumber;

    }
    function addone() public returns (uint256){
        _storedNumber = _storedNumber + 1;
        return _storedNumber;
    }

}