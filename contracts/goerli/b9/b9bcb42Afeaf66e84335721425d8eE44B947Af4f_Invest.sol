// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./lib/Price.sol";

error YouAreNotOwner();
error NoShareLeft();
error NotEnoughEth();

contract Invest {
    using Price for uint256;

    AggregatorV3Interface private s_dataFeed;
    address private immutable i_owner;
    address[] private s_investors;
    mapping(address => uint256) private s_addressToAmountInvested;
    uint256 public constant s_sharePrice = 10;
    uint256 public constant s_totalShares = 500;
    uint256 private s_sharesLeft;

    event Invested(address indexed _investor, uint256 _shareAmount);

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert YouAreNotOwner();
        }
        _;
    }

    modifier ifAvailable() {
        if (s_sharesLeft == 0) {
            revert NoShareLeft();
        }
        _;
    }

    constructor(address dataFeed) {
        s_dataFeed = AggregatorV3Interface(dataFeed);
        i_owner = msg.sender;
        s_sharesLeft = 500;
    }

    function invest() public payable ifAvailable {
        if (msg.value.getInUsd(s_dataFeed) < s_sharePrice) {
            revert NotEnoughEth();
        }
        uint256 numOfShares = msg.value.shareAmount(s_dataFeed);
        emit Invested(msg.sender, numOfShares);
        unchecked {s_sharesLeft -= numOfShares;}
        s_addressToAmountInvested[msg.sender] += msg.value;
        s_investors.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }


    function getVersion() public view returns (uint256) {
        return s_dataFeed.version();
    }

    function getDataFeed() public view returns (AggregatorV3Interface) {
        return s_dataFeed;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getInvestor(uint256 index) public view returns (address) {
        return s_investors[index];
    }

    function getAddressToAmountInvested(address investor) public view returns (uint256) {
        return s_addressToAmountInvested[investor];
    }

    function knowShareLeft() public view returns (uint256) {
        return s_sharesLeft;
    }
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library Price {
    function getRawPrice(AggregatorV3Interface dataFeed) internal view returns (uint256) {
        (, int256 answer, , , ) = dataFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getInUsd(uint256 ethAmount, AggregatorV3Interface dataFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getRawPrice(dataFeed);
        uint256 ethPriceInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethPriceInUsd;
    }

    function shareAmount(uint256 ethAmount, AggregatorV3Interface dataFeed)
        internal
        view
        returns (uint256)
    {
        uint256 Usd = getInUsd(ethAmount, dataFeed);
        uint256 sharesAmount = Usd / 10000000000000000000;
        return (sharesAmount);
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