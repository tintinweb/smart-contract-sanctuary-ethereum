/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract FirstClass {

    string strInsa = "KKumiG>> Hello World..^^!! ";

    function myfunction() public view returns(string memory){
        return strInsa;
    }

    function myFunction2(string memory localInsa) public{
        strInsa = string.concat(strInsa, localInsa);
    }
}