/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// Import other contracts and libraries if necessary

contract Ecommerce {

// Declare variables and data structures to be used

// Struct to represent a product
struct Product {
string name;
string description;
uint256 price;
uint256 stock;
bool isAdded;
}

 address payable owner;

Product[] public products;

// Mapping to store the buyers and their purchased products
mapping(address => mapping(uint256 => uint256)) public purchases;

event ProductAdded(string name, string description, uint256 price, uint256 stock);
event ProductPurchased(address buyer, uint256 productId, uint256 quantity);



modifier onlyOwner {
    require(msg.sender == owner, "Only owner can call this function.");
    _;
}

constructor () {
    owner = payable(msg.sender); 
}

function addProduct(string memory _name, string memory _description, uint256 _price, uint256 _stock) public onlyOwner  {
Product memory newProduct = Product(_name, _description, _price, _stock , true);
products.push(newProduct);
emit ProductAdded(_name, _description, _price, _stock);
}

function purchaseProduct(uint256 _productId, uint256 _quantity) public payable {
Product memory product = products[_productId];
require(msg.value == product.price * _quantity, "Insufficient funds.");
require(product.stock >= _quantity, "Not enough stock available.");

purchases[msg.sender][_productId] += _quantity;
product.stock -= _quantity;

emit ProductPurchased(msg.sender, _productId, _quantity);
}

function viewProduct(uint256 _productId) public view returns (string memory name, string memory description, uint256 price, uint256 stock) {
Product memory product = products[_productId];
return (product.name, product.description, product.price, product.stock);
}

// Other functions to update and delete products can also be added

function updateProduct(uint _id, string memory _name, uint _price) public onlyOwner {
    require(products[_id].isAdded == true, "Product is not available.");
    products[_id].name = _name;
    products[_id].price = _price;
}

}