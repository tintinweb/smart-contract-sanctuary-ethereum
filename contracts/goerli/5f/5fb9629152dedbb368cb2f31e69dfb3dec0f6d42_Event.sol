// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Event{

    uint doneDate;
    event Done(uint indexed);

    function emitAndRevert() external {
        emit Done(block.timestamp);

        doneDate = block.timestamp;
        revert();
    }

    function emitDone() external {
        emit Done(block.timestamp);

        doneDate = block.timestamp;
    }
}