/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
contract TransferToContract {
    error TransferError(address caller, uint amount);

    function hello() external payable {
        revert TransferError(msg.sender, 10000);
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

}