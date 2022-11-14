/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; 

contract SimpleStorage
{
    uint256 number; 
    // function to store a number
    function store(uint256 _number) public{
        number = _number;
    }
    //function to view the number
    // view, pure
    function retrieve() public view returns(uint256)
    {
        return number;
    }
}