// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/IFPIControllerPool.sol";

contract FPIOracle is AggregatorV3Interface {
    using SafeCast for uint256;

    IFPIControllerPool public immutable fpiControllerPool;
    uint8 public immutable FPI_ORACLE_DECIMALS;

    constructor(address _fpiControllerPoolAddress, uint8 _fpiOracleDecimals) {
        fpiControllerPool = IFPIControllerPool(_fpiControllerPoolAddress);
        FPI_ORACLE_DECIMALS = _fpiOracleDecimals;
    }

    /// @notice The ```decimals``` function represents the number of decimals the aggregator responses represent.
    function decimals() external view returns (uint8) {
        return FPI_ORACLE_DECIMALS;
    }

    /// @notice The ```description``` function retuns the items represented as Item / Units
    function description() external pure returns (string memory) {
        return "FPI / USD";
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        pure
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        revert("No Implementation for getRoundData");
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 0;
        startedAt = 0;
        updatedAt = 0;
        answeredInRound = 0;

        answer = fpiControllerPool.getFPIPriceE18().toInt256();
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.8.17;

// NOTE: This file generated from FPIController contract at https://etherscan.io/address/0x2397321b301B80A1C0911d6f9ED4b6033d43cF51#code

interface IFPIControllerPool {
    function FEE_PRECISION() external view returns (uint256);

    function FPI_TKN() external view returns (address);

    function FRAX() external view returns (address);

    function PEG_BAND_PRECISION() external view returns (uint256);

    function PRICE_PRECISION() external view returns (uint256);

    function TWAMM() external view returns (address);

    function acceptOwnership() external;

    function addAMO(address amo_address) external;

    function amos(address) external view returns (bool);

    function amos_array(uint256) external view returns (address);

    function burnFPI(bool burn_all, uint256 fpi_amount) external;

    function calcMintFPI(uint256 frax_in, uint256 min_fpi_out) external view returns (uint256 fpi_out);

    function calcRedeemFPI(uint256 fpi_in, uint256 min_frax_out) external view returns (uint256 frax_out);

    function cancelCurrTWAMMOrder(uint256 order_id_override) external;

    function chainlink_fpi_usd_decimals() external view returns (uint256);

    function chainlink_frax_usd_decimals() external view returns (uint256);

    function collectCurrTWAMMProceeds(uint256 order_id_override) external;

    function cpiTracker() external view returns (address);

    function dollarBalances() external view returns (uint256 frax_val_e18, uint256 collat_val_e18);

    function fpi_mint_cap() external view returns (uint256);

    function frax_borrow_cap() external view returns (int256);

    function frax_borrowed_balances(address) external view returns (int256);

    function frax_borrowed_sum() external view returns (int256);

    function frax_is_token0() external view returns (bool);

    function getFPIPriceE18() external view returns (uint256);

    function getFRAXPriceE18() external view returns (uint256);

    function getReservesAndFPISpot()
        external
        returns (
            uint256 reserveFRAX,
            uint256 reserveFPI,
            uint256 fpi_price
        );

    function giveFRAXToAMO(address destination_amo, uint256 frax_amount) external;

    function last_order_id_twamm() external view returns (uint256);

    function max_swap_fpi_amt_in() external view returns (uint256);

    function max_swap_frax_amt_in() external view returns (uint256);

    function mintFPI(uint256 frax_in, uint256 min_fpi_out) external returns (uint256 fpi_out);

    function mint_fee() external view returns (uint256 fee);

    function mint_fee_manual() external view returns (uint256);

    function mint_fee_multiplier() external view returns (uint256);

    function mints_paused() external view returns (bool);

    function nominateNewOwner(address _owner) external;

    function nominatedOwner() external view returns (address);

    function num_twamm_intervals() external view returns (uint256);

    function owner() external view returns (address);

    function pegStatusMntRdm()
        external
        view
        returns (
            uint256 cpi_peg_price,
            uint256 diff_frac_abs,
            bool within_range
        );

    function peg_band_mint_redeem() external view returns (uint256);

    function peg_band_twamm() external view returns (uint256);

    function pending_twamm_order() external view returns (bool);

    function priceFeedFPIUSD() external view returns (address);

    function priceFeedFRAXUSD() external view returns (address);

    function price_info()
        external
        view
        returns (
            int256 collat_imbalance,
            uint256 cpi_peg_price,
            uint256 fpi_price,
            uint256 price_diff_frac_abs
        );

    function receiveFRAXFromAMO(uint256 frax_amount) external;

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function redeemFPI(uint256 fpi_in, uint256 min_frax_out) external returns (uint256 frax_out);

    function redeem_fee() external view returns (uint256 fee);

    function redeem_fee_manual() external view returns (uint256);

    function redeem_fee_multiplier() external view returns (uint256);

    function redeems_paused() external view returns (bool);

    function removeAMO(address amo_address) external;

    function setFraxBorrowCap(int256 _frax_borrow_cap) external;

    function setMintCap(uint256 _fpi_mint_cap) external;

    function setMintRedeemFees(
        bool _use_manual_mint_fee,
        uint256 _mint_fee_manual,
        uint256 _mint_fee_multiplier,
        bool _use_manual_redeem_fee,
        uint256 _redeem_fee_manual,
        uint256 _redeem_fee_multiplier
    ) external;

    function setOracles(
        address _frax_oracle,
        address _fpi_oracle,
        address _cpi_oracle
    ) external;

    function setPegBands(uint256 _peg_band_mint_redeem, uint256 _peg_band_twamm) external;

    function setTWAMMAndSwapPeriod(address _twamm_addr, uint256 _swap_period) external;

    function setTWAMMMaxSwapIn(uint256 _max_swap_frax_amt_in, uint256 _max_swap_fpi_amt_in) external;

    function setTimelock(address _new_timelock_address) external;

    function swap_period() external view returns (uint256);

    function timelock_address() external view returns (address);

    function toggleMints() external;

    function toggleRedeems() external;

    function twammManual(
        uint256 frax_sell_amt,
        uint256 fpi_sell_amt,
        uint256 override_intervals
    ) external returns (uint256 frax_to_use, uint256 fpi_to_use);

    function use_manual_mint_fee() external view returns (bool);

    function use_manual_redeem_fee() external view returns (bool);
}