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
pragma solidity ^0.8.10;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

contract FundMe {
    using PriceConverter for uint256;

    uint256 public minimumUsd = 50 * 1e18;
    address[] public donaters;
    mapping(address => uint256) public addressToAmount;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address priceAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceAddress);
    }

    function fund() public payable {
        require(
            msg.value.priceConverter(priceFeed) > minimumUsd,
            "Didnt send emough eth"
        );
        donaters.push(msg.sender);
        addressToAmount[msg.sender] += msg.value;
    }

    function withDraw() public onlyOwner {
        //  require(msg.sender==owner,"You are not the owner");
        for (
            uint256 funderIndex;
            funderIndex < donaters.length;
            funderIndex++
        ) {
            address funder = donaters[funderIndex];
            addressToAmount[funder] = 0;
        }

        donaters = new address[](0);
        //3 way to withdarw money
        //transfer
        //send
        //call
        //msg.sender = refer to address
        //payable(msg.sender) = refer to paybale address

        //transfer
        //     payable(msg.sender).transfer(address(this).balance);

        //send
        //    bool paySuccess =  payable(msg.sender).send(address(this).balance);
        //    require(paySuccess,"Pay failed");

        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Pay failed");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
}

// contract fundMe {

//      uint256 public minimumUsd =50*1e18;

//      function fund()public payable {

//           require( geConversionRate(msg.value) >=minimumUsd,"Didn't send enough eth");

//      }

//      function getPrice()public view returns (uint256) {
//        AggregatorV3Interface priceFeed =   AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
//      (,int price,,,) =  priceFeed.latestRoundData();
//      return  uint256(price*1e10);
//      }
//      function geConversionRate(uint256 _ethamount)public view returns(uint256)  {

//           uint256 ethPrice  = getPrice();
//           uint256 ethamountInUsd = (ethPrice*_ethamount) /1e18;
//           return  ethamountInUsd;

//       }

// }

//0x694AA1769357215DE4FAC081bf1f309aDC325306

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint(price * 1e10);
    }

    function priceConverter(
        uint256 _ethEmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 totalpriceinUsd = (ethPrice * _ethEmount) / 1e18;
        return totalpriceinUsd;
    }
}