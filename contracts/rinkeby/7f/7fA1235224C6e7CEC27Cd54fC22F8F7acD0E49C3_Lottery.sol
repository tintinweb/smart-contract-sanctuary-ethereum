//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract Lottery {
    address payable[] public players;
    uint256 USD_entryfee;
    uint256 ticketCost;
    AggregatorV3Interface internal eth_usdPriceFeed;
    address[] tickets;
    address Owner;

    constructor(address _pf_address) public {
        USD_entryfee = 50 * (10**18);
        ticketCost = 2 * (10**18);
        eth_usdPriceFeed = AggregatorV3Interface(_pf_address);
        Owner = msg.sender;
        players.push(payable(Owner));
    }

    function enter() public payable {
        bool is_player = false;
        for (uint256 index = 0; index < players.length; index++) {
            if (msg.sender == players[index]) {
                is_player = true;
                break;
            }
        }

        require(
            is_player == false,
            "You are not a player yet! Enter the lottery first!"
        );

        // minimum 50$
        (uint256 condition, ) = getEntranceFee();
        require(msg.value >= condition);
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256, uint256) {
        (, int256 Price, , , ) = eth_usdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(Price) * 10**10;
        // Now we have 18 decimals since eth-usd priceFeed gives the feed in 8 decimals

        uint256 costToEnter = (USD_entryfee * 10**18) / adjustedPrice;
        uint256 ticket_cost_buy = (ticketCost * 10**18) / adjustedPrice;

        return (costToEnter, ticket_cost_buy);
    }

    function ticket_cost(uint256 _num_tickets) public view returns (uint256) {
        (, uint256 ticketcost) = getEntranceFee();
        return (_num_tickets * ticketcost);
    }

    function getTickets(uint256 _num_tickets) public payable {
        bool is_player = false;
        for (uint256 index = 0; index < players.length; index++) {
            if (msg.sender == players[index]) {
                is_player = true;
                break;
            }
        }

        require(
            is_player == true,
            "You are not a player yet! Enter the lottery first!"
        );

        (, uint256 _ticket_cost) = getEntranceFee();
        uint256 condition = _num_tickets * _ticket_cost;
        require(
            msg.value >= condition,
            "You have to spend more ETH for this many tickets. Check the ticket cost function to see how much!"
        );

        // write code here to see what happens after require condition == true
        for (uint256 count = 0; count < _num_tickets; count++) {
            tickets.push(msg.sender);
        }
    }

    function endLottery() public view returns (address[] memory) {
        return tickets;
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