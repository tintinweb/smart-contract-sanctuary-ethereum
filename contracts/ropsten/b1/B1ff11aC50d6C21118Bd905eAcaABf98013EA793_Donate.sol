/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract Donate {

    uint256 totalDonatedAmount;

    function donate() public payable {
        totalDonatedAmount += msg.value;
    }

    function getTotalDonatedAmount() public view returns(uint256) {
        return(totalDonatedAmount);
    }

}