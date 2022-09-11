// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./priceconverter.sol";

contract Payment {
    using PriceConverter for uint256;
    //error codes
    error Not__SignedIn();
    error Payment__Failed(uint256 paidAmt, uint256 requiredAmt);
    error Transaction__Failed();

    //state variables
    address private immutable i_owner;
    uint256 public s_totalCost;
    address[] public s_users;
    mapping(address => uint256) public s_payments;
    uint256 public s_costInRs;

    AggregatorV3Interface private s_priceFeed;
    //Enum
    enum appState {
        OPEN,
        CLOSED
    }
    appState private s_appState;
    //Events
    event SignedIn(address appUser);
    event gotAmount(uint256 amt);
    event txSuccess();

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
        s_appState = appState.CLOSED;
    }

    function signIn(address user) public {
        for (uint256 i = 0; i < s_users.length; i++) {
            if (user == s_users[i]) {
                emit SignedIn(user);
                s_appState = appState.OPEN;
            }
        }

        s_users.push(user);
        emit SignedIn(user);
        s_appState = appState.OPEN;
    }

    function getAmount(uint256 amount) public {
        if (s_appState != appState.OPEN) {
            revert Not__SignedIn();
        }
        s_costInRs = amount;
        s_totalCost = PriceConverter.getEthInRs(s_priceFeed, s_costInRs);

        emit gotAmount(s_totalCost);
    }

    function makePayment() public payable {
        if (s_appState != appState.OPEN) {
            revert Not__SignedIn();
        }
        if (msg.value != s_totalCost) {
            revert Payment__Failed(msg.value, s_totalCost);
        }
        s_payments[msg.sender] = msg.value;

        (bool success, ) = i_owner.call{value: address(this).balance}("");
        if (!success) {
            revert Transaction__Failed();
        }
        emit txSuccess();
        s_appState = appState.CLOSED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//Using ChainLink's Datafeed to convert ethers to Rupees!
library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit which will be then converted to Rupees!
        return uint256(answer * 80 * 10000000000);
    }

    function getEthInRs(AggregatorV3Interface priceFeed, uint256 amt)
        internal
        view
        returns (uint256)
    {
        uint256 costInRs;
        costInRs = getPrice(priceFeed);
        uint totalCost = ((amt * 10**18) / costInRs) / 10**18;
        return totalCost;
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