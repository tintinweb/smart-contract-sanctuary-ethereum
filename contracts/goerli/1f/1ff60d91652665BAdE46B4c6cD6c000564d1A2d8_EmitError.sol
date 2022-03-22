/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.13;

contract EmitError {
    error ShouldBeVisible();

    fallback() external {
        revert ShouldBeVisible();
    }
}