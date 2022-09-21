pragma solidity 0.8.17;

contract Greeter {
    string greet;

    constructor(string memory _greet) public {
        greet = _greet;
    } 

    function greetings(string memory name) public view returns (string memory) {
        return string(abi.encodePacked(greet, name));
    }
}