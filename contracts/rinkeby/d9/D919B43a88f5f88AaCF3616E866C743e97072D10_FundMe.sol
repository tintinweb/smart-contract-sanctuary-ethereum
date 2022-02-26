// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.6 <0.9.0;

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        //here we want the minimum amount to send to be $50
        //here we are multiplying by 10^18 because we want the amount of USD to be in wei to keep things consistant
        uint256 minimumUSD = 50 * 10**18;

        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH for this transaction"
        );
        //To be able to send the amount of money in dolllars, we have to know what the ETH -> USD conversion rate is
        //here, the += means add and assignment, therefore it adds the right operand to the left operand and assigns the result to the left operand
        addressToAmountFunded[msg.sender] += msg.value;
        //adding thttps://shelleyandkyd.lpages.co/c/?gclid=Cj0KCQjw-_j1BRDkARIsAJcfmTFcj7trWzOOxcDxryTjomAOCCcw2PWewGP6FAGp7xQXBY6hgYoG69MaAoXuEALw_wcBhe user that funds the contract to the array (the funders array) for more easy withdrawals
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        //here we are saying what AggrevatorV3Inferface will be the type of
        //here we are alsoalso getting the data from https://docs.chain.link/docs/ethereum-addresses/ about what ETH/USD is
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        //here we have to wrap uint356 around answer because the return type is uint256 so we have to cast answer...
        //to be a uint256 type, not a int256 type
        return uint256(answer * 10000000000);
    }

    //in this function we are finding the conversion rate between ETH to USD (the amount of ethereum into USD)
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = ((ethPrice * ethAmount) / 1000000000000000000);
        return ethAmountInUSD;
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
        // return minimumUSD / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //in this function we are getting the money out of the function by withdrawing it
    address payable withdraw;

    function Withdraw() public payable onlyOwner returns (bool success) {
        uint256 amount = address(this).balance;
        withdraw.transfer(amount);
        return true;

        //this means that we have an index variable called funderIndex and its going ot start from 0, this loop is going to finish whenever funder index is greater than or equal to the length of the funders and every time a loop is finished 1 will be added to the funder index
        //also, and every time a peice of code in this for loop executes we're going to restart at the top
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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