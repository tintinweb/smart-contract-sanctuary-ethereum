/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract aaa {
    uint a;
    uint[] array;
    string[] name;

    function pushnumber(uint a) public returns(uint){
        array.push(a);
    }

function pushName(string memory s) public {
     name.push(s);
}


    function getnumber(uint _n) public view returns(uint){
             return array[_n-1];
    }
    function getName(uint _n) public view returns(string memory){
        return name[_n-1];
    }
  
   
    
    function lastnumber() public view returns(uint){
        return array[array.length-1];
    }
        function lastName() public view returns(string memory){
        return name[name.length-1];
    }
}