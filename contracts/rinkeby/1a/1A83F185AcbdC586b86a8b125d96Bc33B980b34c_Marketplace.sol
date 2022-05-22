// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev ERC20 Standard Token interface
 */
interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}

/**
 * @title Marketplace
 * @dev Marketplace
 */
contract Marketplace {

    address private owner;
    IERC20 public immutable token;
    bool private locked;
    bool public paused;

    struct Product {
        string name; // name
        bool active;  // active
        uint256 stock; // stock
        uint256 price; // price in tokens
        uint256 maxPerUser; // max single product per user
    }

    struct User {
        uint256 totalSpend;
        mapping(uint256 => uint256) stockOwned;
        uint256[] ownedProducts;
    }

    mapping(address => User) public users;

    Product[] public products;
    
    // image
    // timestamp start / end
    // return array[]
    
    /*uint256[] public activeProducts;
        if(_active) {
            activeProducts.push(products.length-1);
        }*/

    // modifier to check if marketplace is paused
    modifier isPaused() {
        require(!paused, "Marketplace: paused");
        _;
    }

    // modifier to check if product is in stock
    modifier isStock(uint256 _productId, uint256 _amount) {
        require(products[_productId].stock - _amount > 0, "Product: out of stock");
        _;
    }

    // modifier to check if product is active
    modifier isActive(uint256 _productId) {
        require(products[_productId].active, "Product: inactive");
        _;
    }

    // modifier to check if limit is reached
    modifier isLimit(uint256 _productId, uint256 _amount) {
        require(users[msg.sender].stockOwned[_productId]+_amount < products[_productId].maxPerUser, "Product: limit for user is reached");
        _;
    }

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    // Modifiers can be called before and / or after a function.
    // This modifier prevents a function from being called while
    // it is still executing.
    modifier noReentrancy() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event CreateProduct(string indexed name, uint256 indexed stock, bool indexed active, uint256 price, uint256 maxPerUser);
    //event ChangeProduct(uint256 indexed productId, string indexed newValue);

    /**
     * @dev Set contract deployer as owner
     */
    constructor(IERC20 _token) {
        token = _token;
        paused = false;
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Create product
     * @param _name name of product
     * @param _active state of product
     * @param _stock state of stock
     * @param _price in tokens
     * @param _maxPerUser max single product per user
     */
    function createProduct(string memory _name, bool _active, uint256 _stock, uint256 _price, uint256 _maxPerUser) external isOwner {
        products.push(Product({
            name: _name,
            active: _active,
            stock: _stock,
            price: _price,
            maxPerUser: _maxPerUser
        }));
        emit CreateProduct(_name, _stock, _active, _price, _maxPerUser);
    }

    /**
     * @dev Buy product
     * @param _productId in array
     * @param _amount of product
     */
    function buy(uint256 _productId, uint256 _amount) public isActive(_productId) isStock(_productId, _amount) isLimit(_productId, _amount) isPaused noReentrancy {
        //require(token.transferFrom(msg.sender, owner, products[_productId].price * _amount), "Buy: transfert failed");

        users[msg.sender].totalSpend += products[_productId].price * _amount;
        
        if(users[msg.sender].stockOwned[_productId] == 0) {
            users[msg.sender].ownedProducts.push(_productId);
        }
        users[msg.sender].stockOwned[_productId] += _amount;

        products[_productId].stock -= _amount;
    }

    /**
     * @dev Change product name
     * @param _productId in array
     * @param _name of product
     */
    function changeProductName(uint256 _productId, string memory _name) external isOwner {
        products[_productId].name = _name;
    }

    /**
     * @dev Change product state
     * @param _productId in array
     * @param _active true or false
     */
    function changeProductState(uint256 _productId, bool _active) external isOwner {
        products[_productId].active = _active;
    }

    /**
     * @dev Change product stock
     * @param _productId in array
     * @param _stock of product
     */
    function changeProductStock(uint256 _productId, uint256 _stock) external isOwner {
        products[_productId].stock = _stock;
    }

    /**
     * @dev Change product price
     * @param _productId in array
     * @param _price of product
     */
    function changeProductPrice(uint256 _productId, uint256 _price) external isOwner {
        products[_productId].price = _price;
    }

    /**
     * @dev Change product maxPerUser
     * @param _productId in array
     * @param _maxPerUser of product
     */
    function changeProductUserLimit(uint256 _productId, uint256 _maxPerUser) external isOwner {
        products[_productId].maxPerUser = _maxPerUser;
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) external isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Pause markeplace
     */
    function pause() external isOwner {
        paused = true;
    }

    /**
     * @dev Unpause markeplace
     */
    function unpause() external isOwner {
        paused = false;
    }

    /**
     * @dev Return total of products
     * @return total
     */
    function getTotalProducts() external view returns (uint256) {
        return products.length;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    /**
     * @dev Return total spend by user
     * @return address of user
     */
    function getUserTotalSpend(address _user) external view returns (uint256) {
        return users[_user].totalSpend;
    }

    /**
     * @dev Return stock owned by user
     * @return amount of stock owned
     */
    function getUserStockOwned(address _user, uint256 _productId) external view returns (uint256) {
        return users[_user].stockOwned[_productId];
    }

    /**
     * @dev Return owned products by user
     * @return array of products owned
     */
    function getUserOwnedProducts(address _user) external view returns (uint256[] memory) {
        return users[_user].ownedProducts;
    }
}