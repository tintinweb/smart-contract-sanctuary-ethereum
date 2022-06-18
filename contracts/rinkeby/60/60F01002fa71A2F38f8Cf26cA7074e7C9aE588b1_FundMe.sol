// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// Get funds from users;
// Withdraw funds
// Set a minimum funding value in USD

//npm package or github

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    //안바뀌는 애들은 constant쓰면 gas 줄어듬 => 원래는 이름 모두 대문자로
    uint256 public constant minimumUsd = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    //immutable은 constructor로 변경 가능, constant는 아예 불가능
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract?
        require(
            msg.value.getConversionRate(priceFeed) >= minimumUsd,
            "Didn't send enough"
        ); //=1eth
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
        //revert = undo action before, and send remaining gas
    }

    function withdraw() public onlyOwner {
        //보낸사람 돈 0으로
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        //0번부터 모두 삭제
        funders = new address[](0);

        //contract 돈 보내는 법 : transfer send call

        // //transfer 실패하면 error
        // payable(msg.sender).transfer(address(this).balance);

        // //send 실패하면 bool
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // //밑에 require로 revert
        // require(sendSuccess, "Send failed");

        //call
        (bool CallSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(CallSuccess, "Call failed");
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    //fund me 안쓰고 contract에 ETH를 보낸다면?

    //recieve();
    //Fallback();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // 바깥 contract와 상호작용 = ABI, ADDRESS 필요
        // address = ETH/USD :0x9326BFA02ADD2366b30bacB125260Af641031331
        // ABI = interface로 얻는다 => 깃헙으로 찾을 수 있음
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10); // 이거 하는 이유가 price의 decimal이 8자리인데 1eth 는 decimal이 18자리이기때문
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        return (ethAmount * ethPrice) / 1e18;
    }
}

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