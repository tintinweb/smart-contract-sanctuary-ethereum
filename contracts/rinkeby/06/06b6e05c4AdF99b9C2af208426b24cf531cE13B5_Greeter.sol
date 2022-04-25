// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract Greeter {
    error BOBO();
    error Greeting_BOBO();
    error Number_BOBO();

    string private greeting;
    uint256 private number;

    constructor(string memory _greeting, uint256 _number) {
        if(bytes(_greeting).length == 0) revert Greeting_BOBO();
        if(_number == 0) revert Number_BOBO();
        greeting = _greeting;
        number = _number;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        if(bytes(_greeting).length == 0) revert Greeting_BOBO();
        greeting = _greeting;
    }

    function setNumber(uint256 _number) public {
        if(_number == 0) revert Number_BOBO();
        number = _number;
    }

    function bobo() public {
        revert BOBO();

        number = 0;
    }
}