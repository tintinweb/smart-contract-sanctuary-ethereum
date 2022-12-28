//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

import "./PriceConverter.sol";

// 856085
//

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUMUSD = 50 * 1e18;
    // 23537 - no constant
    // 21437 - constant

    address public immutable i_owner;

    // 23641 - no immutable
    // 21437 - immutable

    //will called only when this contract id deployed (by owner)
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    address[] public funder;
    mapping(address => uint256) public addressToAmountFunded;

    function fund() public payable {
        require(
            msg.value.getconversationRate(priceFeed) >= MINIMUMUSD,
            "Not Paying Enugh"
        );
        funder.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function Withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funder.length;
            funderIndex++
        ) {
            addressToAmountFunded[funder[funderIndex]] = 0;
        }
        funder = new address[](0);

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner,"Sender is not Owner!");
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrize(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in Usd
        // 1000.00000000
        return uint256(price * 1e10); // so our doller should also have 18 decimal places
    }

    // take the input of eth ==> gives equivalate usd
    function getconversationRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        return (ethAmount * getPrize(priceFeed)) / 1e18;
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