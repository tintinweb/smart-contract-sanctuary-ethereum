/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title SPex is a decentralized storage provider exchange space on FVM
/// @author Mingming Tang
contract Test11 {

    event EventRecivedMoney(uint256 amount);
    event EventCallFallBack(address sender, uint256 amount);

    fallback() external payable {
        emit EventCallFallBack(msg.sender, msg.value);
    }

    receive() external payable {
        emit EventRecivedMoney(msg.value);
    }

}