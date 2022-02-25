/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

pragma solidity 0.6.12;


interface NativeMarketTokenInterface {
    function borrowBalanceCurrent(address account) external virtual returns (uint256);
    function repayBorrowBehalf(address borrower) external payable ;
}

contract NativeMarketTokenMaxRepay {

    NativeMarketTokenInterface public mativeMarketToken;

    constructor(NativeMarketTokenInterface mativeMarketToken_) public {
        mativeMarketToken = mativeMarketToken_;
    }

    function repayBehalf(address borrower) public payable {
        repayBehalfExplicit(borrower, mativeMarketToken);
    }

    function repayBehalfExplicit(address borrower, NativeMarketTokenInterface mativeMarketToken_) public payable {
        uint received = msg.value;
        uint borrows = mativeMarketToken_.borrowBalanceCurrent(borrower);
        if (received > borrows) {
            mativeMarketToken_.repayBorrowBehalf.value(borrows)(borrower);
            msg.sender.transfer(received - borrows);
        } else {
            mativeMarketToken_.repayBorrowBehalf.value(received)(borrower);
        }
    }
}