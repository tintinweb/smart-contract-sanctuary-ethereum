/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    uint256 private greeting;

    function setCollateralRequired() public {
        greeting = 1;
    }

    function destruct() public {
        selfdestruct(payable(0));
    }
}