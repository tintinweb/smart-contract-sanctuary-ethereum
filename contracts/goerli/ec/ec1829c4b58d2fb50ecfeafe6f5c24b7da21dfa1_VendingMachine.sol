/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract VendingMachine {
    // Declare state variables of the contract
    address payable public owner;
    mapping(address => uint256) public cupcakeBalances;
    uint256 priceCupcake;
    Buyers[] public allBuyers;

    // When 'VendingMachine' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the deployed smart contract's cupcake balance to 100
    constructor() {
        owner = payable(msg.sender);
        cupcakeBalances[address(this)] = 100;
        priceCupcake = 1 gwei;
    }

    struct Buyers {
        address sender;
        uint256 amount;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can perform this action."
        );
        _;
    }

    // Allow the owner to increase the smart contract's cupcake balance
    function refill(uint256 amount) public onlyOwner {
        cupcakeBalances[address(this)] += amount;
    }

    // Allow anyone to purchase cupcakes
    function purchase(uint256 amount) public payable {
        require(
            msg.value >= amount * priceCupcake,
            "You must pay at least 1 gwei per cupcake"
        );
        require(
            cupcakeBalances[address(this)] >= amount,
            "Not enough cupcakes in stock to complete this purchase"
        );
        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;

        bool noExists = true;
        for(uint256 i = 0; i < allBuyers.length; i++){
            if(allBuyers[i].sender == msg.sender){
                allBuyers[i].amount += amount;
                noExists = false;
                break;
            }
        }

        if(noExists){
            allBuyers.push(Buyers({sender: msg.sender, amount: amount}));
        }
    }

    function setPrice(uint256 amount) public onlyOwner {
        priceCupcake = amount;
    }

    function getPrice() public view returns (uint256) {
        return priceCupcake;
    }

    function getVendingMachineCupcakeBalance() public view returns (uint256) {
        return cupcakeBalances[address(this)];
    }

    function getVendingMachineEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function getBuyers() public view returns (Buyers[] memory) {
        Buyers[] memory _buyers = new Buyers[](allBuyers.length);

        for(uint256 i = 0; i < allBuyers.length; i++){
           _buyers[i] = allBuyers[i];
        }

        return _buyers;
    }
}