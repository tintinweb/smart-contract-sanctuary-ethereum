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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error Donate__OnlyOwner();

/// @title A simplistic contract for making donations 
/// @author Travis Uche Emeka
/// @notice Users can donate a minimum of $50 woth of ETH which can only be withdrawn by the contract owner
/// @dev The Contract utilizes Chain Link Price Feed Contract to get the current ETH to USD Price
contract Donate {

    using PriceConverter for uint256;


    // stores minimum usd value ($50) in 18 decimal places
    uint256 private constant MINIMUM_USD = 50 * (10 ** 18);

    address private immutable i_owner;

    // Array of donators
    address[] private s_donators;

    // Simple mapping of donators to funds
    mapping (address => uint256) s_donatorsToAmount;

    // AggregatorV3Interface
    AggregatorV3Interface private priceFeed;


    modifier onlyOwner {
        if(msg.sender != i_owner) revert Donate__OnlyOwner();
        _;
    }


    constructor (address priceFeedAddress)  {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }


    /// @notice A payable function for donating to the smart contract
    /// @dev Makes of a PriceConverter library for calculating price in USD 
    function donate() public payable {
        require(msg.value.convertEthToUsd(priceFeed) >= MINIMUM_USD, "A minimum ETH donation of $50 is required");
        
        s_donators.push(msg.sender);

        s_donatorsToAmount[msg.sender] += msg.value;
    }

    /// @notice Withdraws funds to the contract owner address
    /// @dev Can only be called by the contract owner
    function withdraw() public onlyOwner {
        address[] memory donators = s_donators;

        (bool sent, ) = i_owner.call{value: address(this).balance}("");
        require(sent, "Could not withdraw funds");

        // Empty donators array
        for (uint i = 0; i < donators.length; i++) {
            address donator = donators[i];

            s_donatorsToAmount[donator] = 0;
        }

        // Resetting arrays
        s_donators = new address[](0);
        donators = new address[](0);
    }

    /// @notice For retrieving the address of the contract owner
    /// @return address of the owner
    function getOwner() public view returns (address) {
        return i_owner;
    }

    /// @notice For retrieving the current balance of the contract
    /// @return amount of the contract's balance in uint256
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice For retrieving a donator address
    /// @return address of a donator
    /// @param _index (Index of a donator from the donators address)
    function getDonator(uint256 _index) public view returns (address) {
        return s_donators[_index];
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title A simplistic library for getting current ETH to USD price
/// @author Travis Uche
/// @notice Able to get current ETH to USD price and convert sent ETH to USD
/// @dev This library uses the Chain Link price feed contract on the GOERLI Testnet
library PriceConverter {
    /// @notice For retrieving the current ETH to USD price
    /// @return amount of ETH to USD
    function getEthToUsd(AggregatorV3Interface priceFeed) internal view returns(uint256) {
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint256(price * 10000000000) ;
    }

    /// @notice Calculates the value of the sent ETH in USD
    /// @return value of the sent ETH in USD
    function convertEthToUsd(uint256 _amount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getEthToUsd(priceFeed);
        uint256 amountInUsd = (_amount * ethPrice) / 1000000000000000000;
        return amountInUsd;
    }
}