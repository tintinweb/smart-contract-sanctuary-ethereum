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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    uint256 public constant MINIMUM_USD = 1 * 1e18; //最少1美金，乘于1e18是因为 getConversionRate 返回的值带18位小数。

    using PriceConverter for uint256; //对于uint256类型可以直接将自身作为库函数的第一个输入。

    address[] public funders;
    mapping(address => uint256) public addressToAmountFounded;

    address public immutable owner; //合约的拥有者

    AggregatorV3Interface public priceFeed;

    //构造函数会在合约部署时执行
    constructor(address _priceFeed) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    //用于向合约发送eth
    function fund() public payable {
        //msg.value的单位是WEI
        //如果触发了异常会撤销上面的所有操作，但已消耗的gas不返回
        // require(getConversionRate(msg.value) >= MINIMUM_USD,"Pleas spend more eth!" );
        require(
            msg.value.getConversionRate(priceFeed) >= 0,
            "Pleas spend more eth!"
        );
        addressToAmountFounded[msg.sender] = msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        //清除各个账户的转账资金
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            addressToAmountFounded[funders[funderIndex]] = 0;
        }
        //重置founder Array
        funders = new address[](0);

        // 发送账号的eth到合约创建者的账号

        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(sent, "Failed to send Ether");
    }

    modifier onlyOwner() {
        // require(msg.sender == owner,"not the contract owner!");

        //自定义错误
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    // 为了防止有人误发了eth到我们合约又没调用fund（）函数，我们必须实现fallback()和receive()函数
    // 如果调用了函数，data就会有函数相关内容，不会为空
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    //如果向合约发送ether时，calldata为空，调用receive
    receive() external payable {
        fund();
    }

    function test2() external {}

    //如果向合约发送ether时数据不为空，但没有指定调用函数或者没有合适的函数可以调用fallback
    //或者数据为空，没有定义receive()函数时调用这个
    fallback() external payable {
        fund();
    }

    //获取eth价格所使用的智能合约的版本
    function getVersion() public view returns (uint256) {
        //Network: Goerli
        //Aggregator: ETH/USD
        // Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

        return priceFeed.version();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//调用合约需要address  和 abi ,这个接口相当于abi，具体的实现在已部署的合约里
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//注意要使用library关键字
library PriceConverter {
    //使用chainlink获取以太坊价格
    function getEthPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        //price返回130755846208 有八位小数
        return uint256(price * 1e10); // 乘于1e10 相当于有18位小数，相当于使用WEI为单位
    }

    //EHT转成USD
    function getConversionRate(
        uint256 ethAmountInWEI,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getEthPrice(priceFeed);
        uint256 ethAmountInUsd = (ethAmountInWEI * ethPrice) / 1e18;
        return ethAmountInUsd; //返回的值还是带18位小数
    }
}