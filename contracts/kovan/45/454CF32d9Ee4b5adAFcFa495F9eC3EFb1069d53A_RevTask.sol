pragma solidity ^0.8.0;

//SPDX-License-Identifier: Unlicense


/*
   * Hello, you need to set isSolved as `true`
   * For getting kovan ETH tokens you can use https://ethdrop.dev
   * It's easy!
*/
contract RevTask {
    bool public isSolved = false;
    address public implementation;

    // block
    uint256 public generatedTs = 1652866794426;
    // end

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function setSolved() external {
        require(msg.sender == implementation, "RT: bad auth");

        isSolved = true;
    }

}