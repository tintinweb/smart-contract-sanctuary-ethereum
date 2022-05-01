//SPDX-License-identifier: MIT
pragma solidity ^0.8.10;

contract Boxv2{

    uint public val; 

    function increase()external{
        val +=1;
    }

    function version() public pure returns(string memory){
        return "V 2.0";
    }

}