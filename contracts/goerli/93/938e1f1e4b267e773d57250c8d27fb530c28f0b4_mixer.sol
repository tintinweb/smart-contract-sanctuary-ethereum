/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

pragma solidity ^0.6.0;

contract mixer {

    // define as variaveis do contrato
    address payable public owner;
    uint256 public fee;
    mapping (address => uint256) public balances;

    // construtor do contrato 
    constructor() public {
        owner = msg.sender;
        fee = 0.1 * 1e18; // define a taxa de mistura em 10%
    }

    // funcao para depositar ether no mixer
    function deposit () public payable {
        require(msg.value > 0, "valor do deposito deve ser maior que zero");
        balances[msg.sender] += msg.value;
    }

    // funcao para retirar ether do mixer
    function withdraw (uint256 _amount) public {
        require(_amount > 0, "valor da retirada deve ser maior que zero");
        require(_amount <- balances[msg.sender], "saldo insuficiente");

        // calcula o valor da retirada com a taxa de mistura
        uint256 withdrawa1amount = _amount * (1 - fee / 1e18);

        // envia a quantia retirada para o endereço do remetente
        msg.sender.transfer(withdrawa1amount);

        // atualiza o saldo do remetente
        balances[msg.sender] -= _amount;
    }
}