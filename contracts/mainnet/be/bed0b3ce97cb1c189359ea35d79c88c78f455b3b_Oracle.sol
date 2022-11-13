/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero() internal pure returns (D256 memory) {
        return D256({value: 0});
    }

    function one() internal pure returns (D256 memory) {
        return D256({value: BASE});
    }

    function from(uint256 a) internal pure returns (D256 memory) {
        return D256({value: a.mul(BASE)});
    }

    function ratio(uint256 a, uint256 b) internal pure returns (D256 memory) {
        return D256({value: getPartial(a, BASE, b)});
    }

    // ============ Self Functions ============

    function add(D256 memory self, uint256 b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.add(b.mul(BASE))});
    }

    function sub(D256 memory self, uint256 b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.sub(b.mul(BASE))});
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    ) internal pure returns (D256 memory) {
        return D256({value: self.value.sub(b.mul(BASE), reason)});
    }

    function mul(D256 memory self, uint256 b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.mul(b)});
    }

    function div(D256 memory self, uint256 b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.div(b)});
    }

    function pow(D256 memory self, uint256 b)
        internal
        pure
        returns (D256 memory)
    {
        if (b == 0) {
            return from(1);
        }

        D256 memory temp = D256({value: self.value});
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(D256 memory self, D256 memory b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.add(b.value)});
    }

    function sub(D256 memory self, D256 memory b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: self.value.sub(b.value)});
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    ) internal pure returns (D256 memory) {
        return D256({value: self.value.sub(b.value, reason)});
    }

    function mul(D256 memory self, D256 memory b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: getPartial(self.value, b.value, BASE)});
    }

    function div(D256 memory self, D256 memory b)
        internal
        pure
        returns (D256 memory)
    {
        return D256({value: getPartial(self.value, BASE, b.value)});
    }

    function equals(D256 memory self, D256 memory b)
        internal
        pure
        returns (bool)
    {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b)
        internal
        pure
        returns (bool)
    {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b)
        internal
        pure
        returns (bool)
    {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b)
        internal
        pure
        returns (bool)
    {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b)
        internal
        pure
        returns (bool)
    {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) private pure returns (uint256) {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(D256 memory a, D256 memory b)
        private
        pure
        returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

library Constants {
    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet

    /* Bootstrapping */
    uint256 private constant BOOTSTRAPPING_PERIOD = 672; // 14 days
    uint256 private constant BOOTSTRAPPING_PRICE = 1078280614764947472; // Should be 0.1 difference between peg

    /* Oracle */
    address private constant CRV3 =
        address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490); // Anywhere the term CRV3 is refernenced, consider that as "peg", really
    uint256 private constant ORACLE_RESERVE_MINIMUM = 1e22; // 10,000 T

    /* Bonding */
    uint256 private constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 T -> 100M TS

    /* Epoch */
    struct EpochStrategy {
        uint256 offset;
        uint256 start;
        uint256 period;
    }

    uint256 private constant CURRENT_EPOCH_OFFSET = 0;
    uint256 private constant CURRENT_EPOCH_START = 1667790000;
    uint256 private constant CURRENT_EPOCH_PERIOD = 1800;

    /* Forge */
    uint256 private constant ADVANCE_INCENTIVE_IN_3CRV = 75 * 10**18; // 75 3CRV
    uint256 private constant ADVANCE_INCENTIVE_IN_T_MAX = 5000 * 10**18; // 5000 T

    uint256 private constant FORGE_EXIT_LOCKUP_EPOCHS = 240; // 5 days fluid

    /* Pool */
    uint256 private constant POOL_EXIT_LOCKUP_EPOCHS = 144; // 3 days fluid

    /* Market */
    uint256 private constant COUPON_EXPIRATION = 8640; // 180 days
    uint256 private constant DEBT_RATIO_CAP = 20e16; // 20%

    /* Regulator */
    uint256 private constant SUPPLY_CHANGE_LIMIT = 1e16; // 1%
    uint256 private constant COUPON_SUPPLY_CHANGE_LIMIT = 2e16; // 2%
    uint256 private constant ORACLE_POOL_RATIO = 50; // 50%
    uint256 private constant TREASURY_RATIO = 0; // 0%

    /* Deployed */
    address private constant TREASURY_ADDRESS =
        address(0x0000000000000000000000000000000000000000);

    /**
     * Getters
     */

    function getCrv3Address() internal pure returns (address) {
        return CRV3;
    }

    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }

    function getCurrentEpochStrategy()
        internal
        pure
        returns (EpochStrategy memory)
    {
        return
            EpochStrategy({
                offset: CURRENT_EPOCH_OFFSET,
                start: CURRENT_EPOCH_START,
                period: CURRENT_EPOCH_PERIOD
            });
    }

    function getInitialStakeMultiple() internal pure returns (uint256) {
        return INITIAL_STAKE_MULTIPLE;
    }

    function getBootstrappingPeriod() internal pure returns (uint256) {
        return BOOTSTRAPPING_PERIOD;
    }

    function getBootstrappingPrice()
        internal
        pure
        returns (Decimal.D256 memory)
    {
        return Decimal.D256({value: BOOTSTRAPPING_PRICE});
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return ADVANCE_INCENTIVE_IN_3CRV;
    }

    function getMaxAdvanceTIncentive() internal pure returns (uint256) {
        return ADVANCE_INCENTIVE_IN_T_MAX;
    }

    function getForgeExitLockupEpochs() internal pure returns (uint256) {
        return FORGE_EXIT_LOCKUP_EPOCHS;
    }

    function getPoolExitLockupEpochs() internal pure returns (uint256) {
        return POOL_EXIT_LOCKUP_EPOCHS;
    }

    function getCouponExpiration() internal pure returns (uint256) {
        return COUPON_EXPIRATION;
    }

    function getDebtRatioCap() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DEBT_RATIO_CAP});
    }

    function getSupplyChangeLimit()
        internal
        pure
        returns (Decimal.D256 memory)
    {
        return Decimal.D256({value: SUPPLY_CHANGE_LIMIT});
    }

    function getCouponSupplyChangeLimit()
        internal
        pure
        returns (Decimal.D256 memory)
    {
        return Decimal.D256({value: COUPON_SUPPLY_CHANGE_LIMIT});
    }

    function getOraclePoolRatio() internal pure returns (uint256) {
        return ORACLE_POOL_RATIO;
    }

    function getTreasuryRatio() internal pure returns (uint256) {
        return TREASURY_RATIO;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getTreasuryAddress() internal pure returns (address) {
        return TREASURY_ADDRESS;
    }
}

