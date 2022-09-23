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
    uint e;
    uint f;
    string g = "yesHam";
    string h = "noHam";

    function yesPizza() public returns (string memory,uint) {
     a = a + 1; 
    return (c ,a);
    }
    
    function noPizza() public returns (string memory,uint) {
    b = b + 1;
    return (d,b);
    }

    function YesPizza() public view returns (string memory,uint) {
    return (c ,a);
    }

    function NoPizza() public view returns (string memory,uint) {
    return (d,b);
    }

       function yesHam() public returns (string memory,uint) {
     e = e + 1; 
    return (g ,e);
    }
    
    function noHam() public returns (string memory,uint) {
    f = f + 1;
    return (h,f);
    }

    function YesHam() public view returns (string memory,uint) {
    return (g ,e);
    }

    function NoHam() public view returns (string memory,uint) {
    return (h,f);
    }
}