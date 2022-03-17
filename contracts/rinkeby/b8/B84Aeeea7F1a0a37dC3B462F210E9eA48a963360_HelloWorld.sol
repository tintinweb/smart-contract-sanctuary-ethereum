//BlockGames Zuri Task: Create a "Hello World" contract with a constructor, at least two functions, and a state variable, and deploy to a testnet (Rinkeby)

//SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

contract HelloWorld {
    string public greeting; //state variable

    //Constructor function
    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function setGreeting(string memory _BlockGamesTask2) public {
        greeting = _BlockGamesTask2;
    }

    function getGreeting() public view returns (string memory) {
        return greeting;
    }
}