// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import {AggregatorV2V3Interface} from "AggregatorV2V3Interface.sol";
import {IWstETH} from "IWstETH.sol";
import {TypeConvert} from "TypeConvert.sol";

contract WstETHChainlinkOracle is AggregatorV2V3Interface {
    using TypeConvert for uint256;

    uint8 public override constant decimals = 18;
    uint256 public override constant version = 1;

    string public override description;
    AggregatorV2V3Interface public immutable baseOracle;
    int256 public immutable baseDecimals;
    IWstETH public immutable wstETH;

    constructor(AggregatorV2V3Interface baseOracle_, IWstETH wstETH_, string memory description_) {
        baseOracle = baseOracle_;
        wstETH = wstETH_;
        description = description_;
        baseDecimals = int256(10**baseOracle_.decimals());
    }

    function _calculateAnswer() internal view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        int256 baseAnswer;
        (
            roundId,
            baseAnswer,
            startedAt,
            updatedAt,
            answeredInRound
        ) = baseOracle.latestRoundData();
        require(baseAnswer > 0, "Chainlink Rate Error");

        answer = baseAnswer * wstETH.stEthPerToken().toInt() / baseDecimals;
    }

    function latestRoundData() external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return _calculateAnswer();
    }

    function latestAnswer() external view override returns (int256 answer) {
        (/* */, answer, /* */, /* */, /* */) = _calculateAnswer();
    }

    function latestTimestamp() external view override returns (uint256 updatedAt) {
        (/* */, /* */, /* */, updatedAt, /* */) = _calculateAnswer();
    }

    function latestRound() external view override returns (uint256 roundId) {
        (roundId, /* */, /* */, /* */, /* */) = _calculateAnswer();
    }

    function getRoundData(uint80 _roundId) external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        revert();
    }

    function getAnswer(uint256 roundId) external view override returns (int256) { revert(); }
    function getTimestamp(uint256 roundId) external view override returns (uint256) { revert(); }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "AggregatorInterface.sol";
import "AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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
pragma solidity >=0.7.6;

import {IERC20} from "IERC20.sol";

interface IWstETH is IERC20 {
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
    function stEthPerToken() external view returns (uint256);
    function stETH() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

library TypeConvert {

    function toUint(int256 x) internal pure returns (uint256) {
        require(x >= 0);
        return uint256(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        require (x <= uint256(type(int256).max)); // dev: toInt overflow
        return int256(x);
    }

    function toInt80(int256 x) internal pure returns (int80) {
        require (int256(type(int80).min) <= x && x <= int256(type(int80).max)); // dev: toInt overflow
        return int80(x);
    }

    function toUint80(uint256 x) internal pure returns (uint80) {
        require (x <= uint256(type(uint80).max));
        return uint80(x);
    }
}