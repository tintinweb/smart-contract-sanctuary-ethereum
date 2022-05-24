/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

/** NOTE: Here we took the value of Eth as 10^18 times of the Real Eth Value, which means all the normal USD values we represent here will be mulitiplied by 10^18
    For example 3000 USD = 3000*(10^18), 100 USD = 100*(10^18). Simply when we represent USD values here we multiply the normal value by 10^18  */
contract FundMe {
    address public owner;
    AggregatorV3Interface public priceFeed;

    struct AddressAndAmounts {
        address Address;
        uint256 Amount;
    }

    mapping(address => uint256) public AddressToAmount;

    AddressAndAmounts[] public AddressAndAmountArray;

    address[] public funders;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // used to transfer funds to the contract
    function Fund() public payable {
        // Setting minimum USD to Fund.
        uint256 minimumUSD = 50 * (10**18);
        // Getting the value of Eth in USD per GWEI from the 'EthValue()'. 'Ethvalue()' gives the value for Eth. To find the Value for a GWEI we divide it by 10^9.
        uint256 EthValue_in_GWEI = (EthValue() / (10**9));
        // when we do a transaction 'msg.value' gives thee value in WEI. Since we do the convertion with the Price of per GWEI, we have to submit msg.value in GWEI so we divide it by 10^9.
        uint256 Change_msgvalue_toUSD = (msg.value / (10**9)) *
            EthValue_in_GWEI;
        // the require statement can be used as an if Statement
        require(Change_msgvalue_toUSD >= minimumUSD, "You Need To Donate More");
        // Using this Array we can show the amounts donated by each accounts. this Automatically gets data when transactions are happening
        AddressAndAmountArray.push(
            AddressAndAmounts({Address: msg.sender, Amount: msg.value})
        );
        // the below code is connected with the mapping in line 17. 'msg.sender' refers for the person who clicked the withdraw function
        AddressToAmount[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // using modifier, rechecking whether the deployed account is the withdrawing account.
    modifier OnlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // used withdraw funds from the contract
    function withdraw() public payable OnlyOwner {
        // changing msg.sender to payable address
        address payable HOST = payable(msg.sender);
        address payable CONTRACT = payable(address(this));
        HOST.transfer(CONTRACT.balance);

        // for loop to make every funder on Address to funder mapping to be zero
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            AddressToAmount[funder] = 0;
        }
        // making funders aray as a blank array
        funders = new address[](0);

        // deleting elements in AddressAndAmountArray
        for (
            uint256 AddressAndAmountArrayIndex = 0;
            AddressAndAmountArrayIndex < AddressAndAmountArray.length;
            AddressAndAmountArrayIndex++
        ) {
            delete AddressAndAmountArray[AddressAndAmountArrayIndex];
        }
    }

    // Here the eth value is 10^18th of normal value
    function EthValue() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * (10**10));
    }

    function GWEItoUSD(uint256 Gweis) public view returns (uint256) {
        uint256 ValueOfOneGweiInUSD = EthValue() / (10**9);
        return Gweis * ValueOfOneGweiInUSD;
    }

    function USDtoGWEI(uint256 inputUSD) public view returns (uint256) {
        uint256 USDS = inputUSD * (10**18);
        uint256 GWEIamount = (USDS * (10**9)) / (EthValue());
        return GWEIamount;
    }

    function BalanceInTheContract() public view returns (uint256) {
        return (address(this).balance) / (10**9);
    }

    function GETVERSION() public view returns (uint256) {
        return priceFeed.version();
    }
}