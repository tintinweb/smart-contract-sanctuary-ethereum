/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

pragma solidity ^0.6.0;

contract Mixer {

    // Define as variáveis do contrato
    address payable public owner;
    uint256 public fee;
    mapping (address => uint256) public balances;

    // Construtor do contrato
    constructor() public {
        owner = msg.sender;
        fee = 0.1 * 1e18; // Define a taxa de mistura em 10%
    }

    // Função para depositar ether no mixer
    function deposit() public payable {
        require(msg.value > 0, "Valor do depósito deve ser maior que zero");
        balances[msg.sender] += msg.value;
    }

    // Função para retirar ether do mixer
    function withdraw(uint256 _amount) public {
        require(_amount > 0, "Valor da retirada deve ser maior que zero");
        require(_amount <= balances[msg.sender], "Saldo insuficiente");

        // Calcula o valor da retirada com a taxa de mistura
        uint256 withdrawalAmount = _amount * (1 - fee / 1e18);

        // Envia a quantia retirada para o endereço do remetente
        msg.sender.transfer(withdrawalAmount);

        // Atualiza o saldo do remetente
        balances[msg.sender] -= _amount;
    }
}