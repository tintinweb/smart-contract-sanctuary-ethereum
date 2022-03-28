/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// File contracts/Greeter.sol

// https://github.com/limcheekin/eth-dapps-nextjs-boiletplate/blob/master/contracts/Greeter.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// REF: https://github.com/ethereum/ethereum-org/blob/master/views/content/greeter.md

contract Mortal {
    /* Define variable owner of the type address */
    address owner;

    /* This constructor is executed at initialization and sets the owner of the contract */
    constructor() {
        owner = msg.sender;
    }

    /* Function to recover the funds on the contract */
    function kill() public {
        if (msg.sender == owner) selfdestruct(payable(msg.sender));
    }
}

contract Greeter is Mortal {
    string public greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    function greet(string memory name) public view returns (string memory) {
        return concat(greeting, name);
    }

    // REF: https://betterprogramming.pub/solidity-playing-with-strings-aca62d118ae5
    function concat(string memory s1, string memory s2)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(s1, s2));
    }
}