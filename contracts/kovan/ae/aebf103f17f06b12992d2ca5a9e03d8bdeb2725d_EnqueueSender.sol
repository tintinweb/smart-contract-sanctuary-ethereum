/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

interface ICTC {
    function enqueue(address target, uint gasLimit, bytes memory data) external;
}

contract EnqueueSender {

    event Called(address sender, address origin);

    fallback() external payable {
        emit Called(msg.sender, tx.origin);
    }

    function enqueue(address ctc, address target, uint gasLimit, bytes memory data) external {
        ICTC(ctc).enqueue(target, gasLimit, data);
    }
}