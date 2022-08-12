// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

error GreeterError();

contract Greeter {
    string public greeting;
    address public admin;

    constructor(string memory _greeting, address admin_) {
        greeting = _greeting;
        admin = admin_;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        require(msg.sender == admin, "only admin can set greeting");
        greeting = _greeting;
    }

    function setAdmin(address _admin) public {
        admin = _admin;
    }

    function throwError() external pure {
        revert GreeterError();
    }
}