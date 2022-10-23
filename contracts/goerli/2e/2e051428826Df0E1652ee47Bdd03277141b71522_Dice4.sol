pragma solidity ^0.6.2;

interface IIDO {
    function getEndTimestamp() external view returns (uint256);
}

pragma solidity ^0.6.2;

interface IAssassinCreed {
    function balanceOf(address account) external view returns (uint256);

    function burnFrom(address from, uint256 rawAmount) external;
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/utils/Address.sol
pragma solidity ^0.6.2;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

pragma solidity ^0.6.0;

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/token/ERC20/IERC20.sol
pragma solidity ^0.6.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/token/ERC20/SafeERC20.sol
pragma solidity ^0.6.0;

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        _callOptionalReturn(
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
        _callOptionalReturn(
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
        _callOptionalReturn(
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/utils/ReentrancyGuard.sol
pragma solidity ^0.6.0;


contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/GSN/Context.sol
pragma solidity ^0.6.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.1.0/contracts/access/Ownable.sol
pragma solidity ^0.6.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.6.0;

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    address private immutable original;

    constructor() public {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}



// File: https://github.com/smartcontractkit/chainlink/blob/0964ca290565587963cc4ad8f770274f5e0d9e9d/evm-contracts/src/v0.6/interfaces/LinkTokenInterface.sol
pragma solidity ^0.6.0;

interface LinkTokenInterface {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 value)
        external
        returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue)
        external
        returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue)
        external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value)
        external
        returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}


// File: contracts/Dice4Utopia_com.sol
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


