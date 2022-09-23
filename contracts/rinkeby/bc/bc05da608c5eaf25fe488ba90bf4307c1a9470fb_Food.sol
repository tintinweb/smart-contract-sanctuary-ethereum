/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract Food {
    uint a;
    uint b;
    uint c;
    uint d;
 

//write
    function pizzalike() public returns(uint) {
        a = a+1;
        return a;
    }
     function nopizza() public returns(uint) {
        b = b+1;
        return b;
    }
        function hamlike() public returns(uint) {
        c = c+1;
        return c;
    }
     function noham() public returns(uint) {
        d = d+1;
        return d;
    }
//view
    function pizzalikeadd() public view returns(uint) {
       
        return a;
    }
     function nopizzaadd() public view returns(uint) {
        
        return b;
    }
        function hamlikeadd() public view returns(uint) {
        
        return c;
    }
     function nohamadd() public view returns(uint) {
        
        return d;
    }


}