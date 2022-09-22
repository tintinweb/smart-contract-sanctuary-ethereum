/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract C {


    function add(uint a, uint b) public view returns(uint){
        return a+b;
    }

     function add2(int a, int b) public view returns(int){
        return a-b;
    }

     function X(uint a, uint b) public view returns(uint){
        return a*b;
     }

        function N(uint a, uint b) public view returns(uint, uint){
          return (a/b, a%b);
    }   

      function h(uint a) public view returns(uint, uint){
          return (a**2, a**3);
    }  

}