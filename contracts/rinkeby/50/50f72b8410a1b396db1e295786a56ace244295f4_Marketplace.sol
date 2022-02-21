/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

pragma solidity ^0.5.0;

contract Marketplace {
    string public name;
    uint public productCount = 0;
    uint public productPurchaseCount = 0;
    uint public productTransactionCount = 0;
    uint public loyaltyValue = 10;
    address payable public owner;
    mapping(uint => Product) public products;

    struct Product {
        uint id;
        string name;
        uint price;
        string detailProductParam;
        address payable owner;
        bool purchased;
        bool onSale;
    }

    event ProductCreated(
        uint id,
        string name,
        uint price,
        string detailProductParam,
        address payable owner,
        bool purchased,
        bool onSale
    );

    event ProductPurchased(
        uint id,
        string name,
        uint price,
        address payable owner,
        bool purchased,
        bool onSale
    );

    event UpdateStatusPrice(
        uint id,
        string name,
        uint price,
        bool onSale
    );

    event ProductResell(
        uint id,
        string name,
        uint price,
        address payable owner,
        bool onSale
    );

    constructor() public {
        name = "NFT Buruan";
        owner = msg.sender;
    }

    function createProduct(string memory _name, uint _price, string memory _detailProductParam) public {
        //validate address is owner smart contract
        require(msg.sender == owner, 'You are not the owner!');
        // Require a valid name
        require(bytes(_name).length > 0);
        // Require a valid price
        require(_price > 0);
        // Require a valid detailProductParam
        require(bytes(_detailProductParam).length > 0);
        // Increment product count
        productCount ++;
        // Increment Product Transaction count
        productTransactionCount ++;
        // Create the product
        products[productCount] = Product(productCount, _name, _price, _detailProductParam, msg.sender, false, true);
        // Trigger an event
        emit ProductCreated(productCount, _name, _price, _detailProductParam, msg.sender, false, true);
    }

    function purchaseProduct(uint _id, uint _newPrice, bool _onSale) public payable {
        // Fetch the product
        Product memory _product = products[_id];
        // Fetch the owner
        address payable _seller = _product.owner;
        // Make sure the product has a valid id
        require(_product.id > 0 && _product.id <= productCount);
        // Require that there is enough Ether in the transaction
        require(msg.value >= _product.price);
        // Require that the product has not been purchased already
        require(!_product.purchased);
        // Require that the buyer is not the seller
        require(_seller != msg.sender);
        // Transfer ownership to the buyer
        _product.owner = msg.sender;
        // Mark as purchased
        _product.purchased = true;
        // Mark as purchased
        _product.onSale = _onSale;
        // set new Price
        _product.price = _newPrice;
        // Update the product
        products[_id] = _product;
        // Pay the seller by sending them Ether
        address(_seller).transfer(msg.value);
        // Increment product purchase count
        productPurchaseCount ++;
        // Increment Product Transaction count
        productTransactionCount ++;
        // Trigger an event
        emit ProductPurchased(_id, _product.name, _product.price, msg.sender, true, _onSale);
    }

    function updateSellingPrice(uint _id, uint _price, bool _onSale) public {
        // Fetch the product
        Product memory _product = products[_id];
        // Make sure the product has a valid id
        require(_product.id > 0 && _product.id <= productCount);
        // Require a valid price
        require(_price > 0);
        // Require that the owner product
        require(_product.owner == msg.sender);
        // Transfer ownership to the buyer
        _product.price = _price;
        // Mark as can Buy with other
        _product.onSale = _onSale;
        // Update the product
        products[_id] = _product;
        // Increment Product Transaction
        productTransactionCount ++;
        // Trigger an event
        emit UpdateStatusPrice(_id, _product.name, _price, _onSale);
    }

    function buyProduct(uint _id, uint _newPrice, bool _onSale) public payable {
        // Fetch the product
        Product memory _product = products[_id];
        // Fetch the owner
        address payable _seller = _product.owner;
        // Make sure the product has a valid id
        require(_product.id > 0 && _product.id <= productCount);
        // Require that there is enough Ether in the transaction
        require(msg.value >= _product.price);
        // Require that the buyer is not the seller
        require(_seller != msg.sender);
        // validate product on sale
        require(_product.onSale);
        // Transfer ownership to the buyer
        _product.owner = msg.sender;
        // Mark as purchased
        _product.onSale = _onSale;
        // set new Price
        _product.price = _newPrice;
        // Update the product
        products[_id] = _product;
        // Pay the seller 
        address(_seller).transfer(msg.value * (100 - loyaltyValue) / 100);
        // Pay the loyalty to owner
        address(owner).transfer(msg.value * loyaltyValue / 100);
        // Increment Product Transaction
        productTransactionCount ++;
        // Trigger an event
        emit ProductResell(_id, _product.name, _product.price, msg.sender, _onSale);
    }
}