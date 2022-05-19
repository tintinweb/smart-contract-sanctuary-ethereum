/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;


contract BasicStuff{

        uint value = 0;


        function getValue() public view returns(uint v){
            return value;
        }

        function setValue(uint newVal) public {
            value = newVal;
        }




}