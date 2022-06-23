// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IWAMPL} from "../interfaces/IWAMPL.sol";
import {IChainlinkAggregator} from "../interfaces/IChainlinkAggregator.sol";

/**
 * @title WamplOracle Oracle
 *
 * @notice Provides a value onchain from a chainlink oracle aggregator
 */
contract WamplOracle is IOracle {
    /// @dev The output price has a 8 decimal point precision.
    uint256 public constant PRICE_DECIMALS = 8;
    // The address of the Chainlink Aggregator contract
    IChainlinkAggregator public immutable amplEthOracle;
    IChainlinkAggregator public immutable ethUsdOracle;
    IWAMPL public immutable wampl;
    uint256 public immutable stalenessThresholdSecs;
    uint256 public immutable amplDecimals;
    uint256 public immutable wamplDecimals;
    int256 public immutable convertPriceByDecimals;

    constructor(
        IChainlinkAggregator _amplEthOracle,
        IChainlinkAggregator _ethUsdOracle,
        IWAMPL _wampl,
        uint256 _stalenessThresholdSecs
    ) {
        amplEthOracle = _amplEthOracle;
        ethUsdOracle = _ethUsdOracle;
        wampl = _wampl;
        stalenessThresholdSecs = _stalenessThresholdSecs;
        amplDecimals = uint256(IERC20Metadata(_wampl.underlying()).decimals());
        wamplDecimals = uint256(_wampl.decimals());
        convertPriceByDecimals =
            int256(uint256(_amplEthOracle.decimals())) +
            int256(uint256(_ethUsdOracle.decimals())) -
            int256(PRICE_DECIMALS);
    }

    /**
     * @notice Fetches the latest market price from chainlink
     * @return Value: Latest market price as an 8 decimal fixed point number.
     *         valid: Boolean indicating an value was fetched successfully.
     */
    function getData() external view override returns (uint256, bool) {
        (, int256 amplEth, , uint256 amplEthUpdatedAt, ) = amplEthOracle.latestRoundData();
        (, int256 ethUsd, , uint256 ethUsdUpdatedAt, ) = ethUsdOracle.latestRoundData();
        uint256 amplEthDiff = block.timestamp - amplEthUpdatedAt;
        uint256 ethUsdDiff = block.timestamp - ethUsdUpdatedAt;
        uint256 amplUsd = uint256(amplEth) * uint256(ethUsd);
        if (convertPriceByDecimals > 0) {
            amplUsd = amplUsd / (10**uint256(convertPriceByDecimals));
        } else if (convertPriceByDecimals < 0) {
            amplUsd = amplUsd * (10**uint256(-convertPriceByDecimals));
        }
        uint256 amplPerWampl = wampl.wrapperToUnderlying(10**wamplDecimals);
        uint256 wamplUsd = (amplUsd * amplPerWampl) / (10**amplDecimals);
        return (
            wamplUsd,
            amplEthDiff <= stalenessThresholdSecs && ethUsdDiff <= stalenessThresholdSecs
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later

interface IOracle {
    function getData() external view returns (uint256, bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

interface IWAMPL {
    function decimals() external view returns (uint8);

    function underlying() external view returns (address);

    function wrapperToUnderlying(uint256 wamples) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IChainlinkAggregator {
    function decimals() external view returns (uint8);

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