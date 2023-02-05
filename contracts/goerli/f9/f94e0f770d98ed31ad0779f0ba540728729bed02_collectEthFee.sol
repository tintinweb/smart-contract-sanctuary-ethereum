/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

//This contract receives ETH from any wallet 
//then sends 30% of the amount to two wallets (15% to each)

contract collectEthFee {

    address payable public managementWallet; 
    address payable public treasuryWallet;

    event ethReceived(address _tokenSender, uint _tokenAmount);
    event ethSent(address _tokenSender, address _tokenReceiver, uint _tokenAmount);

    constructor (address payable _wallet1, address payable _wallet2) {

        managementWallet = _wallet1;
        treasuryWallet = _wallet2;

    }

    receive() payable external {

        uint256 _15percent = (msg.value)*15/100;
        managementWallet.transfer(_15percent);
        treasuryWallet.transfer(_15percent);

        emit ethReceived(msg.sender,msg.value);
        emit ethSent(address(this), address(managementWallet) , _15percent);
        emit ethSent(address(this), address(treasuryWallet) , _15percent);        
    }     

}