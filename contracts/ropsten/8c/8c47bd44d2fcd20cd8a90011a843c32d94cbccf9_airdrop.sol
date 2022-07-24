/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract airdrop {


function transfer_To_Multi_Wallet(address[] memory _user) external payable {        
    for (uint256 i = 0; i < _user.length; i++) {
        address wallet = _user[i];
        uint256 amount = msg.value;
        payable(wallet).transfer(amount);
    }
}
}