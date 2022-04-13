/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IMultiSenderETH {
    function sendMultiETH(address[] memory listReceivers, uint256 amount)
        external
        returns (bool);
}

contract MultiSenderETH is IMultiSenderETH {
    function checkBl() public view returns (uint256) {
        return msg.sender.balance;
    }

    function transferETH(address to) public payable {
        payable(to).transfer(1);
    }

    function sendMultiETH(address[] memory listReceivers, uint256 amount)
        public
        override
        returns (bool)
    {
        uint256 totalReceivers = listReceivers.length;
        require(
            msg.sender.balance >= totalReceivers * amount,
            "Total balance not enough"
        );

        for (uint256 i = 0; i < totalReceivers; i++) {
            payable(listReceivers[i]).transfer(amount);
        }
        return true;
    }
}