// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../interfaces/IStableSwap.sol";
import "../interfaces/ITrancheIndexV2.sol";

/// @dev See IVault.sol under https://github.com/balancer-labs/balancer-v2-monorepo/
interface IBalancerVault {
    enum SwapKind {GIVEN_IN, GIVEN_OUT}

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address recipient;
        bool toInternalBalance;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    function WETH() external view returns (address);

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);
}

contract BalancerV2Router is IStableSwapCoreInternalRevertExpected, ITrancheIndexV2 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public constant UP_ROUNDING_FACTOR = 1e10;

    IFundV3 public immutable fund;
    address private immutable _tokenUnderlying;
    address private immutable _tokenQ;
    IBalancerVault public immutable vault;
    bytes32 public immutable poolId;

    constructor(
        address fund_,
        address vault_,
        bytes32 poolId_
    ) public {
        fund = IFundV3(fund_);
        _tokenUnderlying = IFundV3(fund_).tokenUnderlying();
        _tokenQ = IFundV3(fund_).tokenQ();
        vault = IBalancerVault(vault_);
        poolId = poolId_;
    }

    /// @dev Get redemption with StableSwap getQuoteOut interface.
    function getQuoteOut(uint256 baseIn) external override returns (uint256 quoteOut) {
        quoteOut = querySwap(
            IBalancerVault.SingleSwap({
                poolId: poolId,
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: _tokenQ,
                assetOut: _tokenUnderlying,
                amount: baseIn,
                userData: ""
            })
        );
    }

    /// @dev Get creation for QUEEN with StableSwap getQuoteIn interface.
    function getQuoteIn(uint256 baseOut) external override returns (uint256 quoteIn) {
        quoteIn = querySwap(
            IBalancerVault.SingleSwap({
                poolId: poolId,
                kind: IBalancerVault.SwapKind.GIVEN_OUT,
                assetIn: _tokenUnderlying,
                assetOut: _tokenQ,
                amount: baseOut,
                userData: ""
            })
        );
        // Round up by (1 + factor)x + 1 in case of rounding errors
        quoteIn = quoteIn.add(quoteIn / UP_ROUNDING_FACTOR).add(1);
    }

    /// @dev Get creation with StableSwap getBaseOut interface.
    function getBaseOut(uint256 quoteIn) external override returns (uint256 baseOut) {
        baseOut = querySwap(
            IBalancerVault.SingleSwap({
                poolId: poolId,
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: _tokenUnderlying,
                assetOut: _tokenQ,
                amount: quoteIn,
                userData: ""
            })
        );
    }

    /// @dev Get redemption for underlying with StableSwap getBaseIn interface.
    function getBaseIn(uint256 quoteOut) external override returns (uint256 baseIn) {
        baseIn = querySwap(
            IBalancerVault.SingleSwap({
                poolId: poolId,
                kind: IBalancerVault.SwapKind.GIVEN_OUT,
                assetIn: _tokenQ,
                assetOut: _tokenUnderlying,
                amount: quoteOut,
                userData: ""
            })
        );
        // Round up by (1 + factor)x + 1 in case of rounding errors
        baseIn = baseIn.add(baseIn / UP_ROUNDING_FACTOR).add(1);
    }

    /// @dev Create QUEEN with StableSwap buy interface.
    ///      Underlying should have already been sent to this contract
    function buy(
        uint256,
        uint256 baseOut,
        address recipient,
        bytes calldata
    ) external override returns (uint256 realBaseOut) {
        uint256 routerQuoteBalance = IERC20(_tokenUnderlying).balanceOf(address(this));
        IERC20(_tokenUnderlying).safeApprove(address(vault), routerQuoteBalance);

        IBalancerVault.SingleSwap memory singleSwap =
            IBalancerVault.SingleSwap({
                poolId: poolId,
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: _tokenUnderlying,
                assetOut: _tokenQ,
                amount: routerQuoteBalance,
                userData: ""
            });
        IBalancerVault.FundManagement memory funds =
            IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: recipient,
                toInternalBalance: false
            });

        realBaseOut = vault.swap(singleSwap, funds, baseOut, block.timestamp);
    }

    /// @dev Redeem QUEEN with StableSwap sell interface.
    ///      QUEEN should have already been sent to this contract
    function sell(
        uint256,
        uint256 quoteOut,
        address recipient,
        bytes calldata
    ) external override returns (uint256 realQuoteOut) {
        uint256 routerBaseBalance = fund.trancheBalanceOf(TRANCHE_Q, address(this));
        fund.trancheApprove(TRANCHE_Q, address(vault), routerBaseBalance, fund.getRebalanceSize());

        IBalancerVault.SingleSwap memory singleSwap =
            IBalancerVault.SingleSwap({
                poolId: poolId,
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: _tokenQ,
                assetOut: _tokenUnderlying,
                amount: routerBaseBalance,
                userData: ""
            });
        IBalancerVault.FundManagement memory funds =
            IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: recipient,
                toInternalBalance: false
            });

        realQuoteOut = vault.swap(singleSwap, funds, quoteOut, block.timestamp);
    }

    /// @dev See BalancerQueries.sol under https://github.com/balancer-labs/balancer-v2-monorepo/
    function querySwap(IBalancerVault.SingleSwap memory singleSwap) public returns (uint256) {
        // The Vault only supports batch swap queries, so we need to convert the swap call into an equivalent batch
        // swap. The result will be identical.

        // The main difference between swaps and batch swaps is that batch swaps require an assets array. We're going
        // to place the asset in at index 0, and asset out at index 1.
        address[] memory assets = new address[](2);
        assets[0] = singleSwap.assetIn;
        assets[1] = singleSwap.assetOut;

        IBalancerVault.BatchSwapStep[] memory swaps = new IBalancerVault.BatchSwapStep[](1);
        swaps[0] = IBalancerVault.BatchSwapStep({
            poolId: singleSwap.poolId,
            assetInIndex: 0,
            assetOutIndex: 1,
            amount: singleSwap.amount,
            userData: singleSwap.userData
        });

        IBalancerVault.FundManagement memory funds =
            IBalancerVault.FundManagement({
                sender: address(0),
                fromInternalBalance: false,
                recipient: address(0),
                toInternalBalance: false
            });

        int256[] memory assetDeltas = queryBatchSwap(singleSwap.kind, swaps, assets, funds);

        // Batch swaps return the full Vault asset deltas, which in the special case of a single step swap contains more
        // information than we need (as the amount in is known in a GIVEN_IN swap, and the amount out is known in a
        // GIVEN_OUT swap). We extract the information we're interested in.
        if (singleSwap.kind == IBalancerVault.SwapKind.GIVEN_IN) {
            // The asset out will have a negative Vault delta (the assets are coming out of the Pool and the user is
            // receiving them), so make it positive to match the `swap` interface.

            require(assetDeltas[1] <= 0, "SHOULD_NOT_HAPPEN");
            return uint256(-assetDeltas[1]);
        } else {
            // The asset in will have a positive Vault delta (the assets are going into the Pool and the user is
            // sending them), so we don't need to do anything.
            return uint256(assetDeltas[0]);
        }
    }

    function queryBatchSwap(
        IBalancerVault.SwapKind kind,
        IBalancerVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        IBalancerVault.FundManagement memory funds
    ) public returns (int256[] memory assetDeltas) {
        (, bytes memory returnData) =
            address(vault).call(
                abi.encodeWithSelector(
                    IBalancerVault.queryBatchSwap.selector,
                    kind,
                    swaps,
                    assets,
                    funds
                )
            );
        assetDeltas = abi.decode(returnData, (int256[]));
        require(assetDeltas.length == swaps.length.add(1), "Unexpected length");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "../interfaces/IFundV3.sol";

interface IStableSwapCore {
    function getQuoteOut(uint256 baseIn) external view returns (uint256 quoteOut);

    function getQuoteIn(uint256 baseOut) external view returns (uint256 quoteIn);

    function getBaseOut(uint256 quoteIn) external view returns (uint256 baseOut);

    function getBaseIn(uint256 quoteOut) external view returns (uint256 baseIn);

    function buy(
        uint256 version,
        uint256 baseOut,
        address recipient,
        bytes calldata data
    ) external returns (uint256 realBaseOut);

    function sell(
        uint256 version,
        uint256 quoteOut,
        address recipient,
        bytes calldata data
    ) external returns (uint256 realQuoteOut);
}

interface IStableSwap is IStableSwapCore {
    function fund() external view returns (IFundV3);

    function baseTranche() external view returns (uint256);

    function baseAddress() external view returns (address);

    function quoteAddress() external view returns (address);

    function allBalances() external view returns (uint256, uint256);

    function getOraclePrice() external view returns (uint256);

    function getCurrentD() external view returns (uint256);

    function getCurrentPriceOverOracle() external view returns (uint256);

    function getCurrentPrice() external view returns (uint256);

    function getPriceOverOracleIntegral() external view returns (uint256);

    function addLiquidity(uint256 version, address recipient) external returns (uint256);

    function removeLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    ) external returns (uint256 baseOut, uint256 quoteOut);

    function removeLiquidityUnwrap(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    ) external returns (uint256 baseOut, uint256 quoteOut);

    function removeBaseLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut
    ) external returns (uint256 baseOut);

    function removeQuoteLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    ) external returns (uint256 quoteOut);

    function removeQuoteLiquidityUnwrap(
        uint256 version,
        uint256 lpIn,
        uint256 minQuoteOut
    ) external returns (uint256 quoteOut);
}

