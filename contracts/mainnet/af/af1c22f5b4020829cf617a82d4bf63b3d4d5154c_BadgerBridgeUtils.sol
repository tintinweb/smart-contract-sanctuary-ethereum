/**
 *Submitted for verification at Etherscan.io on 2022-03-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract BadgerBridgeUtils {
    /// @dev Helper function to encode parameters for recovering TX
    function encodeUserParams(
        // user args
        address _token, // either renBTC or wBTC
        uint256 _slippage,
        address _user,
        address _vault
    ) external pure returns (bytes memory encoded, bytes32 hashed) {
        encoded = abi.encode(_token, _slippage, _user, _vault);
        hashed = keccak256(encoded);
    }
}