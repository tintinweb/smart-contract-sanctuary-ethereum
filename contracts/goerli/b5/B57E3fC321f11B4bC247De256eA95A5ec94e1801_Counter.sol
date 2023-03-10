// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    uint public counter;
    address public deployer;
    
    constructor() {
        deployer = msg.sender;
        counter = 0;
    }

    modifier onlyDeployer {
        require(msg.sender == deployer, "Only deployer");
        _;
    }

    function count() public onlyDeployer {
        counter = counter + 1;
    }
}