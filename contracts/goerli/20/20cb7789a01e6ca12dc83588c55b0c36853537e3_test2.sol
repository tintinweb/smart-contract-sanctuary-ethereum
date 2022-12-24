/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract test2 {
    uint public num;
    address public contracts;

    constructor(address ct) {
        contracts = ct;
    }

    modifier OnlyContract {
        require(msg.sender == contracts, "!!!");
        _;
    }

    function setNum(uint _num) external OnlyContract {
        num = _num;
    }
}