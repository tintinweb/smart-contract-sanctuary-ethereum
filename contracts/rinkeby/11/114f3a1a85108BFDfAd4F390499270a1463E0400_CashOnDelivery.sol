//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error AlreadyListed(uint256 _productId, uint256 _productPrice);
error NotRegistered(uint256 _productId, uint256 _productPrice);
error NotOwner();
error PriceMustBeAboveZero();
error GiveCorrectPrice(uint256 _productId, uint256 _productPrice);
error NoMoneyForSeller();

contract CashOnDelivery {
    enum DeliveryState {
        noOrder,
        orderTaken,
        delivered
    }

    struct ProductRegistration {
        uint256 _price;
        address _sellerAddress;
    }

    event ProductRegistered(address indexed _seller, uint256 indexed _prouctId, uint256 _price);
    event OrderTaken(address indexed _buyer, uint256 indexed _productId, uint256 indexed _price);
    event Delivered(address indexed _buyer, uint256 _productId, uint256 _price);

    mapping(uint256 => ProductRegistration) private s_products;
    mapping(address => uint256) private s_sellersMoney;
    DeliveryState private s_deliveryState;

    modifier notRegistered(
        address _seller,
        uint256 _productId,
        uint256 _productPrice
    ) {
        ProductRegistration memory _productRegistration = s_products[_productId];
        if (_productRegistration._price > 0) {
            revert AlreadyListed(_productId, _productPrice);
        }
        _;
    }

    modifier isRegistered(uint256 _productId, uint256 _productPrice) {
        ProductRegistration memory _productRegistration = s_products[_productId];
        if (_productRegistration._price <= 0) {
            revert NotRegistered(_productId, _productPrice);
        }
        _;
    }

    modifier isOwner(uint256 _productId, uint256 _productPrice) {
        ProductRegistration memory _productRegistration = s_products[_productId];
        if (_productRegistration._sellerAddress != msg.sender) {
            revert NotOwner();
        }
        _;
    }

    constructor() {
        s_deliveryState = DeliveryState.noOrder;
    }

    function registerProduct(uint256 _productId, uint256 _productPrice)
        external
        notRegistered(msg.sender, _productId, _productPrice)
    {
        s_products[_productId] = ProductRegistration(_productPrice, msg.sender);
        emit ProductRegistered(msg.sender, _productId, _productPrice);
    }

    function updatePrice(
        uint256 _productId,
        uint256 _newPrice,
        uint256 _lastPrice
    ) external isRegistered(_productId, _lastPrice) isOwner(_productId, _lastPrice) {
        if (_newPrice <= 0) {
            revert PriceMustBeAboveZero();
        }
        s_products[_productId]._price = _newPrice;
        emit ProductRegistered(msg.sender, _productId, _newPrice);
    }

    function placeOrder(uint256 _productId, uint256 _productPrice) external {
        ProductRegistration memory _productRegistration = s_products[_productId];
        if (_productPrice < _productRegistration._price) {
            revert GiveCorrectPrice(_productId, _productRegistration._price);
        }
        emit OrderTaken(msg.sender, _productId, _productPrice);
        s_deliveryState = DeliveryState.orderTaken;
    }

    function buyTheProduct(uint256 _productId, uint256 _productPrice) external payable {
        ProductRegistration memory _productRegistration = s_products[_productId];
        if (_productPrice < _productRegistration._price) {
            revert GiveCorrectPrice(_productId, _productRegistration._price);
        }
        if (msg.value < _productRegistration._price) {
            revert GiveCorrectPrice(_productId, _productRegistration._price);
        }
        s_sellersMoney[_productRegistration._sellerAddress] += msg.value;
        emit Delivered(msg.sender, _productId, _productPrice);
    }

    function withdrawSellerMoney() external {
        uint256 _money = s_sellersMoney[msg.sender];
        if (_money <= 0) {
            revert NoMoneyForSeller();
        }
        s_sellersMoney[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: _money}("");
        require(success, "Transaction failed");
    }

    function knowTheProducts(uint256 _productId)
        external
        view
        returns (ProductRegistration memory)
    {
        return s_products[_productId];
    }

    function knowTheSellerMoney(address _seller) external view returns (uint256) {
        return s_sellersMoney[_seller];
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}