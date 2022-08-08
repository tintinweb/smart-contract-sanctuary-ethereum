/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Counter {
    uint count;
    address constant multisig = 0x4a81FD7d3B2d3BAddf0e60aE697D6CCE80EE6A32; // gnosis test-goerli

    function increase() public onlyMultisig {
        count++;
    }

    function getCount() public view returns (uint) {
        return count;
    }

    modifier onlyMultisig() {
        require(msg.sender == multisig);
        _;
    }
}