// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./PriceConverter.sol";

error FundMe__NotOwner();

/** 
 * @title A contract for crowd funding
 * @author seamew
 * @notice This conftract is to demo a sample funding contract
 * @dev This implememnts price fee as our library
 */
contract FundMe
{
    using PriceConverter for uint256;

    // const 常量必须在定义时就初始化，常量可以省 gas
    uint256 public constant MINIMUM_USD = 14 * 1e18;

    address[] private s_funders; 
    mapping(address => uint256) private s_addressToAmountFunded; // s => store

    // immutable 表示不可变的变量，可以在构造器中初始化，一经初始化后其值不可被改变，
    // immutable 和 constant 比较省 gas，constant 只可用于 string 和基础数据类型，
    // immutable 只可用于基础数据类型
    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    // modifier 可以为某个函数提供附加的功能，_ 表示执行函数中的代码，例如下面的例子，在执行 withdraw() 函数之前，
    // 首先要判断调用函数的人是不是合约的拥有者，如果是的话再执行函数中的代码
    modifier onlyOwner
    {
        // 使用自定义 error 代替 require 语句可以省 gas，因为 require 中的 string 会消耗存储空间
        if (msg.sender != i_owner) { revert FundMe__NotOwner(); }
        _;
    }

    constructor(address priceFeedAddress)
    {
        // 这里的 msg.sender 是部署合约的人的钱包地址
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }


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
    // receive() external payable
    // {
    //     fund();
    // }

    // fallback() external payable
    // {
    //     fund();
    // }

    function fund() public payable
    {
        // Want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract
        // require 中的条件表达式为 false 时会回滚之前的所有操作，并且抛出错误信息
        // msg 是 solidity 中内置的全局对象，msg.value 表示发送来的虚拟货币的数量
        // 单位是 wei，msg.sender 表示调用当前函数发送虚拟货币的发送人的地址
        // 详见 https://docs.soliditylang.org/en/v0.8.17/units-and-global-variables.html
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Didn't send enough");
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner
    {
        // reset map
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        // reset the array
        s_funders = new address[](0);

        // actually withdraw the funds
        // 1. transfer
        // 2. send
        // 3. call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner 
    {
        // mapping 不能存储到 memory 中
        address[] memory funders = s_funders;
        uint256 length = funders.length;
        for (uint256 i = 0; i < length; i++) {
            address funder = funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success, "Call failed");
    }

    function getFunder(uint256 index) public view returns (address)
    {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder) public view returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getOwner() public view returns (address) 
    {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface)
    {
        return s_priceFeed;
    }
}

/*  
    gas 优化:
    1. 避免频繁读写 storage 变量，如果需要频繁读取，应该把 storage 变量尝试加载到
       memory 中进行读取操作
    2. 不可变的变量使用 immutable 和 constant 修饰符
    3. 将变量的可见性改为 private 可以省 gas
    4. 将 require(...) 改为使用 revert，因为 require 中的字符串会被存储到链上，
       会消耗一定的 gas 
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter
{
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256)
    {
        // ABI 
        // Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // 使用 chainlink 获取 eth 的mei yuan
        (, int256 price, , ,) = priceFeed.latestRoundData();

        // solidity 中没有浮点数，所以用整型变量保存浮点数的整数位和小数位
        // 这里得到的 price 的值为 145598000000，实际值为 1455.98
        // 这里得到的 price 有 8 位小数，msg.value 的单位是 wei，有 18 位数，
        // 所以这里增加一下 price 的小数位数方便计算
        price *= 1e10;
        return uint256(price);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        // ethPrice 和 ethAmount 各有 18 位小数，相乘后有 36 位小数，所以要除去 18 位小数
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
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