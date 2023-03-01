/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Escrow {
    enum Available { NO, YES }
    enum Status {
        OPEN,
        PENDING,
        DELIVERY,
        CONFIRMED,
        DISPUTED,
        REFUNDED,
        WITHDRAWED
    }

    struct ItemStruct {
        uint itemId;
        string purpose;
        uint amount;
        address owner;
        address supplier;
        Status status;
        bool provided;
        bool confirmed;
        uint timestamp;
    }

    address public escAcc;
    uint public escBal;
    uint public escAvailBal;
    uint public escFee;
    uint public totalItems;
    uint public totalConfirmed;
    uint public totalDisputed;

    mapping(uint => ItemStruct) items;
    mapping(address => ItemStruct[]) itemsOf;
    mapping(address => mapping(uint => bool)) public requested;
    mapping(uint => address) public ownerOf;
    mapping(uint => Available) public isAvailable;

    event Action (
        uint itemId,
        string actiontype,
        Status status,
        address indexed executor
    );

    constructor(uint _escFee) {
        escAcc = msg.sender;
        escFee = _escFee;
    }

    function createItem(string memory purpose) public payable returns (bool) {
        require(bytes(purpose).length > 0, "Purpose cannot be empty");
        require(msg.value > 0 ether, "Amount cannot be zero");

        uint itemId = totalItems++;
        ItemStruct storage item = items[itemId];
        item.itemId = itemId;
        item.purpose = purpose;
        item.amount = msg.value;
        item.timestamp = block.timestamp;
        item.owner = msg.sender;

        itemsOf[msg.sender].push(item);
        ownerOf[itemId] = msg.sender;
        isAvailable[itemId] = Available.YES;
        escBal += msg.value;

        emit Action (
            itemId,
            "ITEM CREATED",
            Status.OPEN,
            msg.sender
        );

        return true;
    }

    function getItems() public view returns (ItemStruct[] memory props) {
        props = new ItemStruct[](totalItems);

        for(uint i=0; i < totalItems; i++) {
            props[i] = items[i];
        }
    }

    function getItem(uint itemId) public view returns (ItemStruct memory) {
        return items[itemId];
    }

    function myItems() public view returns (ItemStruct[] memory) {
        return itemsOf[msg.sender];
    }

    function requestItem(uint itemId) public returns (bool) {
        require(msg.sender != ownerOf[itemId], "Owner not allowed");
        require(isAvailable[itemId] == Available.YES, "Item not available");

        requested[msg.sender][itemId] = true;

        emit Action (
            itemId,
            "ITEM REQUESTED",
            Status.OPEN,
            msg.sender
        );

        return true;
    }

    function approveRequest(uint itemId, address supplier) public returns (bool) {
        require(msg.sender == ownerOf[itemId], "Only owner allowed");
        require(isAvailable[itemId] == Available.YES, "Item not available");
        require(requested[supplier][itemId], "supplier not on the list");

        items[itemId].supplier = supplier;
        items[itemId].status = Status.PENDING;
        isAvailable[itemId] = Available.NO;

        emit Action (
            itemId,
            "ITEM APPROVED",
            Status.PENDING,
            msg.sender
        );

        return true;
    }

    function performDelivery(uint itemId) public returns (bool) {
        require(msg.sender == items[itemId].supplier, "You are not the approved supplier");
        require(!items[itemId].provided, "You have already delieverd this item");
        require(!items[itemId].confirmed, "You have already confirmed this item");

        items[itemId].provided = true;
        items[itemId].status = Status.DELIVERY;

        emit Action (
            itemId,
            "ITEM DELIVERY INITIATED",
            Status.DELIVERY,
            msg.sender
        );

        return true;
    }

    function confirmDelievery(uint itemId, bool provided) public returns (bool) {
        require(msg.sender == ownerOf[itemId], "Only owner allowed");
        require(items[itemId].provided, "You have not delieverd this item");
        require(items[itemId].status != Status.REFUNDED, "Already refunded, create a new Item instead");

        if(provided) {
            uint fee = (items[itemId].amount * escFee) / 100;
            uint amount = items[itemId].amount - fee;
            payTo(items[itemId].supplier, amount);
            escBal -= items[itemId].amount;
            escAvailBal += fee;

            items[itemId].confirmed = true;
            items[itemId].status = Status.CONFIRMED;
            totalConfirmed++;

            emit Action (
                itemId,
                "ITEM CONFIRMED",
                Status.CONFIRMED,
                msg.sender
            );

        } else {
            items[itemId].status = Status.DISPUTED;

            emit Action (
                itemId,
                "ITEM DISPUTED",
                Status.DISPUTED,
                msg.sender
            );
        }
        
        return true;
    }

    function refundItem(uint itemId) public returns (bool) {
        require(msg.sender == escAcc, "Only Escrow admin allowed");
        require(!items[itemId].provided, "You have already delieverd this item");

        payTo(items[itemId].owner, items[itemId].amount);
        escBal -= items[itemId].amount;
        items[itemId].status = Status.REFUNDED;
        totalDisputed++;

        emit Action (
            itemId,
            "ITEM REFUNDED",
            Status.REFUNDED,
            msg.sender
        );

        return true;
    }

    function withdrawFund(address to, uint amount) public returns (bool) {
        require(msg.sender == escAcc, "Only Escrow admin allowed");
        require(amount <= escAvailBal, "insufficient fund");

        payTo(to, amount);
        escAvailBal -= amount;

        return true;
    }

    function payTo(address to, uint amount) internal returns (bool) {
        (bool succeeded,) = payable(to).call{value: amount}("");
        require(succeeded, "Payment failed");
        return true;
    }
}