/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Transactions {
    function depositContract() public payable returns (bool) {
        require(msg.value >= 1 ether, "Depositos nao podem ser menores que 1 ETH");

        return true;
    }

    function withdrawContractToSender(uint _amount) public returns (bool) {
        require(_amount >= 1 ether, "Saque minimo deve ser de 1 ETH");
        require(address(this).balance >= _amount, "Saldo insuficiente para saque");

        return payable(msg.sender).send(_amount);
    }

    function withdrawContractToSpecificAddress(uint _amount, address payable _to) public returns (bool) {
        require(_amount >= 1 ether, "Saque minimo deve ser de 1 ETH");
        require(address(this).balance >= _amount, "Saldo insuficiente para saque");

        return _to.send(_amount);
    }

    function balanceContract() public view returns (uint) {
        return address(this).balance;
    }

    function balanceAccount() public view returns (uint) {
        return address(msg.sender).balance;
    }
}