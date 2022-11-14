/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// File: test.sol

/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

pragma solidity ^0.8.17;


contract Helloworld {
    AggregatorV3Interface internal priceFeed;

    struct Item {
        uint id;
        string nameOfItem;
        string value;
    }
    Item[] itemsList;
    address owner = 0x3F1d308983c2dD2A0f51875eab4A827ce22588cF;
    int times_called = 0;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }


    function getItems() public returns (Item[] memory) {
        times_called += 1;
        return itemsList;
    }

    
    function createItem(string memory _nameOfItem, string memory _value) public returns (string memory) {
        // Get the address of the owner of the contract
        if (owner == msg.sender) {
            Item memory item = Item({id: itemsList.length, nameOfItem: _nameOfItem, value: _value });
            itemsList.push(item);
            return "Item added";
        }
        else {
            revert("You are not the owner of the contract");
        }
    }


    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }


}