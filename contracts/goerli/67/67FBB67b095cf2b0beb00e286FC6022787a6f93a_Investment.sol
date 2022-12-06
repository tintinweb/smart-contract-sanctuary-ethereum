// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Investment {
    AggregatorV3Interface pricefeed;

    mapping(address => uint256) addressAmountFunded;
    address[] fundedAddress;
    address owner;
    uint256 minimumInvestment;

    event FundedEvent(address funder, uint256 amount, string message);

    constructor(address _chainLinkContractAddress, uint256 _minimumInvestment) {
        owner = msg.sender;
        pricefeed = AggregatorV3Interface(_chainLinkContractAddress);

        //Funding minimum of 100 dollors
        minimumInvestment = _minimumInvestment;
    }

    function fundMe() public payable {
        require(
            converthETHToUSD(msg.value) >= minimumInvestment,
            "Funding number minimum amount is USD100"
        );

        addressAmountFunded[msg.sender] += msg.value;
        fundedAddress.push(msg.sender);

        emit FundedEvent(msg.sender, msg.value, "Amount Funded");
    }

    function getMinimumInvestmentInEth() public view returns (uint256) {
        uint256 ethPriceInUsd = getEthPriceInUsd();
        uint256 precision = 1 * 10**18;
        return (minimumInvestment * precision) / ethPriceInUsd;
    }

    function getFundedAddressAmount(address _fundAddress)
        public
        view
        returns (uint256)
    {
        return addressAmountFunded[_fundAddress];
    }

    function getChainLinkABIVersion() public view returns (uint256) {
        return pricefeed.version();
    }

    function getChainLinkUsdDecimal() public view returns (uint256) {
        return pricefeed.decimals();
    }

    function getEthPriceInUsd() public view returns (uint256) {
        (, int256 answer, , , ) = pricefeed.latestRoundData();
        return (uint256(answer) * (10**(18 - getChainLinkUsdDecimal())));
    }

    function converthETHToUSD(uint256 _amountOfEthInWei)
        public
        view
        returns (uint256)
    {
        uint256 ethInUsd = ((getEthPriceInUsd() * _amountOfEthInWei) /
            (10**18));
        return ethInUsd;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "You are not the owner of the contract");
        _;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        //update the addressAmountFunded
        for (uint256 i = 0; i < fundedAddress.length; i++) {
            addressAmountFunded[fundedAddress[i]] = 0;
        }

        fundedAddress = new address[](0);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getOwnerAddress() public view returns (address) {
        return owner;
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