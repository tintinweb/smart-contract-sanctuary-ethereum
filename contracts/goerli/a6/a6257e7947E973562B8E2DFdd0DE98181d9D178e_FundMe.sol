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
pragma solidity ^0.8.17;
import "./PriceConverter.sol";

error FundMe__NotOwner();

/**
 * @title Crowd funding
 * @author Oleksii Bichuk
 * @notice Demo of crowdfunding
 * @dev With link price feeds
 */
contract FundMe {
    using PriceConverter for uint256;

    address[] private s_funders;
    mapping(address => uint256) private s_addressToValue;
    AggregatorV3Interface private s_priceFeed;

    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    address private immutable i_owner;

    modifier onlyOwner() {
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

    /**
     * @notice Function for funding this contract
     *
     */
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Not enough"
        );
        s_funders.push(msg.sender);
        s_addressToValue[msg.sender] += msg.value;
    }

    /**
     * @notice Function for withdraw money, only owner
     *
     */
    function withdraw() public payable onlyOwner {
        for (uint256 i = 0; i < s_funders.length; i++) {
            s_addressToValue[s_funders[i]] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        for (uint256 i = 0; i < funders.length; i++) {
            s_addressToValue[funders[i]] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 i) public view returns (address) {
        return s_funders[i];
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) public view returns (uint256) {
        return s_addressToValue[fundingAddress];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10000000000);
    }

    function getConversionRate(
        uint256 ethValue,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        return (ethPrice * ethValue) / 1000000000000000000;
    }
}