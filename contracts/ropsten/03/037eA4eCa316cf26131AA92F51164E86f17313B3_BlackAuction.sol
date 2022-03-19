/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

contract BlackAuction {
    /*
        Welcome to BlackAuction, which will only give items to registered persons on next Sunday.
                All items in this auction have a fixed price (only 0.15 Ether)
            You must charge your wallet before buying (min 0.173 Ether)
            CyberPowerPC is an American personal computer retailer.
    */
    uint price;
    address owner;
    mapping(address => uint) wallet;
    mapping(uint => uint) purchases;
    mapping(uint => address) suggest;
    mapping(uint => bool) lock;

    event ChargeWallet(uint time, address _buyer, uint _value);
    event Purchase(uint time, uint _buyer, uint _productID);
    event PriceChange(uint time, address _owner, uint _price);
    event Swap(uint time, uint _buyer, uint _productID);

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
        price = 150000000000000000; //only 0.15 Ether
    }

    function setPrice(uint _price) ownerOnly() public {
        price = _price;
        emit PriceChange(block.timestamp, owner, price);
    }

    function terminate() ownerOnly() public payable{
        selfdestruct(payable(owner));
    }

    function changeOwner(address newOwner) ownerOnly() public{
        owner = newOwner;
    }
    /*
        #Action: chargeWallet, buyNow, swapThis, watchPrice, watchPurchase
        Items:
        ID 1: Inspiron 15 Laptop
        ID 2: Inspiron 15 2-in-1 Laptop
        ID 3: Inspiron 24 5000 Black All-In-One with Bipod Stand
        ID 4: Xbox Series S – Fortnite & Rocket League Bundle

        Note that you can only buy one product
    */
    /* --------------------Action---------------------- */
    function getEtherBack(address payable to) internal{
        uint sendback;
        if(wallet[to]>0){
            sendback = wallet[to]-price;

            to.send(sendback);
            wallet[to]=wallet[to]-sendback;
        }
    }
    //#charge#
    function chargeWallet() public payable{
        require(msg.value >= 0.173 ether);
        wallet[msg.sender] += msg.value;
        emit ChargeWallet(block.timestamp, msg.sender, wallet[msg.sender]);
    }
    //#buy#
    function buyNow(uint ID, uint buyerID) public{
        require(wallet[msg.sender] >= 0.173 ether);
        require(lock[buyerID] == false,"sender already buyed");
        require(ID>0 && ID<5,"item ID is not valid");

        purchases[buyerID] = ID;
        emit Purchase(block.timestamp, buyerID, ID);

        getEtherBack(msg.sender);
        suggest[buyerID] = msg.sender;
        lock[buyerID] = true;
    }
    //#swap#
    function swapThis(uint buyerID, uint ID) public{
        require(suggest[buyerID] == msg.sender,"buyerID is not suggested by sender");
        purchases[buyerID] = ID;
        emit Swap(block.timestamp, buyerID, ID);
    }
    //#watch price#
    function watchPrice() public view returns(uint){
        return price;
    }
    //#watch purchase#
    function watchPurchase(uint buyerID) public view returns(uint){
        return purchases[buyerID];
    }
}