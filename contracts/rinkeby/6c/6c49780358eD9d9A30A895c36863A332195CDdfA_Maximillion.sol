// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./Ether.sol";
contract Maximillion {
     Ether public cEther;
    constructor(Ether ether_) public {
        cEther = ether_;
    }
    function repayBehalf(address borrower) public payable {
        repayBehalfExplicit(borrower, cEther);
    }
    function repayBehalfExplicit(address borrower, Ether ether_) public payable {
        uint received = msg.value;
        uint borrows = ether_.borrowBalanceCurrent(borrower);
        if (received > borrows) {
            ether_.repayBorrowBehalf{value:received}(borrower);
            msg.sender.transfer(received - borrows);
        } else {
            ether_.repayBorrowBehalf{value:received}(borrower);
        }
    }
}