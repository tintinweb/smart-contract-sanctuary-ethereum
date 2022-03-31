// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


contract Greeting {
    string public name = 'wappist';

    constructor() {
    }

    /** Set the name 
    * @param newName the name to greet
    */
    function setName(string memory newName) public {
        name = newName;
    }

    /** Greeting function 
    */
    function getGreeting() public view returns(string memory) {
        return string(abi.encodePacked('Hello ', name));
    }

}