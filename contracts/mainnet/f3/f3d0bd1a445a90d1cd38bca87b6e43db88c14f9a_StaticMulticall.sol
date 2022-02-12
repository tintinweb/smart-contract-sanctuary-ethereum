/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

/// @title  StaticMulticall based on UniswapV3 Multicall at 0x5BA1e12693Dc8F9c48aAD8770482f4739bEeD696
/// @author Aleph Retamal <github.com/alephao>
/// @notice Modified (UniswapV3 Multicall).aggregate to be a `view` fn. 
///         Using staticcall instead of call and if it fails, return the error
contract StaticMulticall {  
    error CallError(bytes err);

    struct Call {
        address target;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    function aggregate(Call[] memory calls) external view returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.staticcall(calls[i].callData);
            if (!success) {
              revert CallError(ret);
            }
            returnData[i] = ret;
        }
    }
}