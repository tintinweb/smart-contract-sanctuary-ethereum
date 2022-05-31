// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";
// interfaces compile down to ABI - Application Binary Interfaces, which tells solidity how it can
// interact with another contract
// Anytime you need to interact with a smart contract you will need adn ABI

// interfaces minimalisttic view into another contract


contract receiveRinkeby {

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    //accept payment
    // when we send or fund , now the contract is the owner of the funds
    // will fund a smartcontract whereever is deployed

    function contract_deploy() public payable {
        // $50
        uint256 minimumUSD = 50 * 10 ** 18;
        require(getConversionRate(msg.value) >= minimumUSD, "You need more eth");

        // 1 wei is the smallert denomination of ether
        // red button payable function

        //msg.sender and msg.value are key words in a contract
        addressToAmountFunded[msg.sender] += msg.value;

        funders.push(msg.sender);

        // ETH to USD conversion

    }

    function getVersion() public view returns (uint256) {
        // using constructor now... AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
       // using constructor  AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

        (uint80 roundId,
         int256 answer,
         uint256 startedAt,
         uint256 updateAt,
         uint80 answeredInRound) = priceFeed.latestRoundData();
         return uint256(answer * 10000000000) ; // multiply to change from wei to gwei
        // 197749555185 is 1,977.49555185
    }

    // 1000000000 one wei
    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
        // 1985980000000
    }

//     function withdraw() payable public {
//         require(msg.sender == owner);
//         payable(msg.sender).transfer(address(this).balance);
//    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    // modifier us used to change behavior of a function in a declarative way
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable onlyOwner public {

        payable(msg.sender).transfer(address(this).balance);

        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
   }
// acct 1   0xf6C0DBd210394ddFfDDBC4eac66E58c63a05A2bC
// acct 2   0xb96A132DB696eFBE7dd678239c14617486776Ce8
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