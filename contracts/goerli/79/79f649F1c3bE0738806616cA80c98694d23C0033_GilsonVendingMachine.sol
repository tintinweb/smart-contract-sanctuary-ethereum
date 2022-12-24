/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract GilsonVendingMachine {
    // Declare state variables of the contract
    address payable public owner;
    mapping (address => uint) public cupcakeBalances;

    struct Purchasing {
        address buyer;
        uint amount;
    }

    uint private cupcakePrice;
    Purchasing[] public purchasingList;



    // When 'VendingMachine' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the deployed smart contract's cupcake balance to 100
    constructor() {
        owner = payable(msg.sender);
        cupcakeBalances[address(this)] = 100;
        cupcakePrice = 1 gwei;
    }

    //1. Alterar o contrato para usar um modificador "onlyOwner" para substituir a verificação
    //require na operação refill.
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can refill.");
        _;
    }

    // Allow the owner to increase the smart contract's cupcake balance
    function refill(uint amount) public onlyOwner{
        cupcakeBalances[address(this)] += amount;
    }

    // Allow anyone to purchase cupcakes
    function purchase(uint amount) public payable {
        require(msg.value >= amount * cupcakePrice, "You must pay at least 1 ETH per cupcake");
        require(cupcakeBalances[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");
        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;
        purchasingList.push(Purchasing({
            buyer: msg.sender, 
            amount: msg.value 
        }));
    }

    // 2. Criar a função setPrice para permitir que o dono do contrato informe preço (em Gwei:
    //1 ETH = 109 Gwei) para os cupcakes. Criar a função getPrice para retornar o preço dos
    //cupcakes.
    function setPrice(uint price) public onlyOwner {
        cupcakePrice = price;
    }

    function getPrice() public view returns (uint) {
        return cupcakePrice;
    }

    //3. Criar a função getVendingMachineCupcakeBalance para retornar o total de
    //cupcakes disponíveis na máquina de vendas.
    function getVendingMachineCupcakeBalance() public view returns (uint) {
        return cupcakeBalances[address(this)];
    }


    //4. Criar a função getVendingMachineEtherBalance para retornar o total de dinheiro
    //(Ether) disponível na máquina de vendas.
    //a. Dica: O saldo (balanço) em ether do contrato pode ser obtido com
    //address(this).balance
    function getVendingMachineEtherBalance() public view onlyOwner returns (uint) {
        return address(this).balance;
    }


    //5. Criar a função withdraw para permitir o resgate do Ether disponível na máquina de
    //vendas para o dono da máquina. Essa função irá transferir o Ether do endereço do
    //contrato da máquina para o endereço do dono.
    //a. Dica: a transferência de Ether do contrato para uma conta (endereço) destino
    //pode ser realizada com destino.transfer(valor)
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    //6. Criar a função getBuyers que irá retornar os endereços dos compradores de cupcakes
    //e as respectivas quantidades compradas.
    function getBuyers() public view onlyOwner returns (Purchasing[] memory) {
        return purchasingList;
    }
}