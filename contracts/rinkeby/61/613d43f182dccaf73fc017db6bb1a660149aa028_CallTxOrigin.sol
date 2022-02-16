/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

contract CallTxOrigin {
    event WhichAddress(string name, address addr);

    function emitEvents() public returns(address, address) {
        emit WhichAddress("msgsender", msg.sender);
        emit WhichAddress("txorigin", tx.origin);

        return (msg.sender, tx.origin);
    }
}