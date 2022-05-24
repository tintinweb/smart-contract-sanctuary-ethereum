// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev ERC721 Standard NFT interface
 */
interface ERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

/**
 * @dev ERC20 Standard Token interface
 */
interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

/**
 * @title Marketplace
 * @dev Marketplace
 */
contract MarketplaceERC20 {

    address private owner;
    ERC20 public immutable token;
    bool private locked;
    bool public paused;

    struct Product {
        string name; // name
        string image; // image
        bool active;  // active
        uint256 start; // start
        uint256 end; // end
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

    uint256[] public activeProductIds;

    Product[] public products;

    // modifier to check if marketplace is paused
    modifier isPaused() {
        require(!paused, "Marketplace: paused");
        _;
    }

    // modifier to check if product is available
    modifier isTime(uint256 _productId) {
        if(products[_productId].start != 0) {
            require(block.timestamp > products[_productId].start, "Product: sale not started");
        }
        if(products[_productId].end != 0) {
            require(block.timestamp < products[_productId].end, "Product: sale ended");
        }
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
    modifier isLimit(uint256 _productId, uint256 _amount, address _user) {
        require(users[_user].stockOwned[_productId]+_amount < products[_productId].maxPerUser, "Product: limit for user is reached");
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
    event CreateProduct(string indexed name, uint256 indexed stock, bool indexed active, uint256 price, uint256 maxPerUser, string image, uint256 start, uint256 end);

    /**
     * @dev Set contract deployer as owner
     */
    constructor(ERC20 _token) {
        token = _token;
        paused = false;
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Create product
     * @param _name name of product
     * @param _image image of product
     * @param _active state of product
     * @param _start state of product
     * @param _end state of product
     * @param _stock state of stock
     * @param _price in tokens
     * @param _maxPerUser max single product per user
     */
    function createProduct(string memory _name, string memory _image, bool _active, uint256 _start, uint256 _end, uint256 _stock, uint256 _price, uint256 _maxPerUser) external isOwner {
        if(_active) {
            activeProductIds.push(products.length);
        }
        products.push(Product({
            name: _name,
            image: _image,
            active: _active,
            start: _start,
            end: _end,
            stock: _stock,
            price: _price,
            maxPerUser: _maxPerUser
        }));
        emit CreateProduct(_name, _stock, _active, _price, _maxPerUser, _image, _start, _end);
    }

    /**
     * @dev Buy product
     * @param _productId in array
     * @param _amount of product
     */
    function buy(uint256 _productId, uint256 _amount) public noReentrancy isPaused isActive(_productId) isTime(_productId) isStock(_productId, _amount) isLimit(_productId, _amount, msg.sender) {
        require(token.transferFrom(msg.sender, owner, products[_productId].price * _amount), "Buy: transfert failed");

        users[msg.sender].totalSpend += products[_productId].price * _amount;
        
        if(users[msg.sender].stockOwned[_productId] == 0) {
            users[msg.sender].ownedProducts.push(_productId);
        }
        users[msg.sender].stockOwned[_productId] += _amount;

        products[_productId].stock -= _amount;
    }

    /**
     * @dev Buy product for address
     * @param _productId in array
     * @param _amount of product
     * @param _to owner
     */
    function buyFor(uint256 _productId, uint256 _amount, address _to) public noReentrancy isPaused isActive(_productId) isTime(_productId) isStock(_productId, _amount) isLimit(_productId, _amount, _to) {
        require(token.transferFrom(msg.sender, owner, products[_productId].price * _amount), "Buy: transfert failed");

        users[msg.sender].totalSpend += products[_productId].price * _amount;

        if(users[_to].stockOwned[_productId] == 0) {
            users[_to].ownedProducts.push(_productId);
        }
        users[_to].stockOwned[_productId] += _amount;

        products[_productId].stock -= _amount;
    }

    /**
     * @dev Withdraw tokens of smart contract.
     * @param _token address.
     * @param _amount of token.
     */
    function ownerWithdrawToken(address _token, uint256 _amount) public isOwner {
        ERC20(_token).transfer(msg.sender, _amount);
    }

    /**
     * @dev Withdraw nfts of smart contract.
     * @param _token address.
     * @param _tokenId of token.
     */
    function ownerWithdrawNFT(address _token, uint256 _tokenId) public isOwner {
        ERC721(_token).transferFrom(address(this), msg.sender, _tokenId);
    }

    /**
     * @dev Delete last pushed active products
     */
    function deleteLastActiveProduct() public isOwner {
        activeProductIds.pop();
    }

    /**
     * @dev Change product
     * @param _productId of product
     * @param _name name of product
     * @param _image image of product
     * @param _active state of product
     * @param _start state of product
     * @param _end state of product
     * @param _stock state of stock
     * @param _price in tokens
     * @param _maxPerUser max single product per user
     */
    function changeProduct(uint256 _productId, string memory _name, string memory _image, bool _active, uint256 _start, uint256 _end, uint256 _stock, uint256 _price, uint256 _maxPerUser) external isOwner {
        if(products[_productId].active == !_active) {
            if(_active){
                activeProductIds.push(_productId);
            } else {
                for (uint256 i; i < activeProductIds.length; i++) {
                    if (activeProductIds[i] == _productId) {
                        activeProductIds[i] = activeProductIds[activeProductIds.length - 1];
                        activeProductIds.pop();
                        break;
                    }
                }
            }
        }
        products[_productId].name = _name;
        products[_productId].image = _image;
        products[_productId].active = _active;
        products[_productId].start = _start;
        products[_productId].end = _end;
        products[_productId].stock = _stock;
        products[_productId].price = _price;
        products[_productId].maxPerUser = _maxPerUser;
    }

    /**
     * @dev Change product name
     * @param _productId in array
     * @param _name of product
     */
    function changeProductName(uint256 _productId, string memory _name) public isOwner {
        products[_productId].name = _name;
    }

    /**
     * @dev Change product image
     * @param _productId in array
     * @param _image of product
     */
    function changeProductImage(uint256 _productId, string memory _image) public isOwner {
        products[_productId].image = _image;
    }

    /**
     * @dev Change product state
     * @param _productId in array
     * @param _active true or false
     */
    function changeProductState(uint256 _productId, bool _active) public isOwner {
        if(products[_productId].active == !_active) {
            if(_active){
                activeProductIds.push(_productId);
            } else {
                for (uint256 i; i < activeProductIds.length; i++) {
                    if (activeProductIds[i] == _productId) {
                        activeProductIds[i] = activeProductIds[activeProductIds.length - 1];
                        activeProductIds.pop();
                        break;
                    }
                }
            }
        }
        products[_productId].active = _active; 
    }

    /**
     * @dev Change product start
     * @param _productId in array
     * @param _time in timestamp
     */
    function changeProductStart(uint256 _productId, uint256 _time) public isOwner {
        products[_productId].start = _time;
    }

    /**
     * @dev Change product end
     * @param _productId in array
     * @param _time in timestamp
     */
    function changeProductEnd(uint256 _productId, uint256 _time) public isOwner {
        products[_productId].end = _time;
    }

    /**
     * @dev Change product stock
     * @param _productId in array
     * @param _stock of product
     */
    function changeProductStock(uint256 _productId, uint256 _stock) public isOwner {
        products[_productId].stock = _stock;
    }

    /**
     * @dev Change product price
     * @param _productId in array
     * @param _price of product
     */
    function changeProductPrice(uint256 _productId, uint256 _price) public isOwner {
        products[_productId].price = _price;
    }

    /**
     * @dev Change product maxPerUser
     * @param _productId in array
     * @param _maxPerUser of product
     */
    function changeProductUserLimit(uint256 _productId, uint256 _maxPerUser) public isOwner {
        products[_productId].maxPerUser = _maxPerUser;
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Pause markeplace
     */
    function pause() public isOwner {
        paused = true;
    }

    /**
     * @dev Unpause markeplace
     */
    function unpause() public isOwner {
        paused = false;
    }

    /**
     * @dev Return total of products
     * @return total
     */
    function getTotalProducts() public view returns (uint256) {
        return products.length;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() public view returns (address) {
        return owner;
    }

    /**
     * @dev Return total spend by user
     * @return total spend by user
     */
    function getUserTotalSpend(address _user) public view returns (uint256) {
        return users[_user].totalSpend;
    }

    /**
     * @dev Return total active products
     * @return total active products
     */
    function getTotalActiveProduct() public view returns (uint256) {
        return activeProductIds.length;
    }

    /**
     * @dev Return stock owned by user
     * @return amount of stock owned
     */
    function getUserStockOwned(address _user, uint256 _productId) public view returns (uint256) {
        return users[_user].stockOwned[_productId];
    }

    /**
     * @dev Return owned products by user
     * @return array of products owned
     */
    function getUserOwnedProducts(address _user) public view returns (uint256[] memory) {
        return users[_user].ownedProducts;
    }

    /**
     * @dev Return active products
     * @return array of active products
     */
    function getActiveProducts() public view returns (Product[] memory) {
      Product[] memory activeProducts = new Product[](activeProductIds.length);
      
      for (uint i = 0; i < activeProductIds.length; i++) {
          Product storage product = products[i];
          activeProducts[i] = product;
      }

      return activeProducts;
    }
}