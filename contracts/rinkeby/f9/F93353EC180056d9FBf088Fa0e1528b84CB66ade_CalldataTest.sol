// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8;

contract CalldataTest {
    function execute(
        bytes calldata _data
    ) external pure returns (bytes4 response) {
        bytes4 selector;
        assembly {
            selector := calldataload(_data.offset)
        }

        return selector;
    }

    fallback(bytes calldata) external returns (bytes memory output) {
        return msg.data;
    }
}