// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// https://github.com/smartcontractkit/chainlink/blob/master/contracts/src/v0.8/

// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts

contract Lottery {
    string public s_name = "myContract";

    constructor() {}

    /* View/Pure functions  */

    function getName() public view returns (string memory) {
        return s_name;
    }
}