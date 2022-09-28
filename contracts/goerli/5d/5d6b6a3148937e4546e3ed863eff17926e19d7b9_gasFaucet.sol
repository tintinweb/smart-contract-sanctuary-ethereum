/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

error FaucetFailed(address recipient);

contract gasFaucet {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) external {
        owner = newOwner;
    }

    receive() external payable {}

    fallback() external payable {}

    function faucet(address payable recipient) external {
        bool sent = recipient.send(0.1 ether);
        if(!sent) {
            revert FaucetFailed(recipient);
        }
    }
}