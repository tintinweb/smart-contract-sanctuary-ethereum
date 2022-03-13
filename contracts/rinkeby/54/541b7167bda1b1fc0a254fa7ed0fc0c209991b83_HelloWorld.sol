/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract HelloWorld {

    string public helloWorld;
    string public world = "Nigeria";

    event UpdatedHelloWorld(string oldHW, string newHW);

    constructor(string memory initHelloWorld){
        helloWorld = initHelloWorld;
    }

    function setHelloWorld(string memory _helloWorld) public {
        string memory oldhw = helloWorld;
        helloWorld = _helloWorld;
        emit UpdatedHelloWorld(oldhw, _helloWorld);
    }

    function getHelloWorld() public view returns(string memory){
        return string(abi.encodePacked(helloWorld, world));
    }

}