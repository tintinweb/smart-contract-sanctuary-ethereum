/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library StoreLib {
    function find(uint256[] storage _array, uint256 x)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_array[i] == x) {
                return true;
            }
        }
        return false;
    }

    function compareStrings(string memory _stringA, string memory _stringB)
        external
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_stringA)) ==
            keccak256(abi.encodePacked(_stringB));
    }
}

contract Store {
    // Create owner
    //uint public numberOfProducts;
    address payable private immutable admin;
    address[] private clientAddresses;

    struct Product {
        uint256 id;
        string name;
        uint256 price;
        uint256 quantity;
        uint256 blockNumber;
        address payable owner;
    }

    mapping(uint256 => Product) public products;
    Product[] public ownedProducts;
    Product[] private viewProducts;

    constructor() {
        admin = payable(msg.sender);
        //numberOfProducts = 0;
    }

    receive() external payable {} // Fallback

    modifier AdminOnly() {
        require(msg.sender == admin, "This action isn't allowed");
        _;
    }

    event NewProductLog(
        uint256 id,
        string name,
        uint256 price,
        uint256 quantity,
        uint256 blockNumber,
        address indexed owner
    );
    event BuyProductLog(
        uint256 id,
        string name,
        uint256 price,
        uint256 quantity,
        uint256 blockNumber,
        address indexed purchasedBy
    );

    function createProduct(
        string calldata _name,
        uint256 _price,
        uint256 _quantity
    ) external AdminOnly {
        uint256 productId = createId(_name, msg.sender);

        require(bytes(_name).length > 0, "The name is not valid");
        require(_price > 0, "The price is not valid");

        products[productId].id = productId;
        products[productId].name = _name;
        products[productId].price = _price;
        products[productId].quantity = products[productId].quantity + _quantity;
        products[productId].blockNumber = block.number;
        products[productId].owner = payable(msg.sender);
        viewProducts.push(products[productId]);
        emit NewProductLog(
            productId,
            _name,
            _price,
            _quantity,
            block.number,
            msg.sender
        );
    }

    function createId(string memory _string, address _address)
        private
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(_string, _address)));
    }

    function buyProductsID(uint256 _id) external payable {
        require(products[_id].quantity == 0, "The product is out of stock");
        products[_id].quantity = products[_id].quantity - 1;

        ownedProducts.push(
            Product({
                id: products[_id].id,
                name: products[_id].name,
                price: products[_id].price,
                quantity: 1,
                blockNumber: block.number,
                owner: payable(msg.sender)
            })
        );

        clientAddresses.push(msg.sender);
        emit BuyProductLog(
            products[_id].id,
            products[_id].name,
            products[_id].price,
            products[_id].quantity,
            products[_id].blockNumber,
            msg.sender
        );
    }

    function returnProduct(uint256 _index) external returns (bool success) {
        require(ownedProducts.length > 0, "You don't own any products");

        Product storage _owned = ownedProducts[_index];
        Product storage _product = products[_owned.id];

        require(
            block.number - ownedProducts[_index].blockNumber >= 100,
            "You cannot return the product anymore"
        );

        _product.quantity = _product.quantity + _owned.quantity;
        _product.owner = admin;

        delete ownedProducts[_index];

        // remove clientAddresses when product is returned
        return true;
    }

    function viewProduct(uint256 _index)
        external
        view
        returns (
            uint256 id,
            string memory name,
            uint256 price
        )
    {
        Product memory product = viewProducts[_index];
        return (product.id, product.name, product.price);
    }

    function viewAllPurchasesByClientAddresses()
        public
        view
        returns (address[] memory)
    {
        return clientAddresses;
    }

    function withdrawFunds(uint256 _amount) external AdminOnly {
        admin.transfer(_amount);
    }

    function storeBalance() external view AdminOnly returns (uint256) {
        return address(this).balance;
    }
}