interface IMetaPool {
    event Transfer(
        address indexed sender,
        address indexed receiver,
        uint256 value
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event TokenExchange(
        address indexed buyer,
        int128 sold_id,
        uint256 tokens_sold,
        int128 bought_id,
        uint256 tokens_bought
    );
    event TokenExchangeUnderlying(
        address indexed buyer,
        int128 sold_id,
        uint256 tokens_sold,
        int128 bought_id,
        uint256 tokens_bought
    );
    event AddLiquidity(
        address indexed provider,
        uint256[2] token_amounts,
        uint256[2] fees,
        uint256 invariant,
        uint256 token_supply
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256[2] token_amounts,
        uint256[2] fees,
        uint256 token_supply
    );
    event RemoveLiquidityOne(
        address indexed provider,
        uint256 token_amount,
        uint256 coin_amount,
        uint256 token_supply
    );
    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[2] token_amounts,
        uint256[2] fees,
        uint256 invariant,
        uint256 token_supply
    );
    event CommitNewAdmin(uint256 indexed deadline, address indexed admin);
    event NewAdmin(address indexed admin);
    event CommitNewFee(
        uint256 indexed deadline,
        uint256 fee,
        uint256 admin_fee
    );
    event NewFee(uint256 fee, uint256 admin_fee);
    event RampA(
        uint256 old_A,
        uint256 new_A,
        uint256 initial_time,
        uint256 future_time
    );
    event StopRampA(uint256 A, uint256 t);

    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _coin,
        uint256 _decimals,
        uint256 _A,
        uint256 _fee,
        address _admin
    ) external;

    function decimals() external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function get_previous_balances() external view returns (uint256[2] memory);

    function get_balances() external view returns (uint256[2] memory);

    function get_twap_balances(
        uint256[2] calldata _first_balances,
        uint256[2] calldata _last_balances,
        uint256 _time_elapsed
    ) external view returns (uint256[2] memory);

    function get_price_cumulative_last()
        external
        view
        returns (uint256[2] memory);

    function admin_fee() external view returns (uint256);

    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(
        uint256[2] calldata _amounts,
        bool _is_deposit,
        bool _previous
    ) external view returns (uint256);

    function add_liquidity(
        uint256[2] calldata _amounts,
        uint256 _min_mint_amount
    ) external returns (uint256);

    function add_liquidity(
        uint256[2] calldata _amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[2] calldata _balances
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[2] calldata _balances
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address _receiver
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address _receiver
    ) external returns (uint256);

    function remove_liquidity(
        uint256 _burn_amount,
        uint256[2] calldata _min_amounts
    ) external returns (uint256[2] memory);

    function remove_liquidity(
        uint256 _burn_amount,
        uint256[2] calldata _min_amounts,
        address _receiver
    ) external returns (uint256[2] memory);

    function remove_liquidity_imbalance(
        uint256[2] calldata _amounts,
        uint256 _max_burn_amount
    ) external returns (uint256);

    function remove_liquidity_imbalance(
        uint256[2] calldata _amounts,
        uint256 _max_burn_amount,
        address _receiver
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(
        uint256 _burn_amount,
        int128 i,
        bool _previous
    ) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received,
        address _receiver
    ) external returns (uint256);

    function ramp_A(uint256 _future_A, uint256 _future_time) external;

    function stop_ramp_A() external;

    function admin_balances(uint256 i) external view returns (uint256);

    function withdraw_admin_fees() external;

    function admin() external view returns (address);

    function coins(uint256 arg0) external view returns (address);

    function balances(uint256 arg0) external view returns (uint256);

    function fee() external view returns (uint256);

    function block_timestamp_last() external view returns (uint256);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address arg0) external view returns (uint256);

    function allowance(address arg0, address arg1)
        external
        view
        returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
