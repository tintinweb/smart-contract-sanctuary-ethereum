/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract D{
    
   

    function a1(uint a) public view returns(uint){
        
        return a*a;
    }

    function a2(uint a) public view returns(uint){
        
        return a*a*a;
    }

    function a3(uint a,uint b) public view returns(uint){
        
        return a/b;
    }
    function a4(uint a,uint b) public view returns(uint){
        
        return a%b;
    }
}