/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: GPL-3.0

//Foi necessario mudar a versao para utilizar funcao de concatenar strings
pragma solidity 0.8.12;

contract VendingMachineCorp {
    // Declare state variables of the contract

    struct Product {
        string name;
        uint price;
        uint balance;
    }

    struct Purchase {
        address origin;
        string product;
        uint value;
    }

    Product[] public products;
    address[] public buyers;

    mapping (address => Purchase[]) public purchasing;

    address payable public owner;


    // When 'VendingMachine' contract is deployed
    constructor() payable {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() { 
        require(msg.sender == owner, "Only the owner can refill."); 
        _; 
    } 

    //Adicionar produtos a vending machine
    function addProduct (string memory name, uint price, uint balance) public onlyOwner() {
        products.push(Product({
            name: name,
            price: price,
            balance: balance
        }));
    }

    // Reabastecer produtos da vending machine
    function refill(uint amount, uint productIndex) public onlyOwner() {
        require (productIndex < products.length, "Produto nao encontrado");
        products[productIndex].balance += amount;
    }

    // Trocar preco do produto da vending machine
    function setPrice(uint price, uint productIndex) public onlyOwner() {
        require (productIndex < products.length, "Produto nao encontrado");
        products[productIndex].price = price;
    }

    // Obter precos dos produto da vending machine pelo index
    function getPrice(uint productIndex) public view returns (string memory name, uint price) {
        require (productIndex < products.length, "Produto nao encontrado");
        price = products[productIndex].price;
        name = products[productIndex].name;
    }

    function uint2str( uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0)
        {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }

    // Obter preco de todos produtos
    function getPrices() public view returns (string memory) {
        string memory response;
        for (uint i = 0; i < products.length; i++) {
            string memory data = this.concatStrings(products[i].name, " :", uint2str(products[i].price), "  Gwei, ");
            response = concatStrings(response, data, "\n", "");
        }
        return response;
    }

    // Obter o estoque do produto
    function getBalance(uint productIndex) public view returns (string memory name, uint balance) {
        require (productIndex < products.length, "Produto nao encontrado");
        balance = products[productIndex].balance;
        name = products[productIndex].name;
    }

    //Obter a quantidade de produtos diponiveis
    function getBalances() public view returns (string memory) {
        string memory response;
        for (uint i = 0; i < products.length; i++) {
            string memory data = this.concatStrings(products[i].name, " :", uint2str(products[i].balance), " unidades, ");
            response = concatStrings(response, data, "\n", "");
        }
        return response;
    }

    // Obter valor de saldo da maquina
    function getVendingMachineEtherBalance () public view returns (uint) {
        return address(this).balance;
    }

    // Transferir o saldo para carteira que publicou a maquina
    function withdraw () public onlyOwner() {
        uint totalBalance = this.getVendingMachineEtherBalance();
        owner.transfer(totalBalance);
    }

    // Concatenar strings para montar textos de exibição
    function concatStrings (string memory text1, string memory  text2, string memory text3, string memory text4) 
        public pure returns (string memory) 
    {
        return string.concat(text1, text2, text3, text4);
    }

    // Comprar produtos da vending machine informando o index do produto
    function purchase(uint productId, uint amount) public payable {
        require (productId < products.length, "Produto nao encontrado");

        uint productPrice = products[productId].price;
        uint productBalance = products[productId].balance;
        string memory productName = products[productId].name;
        
        uint totalValue = amount * productPrice * 1 gwei;

        require(msg.value >= totalValue, concatStrings("Voce deve pagar pelo menos ", uint2str(totalValue), " pelo ", productName));
        require(productBalance >= amount, concatStrings("A quantidade maxima de ", productName, " e ", uint2str(productBalance)));

        products[productId].balance -= amount;

        addBuyer(msg.sender);
        
        purchasing[msg.sender].push(Purchase({
            origin: msg.sender,
            product: productName,
            value: amount
        }));
    }

    function addBuyer (address buyer) private {
        bool hasBuyer = false;
        if (buyers.length == 0) {
            buyers.push(buyer);
            return;
        }
        for(uint i = 0; i < buyers.length; i++ ) {
            if (buyer == buyers[i]) {
                hasBuyer = true;
            }
        }
        if (!hasBuyer) {
            buyers.push(buyer);
        }
    }


    // Retorna todos compradores
    function getBuyers() public view returns (address[] memory) {
        return buyers;
    }

    //Obtem as compras do comprador
    function getBuyerPurchasing (address buyer) public view returns (string memory) {
        Purchase[] memory buyerPurchasing = purchasing[buyer];
        string memory response;
        for (uint i = 0; i < buyerPurchasing.length; i++) {
            string memory data = this.concatStrings(buyerPurchasing[i].product, " :", uint2str(buyerPurchasing[i].value), " produtos, ");
            response = concatStrings(response, data, "\n", "");
        }
        return response;
    }
}