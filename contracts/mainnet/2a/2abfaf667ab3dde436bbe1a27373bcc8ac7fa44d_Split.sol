// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// This is a payment splitter for team payouts

import "./PaymentSplitter.sol";

contract Split is PaymentSplitter {

    address[] private _Payees = [0x67935A1b7E18D16d55f9Cc3638Cc612aBf3ff800, 0x9FcFD77494a0696618Fab4568ff11aCB0F0e5d9C, 0x1380c8aa439AAFf8CEf5186350ce6b08a6062E90, 0xa4D89eb5388613A9BF7ED0eaFf5fD2c05a4B34e3];
    uint256[] private _Shares = [500, 166, 166, 167];

    constructor() PaymentSplitter(_Payees, _Shares) payable {
    }
}