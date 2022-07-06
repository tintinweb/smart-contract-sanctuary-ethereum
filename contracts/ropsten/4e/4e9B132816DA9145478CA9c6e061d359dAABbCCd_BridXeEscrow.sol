// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import './ReentrancyGuard.sol';

// TODO: There is a bug in BuyerConfirmDelivery where if you put in false, it still confirms the delivery
// TODO: implement seller locks NFT in escrow
// TODO: After BuyerConfrimDelivery is true, take item out of getSellOrders array
// TODO: After BuyerConfirmDelvery is false and/or EscrowRefund Item, reset values so that item is either delisted or back up for sale

contract BridXeEscrow is ReentrancyGuard {
    string public name = "BridXe escrow contract";

    address private escAcc;
    uint256 private escBal;
    uint256 private escRoyalty;
    uint256 private escFee; 
    uint256 public totalItems = 0;
    uint256 public totalConfirmed = 0;
    uint256 public totalDisputed = 0;

    // Challenge: make this price dynamic according to the current currency price
    uint256 private listingFee = 0.0045 ether; //TODO: Make a function to edit this later on

    mapping(uint256 => ItemStruct) private items;
    mapping(address => ItemStruct[]) private itemsOf;
    mapping(address => mapping(uint256 => bool)) public requested;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => Available) public isAvailable;

    enum Status {
        OPEN,
        PENDING,
        DELIVERY,
        CONFIRMED,
        DISPUTED,
        REFUNDED,
        WITHDRAWED
    }

    enum Available { NO, YES }

    struct ItemStruct {
        uint256 itemId;
        string itemDescription;
        uint256 listingPrice; // x * 10^18 = amount in eth
        uint256 paidPrice;
        uint256 timestamp;
        address owner;
        address buyer;
        Status status;
        bool delivered;
        bool confirmed;
    }

    event Action (
        uint256 itemId,
        string actionType,
        Status status,
        address indexed executor
    );

    constructor() {
        escAcc = msg.sender;
        escBal = 0;
        escRoyalty = 0; 
        escFee = 10; //Set escrow royalty percentage, TODO: Make function to edit this later on
    }

    function getListingFee() public view returns (uint256) {
        return listingFee;
    }

    function getEscrowBalance() public view returns (uint256) {
        return escBal;
    }

    function getEscrowRoyalty() public view returns (uint256) {
        return escRoyalty;
    }

    function sellerCreateSellOrder(
        string calldata itemDescription,
        uint256 listingPrice
    ) payable external returns (bool) {
        require(msg.sender != escAcc, "Escrow wallet cannot interact with buy or sell orders");
        require(bytes(itemDescription).length > 0, "Item Description cannot be empty");
        require(listingPrice > 0 ether, "Listing price must be greater than 0eth");
        require(msg.value == listingFee, "Price must be equal to listing fee of 0.045eth");


        uint256 itemId = totalItems++;
        ItemStruct storage item = items[itemId];

        item.itemId = itemId;
        item.itemDescription = itemDescription;
        item.timestamp = block.timestamp;
        item.owner = msg.sender;
        item.status = Status.OPEN;
        item.listingPrice = listingPrice;

        itemsOf[msg.sender].push(item);
        ownerOf[itemId] = msg.sender;
        isAvailable[itemId] = Available.YES;
        escBal += msg.value;
        escRoyalty += msg.value;

        emit Action (
            itemId,
            "ITEM CREATED",
            Status.OPEN,
            msg.sender
        );
        return true;
    }

    function getSellOrders()
        external
        view
        returns (ItemStruct[] memory props) {
        props = new ItemStruct[](totalItems);

        for (uint256 i = 0; i < totalItems; i++) {
            props[i] = items[i];
        }
    }

    function getSellOrder(uint256 itemId)
        external
        view
        returns (ItemStruct memory) {
        return items[itemId];
    }

    function mySellOrders()
        external
        view
        returns (ItemStruct[] memory) {
        return itemsOf[msg.sender];
    }

    function buyerRequestToBuy(uint256 itemId) payable external returns (bool) {
        require(msg.sender != ownerOf[itemId], "Owner of item not allowed");
        require(msg.sender != escAcc, "Escrow wallet cannot interact with buy or sell orders");
        require(isAvailable[itemId] == Available.YES, "Item not available");
        
        //payment
        require(msg.value >= items[itemId].listingPrice, "Price must be greater than or equal to the listing price of the item");
        escBal += msg.value;
        items[itemId].paidPrice = msg.value;

        requested[msg.sender][itemId] = true;

        emit Action (
            itemId,
            "REQUESTED by some Buyer",
            Status.OPEN,
            msg.sender
        );

        return true;
    }

    function sellerApproveBuyRequest(
        uint256 itemId,
        address buyer
    ) external returns (bool) {
        require(msg.sender == ownerOf[itemId], "Only owner of item allowed");
        require(msg.sender != escAcc, "Escrow wallet cannot interact with buy or sell orders");
        require(isAvailable[itemId] == Available.YES, "Item not available");
        require(requested[buyer][itemId], "Buyer is not on the list");

        isAvailable[itemId] == Available.NO;
        items[itemId].status = Status.PENDING;
        items[itemId].buyer = buyer;

        emit Action (
            itemId,
            "APPROVED",
            Status.PENDING,
            msg.sender
        );

        return true;
    }

    function sellerPerformDelievery(uint256 itemId) external returns (bool) {
        require(msg.sender == items[itemId].owner, "Service not awarded to you, only the owner of the item may perform this action");
        require(msg.sender != escAcc, "Escrow wallet cannot interact with buy or sell orders");
        require(!items[itemId].delivered, "item already delivered");
        require(!items[itemId].confirmed, "item delivery already confirmed");

        items[itemId].delivered = true;
        items[itemId].status = Status.DELIVERY;

        emit Action (
            itemId,
            "DELIVERY INTIATED",
            Status.DELIVERY,
            msg.sender
        );

        return true;
    }

    function buyerConfirmDelivery(
        uint256 itemId,
        bool delivered
    ) external returns (bool) {
        require(items[itemId].delivered, "Service was never delivered");
        require(msg.sender != escAcc, "Escrow wallet cannot interact with buy or sell orders");
        require(items[itemId].status != Status.REFUNDED, "Already refunded, create a new Item");
        require(msg.sender == items[itemId].buyer, "Only buyer allowed");

        if(delivered) {
            uint256 fee = (items[itemId].paidPrice * escFee) / 100;
            payTo(items[itemId].owner, (items[itemId].paidPrice - fee));
            escBal -= items[itemId].paidPrice - fee;
            escRoyalty += fee;

            items[itemId].confirmed = true;
            items[itemId].status = Status.CONFIRMED;
            items[itemId].owner  = msg.sender;
            items[itemId].buyer = address(0); //resets buyer address to default

            totalConfirmed++;

            emit Action (
                itemId,
                "CONFIRMED",
                Status.CONFIRMED,
                msg.sender
            );
        } else {
           items[itemId].status = Status.DISPUTED; 

           emit Action (
                itemId,
                "DISPUTED",
                Status.DISPUTED,
                msg.sender
            );
        }

        return true;
    }

    function escrowRefundItem(uint256 itemId) external returns (bool) {
        require(msg.sender == escAcc, "Only Escrow wallet allowed");
        require(!items[itemId].confirmed, "item delivery was already confirmed");

        payTo(items[itemId].buyer, items[itemId].paidPrice);
        escBal -= items[itemId].paidPrice;
        items[itemId].status = Status.REFUNDED;
        totalDisputed++;

        emit Action (
            itemId,
            "REFUNDED",
            Status.REFUNDED,
            msg.sender
        );

        return true;
    }

    function escrowWithdrawFund(
        address to,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == escAcc, "Only Escrow allowed");
        require(amount > 0 ether && amount <= escRoyalty, "There is nothing to withdraw");

        payTo(to, amount);
        escRoyalty -= amount;

        emit Action (
            block.timestamp,
            "WITHDRAWED",
            Status.WITHDRAWED,
            msg.sender
        );

        return true;
    }

    function payTo(
        address to, 
        uint256 amount
    ) internal returns (bool) {
        (bool success,) = payable(to).call{value: amount}("");
        require(success, "Payment failed");
        return true;
    }
}