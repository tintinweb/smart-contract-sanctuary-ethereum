/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract TestContract {

    error RevertFunction();

    function revertString() external {
        revert("RevertString");
    }

    function revertFunction() external {
        revert RevertFunction();
    }

}