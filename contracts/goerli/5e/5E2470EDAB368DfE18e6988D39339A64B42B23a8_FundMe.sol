// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "AggregatorV3Interface.sol";

contract FundMe {
    address owner;
    address[] senders;
    mapping(address => uint256) public senderToAmount;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        owner = msg.sender;
        // Goerli testnet
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getDecimals() public view returns (uint8) {
        return priceFeed.decimals();
    }

    // accepts ethAmount in wei, returns USD in wei
    function getUSDPrice(uint256 ethAmount) public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        uint256 rate = uint256(answer) * 10**(18 - getDecimals()); // 1 USD in ETH wei
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

    // returns how much ETH is needed (for $50), in wei
    function getEntranceFee() public view returns (uint256) {
        // minimum USD
        uint256 minimumUsdWei = 50 * 10**18;
        uint256 oneEthInUsdWei = getUSDPrice(1 * 10**18);
        return (minimumUsdWei * 10**18) / oneEthInUsdWei;
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