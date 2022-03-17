/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Balance {

  uint256 private balanceAccount = (address(this)).balance;

    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function balance() public view returns (uint256){
        return balanceAccount;
    }
}