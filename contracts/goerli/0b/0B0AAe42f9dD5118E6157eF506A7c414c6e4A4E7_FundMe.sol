// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

/**
 *
 *  @title a contract for crowd founding.
 *  @author Alessandro Bartoli.
 *  @notice This contract is a demo of a funding contract.
 *  @dev This implements price feeds as our library.
 *
 */
contract FundMe {
    /** Type Desclarations ****************************************************/
    // Use the library.
    using PriceConverter for uint256;

    /*** State Variables ******************************************************/
    // Dictionary of funders, to keep track who fund.
    mapping(address => uint256) public addressToAmountFunded;

    // Array of founders.
    address[] public funders;

    // Definethe Owner of this contract.
    address public /* immutable */ owner;

    AggregatorV3Interface public priceFeed;

    /*** Modifiers ************************************************************/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*** Functions ************************************************************/

    /**
     *
     * Constructor.
     *
     * @param _priceFeed address
     *
     */
    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    /**
     *
     *  @notice This function funds thsi contract.
     *  @dev This implements price feeds as our library.
     *
     */
    function fund() public payable {
        uint256 minimumUSD = 50 * 10**18; // 1000000000000000000
        require(
            // pass msg.value as a first param and priceFeed as a second param.
            msg.value.getConversionRate(priceFeed) >= minimumUSD,
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }

    function cheaperWithdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        address[] memory _funders = funders;
        // mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < _funders.length;
            funderIndex++
        ) {
            address funder = _funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface _priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = _priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(
        uint256 _ethAmount,
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(_priceFeed);
        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
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