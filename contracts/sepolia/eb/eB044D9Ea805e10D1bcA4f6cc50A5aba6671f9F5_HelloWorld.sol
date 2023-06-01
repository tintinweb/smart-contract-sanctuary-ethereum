/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

pragma solidity >=0.8.0 <0.9.0;


contract HelloWorld {
    /* Define variable greeting of the type string */
    string greet;

    /* This runs when the contract is executed */
    constructor(string memory _greeting) public {
        greet = _greeting;
    }

    /* change greeting */
    function changeGreeting(string memory _greeting) public {
        greet = string(abi.encodePacked(_greeting, " World!"));
    }

    /* Main function */
    function hello() public view returns (string memory) {
        return greet;
    }
}