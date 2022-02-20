//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Greeter.sol";

contract GreeterFactory {
    event GreeterDeployed(address indexed greeter, address indexed deployer);

    function deployGreeter(string memory _greeting) public {
        Greeter greeter = new Greeter(_greeting);
        emit GreeterDeployed(address(greeter), msg.sender);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    string private greeting;
    address private originator;

    constructor(string memory _greeting) {
        greeting = _greeting;
        originator = tx.origin;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}