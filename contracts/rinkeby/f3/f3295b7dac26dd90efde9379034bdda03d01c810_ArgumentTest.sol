/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract ArgumentTest {

    event Received(uint256 argumentType, bytes data);

    function testMemory(bytes memory _data) external {
        emit Received(1, _data);
    }

    function testCalldata(bytes calldata _data) external {
        emit Received(2, _data);
    }

}