/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract HelloWorld {
    string public hello;

    constructor(string memory _hello) {
        hello = _hello;
    }

    function sayHello() public view returns (string memory) {
        return hello;
    }

    function setHello(string memory _hello) public {
        hello = _hello;
    }
}