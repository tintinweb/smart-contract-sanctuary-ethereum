/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract TT1 {
    /** Custom errors **/
    error InvalidArgument();
    error FailedToSendEther();
    error Unauthorized();


    function runA() external {
        revert Unauthorized();
    }

    function runB() external {
        require(1 == 2, "You are Unauthorized!!");
    }
}