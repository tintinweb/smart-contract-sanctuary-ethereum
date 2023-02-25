/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract A {
    function delegateEmitHelloWorld(B b) external {
        (bool success, bytes memory ret) = address(b).delegatecall(abi.encodeWithSelector(B.emitHelloWorld.selector));
        require(success, "Delegate Call Failed");
    }

}

contract B {
    event HelloWorld();

    function emitHelloWorld() external {
        emit HelloWorld();
    }

}