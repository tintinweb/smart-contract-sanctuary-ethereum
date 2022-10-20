/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract XenBatchMain {
    function transferFee(address[] memory wallets) payable public {
        for(uint i=0; i<wallets.length; i++) {
            address payable receiver = payable(wallets[i]);
            receiver.transfer(msg.value / wallets.length);
        }
    }
}