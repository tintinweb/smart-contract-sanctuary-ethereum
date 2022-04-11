// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Demo {
    address public owner;
    string greet;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
    
    }

    function setGreet(string memory _greet) public {
        greet = _greet;
    }

    function getGreet() public view returns(string memory) {
        return greet;
    }

    modifier requireOwner() {
        require(owner == msg.sender, "Not an owner");
        _;
    }

    function withdrawTo(address payable _to) public requireOwner {
        _to.transfer(address(this).balance);
    }
}