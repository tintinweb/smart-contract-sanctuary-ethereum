//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*
   * Hello, you need to set isSolved as `true`
   * For getting kovan ETH tokens you can use https://ethdrop.dev
   * It's easy!
*/
contract RevTask {
    bool public isSolved = false;
    address private implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function setSolved() external {
        require(msg.sender == implementation, "RT: bad auth");

        isSolved = true;
    }

}