//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



contract Greeter {
    string private greeting;
    string public lanuauge_;

    constructor(string memory _greeting, string memory lanuauge) {
        greeting = _greeting;
        lanuauge = lanuauge_;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }


}