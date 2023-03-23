// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ICrossChainFilter.sol";

contract Callee is ICrossChainFilter{
    uint256 public sum = 0;

    function add(uint256 _value) external {
        sum = sum + _value;
    }

    function cross_chain_filter(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address sourceAccount,
        bytes calldata payload
    ) external view returns (bool) {
        return true;
    }

}