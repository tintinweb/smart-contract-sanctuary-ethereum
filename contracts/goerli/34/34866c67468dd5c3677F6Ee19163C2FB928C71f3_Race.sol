/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: GPL3.0

pragma solidity 0.8.17;

contract Race {
    bool public storedVar;
    address public immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function flipStoredVar(bool oldValue) external payable {
        bool localVar = storedVar;
        require(localVar == oldValue);
        storedVar = !localVar;
        block.coinbase.transfer(msg.value);
    }

    function withdraw() external {
        (bool success,) = owner.call{value: address(this).balance}("");
        success = false;
    }
}