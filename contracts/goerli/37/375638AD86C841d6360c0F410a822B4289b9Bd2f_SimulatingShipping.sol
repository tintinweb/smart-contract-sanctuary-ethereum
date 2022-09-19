// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./EthToUsd.sol";

error NotOwner();
error ProductNotPresent();
error notEnoughUsd();

contract SimulatingShipping {
    using EthToUsd for uint256;

    enum STATUS {
        AVAILABLE,
        SOLD
    }

    struct Product {
        uint256 id;
        string name;
        string description;
        uint256 price;
        STATUS status;
    }

    Product[] private products;
    mapping(address => uint256) private s_addressToProduct;
    AggregatorV3Interface private s_priceFeed;
    address private immutable i_owner;

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    modifier onlyIfExists(uint256 _id) {
        bool isPresent = false;
        if (
            products.length == 0 ||
            products.length < _id ||
            products[_id - 1].status == STATUS.SOLD
        ) {
            revert ProductNotPresent();
        }
        _;
    }

    constructor(address _priceFeed) {
        s_priceFeed = AggregatorV3Interface(_priceFeed);
        i_owner = msg.sender;
    }

    function addNewProduct(
        string memory _name,
        string memory _description,
        uint256 _price
    ) public onlyOwner {
        Product memory newProduct = Product(
            products.length,
            _name,
            _description,
            _price,
            STATUS.AVAILABLE
        );
        products.push(newProduct);
    }

    function buyProduct(uint256 _id) public payable onlyIfExists(_id) {
        if (
            msg.value.getPriceConversion(s_priceFeed) < products[_id - 1].price
        ) {
            revert notEnoughUsd();
        }
        products[_id - 1].status = STATUS.SOLD;
        s_addressToProduct[msg.sender] = products[_id - 1].id;
    }

    function withdraw() public onlyOwner {
        (bool isCall, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(isCall, "Call failed");
    }

    function getAddressToProduct(address addr) public view returns (uint256) {
        return s_addressToProduct[addr];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    function getProduct(uint256 index) public view returns (Product memory) {
        return products[index];
    }

    function getProducts() public view returns (Product[] memory) {
        return products;
    }
    //	0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library EthToUsd {
    function getPriceConversion(
        uint256 priceWei,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 newPrice = uint256(price) * 1e10;
        return (priceWei * newPrice) / 1e18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}