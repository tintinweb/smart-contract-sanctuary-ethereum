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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner();

/**  
    @title A contract for crowd funding
    @author Renate Gouveia
    @notice This is a sample
    @dev This implements price feed
 */

contract FundMe {
    // Type declarations
    using PriceConverter for uint256;

    struct Campaign {
        uint256 allocatedFunds;
        string name;
        string description;
        address owner;
    }

    // State variables
    // If you know value at compile time
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address private immutable i_owner;

    address[] private s_funders;
    Campaign[] public s_campaigns;
    mapping(address => uint256) private s_addressToAmountFunded;
    mapping(address => Campaign) public s_addressToCampaign;

    AggregatorV3Interface private s_priceFeed;

    // Modifers
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _; // Represents the rest of the code in function
    }

    // This is the order of functions
    constructor(address _priceFeed) {
        s_priceFeed = AggregatorV3Interface(_priceFeed);
        i_owner = msg.sender;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**  
        @notice This funds the contract
        @dev Some stuff for the devs
    */
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function createCampaign(string memory _name, string memory _description)
        public
        payable
    {
        s_addressToCampaign[msg.sender] = Campaign(
            0,
            _name,
            _description,
            msg.sender
        );
    }

    function fundCampaign(address campaignOwner) public payable {
        s_addressToCampaign[campaignOwner].allocatedFunds =
            s_addressToCampaign[campaignOwner].allocatedFunds +
            msg.value;
    }

    function withdrawFundsFromCampaign() public payable {
        Campaign memory value = s_addressToCampaign[msg.sender];
        if (value.allocatedFunds > 0) {
            (bool callSuccess, ) = payable(msg.sender).call{
                value: value.allocatedFunds
            }("");
            s_addressToCampaign[msg.sender].allocatedFunds = 0;
        }
    }

    function withdraw() public payable onlyOwner {
        // Very expensive
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // Cheaper to reset the array
        s_funders = new address[](0);
        // Call any function all of ethereum without know the ABI
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address index)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[index];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    function getCampaign(address index) public view returns (Campaign memory) {
        return s_addressToCampaign[index];
    }

    function getTotalFundraised() public view returns (uint256) {
        return address(this).balance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    (, int256 answer, , , ) = priceFeed.latestRoundData();
    // ETH/USD rate in 18 digit
    return uint256(answer * 10000000000);
  }

  // 1000000000
  // call it get fiatConversionRate, since it assumes something about decimals
  // It wouldn't work for every aggregator
  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    uint256 ethPrice = getPrice(priceFeed);
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
    // the actual ETH/USD conversation rate, after adjusting the extra 0s.
    return ethAmountInUsd;
  }
}