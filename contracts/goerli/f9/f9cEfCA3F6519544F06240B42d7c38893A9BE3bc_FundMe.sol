// Get funds from users
// Withdraw funds
// Set minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error FundMe__NotOwner();
error FundMe__NotEnoughEthSent();
error FundMe__CallFailed();

// Deployment gas: 793.911 -> 774.609 by declaring MINIMUM_USD as a constant

/** @title A contract for crowd funding
 *  @author Domingo García
 *  @notice This contract is to demo a sample funding contract
 *  @dev This implements price feeds as our library
 */
contract FundMe {
    using PriceConverter for uint256;

    uint256 public MINIMUM_USD = 50 * 1e18; // 1e18 == 1 * 10 * 1000000000000000000
    // 21415 gas -> as a constant
    // 23515 gas -> not a constant
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    address private immutable i_owner;
    // 21508 gas -> immutable
    // 23619 gas -> non-immutable
    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /** @notice This function funds this contract
     *  @dev This implements the funding of our contract
     */
    function fund() public payable {
        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD)
            revert FundMe__NotEnoughEthSent();
        // 18 decimals
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    /** @notice This function withdraws the funds from this contract
     *  @dev This implements the withdrawal of the funds stored in the contract by the owner
     */
    function withdraw() public onlyOwner {
        // reset the s_addressToAmountFunded mapping
        for (uint256 index = 0; index < s_funders.length; index++) {
            address funder = s_funders[index];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the s_funders array
        s_funders = new address[](0);
        // withdraw the funds
        // call (forward all gas or set gas and returns a boolean indicating if the transaction was successfull or not, but does not revert the transaction automatically)
        (
            bool callSuccess, /*bytes memory dataReturned*/

        ) = payable(msg.sender).call{value: address(this).balance}("");
        // require(callSuccess, "Call failed");
        if (!callSuccess) revert FundMe__CallFailed();
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;

        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            address funder = funders[fundersIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);

        (
            bool callSuccess, /*bytes memory dataReturned*/

        ) = payable(msg.sender).call{value: address(this).balance}("");
        // require(callSuccess, "Call failed");
        if (!callSuccess) revert FundMe__CallFailed();
    }

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

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        // Eth in terms of USD
        // 1256.00000000
        return uint256(price * 1e10); // 1e10 == 1**10 == 10000000000
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18;
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