/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

pragma solidity ^0.5.0;

contract Mixer {
    address payable public owner;
    mapping (address => uint) public deposited;
    mapping (address => uint) public withdrawals;
    constructor() public {
        owner = msg.sender;
    }
    // Função para depositar ETH
    function deposit() public payable {
        deposited[msg.sender] += msg.value;
    }
    // Função para retirar ETH 
    function withdraw(uint amount) public {
        require(deposited[msg.sender] >= amount);
        withdrawals[msg.sender] += amount;
        msg.sender.transfer(amount);
    }
    // Função para o proprietário do contrato retirar todos os fundos
    function withdrawAll() public {
        uint amount = deposited[owner];
        require(amount > 0);
        withdrawals[owner] += amount;
        owner.transfer(amount);
   }
    // Função para destruir o contrato
    function destroy() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}