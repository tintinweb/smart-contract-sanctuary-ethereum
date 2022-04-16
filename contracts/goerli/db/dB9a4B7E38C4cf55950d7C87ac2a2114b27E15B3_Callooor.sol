/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

contract Callooor {

    address constant fDAI = 0x88271d333C72e51516B67f5567c728E702b3eeE8;


    function checkMeBalance() public view returns (uint256) {

        return IERC20(fDAI).balanceOf(msg.sender);

    }

}