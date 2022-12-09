//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.14;

contract TestBorrowEvent {
    event BorrowEvent(uint256 loanId, address borrower);

    uint256 public loanId = 0;

    function borrow() external {
        loanId++;
        emit BorrowEvent(loanId, msg.sender);
    }
}