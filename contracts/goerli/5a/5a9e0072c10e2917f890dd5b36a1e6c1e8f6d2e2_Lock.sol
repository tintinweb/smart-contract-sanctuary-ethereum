/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Lock {
    string public text = "text";

    error CustomError();

    function functionWhichWillRevert() external {
        revert CustomError();
    }

}