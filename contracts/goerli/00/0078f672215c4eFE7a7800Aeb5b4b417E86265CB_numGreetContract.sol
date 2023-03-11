//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract numGreetContract{
    
    uint256 num;
    string greet;

    struct numGreet{
        uint256 number;
        string greeting;
    }
    constructor(uint256 number, string memory greeting){
        num = number;
        greet = greeting;

    }

    function greetWithNum() public view returns(numGreet memory){
        return numGreet({
            number: num,
            greeting: greet
        });
    }
}