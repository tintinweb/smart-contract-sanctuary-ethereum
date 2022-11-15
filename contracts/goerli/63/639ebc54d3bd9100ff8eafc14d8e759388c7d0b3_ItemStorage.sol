/**
 *Submitted for verification at Etherscan.io on 2022-11-15
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


pragma solidity ^0.8.17;


contract ItemStorage {

    struct Item {
        uint id;
        string nameOfItem;
        string value;
        uint lastUpdated;
    }
    Item[] itemsList;
    address owner = 0xD31B40ED3989DCC8145336249cE70Fdc73A3fE5c;
    int public times_called = 0;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    AggregatorV3Interface internal priceFeed;
    constructor() {
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }


    function getItems(uint _startDate, uint _endDate) public returns (Item[] memory) {

        times_called ++;
        uint length = 0;
        for(uint i = 0; i < itemsList.length; i++){
            if(itemsList[i].lastUpdated >= _startDate && itemsList[i].lastUpdated <= _endDate){
                length++;
            }
        }

        Item[] memory returnedItems = new Item[](length);

        for(uint i = 0; i < itemsList.length; i++){
            if(itemsList[i].lastUpdated >= _startDate && itemsList[i].lastUpdated <= _endDate){
                returnedItems[i]=itemsList[i];
            }
        }
        return returnedItems;
    }

    function createItem(string memory _nameOfItem, string memory _value) public returns (string memory) {
        // Check if the address is of the owner of the contract
        require (owner == msg.sender);

        Item memory item = Item({id: itemsList.length, nameOfItem: _nameOfItem, value: _value, lastUpdated: block.timestamp });
        itemsList.push(item);
        return "Item added";
    }

    // Oracle test! (gives eth price in usd)
    function getLatestPrice() public view returns (int) {
        (,int price,,,) = priceFeed.latestRoundData();
        return price;
    }
}