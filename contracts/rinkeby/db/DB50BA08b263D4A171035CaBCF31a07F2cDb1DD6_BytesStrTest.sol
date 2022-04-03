/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract BytesStrTest {
    bytes public bytesValue;
    string public stringValue;

    function setBytes(bytes calldata _bytes) external {
        bytesValue = _bytes;
    }

    function setString(string calldata _str) external {
        stringValue = _str;
    }
}