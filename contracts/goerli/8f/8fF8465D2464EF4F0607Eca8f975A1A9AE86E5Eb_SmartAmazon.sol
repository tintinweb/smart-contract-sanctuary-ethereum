// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SmartAmazon {
    address public owner;
    uint256 public productCounter;
    struct Product {
        uint256 id;
        string name;
        string description;
        string category;
        string image;
        uint256 rating;
        uint256 price;
        uint256 stock;
    }
    struct Order {
        uint256 time;
        Product products;
    }
    mapping(uint256 => Product) public products;
    mapping(address => Order[]) public orders;

    event AddProduct(string name, uint256 price, uint256 stock);
    event BuyProduct(address buyer, uint256 productId);

    error InvalidOwner(address from);
    error OnlyCustomerCanBuy(address from);
    error NotEnoughEthToBuy(uint256 eth);
    error ProductOutOfStock();
    error NotEnoughBalanceToWithdraw();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert InvalidOwner(msg.sender);
        }
        _;
    }
    modifier onlyCustomer() {
        if (msg.sender == owner) {
            revert OnlyCustomerCanBuy(msg.sender);
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addProduct(
        string memory name,
        string memory description,
        string memory category,
        string memory image,
        uint256 rating,
        uint256 price,
        uint256 stock
    ) public onlyOwner returns (uint256) {
        productCounter += 1;
        products[productCounter] = Product(
            productCounter,
            name,
            description,
            category,
            image,
            rating,
            price,
            stock
        );
        emit AddProduct(name, price, stock);
        return productCounter;
    }

    function buyProduct(uint256 _productId) public payable onlyCustomer {
        Product memory buyingProduct = products[_productId];
        if (msg.value < buyingProduct.price) {
            revert NotEnoughEthToBuy(msg.value);
        }
        if (buyingProduct.stock <= 0) {
            revert ProductOutOfStock();
        }
        orders[msg.sender].push(Order(block.timestamp, buyingProduct));
        buyingProduct.stock = buyingProduct.stock - 1;
        products[_productId] = buyingProduct;
        emit BuyProduct(msg.sender, _productId);
    }

    function withdraw() public onlyOwner {
        if (address(this).balance <= 0) {
            revert NotEnoughBalanceToWithdraw();
        }
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Not withdraw successfully");
    }
}