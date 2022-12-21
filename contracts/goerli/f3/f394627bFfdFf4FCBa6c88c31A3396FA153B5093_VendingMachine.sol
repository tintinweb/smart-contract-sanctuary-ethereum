/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract VendingMachine {

    address public owner;
    mapping (address => uint) public cupcakeBalances;
	
	struct Buyer {
		uint balance;
		address buyer;
		bool registered;
	}
	
	mapping (address => Buyer) public buyers;
	address[] private registeredBuyers;
	
	// Armazena o preco do cupcake
	uint private _price = 1;
	
	modifier onlyOwner {
		require(msg.sender == owner, "Only the owner can refill.");
		_;
	}

    // When 'VendingMachine' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the deployed smart contract's cupcake balance to 100
    constructor() {
        owner = payable(msg.sender);
        cupcakeBalances[address(this)] = 100;
    }
	

	function getVendingMachineCupcakeBalance() public view returns (uint) {
        return cupcakeBalances[address(this)];
    }
	
	function getVendingMachineEtherBalance() public view returns (uint256) {
        return address(this).balance / 1 ether;
    }
	

    // Allow the owner to increase the smart contract's cupcake balance
    function refill(uint amount) public onlyOwner {
        cupcakeBalances[address(this)] += amount;
    }

    // Allow anyone to purchase cupcakes
    function purchase(uint amount) public payable {
        require(msg.value >= amount * 1 ether, "Valor insuficiente para cupcake.");
        require(cupcakeBalances[address(this)] >= amount, "Nao ha cupcakes suficientes em estoque para concluir esta compra.");
        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;
		
		buyers[msg.sender].balance = cupcakeBalances[msg.sender];
		
		if (!buyers[msg.sender].registered) {
			registeredBuyers.push(msg.sender);
		}
		
		buyers[msg.sender].registered = true;
    }
	
	
	function setPrice(uint price) public onlyOwner {
		require(price > 0, "Preco deve ser maior que zero.");
		_price = price * 1 ether;
	}
	
	function getPrice() public view returns (uint) {
		return _price / 1 ether;
	}
	
	function withdraw() public onlyOwner {
        require(address(this).balance > 0, "A carteira nao tem Ethers.");
        payable(msg.sender).transfer(address(this).balance);
    }
	
	function getBuyers() public view returns(Buyer[] memory) { 
        Buyer[] memory _buyers = new Buyer[](registeredBuyers.length); 
        for (uint i=0; i<registeredBuyers.length; i++) { 
            _buyers[i] = buyers[registeredBuyers[i]]; 
        } 
        return _buyers; 
    }     
	
}