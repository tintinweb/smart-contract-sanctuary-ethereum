/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Token{

       string name;
       string symbol;

constructor(){
        name = "Hello";

        symbol = "HEL";
    }

    function getName() public view returns(string memory){
        return name;
    }
function getSymbol() public view returns(string memory){
        return symbol;
    }

}