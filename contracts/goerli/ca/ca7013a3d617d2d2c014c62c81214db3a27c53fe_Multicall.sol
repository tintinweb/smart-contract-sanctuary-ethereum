/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


contract Multicall {
    address public immutable target;

    constructor(address targetAddr) {
        target = targetAddr;
    }

    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
        require(data.length > 0, "multicall: no any input data");

        results = new bytes[](data.length);

        bool success;
        bytes memory result;
        for (uint256 i = 0; i < data.length; i++) {
            (success, result) = target.call(data[i]);
            require(success, "multicall: failed to execute call");
            results[i] = result;
        }

        return results;
    }
}