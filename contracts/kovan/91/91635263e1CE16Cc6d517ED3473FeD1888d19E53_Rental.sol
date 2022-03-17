/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: Rental.sol

contract Rental {
    address creator;
    Item[] public itemList;
    address ownerAccount;
    mapping(string => address) public itemsToOwner;

    constructor() public {
        creator = msg.sender;
    }

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

    struct Item {
        uint256 id;
        string name;
        address ownerAddress;
        uint256 priceUSD;
    }

    function createItem(
        string memory _name,
        address _ownerAddress,
        uint256 _priceUSD
    ) public returns (bool success) {
        uint256 _id = itemList.length + 1;
        itemList.push(
            Item({
                id: _id,
                name: _name,
                ownerAddress: _ownerAddress,
                priceUSD: _priceUSD
            })
        );
        itemsToOwner[_name] = _ownerAddress;
        return true;
    }

    function transferItem(
        uint256 _itemId,
        address payable _prevOwner,
        address _newOwner
    ) public payable returns (uint256) {
        for (uint256 i = 0; i < itemList.length; i++) {
            if (
                itemList[i].id == _itemId &&
                itemList[i].ownerAddress == _prevOwner
            ) {
                itemList[i].ownerAddress = _newOwner;
                itemsToOwner[itemList[i].name] = _newOwner;
                getConversionRate(msg.value);
                _prevOwner.transfer(msg.value);
            }
        }
        return itemList.length;
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getETHPrice();
        return (ethAmount * ethPrice) / 1000000000000000000;
    }

    function getETHPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        (, int256 result, , , ) = priceFeed.latestRoundData();
        return uint256(result * 10000000000); //2702
    }
}