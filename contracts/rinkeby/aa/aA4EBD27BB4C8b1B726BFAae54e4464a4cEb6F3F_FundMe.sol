// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    address payable public owner;
    address[] public funders;
    AggregatorV3Interface public price_feed;

    constructor(address _price_feed) {
        price_feed = AggregatorV3Interface(_price_feed);
        owner = payable(msg.sender);
    }

    mapping(address => uint256) public address_to_balance;

    function fund() public payable {
        uint256 minETH = 50 * 10**18; //$50 in WEI terms
        require(ETH_to_USD_conversion(msg.value) > minETH, "SEND MORE ETH!");
        address_to_balance[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    modifier Owner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable Owner {
        owner.transfer(address(this).balance);
        for (uint16 i = 0; i < funders.length; i++) {
            address f = funders[i];
            address_to_balance[f] = 0;
        }
        funders = new address[](0);
    }

    function current_balance() public view returns (uint256) {
        return address(this).balance;
    }

    function getVersion() public view returns (uint256) {
        return price_feed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = price_feed.latestRoundData();
        //we can leave empty space when returning tuples so that we dont have uninitialized mem
        //here we only need the int256 answer so we leave the others empty

        return uint256(answer * 10000000000);
        //here we convert the price to WEI terms so we can keep the same unit throughout the contract
    }

    function ETH_to_USD_conversion(uint256 ETH) public view returns (uint256) {
        return (ETH * getPrice()) / 1000000000000000000;
        //we divide by this huge number because the getPrice returns the USD rate in WEI terms
    }
}

// SPDX-License-Identifier: MIT
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