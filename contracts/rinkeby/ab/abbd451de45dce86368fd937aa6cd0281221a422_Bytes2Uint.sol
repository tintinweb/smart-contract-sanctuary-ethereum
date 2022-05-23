// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;

contract Bytes2Uint {
    function calculate(bytes32 inputBytes) public pure returns (uint256 id) {
        return uint256(inputBytes);
    }
}