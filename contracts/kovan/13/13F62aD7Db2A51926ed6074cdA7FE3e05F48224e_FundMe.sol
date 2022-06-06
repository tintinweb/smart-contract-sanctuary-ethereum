// SPDX-License-Identifier: MIT
import "AggregatorV3Interface.sol";

pragma solidity ^0.8.14;

contract FundMe {
    mapping(address => uint256) public addressFundedAmount;
    address[] public funders;
    address owner;

    constructor() {
        owner = msg.sender; // sender of the message is us
        // one that deploys the smart contract
    }

    function fund() public payable {
        uint256 minUSD = 50 * 10**18;

        require(convert(msg.value) >= minUSD, "You need to spend more ETH!");
        addressFundedAmount[msg.sender] += msg.value;

        funders.push(msg.sender); // storing fundres address into array
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface rate = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        return rate.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface rate = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        (, int256 answer, , , ) = rate.latestRoundData();

        return uint256(answer);
    }

    function convert(uint256 fundedAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 inUSD = (ethPrice * fundedAmount) / 1000000000000000000;
        return inUSD;
    }

    modifier admin() {
        require(msg.sender == owner);
        _;
    }

    function withDraw() public payable admin {
        payable(msg.sender).transfer(address(this).balance);

        // to reset the amount
        for (uint256 index = 0; index < funders.length; index++) {
            address funderAddress = funders[index];
            addressFundedAmount[funderAddress] = 0;
        }
        funders = new address[](0); // resetting array
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