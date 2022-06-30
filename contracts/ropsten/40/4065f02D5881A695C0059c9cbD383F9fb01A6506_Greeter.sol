//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Greeter {
    string private greeting;

    // float public ww; // no floating number in solidity native support
    // solhint-disable-next-line
    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    /// @return Documents the return variables of a contract’s function state variable
    function greet(uint256 ee) public view returns (string memory) {
        ee + 3;
        return greeting;
    }

    function wowow () public pure returns (string memory) {
        return "hey there";
    }
}