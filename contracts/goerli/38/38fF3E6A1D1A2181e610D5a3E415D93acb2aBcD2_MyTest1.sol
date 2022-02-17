// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

contract MyTest1 {

    uint public myUint;
    uint public myUintDeployer;
    address public deployer;

    function setMyUint(uint _myUint) public {
        myUint = _myUint;
    }

    function setMyUintDeployer(uint _myUint) public {
        require(msg.sender == deployer);
        myUintDeployer = _myUint;
    }

    constructor() {
        deployer = msg.sender;
    }

}