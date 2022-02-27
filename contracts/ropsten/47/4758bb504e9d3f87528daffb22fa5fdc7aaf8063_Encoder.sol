/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Encoder {
    function encode(uint256 _number) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_number));
    }
}