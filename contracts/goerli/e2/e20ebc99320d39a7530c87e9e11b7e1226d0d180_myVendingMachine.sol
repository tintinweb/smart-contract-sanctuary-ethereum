/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract myVendingMachine {
    // Declare state variables of the contract
    address payable public owner;

    uint private cupcakeBalance;
    uint32 private cupcakePrice;

    Buyer[] private buyers;

    struct Buyer {
        address _address;
        uint cupcakeBalance;
    }

    // When 'VendingMachine' contract is deployed:
    // 1. set the deploying address as the owner of the contract
    // 2. set the deployed smart contract's cupcake balance to 100
    // 3. set the deployed smart contract's cupcake price to 1 GWEI
    constructor() {
        owner = payable(msg.sender);
        cupcakeBalance=100;
        cupcakePrice = 1;  
    }

    // get cupcake price in gwei
    function getPrice() public view returns (uint32) {
        return cupcakePrice;
    }

    // allow the owner to set price in gwei
    function setPrice (uint32 price) public onlyOwner() {
        cupcakePrice = price;
    }
    // Allow the owner to increase the smart contract's cupcake balance
    function refill(uint amount) public onlyOwner() {
        cupcakeBalance+= amount;
    }

    // Allow anyone to purchase cupcakes
    function purchase(uint amount) public payable {
        require(msg.value >= amount * cupcakePrice * 1e9, "Insufficient GWEI per cupcake");
        require(cupcakeBalance>= amount, "Not enough cupcakes in stock to complete this purchase");
        cupcakeBalance -= amount;
        //*Variables used to capture the return from _isRegistered() 
        uint256 index; 
        bool _isRegistered;

        (_isRegistered,index)= isRegistered(msg.sender);
        if(_isRegistered){
            buyers[index].cupcakeBalance+=amount;
        }else{
            buyers.push(Buyer({
                cupcakeBalance: amount,
                _address: msg.sender
            }));
        }

    }

    // return cupcake balance
    function getVendingMachineCupcakeBalance() public view returns (uint){
        return cupcakeBalance;
    }

    // return balance in gwei
    function getVendingMachineEtherBalance() public view returns(uint256){
        return address(this).balance/1e9;
    }

    // withdraw ether balance in gwei
    function withdraw(uint256 value) public onlyOwner(){
        require(value*1e9<=address(this).balance,"Insufficient balance");
        owner.transfer(value*1e9);
    }

    // return all buyers
    function getBuyers() public view returns(Buyer[] memory) {
        Buyer[] memory _buyers = new Buyer[](buyers.length);
        for (uint256 i=0; i<buyers.length; i++  ) {
           _buyers[i] = buyers[i];
        }
        return _buyers;
    }    
    
    // internal function used to check wheter a given address is registered in 'buyers'
    function isRegistered(address addrr) private view returns(bool,uint256){
        for (uint256 i = 0; i < buyers.length; i++  ) {
             address _address = buyers[i]._address;
            if (_address == addrr) {
                return (true,i);
            }
        }
        return (false,0);
    }

    modifier onlyOwner(){
        require(msg.sender ==owner, "Only the owner can call this function");
        _;
    }
}