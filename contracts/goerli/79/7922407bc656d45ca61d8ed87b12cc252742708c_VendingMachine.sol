/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract VendingMachine {
    address payable public dono;
    address payable public destino;
    address payable public comprador;
    mapping (address => uint) public saldoCupcake;
    uint256 public preco;

    // Quando o contrato 'VendingMachine' é implantado:
    // 1. defina o endereço de implantação como o proprietário do contrato
    // 2. defina o saldo de cupcake do contrato inteligente implantado para 100
    constructor() {
        dono = payable(msg.sender);
        saldoCupcake[address(this)] = 100;
        
    }

    // modificador para verificar se é o dono
    modifier somenteDono() {
        require(msg.sender == dono, "Somente o dono pode reabastecer a maquina!");
        _;
    }

    // Permitir que o proprietário aumente o saldo do cupcake do contrato inteligente
    function refill(uint amount) public somenteDono() {
        saldoCupcake[address(this)] += amount;
    }

    //Altera o preco do kupcake
    function alterarPreco(uint256 value) public somenteDono() {
        VendingMachine.preco = value;
    }

    //Busca do preço do kupcake
    function obterPreco() public view 
        returns (uint256 valor)
    {
        valor = VendingMachine.preco;
    }

    //Retorna o balanco de kupcakes vendidos
    function obterSaldoCupcake() public view 
        returns (int cupcakes)
        {
            cupcakes = int(saldoCupcake[address(this)]);
        }

    function obterSaldoEther() public view 
        returns (int cupcakesSending)
        {
            cupcakesSending = int(address(this).balance);
        }

    function retirada(uint256 valorTrans) public somenteDono(){
         destino.transfer(valorTrans);
    }

        function obterCompradores() public {
        comprador.transfer(uint256(preco));
    }

    // Permitir que qualquer pessoa compre cupcakes
    function comprar(uint amount) public payable {
        require(msg.value >= amount * 1 ether, "Voce deve pagar pelo menos 1 ETH por cupcake");
        require(saldoCupcake[address(this)] >= amount, "Cupcakes insuficientes no estoque!");
        saldoCupcake[address(this)] -= amount;
        saldoCupcake[msg.sender] += amount;
    }
}