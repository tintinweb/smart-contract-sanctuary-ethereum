// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract SimpleToContract {
    event testEvent(address indexed from, uint256 testUint256);

    function testFunc(uint256 testUint256) external returns (uint256) {
        emit testEvent(msg.sender, testUint256);
        return testUint256;
    }
}