// SPDX-License-Identifier: MIT
// Pragma
pragma solidity ^0.8.9;
// Imports
import "./PriceConverter.sol";
// Error Codes
error FundMe__NotOwner();

// Interfaces, Libraries, Contracts

/** @title A contract for ceowd funding
 *  @author Robert
 *  @notice This contract is to demo a sample funding contract
 *  @dev This implements price feeds as our library
 */
contract FundMe {
    // Type declarations
    using PriceConverter for uint256;

    // State Variables!
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    // Modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!"); - use custom error instead
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; // represents the rest of the code from the function where the modifier is used
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
     *  @notice This function funds this contract
     *  @dev This implements price feeds as our library
     */
    function fund() public payable {
        // require(getConversionRate(msg.value) > minimumUsd, "Didn't send enough!"); // access the value attribute with global keyword 'msg'
        require(
            msg.value.getConversionRate(s_priceFeed) > MINIMUM_USD,
            "Didn't send enough!"
        );

        s_funders.push(msg.sender); // msg.sender is the address
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "Sender is not owner!"); -> will use modifiers instead
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset array
        s_funders = new address[](0); // resetting array (0),(1) ..how many elements the new array should have
        // actually withdraw the funds

        // transfer
        // msg.sender = type address
        //payable(msg.sender) = type payable address
        payable(msg.sender).transfer(address(this).balance);

        // send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");

        // call - recomended way to send and receive blockchain native token
        // (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}(""); // dataReturned is string so we need memory
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); // only what we need
        require(callSuccess, "Call failed");
        // revert(); -you can revert wherever you want
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mapping can t be in memory
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    // view / pure
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 3000.00000000
        return uint256(price * 1e10); // 1**10 == 10000000000; covert from int256 to uint256
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // 3000_000000000000000000 = ETH / USD price
        // 1_000000000000000000 ETH

        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // 36 zeros if not divided
        // 2999.999999999999999999 = 2999e21 ->3000
        return ethAmountInUsd;
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