// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
    Interfaces compile down to ABI (Application Binary Interface)
    ABI tells solidity how to interact with other contracts.
*/

// This is an interface that we are importing from NPM/Github
// import "AggregatorV3Interface.sol";

import "AggregatorV3Interface.sol";

/*
    Conversions
    1 Ether = 10**18 wei
    1 gwei = 10**9 wei
    1 wei  = 1 wei
*/
contract FundMe {
    address public owner;

    constructor() public {
        // Set the owner of this ccontract to the first sender jo ki mai he hun
        owner = msg.sender;
    }

    mapping(address => uint256) public addressToAmountFunded;
    uint256 public total = 0;

    address[] funders;

    function fund() public payable {
        // 18 digit number to be compared with donated amount
        uint256 minimumUSD = 5 * 10**18;
        //is the donated amount less than 50USD?
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );

        //if not, add to mapping and funders array
        addressToAmountFunded[msg.sender] += msg.value;
        total += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // https://docs.chain.link/docs/ethereum-addresses/
        // Address is for Rinkeby chain ETH/USD pair
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );

        // Tuple destructuring
        // (
        //     uint80 roundId,
        //     int256 answer,
        //     uint256 startedAt,
        //     uint256 updatedAt,
        //     uint80 answeredInRound
        // ) =  priceFeed.latestRoundData();

        // Tuple destructuring  improved
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        // converting ETH/USD rate in 18 digit or in wei
        // 10 0's
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        // ethAmount is given in Ether
        uint256 ethPrice = getPrice();

        // 18 0's
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }

    // Method 2 of preventing unath access
    modifier onlyOwner() {
        require(msg.sender == owner);

        // Contine the rest of the code after this _;
        _;
    }

    function withdraw() public payable onlyOwner {
        // Method 1 of preventing unauth access
        // require(msg.sender == owner);

        msg.sender.transfer(address(this).balance);

        // Resetting funders amounts
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // Create a new arrray which will reset the funders list
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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