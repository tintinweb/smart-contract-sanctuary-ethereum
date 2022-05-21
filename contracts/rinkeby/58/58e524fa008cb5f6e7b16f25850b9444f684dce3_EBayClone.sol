/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity ^0.4.23;

contract EBayClone {
    struct Product {
        uint id;
        address seller;
        address buyer;
        string name;
        string description;
        uint price;
    }

    uint productCounter;
    mapping (uint => Product) public products;        

    function sellProduct(string _name, string _description, uint _price) public{
        //require(msg.sender != 0x0);
        
        Product memory newProduct = Product({
            id: productCounter,
            seller: msg.sender,
            buyer: 0x0,
            name: _name,
            description: _description,
            price: _price
        });
                
        products[productCounter] = newProduct;
        productCounter++;        
    }

    function getNumberOfProducts() public view returns (uint) {
        return productCounter;
    }
   
    function buyProduct (uint _id) payable public{
      Product storage product = products[_id];
      //require(product.seller != 0x0);
      require(product.buyer == 0x0); // article has not been bought
      require(msg.sender != product.seller); // buyer cannot be same as seller
      require(msg.value == product.price);
      product.buyer = msg.sender;
      product.seller.transfer(msg.value);
    }
}