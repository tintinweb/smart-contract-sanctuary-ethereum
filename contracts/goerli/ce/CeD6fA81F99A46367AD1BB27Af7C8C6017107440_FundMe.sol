// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity ^0.8.7;
// 2. Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// 3. Interfaces, Libraries, Contracts
error FundMe__NotOwner();

/**@title A sample Funding Contract
 * @author Patrick Collinss_priceFeed
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State variables
    uint256 public constant MINIMUM_USD = 50 * 10**18;
    address public immutable i_owner;
    address[] public s_funders;
    mapping(address => uint256) public s_addressToAmountFunded;
    AggregatorV3Interface public s_priceFeed;

    // Events (we have none!)

    // Modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address s_priceFeedAddress) {
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
        i_owner = msg.sender;
    }

    /// @notice Funds our contract based on the ETH/USD price
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // Transfer vs call vs Send
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    //节省Gas费
    //刚开始这个节省的幅度可能不明显,数组越大越明显
    function cheaperWithdraw() public payable onlyOwner {
        //一次将整个数组读入内存,然后从内存中读取而不是从存储中进行昂贵的读取
        address[] memory funders = s_funders; //memory意味着该数组只会暂时存在于函数当中,把存储变量保存到内存变量(多出来的这行代码也消耗Gas费)
        //这样我们可以在内存变量中读写(Gas费便宜得多),读写完成后再保存到存储变量中
        //映射不能使用memory关键字
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex]; //使用我们的内存变量
            s_addressToAmountFunded[funder] = 0; //重置映射
        }
        s_funders = new address[](0); //读写完成后再保存到存储变量中
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
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

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //用该函数来计算以美元为单位时,代币的理论价格
    //为了获取价格一定要使用Chainlink喂价来获取定价信息
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //引入项目外合约里的价格函数
        //因为这是我们在与项目之外的合约进行交互,所以我们需要两样东西(之前的交互都是使用import)
        //1.合约的ABI 通过编译聚合器V3接口合约,我们能得到ABI
        //2.合约的地址address 	ETH/USD:0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        //创建一个聚合器对象,命名为喂价,这个合约地址的对象是否拥有聚合器接口的全部功能?
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // ); //创建此对象后向chainlink报告说这是一个接口对象这是一个接口对象，它被编译成 abi。如果您将 abi 与地址匹配，您将获得可以与之交互的合约。

        //调用函数,获取最新一轮的价格,由于这个函数返回一大堆不同的变量,故需要设置返回值,但是这些变量里我们只关注价格,把其他变量去掉只留下逗号
        (, int256 price, , , ) = priceFeed.latestRoundData(); //相当于返回最新一轮数据的价格
        //上述函数返回的是按美元计算的ETH的价格
        //AggregatorV3Interface合约有一个小数(decimals)函数,它会告诉你在喂价中有多少个小数位.
        //解决小数点问题
        return uint256(price * 1e10); //1 * 10^10 == 10000000000//因为msg.value是uint256类型的,获取的定价也应是uint256类型的
        //18-10=8位小数?

        //(uint80 roundId,int price,uint startedAt,uint timeStamp,uint80 answeredInRound) = priceFeed.latestRoundData();
    }

    //用该函数来获取转换率
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        //调用新创建的getPrice函数来为自变量赋值
        uint256 ethPrice = getPrice(priceFeed); //现在当我们调用我们的getPrice函数时,我们可以将喂价传递给getPrice()

        //3000_000000000000000000 = ETH/USD

        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}