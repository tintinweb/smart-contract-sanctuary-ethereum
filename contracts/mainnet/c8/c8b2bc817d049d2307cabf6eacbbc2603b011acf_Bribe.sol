/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
contract Bribe {
    function bribe() payable public {
        block.coinbase.transfer(msg.value);
    }
}