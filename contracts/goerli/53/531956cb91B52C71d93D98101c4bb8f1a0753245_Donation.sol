// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Donate Funds
/// @author Mazen Jamshed
/// @notice Only use on testnet. Not fully tested yet

contract Donation {
    mapping(address => uint256) public addressToAmountDonated; // amount donated by an address

    address private owner; // Deployer
    address[] public supporters; // Array of donators

    AggregatorV3Interface internal priceFeed;

    constructor(AggregatorV3Interface feedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(feedAddress);
    }

    function getEthPrice() public view returns (int256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return answer;
    }

    function decimals() external view returns (uint8 decimalPlaces) {
        return priceFeed.decimals();
    }

    // };

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    function passOwnership(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }

    //* Minimum amount 50$
    function Donate() public payable {
        addressToAmountDonated[msg.sender] += msg.value;
        supporters.push(msg.sender);
    }

    function widthdraw() public payable onlyOwner {
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
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