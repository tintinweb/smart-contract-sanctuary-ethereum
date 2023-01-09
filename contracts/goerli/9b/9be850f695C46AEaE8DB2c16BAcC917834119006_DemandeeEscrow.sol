/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

contract DemandeeEscrow{

    enum State {AWAITING_PAYMENT, AWAITING_DELIVERY, COMPLETE}



    struct Product{
        uint productId;
        uint bidPrice;
        address payable farmer;
        address  bidder;
        uint minimumBid;
        bool bidAccepted; 
        State status; 
    }

    uint public productID=1;
    mapping (uint=>address) public buyerBuy; //productID>>>>>buyerWallet
    mapping (uint=>uint) public productPayments;
    mapping (uint => Product) public appProducts;
    address payable  [] public farmers;
    address payable [] public buyers;

    function addProduct(uint _bidPrice, uint _minimumBid) public payable  {
        require(_bidPrice>_minimumBid,"Bid cant be less than mininimum bid");
        appProducts[productID]=Product(productID, _bidPrice,payable(msg.sender),address(0),_minimumBid,false,State.AWAITING_PAYMENT);
        productID++;
    }

    function addBid(uint _bidPrice, uint _productID) public payable {
        require(appProducts[_productID].farmer!=address(0));
        require(_bidPrice>appProducts[_productID].bidPrice, "previous bid is greater");
        require(appProducts[_productID].bidAccepted==false,"Bid Confirmed Already");
        appProducts[_productID].bidPrice=_bidPrice;
        appProducts[_productID].bidder=msg.sender;
    }

    function confirmBid(uint _productID) public {
        require(appProducts[_productID].farmer==payable(msg.sender));
        appProducts[_productID].bidAccepted=false;
    }
    
    function buyProduct(uint _productID) public payable 
    {
        require(appProducts[_productID].bidAccepted==true, "Bid Not confirmed");
        require(appProducts[_productID].bidder==msg.sender, "Only bidder can buy product");
        require(buyerBuy[_productID]==address(0), "Already bought");
        require(msg.value>=appProducts[_productID].bidPrice,"ETH less the bid");
        require(appProducts[_productID].status==State.AWAITING_PAYMENT,"No Product Awaiting Payment");
        appProducts[_productID].status=State.AWAITING_DELIVERY;
        buyerBuy[_productID]=msg.sender;
        productPayments[_productID]=msg.value;
    }

    function confirmDelivery(uint _productID) public payable returns (bool)
    {
        require(buyerBuy[_productID]!=address(0),"No buyer paid for specific product");
        require(appProducts[_productID].status==State.AWAITING_DELIVERY,"Product hasnt been paid for");
        appProducts[_productID].farmer.send(productPayments[_productID]);
        appProducts[_productID].status=State.COMPLETE;

        return true; 

    }

    function addBuyer(address payable _buyer) public
    {
        buyers.push(_buyer);
    }

    function addFarmer(address payable _farmer) public
    {
        farmers.push(_farmer);
    }
    
    function withdraw() public payable  {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
   
}