contract Dice4 is
    NoDelegateCall,
    Ownable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using Address for address;

    using SafeERC20 for IERC20;

    // Chainlink VRF related parameters
    address public constant LINK_TOKEN =
        0xb0897686c545045aFc77CF20eC7A532E3120E0F1; 

    address public constant VRF_COORDINATOR =
        0x3d2341ADb2D31f1c5530cDC622016af293177AE0; 
    bytes32 public keyHash =
        0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    uint256 public chainlinkFee = 100000000000000; // 0.0001 LINK

    address public IDO_Address;
    address public AssassinCreed_Address;

    // Each bet is deducted 100 basis points (1%) in favor of the house
    uint256 public houseEdgeBP = 100;

    // Modulo is the number of equiprobable outcomes in a game:
    //  2 for coin flip
    //  6 for dice roll
    //  36 for double dice roll
    //  37 for roulette
    //  100 for Dice4Utopia_com
    uint256 constant MAX_MODULO = 100;

    // Modulos below MAX_MASK_MODULO are checked against a bit mask, allowing betting on specific outcomes.
    // For example in a dice roll (modolo = 6),
    // 000001 mask means betting on 1. 000001 converted from binary to decimal becomes 1.
    // 101000 mask means betting on 4 and 6. 101000 converted from binary to decimal becomes 40.
    // The specific value is dictated by the fact that 256-bit intermediate
    // multiplication result allows implementing population count efficiently
    // for numbers that are up to 42 bits, and 40 is the highest multiple of eight below 42.
    uint256 constant MAX_MASK_MODULO = 40;

    // This is a check on bet mask overflow. Maximum mask is equivalent to number of possible binary outcomes for maximum modulo.
    uint256 constant MAX_BET_MASK = 2**MAX_MASK_MODULO;

    // These are constants that make O(1) population count in placeBet possible.
    uint256 constant POPCNT_MULT =
        0x0000000000002000000000100000000008000000000400000000020000000001;
    uint256 constant POPCNT_MASK =
        0x0001041041041041041041041041041041041041041041041041041041041041;
    uint256 constant POPCNT_MODULO = 0x3F;

    // In addition to house edge, wealth tax is added for bet amount that exceeds a multiple of wealthTaxThreshold.
    // For example, if wealthTaxThreshold = 200 ether and wealthTaxBP = 100,
    // A bet amount of 200 ether will have a wealth tax of 1% in addition to house edge.
    // A bet amount of 400 ether will have a wealth tax of 2% in addition to house edge.
    uint256 public wealthTaxThreshold = 200 ether; // main network setted 500000000000000000000
    uint256 public wealthTaxBP = 100;

    // Minimum and maximum bet amounts.
    uint256 public minBetAmount = 2 ether;
    uint256 public maxBetAmount = 800 ether;

    // Balance-to-maxProfit ratio. Used to dynamically adjusts maxProfit based on balance.
    uint256 public balanceMaxProfitRatio = 12;

    // Funds that are locked in potentially winning bets. Prevents contract from committing to new bets that it cannot pay out.
    uint256 public lockedInBets;

    uint256 public sharesDiceAll;

    uint256 public Wall = 10e18;

    uint256 public SatanDevil = 180;

    // Info of each bet.
    struct Bet {
        // Wager amount in wei.
        uint256 amount;
        // Modulo of a game.
        uint8 modulo;
        // Number of winning outcomes, used to compute winning payment (* modulo/rollUnder),
        // and used instead of mask for games with modulo > MAX_MASK_MODULO.
        uint8 rollUnder;
        // Bit mask representing winning bet outcomes (see MAX_MASK_MODULO comment).
        uint40 mask;
        // Block number of placeBet tx.
        uint256 placeBlockNumber;
        // Address of a gambler, used to pay out winning bets.
        address payable gambler;
        // Status of bet settlement.
        bool isSettled;
        // Outcome of bet.
        uint256 outcome;
        // Win amount.
        uint256 winAmount;
    }

    // Array of bets
    Bet[] public bets;

    // Mapping requestId returned by Chainlink VRF to bet Id.
    mapping(bytes32 => uint256) public betMap;
    mapping(address => uint256) public sharesDice;

    function getBets() external view returns (Bet[] memory) {
        return bets;
    }

    // Signed integer used for tracking house profit since inception.
    uint256 public incomeProfit;
    uint256 public outcomeProfit;

    // 15% Of All Matic
    uint256 public Exodus;

    // Events
    event BetPlaced(
        uint256 indexed betId,
        address indexed gambler,
        uint256 amount,
        uint8 indexed modulo,
        uint8 rollUnder,
        uint40 mask
    );

    event BetSettled(
        uint256 indexed betId,
        address indexed gambler,
        uint256 amount,
        uint8 indexed modulo,
        uint8 rollUnder,
        uint40 mask,
        uint256 outcome,
        uint256 winAmount
    );
    event BetRefunded(
        uint256 indexed betId,
        address indexed gambler,
        uint256 amount
    );
    event Deposit(address user, uint256 investment);
    event WithdrawalIncomeEvent(
        address user,
        uint256 burnACreed, // burn amount_burn_share
        uint256 outMatic
    );

    // Constructor. Using Chainlink VRFConsumerBase constructor.
    constructor(address AssassinCreed_Address_, address IDO_Address_)
        public
    {
        AssassinCreed_Address = AssassinCreed_Address_;
        IDO_Address = IDO_Address_;
    }

    function balanceAddress(address _address_) external view returns (uint256) {
        return address(_address_).balance;
    }

    // Returns link token balance.
    function balanceLinkToken() external view returns (uint256) {
        return 100; //LINK.balanceOf(address(this));
    }

    // Returns number of bets.
    function betsLength() external view returns (uint256) {
        return bets.length;
    }

    // Returns maximum profit allowed per bet. Prevents contract from accepting any bets with potential profit exceeding maxProfit.
    function maxProfit() public view returns (uint256) {
        return diceFreeMatic() / balanceMaxProfitRatio;
    }

    function setWall(uint256 wall) external onlyOwner {
        Wall = wall;
    }

    // Set balance-to-maxProfit ratio.
    function setBalanceMaxProfitRatio(uint256 _balanceMaxProfitRatio)
        external
        onlyOwner
    {
        balanceMaxProfitRatio = _balanceMaxProfitRatio;
    }

    // Update Chainlink fee.
    function setChainlinkFee(uint256 _chainlinkFee) external onlyOwner {
        chainlinkFee = _chainlinkFee;
    }

    // Update Chainlink keyHash. Currently using keyHash with 10 block waiting time config. May configure to 64 block waiting time for more security.
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    // Set minimum bet amount. minBetAmount should be large enough such that its house edge fee can cover the Chainlink oracle fee.
    function setMinBetAmount(uint256 _minBetAmount) external onlyOwner {
        minBetAmount = _minBetAmount;
    }

    // Set maximum bet amount. Setting this to zero effectively disables betting.
    function setMaxBetAmount(uint256 _maxBetAmount) external onlyOwner {
        maxBetAmount = _maxBetAmount;
    }

    // Set house edge.
    function setHouseEdgeBP(uint256 _houseEdgeBP) external onlyOwner {
        houseEdgeBP = _houseEdgeBP;
    }

    // Set wealth tax. Setting this to zero effectively disables wealth tax.
    function setWealthTaxBP(uint256 _wealthTaxBP) external onlyOwner {
        wealthTaxBP = _wealthTaxBP;
    }

    // Set threshold to trigger wealth tax.
    function setWealthTaxThreshold(uint256 _wealthTaxThreshold)
        external
        onlyOwner
    {
        wealthTaxThreshold = _wealthTaxThreshold;
    }

    // Place bet
    function placeBet(uint256 betMask, uint256 modulo)
        external
        nonReentrant returns(uint256 betId)
    {
        // Validate input data.
        uint256 amount = block.number+1;
        require(modulo > 1 && modulo <= MAX_MODULO, "Modulo not within range");
        require(betMask > 0 && betMask < MAX_BET_MASK, "Mask not within range");

        uint256 rollUnder;
        uint256 mask;

        if (modulo <= MAX_MASK_MODULO) {
            // Small modulo games can specify exact bet outcomes via bit mask.
            // rollUnder is a number of 1 bits in this mask (population count).
            // This magic looking formula is an efficient way to compute population
            // count on EVM for numbers below 2**40.
            rollUnder = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            mask = betMask;
        } else {
            // Larger modulos games specify the right edge of half-open interval of winning bet outcomes.
            require(
                betMask > 0 && betMask <= modulo,
                "betMask larger than modulo"
            );
            rollUnder = betMask;
        }

        // Winning amount.
        uint256 possibleWinAmount = getWinAmount(amount, modulo, rollUnder);

        // Update lock funds.
        lockedInBets += possibleWinAmount;

        // Record bet in event logs. Placed before pushing bet to array in order to get the correct bets.length.
        emit BetPlaced(
            bets.length,
            msg.sender,
            amount,
            uint8(modulo),
            uint8(rollUnder),
            uint40(mask)
        );

        betId = bets.length;
        // Store bet in bet list.
        bets.push(
            Bet({
                amount: amount,
                modulo: uint8(modulo),
                rollUnder: uint8(rollUnder),
                mask: uint40(mask),
                placeBlockNumber: block.number,
                gambler: msg.sender,
                isSettled: false,
                outcome: 0,
                winAmount: 0
            })
        );
    }

    // Returns the expected win amount.
    function getWinAmount(
        uint256 amount,
        uint256 modulo,
        uint256 rollUnder
    ) private view returns (uint256 winAmount) {
        require(
            0 < rollUnder && rollUnder <= modulo,
            "Win probability out of range"
        );
        uint256 houseEdgeFee = (amount *
            (houseEdgeBP + getEffectiveWealthTaxBP(amount))) / 10000;
        winAmount = ((amount - houseEdgeFee) * modulo) / rollUnder;
    }

    // Get effective wealth tax for a given bet size.
    function getEffectiveWealthTaxBP(uint256 amount)
        private
        view
        returns (uint256 effectiveWealthTaxBP)
    {
        effectiveWealthTaxBP = (amount / wealthTaxThreshold) * wealthTaxBP;
    }


    // Settle bet. Function can only be called by fulfillRandomness function, which in turn can only be called by Chainlink VRF.
    function settleBet(uint256 betId, uint256 randomNumber)
        external
        nonReentrant
    {
        Bet storage bet = bets[betId];
        uint256 amount = bet.amount;

        // Validation checks.
        require(amount > 0, "Bet does not exist");
        require(bet.isSettled == false, "Bet is settled already");

        // Fetch bet parameters into local variables (to save gas).
        uint256 modulo = bet.modulo;
        uint256 rollUnder = bet.rollUnder;
        address payable gambler = bet.gambler;

        // Do a roll by taking a modulo of random number.
        uint256 outcome = randomNumber % modulo;

        // Win amount if gambler wins this bet
        uint256 possibleWinAmount = getWinAmount(amount, modulo, rollUnder);

        // Actual win amount by gambler.
        uint256 winAmount = 0;

        // Determine dice outcome.
        if (modulo <= MAX_MASK_MODULO) {
            // For small modulo games, check the outcome against a bit mask.
            if ((2**outcome) & bet.mask != 0) {
                winAmount = possibleWinAmount;
            }
        } else {
            // For larger modulos, check inclusion into half-open interval.
            if (outcome < rollUnder) {
                winAmount = possibleWinAmount;
            }
        }

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets -= possibleWinAmount;

        bet.isSettled = true;
        bet.winAmount = winAmount;
        bet.outcome = outcome;

        // Send prize to winner
        if (winAmount > 0) {
            uint256 _outcomeProfit_ = winAmount.sub(amount);
            outcomeProfit += _outcomeProfit_;

            uint256 _Exodus_ = _outcomeProfit_.mul(15).div(100);
            Exodus >= _Exodus_ ? Exodus -= _Exodus_ : Exodus = 0;

            // gambler.transfer(winAmount);
        } else {
            incomeProfit += amount;
            Exodus += amount.mul(15).div(100);
        }

        // Record bet settlement in event log.
        emit BetSettled(
            betId,
            gambler,
            amount,
            uint8(modulo),
            uint8(rollUnder),
            bet.mask,
            outcome,
            winAmount
        );
    }

    // Owner can withdraw 85% funds not exceeding balance minus potential win amounts by open bets.
    function withdrawFunds(address payable beneficiary, uint256 withdrawAmount)
        external
        onlyOwner
    {
        // max 85 %
        require(
            withdrawAmount <= diceFreeMatic() - Exodus,
            "Withdrawal exceeds limit - Fair For Dao2Utopia.com ☮ !"
        );
        beneficiary.transfer(withdrawAmount);
    }

    // Owner can withdraw non-MATIC tokens.
    function withdrawToken(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(
            owner(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    // Return the bet in the very unlikely scenario it was not settled by Chainlink VRF.
    // In case you find yourself in a situation like this, just contact Dice4Utopia_com support.
    // However, nothing precludes you from calling this method yourself.
    function refundBet(uint256 betId) external nonReentrant {
        Bet storage bet = bets[betId];
        uint256 amount = bet.amount;

        // Validation checks
        require(amount > 0, "Bet does not exist");
        require(bet.isSettled == false, "Bet is settled already");

        uint256 possibleWinAmount = getWinAmount(
            amount,
            bet.modulo,
            bet.rollUnder
        );

        // Unlock possibleWinAmount from lockedInBets, regardless of the outcome.
        lockedInBets -= possibleWinAmount;

        // Update bet records
        bet.isSettled = true;
        bet.winAmount = amount;

        // Record refund in event logs
        emit BetRefunded(betId, bet.gambler, amount);
    }

    function deposit(address user, uint256 matic) external payable {
        uint256 msgValue = matic;
        require(
            msgValue > 0 && msg.sender == IDO_Address,
            "deposit::Invalid investment"
        );

        sharesDice[user] += msgValue;
        sharesDiceAll += msgValue;

        Exodus += msgValue.mul(15).div(100);
        emit Deposit(user, msgValue);
    }

    // Work in the dark, but serve the light ! ☮
    // Assassin have to approve Assassin's Creed to this address before
    function WithdrawalIncome(uint256 amount_burn_share)
        external
        nonReentrant
        noDelegateCall
    {
        require(
            msg.sender == tx.origin,
            "WithdrawalIncome::please be EOA account"
        );

        address payable user = msg.sender;
        uint256 share = sharesDice[user];
        require(
            share > 0 && sharesDiceAll > 0,
            "WithdrawalIncome::Sorry, you have not participated in the Initial Digital Assets Offering"
        );
        require(
            share >= amount_burn_share,
            "WithdrawalIncome::Shares to be destroyed exceeds your shares"
        );

        // clear user shares
        sharesDice[user] = share.sub(amount_burn_share);

        IAssassinCreed(AssassinCreed_Address).burnFrom(
            msg.sender,
            getSatanDevil(amount_burn_share)
        );

        if (
            block.timestamp > IIDO(IDO_Address).getEndTimestamp().add(182 days)
        ) {
            // 15% of All Matic
            require(
                Exodus > 0,
                "WithdrawalIncome::HouseBalance 15% less than 0 matic"
            );
            uint256 For___Assassin = Exodus.mul(amount_burn_share).div(
                sharesDiceAll
            );
            require(
                For___Assassin <= Exodus,
                "WithdrawalIncome::Exodus Insufficient balance"
            );
            // clear Exodus
            Exodus -= For___Assassin;
            user.transfer(For___Assassin);
            emit WithdrawalIncomeEvent(user, amount_burn_share, For___Assassin);
        } else {
            // 10% of Profit Matic
            require(
                incomeProfit > outcomeProfit,
                "WithdrawalIncome::HouseProfit 10% less than 0 matic"
            );
            uint256 Profit = incomeProfit.sub(outcomeProfit);

            uint256 power = Profit.mul(10).div(100);
            uint256 For___Assassin = power.mul(amount_burn_share).div(
                sharesDiceAll
            );
            require(
                For___Assassin <= power && For___Assassin <= incomeProfit,
                "WithdrawalIncome::IncomeProfit Insufficient balance"
            );
            // clear incomeProfit
            incomeProfit -= For___Assassin;
            user.transfer(For___Assassin);
            emit WithdrawalIncomeEvent(user, amount_burn_share, For___Assassin);
        }

        // clear sharesDiceAll
        sharesDiceAll.sub(amount_burn_share);

        MerlinMage(amount_burn_share);
    }

    // 15% of All
    function FullRelease() external view returns (uint256) {
        return
            block.timestamp > IIDO(IDO_Address).getEndTimestamp().add(182 days)
                ? Exodus
                : 0;
    }

    // 10% of Profit
    function ProfitRelease() external view returns (uint256) {
        return
            incomeProfit >= outcomeProfit
                ? incomeProfit.sub(outcomeProfit).mul(10).div(100)
                : 0;
    }

    function getSatanDevil(uint256 amount) private view returns (uint256) {
        return amount.mul(SatanDevil).div(100);
    }

    function MerlinMage(uint256 amount_burn_share) private {
        if(amount_burn_share >= Wall) { 
            SatanDevil < 1000 ? SatanDevil += 2 : SatanDevil = 1000;
        } else { 
            SatanDevil += 6;
        }
        if (SatanDevil > 1000) {  SatanDevil = 1000; }
    }

    function diceFreeMatic() private view returns (uint256 HouseFreeMatic) {
        uint256 HouseMatic = address(this).balance;
        require(HouseMatic >= lockedInBets, "diceFreeMatic::HouseMatic < lockedInBets");
        HouseFreeMatic = HouseMatic - lockedInBets;
    }

    // Fallback & receive payable function
    fallback() external payable {}

    receive() external payable {}
}