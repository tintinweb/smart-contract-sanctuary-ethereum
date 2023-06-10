// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

// 自定义错误，节省gas

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // 使用constant 节省gas
    uint256 constant MINIMAL_USD = 50 * 1e18;

    address[] public funders;

    mapping(address => uint256) public addressToAmountFunder;

    // 节省gas
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    // 构造函数
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(
            msg.value.getConvertionRate(priceFeed) >= MINIMAL_USD,
            "Minimal value is 1ETH"
        );
        // require(getConvertionRate(msg.value)  >= minimalUSD, "Minimal value is 1ETH");
        funders.push(msg.sender);
        addressToAmountFunder[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 idx = 0; idx < funders.length; idx++) {
            address funderAddr = funders[idx];
            addressToAmountFunder[funderAddr] = 0;
        }

        // 初始化新数组
        funders = new address[](0);

        // 转账

        // transfer gas 上线2300，失败了会报错并回滚
        // payable(msg.sender).transfer(address(this).balance);

        // 失败了会返回一个bool
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //手动回滚
        // require(sendSuccess, "Send failed");

        // call是一个比较底层的方法
        // 在大多数情况下，推荐这种方法来转移
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // 修饰器，被修饰的函数仅可以被owner调用
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        // 这个代表的是其余代码
        // 也就是说，如果_;放在上方，代表先运行其他代表，再运行modifier中的内容！
        _;
    }

    // 当calldata中没有值（代表的是函数名）的时候，调用的是这个函数
    // 直接向合约地址转账，也会调用这个函数
    receive() external payable {
        fund();
    }

    // 找不到所调用函数时候，自动调用这个
    fallback() external payable {
        fund();
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
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // 3000.00000000
        // 转为18位数
        return uint256(answer * 1e10);
    }

    function getConvertionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // price 和 amount都是 Ne18
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUSD;
    }
}