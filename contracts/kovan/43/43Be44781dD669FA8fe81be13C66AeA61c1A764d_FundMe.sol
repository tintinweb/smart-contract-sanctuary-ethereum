// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "AggregatorV3Interface.sol";
import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;

    function fund() public payable {
        uint256 minimumUSD = 50 * 10**18;
        // require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH! ");
        addressToAmountFunded[msg.sender] += msg.value;
    }

    address public owner;

    constructor() public {
        // called right after the contract is created
        owner = msg.sender;
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        ).latestRoundData(); //ETH -> USD
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        return (ethAmount * getPrice()) / 100000000000000000000; //ETH -> USD
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You have no permissions to revert the transaction"
        );
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance); // message sender get all the money on this xontract transfered to him/her
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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