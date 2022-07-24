pragma solidity ^0.8.0;

//SPDX-License-Identifier: Unlicense


/*
   * Hello, you need to set isSolved as `true`
   * For getting ETH tokens you can use:
   * - https://goerlifaucet.com
*/
contract RevTask {
    bool public isSolved = false;
    address public implementation;

    // block
    uint256 public generatedTs = 1658482284514;
    // end

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function setSolved() external {
        require(msg.sender == implementation, "RT: bad auth");

        isSolved = true;
    }

}