//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract HellowWorld {
    string private greeting;
    uint256 public immutable imutavel;
    error UnevitactableError();

    constructor(string memory _greeting) {
        greeting = _greeting;
        imutavel = 10;
    }

    function hello() public view returns (string memory) {
        return greeting;
    }

    function setHello(string memory _greeting) public {
        greeting = _greeting;
    }

    function testFailRequire() external {
        for (uint256 i = 0; i < 100; i++) {
            greeting = "consome gas";
        }
        require(false);
    }

    function testFailRevert() external {
        for (uint256 i = 0; i < 100; i++) {
            greeting = "consome gas";
        }
        revert UnevitactableError();
    }

    function testFailAssert() external {
        for (uint256 i = 0; i < 100; i++) {
            greeting = "consome gas";
        }
        assert(false);
    }
}