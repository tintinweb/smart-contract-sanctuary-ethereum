/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract MultiSenderETH {
    function sendMultiETH(address[] memory listReceivers)
        public
        payable
        returns (bool)
    {
        uint256 totalReceivers = listReceivers.length;
        require(
            msg.sender.balance >= totalReceivers * msg.value,
            "Total balance not enough"
        );

        for (uint256 i = 0; i < totalReceivers; i++) {
            payable(listReceivers[i]).transfer(msg.value);
        }
        return true;
    }
}