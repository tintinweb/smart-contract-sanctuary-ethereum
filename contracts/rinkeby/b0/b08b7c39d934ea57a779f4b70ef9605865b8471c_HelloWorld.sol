/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;

// Modified Greeter contract. Based on example at https://www.ethereum.org/greeter.

contract Mortal {
    /* Define variable owner of the type address*/
    address owner;

    /* this function is executed at initialization and sets the owner of the contract */
    constructor () {owner = msg.sender;}

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    /* Function to recover the funds on the contract */
    function kill() onlyOwner public {selfdestruct(msg.sender);}
}

contract HelloWorld is Mortal {
    /* define variable greeting of the type string */
    string greet;

    /* this runs when the contract is executed */
    constructor (string memory _greet) {
        greet = _greet;
    }

    function newGreeting(string memory _greet) onlyOwner public {
        emit Modified(greet, _greet, greet, _greet);
        greet = _greet;
    }

    /* main function */
    function greeting() public view returns (string memory)  {
        return greet;
    }

    event Modified(
        string indexed oldGreetingIdx, string indexed newGreetingIdx,
        string oldGreeting, string newGreeting);
}