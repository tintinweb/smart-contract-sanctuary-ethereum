// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContractDemo {
    uint256 public index = 3;

}

contract ContractTest {
    address public addr;

    constructor() {
        ContractDemo demo;
        demo = new ContractDemo();
        addr = address(demo);
    }
}