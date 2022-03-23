/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

contract SimpleStorage{

    uint public storedData;
    // uint storad;
    function set(uint x) public  {
        storedData = x;

    }

    function get() public view returns(uint){
       
        return storedData;
    } 
}