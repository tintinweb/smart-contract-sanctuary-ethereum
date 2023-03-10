// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract Test {
    event DeployedTest();
    event DestroyedTest(address sender);
    constructor(){
        emit DeployedTest();
    }

    function destroy(address payable to) external {
        emit DestroyedTest(msg.sender);
        selfdestruct(to);
    }
}