//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

contract NftPrice {
/*=========================== Events ========================== */
    event PriceSetted(address _collection, uint256 _price);
    event MultiPriceSetted(address[] _collections, uint256[] _prices);

/*=========================== State Variables ========================== */
    address public admin;
    mapping(address => uint256) private prices;

/*=========================== Modifiers ========================== */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Admin");
        _;
    }

/*=========================== Constructor ========================== */
    constructor (){
        admin = msg.sender;
    }

/*============================ External Functions ========================== */
    function updateCollectionPrice(address _collection, uint256 _price)
        external
        onlyAdmin
    {
        require(
            _collection != address(0),
            "Collection can not be address zero"
        );
        require(_price > 0, "price should be more than zero");

        prices[_collection] = _price;

        emit PriceSetted(_collection, _price);
    }

    function setBatchCollectionPrice(
        address[] calldata _collections,
        uint256[] calldata _prices
    ) external onlyAdmin {
        require(_collections.length == _prices.length, "Missing argument");
        require(_collections.length > 0, "Can not set zero argument");

        for (uint256 i = 0; i < _collections.length; i++) {
            prices[_collections[i]] = _prices[i];
        }

        emit MultiPriceSetted(_collections, _prices);
    }

    function deleteCollection (address _collection) external {
        delete prices[_collection];
    }

/*========================== Read Functions ========================== */
    function getPrice(address _collection)
        external
        view
        returns (uint256 _price)
    {
        require(prices[_collection] != 0,"No price information setted!");
        _price = prices[_collection];
    }

    function getTotalPrice(address[] calldata _collections) external view {
        uint256 _totalPrice;
        for(uint256 i = 0; i< _collections.length; i++){
            _totalPrice += prices[_collections[i]];
        }
    }
  
}