/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract MEVBriber {
    bool internal lock = false;

    function burnGas() public payable {
        require(!lock);
        lock = true;
        block.coinbase.transfer(msg.value);
        lock = false;
    }
}