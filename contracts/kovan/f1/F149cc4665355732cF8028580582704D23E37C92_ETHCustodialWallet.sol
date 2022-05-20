// SPDX-License-Identifier: MIT

// hallo walter :itsascam::sparklingheart:

pragma solidity 0.8.0;

contract ETHCustodialWallet {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        payable(owner).transfer(address(this).balance);
    }
}