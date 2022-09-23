/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract BB {

    uint a;
    uint b;
    string c = "yespizza";
    string d = "nopizza";

    function yesPizza() public returns (string memory,uint) {
     a = a + 1; 
    return (c ,a);
    }
    
    function noPizza() public returns (string memory,uint) {
    b = b + 1;
    return (d,b);
    }

}