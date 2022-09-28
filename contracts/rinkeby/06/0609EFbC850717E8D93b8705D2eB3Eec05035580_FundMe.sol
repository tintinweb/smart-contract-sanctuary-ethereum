// SPDX-License-Identifier: MIT

// Get funds from users
// Withdraw funds to owner
// Set a minimun funding value in USD

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();

contract FundMe {

    using PriceConverter for uint256;


    address public /*immutable*/ i_owner;
    address[] public funders;
    uint256 public totalFunded;

    uint256 public constant MINIMUM_USD = 3 * 10 ** 18;
    mapping(address => uint256) public addressToAmountFunded;

    AggregatorV3Interface public priceFeed;
    
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOwner () {
        //require (msg.sender == i_owner, "You are not the owner of the contract");
        if(msg.sender != i_owner) revert NotOwner();
        _;
    }

    function fund () public payable {
        require(msg.value.getConvertionRate(priceFeed) > MINIMUM_USD, "You need to spend more Money!!");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
        totalFunded += msg.value;
    }

    function getVersion() public view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return (priceFeed.version());
    }

    function withdraw() public onlyOwner {
        for (uint funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder]=0;
        }

        totalFunded = 0;
        //Reset funcers array
        funders = new address[](0);
        //Withdraw funds using transfer method
        payable(msg.sender).transfer(address(this).balance);
        //Withdraw funds using send method
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require (sendSuccess,"SEND operation failed");
        //Withdraw funds using call method
        (bool callSuccess,) = payable(msg.sender).call{value:address(this).balance}("");
        require(callSuccess,"CALL operation failed");
    }

        function cheepWithdraw() public onlyOwner {
            address[] memory s_funders = funders;
        for (uint funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder]=0;
        }

        totalFunded = 0;
        //Reset funcers array
        funders = new address[](0);
        //Withdraw funds using transfer method
        payable(msg.sender).transfer(address(this).balance);
        //Withdraw funds using send method
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require (sendSuccess,"SEND operation failed");
        //Withdraw funds using call method
        (bool callSuccess,) = payable(msg.sender).call{value:address(this).balance}("");
        require(callSuccess,"CALL operation failed");
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // Use case : sending ETH to contract without calling Fund Function (through Metamask Send Button for instance)
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

/**
pragma solidity ^0.8.8;

import "hardhat/console.sol";
import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe_NotOwner();

contract FundMe {
    //Variable Declaration

    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 3 * 10**18;

    address private immutable i_owner;
    address[] private s_funders;

    mapping(address => uint256) private s_addressToAmountFunded;

    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe_NotOwner();
        _;
    }

    constructor(AggregatorV3Interface priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "NOT ENOUGH ETH"
        );
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        //Withdraw all funds to owner wallet
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success, "WITHDRAW FAILED");
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getAddressToAmountFunded(address fundingAddress)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ABI is required and address of the contract
        // 	0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e for GOERLI ETH/USD
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // as the conversion ETH/USD comes with 8 extra decimals, we multiply by 10
        return uint256(answer * 10**10);
    }

    function getConvertionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}

/**
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        //Extract ETH/USD rate with 18 digits for better maniopulation
        return (uint256(answer * 10**10));
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 10**18;
        return ethAmountInUsd;
    }
}*/

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