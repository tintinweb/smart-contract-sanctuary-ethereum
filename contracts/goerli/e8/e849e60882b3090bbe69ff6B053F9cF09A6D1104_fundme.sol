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

pragma solidity 0.8.8;
import "./PriceConverter.sol";

error notowner(); //custom error

contract fundme {
    using priceconvertor for uint256;
    uint256 public constant minusd = 50 * 1e18;
    address[] public funders;
    address public immutable owner;
    mapping(address => uint256) public addresstoamountfunded;

    AggregatorV3Interface public pricefeed;

    constructor(address pricefeedaddress) {
        owner = msg.sender;
        pricefeed = AggregatorV3Interface(pricefeedaddress);
    }

    function fund() public payable {
        //revert => transaction is reversed (i.e) deducted gas is returned to wallet

        require(
            msg.value.getconversionethTOusd(pricefeed) >= minusd,
            "Didn't send"
        ); // men=>m[n times 0]
        funders.push(msg.sender);
        addresstoamountfunded[msg.sender] = msg.value;
    }

    function withdraw(address reciever) public {
        for (uint i = 0; i < funders.length; i++) {
            addresstoamountfunded[funders[i]] = 0;
        }
        funders = new address[](0); //reset the array

        //TRANSFER ETH
        //transfer
        //  payable(msg.sender).transfer(address(this).balance);

        //  send
        //  bool sendsuccess = payable(msg.sender).send(address(this).balance);
        //  require(sendsuccess,"send fail");

        //call
        (bool callsuccess, ) = payable(reciever).call{
            value: address(this).balance
        }("");
        require(callsuccess, "call fail");
    }

    modifier onlyowner() {
        //require(msg.sender==owner,"Not the owner!");
        if (msg.sender != owner) {
            revert notowner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.8;

//import "./AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library priceconvertor {
    function getprice(
        AggregatorV3Interface pricefeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = pricefeed.latestRoundData();

        return uint256(price * 1e10);
    }

    function getconversionethTOusd(
        uint256 eth,
        AggregatorV3Interface pricefeed
    ) internal view returns (uint256) {
        uint256 ethprice = getprice(pricefeed);
        uint256 amountinusd = (ethprice * eth) / 1e18;
        return amountinusd;
    }
}