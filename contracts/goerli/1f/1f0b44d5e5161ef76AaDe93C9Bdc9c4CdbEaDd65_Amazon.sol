// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error Amazon__NotEnoughETH();
error Amazon__NotEnoughStock();
error Amazon__NotGreaterThanTwoETH();
error Amazon__OnlySellerCanUpdate();

contract Amazon {
    address public immutable i_owner;
    uint256 private s_ID = 0;

    // The Product DataType.
    struct Product {
        uint256 id;
        string name;
        string category;
        string image;
        string description;
        uint256 rating;
        uint256 cost;
        uint256 stock;
        address seller;
    }

    // The Order DataType.
    struct Order {
        uint256 time;
        Product item;
    }

    mapping(address => uint256[]) private s_sellers;
    mapping(address => uint256) private s_payments;
    mapping(uint256 => Product) private s_items;
    mapping(address => mapping(uint256 => Order)) private s_orders;
    mapping(address => uint256) private s_orderCount;

    event Buy(address buyer, uint256 orderId, uint256 itemId);
    event Update(uint256 itemId, string name, uint256 cost, uint256 quantity);
    event List(uint256 itemId, string name, uint256 cost, uint256 quantity);

    constructor() {
        i_owner = msg.sender;
    }

    function createProduct(
        string memory _name,
        string memory _category,
        string memory _image,
        string memory _description,
        uint256 _cost,
        uint256 _stock
    ) public {
        s_ID++;
        // Create Product
        Product memory item = Product(
            s_ID,
            _name,
            _category,
            _image,
            _description,
            0,
            _cost,
            _stock,
            msg.sender
        );

        // Add seller to mapping
        s_sellers[msg.sender].push(s_ID);

        // Add Product to mapping
        s_items[s_ID] = item;

        // Emit event
        emit List(item.id, _name, _cost, _stock);
    }

    function buy(uint256 _id, uint256 rating) public payable {
        // Fetch item
        Product memory item = s_items[_id];

        // Require enough ether to buy item
        if (msg.value < item.cost) {
            revert Amazon__NotEnoughETH();
        }

        // Require item is in stock
        if (item.stock < 0) {
            revert Amazon__NotEnoughStock();
        }

        // Create order
        Order memory order = Order(block.timestamp, item);

        // Add order for user
        s_orderCount[msg.sender]++; // <-- Order ID
        s_orders[msg.sender][s_orderCount[msg.sender]] = order;

        // Subtract stock
        s_items[_id].stock = item.stock - 1;

        // Add Rating
        uint256 previousRating = s_items[_id].rating;
        if (previousRating == 0) {
            s_items[_id].rating = rating;
        } else {
            s_items[_id].rating = (previousRating + rating) / 2;
        }

        // Update the Pay of Seller
        s_payments[item.seller] += item.cost;

        // Emit event
        emit Buy(msg.sender, s_orderCount[msg.sender], item.id);
    }

    function withdraw() public {
        if (s_payments[msg.sender] < 2) {
            revert Amazon__NotGreaterThanTwoETH();
        }

        (bool success, ) = msg.sender.call{value: s_payments[msg.sender]}("");
        require(success);

        s_payments[msg.sender] = 0;
    }

    function updateProduct(
        uint256 id,
        string memory _name,
        string memory _category,
        string memory _image,
        string memory _description,
        uint256 _cost,
        uint256 _stock
    ) public {
        if (id > s_ID && msg.sender == s_items[id].seller) {
            revert Amazon__OnlySellerCanUpdate();
        }

        Product memory item = s_items[id];
        item.name = _name;
        item.category = _category;
        item.image = _image;
        item.description = _description;
        item.cost = _cost;
        item.stock = _stock;

        // Add Product to mapping
        s_items[id] = item;

        // Emit event
        emit Update(item.id, _name, _cost, _stock);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getLatestProduct() public view returns (Product memory) {
        return s_items[s_ID];
    }

    function getID() public view returns (uint256) {
        return s_ID;
    }

    function getProduct(uint256 id) public view returns (Product memory) {
        return s_items[id];
    }

    function getOrderCount(address addr) public view returns (uint256) {
        return s_orderCount[addr];
    }

    function getOrder(address addr, uint256 id) public view returns (Order memory) {
        return s_orders[addr][id];
    }

    function getPay(address addr) public view returns (uint256) {
        return s_payments[addr];
    }

    function getAllProducts() public view returns (Product[] memory) {
        Product[] memory products = new Product[](s_ID);
        for (uint i = 0; i < s_ID; i++) {
            products[i] = s_items[i];
        }
        return products;
    }

    function getSellerProducts(address addr) public view returns (uint256[] memory) {
        return s_sellers[addr];
    }
}