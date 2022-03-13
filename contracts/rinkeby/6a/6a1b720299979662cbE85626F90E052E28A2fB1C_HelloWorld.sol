/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {

    string greeting;
    constructor(string memory _greeting){
        greeting = _greeting;
    }

    function setGreeting (string memory _greeting) public {
        greeting = _greeting;
    }

    function getGreeting () public view returns(string memory){
        return greeting;
    }
}