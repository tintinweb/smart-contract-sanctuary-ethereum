/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Colexion {
    
    struct Product {
      address owner;
      string name;
      string imageURL;  
      string description;
      uint256 price;
      bool sold;
    }
    event Successfull(
      address owner ,
      uint256 price,
      bool sold
    );

    Product[] public products ;
    address payable owner;

    constructor() {
        owner = payable(msg.sender) ;
    }

    modifier onlyOwner(){
        require(msg.sender == owner) ;
        _;
    }

    function addProduct(string calldata _name, string calldata _imageURL, string calldata _description, uint256 _price)  public onlyOwner {
        products.push(Product(msg.sender, _name, _imageURL , _description , _price, false )) ;
    }

    function getProductsLength() public view returns (uint256) {
        return products.length;
    }

    function buyProduct(uint index) public payable{
        Product storage _product = products[index];
        uint Price = _product.price;
        require(msg.value == Price && _product.sold == false, "Price unmatched or sold");
        _product.sold = true;
        _product.owner = msg.sender;
        payable(owner).transfer(Price);

        emit Successfull(
         msg.sender,
         Price,
         true
        );    
    }

    function getProductArray() public view returns (Product[] memory) {
        return products;
    }
}