//SPDX-License-identifier: MIT
pragma solidity ^0.8.10;

contract BoxV1{

    uint public val; 

    function initialize(uint _val)external{
        val = _val;
    }

    function version() public pure returns(string memory){
        return "V 1.1";
    }

}