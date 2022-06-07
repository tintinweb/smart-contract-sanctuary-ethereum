/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// My First Smart Contract 
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
contract HelloWorld {
    function get()public pure returns (string memory){
        return 'Hello Contracts';
    }
}