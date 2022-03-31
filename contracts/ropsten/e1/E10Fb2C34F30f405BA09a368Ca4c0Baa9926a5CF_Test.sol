pragma solidity ^0.5.8;

contract Test {
    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    function hello() public view returns(string memory) {
        return "test";
    }
}