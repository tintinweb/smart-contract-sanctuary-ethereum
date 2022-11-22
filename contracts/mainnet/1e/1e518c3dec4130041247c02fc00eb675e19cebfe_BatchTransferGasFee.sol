/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract BatchTransferGasFee {
    function batchTransferToken(
        address token,
        uint256 amount,
        address[] memory _accounts
    ) public {
        for (uint256 index = 0; index < _accounts.length; index++) {
            IERC20(token).transferFrom(msg.sender, _accounts[index], amount);
        }
    }

    function batchTransferNative(uint256 _amount, address[] memory _accounts)
        public
        payable
    {
        require(msg.value != 0, "Insufficient");

        for (uint256 index = 0; index < _accounts.length; index++) {
            payable(_accounts[index]).transfer(_amount);
        }

        payable(msg.sender).transfer(address(this).balance);
    }
}