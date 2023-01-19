/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Test {
    event MyEvent(address, uint256, uint256);
    event MyEventIndexed(address indexed, uint256 indexed, uint256 );

    function emitEvent() external {
        emit MyEvent(address(this), 9, 17);
    }

    function emitEventIndexed() external {
        emit MyEventIndexed(address(this), 9, 17);
    }
}