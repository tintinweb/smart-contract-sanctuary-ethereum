/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// SPDX-License-Identifier: AFL-1.1

pragma solidity ^0.8.0;

contract Escrow {

    address public owner;
    address[] public seller;
    uint256 public sellerCount;
    uint256 public ownerRevenue;

    // state 0 : unactive sell
    // state 1 : active sell
    // state 2 : on shipping process
    // state 3 : open dispute

    struct order {
        uint256 price;
        address buyer;
        address seller;
        uint256 state;
        uint256 lockAmount;
        string description;
        uint256 expiredTime;
        string[] disputeMessage;
    }

    constructor() {
        owner = msg.sender;
    }

    mapping (address => order[]) public sellerDB;
    mapping (address => uint256) public orderCount;
    mapping (address => uint256) private checkSellerRedun;

    function BlockTime() public view returns(uint256) {
        return block.timestamp;
    }

    function activateSell(uint256 price,string memory addDescription) public {
        if(checkSellerRedun[msg.sender] == 0){
            seller.push(msg.sender);
            sellerCount +=1;
            checkSellerRedun[msg.sender] +=1;
        }
        orderCount[msg.sender] +=1;
        order memory currentOrder;
        currentOrder.price = price+100000000000000;
        currentOrder.seller = msg.sender;
        currentOrder.description = addDescription;
        currentOrder.state = 1;
        sellerDB[msg.sender].push(currentOrder);
    }

    function sendOrder(address sellerAddress,uint256 orderID) public payable {
        require(sellerDB[sellerAddress][orderID].state == 1,"only active sell state order can call");
        sellerDB[sellerAddress][orderID].buyer = msg.sender;
        sellerDB[sellerAddress][orderID].lockAmount += msg.value-100000000000000;
        if(sellerDB[sellerAddress][orderID].lockAmount >= sellerDB[sellerAddress][orderID].price-100000000000000 ){
            sellerDB[sellerAddress][orderID].state = 2;
            sellerDB[sellerAddress][orderID].expiredTime = block.timestamp+2600000 ;
        }
    }

    function releasedLockAmount(address sellerAddress,uint256 orderID) public {
        require(( owner == msg.sender || sellerDB[sellerAddress][orderID].buyer == msg.sender ) ||
         ( sellerDB[sellerAddress][orderID].expiredTime < block.timestamp && sellerDB[sellerAddress][orderID].seller == msg.sender )
         ,"only owner or buyer can cancel an order or the time was expired");
        payable(sellerDB[sellerAddress][orderID].seller).transfer( sellerDB[sellerAddress][orderID].lockAmount );
        ownerRevenue+=100000000000000;
        sellerDB[sellerAddress][orderID].lockAmount = 0;
        sellerDB[sellerAddress][orderID].state = 0;
        sellerDB[sellerAddress][orderID].buyer = 0x0000000000000000000000000000000000000000;
    }

    function cancelOrder(address sellerAddress,uint256 orderID) public {
        require(owner == msg.sender || sellerDB[sellerAddress][orderID].seller == msg.sender,"only owner or seller can cancel an order");
        payable(sellerDB[sellerAddress][orderID].buyer).transfer( sellerDB[sellerAddress][orderID].lockAmount+100000000000000 );
        sellerDB[sellerAddress][orderID].lockAmount = 0;
        sellerDB[sellerAddress][orderID].state = 0;
        sellerDB[sellerAddress][orderID].buyer = 0x0000000000000000000000000000000000000000;
    } 

    function openDispute(address sellerAddress,uint256 orderID,string memory message) public {
        require(((sellerDB[sellerAddress][orderID].seller == msg.sender) || (sellerDB[sellerAddress][orderID].buyer == msg.sender) || (owner==msg.sender))
        && (sellerDB[sellerAddress][orderID].state == 2),"only state 'on shipping' and seller,buyer can open dispute");
        sellerDB[sellerAddress][orderID].expiredTime += 2600000;
        sellerDB[sellerAddress][orderID].state = 3;
        sellerDB[sellerAddress][orderID].disputeMessage.push(message);
    }

    function returnSellerArray() public view returns(address[] memory){
        return seller;
    }

    function ownerClaim() public {
        require( owner == msg.sender,"only owner can claim");
        payable(owner).transfer( ownerRevenue );
    }

}