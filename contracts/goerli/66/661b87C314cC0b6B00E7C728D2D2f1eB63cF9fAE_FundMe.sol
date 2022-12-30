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

/// Pragma
pragma solidity ^0.8.8;

/// Imports
import "./PriceConverter.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// Error Code
error FundMe__NotOwner(); //Best practice: add the name of the contract(with 2 underscores) as prefix of the errors

/// Interfaces

/// Librairies

/// Contracts

/** @title A Crowd-Funding Contract
 *  @author George
 *  @notice This demo a sample crowndfunding demonstrating how to deploy on multiple networks
 *  @dev This implements chainlink price feeds as our library
 */
contract FundMe {
    /// Type declarations
    using PriceConverter for uint256;

    /// State variables
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;

    /// Events

    /// Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    /// Functions

    ///1-constructor
    constructor(address priceFeedContractAdress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedContractAdress);
    }

    ///2-receive function (if exists)
    receive() external payable {
        fund();
    }

    ///3-fallback function (if exists)
    fallback() external payable {
        fund();
    }

    ///4-external

    ///5-public
    /**
     *  @notice This function funds this contract (param and return are other option but we don't have now)
     *  @dev We actually use the chainlink price feed to require a minimum amount in USD instead of ether
     */
    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD
        //1. How do we send eth to this contract?
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Did not send enough Eth"
        ); //1e8 == 1 * 10 ** 18 == 1 000000000000000000(18 zeros)
        // for testing MINIMUM_USD / eth price -> convert and take the wei value to remix when calling fund function
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funderAddress = funders[funderIndex];
            addressToAmountFunded[funderAddress] = 0;
        }
        // reset funders array
        funders = new address[](0);
        // actually withdraw the funds
        /* withdrawing fund from contract address -> https://solidity-by-example.org/sending-ether/
        transfer:
        send:
        call: recommended 4:45:00
        */
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call to withdraw Fail!");
    }

    //6-internal

    //7-private

    //Optimization of this contract 05:04:18 (gas optimization)
    // 1 - uint256 public minimumUsd = 50 * 1e18; and address public owner; get set once-> use constant and immutable to make them more gas efficient
    // Solution for saving more gas an optimizing our contract:
    // from uint256 public minimumUsd = 50 * 1e18; --> uint256 public constant MINIMUM_USD = 50 * 1e18;
    // from address public owner; --> address public immutable i_owner;
    // We save gas because instead of story both variable into a storage slot, we store it directly into the byte code of the contract.
    //NB: they are nice gas saver if you are only setting your variable once.
    //Now we can replace our requires with custom errors.

    /* What happens if someone sends this contract ETH without calling fund function ?*/
    // receive and fallback

    // This the end for basics and with remix we still have a tone to learn:
    // 1. Enums
    // 2. Events
    // 3. Try / Catch
    // 4. Function Selectors
    // 5. abi.encode / decode
    // 6. Hashing
    // 7. Yul / Assumbly.

    //Look at how to ask for help and practice formating 05:37:34 (hoe to ask for help)
}

// SPDX-License-Identifier: MIT
//https://solidity-by-example.org/library/

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //Note make all the function internal

    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // Now getting price of Eth in terms of USD 8 decimal while msg.value is 18 decimal we need to get them to match up
        // 1214.19296102
        return uint256(price * 1e10); //10 zero to get the match to 18 decimals like eth
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        //ethPrice(18decimal) + ethAmount(18 decimal) = 36 decimals that's why we divide it 1e18 to maintain 18 decimal back
        return ethAmountInUsd;
    }

    function getVersion(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        return priceFeed.version();
    }
}