// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract AFacet {
    function name() external view returns (address) {
        return msg.sender;
    }
}