// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {

    struct Product {
        address owner;
        string title;
        string description;
        uint price;
        uint quantity;
        string image;
        address[] buyers;
    }

    mapping(uint => Product) public products;

    function createProduct(string memory _title, string memory _description, uint _price, uint _quantity, string memory _image) public {
        products[1] = Product(msg.sender, _title, _description, _price, _quantity, _image, new address[](0));
    }
    
    function getProducts() public view returns (Product[] memory) {
        Product[] memory _products = new Product[](1);
        _products[0] = products[1];
        return _products;
    }

    function buyProduct(uint _id) public payable {
        Product storage product = products[_id];
        require(msg.value >= product.price, 'Not enough ETH');
        product.buyers.push(msg.sender);
    }

    function getBuyers(uint _id) public view returns (address[] memory) {
        return products[_id].buyers;
    }

    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getOwner(uint _id) public view returns (address) {
        return products[_id].owner;
    }

    function getTitle(uint _id) public view returns (string memory) {
        return products[_id].title;
    }

    function getDescription(uint _id) public view returns (string memory) {
        return products[_id].description;
    }

    function getPrice(uint _id) public view returns (uint) {
        return products[_id].price;
    }

    function getQuantity(uint _id) public view returns (uint) {
        return products[_id].quantity;
    }   

    function getImage(uint _id) public view returns (string memory) {
        return products[_id].image;
    }

    function getBuyersLength(uint _id) public view returns (uint) {
        return products[_id].buyers.length;
    }

    function getBuyer(uint _id, uint _buyerId) public view returns (address) {
        return products[_id].buyers[_buyerId];
    }

    function getBuyerCount(uint _id) public view returns (uint) {
        return products[_id].buyers.length;
    }

    function getBuyerAtIndex(uint _id, uint _buyerId) public view returns (address) {
        return products[_id].buyers[_buyerId];
    }

    function getBuyerCountAtIndex(uint _id) public view returns (uint) {
        return products[_id].buyers.length;
    }
}