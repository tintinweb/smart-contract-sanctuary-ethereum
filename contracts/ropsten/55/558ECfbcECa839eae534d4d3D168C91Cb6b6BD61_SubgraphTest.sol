//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SubgraphTest {
    event Something(string state);

    string public state;

    function doSomething() external {
        state = "before";
        emit Something(state);
        state = "after";
    } 
}