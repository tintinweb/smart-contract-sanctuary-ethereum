/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Spamer {
    constructor() {
    }
    event AddrChanged(bytes32 indexed node, address a);
    function addrs (uint n) external {
        for (uint i; i < n; i++) {
            emit AddrChanged(bytes32(0x1234567891234567+i), address(uint160(i)));
        }
    }
}