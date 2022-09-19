/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface InterSabrinaAge{
    function SetAgeOfSabrina(uint256 _sabrinaAge) external returns(uint256);   
}

contract Lucifer{

    address public lucifer;

    constructor()
    {
        lucifer = msg.sender;
    }

    uint256 public SabrinaAge;



    function SetAgeOfSabrina(uint256 _sabrinaAge) external returns(uint256)
    {
        require(msg.sender == lucifer , "only lucifer can set the age");

        SabrinaAge = _sabrinaAge;

        return SabrinaAge;
    }
    
}