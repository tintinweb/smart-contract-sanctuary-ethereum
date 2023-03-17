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

// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// 1. Pragma
pragma solidity ^0.8.8;

// 2. Imports
import "./PriceConverter.sol";

// Error Codes
error FundMe__NotOwner();

// 3. Interfaces, Libraries, Contracts

/**@title A sample Funding Contract
 * @author Patrick Collins (forked)
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {

    // Type Declarations
    using PriceConverter for uint256;
    
    // State variables
    mapping(address=>uint256) private s_addressToAmountFunded;
    address[] private s_funders;
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD =  50 * 10 ** 18; 
    AggregatorV3Interface private s_priceFeed;
    
    // Events (we have none!)

    // Modifiers
    modifier onlyOwner {
        //require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }
    
    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /** 
     *  @notice this function funds this contract
     */
    function fund() public payable {

       require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
       s_funders.push(msg.sender);
       s_addressToAmountFunded[msg.sender] = msg.value;
        
    }

    function withdraw() public onlyOwner {
        /* for(starting index, ending index, step amount) */
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);
        
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        
        // call vs delegatecall
        require(callSuccess, "Transfer failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory, sorry!
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getOwner() public view returns(address){
        return i_owner;
    }

    function getFunder(uint256 index) public view returns(address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder) public view returns(uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns(AggregatorV3Interface) {
        return s_priceFeed;
    }

}

// SPDX-License-Identifier: MIT

// Library Example

pragma solidity ^0.8.0;


import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {

        (, int256 price,,,) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(price * 1e10); // 1**10 == 10000000000
    }

    // in libraries first parameters itself (this)
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // 1700_000000000000000000 = ETH / USD price
        // 1_000000000000000000 ETH
        // 1699.999999999999999999 USD 
        // ~1700 USD
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}