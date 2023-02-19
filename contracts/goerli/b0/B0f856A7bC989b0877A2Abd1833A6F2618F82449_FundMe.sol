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

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

contract FundMe {
    error FundMe__NotOwner();
    error FundMe__NotEnugh();

    using PriceConverter for uint256;

    uint256 public constant MINUSD = 50 * 1e18;
    address[] private funders;
    AggregatorV3Interface private priceFeedAddress;

    mapping(address => uint256) public addressToAmountFund;

    constructor(AggregatorV3Interface _priceFeedAddress) {
        i_owner = msg.sender;
        priceFeedAddress = AggregatorV3Interface(_priceFeedAddress);
    }

    receive() external payable {
        Fund();
    }

    fallback() external payable {
        Fund();
    }

    function Fund() public payable {
        if (msg.value.getConversionRate(priceFeedAddress) < MINUSD) {
            revert FundMe__NotEnugh();
        }
        // require(
        //     msg.value.getConversionRate(priceFeedAddress) >= MINUSD,
        //     FundME__NotEnugh()
        // );
        funders.push(msg.sender);

        addressToAmountFund[msg.sender] += msg.value;
    }

    address public immutable i_owner;

    function Withdraw() public onlyOwner {
        // TO FREE THE MAPPING
        address[] memory fundList = funders;

        for (
            uint256 funderIndex = 0;
            funderIndex < fundList.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFund[funder] = 0;
        }
        // TO FREE THE ARRAY
        funders = new address[](0);

        // TO SNED ALL BALANCE TO OWNER
        // I HAVE the problem that any one can send mony to himself so i will make that no one can use this function just the owner of contract ;;
        (bool callSuccess, ) = payable(i_owner).call{
            value: address(this).balance
        }("");

        if (!callSuccess) {
            revert("Transcation Faild");
        }
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }

        // require(msg.sender == i_owner,"sender is not the owner");
        _;
    }

    function getFundersAt(uint256 index) public view returns (address) {
        return funders[index];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return priceFeedAddress;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice(
        AggregatorV3Interface priceFeedAddress
    ) internal view returns (uint256) {
        // Goerli ETH / USD Address
        // https://docs.chain.link/docs/ethereum-addresses/
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        (, int256 answer, , , ) = priceFeedAddress.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeedAddress
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeedAddress);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }
}