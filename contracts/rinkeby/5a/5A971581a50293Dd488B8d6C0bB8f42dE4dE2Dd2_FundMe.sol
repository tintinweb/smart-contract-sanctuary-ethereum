// In lesson 7 we clean up and organize our contract with some conventions
// we will use some low level solidity to make this "better"
// we will follow a style layout that can be found in https://docs.soliditylang.org/en/v0.8.15/style-guide.html
// we will also take a look into a gas optimization technique (variable declaration)

// SPDX-License-Identifier: MIT

// pragma

pragma solidity ^0.8.8;

// imports

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// error code

// error NotOwner();    --> uncorrect naming
error FundMe__NotOwner(); // correct syntax for name

// Interfaces, Libraries

// Contracts

/** @title A contract for crowd funding
 *  @author Nicolas Arnedo
 *  @notice This contract is to demo a sampler funding contract
 *  @dev This implements price feeds as our library
 */

contract FundMe {
    // 1.- Type declarations

    using PriceConverter for uint256;

    // 2.- State variables

    mapping(address => uint256) private s_addressToAmountFunded; // we change the name to a s_varName so that we know that it is a variable that is being stored
    address[] private s_funders; // same here + we change public to private

    address private immutable i_owner; // also saves gas to declare variables private or internal (changed i_owner from public to private)
    uint256 public constant MINIMUM_USD = 50 * 10**18;

    AggregatorV3Interface private s_priceFeed; // we declare an AggregatorV3Interface variable

    // by having the variable with s_varName we can then check the functions and see which ones have a lot of these types of variables inside of it
    // and then we can know where to posibly start to optimize the code

    // 3.- Events & Modifiers

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    // 4.- Functions (constructor > recieve > fallback > external > public > internal > private > view/pure)

    constructor(address s_priceFeedAddress) {
        // modularize the chainlink priceconverter contract address so we dont have to manually change in the code
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress); // now it is variable and modularized
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        // this code is extremely gas inefficient
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length; // reading a storage variable in every loop iteration
            funderIndex++
        ) {
            address funder = s_funders[funderIndex]; // saving a storage variable in every loop iteration
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        // to make it cheaper we can read the array one time from storage to memory
        // and then when we loop through the array we will do it directly from memory
        // and not from storage, this will make the loop cheaper

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
        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
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
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        /* We no longet need to hardcode this contract in since now we can input it in the function statements
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        ); */
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed // we add it here as the second parameter that must be passed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed); // and we include the parameter here
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }
}