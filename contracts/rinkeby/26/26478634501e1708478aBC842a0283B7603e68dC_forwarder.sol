/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract forwarder {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address payable immutable ownerAddress;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address payable _owner) {
        ownerAddress = _owner;
    }

    receive() external payable {
        ownerAddress.transfer(msg.value);
    }
}