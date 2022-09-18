// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "AggregatorV3Interface.sol";

contract FundMe {
    address owner;
    address[] senders;
    mapping(address => uint256) public senderToAmount;
    AggregatorV3Interface priceFeed;

    constructor() {
        owner = msg.sender;
        // Goerli testnet
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }

    function getUSDPrice(uint256 ethAmount) public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        uint256 rate = uint256(answer) * 10**10; // 1 USD in ETH wei
        // ethAmount is in ETH wei
        return (ethAmount * rate) / 10**18;
    }

    function fund() public payable {
        require(
            getUSDPrice(msg.value) >= 50 * 10**18,
            "You must fund with more than $50 USD worth of value!"
        );
        senders.push(msg.sender);
        senderToAmount[msg.sender] = msg.value;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You must be the owner of this contract to execute this operation!"
        );
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        // reset
        for (uint256 i = 0; i < senders.length; i++) {
            senderToAmount[senders[i]] = 0;
        }
        senders = new address[](0);
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