/// @dev The interface shares the same function names as in `IStableSwapCore`;
///      all getters are defined as non-view functions in order to parse and
///      return the internal revert messages
interface IStableSwapCoreInternalRevertExpected {
    function getQuoteOut(uint256 baseIn) external returns (uint256 quoteOut);

    function getQuoteIn(uint256 baseOut) external returns (uint256 quoteIn);

    function getBaseOut(uint256 quoteIn) external returns (uint256 baseOut);

    function getBaseIn(uint256 quoteOut) external returns (uint256 baseIn);

    function buy(
        uint256 version,
        uint256 baseOut,
        address recipient,
        bytes calldata data
    ) external returns (uint256 realBaseOut);

    function sell(
        uint256 version,
        uint256 quoteOut,
        address recipient,
        bytes calldata data
    ) external returns (uint256 realQuoteOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

/// @notice Amounts of QUEEN, BISHOP and ROOK are sometimes stored in a `uint256[3]` array.
///         This contract defines index of each tranche in this array.
///
///         Solidity does not allow constants to be defined in interfaces. So this contract follows
///         the naming convention of interfaces but is implemented as an `abstract contract`.
abstract contract ITrancheIndexV2 {
    uint256 internal constant TRANCHE_Q = 0;
    uint256 internal constant TRANCHE_B = 1;
    uint256 internal constant TRANCHE_R = 2;

    uint256 internal constant TRANCHE_COUNT = 3;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "./ITwapOracleV2.sol";

interface IFundV3 {
    /// @notice A linear transformation matrix that represents a rebalance.
    ///
    ///         ```
    ///             [        1        0        0 ]
    ///         R = [ ratioB2Q  ratioBR        0 ]
    ///             [ ratioR2Q        0  ratioBR ]
    ///         ```
    ///
    ///         Amounts of the three tranches `q`, `b` and `r` can be rebalanced by multiplying the matrix:
    ///
    ///         ```
    ///         [ q', b', r' ] = [ q, b, r ] * R
    ///         ```
    struct Rebalance {
        uint256 ratioB2Q;
        uint256 ratioR2Q;
        uint256 ratioBR;
        uint256 timestamp;
    }

    function tokenUnderlying() external view returns (address);

    function tokenQ() external view returns (address);

    function tokenB() external view returns (address);

    function tokenR() external view returns (address);

    function tokenShare(uint256 tranche) external view returns (address);

    function primaryMarket() external view returns (address);

    function primaryMarketUpdateProposal() external view returns (address, uint256);

    function strategy() external view returns (address);

    function strategyUpdateProposal() external view returns (address, uint256);

    function underlyingDecimalMultiplier() external view returns (uint256);

    function twapOracle() external view returns (ITwapOracleV2);

    function feeCollector() external view returns (address);

    function endOfDay(uint256 timestamp) external pure returns (uint256);

    function trancheTotalSupply(uint256 tranche) external view returns (uint256);

    function trancheBalanceOf(uint256 tranche, address account) external view returns (uint256);

    function trancheAllBalanceOf(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function trancheBalanceVersion(address account) external view returns (uint256);

    function trancheAllowance(
        uint256 tranche,
        address owner,
        address spender
    ) external view returns (uint256);

    function trancheAllowanceVersion(address owner, address spender)
        external
        view
        returns (uint256);

    function trancheTransfer(
        uint256 tranche,
        address recipient,
        uint256 amount,
        uint256 version
    ) external;

    function trancheTransferFrom(
        uint256 tranche,
        address sender,
        address recipient,
        uint256 amount,
        uint256 version
    ) external;

    function trancheApprove(
        uint256 tranche,
        address spender,
        uint256 amount,
        uint256 version
    ) external;

    function getRebalanceSize() external view returns (uint256);

    function getRebalance(uint256 index) external view returns (Rebalance memory);

    function getRebalanceTimestamp(uint256 index) external view returns (uint256);

    function currentDay() external view returns (uint256);

    function splitRatio() external view returns (uint256);

    function historicalSplitRatio(uint256 version) external view returns (uint256);

    function fundActivityStartTime() external view returns (uint256);

    function isFundActive(uint256 timestamp) external view returns (bool);

    function getEquivalentTotalB() external view returns (uint256);

    function getEquivalentTotalQ() external view returns (uint256);

    function historicalEquivalentTotalB(uint256 timestamp) external view returns (uint256);

    function historicalNavs(uint256 timestamp) external view returns (uint256 navB, uint256 navR);

    function extrapolateNav(uint256 price)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function doRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 index
    )
        external
        view
        returns (
            uint256 newAmountQ,
            uint256 newAmountB,
            uint256 newAmountR
        );

    function batchRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 fromIndex,
        uint256 toIndex
    )
        external
        view
        returns (
            uint256 newAmountQ,
            uint256 newAmountB,
            uint256 newAmountR
        );

    function refreshBalance(address account, uint256 targetVersion) external;

    function refreshAllowance(
        address owner,
        address spender,
        uint256 targetVersion
    ) external;

    function shareTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function shareTransferFrom(
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external returns (uint256 newAllowance);

    function shareIncreaseAllowance(
        address sender,
        address spender,
        uint256 addedValue
    ) external returns (uint256 newAllowance);

    function shareDecreaseAllowance(
        address sender,
        address spender,
        uint256 subtractedValue
    ) external returns (uint256 newAllowance);

    function shareApprove(
        address owner,
        address spender,
        uint256 amount
    ) external;

    function historicalUnderlying(uint256 timestamp) external view returns (uint256);

    function getTotalUnderlying() external view returns (uint256);

    function getStrategyUnderlying() external view returns (uint256);

    function getTotalDebt() external view returns (uint256);

    event RebalanceTriggered(
        uint256 indexed index,
        uint256 indexed day,
        uint256 navSum,
        uint256 navB,
        uint256 navROrZero,
        uint256 ratioB2Q,
        uint256 ratioR2Q,
        uint256 ratioBR
    );
    event Settled(uint256 indexed day, uint256 navB, uint256 navR, uint256 interestRate);
    event InterestRateUpdated(uint256 baseInterestRate, uint256 floatingInterestRate);
    event BalancesRebalanced(
        address indexed account,
        uint256 version,
        uint256 balanceQ,
        uint256 balanceB,
        uint256 balanceR
    );
    event AllowancesRebalanced(
        address indexed owner,
        address indexed spender,
        uint256 version,
        uint256 allowanceQ,
        uint256 allowanceB,
        uint256 allowanceR
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "./ITwapOracle.sol";

interface ITwapOracleV2 is ITwapOracle {
    function getLatest() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface ITwapOracle {
    enum UpdateType {PRIMARY, SECONDARY, OWNER, CHAINLINK, UNISWAP_V2}

    function getTwap(uint256 timestamp) external view returns (uint256);
}