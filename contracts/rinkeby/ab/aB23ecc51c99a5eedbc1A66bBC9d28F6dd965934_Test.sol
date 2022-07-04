pragma solidity ^0.8.0;

contract Test {
    string private greet;

    constructor(string memory _greet) {
        greet = _greet;
    }

    function getGreet() public view returns (string memory) {
        return greet;
    }

    function setGreet(string memory _greet) external {
        greet = _greet;
    }
}