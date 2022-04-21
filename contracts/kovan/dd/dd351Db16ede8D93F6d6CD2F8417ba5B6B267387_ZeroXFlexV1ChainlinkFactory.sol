// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "IERC20.sol";

import "IZeroXFlexV1ChainlinkFactory.sol";

import "ZeroXFlexV1FeedFactory.sol";
import "ZeroXFlexV1ChainlinkFeed.sol";

contract ZeroXFlexV1ChainlinkFactory is IZeroXFlexV1ChainlinkFactory, ZeroXFlexV1FeedFactory {

    address public immutable feedRegistry;

    // registry of feeds; for a given an chainlink aggregator proxy address
    // returns associated feed
    mapping(address => address) public getFeed;

    constructor(
      address _feedRegistry,
      uint256 _microWindow,
      uint256 _macroWindow
    ) ZeroXFlexV1FeedFactory(
      _microWindow, 
      _macroWindow
    ) {

      feedRegistry = _feedRegistry;

    }

    /// @dev deploys a new feed contract
    /// @return feed_ address of the new feed
    function deployFeed(
      address _aggregatorProxy
    ) external returns (address feed_) {
        // get the pool address for market tokens


        // Create a new Feed contract
        feed_ = address(
            new ZeroXFlexV1ChainlinkFeed(
                _aggregatorProxy,
                microWindow,
                macroWindow
            )
        );

        // store feed registry record for
        // (marketPool, marketBaseToken, marketBaseAmount, flexXPool) combo
        // and record address as deployed feed
        getFeed[_aggregatorProxy] = feed_;
        isFeed[feed_] = true;
        emit FeedDeployed(msg.sender, feed_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "IZeroXFlexV1FeedFactory.sol";

interface IZeroXFlexV1ChainlinkFactory is IZeroXFlexV1FeedFactory {

    function feedRegistry() external view returns (address);

    // registry of feeds; for a given (pool, base, quote, amount) pair, returns associated feed
    function getFeed(
        address aggregatorProxy
    ) external view returns (address feed_);

    /// @dev deploys a new feed contract
    /// @return feed_ address of the new feed
    function deployFeed(
        address feed
    ) external returns (address feed_);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "Oracle.sol";

interface IZeroXFlexV1FeedFactory {
    // immutables
    function microWindow() external view returns (uint256);

    function macroWindow() external view returns (uint256);

    // registry of deployed feeds by factory
    function isFeed(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Oracle {
    struct Data {
        uint256 timestamp;
        uint256 microWindow;
        uint256 macroWindow;
        uint256 priceOverMicroWindow; // p(now) averaged over micro
        uint256 priceOverMacroWindow; // p(now) averaged over macro
        uint256 priceOneMacroWindowAgo; // p(now - macro) avg over macro
        uint256 reserveOverMicroWindow; // r(now) in flex averaged over micro
        bool hasReserve; // whether oracle has manipulable reserve pool
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "IZeroXFlexV1FeedFactory.sol";
import "Oracle.sol";

abstract contract ZeroXFlexV1FeedFactory is IZeroXFlexV1FeedFactory {
    uint256 public immutable microWindow;
    uint256 public immutable macroWindow;

    // registry of deployed feeds by factory
    mapping(address => bool) public isFeed;

    event FeedDeployed(address indexed user, address feed);

    constructor(uint256 _microWindow, uint256 _macroWindow) {
        // sanity checks on micro and macroWindow
        require(_microWindow > 0, "0xFLEX: microWindow == 0");
        require(_macroWindow >= _microWindow, "0xFLEX: macroWindow < microWindow");
        require(_macroWindow <= 86400, "0xFLEX: macroWindow > 1 day");

        microWindow = _microWindow;
        macroWindow = _macroWindow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

import "AggregatorV3Interface.sol";

import "ZeroXFlexV1Feed.sol";

import "IZeroXFlexV1ChainlinkFeed.sol";

contract ZeroXFlexV1ChainlinkFeed is IZeroXFlexV1ChainlinkFeed, ZeroXFlexV1Feed {

    AggregatorV3Interface public immutable feed;

    constructor(
        address _feed,
        uint256 _microWindow,
        uint256 _macroWindow
    ) ZeroXFlexV1Feed(_microWindow, _macroWindow) {

      feed = AggregatorV3Interface(_feed);

    }

    /// @dev fetches TWAP, liquidity data from the univ3 pool oracle
    /// @dev for micro and macro window averaging intervals.
    /// @dev market pool and flexX pool have different consult inputs
    /// @dev to minimize accumulator snapshot queries with consult
    function _fetch() internal view virtual override returns (Oracle.Data memory) { 

      (,int price,,,) = feed.latestRoundData();

      return Oracle.Data(
        block.timestamp,
        600,
        3600,
        uint(price),
        uint(price),
        uint(price),
        0,
        false
      );

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "IZeroXFlexV1Feed.sol";
import "Oracle.sol";

abstract contract ZeroXFlexV1Feed is IZeroXFlexV1Feed {
    using Oracle for Oracle.Data;

    address public immutable feedFactory;
    uint256 public immutable microWindow;
    uint256 public immutable macroWindow;

    constructor(uint256 _microWindow, uint256 _macroWindow) {
        // set the immutables
        microWindow = _microWindow;
        macroWindow = _macroWindow;
        feedFactory = msg.sender;
    }

    /// @dev returns freshest possible data from oracle
    function latest() external view returns (Oracle.Data memory) {
        return _fetch();
    }

    /// @dev fetches data from oracle. should be implemented differently
    /// @dev for each feed type
    function _fetch() internal view virtual returns (Oracle.Data memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "Oracle.sol";

interface IZeroXFlexV1Feed {
    // immutables
    function feedFactory() external view returns (address);

    function microWindow() external view returns (uint256);

    function macroWindow() external view returns (uint256);

    // returns freshest possible data from oracle
    function latest() external view returns (Oracle.Data memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "IZeroXFlexV1Feed.sol";
import "AggregatorV3Interface.sol";

interface IZeroXFlexV1ChainlinkFeed is IZeroXFlexV1Feed {

    // @dev chainlink feed
    function feed() external view returns (AggregatorV3Interface);

}