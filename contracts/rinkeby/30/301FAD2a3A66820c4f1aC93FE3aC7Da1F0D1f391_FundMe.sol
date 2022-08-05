// SPDX-License-Identifier: MIT
//1. PRAGMA
pragma solidity ^0.8.8;

//2. IMPORTS
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

//3. ERROR CODES
error FundMe__NotOwner(); // add contract__name

//4. INTERFACES, LIBRARIES,contracts--------------------------------------------------------------------

//5. CONTRACTS    "description"
/**  @title A contract for crowd funding
 *   @author Mr.Fla
 *   @notice This contract is to demo a sample funding contract
 *   @dev This implements pricefeeds as our library
 */
contract FundMe {
    //5.1 TYPE DECLARATIONS
    using PriceConverter for uint256;

    //event Funded(address indexed from, uint256 amount); //

    //5.2 STATE VARIABLES !
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address public immutable owner;
    uint256 public constant MINIMUM_USD = 50 * 10**18;
    AggregatorV3Interface public priceFeed;
    //5.3 EVENTS

    //5.4 MODIFIER
    modifier onlyOwner() {
        // require(msg.sender == owner)
        if (msg.sender != owner) revert FundMe__NotOwner(); // add contract__name
        _;
    }

    //5.5 FUNCTIONS
    /** FUNCTIONS ORDER
     *       constructor
     *       receive
     *       fallback
     *       external
     *       public
     *       internal
     *       private
     *       view / pure
     */
    //constructor
    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //receive
    //receive() external payable {
    //    fund();
    //}

    //fallback
    //fallback() external payable {
    //    fund();
    //}

    /**
     *   @notice This function funds this contract
     *   @dev This implements pricefeeds as our library
     */
    //public
    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        //call vs delegatecall
        require(success, "Transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // Rinkeby ETH / USD Address
        // https://docs.chain.link/docs/ethereum-addresses/
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //    0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //);
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }
}