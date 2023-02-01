// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title PendleMulticall - A more gas-efficient version of Multicall3
/// @author UncleGrandpa925 <[email protected]>
contract PendleMulticall {
    error MulticallFailed(uint256 index);

    struct Call {
        address target;
        bytes callData;
    }

    function aggregate(Call[] calldata calls) external payable {
        uint256 length = calls.length;
        Call calldata call;
        for (uint256 i = 0; i < length; ) {
            call = calls[i];
            (bool success, ) = call.target.call(call.callData);
            if (!success) revert MulticallFailed(i);
        unchecked {
            ++i;
        }
        }
    }
}