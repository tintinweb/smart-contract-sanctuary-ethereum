// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error ApniDukan__transactionFailed();

contract ApniDukan {
    event InvoiceCreated(uint indexed invoiceId);
    event ItemBought(uint indexed itemId);
    event SellerAdded(uint indexed sellerId);
    event SellerRemoved(uint indexed sellerId);
    event ItemAdded(uint indexed sellerId, uint indexed itemId);
    event ItemUpdated(uint indexed sellerId, uint indexed itemId);

    address admin;

    struct Invoice {
        uint invoiceId;
        string buyerPan;
        string sellerPan;
        uint itemId;
        uint invoiceDate;
        bool paymentStatus;
    }

    struct Item {
        uint itemId;
        string name;
        uint price;
    }

    struct Seller {
        uint sellerId;
        address sellerAddress;
        string sellerPan;
        bool hasAdminPermission;
    }

    // constructor
    constructor() {
        admin = msg.sender;
    }

    // mappings
    mapping(uint => Seller) idToSeller;
    mapping(uint => Invoice) invoiceIdToInvoice;
    mapping(uint => Item[]) sellerIdToItems;

    // lists
    Seller[] sellers;
    Invoice[] invoices;

    // Modifiers
    modifier onlySeller(uint _sellerId) {
        require(idToSeller[_sellerId].sellerAddress == msg.sender, "Only seller");
        _;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "Only admin");
        _;
    }

    modifier hasAdminPermission(uint _sellerId) {
        require(idToSeller[_sellerId].hasAdminPermission, "Not have admin permission");
        _;
    }

    modifier itemExists(uint _sellerId, uint _itemId) {
        require(_itemId < sellerIdToItems[_sellerId].length, "Item does not exist");
        _;
    }

    modifier sellerExist(uint _sellerId) {
        require(_sellerId < sellers.length, "Seller does not exist");
        _;
    }

    // buyer buys particular item from seller
    function buyItem(
        string memory _buyerPan,
        uint _sellerId,
        uint _itemId
    )
        external
        payable
        hasAdminPermission(_sellerId)
        sellerExist(_sellerId)
        itemExists(_sellerId, _itemId)
    {
        uint price = sellerIdToItems[_sellerId][_itemId].price;
        require(msg.value >= price, "Send enough to buy item");
        string memory sellerPan = idToSeller[_sellerId].sellerPan;
        address sellerAddress = idToSeller[_sellerId].sellerAddress;

        (bool success, ) = payable(sellerAddress).call{value: msg.value}("");
        if (success) {
            Invoice memory invoice = Invoice(
                invoices.length,
                _buyerPan,
                sellerPan,
                _itemId,
                block.timestamp,
                success
            );
            invoices.push(invoice);

            emit ItemBought(_itemId);
            emit InvoiceCreated(invoices.length - 1);
        } else {
            revert ApniDukan__transactionFailed();
        }
    }

    // add item
    function addItem(
        uint _sellerId,
        string memory _itemName,
        uint _itemPrice
    ) external hasAdminPermission(_sellerId) onlySeller(_sellerId) {
        uint id = sellerIdToItems[_sellerId].length;
        sellerIdToItems[_sellerId].push(Item(id, _itemName, _itemPrice));
        emit ItemAdded(_sellerId, id);
    }

    // update item
    function updateItem(
        uint _sellerId,
        uint _itemId,
        string memory _newItemName,
        uint _newItemPrice
    ) external onlySeller(_sellerId) hasAdminPermission(_sellerId) itemExists(_sellerId, _itemId) {
        sellerIdToItems[_sellerId][_itemId].name = _newItemName;
        sellerIdToItems[_sellerId][_itemId].price = _newItemPrice;
        emit ItemUpdated(_sellerId, _itemId);
    }

    // add seller
    function addSeller(string memory _sellerPan, address _sellerAddress) public onlyAdmin {
        Seller memory seller = Seller(sellers.length, _sellerAddress, _sellerPan, true);
        idToSeller[sellers.length] = seller;
        sellers.push(seller);
        emit SellerAdded(sellers.length - 1);
    }

    // remove seller
    function removeSeller(uint _sellerId) public onlyAdmin sellerExist(_sellerId) {
        idToSeller[_sellerId].hasAdminPermission = false;
        emit SellerRemoved(_sellerId);
    }

    // get payment status
    function getPaymentStatus(uint _invoiceId) public view returns (bool) {
        return invoiceIdToInvoice[_invoiceId].paymentStatus;
    }

    function getPreviousInvoicesForBuyer(
        string memory _pan
    ) public view returns (Invoice[] memory) {
        uint counter = 0;
        for (uint i = 0; i < invoices.length; i++) {
            if (
                keccak256(abi.encodePacked(_pan)) ==
                keccak256(abi.encodePacked(invoices[i].buyerPan))
            ) {
                ++counter;
            }
        }
        Invoice[] memory buyerInvoices = new Invoice[](counter);

        uint counter2 = 0;
        for (uint i = 0; i < invoices.length; i++) {
            if (
                keccak256(abi.encodePacked(_pan)) ==
                keccak256(abi.encodePacked(invoices[i].buyerPan))
            ) {
                buyerInvoices[counter2] = invoices[i];
                ++counter2;
            }
        }
        return buyerInvoices;
    }

    // transfer ownership
    function transferOwnership(address newAdmin) public onlyAdmin {
        admin = newAdmin;
    }

    // getters

    function getAdmin() public view returns (address) {
        return admin;
    }

    function getSellers() public view returns (Seller[] memory) {
        return sellers;
    }

    function getItems(uint _sellerId) public view returns (Item[] memory) {
        return sellerIdToItems[_sellerId];
    }
}