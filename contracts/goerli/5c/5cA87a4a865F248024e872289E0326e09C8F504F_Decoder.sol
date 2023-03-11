// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Decoder {
    error DecodingCallFailed(address to, bytes data);

    function decode(
        address to,
        bytes memory data
    ) public returns (bytes memory) {
        (bool success, bytes memory result) = to.call(data);
        if (!success) revert DecodingCallFailed(to, data);
        return result;
    }
}