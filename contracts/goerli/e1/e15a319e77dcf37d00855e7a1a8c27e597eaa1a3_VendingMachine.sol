/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract VendingMachine {
    // Declare state variables of the contract
    address payable public owner;
    mapping (address => uint) public cupcakeBalances;

    // When 'VendingMachine' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the deployed smart contract's cupcake balance to 100
    constructor() {
        owner = payable(msg.sender);
        cupcakeBalances[address(this)] = 100;
    }

    struct Buyer {
        address buyerAdsress; 
        int cupcakeCount;
    }
    

    uint price;
    Buyer[] public buyers;

    /// Only the owner can call this function.
    error OnlyOwner();


    modifier onlyOwner() {
        if (msg.sender != owner)
            revert OnlyOwner();
        _;
    }

    // Allow the owner to increase the smart contract's cupcake balance
    function refill(uint amount) public onlyOwner {
        cupcakeBalances[address(this)] += amount;
    }

    function setPrice(uint amount) public onlyOwner {
        price = amount;
    }

    function getPrice() external view returns (uint) {
        return price;
    }

    function getVendingMachineCupcakeBalance() external view returns (uint) {
        return cupcakeBalances[address(this)];
    }

    function getVendingMachineEtherBalance() external view returns (uint) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "No values to withdraw");
        owner.transfer(address(this).balance);
    }

    function getBuyers() external view returns (Buyer[] memory ) {
        return buyers;
    }


    // Allow anyone to purchase cupcakes
    function purchase(uint amount) public payable {
        require(msg.value >= amount * 1 gwei, "You must pay at least 1 GWEY per cupcake");
        require(cupcakeBalances[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");
        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;

        uint buyerIndex;
        bool buyerAlreadyExist = false;

        for (uint i = 0; i < buyers.length; i++) {
            if (buyers[i].buyerAdsress == msg.sender) {
                buyerAlreadyExist = true;
                buyerIndex = i;
                return ;
            }
        }

        if (buyerAlreadyExist) {
           buyers[buyerIndex].cupcakeCount += 1;
        } 
        else { 
            Buyer memory buyer = Buyer({ buyerAdsress: msg.sender, cupcakeCount: 1 });
            buyers.push(buyer);
        }
    }
}