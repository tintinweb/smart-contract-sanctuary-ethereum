// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// traer el paquete de chainlink para el API de ETH/USD desde GitHub (ver el .yaml)
// import "AggregatorV3Interface.sol";

// Can also use:
// Interface compile down to an ABI, they specifty what functions you can use of another contract
// Interfaces are a minimalistic view into another contract
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

// create a contract to be able to accept some type of payment
contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    // payable is to define a function that can pay with ethereum
    function fund() public payable {
        // define  a minimum of $1 USD
        uint256 minimumUSD = 1 * 10**18;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "you need to spend more than 1 USD"
        );

        // msg.sender is the sender of the function called
        // msg.value is the value send by the sender
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // getting external data:
    // smart contracts are unable to connnect with external systems, data feeds or APIs
    // A blockchain oracle: is any device that interacts with the off-chain world to provide
    // external data or computation of smart contracts

    // having a centralized oracle is a problem in case of failure, Chainlink solve this
    // by creating a descentralized oracle network for validation of external data

    // we want to know what the ETH -> USD conversion rate is

    function getVersion() public view returns (uint256) {
        // Address can be found in the eth price feed documentation of Chainlink
        // here we use ETH /USD address of Rinkeby Testnet

        // this line says: we have a contract with functions defined at interface "AggregatorV3Interface"
        // located a the ETH /USD address of Rinkeby Testnet
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        // Tuple: a list of objects of potentially different types whose number is a constant at compile-time
        // we ignore the other elements returned by the function because we only need the answer (the price)
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // cast int256 to uint256
        // multiply by 10000000000 to get the price in WEI
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    modifier onlyOwner() {
        // only want the contract owner can withdraw
        require(msg.sender == owner, "only the owner can withdraw");
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset funders array
        funders = new address[](0);
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