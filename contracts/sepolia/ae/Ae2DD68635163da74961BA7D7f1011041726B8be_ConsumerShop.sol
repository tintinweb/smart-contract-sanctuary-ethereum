//SPDX-License-Identifier: MIT
//Omar ALHABSHI -- 2023
pragma solidity ^0.8.4;

contract ConsumerShop {
    //maximum purchase per transaction
    uint constant MAX_PURCHASE = 1;
    //stores the owner of the contract
    address owner;
    //define the properties of a Product
    struct Product {
        uint sku;
        string name;
        string image;
        string description;
        uint price;
        uint quantityAvailable;
        uint quantitySold;
    }

    //stores all products that have been created
    Product[] public products;

    //restrict access to only the owner of the contract
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    //@dev event to be emitted when a new product is created
    event ProductCreated(
        uint indexed index,
        uint indexed sku,
        string name,
        string image,
        string description,
        uint quantityAvailable,
        uint price
    );

    // event to be emitted when a product is sold
    event ProductSold(
        uint indexed index,
        uint indexed sku,
        uint quantitySold,
        uint totalQuantitySold,
        uint newQuantityAvailable
    );

    constructor() {
        //set the owner of the contract to the address that deployed the contract
        owner = msg.sender;
    }

    /**
     *returns the number of products listed
     */
    function numberOfProducts() external view returns (uint) {
        return products.length;
    }

    /**
     *@dev creates a new product and adds it to the `products` array
     * restrict access to the owner of the contract using `onlyOwner` modifier
     *@param _sku - a unique ID for product
     *@param _image - a url of product image
     *@param _description - a label or short description of the product
     *@param _price - price at which the product will be sold
     *@param _quantityAvailable - quantity of products available for sale
     */
    function createProduct(
        uint _sku,
        string memory _name,
        string memory _image,
        string memory _description,
        uint _price,
        uint _quantityAvailable
    ) public onlyOwner {
        // we make some assumption that information on sku, name, and price
        // are the least requirements of a product
        require(_sku > 0, "SKU is required");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(_price > 0, "Product price must be greater than 0");
        require(_quantityAvailable > 0, "Product quantity must be one or more");

        //make a new product using the key-value pair approach
        //and push into the products array
        products.push(
            Product({
                sku: _sku,
                name: _name,
                image: _image,
                description: _description,
                price: _price,
                quantityAvailable: _quantityAvailable,
                quantitySold: 0
            })
        );

        //emit a `ProductCreated` event to log to the blockchain
        emit ProductCreated(
            products.length,
            _sku,
            _name,
            _image,
            _description,
            _quantityAvailable,
            _price
        );
    }

    /**
     *@dev `buyProduct` allows a user to buy a product per transaction
     *@param index - index of the product in the `products` array
     */
    function buyProduct(uint index) external payable {
        //make sure the index is within range of the array
        require(index <= products.length - 1, "Index is out of range");
        //get the product
        Product storage product = products[index];
        //make sure that the amount sent by the user is enough
        require(msg.value >= product.price, "Amount sent is not enough");

        //make sure there is a product to buy
        require(product.quantityAvailable >= 1, "Product is out of stock");

        //reduce product quantityAvailable by 1
        product.quantityAvailable -= MAX_PURCHASE;
        //increase product quatitySold by 1
        product.quantitySold += MAX_PURCHASE;

        //emit a `ProductSold` event to log to the blockchain
        emit ProductSold(
            index,
            product.sku,
            MAX_PURCHASE,
            product.quantitySold,
            product.quantityAvailable
        );
    }

    //@dev additional functionality to withdraw funds, and update product information
    //Yet the object here is to demonstract events in solidity so we stick to it.

    //enable our contract to receive ether
    receive() external payable {}

    fallback() external payable {}
}