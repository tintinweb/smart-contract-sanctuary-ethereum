// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;
import "./BEther.sol";
contract Maximillion {
    BEther public bEther;
    constructor(BEther bEther_) public {
        bEther = bEther_;
    }
    function repayBehalf(address borrower) public payable {
        repayBehalfExplicit(borrower, bEther);
    }
    function repayBehalfExplicit(address borrower, BEther bEther_) public payable {
        uint received = msg.value;
        uint borrows = bEther_.borrowBalanceCurrent(borrower);
        if (received > borrows) {
            bEther_.repayBorrowBehalf.value(borrows)(borrower);
            msg.sender.transfer(received - borrows);
        } else {
            bEther_.repayBorrowBehalf.value(received)(borrower);
        }
    }
}