contract Oracle {
    address public pool;
    address public token0;
    address public token1;
    uint256 public price0Average;
    uint256 public price1Average;
    uint256[2] public twapBalances;
    uint256 public pricesBlockTimestampLast;
    uint256[2] public priceCumulativeLast;

    address internal dao;

    constructor(
        address _dao,
        address _pool,
        address _Ttoken0,
        address _curve3CRVtoken1,
        address _previousOracle
    ) public {
        dao = _dao;
        pool = _pool;
        // coin at index 0 is T and index 1 is 3CRV
        require(
            IMetaPool(_pool).coins(0) == _Ttoken0 &&
                IMetaPool(_pool).coins(1) == _curve3CRVtoken1,
            "TWAPOracle: COIN_ORDER_MISMATCH"
        );

        token0 = _Ttoken0;
        token1 = _curve3CRVtoken1;

        Oracle prevOracle = Oracle(_previousOracle);
        price0Average = prevOracle.price0Average();
        price1Average = prevOracle.price1Average();
        twapBalances[0] = IMetaPool(pool).balances(0);
        twapBalances[1] = IMetaPool(pool).balances(1);
        pricesBlockTimestampLast = prevOracle.pricesBlockTimestampLast();
        priceCumulativeLast[0] = prevOracle.priceCumulativeLast(0);
        priceCumulativeLast[1] = prevOracle.priceCumulativeLast(1);
    }

    // calculate average price
    function update() external onlyDao {
      (
          uint256[2] memory priceCumulative,
          uint256 blockTimestamp
      ) = _currentCumulativePrices();

      if (blockTimestamp - pricesBlockTimestampLast > 0) {
          // get the balances between now and the last price cumulative snapshot
          twapBalances = IMetaPool(pool).get_twap_balances(
              priceCumulativeLast,
              priceCumulative,
              blockTimestamp - pricesBlockTimestampLast
          );

          // price to exchange amounIn T to 3CRV based on TWAP
          price0Average = IMetaPool(pool).get_dy(0, 1, 1 ether, twapBalances);
          // price to exchange amounIn 3CRV to T  based on TWAP
          price1Average = IMetaPool(pool).get_dy(1, 0, 1 ether, twapBalances);
          // we update the priceCumulative
          priceCumulativeLast = priceCumulative;
          pricesBlockTimestampLast = blockTimestamp;
      }
    }

    function averageDollarPrice()
        public
        view
        returns (Decimal.D256 memory, bool)
    {
        bool valid = true;
        if (twapBalances[0] < Constants.getOracleReserveMinimum()) {
            valid = false;
        }
        return (Decimal.D256({value: price0Average}), valid);
    }

    // note this will always return 0 before update has been called successfully
    // for the first time.
    function consult(address token) external view returns (uint256 amountOut) {
        if (token == token0) {
            // price to exchange 1 T to 3CRV based on TWAP
            amountOut = price0Average;
        } else {
            require(token == token1, "TWAPOracle: INVALID_TOKEN");
            // price to exchange 1 3CRV to T  based on TWAP
            amountOut = price1Average;
        }
    }

    function _currentCumulativePrices()
        internal
        view
        returns (uint256[2] memory priceCumulative, uint256 blockTimestamp)
    {
        priceCumulative = IMetaPool(pool).get_price_cumulative_last();
        blockTimestamp = IMetaPool(pool).block_timestamp_last();
    }

    modifier onlyDao() {
        require(msg.sender == dao, "Not dao");
        _;
    }
}