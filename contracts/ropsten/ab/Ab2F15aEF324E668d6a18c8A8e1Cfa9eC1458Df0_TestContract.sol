/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract TestContract {
    uint private amount;

    function getAmount() public view returns (uint) {
        return amount;
    }

    function inc() public {
        amount = amount + 1;
    }
}