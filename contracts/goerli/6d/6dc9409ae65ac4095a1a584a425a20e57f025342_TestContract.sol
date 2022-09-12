/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract TestContract {

    uint256 public totalTests = 0;

    function revertString(bool test) external {
        if (test) {
            totalTests++;
            revert("Revert string.");
        }
    }

    function revertFunction1(bool test) external {
        if (test) {
            totalTests++;
            revert RevertFunction1();
        }
    }

    function revertFunction2(bool test) external {
        if (test) {
            totalTests++;
            revert RevertFunction2(address(this), block.timestamp, totalTests);
        }
    }

}

/// @notice This is the notice message #1.
/// @dev This is the dev message #1.
error RevertFunction1();

/// @notice This is the notice message #2.
/// @dev This is the dev message #2.
error RevertFunction2(address account, uint256 timestamp, uint256 totalTests);