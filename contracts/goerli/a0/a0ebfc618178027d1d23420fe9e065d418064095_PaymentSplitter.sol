/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// File: Multi_sender/multi_sender_token.sol

pragma solidity ^0.8.15;


contract PaymentSplitter  {
    address payable [] public recipients;
    event TransferReceived(address _from, uint _amount);
    

    ///При деплое контракта, вносим адреса
    constructor(address payable [] memory _addrs) {
        for(uint i=0; i<_addrs.length; i++){
            recipients.push(_addrs[i]);
        }
    }
    

    ///Как только поступают деньги на счёт контракта, они делятся кол-во адресов в массиве и отправляется на их счёт
    receive() payable external {
        uint256 share = msg.value / recipients.length; 

        for(uint i=0; i < recipients.length; i++){
            recipients[i].transfer(share);
        }    
        emit TransferReceived(msg.sender, msg.value);
    }

    ///Очистить массив, сделав его длину 0
    function clearMassive() external {
        recipients.length == 0;
    }

    ///Добавить в массив новые адреса
    function UpdateMassive(address payable [] memory _addrs) external {
        for(uint i=0; i<_addrs.length; i++){
            recipients.push(_addrs[i]);
        }
    }

}