// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract Greeter {
    error BOBO();
    error Greeting_BOBO();
    error Number_BOBO();
    error Owner_BOBO(address send, address required);

    string public greeting;
    uint256 public number;

    address public owner;
    uint256 public count;

    constructor(string memory _greeting, uint256 _number) {
        if(bytes(_greeting).length == 0) revert Greeting_BOBO();
        if(_number == 0) revert Number_BOBO();
        greeting = _greeting;
        number = _number;
        owner = msg.sender;
    }

    function setGreeting(string memory _greeting) public {
        if(bytes(_greeting).length == 0) revert Greeting_BOBO();
        greeting = _greeting;
    }

    function setNumber(uint256 _number) public {
        if(_number == 0) revert Number_BOBO();
        number = _number;
    }

    function increase() public {
        if(msg.sender != owner) revert Owner_BOBO({
            send: msg.sender,
            required: owner
        });
        count++;
    }

    function bobo() public {
        revert BOBO();

        number = 0;
    }
}