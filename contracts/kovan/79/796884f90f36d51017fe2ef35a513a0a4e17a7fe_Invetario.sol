/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

// Cofre, que o dono define quem é a pessoa que pode sacar, e em qual data.
 

contract Invetario  {

    uint256 public dataDeSaque;
    address payable public herdeiro;
    address public dono;

    constructor(uint data, address payable _herdeiro) {
        dataDeSaque = data;
        herdeiro = _herdeiro;
        dono = msg.sender;
    }

    function deposito() public payable {
    }

    function saque(uint256 valor) public payable {
        require(msg.sender == herdeiro,  "vc nao eh o herdeiro");
        require(block.timestamp > dataDeSaque, "ainda nao esta na hora do saque");
        require(valor < saldo(), "valor nao suficiente");

        herdeiro.transfer(valor);
    }

    function saldo() public view returns(uint) {
        return address(this).balance;
    }

    function blocoAtual() public view returns(uint) {
        return block.timestamp;
    }

}