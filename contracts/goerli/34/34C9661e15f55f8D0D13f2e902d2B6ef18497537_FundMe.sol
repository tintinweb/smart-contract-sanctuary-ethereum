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

pragma solidity ^0.8.7;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToFunde;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // 获取用户资金
    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        );

        funders.push(msg.sender);
        addressToFunde[msg.sender] += msg.value;
    }

    // 提取资金
    function withdraw() public onlyOwner {
        // 将每个地址提供的资金设置为0
        for (
            uint256 fundIndex = 0;
            fundIndex < funders.length;
            fundIndex = fundIndex + 1
        ) {
            address funder = funders[fundIndex];
            addressToFunde[funder] = 0;
        }

        // 重置数组
        funders = new address[](0);

        // 真实的取出资金
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call fail");

        revert(); // 与onlyOwner对应 回滚交易
    }

    // 修饰函数
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // 如果有人直接向合约地址交易会发生什么？
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // 从npm下载接口 路径跟github上一致

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // ABI
        // Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e 通过地址获取合约 调用合约上的方法
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint256(price * 1e10); // 转变为和wei一样的 1后面18个0的形式
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