/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.8.0;

contract Pay {

    event ReceiveETH(address sender, uint256 amount);

    function pay() external payable {
        require(msg.value>0,'zero ether');
        emit ReceiveETH(msg.sender, msg.value);
    }

    receive() external payable {
        emit ReceiveETH(msg.sender, msg.value);
    }
}