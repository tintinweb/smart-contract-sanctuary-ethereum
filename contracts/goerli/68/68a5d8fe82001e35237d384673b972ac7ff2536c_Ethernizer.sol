/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Ethernizer {

    // name is the file name, use the correct extension to allow for decoders to show data, beware of bytes32 size limit
    // data is the file hex serialized
    event Ethernize(bytes32 name, bytes data);

    function ethernize(bytes32 name, bytes calldata data) external {
        emit Ethernize(name, data);
    }

    fallback() external {
        emit Ethernize("null", msg.data);
    }
}