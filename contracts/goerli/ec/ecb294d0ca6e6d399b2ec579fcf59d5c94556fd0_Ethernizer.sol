/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: Steal this
pragma solidity 0.8.17;

contract Ethernizer {
    // header is the file file type, data is the file hex serialized
    event Ethernize(bytes32 header, bytes data);

    function ethernize(bytes32 header, bytes calldata data) external {
        emit Ethernize(header, data);
    }

    fallback() external {
        emit Ethernize("null", msg.data);
    }
}