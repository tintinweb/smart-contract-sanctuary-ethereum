/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

pragma solidity ^0.5.0;

contract Marketplace {
    string public name;
    uint public productCount = 0;
    uint public productPurchaseCount = 0;
    address public owner;
    mapping(uint => Product) public products;

    struct Product {
        uint id;
        string name;
        uint price;
        string detailProductParam;
        address payable owner;
        bool purchased;
    }

    event ProductCreated(
        uint id,
        string name,
        uint price,
        string detailProductParam,
        address payable owner,
        bool purchased
    );

    event ProductPurchased(
        uint id,
        string name,
        uint price,
        address payable owner,
        bool purchased
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
        // Create the product
        products[productCount] = Product(productCount, _name, _price, _detailProductParam, msg.sender, false);
        // Trigger an event
        emit ProductCreated(productCount, _name, _price, _detailProductParam, msg.sender, false);
    }

    function purchaseProduct(uint _id) public payable {
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
        // Update the product
        products[_id] = _product;
        // Pay the seller by sending them Ether
        address(_seller).transfer(msg.value);
        // Increment product count
        productPurchaseCount ++;
        // Trigger an event
        emit ProductPurchased(productCount, _product.name, _product.price, msg.sender, true);
    }
}