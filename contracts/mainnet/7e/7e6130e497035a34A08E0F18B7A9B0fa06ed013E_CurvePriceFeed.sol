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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IFundDeployer Interface
/// @author Enzyme Council <[email protected]>
interface IFundDeployer {
    function getOwner() external view returns (address);

    function hasReconfigurationRequest(address) external view returns (bool);

    function isAllowedBuySharesOnBehalfCaller(address) external view returns (bool);

    function isAllowedVaultCall(
        address,
        bytes4,
        bytes32
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IDerivativePriceFeed Interface
/// @author Enzyme Council <[email protected]>
/// @notice Simple interface for derivative price source oracle implementations
interface IDerivativePriceFeed {
    function calcUnderlyingValues(address, uint256)
        external
        returns (address[] memory, uint256[] memory);

    function isSupportedAsset(address) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../../interfaces/ICurveAddressProvider.sol";
import "../../../../interfaces/ICurveLiquidityPool.sol";
import "../../../../interfaces/ICurvePoolOwner.sol";
import "../../../../interfaces/ICurveRegistryMain.sol";
import "../../../../interfaces/ICurveRegistryMetapoolFactory.sol";
import "../../../../utils/FundDeployerOwnerMixin.sol";
import "../IDerivativePriceFeed.sol";

/// @title CurvePriceFeed Contract
/// @author Enzyme Council <[email protected]>
/// @notice Price feed for Curve pool tokens
contract CurvePriceFeed is IDerivativePriceFeed, FundDeployerOwnerMixin {
    using SafeMath for uint256;

    event CurvePoolOwnerSet(address poolOwner);

    event DerivativeAdded(address indexed derivative, address indexed pool);

    event DerivativeRemoved(address indexed derivative);

    event InvariantProxyAssetForPoolSet(address indexed pool, address indexed invariantProxyAsset);

    event PoolRemoved(address indexed pool);

    event ValidatedVirtualPriceForPoolUpdated(address indexed pool, uint256 virtualPrice);

    uint256 private constant ADDRESS_PROVIDER_METAPOOL_FACTORY_ID = 3;
    uint256 private constant VIRTUAL_PRICE_DEVIATION_DIVISOR = 10000;
    uint256 private constant VIRTUAL_PRICE_UNIT = 10**18;

    ICurveAddressProvider private immutable ADDRESS_PROVIDER_CONTRACT;
    uint256 private immutable VIRTUAL_PRICE_DEVIATION_THRESHOLD;

    // We take one asset as representative of the pool's invariant, e.g., WETH for ETH-based pools.
    // Caching invariantProxyAssetDecimals in a packed storage slot
    // removes an additional external call and cold SLOAD operation during value lookups.
    struct PoolInfo {
        address invariantProxyAsset; // 20 bytes
        uint8 invariantProxyAssetDecimals; // 1 byte
        uint88 lastValidatedVirtualPrice; // 11 bytes (could safely be 8-10 bytes)
    }

    address private curvePoolOwner;

    // Pool tokens and liquidity gauge tokens are treated the same for pricing purposes
    mapping(address => address) private derivativeToPool;
    mapping(address => PoolInfo) private poolToPoolInfo;

    // Not necessary for this contract, but used by Curve liquidity adapters
    mapping(address => address) private poolToLpToken;

    constructor(
        address _fundDeployer,
        address _addressProvider,
        address _poolOwner,
        uint256 _virtualPriceDeviationThreshold
    ) public FundDeployerOwnerMixin(_fundDeployer) {
        ADDRESS_PROVIDER_CONTRACT = ICurveAddressProvider(_addressProvider);
        VIRTUAL_PRICE_DEVIATION_THRESHOLD = _virtualPriceDeviationThreshold;

        __setCurvePoolOwner(_poolOwner);
    }

    /// @notice Converts a given amount of a derivative to its underlying asset values
    /// @param _derivative The derivative to convert
    /// @param _derivativeAmount The amount of the derivative to convert
    /// @return underlyings_ The underlying assets for the _derivative
    /// @return underlyingAmounts_ The amount of each underlying asset for the equivalent derivative amount
    function calcUnderlyingValues(address _derivative, uint256 _derivativeAmount)
        external
        override
        returns (address[] memory underlyings_, uint256[] memory underlyingAmounts_)
    {
        address pool = getPoolForDerivative(_derivative);
        require(pool != address(0), "calcUnderlyingValues: _derivative is not supported");

        PoolInfo memory poolInfo = getPoolInfo(pool);

        uint256 virtualPrice = ICurveLiquidityPool(pool).get_virtual_price();

        // Validate and update the cached lastValidatedVirtualPrice if:
        /// 1. a pool requires virtual price validation, and
        /// 2. the unvalidated `virtualPrice` deviates from the PoolInfo.lastValidatedVirtualPrice value
        /// by more than the tolerated "deviation threshold" (e.g., 1%).
        /// This is an optimization to save gas on validating non-reentrancy during the virtual price query,
        /// since the virtual price increases relatively slowly as the pool accrues fees over time.
        if (
            poolInfo.lastValidatedVirtualPrice > 0 &&
            __virtualPriceDiffExceedsThreshold(
                virtualPrice,
                uint256(poolInfo.lastValidatedVirtualPrice)
            )
        ) {
            __updateValidatedVirtualPrice(pool, virtualPrice);
        }

        underlyings_ = new address[](1);
        underlyings_[0] = poolInfo.invariantProxyAsset;

        underlyingAmounts_ = new uint256[](1);
        if (poolInfo.invariantProxyAssetDecimals == 18) {
            underlyingAmounts_[0] = _derivativeAmount.mul(virtualPrice).div(VIRTUAL_PRICE_UNIT);
        } else {
            underlyingAmounts_[0] = _derivativeAmount
                .mul(virtualPrice)
                .mul(10**uint256(poolInfo.invariantProxyAssetDecimals))
                .div(VIRTUAL_PRICE_UNIT)
                .div(VIRTUAL_PRICE_UNIT);
        }

        return (underlyings_, underlyingAmounts_);
    }

    /// @notice Checks if an asset is supported by the price feed
    /// @param _asset The asset to check
    /// @return isSupported_ True if the asset is supported
    function isSupportedAsset(address _asset) external view override returns (bool isSupported_) {
        return getPoolForDerivative(_asset) != address(0);
    }

    //////////////////////////
    // DERIVATIVES REGISTRY //
    //////////////////////////

    // addPools() is the primary action to add validated lpTokens and gaugeTokens as derivatives.
    // addGaugeTokens() can be used to add validated gauge tokens for an already-registered pool.
    // addPoolsWithoutValidation() and addGaugeTokensWithoutValidation() can be used as overrides.
    // It is possible to remove all pool data and derivatives (separately).
    // It is possible to update the invariant proxy asset for any pool.
    // It is possible to update whether the pool's virtual price is reenterable.

    /// @notice Adds validated gaugeTokens to the price feed
    /// @param _gaugeTokens The ordered gauge tokens
    /// @param _pools The ordered pools corresponding to _gaugeTokens
    /// @dev All params are corresponding, equal length arrays.
    /// _pools must already have been added via an addPools~() function
    function addGaugeTokens(address[] calldata _gaugeTokens, address[] calldata _pools)
        external
        onlyFundDeployerOwner
    {
        ICurveRegistryMain registryContract = __getRegistryMainContract();
        ICurveRegistryMetapoolFactory factoryContract = __getRegistryMetapoolFactoryContract();

        for (uint256 i; i < _gaugeTokens.length; i++) {
            if (factoryContract.get_gauge(_pools[i]) != _gaugeTokens[i]) {
                __validateGaugeMainRegistry(_gaugeTokens[i], _pools[i], registryContract);
            }
        }

        __addGaugeTokens(_gaugeTokens, _pools);
    }

    /// @notice Adds unvalidated gaugeTokens to the price feed
    /// @param _gaugeTokens The ordered gauge tokens
    /// @param _pools The ordered pools corresponding to _gaugeTokens
    /// @dev Should only be used if something is incorrectly failing in the registry validation,
    /// or if gauge tokens exist outside of the registries supported by this price feed,
    /// e.g., a wrapper for non-tokenized gauges.
    /// All params are corresponding, equal length arrays.
    /// _pools must already have been added via an addPools~() function.
    function addGaugeTokensWithoutValidation(
        address[] calldata _gaugeTokens,
        address[] calldata _pools
    ) external onlyFundDeployerOwner {
        __addGaugeTokens(_gaugeTokens, _pools);
    }

    /// @notice Adds validated Curve pool info, lpTokens, and gaugeTokens to the price feed
    /// @param _pools The ordered Curve pools
    /// @param _invariantProxyAssets The ordered invariant proxy assets corresponding to _pools,
    /// e.g., WETH for ETH-based pools
    /// @param _reentrantVirtualPrices The ordered flags corresponding to _pools,
    /// true if the get_virtual_price() function is potentially reenterable
    /// @param _lpTokens The ordered lpToken corresponding to _pools
    /// @param _gaugeTokens The ordered gauge token corresponding to _pools
    /// @dev All params are corresponding, equal length arrays.
    /// address(0) can be used for any _gaugeTokens index to omit the gauge (e.g., no gauge token exists).
    /// _lpTokens is not technically necessary since it is knowable from a Curve registry,
    /// but it's better to use Curve's upgradable contracts as an input validation rather than fully-trusted.
    function addPools(
        address[] calldata _pools,
        address[] calldata _invariantProxyAssets,
        bool[] calldata _reentrantVirtualPrices,
        address[] calldata _lpTokens,
        address[] calldata _gaugeTokens
    ) external onlyFundDeployerOwner {
        ICurveRegistryMain registryContract = __getRegistryMainContract();
        ICurveRegistryMetapoolFactory factoryContract = __getRegistryMetapoolFactoryContract();

        for (uint256 i; i < _pools.length; i++) {
            // Validate the lpToken and gauge token based on registry
            if (_lpTokens[i] == registryContract.get_lp_token(_pools[i])) {
                // Main registry

                if (_gaugeTokens[i] != address(0)) {
                    __validateGaugeMainRegistry(_gaugeTokens[i], _pools[i], registryContract);
                }
            } else if (_lpTokens[i] == _pools[i] && factoryContract.get_n_coins(_pools[i]) > 0) {
                // Metapool factory registry
                // lpToken and pool are the same address
                // get_n_coins() is arbitrarily used to validate the pool is on this registry

                if (_gaugeTokens[i] != address(0)) {
                    __validateGaugeMetapoolFactoryRegistry(
                        _gaugeTokens[i],
                        _pools[i],
                        factoryContract
                    );
                }
            } else {
                revert("addPools: Invalid inputs");
            }
        }

        __addPools(
            _pools,
            _invariantProxyAssets,
            _reentrantVirtualPrices,
            _lpTokens,
            _gaugeTokens
        );
    }

    /// @notice Adds unvalidated Curve pool info, lpTokens, and gaugeTokens to the price feed
    /// @param _pools The ordered Curve pools
    /// @param _invariantProxyAssets The ordered invariant proxy assets corresponding to _pools,
    /// e.g., WETH for ETH-based pools
    /// @param _reentrantVirtualPrices The ordered flags corresponding to _pools,
    /// true if the get_virtual_price() function is potentially reenterable
    /// @param _lpTokens The ordered lpToken corresponding to _pools
    /// @param _gaugeTokens The ordered gauge token corresponding to _pools
    /// @dev Should only be used if something is incorrectly failing in the registry validation,
    /// or if pools exist outside of the registries supported by this price feed.
    /// All params are corresponding, equal length arrays.
    /// address(0) can be used for any _gaugeTokens index to omit the gauge (e.g., no gauge token exists).
    function addPoolsWithoutValidation(
        address[] calldata _pools,
        address[] calldata _invariantProxyAssets,
        bool[] calldata _reentrantVirtualPrices,
        address[] calldata _lpTokens,
        address[] calldata _gaugeTokens
    ) external onlyFundDeployerOwner {
        __addPools(
            _pools,
            _invariantProxyAssets,
            _reentrantVirtualPrices,
            _lpTokens,
            _gaugeTokens
        );
    }

    /// @notice Removes derivatives from the price feed
    /// @param _derivatives The derivatives to remove
    /// @dev Unlikely to be needed, just in case of bad storage entry.
    /// Can remove both lpToken and gaugeToken from derivatives list,
    /// but does not remove lpToken from pool info cache.
    function removeDerivatives(address[] calldata _derivatives) external onlyFundDeployerOwner {
        for (uint256 i; i < _derivatives.length; i++) {
            delete derivativeToPool[_derivatives[i]];

            emit DerivativeRemoved(_derivatives[i]);
        }
    }

    /// @notice Removes pools from the price feed
    /// @param _pools The pools to remove
    /// @dev Unlikely to be needed, just in case of bad storage entry.
    /// Does not remove lpToken nor gauge tokens from derivatives list.
    function removePools(address[] calldata _pools) external onlyFundDeployerOwner {
        for (uint256 i; i < _pools.length; i++) {
            delete poolToPoolInfo[_pools[i]];
            delete poolToLpToken[_pools[i]];

            emit PoolRemoved(_pools[i]);
        }
    }

    /// @notice Sets the Curve pool owner
    /// @param _nextPoolOwner The next pool owner value
    function setCurvePoolOwner(address _nextPoolOwner) external onlyFundDeployerOwner {
        __setCurvePoolOwner(_nextPoolOwner);
    }

    /// @notice Updates the PoolInfo for the given pools
    /// @param _pools The ordered pools
    /// @param _invariantProxyAssets The ordered invariant asset proxy assets
    /// @param _reentrantVirtualPrices The ordered flags corresponding to _pools,
    /// true if the get_virtual_price() function is potentially reenterable
    function updatePoolInfo(
        address[] calldata _pools,
        address[] calldata _invariantProxyAssets,
        bool[] calldata _reentrantVirtualPrices
    ) external onlyFundDeployerOwner {
        require(
            _pools.length == _invariantProxyAssets.length &&
                _pools.length == _reentrantVirtualPrices.length,
            "updatePoolInfo: Unequal arrays"
        );

        for (uint256 i; i < _pools.length; i++) {
            __setPoolInfo(_pools[i], _invariantProxyAssets[i], _reentrantVirtualPrices[i]);
        }
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to add a derivative to the price feed
    function __addDerivative(address _derivative, address _pool) private {
        require(
            getPoolForDerivative(_derivative) == address(0),
            "__addDerivative: Already exists"
        );

        // Assert that the assumption that all Curve pool tokens are 18 decimals
        require(ERC20(_derivative).decimals() == 18, "__addDerivative: Not 18-decimal");

        derivativeToPool[_derivative] = _pool;

        emit DerivativeAdded(_derivative, _pool);
    }

    /// @dev Helper for common logic in addGauges~() functions
    function __addGaugeTokens(address[] calldata _gaugeTokens, address[] calldata _pools) private {
        require(_gaugeTokens.length == _pools.length, "__addGaugeTokens: Unequal arrays");

        for (uint256 i; i < _gaugeTokens.length; i++) {
            require(
                getLpTokenForPool(_pools[i]) != address(0),
                "__addGaugeTokens: Pool not registered"
            );
            // Not-yet-registered _gaugeTokens[i] tested in __addDerivative()

            __addDerivative(_gaugeTokens[i], _pools[i]);
        }
    }

    /// @dev Helper for common logic in addPools~() functions
    function __addPools(
        address[] calldata _pools,
        address[] calldata _invariantProxyAssets,
        bool[] calldata _reentrantVirtualPrices,
        address[] calldata _lpTokens,
        address[] calldata _gaugeTokens
    ) private {
        require(
            _pools.length == _invariantProxyAssets.length &&
                _pools.length == _reentrantVirtualPrices.length &&
                _pools.length == _lpTokens.length &&
                _pools.length == _gaugeTokens.length,
            "__addPools: Unequal arrays"
        );

        for (uint256 i; i < _pools.length; i++) {
            // Redundant for validated addPools()
            require(_lpTokens[i] != address(0), "__addPools: Empty lpToken");
            // Empty _pools[i] reverts during __validatePoolCompatibility
            // Empty _invariantProxyAssets[i] reverts during __setPoolInfo

            // Validate new pool's compatibility with price feed
            require(getLpTokenForPool(_pools[i]) == address(0), "__addPools: Already registered");
            __validatePoolCompatibility(_pools[i]);

            // Register pool info
            __setPoolInfo(_pools[i], _invariantProxyAssets[i], _reentrantVirtualPrices[i]);
            poolToLpToken[_pools[i]] = _lpTokens[i];

            // Add lpToken and gauge token as derivatives
            __addDerivative(_lpTokens[i], _pools[i]);
            if (_gaugeTokens[i] != address(0)) {
                __addDerivative(_gaugeTokens[i], _pools[i]);
            }
        }
    }

    /// @dev Helper to get the main Curve registry contract
    function __getRegistryMainContract() private view returns (ICurveRegistryMain contract_) {
        return ICurveRegistryMain(ADDRESS_PROVIDER_CONTRACT.get_registry());
    }

    /// @dev Helper to get the Curve metapool factory registry contract
    function __getRegistryMetapoolFactoryContract()
        private
        view
        returns (ICurveRegistryMetapoolFactory contract_)
    {
        return
            ICurveRegistryMetapoolFactory(
                ADDRESS_PROVIDER_CONTRACT.get_address(ADDRESS_PROVIDER_METAPOOL_FACTORY_ID)
            );
    }

    /// @dev Helper to call a known non-reenterable pool function
    function __makeNonReentrantPoolCall(address _pool) private {
        ICurvePoolOwner(getCurvePoolOwner()).withdraw_admin_fees(_pool);
    }

    /// @dev Helper to set the Curve pool owner
    function __setCurvePoolOwner(address _nextPoolOwner) private {
        curvePoolOwner = _nextPoolOwner;

        emit CurvePoolOwnerSet(_nextPoolOwner);
    }

    /// @dev Helper to set the PoolInfo for a given pool
    function __setPoolInfo(
        address _pool,
        address _invariantProxyAsset,
        bool _reentrantVirtualPrice
    ) private {
        uint256 lastValidatedVirtualPrice;
        if (_reentrantVirtualPrice) {
            // Validate the virtual price by calling a non-reentrant pool function
            __makeNonReentrantPoolCall(_pool);

            lastValidatedVirtualPrice = ICurveLiquidityPool(_pool).get_virtual_price();

            emit ValidatedVirtualPriceForPoolUpdated(_pool, lastValidatedVirtualPrice);
        }

        poolToPoolInfo[_pool] = PoolInfo({
            invariantProxyAsset: _invariantProxyAsset,
            invariantProxyAssetDecimals: ERC20(_invariantProxyAsset).decimals(),
            lastValidatedVirtualPrice: uint88(lastValidatedVirtualPrice)
        });

        emit InvariantProxyAssetForPoolSet(_pool, _invariantProxyAsset);
    }

    /// @dev Helper to update the last validated virtual price for a given pool
    function __updateValidatedVirtualPrice(address _pool, uint256 _virtualPrice) private {
        // Validate the virtual price by calling a non-reentrant pool function
        __makeNonReentrantPoolCall(_pool);

        // _virtualPrice is now considered valid
        poolToPoolInfo[_pool].lastValidatedVirtualPrice = uint88(_virtualPrice);

        emit ValidatedVirtualPriceForPoolUpdated(_pool, _virtualPrice);
    }

    /// @dev Helper to validate a gauge on the main Curve registry
    function __validateGaugeMainRegistry(
        address _gauge,
        address _pool,
        ICurveRegistryMain _mainRegistryContract
    ) private view {
        (address[10] memory gauges, ) = _mainRegistryContract.get_gauges(_pool);
        for (uint256 i; i < gauges.length; i++) {
            if (_gauge == gauges[i]) {
                return;
            }
        }

        revert("__validateGaugeMainRegistry: Invalid gauge");
    }

    /// @dev Helper to validate a gauge on the Curve metapool factory registry
    function __validateGaugeMetapoolFactoryRegistry(
        address _gauge,
        address _pool,
        ICurveRegistryMetapoolFactory _metapoolFactoryRegistryContract
    ) private view {
        require(
            _gauge == _metapoolFactoryRegistryContract.get_gauge(_pool),
            "__validateGaugeMetapoolFactoryRegistry: Invalid gauge"
        );
    }

    /// @dev Helper to validate a pool's compatibility with the price feed.
    /// Pool must implement expected get_virtual_price() function.
    function __validatePoolCompatibility(address _pool) private view {
        require(
            ICurveLiquidityPool(_pool).get_virtual_price() > 0,
            "__validatePoolCompatibility: Incompatible"
        );
    }

    /// @dev Helper to check if the difference between lastValidatedVirtualPrice and the current virtual price
    /// exceeds the allowed threshold before the current virtual price must be validated and stored
    function __virtualPriceDiffExceedsThreshold(
        uint256 _currentVirtualPrice,
        uint256 _lastValidatedVirtualPrice
    ) private view returns (bool exceedsThreshold_) {
        // Uses the absolute delta between current and last validated virtual prices for the rare
        // case where a virtual price might have decreased (e.g., rounding, slashing, yet unknown
        // manipulation vector, etc)
        uint256 absDiff;
        if (_currentVirtualPrice > _lastValidatedVirtualPrice) {
            absDiff = _currentVirtualPrice.sub(_lastValidatedVirtualPrice);
        } else {
            absDiff = _lastValidatedVirtualPrice.sub(_currentVirtualPrice);
        }

        return
            absDiff >
            _lastValidatedVirtualPrice.mul(VIRTUAL_PRICE_DEVIATION_THRESHOLD).div(
                VIRTUAL_PRICE_DEVIATION_DIVISOR
            );
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the Curve pool owner
    /// @return poolOwner_ The Curve pool owner
    function getCurvePoolOwner() public view returns (address poolOwner_) {
        return curvePoolOwner;
    }

    /// @notice Gets the lpToken for a given pool
    /// @param _pool The pool
    /// @return lpToken_ The lpToken
    function getLpTokenForPool(address _pool) public view returns (address lpToken_) {
        return poolToLpToken[_pool];
    }

    /// @notice Gets the stored PoolInfo for a given pool
    /// @param _pool The pool
    /// @return poolInfo_ The PoolInfo
    function getPoolInfo(address _pool) public view returns (PoolInfo memory poolInfo_) {
        return poolToPoolInfo[_pool];
    }

    /// @notice Gets the pool for a given derivative
    /// @param _derivative The derivative
    /// @return pool_ The pool
    function getPoolForDerivative(address _derivative) public view returns (address pool_) {
        return derivativeToPool[_derivative];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveAddressProvider interface
/// @author Enzyme Council <[email protected]>
interface ICurveAddressProvider {
    function get_address(uint256) external view returns (address);

    function get_registry() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveLiquidityPool interface
/// @author Enzyme Council <[email protected]>
interface ICurveLiquidityPool {
    function coins(int128) external view returns (address);

    function coins(uint256) external view returns (address);

    function get_virtual_price() external view returns (uint256);

    function underlying_coins(int128) external view returns (address);

    function underlying_coins(uint256) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurvePoolOwner interface
/// @author Enzyme Council <[email protected]>
interface ICurvePoolOwner {
    function withdraw_admin_fees(address) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveRegistryMain interface
/// @author Enzyme Council <[email protected]>
/// @notice Limited interface for the Curve Registry contract at ICurveAddressProvider.get_address(0)
interface ICurveRegistryMain {
    function get_gauges(address) external view returns (address[10] memory, int128[10] memory);

    function get_lp_token(address) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title ICurveRegistryMetapoolFactory interface
/// @author Enzyme Council <[email protected]>
/// @notice Limited interface for the Curve Registry contract at ICurveAddressProvider.get_address(3)
interface ICurveRegistryMetapoolFactory {
    function get_gauge(address) external view returns (address);

    function get_n_coins(address) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../core/fund-deployer/IFundDeployer.sol";

/// @title FundDeployerOwnerMixin Contract
/// @author Enzyme Council <[email protected]>
/// @notice A mixin contract that defers ownership to the owner of FundDeployer
abstract contract FundDeployerOwnerMixin {
    address internal immutable FUND_DEPLOYER;

    modifier onlyFundDeployerOwner() {
        require(
            msg.sender == getOwner(),
            "onlyFundDeployerOwner: Only the FundDeployer owner can call this function"
        );
        _;
    }

    constructor(address _fundDeployer) public {
        FUND_DEPLOYER = _fundDeployer;
    }

    /// @notice Gets the owner of this contract
    /// @return owner_ The owner
    /// @dev Ownership is deferred to the owner of the FundDeployer contract
    function getOwner() public view returns (address owner_) {
        return IFundDeployer(FUND_DEPLOYER).getOwner();
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `FUND_DEPLOYER` variable
    /// @return fundDeployer_ The `FUND_DEPLOYER` variable value
    function getFundDeployer() public view returns (address fundDeployer_) {
        return FUND_DEPLOYER;
    }
}