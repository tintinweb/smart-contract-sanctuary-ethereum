/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

/** License Identification is very important in open source software for license compliance 
*/

// SPDX-License-Identifier: MIT

/** Source files can (and should) be annotated with a version pragma to reject compilation with 
future compiler versions that might introduce incompatible changes.
*/
pragma solidity ^0.8.11;

/** Contracts in Solidity are similar to classes in object-oriented languages. They contain
    persistent data in state variables, and functions that can modify these variables. Calling
    a function on a different contract (instance) will perform an EVM function call and thus
    switch the context such that state variables in the calling contract are inaccessible.
    A contract and its functions need to be called for anything to happen.
*/

contract Greeting{
    string public name;
    string public greetingPrefix = "Hello ";

    constructor(string memory initialName){
        name = initialName;
    }

    function setName(string memory newName) public {
        name = newName;
    }

    function getGreeting() public view returns (string memory) {
        return string(abi.encodePacked(greetingPrefix, name));
    }

}