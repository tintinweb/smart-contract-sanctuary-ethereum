// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error failed();

contract FundMe {
    using PriceConverter for uint256;
    address public immutable i_owner;
    //宣告一個全域變數,priceFeed,其類別是AggregatorV3Interface
    AggregatorV3Interface public priceFeed;

    //傳遞一個address變數給constructor
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        //將全域變數設定為interface(智能合約地址)
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner);
        _;
    }

    uint public constant MINIUSD = 10 * 1e18;
    address[] public funders;
    mapping(address => uint) public fundMoney;

    function fund() public payable {
        //在msg.value呼叫library的function getConversionRate時,額外再傳遞一個全域變數priceFeed
        require(msg.value.getConversionRate(priceFeed) > MINIUSD);
        funders.push(msg.sender);
        fundMoney[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint i = 0; i < funders.length; i++) {
            address tempAccount = funders[i];
            fundMoney[tempAccount] = 0;
        }
        funders = new address[](0);
        (bool call, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        if (call != true) {
            revert failed();
        }
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function traFromContract(address payable _to, uint _value)
        public
        onlyOwner
    {
        _to.transfer(_value);
    }

    function sendFromContract(address payable _to, uint _value)
        public
        onlyOwner
    {
        bool sent = _to.send(_value);
        if (sent != true) {
            revert failed();
        }
    }

    function callFromContract(address payable _to, uint _value)
        public
        onlyOwner
    {
        (bool call, ) = _to.call{value: _value}("");
        if (call != true) {
            revert failed();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //在function多加一個傳入參數AggregatorV3Interface priceFeed
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint)
    {
        //註解原有寫死的智能合約地址
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );
        //透過AggregatorV3Interface priceFeed直接取用其ABI latestRoundData 得到ethPrice的餵價
        (, int256 ethPrice, , , ) = priceFeed.latestRoundData();
        return uint(ethPrice * 1e10);
    }

    //在這個function多加上第二個輸入變數AggregatorV3Interface priceFeed,用來承接fundme.sol合約傳送過來的priceFeed全域變數
    function getConversionRate(uint _ethAmount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint)
    {
        //呼叫getPrice function時傳遞priceFeed變數進去
        uint ethPrice = getPrice(priceFeed);
        uint totalUSD = (ethPrice * _ethAmount) / 1e18;
        return totalUSD;
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