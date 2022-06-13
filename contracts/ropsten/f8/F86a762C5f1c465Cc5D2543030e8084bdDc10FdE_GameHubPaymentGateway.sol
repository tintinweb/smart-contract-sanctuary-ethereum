/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

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

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// pragma solidity ^0.5.5;

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

// File: contracts/interfaces/IWETH.sol

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// File: contracts/interfaces/ISwapRouter

/**
 * @title ISwapRouter
 * @dev Abbreviated interface of UniswapV2Router
 */
interface ISwapRouter {
    function WETH() external pure returns (address);

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

// File: contracts/GameHubPaymentGateway.sol

contract GameHubPaymentGateway is Pausable {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    uint16 private constant DELIMINATOR = 10000;

    /** Fee distribution logic */
    uint16 public _marketingRate = 3000;
    uint16 public _treasuryRate = 2000;
    uint16 public _charityRate = 5000;

    /** Swap to unit token or not before distribution */
    bool public _swapAtDeposit = false;

    /** Rates of unit token to game coin */
    uint256 public _gameCoinPrice = 1 ether;

    /** Min / max limitation per deposit (it is calculated in unit token) */
    uint256 public _maxDepositAmount = 0;
    uint256 public _minDepositAmount = 0;

    /** Wallet addresses for distributing deposited funds */
    address public _marketingWallet =
        0x19E53469BdfD70e103B18D9De7627d88c4506DF2;
    address public _treasuryWallet = 0x172A25d57dA59AB86792FB8cED103ad871CBEf34;
    address public _charityWallet = 0x7861e0f3b46e7C4Eac4c2fA3c603570d58bd1d97;

    /** Unit token corresponding to game coin */
    address public _unitToken = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; // Ropsten USDC
    /** Swap router address */
    ISwapRouter public _swapRouter =
        ISwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Ropsten router

    /** Accounts blocked to deposit */
    mapping(address => bool) public _accountBlacklist;
    /** Tokens whitelisted for deposit */
    mapping(address => bool) public _tokenWhitelist;

    event NewDeposit(
        address indexed account,
        address indexed payToken, // paid token
        uint256 payAmount, // paid token amount
        address indexed unitToken, // unit token
        uint256 unitAmount, // amount in unit token
        uint256 gameCoinAmount // game coin amount allocated to the user
    );
    event NewDistribute(
        address indexed account,
        address indexed token,
        uint256 marketingAmount,
        uint256 treasuryAmount,
        uint256 charityAmount
    );
    event NewAccountBlacklist(address indexed account, bool blacklisted);
    event NewTokenWhitelist(address indexed token, bool whitelisted);

    constructor() {
        _tokenWhitelist[address(0x0)] = true;
        _tokenWhitelist[0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE] = true;
        _tokenWhitelist[0x07865c6E87B9F70255377e024ace6630C1Eaa37F] = true; // Ropsten USDC
        _tokenWhitelist[0x110a13FC3efE6A245B50102D2d79B3E76125Ae83] = true; // Ropsten USDT
        _tokenWhitelist[0xc778417E063141139Fce010982780140Aa0cD5Ab] = true; // Ropsten WETH
    }

    /**
     * @dev To receive ETH
     */
    receive() external payable {}

    /**
     * @notice Deposit tokens to get game coins
     * @dev Only available when gateway is not paused
     * @param tokenIn_: deposit token, must whitelisted, allow native token (0x0)
     * @param path_: optional param for indicating swap path instead of default path
     */
    function deposit(
        address tokenIn_,
        uint256 amountIn_,
        address[] memory path_
    ) external payable whenNotPaused {
        require(!_accountBlacklist[_msgSender()], "Blacklisted account");
        require(_tokenWhitelist[tokenIn_], "Token not whitelisted");

        IERC20 payingToken = IERC20(tokenIn_);
        uint256 balanceBefore = payingToken.universalBalanceOf(address(this));
        payingToken.universalTransferFrom(
            _msgSender(),
            address(this),
            amountIn_
        );
        if (!payingToken.isETH()) {
            amountIn_ = payingToken.universalBalanceOf(address(this)).sub(
                balanceBefore
            );
        }

        uint256 unitAmount = 0;
        uint256 gameCoinAmount = 0;
        // Swap to unitToken, and distribute
        if (_swapAtDeposit) {
            (unitAmount, gameCoinAmount) = doSwapWithDeposit(
                tokenIn_,
                amountIn_,
                path_
            );
            distributeToken(IERC20(_unitToken), unitAmount);
        }
        // Just distribute tokenIn
        else {
            distributeToken(IERC20(tokenIn_), amountIn_);
            (unitAmount, gameCoinAmount) = viewConversion(
                tokenIn_,
                amountIn_,
                path_
            );
        }

        require(
            _minDepositAmount == 0 || _minDepositAmount <= gameCoinAmount,
            "Too small amount"
        );
        require(
            _maxDepositAmount == 0 || _maxDepositAmount >= gameCoinAmount,
            "Too much amount"
        );

        emit NewDeposit(
            _msgSender(),
            tokenIn_,
            amountIn_,
            _unitToken,
            unitAmount,
            gameCoinAmount
        );
    }

    /**
     * @notice Get valid path for swapping to unit token
     * @param givenPath_: User defined swap path
     * @return given path if valid, or new valid path
     */
    function getValidPath(address tokenIn_, address[] memory givenPath_)
        public
        view
        returns (address[] memory)
    {
        bool isValidStart = true;
        bool isValidEnd = true;
        address WETH = _swapRouter.WETH();

        if (givenPath_.length < 2) {
            isValidStart = false;
        } else if (IERC20(tokenIn_).isETH()) {
            if (givenPath_[0] != WETH) {
                isValidStart = false;
            }
        } else if (!isSameTokens(givenPath_[0], tokenIn_)) {
            isValidStart = false;
        } else if (IERC20(_unitToken).isETH()) {
            if (givenPath_[givenPath_.length - 1] != WETH) {
                isValidEnd = false;
            }
        } else if (
            !isSameTokens(givenPath_[givenPath_.length - 1], _unitToken)
        ) {
            isValidEnd = false;
        }

        if (isValidStart && isValidEnd) {
            return givenPath_;
        } else {
            address[] memory newValidPath = new address[](2);
            newValidPath[0] = IERC20(tokenIn_).isETH() ? WETH : tokenIn_;
            newValidPath[1] = IERC20(_unitToken).isETH() ? WETH : _unitToken;
            return newValidPath;
        }
    }

    /**
     * @notice View converted amount in unit token, and game coin amount
     * @param path_: swap path for the conversion
     */
    function viewConversion(
        address tokenIn_,
        uint256 amountIn_,
        address[] memory path_
    ) public view returns (uint256 unitAmount_, uint256 gameCoinAmount_) {
        address[] memory validPath = getValidPath(tokenIn_, path_);
        address WETH = _swapRouter.WETH();

        if (
            isSameTokens(tokenIn_, _unitToken) ||
            (tokenIn_ == WETH && IERC20(_unitToken).isETH()) ||
            (IERC20(tokenIn_).isETH() && _unitToken == WETH)
        ) {
            // No need to expect amount in case of tokenIn = unitToken, WETH => ETH, ETH => WETH
            unitAmount_ = amountIn_;
        } else {
            uint256[] memory amountsOut = _swapRouter.getAmountsOut(
                amountIn_,
                validPath
            );
            unitAmount_ = amountsOut[amountsOut.length - 1];
        }
        gameCoinAmount_ = unitAmount_.div(_gameCoinPrice);
    }

    /**
     * @notice Swap deposited tokens to unitToken
     */
    function doSwapWithDeposit(
        address tokenIn_,
        uint256 amountIn_,
        address[] memory path_
    ) internal returns (uint256 unitAmount_, uint256 gameCoinAmount_) {
        address WETH = _swapRouter.WETH();
        address[] memory validPath = getValidPath(tokenIn_, path_);

        // tokenIn = unitToken, no need any swap
        if (isSameTokens(tokenIn_, _unitToken)) {
            unitAmount_ = amountIn_;
        }
        // WETH => ETH,
        else if (tokenIn_ == WETH && IERC20(_unitToken).isETH()) {
            IWETH(WETH).withdraw(amountIn_);
            unitAmount_ = amountIn_;
        }
        // ETH => WETH
        else if (IERC20(tokenIn_).isETH() && _unitToken == WETH) {
            IWETH(WETH).deposit{value: amountIn_}();
            unitAmount_ = amountIn_;
        } else {
            uint256 balanceBefore = IERC20(_unitToken).universalBalanceOf(
                address(this)
            );
            if (!IERC20(tokenIn_).isETH()) {
                // Approve operation for swapping
                IERC20(tokenIn_).universalApprove(
                    address(_swapRouter),
                    amountIn_
                );
            }
            // tokenIn => ETH
            if (IERC20(_unitToken).isETH()) {
                _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    amountIn_,
                    0,
                    validPath,
                    address(this),
                    block.timestamp.add(300)
                );
            }
            // ETH => unitToken
            else if (IERC20(tokenIn_).isETH()) {
                _swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: amountIn_
                }(0, validPath, address(this), block.timestamp.add(300));
            }
            // tokenIn => unitToken
            else {
                _swapRouter
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        amountIn_,
                        0,
                        validPath,
                        address(this),
                        block.timestamp.add(300)
                    );
            }
            unitAmount_ = IERC20(_unitToken)
                .universalBalanceOf(address(this))
                .sub(balanceBefore);
        }
        gameCoinAmount_ = unitAmount_.div(_gameCoinPrice);
    }

    /**
     * @notice Distribute token as the distribution rates
     */
    function distributeToken(IERC20 token_, uint256 amount_) internal {
        uint256 marketingAmount = amount_.mul(_marketingRate).div(DELIMINATOR);
        uint256 treasuryAmount = amount_.mul(_treasuryRate).div(DELIMINATOR);
        uint256 charityAmount = amount_.sub(marketingAmount).sub(
            treasuryAmount
        );

        if (marketingAmount > 0) {
            token_.universalTransfer(_marketingWallet, marketingAmount);
        }
        if (charityAmount > 0) {
            token_.universalTransfer(_charityWallet, charityAmount);
        }
        if (treasuryAmount > 0) {
            token_.universalTransfer(_treasuryWallet, treasuryAmount);
        }
        emit NewDistribute(
            _msgSender(),
            address(token_),
            marketingAmount,
            treasuryAmount,
            charityAmount
        );
    }

    /**
     * @notice Check if 2 tokens are same
     */
    function isSameTokens(address token1_, address token2_)
        internal
        pure
        returns (bool)
    {
        return
            token1_ == token2_ ||
            (IERC20(token1_).isETH() && IERC20(token2_).isETH());
    }

    /**
     * @notice Block account from deposit or not
     * @dev Only owner can call this function
     */
    function blockAccount(address account_, bool flag_) external onlyOwner {
        _accountBlacklist[account_] = flag_;

        emit NewAccountBlacklist(account_, flag_);
    }

    /**
     * @notice Allow token for deposit or not
     * @dev Only owner can call this function
     */
    function allowToken(address token_, bool flag_) external onlyOwner {
        _tokenWhitelist[token_] = flag_;

        emit NewTokenWhitelist(token_, flag_);
    }

    /**
     * @notice Set swap router
     * @dev Only owner can call this function
     */
    function setSwapRouter(address swapRouter_) external onlyOwner {
        require(swapRouter_ != address(0), "Invalid swap router");
        _swapRouter = ISwapRouter(swapRouter_);
    }

    /**
     * @notice Set deposit min / max limit
     * @dev Only owner can call this function
     */
    function setDepositLimit(uint256 minAmount_, uint256 maxAmount_)
        external
        onlyOwner
    {
        _minDepositAmount = minAmount_;
        _maxDepositAmount = maxAmount_;
    }

    /**
     * @notice Toggle if deposited tokens are swapped to the unit token or not
     * @dev Only owner can call this function
     */
    function toggleSwapAtDeposit() external onlyOwner {
        _swapAtDeposit = !_swapAtDeposit;
    }

    /**
     * @notice Set unit token and the rate of unit token to game coin
     * @dev Only owner can call this function
     */
    function setUnitTokenAndRate(address unitToken_, uint256 rate_)
        external
        onlyOwner
    {
        IERC20(unitToken_).universalBalanceOf(address(this)); // Check the token address is valid
        require(rate_ > 0, "Invalid rates to game coin");
        _unitToken = unitToken_;
        _gameCoinPrice = rate_;
    }

    /**
     * @notice Set distribution rates, sum of the params should be 100% (10000)
     * @dev Only owner can call this function
     */
    function setDistributionRates(
        uint16 marketingRate_,
        uint16 treasuryRate_,
        uint16 charityRate_
    ) external onlyOwner {
        require(
            marketingRate_ + treasuryRate_ + charityRate_ == DELIMINATOR,
            "Invalid values"
        );
        _marketingRate = marketingRate_;
        _treasuryRate = treasuryRate_;
        _charityRate = charityRate_;
    }

    /**
     * @notice Set distribution wallets
     * @dev Only owner can call this function
     */
    function setDistributionWallets(
        address marketingWallet_,
        address treasuryWallet_,
        address charityWallet_
    ) external onlyOwner {
        require(marketingWallet_ != address(0), "Invalid marketing wallet");
        require(treasuryWallet_ != address(0), "Invalid treasury wallet");
        require(charityWallet_ != address(0), "Invalid charity wallet");
        _marketingWallet = marketingWallet_;
        _treasuryWallet = treasuryWallet_;
        _charityWallet = charityWallet_;
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