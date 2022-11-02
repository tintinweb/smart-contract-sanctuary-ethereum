/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract SmartBatchTransfer {

    error CostPerTransferExceeded(uint256 index);

    function batchTransfer(address payable[] calldata accounts, uint256[] calldata amounts, uint256 costPerTransfer) external payable {
        for (uint256 i; i < accounts.length; ++i) {
            uint256 startingGasLeft = gasleft();

            accounts[i].transfer(amounts[i]);

            if (startingGasLeft - gasleft() > costPerTransfer) revert CostPerTransferExceeded(i);
        }

        uint256 balance = address(this).balance;

        if (balance == 0) return;

        payable(msg.sender).transfer(balance);
    }

}