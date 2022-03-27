/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {

    address public Owner;
    address[] public Funders;
    AggregatorV3Interface public PriceFeed;

    constructor(address PriceFeedAddress) {
        Owner = msg.sender;
        PriceFeed = AggregatorV3Interface(PriceFeedAddress);
    }

    modifier OwnerOnly {
        require(msg.sender == Owner);
        _;
    }

    mapping(address => uint256) public AddressToAmountFunded;

    function FundThisContract() public payable {
        AddressToAmountFunded[msg.sender] += msg.value;
        Funders.push(msg.sender);
    }
    
    function GetBalance() public view returns(uint256) {
        return AddressToAmountFunded[msg.sender];
    }

    function GetVersion() public view returns(uint256) {
        return PriceFeed.version();
    }

    function GetPrice() public view returns(uint256) {
        (,int256 answer,,,) = PriceFeed.latestRoundData();
        return uint256(answer * 10); // Returns in GWei
    }

    function GetEntranceFee() public view returns(uint256) {
        uint256 MinimumUSD = 50 * 10 ** 18;
        uint256 Price = GetPrice();
        uint256 Precision = 1 * 10 ** 18;
        uint256 EntranceFee = (MinimumUSD * Precision) / (Price * 10 ** 9);
        return EntranceFee;
    }

    function GetConversionRate(uint256 EthAmount) public view returns(uint256) { // EthAmount must be in WEI.
        uint256 EthPriceInUSD = GetPrice();
        uint256 EthAmountInUSD = (EthPriceInUSD * EthAmount);
        return EthAmountInUSD;
    }

    function GetDescription() public view returns(string memory) {
        return PriceFeed.description();
    }

    function GetAddressOfSender() public view returns(address) {
        return msg.sender;
    }

    function GetContractAddress() public view returns(address) {
        return address(this);
    }

    function GetContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function WithdrawAll() public payable OwnerOnly {
        payable(msg.sender).transfer(address(this).balance);

        for (uint256 FunderIndex = 0; FunderIndex < Funders.length; FunderIndex++) {
            address Funder = Funders[FunderIndex];
            AddressToAmountFunded[Funder] = 0;
        }

        Funders = new address[](0);
    }
}