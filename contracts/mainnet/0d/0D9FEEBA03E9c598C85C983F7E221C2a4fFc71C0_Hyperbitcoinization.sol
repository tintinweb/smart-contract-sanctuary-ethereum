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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

/// ============ Imports ============

import {IERC20} from "./interfaces/IERC20.sol"; // ERC20 minified interface
import {AggregatorV3Interface} from "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // Chainlink pricefeed

/// @title Hyperbitcoinization
/// @author Anish Agnihotri
/// @notice Simple 1M USDC vs 1 wBTC 90-day bet cleared by Chainlink
contract Hyperbitcoinization {
    /// ============ Structs ============

    /// @notice Individual bet
    struct Bet {
        /// @notice Has bet already been settled
        bool settled;
        /// @notice Has partyUSDC sent funds
        bool USDCSent;
        /// @notice Has partyWBTC sent funds
        bool WBTCSent;
        /// @notice Party providing USDC
        address partyUSDC;
        /// @notice Party providing wBTC
        address partyWBTC;
        /// @notice Bet starting timestamp
        uint256 startTimestamp;
    }

    /// ============ Constants ============

    /// @notice 90 days
    uint256 public constant BET_DURATION = 90 days;
    /// @notice USDC amount
    uint256 public constant USDC_AMOUNT = 1_000_000e6;
    /// @notice wBTC amount
    uint256 public constant WBTC_AMOUNT = 1e8;
    /// @notice winning BTC/USD price
    uint256 public constant WINNING_BTC_PRICE = 1_000_000;

    /// ============ Immutable storage ============

    /// @notice USDC token
    IERC20 public immutable USDC_TOKEN;
    /// @notice WBTC token
    IERC20 public immutable WBTC_TOKEN;
    /// @notice BTC/USD price feed (Chainlink)
    AggregatorV3Interface public immutable BTCUSD_PRICEFEED;

    /// ============ Mutable storage ============

    /// @notice ID of current bet (next = curr + 1)
    uint256 public currentBetId = 0;
    /// @notice Mapping of bet id => bet
    mapping(uint256 => Bet) public bets;

    /// ============ Constructor ============

    /// @notice Creates a new Hyperbitcoinization contract
    /// @param _USDC_TOKEN address of USDC token
    /// @param _WBTC_TOKEN address of WBTC token
    /// @param _BTCUSD_PRICEFEED address of pricefeed for BTC/USD
    constructor(address _USDC_TOKEN, address _WBTC_TOKEN, address _BTCUSD_PRICEFEED) {
        USDC_TOKEN = IERC20(_USDC_TOKEN);
        WBTC_TOKEN = IERC20(_WBTC_TOKEN);
        BTCUSD_PRICEFEED = AggregatorV3Interface(_BTCUSD_PRICEFEED);
    }

    /// ============ Functions ============

    /// @notice Creates a new bet between two parties
    /// @param partyUSDC providing USDC
    /// @param partyWBTC providing wBTC
    function createBet(address partyUSDC, address partyWBTC) external returns (uint256) {
        currentBetId++;
        bets[currentBetId] = Bet({
            settled: false,
            USDCSent: false,
            WBTCSent: false,
            partyUSDC: partyUSDC,
            partyWBTC: partyWBTC,
            startTimestamp: 0
        });
        return currentBetId;
    }

    /// @notice Allows partyUSDC to add USDC to a bet.
    /// @dev Requires user to approve contract.
    /// @param betId to add funds to
    function addUSDC(uint256 betId) external {
        Bet storage bet = bets[betId];
        require(!bet.USDCSent, "USDC already added");
        require(msg.sender == bet.partyUSDC, "User not part of bet");

        // Transfer USDC
        USDC_TOKEN.transferFrom(msg.sender, address(this), USDC_AMOUNT);

        // Toggle USDC sent
        bet.USDCSent = true;

        // Start bet if both parties sent
        if (bet.WBTCSent) bet.startTimestamp = block.timestamp;
    }

    /// @notice Allows partyWBTC to add wBTC to a bet.
    /// @dev Requires user to approve contract.
    /// @param betId to add funds to
    function addWBTC(uint256 betId) external {
        Bet storage bet = bets[betId];
        require(!bet.WBTCSent, "wBTC already added");
        require(msg.sender == bet.partyWBTC, "User not part of bet");

        // Transfer WBTC
        WBTC_TOKEN.transferFrom(msg.sender, address(this), WBTC_AMOUNT);

        // Toggle wBTC sent
        bet.WBTCSent = true;

        // Start bet if both parties sent
        if (bet.USDCSent) bet.startTimestamp = block.timestamp;
    }

    /// @notice Collect BTC/USD price from Chainlink
    function getBTCPrice() public view returns (uint256) {
        // Collect BTC price
        (, int256 price,,,) = BTCUSD_PRICEFEED.latestRoundData();
        return uint256(price) / 10 ** BTCUSD_PRICEFEED.decimals();
    }

    /// @notice Allows anyone to settle an existing bet
    /// @param betId to settle
    function settleBet(uint256 betId) external {
        Bet storage bet = bets[betId];
        require(!bet.settled, "Bet already settled");
        require(block.timestamp >= bet.startTimestamp + BET_DURATION, "Bet still pending");

        // Mark bet settled
        bet.settled = true;

        // Check for winner
        address winner = getBTCPrice() > WINNING_BTC_PRICE ? bet.partyUSDC : bet.partyWBTC;

        // Send funds to winner
        USDC_TOKEN.transfer(winner, USDC_AMOUNT);
        WBTC_TOKEN.transfer(winner, WBTC_AMOUNT);
    }

    /// @notice Allows any bet party to withdraw funds while bet is pending
    /// @param betId to withdraw
    function withdrawStale(uint256 betId) external {
        Bet storage bet = bets[betId];
        require(bet.startTimestamp == 0, "Bet already started");
        require(msg.sender == bet.partyUSDC || msg.sender == bet.partyWBTC, "Not bet participant");

        // If USDC received, return USDC
        if (bet.USDCSent) {
            bet.USDCSent = false;
            USDC_TOKEN.transfer(bet.partyUSDC, USDC_AMOUNT);
        }
        // If wBTC received, return wBTC
        if (bet.WBTCSent) {
            bet.WBTCSent = false;
            WBTC_TOKEN.transfer(bet.partyWBTC, WBTC_AMOUNT);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface IERC20 {
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}