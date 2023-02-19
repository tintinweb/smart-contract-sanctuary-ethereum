/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract SupplyChain {
  // Product Information
  struct Product {
    uint256 productID;
    string productName;
    string productDescription;
    uint256 productPrice;
    address owner;
    bool isAvailable;
    address certificationtoken;
    string cottontype;
  }

  mapping (uint256 => Product) public products;
  uint256 public productCounter;

  // Events
  event ProductCreated(uint256 productID, string productName, string productDescription, uint256 productPrice, address owner, address certificationtoken, string cottontype);
  event ProductSold(uint256 productID, address buyer);
  event ProductAvailabilityChanged(uint256 productID, bool isAvailable);

  // Functions
  function createProduct(string memory _productName, string memory _productDescription, uint256 _productPrice, address _certificationtoken, string memory _cottontype) public {
    productCounter++;
    products[productCounter] = Product(productCounter, _productName, _productDescription, _productPrice, msg.sender, true, _certificationtoken, _cottontype);
    emit ProductCreated(productCounter, _productName, _productDescription, _productPrice, msg.sender, _certificationtoken, _cottontype);
  }

  function sellProduct(uint256 _productID, address _buyer) public {
    Product storage product = products[_productID];
    require(product.isAvailable, "Product is not available for sale.");
    require(product.owner == msg.sender, "You are not the owner of this product.");
    product.isAvailable = false;
    product.owner = _buyer;
    emit ProductSold(_productID, _buyer);
    emit ProductAvailabilityChanged(_productID, false);
  }

  function changeProductAvailability(uint256 _productID, bool _isAvailable) public {
    Product storage product = products[_productID];
    require(product.owner == msg.sender, "You are not the owner of this product.");
    product.isAvailable = _isAvailable;
    emit ProductAvailabilityChanged(_productID, _isAvailable);
  }
}