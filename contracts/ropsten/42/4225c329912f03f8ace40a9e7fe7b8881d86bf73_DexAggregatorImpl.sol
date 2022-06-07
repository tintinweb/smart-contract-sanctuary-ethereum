/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// File: contracts\DexAggregatorImpl.sol

//SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.8.4;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.8.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

/**
 * @dev Optional functions from the ERC20 standard.
 */
abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return payable(address(uint160(account)));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: contracts/UniversalERC20.sol

library UniversalERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant ZERO_ADDRESS =
        IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            payable(address(uint160(to))).transfer(amount);
            return true;
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(
                from == msg.sender && msg.value >= amount,
                "Wrong useage of ETH.universalTransferFrom()"
            );
            if (to != address(this)) {
                payable(address(uint160(to))).transfer(amount);
            }
            if (msg.value > amount) {
                payable(msg.sender).transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalTransferFromSenderToThis(IERC20 token, uint256 amount)
        internal
    {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            if (msg.value > amount) {
                // Return remainder if exist
                payable(msg.sender).transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function universalApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (!isETH(token)) {
            if (amount > 0 && token.allowance(address(this), to) > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who)
        internal
        view
        returns (uint256)
    {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function universalDecimals(IERC20 token) internal view returns (uint256) {
        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall{
            gas: 10000
        }(abi.encodeWithSignature("decimals()"));
        if (!success || data.length == 0) {
            (success, data) = address(token).staticcall{gas: 10000}(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) ||
            address(token) == address(ETH_ADDRESS));
    }
}

// File: contracts/interface/IWETH.sol

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// File: contracts/interface/ICurve.sol

interface ICurve {
    // solium-disable-next-line mixedcase
    function get_dx_underlying(
        int128 i,
        int128 j,
        uint256 dy
    ) external view returns (uint256 dx);

    // solium-disable-next-line mixedcase
    function get_dx(
        int128 i,
        int128 j,
        uint256 dy
    ) external view returns (uint256 dx);

    // solium-disable-next-line mixedcase
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 dy);

    // solium-disable-next-line mixedcase
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 dy);

    // solium-disable-next-line mixedcase
    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;

    // solium-disable-next-line mixedcase
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external;
}

// File: contracts/interface/IUniswapV2Exchange.sol

interface IUniswapV2Exchange {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: contracts/IDexAggregator.sol

interface IDexAggregator {
    function getExpectedInput(
        address fromToken,
        address destToken,
        address[] memory path,
        uint256 amountOut,
        address[] memory exchanges,
        uint256[] memory flags
    ) external view returns (uint256 bestAmount, uint256 bestIndex);

    function getExpectedReturn(
        address fromToken,
        address destToken,
        address[] memory path,
        uint256 amountIn,
        address[] memory exchanges,
        uint256[] memory flags
    ) external view returns (uint256 bestAmount, uint256 bestIndex);

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        address[] memory path,
        uint256 amountIn,
        uint256 minReturn,
        address recipient,
        address[] memory exchanges,
        uint256[] memory flags
    ) external payable;
}

contract DexAggregatorImpl is IDexAggregator, Ownable {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    /// Flags for indicating exchange types
    uint256 public constant FLAG_UNISWAP_V2 = 0x01;
    uint256 public constant FLAG_UNISWAP_V3 = 0x02;
    uint256 public constant FLAG_CURVE_COMPOUND = 0x03;
    uint256 public constant FLAG_CURVE_USDT = 0x04;
    uint256 public constant FLAG_CURVE_Y = 0x05;
    uint256 public constant FLAG_CURVE_BINANCE = 0x06;
    uint256 public constant FLAG_CURVE_SYNTHETIX = 0x07;
    uint256 public constant FLAG_CURVE_PAX = 0x08;
    uint256 public constant FLAG_CURVE_RENBTC = 0x09;
    uint256 public constant FLAG_CURVE_TBTC = 0x10;

    /// Addresses of known coins / tokens
    address public constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant tusd = 0x0000000000085d4780B73119b644AE5ecd22b376;
    address public constant busd = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address public constant susd = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address public constant pax = 0x8E870D67F660D95d5be530380D0eC0bd388289E1;
    // address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant weth = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address public constant renbtc = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
    address public constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant tbtc = 0x1bBE271d15Bb64dF0bc6CD28Df9Ff322F2eBD847;
    address public constant hbtc = 0x0316EB71485b0Ab14103307bf65a021042c6d380;

    constructor() {}

    receive() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    function _infiniteApproveIfNeeded(IERC20 token, address to) internal {
        if (!token.isETH()) {
            if ((token.allowance(address(this), to) >> 255) == 0) {
                token.universalApprove(to, uint256(int256(-1)));
            }
        }
    }

    function calculateInAmount(
        address exchange,
        uint256 flag,
        address fromToken,
        address destToken,
        address[] memory path,
        uint256 amountOut
    ) private view returns (uint256) {
        if (flag == FLAG_UNISWAP_V2) {
            return calcUniV2In(exchange, fromToken, destToken, path, amountOut);
        }
        if (flag >= FLAG_CURVE_COMPOUND && flag <= FLAG_CURVE_TBTC) {
            return calcCurvIn(exchange, flag, fromToken, destToken, amountOut);
        }
        // if (flag == FLAG_UNISWAP_V3) {

        // }
        return uint256(int256(-1));
    }

    function calculateOutAmount(
        address exchange,
        uint256 flag,
        address fromToken,
        address destToken,
        address[] memory path,
        uint256 amountIn
    ) private view returns (uint256) {
        if (flag == FLAG_UNISWAP_V2) {
            return calcUniV2Out(exchange, fromToken, destToken, path, amountIn);
        }
        if (flag >= FLAG_CURVE_COMPOUND && flag <= FLAG_CURVE_TBTC) {
            return calcCurvOut(exchange, flag, fromToken, destToken, amountIn);
        }
        // if (flag == FLAG_UNISWAP_V3) {

        // }
        return 0;
    }

    /// @dev Get params for calling curve finance pool function
    function getCurveParams(
        uint256 flag,
        address fromToken,
        address destToken
    ) private pure returns (int128, int128) {
        uint8 i = 0;
        uint8 j = 0;
        if (flag == FLAG_CURVE_COMPOUND) {
            i = (fromToken == dai ? 1 : 0) + (fromToken == usdc ? 2 : 0);
            j = (destToken == dai ? 1 : 0) + (destToken == usdc ? 2 : 0);
        } else if (flag == FLAG_CURVE_USDT) {
            i =
                (fromToken == dai ? 1 : 0) +
                (fromToken == usdc ? 2 : 0) +
                (fromToken == usdt ? 3 : 0);
            j =
                (destToken == dai ? 1 : 0) +
                (destToken == usdc ? 2 : 0) +
                (destToken == usdt ? 3 : 0);
        } else if (flag == FLAG_CURVE_Y) {
            i =
                (fromToken == dai ? 1 : 0) +
                (fromToken == usdc ? 2 : 0) +
                (fromToken == usdt ? 3 : 0) +
                (fromToken == tusd ? 4 : 0);
            j =
                (destToken == dai ? 1 : 0) +
                (destToken == usdc ? 2 : 0) +
                (destToken == usdt ? 3 : 0) +
                (destToken == tusd ? 4 : 0);
        } else if (flag == FLAG_CURVE_BINANCE) {
            i =
                (fromToken == dai ? 1 : 0) +
                (fromToken == usdc ? 2 : 0) +
                (fromToken == usdt ? 3 : 0) +
                (fromToken == busd ? 4 : 0);
            j =
                (destToken == dai ? 1 : 0) +
                (destToken == usdc ? 2 : 0) +
                (destToken == usdt ? 3 : 0) +
                (destToken == busd ? 4 : 0);
        } else if (flag == FLAG_CURVE_SYNTHETIX) {
            i =
                (fromToken == dai ? 1 : 0) +
                (fromToken == usdc ? 2 : 0) +
                (fromToken == usdt ? 3 : 0) +
                (fromToken == susd ? 4 : 0);
            j =
                (destToken == dai ? 1 : 0) +
                (destToken == usdc ? 2 : 0) +
                (destToken == usdt ? 3 : 0) +
                (destToken == susd ? 4 : 0);
        } else if (flag == FLAG_CURVE_PAX) {
            i =
                (fromToken == dai ? 1 : 0) +
                (fromToken == usdc ? 2 : 0) +
                (fromToken == usdt ? 3 : 0) +
                (fromToken == pax ? 4 : 0);
            j =
                (destToken == dai ? 1 : 0) +
                (destToken == usdc ? 2 : 0) +
                (destToken == usdt ? 3 : 0) +
                (destToken == pax ? 4 : 0);
        } else if (flag == FLAG_CURVE_RENBTC) {
            i = (fromToken == renbtc ? 1 : 0) + (fromToken == wbtc ? 2 : 0);
            j = (destToken == renbtc ? 1 : 0) + (destToken == wbtc ? 2 : 0);
        } else if (flag == FLAG_CURVE_TBTC) {
            i =
                (fromToken == tbtc ? 1 : 0) +
                (fromToken == wbtc ? 2 : 0) +
                (fromToken == hbtc ? 3 : 0);
            j =
                (destToken == tbtc ? 1 : 0) +
                (destToken == wbtc ? 2 : 0) +
                (destToken == hbtc ? 3 : 0);
        }
        return (int128(int16(uint16(i))), int128(int16(uint16(j))));
    }

    /// @dev Get valid uniswap v2 path
    function getUniV2ValidPath(
        address fromToken,
        address destToken,
        address[] memory path
    ) private pure returns (address[] memory) {
        address fromTokenReal = IERC20(fromToken).isETH() ? weth : fromToken;
        address destTokenReal = IERC20(destToken).isETH() ? weth : destToken;

        // Check if path is valid
        bool pathValid = path.length >= 2 &&
            path[0] == fromTokenReal &&
            path[path.length - 1] == destTokenReal;
        // Rebuild path when invalid
        if (!pathValid) {
            if (fromTokenReal == weth || destTokenReal == weth) {
                path = new address[](2);
                path[0] = fromTokenReal;
                path[1] = destTokenReal;
            } else {
                path = new address[](3);
                path[0] = fromTokenReal;
                path[1] = weth;
                path[2] = destTokenReal;
            }
        }
        return path;
    }

    // View Helpers
    function calcCurvIn(
        address exchange,
        uint256 flag,
        address fromToken,
        address destToken,
        uint256 amountOut
    ) private view returns (uint256) {
        (int128 i, int128 j) = getCurveParams(flag, fromToken, destToken);
        if (i == 0 || j == 0) {
            return 0;
        }

        if (flag <= FLAG_CURVE_PAX) {
            return ICurve(exchange).get_dx_underlying(i - 1, j - 1, amountOut);
        } else {
            return ICurve(exchange).get_dx(i - 1, j - 1, amountOut);
        }
    }

    // View Helpers
    function calcCurvOut(
        address exchange,
        uint256 flag,
        address fromToken,
        address destToken,
        uint256 amountIn
    ) private view returns (uint256) {
        (int128 i, int128 j) = getCurveParams(flag, fromToken, destToken);
        if (i == 0 || j == 0) {
            return 0;
        }

        if (flag <= FLAG_CURVE_PAX) {
            return ICurve(exchange).get_dy_underlying(i - 1, j - 1, amountIn);
        } else {
            return ICurve(exchange).get_dy(i - 1, j - 1, amountIn);
        }
    }

    function calcUniV2In(
        address exchange,
        address fromToken,
        address destToken,
        address[] memory path,
        uint256 amountOut
    ) private view returns (uint256) {
        address[] memory validPath = getUniV2ValidPath(
            fromToken,
            destToken,
            path
        );
        uint256[] memory inAmounts = IUniswapV2Exchange(exchange).getAmountsIn(
            amountOut,
            validPath
        );
        return inAmounts[0];
    }

    function calcUniV2Out(
        address exchange,
        address fromToken,
        address destToken,
        address[] memory path,
        uint256 amountIn
    ) private view returns (uint256) {
        address[] memory validPath = getUniV2ValidPath(
            fromToken,
            destToken,
            path
        );
        uint256[] memory outAmounts = IUniswapV2Exchange(exchange)
            .getAmountsOut(amountIn, validPath);
        return outAmounts[outAmounts.length - 1];
    }

    function getExpectedInput(
        address fromToken,
        address destToken,
        address[] memory path,
        uint256 amountOut,
        address[] memory exchanges,
        uint256[] memory flags
    )
        public
        view
        override
        returns (
            uint256, /*returnAmount*/
            uint256 /*best exchange index*/
        )
    {
        fromToken = IERC20(fromToken).isETH() ? weth : fromToken;
        destToken = IERC20(destToken).isETH() ? weth : destToken;

        if (fromToken == destToken || amountOut == 0) {
            // when from token is same as dest token
            return (amountOut, 0);
        }

        uint256 bestAmount = uint256(int256(-1));
        uint256 bestIndex = 0;
        for (uint256 i = 0; i < exchanges.length; i++) {
            uint256 amountIn = calculateInAmount(
                exchanges[i],
                flags[i],
                fromToken,
                destToken,
                path,
                amountOut
            );
            if (bestAmount > amountIn && amountIn > 0) {
                bestAmount = amountIn;
                bestIndex = i;
            }
        }

        return (bestAmount, bestIndex);
    }

    function getExpectedReturn(
        address fromToken,
        address destToken,
        address[] memory path,
        uint256 amountIn,
        address[] memory exchanges,
        uint256[] memory flags
    )
        public
        view
        override
        returns (
            uint256, /*returnAmount*/
            uint256 /*best exchange index*/
        )
    {
        fromToken = IERC20(fromToken).isETH() ? weth : fromToken;
        destToken = IERC20(destToken).isETH() ? weth : destToken;

        if (fromToken == destToken || amountIn == 0) {
            // when from token is same as dest token
            return (amountIn, 0);
        }

        uint256 bestAmount = 0;
        uint256 bestIndex = 0;
        for (uint256 i = 0; i < exchanges.length; i++) {
            uint256 amountOut = calculateOutAmount(
                exchanges[i],
                flags[i],
                fromToken,
                destToken,
                path,
                amountIn
            );
            if (bestAmount < amountOut) {
                bestAmount = amountOut;
                bestIndex = i;
            }
        }

        return (bestAmount, bestIndex);
    }

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        address[] memory path,
        uint256 amountIn,
        uint256 minReturn,
        address, /** recipient is not used here, send from/to tokens back to msg sender */
        address[] memory exchanges,
        uint256[] memory flags
    ) public payable override {
        // no need to swap when from token is same as dest token
        if (
            (fromToken.isETH() && destToken.isETH()) ||
            address(fromToken) == address(destToken)
        ) {
            return;
        }

        fromToken.universalTransferFrom(msg.sender, address(this), amountIn);
        uint256 confirmed = fromToken.universalBalanceOf(address(this));

        (, uint256 bestIndex) = getExpectedReturn(
            address(fromToken),
            address(destToken),
            path,
            confirmed,
            exchanges,
            flags
        );
        _swap(
            exchanges[bestIndex],
            flags[bestIndex],
            fromToken,
            destToken,
            path,
            confirmed
        );

        uint256 returnAmount = destToken.universalBalanceOf(address(this));
        require(
            returnAmount >= minReturn,
            "DexAggregatorImpl: actual return amount is less than minReturn"
        );
        destToken.universalTransfer(msg.sender, returnAmount);
        fromToken.universalTransfer(
            msg.sender,
            fromToken.universalBalanceOf(address(this))
        );
    }

    function _swap(
        address exchange,
        uint256 flag,
        IERC20 fromToken,
        IERC20 destToken,
        address[] memory path,
        uint256 amountIn
    ) private {
        if (fromToken.isETH() && address(destToken) == weth) {
            // ETH => WETH
            IWETH(weth).deposit{value: amountIn}();
            return;
        }
        if (address(fromToken) == weth && destToken.isETH()) {
            // WETH => ETH
            IWETH(weth).withdraw(amountIn);
            return;
        }
        if (flag == FLAG_UNISWAP_V2) {
            _swapOnUniV2(
                exchange,
                address(fromToken),
                address(destToken),
                path,
                amountIn
            );
            return;
        }
        if (flag == FLAG_UNISWAP_V3) {}
        if (flag >= FLAG_CURVE_COMPOUND && flag <= FLAG_CURVE_TBTC) {
            _swapOnCurv(
                exchange,
                flag,
                address(fromToken),
                address(destToken),
                amountIn
            );
        }
    }

    function _swapOnCurv(
        address exchange,
        uint256 flag,
        address fromToken,
        address destToken,
        uint256 amount
    ) private {
        (int128 i, int128 j) = getCurveParams(flag, fromToken, destToken);
        if (i == 0 || j == 0) {
            return;
        }

        _infiniteApproveIfNeeded(IERC20(fromToken), exchange);
        if (flag <= FLAG_CURVE_PAX) {
            ICurve(exchange).exchange_underlying(i - 1, j - 1, amount, 0);
        } else {
            ICurve(exchange).exchange(i - 1, j - 1, amount, 0);
        }
    }

    function _swapOnUniV2(
        address exchange,
        address fromToken,
        address destToken,
        address[] memory path,
        uint256 amountIn
    ) private {
        address[] memory validPath = getUniV2ValidPath(
            fromToken,
            destToken,
            path
        );
        if (IERC20(fromToken).isETH()) {
            IUniswapV2Exchange(exchange)
                .swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: amountIn
            }(0, validPath, address(this), block.timestamp.add(300));
            return;
        }
        _infiniteApproveIfNeeded(IERC20(fromToken), exchange);
        if (IERC20(destToken).isETH()) {
            IUniswapV2Exchange(exchange)
                .swapExactTokensForETHSupportingFeeOnTransferTokens(
                    amountIn,
                    0,
                    validPath,
                    address(this),
                    block.timestamp.add(300)
                );
            return;
        }
        IUniswapV2Exchange(exchange)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                0,
                validPath,
                address(this),
                block.timestamp.add(300)
            );
    }

    /**
     * @notice It allows the admin to recover tokens sent to the contract
     * @param token_: the address of the token to withdraw
     * @param amount_: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverTokens(address token_, uint256 amount_) external onlyOwner {
        IERC20(token_).universalTransfer(_msgSender(), amount_);
    }
}