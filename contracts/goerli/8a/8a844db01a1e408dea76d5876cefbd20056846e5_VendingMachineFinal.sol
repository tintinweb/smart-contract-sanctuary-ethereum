/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract VendingMachineFinal {
    // Declare state variables of the contract
    address payable private owner;
    uint private price;
    mapping (address => uint) private cupcakeBalances;

    struct Buyer {
        address buyer; 
        uint qnt; 
        bool onRegisteredBuyers;
    }

    struct BuyerDto {
        address buyer; 
        uint qnt; 
    }

    address[] private registeredBuyers;
    mapping(address => Buyer) private buyers;

    // When 'VendingMachine' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the deployed smart contract's cupcake balance to 100
    constructor() {
        owner = payable(msg.sender);
        cupcakeBalances[address(this)] = 100;
    }

    // modifier to verify if you are the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can do it.");
        _;
    }

    // set the price of cupcake in GWei
    function setPrice(uint parameterPrice) public onlyOwner() {
        price = parameterPrice;
    }

    // get the price of cupcake in GWei
    function getPrice() public view returns (uint) {
        return price;
    }

    // get the owner
    function getOwner() public view returns (address) {
        return owner;
    }

    // get the number of cupcakes in the machine
    function getVendingMachineCupcakeBalance() public view returns (uint) {
        return cupcakeBalances[address(this)];
    }

    // get amount of ether from machine address in ETH or GWei
    function getVendingMachineEtherBalance() public view returns (uint) {
        return address(this).balance / 1 ether;
    }

    // get amount of ether from owner address in ETH or GWei
    function getOwnerEtherBalance() public view returns (uint) {
        return owner.balance / 1 ether;
    }

    // get amount of ether from machine address in GWei
    function getVendingMachineGweiBalance() public view returns (uint) {
        return address(this).balance / 1 gwei;
    }

    // get amount of ether from owner address in ETH or GWei
    function getOwnerGweiBalance() public view returns (uint) {
        return owner.balance / 1 gwei;
    }

    // transfer the amount of ether from the machine to the owner
    function withdraw () public {
        owner.transfer(address(this).balance);
    } 

    // Returns a list of buyers
    function getBuyers() public view returns(BuyerDto[] memory) {
        BuyerDto[] memory _buyers = new BuyerDto[](registeredBuyers.length);
        for (uint i=0; i<registeredBuyers.length; i++) {
            _buyers[i].buyer=registeredBuyers[i];
            _buyers[i].qnt=cupcakeBalances[registeredBuyers[i]];
        }
        return _buyers;
    }

    // Allow the owner to increase the smart contract's cupcake balance
    function refill(uint amount) public onlyOwner() {
        cupcakeBalances[address(this)] += amount;
    }

    // Allow anyone to purchase cupcakes
    function purchase(uint amount) public payable {
        require(msg.value >=  amount * price * 1 gwei, "You must pay at least 0.01 ETH per cupcake");
        require(cupcakeBalances[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");
        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;

        address buyer = msg.sender;

        if(!buyers[buyer].onRegisteredBuyers) {
            buyers[buyer].onRegisteredBuyers = true;
            registeredBuyers.push(buyer);
        }

    }
}