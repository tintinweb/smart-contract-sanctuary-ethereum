/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract MyContract {
    string public hello;
    
    constructor(){
        hello = "Hola mundo!";
    }
    
    function setHello(string memory _hello) public {
        hello = _hello;
    }
}