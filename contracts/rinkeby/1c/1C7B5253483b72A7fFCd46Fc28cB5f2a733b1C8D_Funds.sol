/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Funds {

    address payable walletOliver;
    address payable walletGeronimo;

    constructor(address payable _walletOliver, address payable _walletGeronimo) {
        walletOliver = _walletOliver;
        walletGeronimo = _walletGeronimo;
    }

    receive() external payable {
        uint256 amount = msg.value / 2;
        walletOliver.transfer(amount);
        walletGeronimo.transfer(amount);
    }
    
}