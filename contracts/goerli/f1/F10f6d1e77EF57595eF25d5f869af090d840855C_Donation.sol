// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConvertor.sol";

/// @title Donate Funds
/// @author Mazen Jamshed
/// @notice Only use on testnet. Not fully tested yet

contract Donation {
    using PriceConvertor for uint256;

    error Donation__NotEnoughEth();
    mapping(address => uint256) public addressToAmountDonated; // amount donated by an address

    address private owner; // Deployer
    address[] public supporters; // Array of donators
    uint256 public constant MINIMUM_USD = 50 * 10**18;

    AggregatorV3Interface internal priceFeed;

    constructor(AggregatorV3Interface feedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(feedAddress);
    }

    // };

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    function passOwnership(address payable newOwner) public onlyOwner {
        owner = newOwner;
    }

    function Donate() public payable {
        if (msg.value.checkMinimumInUsd(priceFeed) < MINIMUM_USD)
            revert Donation__NotEnoughEth();

        // require(msg.value < 50000000000000000, "Not enough eth bitch");
        addressToAmountDonated[msg.sender] += msg.value;
        supporters.push(msg.sender);
    }

    function widthdraw(uint256 amount) public payable onlyOwner {
        if (amount > address(this).balance)
            revert("Insufficient Funds in contract!!");

        // payable(msg.sender).transfer(amount);

        (bool callSuccess, ) = payable(msg.sender).call{value: amount}("");
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
    // function decimals() public view returns (uint8 decimalPlaces) {
    //     return priceFeed.decimals();
    // }

    function getEthPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer * (10000000000)); // answer * 1 to the power of 10 to get 18 digit decimal
    }

    function checkMinimumInUsd(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 currentEth = getEthPrice(priceFeed); // current eth price with 18 decimals

        uint256 ethAmountInUsd = (currentEth * ethAmount) /
            (1000000000000000000);
        return ethAmountInUsd;
    }
}