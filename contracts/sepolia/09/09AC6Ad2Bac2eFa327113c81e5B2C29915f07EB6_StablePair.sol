// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPair {
    function initialize(address[] memory _tokens, bytes memory _data) external;

    function PAIR_TYPE() external view returns (uint8);

    function AUTH() external view returns (bool);

    function tokens() external view returns (address[] memory);

    function getAmountOut(address _from, address _to, uint256 _amount) external view returns (uint256);
}

interface IVolatilePair is IPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

    function mint(address _to) external returns (uint256 _liquidity);

    function burn(address _to) external returns (uint256 _amount0, uint256 _amount1);

    function swap(uint256 _amount0Out, uint256 _amount1Out, address _to, bytes calldata _data) external;

    function getRealBalanceOf() external view returns (uint256, uint256);

    function skim(address _to) external;

    function sync() external;

    function claimFees() external returns (uint256[] memory _adminFees);
}

interface IStablePair is IPair {
    function lpToken() external view returns (address);

    function calculateTokenAmount(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bool _deposit
    ) external view returns (uint256);

    function calculateRemoveLiquidityOneToken(address _token, uint256 _liquidity) external view returns (uint256);

    function calculateRemoveLiquidity(
        address[] calldata _tokens,
        uint256 _amount
    ) external view returns (uint256[] memory);

    function addLiquidity(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        uint256 _minToMint,
        address _receiver,
        uint256 _deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 _amount,
        address[] calldata _tokens,
        uint256[] calldata _minAmounts,
        address _receiver,
        uint256 _deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 _tokenAmount,
        address _token,
        uint256 _minAmount,
        address _receiver,
        uint256 _deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        uint256 _maxBurnAmount,
        address _receiver,
        uint256 _deadline
    ) external returns (uint256);

    function swap(
        address _tokenFrom,
        address _tokenTo,
        uint256 _dx,
        uint256 _minDy,
        address _receiver,
        uint256 _deadline
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPairERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IPairFactory {
    function allPairsLength() external view returns (uint256);

    function isPair(address _pair) external view returns (bool);

    function manager() external view returns (address);

    function getPairAddress(address[] memory _tokens, uint8 _type) external view returns (address);

    function pairTypeValues() external view returns (address[] memory);

    function atPairType(uint256 _index) external view returns (address);

    function createPair(address[] memory _tokens, uint8 _pairType, bytes memory _data) external returns (address _pair);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../interface/IPairERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title PairERC20
 * @dev Abstract contract that implements the IPairERC20 interface and provides basic ERC20 functionality.
 */
abstract contract PairERC20 is IPairERC20 {
    using SafeMath for uint256;

    string public override name;
    string public override symbol;
    uint8 public constant override decimals = 18;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;

    // keccak256("Permit(address owner,address spender,uint256 chainId, uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH =
        0x576144ed657c8304561e56ca632e17751956250114636e8c01f64a7f2c6d98cf;

    mapping(address => uint256) public override nonces;

    /**
     * @dev Initializes the contract by setting the name and symbol of the token, as well as the domain separator for the permit function.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     */
    function _initialize(string memory _name, string memory _symbol) internal {
        name = _name;
        symbol = _symbol;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                _getChainId(),
                address(this)
            )
        );
    }

    function _getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    /**
     * @dev Mints new tokens and adds them to the total supply.
     * @param to The address to which the new tokens will be minted.
     * @param value The amount of tokens to be minted.
     */
    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    /**
     * @dev Burns tokens and removes them from the total supply.
     * @param from The address from which the tokens will be burned.
     * @param value The amount of tokens to be burned.
     */
    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    /**
     * @dev Approves a spender to transfer tokens on behalf of the owner.
     * @param owner The address of the owner of the tokens.
     * @param spender The address of the spender to be approved.
     * @param value The amount of tokens to be approved for transfer.
     */
    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Transfers tokens from one address to another.
     * @param from The address from which the tokens will be transferred.
     * @param to The address to which the tokens will be transferred.
     * @param value The amount of tokens to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal virtual {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Approves a spender to transfer tokens on behalf of the owner.
     * @param spender The address of the spender to be approved.
     * @param value The amount of tokens to be approved for transfer.
     * @return A boolean indicating whether the approval was successful or not.
     */
    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfers tokens from the caller's address to another address.
     * @param to The address to which the tokens will be transferred.
     * @param value The amount of tokens to be transferred.
     * @return A boolean indicating whether the transfer was successful or not.
     */
    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Transfers tokens from one address to another, on behalf of the owner.
     * @param from The address from which the tokens will be transferred.
     * @param to The address to which the tokens will be transferred.
     * @param value The amount of tokens to be transferred.
     * @return A boolean indicating whether the transfer was successful or not.
     */
    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Approves a spender to transfer tokens on behalf of the owner, using a permit signature.
     * @param owner The address of the owner of the tokens.
     * @param spender The address of the spender to be approved.
     * @param value The amount of tokens to be approved for transfer.
     * @param deadline The deadline by which the permit must be used.
     * @param v The recovery byte of the permit signature.
     * @param r The R component of the permit signature.
     * @param s The S component of the permit signature.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "PairERC20: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, _getChainId(), value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "PairERC20: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./utils/SwapUtils.sol";
import "./utils/AmplificationUtils.sol";
import "./utils/ERC20Call.sol";
import "./interface/IPairERC20.sol";
import "./interface/IPairFactory.sol";
import "./interface/IPair.sol";

/**
 * @title Swap - A StableSwap implementation in solidity.
 * @notice This contract is responsible for custody of closely pegged assets (eg. group of stablecoins)
 * and automatic market making system. Users become an LP (Liquidity Provider) by depositing their tokens
 * in desired ratios for an exchange of the pool token that represents their share of the pool.
 * Users can burn pool tokens and withdraw their share of token(s).
 *
 * Each time a swap between the pooled tokens happens, a set fee incurs which effectively gets
 * distributed to the LPs.
 *
 * In case of emergencies, admin can pause additional deposits, swaps, or single-asset withdraws - which
 * stops the ratio of the tokens in the pool from changing.
 * Users can always withdraw their tokens via multi-asset withdraws.
 *
 * @dev Most of the logic is stored as a library `SwapUtils` for the sake of reducing contract's
 * deployment size.
 */
contract StablePair is Initializable, IStablePair {
    using SwapUtils for SwapUtils.Swap;
    using AmplificationUtils for SwapUtils.Swap;
    using ERC20Call for address;

    // The type of the pair
    uint8 public constant override PAIR_TYPE = 3;
    // Whether the pair is authorized
    bool public constant override AUTH = true;

    // The factory that created this pair
    address public factory;

    // A lock to prevent reentrancy
    uint256 private unlocked_;

    // Struct storing data responsible for automatic market maker functionalities. In order to
    // access this data, this contract uses SwapUtils library. For more details, see SwapUtils.sol
    SwapUtils.Swap public swapStorage;

    // Maps token address to an index in the pool. Used to prevent duplicate tokens in the pool.
    // getTokenIndex function also relies on this mapping to retrieve token index.
    mapping(address => uint8) internal tokenIndexes_;

    /*** EVENTS ***/

    // events replicated from SwapUtils to make the ABI easier for dumb
    // clients
    /**
     * @dev Event emitted when a token swap occurs.
     * @param buyer The address of the buyer.
     * @param tokensSold The amount of tokens sold.
     * @param tokensBought The amount of tokens bought.
     * @param soldId The ID of the sold token.
     * @param boughtId The ID of the bought token.
     */
    event TokenSwap(address indexed buyer, uint256 tokensSold, uint256 tokensBought, uint128 soldId, uint128 boughtId);

    /**
     * @dev Event emitted when liquidity is added to the pool.
     * @param provider The address of the liquidity provider.
     * @param tokenAmounts The amounts of tokens added.
     * @param fees The fees paid for adding liquidity.
     * @param invariant The invariant of the pool.
     * @param lpTokenSupply The total supply of LP tokens.
     */
    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );

    /**
     * @dev Event emitted when liquidity is removed from the pool.
     * @param provider The address of the liquidity provider.
     * @param tokenAmounts The amounts of tokens removed.
     * @param lpTokenSupply The total supply of LP tokens.
     */
    event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts, uint256 lpTokenSupply);

    /**
     * @dev Event emitted when a single asset is removed from the pool.
     * @param provider The address of the liquidity provider.
     * @param lpTokenAmount The amount of LP tokens burned.
     * @param lpTokenSupply The total supply of LP tokens.
     * @param boughtId The ID of the bought token.
     * @param tokensBought The amount of tokens bought.
     */
    event RemoveLiquidityOne(
        address indexed provider,
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint256 boughtId,
        uint256 tokensBought
    );

    /**
     * @dev Event emitted when liquidity is removed from the pool in an imbalanced way.
     * @param provider The address of the liquidity provider.
     * @param tokenAmounts The amounts of tokens removed.
     * @param fees The fees paid for removing liquidity.
     * @param invariant The invariant of the pool.
     * @param lpTokenSupply The total supply of LP tokens.
     */
    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );

    /**
     * @dev Event emitted when the swap fees are updated.
     * @param tokens The tokens in the pool.
     * @param swapFees The new swap fees.
     */
    event SwapFee(address[] tokens, uint256[] swapFees);

    /**
     * @dev Event emitted when the admin fee is updated.
     * @param newAdminFee The new admin fee.
     */
    event NewAdminFee(uint256 newAdminFee);

    /**
     * @dev Event emitted when the swap fee is updated.
     * @param newSwapFee The new swap fee.
     */
    event NewSwapFee(uint256 newSwapFee);

    /**
     * @dev Event emitted when the withdraw fee is updated.
     * @param newWithdrawFee The new withdraw fee.
     */
    event NewWithdrawFee(uint256 newWithdrawFee);

    /**
     * @dev Event emitted when the amplification coefficient is ramped.
     * @param oldA The old amplification coefficient.
     * @param newA The new amplification coefficient.
     * @param initialTime The initial time.
     * @param futureTime The future time.
     */
    event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);

    /**
     * @dev Event emitted when the amplification coefficient ramp is stopped.
     * @param currentA The current amplification coefficient.
     * @param time The time.
     */
    event StopRampA(uint256 currentA, uint256 time);

    /**
     * @dev Initializes this StablePair contract with the given parameters.
     * @param _tokens an array of ERC20s this pool will accept
     * @param _data encoded parameters for the StablePair contract
     */
    function initialize(address[] calldata _tokens, bytes calldata _data) external override initializer {
        factory = msg.sender;
        unlocked_ = 1;
        string memory _lpTokenName = "dForce AMM Stable - ";
        string memory _lpTokenSymbol = "sAMM-";
        string memory _separator = "-";
        uint8[] memory _decimals = new uint8[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _decimals[i] = IPairERC20(_tokens[i]).decimals();
            string memory _tokenSymbol = _tokens[i].callSymbol();
            if (i == _tokens.length - 1) _separator = "";
            _lpTokenName = string(abi.encodePacked(_lpTokenName, _tokenSymbol, _separator));
            _lpTokenSymbol = string(abi.encodePacked(_lpTokenSymbol, _tokenSymbol, _separator));
        }

        (uint256 _swapFee, uint256 _adminFeeRate, uint256 _a, address _lpTokenTargetAddress) = abi.decode(
            _data,
            (uint256, uint256, uint256, address)
        );
        __SwapV2_init(
            _tokens,
            _decimals,
            _lpTokenName,
            _lpTokenSymbol,
            _a,
            _swapFee,
            _adminFeeRate,
            _lpTokenTargetAddress
        );
    }

    /**
     * @notice Initializes this Swap contract with the given parameters.
     * This will also clone a LPToken contract that represents users'
     * LP positions. The owner of LPToken will be this contract - which means
     * only this contract is allowed to mint/burn tokens.
     *
     * @param _pooledTokens an array of ERC20s this pool will accept
     * @param _decimals the decimals to use for each pooled token,
     * eg 8 for WBTC. Cannot be larger than POOL_PRECISION_DECIMALS
     * @param _lpTokenName the long-form name of the token to be deployed
     * @param _lpTokenSymbol the short symbol for the token to be deployed
     * @param _a the amplification coefficient * n * (n - 1). See the
     * StableSwap paper for details
     * @param _fee default swap fee to be initialized with
     * @param _adminFee default adminFee to be initialized with
     * @param _lpTokenTargetAddress the address of an existing LPToken contract to use as a target
     */
    function __SwapV2_init(
        address[] memory _pooledTokens,
        uint8[] memory _decimals,
        string memory _lpTokenName,
        string memory _lpTokenSymbol,
        uint256 _a,
        uint256 _fee,
        uint256 _adminFee,
        address _lpTokenTargetAddress
    ) internal virtual {
        // Check _pooledTokens and precisions parameter
        require(_pooledTokens.length > 1, "StablePair: _pooledTokens.length <= 1");
        require(_pooledTokens.length <= 32, "StablePair: _pooledTokens.length > 32");
        require(_pooledTokens.length == _decimals.length, "StablePair: _pooledTokens decimals mismatch");

        uint256[] memory _precisionMultipliers = new uint256[](_decimals.length);
        IERC20[] memory _poolTokens = new IERC20[](_decimals.length);

        for (uint8 i = 0; i < _pooledTokens.length; i++) {
            if (i > 0) {
                // Check if index is already used. Check if 0th element is a duplicate.
                require(
                    tokenIndexes_[_pooledTokens[i]] == 0 && _pooledTokens[0] != _pooledTokens[i],
                    "StablePair: Duplicate tokens"
                );
            }
            require(
                _pooledTokens[i] != address(0) && _pooledTokens[i] != address(this),
                "StablePair: The 0 address isn't an ERC-20"
            );
            require(_decimals[i] <= SwapUtils.POOL_PRECISION_DECIMALS, "StablePair: Token decimals exceeds max");
            _precisionMultipliers[i] = 10 ** (uint256(SwapUtils.POOL_PRECISION_DECIMALS) - uint256(_decimals[i]));
            _poolTokens[i] = IERC20(_pooledTokens[i]);
            tokenIndexes_[_pooledTokens[i]] = i;
        }

        // Check _a, _fee, _adminFee, _withdrawFee parameters
        require(_a < AmplificationUtils.MAX_A, "StablePair: _a exceeds maximum");
        require(_fee < SwapUtils.MAX_SWAP_FEE, "StablePair: _fee exceeds maximum");
        require(_adminFee < SwapUtils.MAX_ADMIN_FEE, "StablePair: _adminFee exceeds maximum");

        // Clone and initialize a LPToken contract
        LPToken _lpToken = LPToken(Clones.clone(_lpTokenTargetAddress));
        require(_lpToken.initialize(_lpTokenName, _lpTokenSymbol), "StablePair: could not init lpToken clone");

        // Initialize swapStorage struct
        swapStorage.lpToken = _lpToken;
        swapStorage.pooledTokens = _poolTokens;
        swapStorage.tokenPrecisionMultipliers = _precisionMultipliers;
        swapStorage.balances = new uint256[](_pooledTokens.length);
        swapStorage.initialA = _a * AmplificationUtils.A_PRECISION;
        swapStorage.futureA = _a * AmplificationUtils.A_PRECISION;
        // swapStorage.initialATime = 0;
        // swapStorage.futureATime = 0;
        swapStorage.swapFee = _fee;
        swapStorage.adminFee = _adminFee;
    }

    /*** MODIFIERS ***/

    /**
     * @notice Modifier to check sender against factory manager.
     */
    modifier onlyManager() {
        require(IPairFactory(factory).manager() == msg.sender, "StablePair: : not manager");
        _;
    }

    /**
     * @notice contract function lock modifier.
     */
    modifier lock() {
        require(unlocked_ == 1, "StablePair: LOCKED");
        unlocked_ = 0;
        _;
        unlocked_ = 1;
    }

    /**
     * @notice Modifier to check _deadline against current timestamp
     * @param _deadline latest timestamp to accept this transaction
     */
    modifier deadlineCheck(uint256 _deadline) {
        require(block.timestamp <= _deadline, "StablePair: Deadline not met");
        _;
    }

    /*** VIEW FUNCTIONS ***/

    /**
     * @notice Return A, the amplification coefficient * n * (n - 1)
     * @dev See the StableSwap paper for details
     * @return A parameter
     */
    function getA() external view virtual returns (uint256) {
        return swapStorage.getA();
    }

    /**
     * @notice Return A in its raw precision form
     * @dev See the StableSwap paper for details
     * @return A parameter in its raw precision form
     */
    function getAPrecise() external view virtual returns (uint256) {
        return swapStorage.getAPrecise();
    }

    /**
     * @notice Return address of the pooled token at given index. Reverts if _tokenIndex is out of range.
     * @param _index the index of the token
     * @return address of the token at given index
     */
    function getToken(uint8 _index) public view virtual returns (address) {
        require(_index < swapStorage.pooledTokens.length, "StablePair: Out of range");
        return address(swapStorage.pooledTokens[_index]);
    }

    /**
     * @notice Query all token addresses in pair.
     * @return _tokens all token addresses
     */
    function tokens() external view override returns (address[] memory _tokens) {
        _tokens = new address[](swapStorage.pooledTokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) _tokens[i] = address(swapStorage.pooledTokens[i]);
    }

    /**
     * @notice Query lpToken addresse.
     * @return lpToken addresse
     */
    function lpToken() external view override returns (address) {
        return address(swapStorage.lpToken);
    }

    /**
     * @notice Return the index of the given token address. Reverts if no matching
     * token is found.
     * @param _tokenAddress address of the token
     * @return the index of the given token address
     */
    function getTokenIndex(address _tokenAddress) public view virtual returns (uint8) {
        uint8 _index = tokenIndexes_[_tokenAddress];
        require(getToken(_index) == _tokenAddress, "StablePair: Token does not exist");
        return _index;
    }

    /**
     * @notice Return current balance of the pooled token at given index
     * @param _index the index of the token
     * @return current balance of the pooled token at given index with token's native precision
     */
    function getTokenBalance(uint8 _index) external view virtual returns (uint256) {
        require(_index < swapStorage.pooledTokens.length, "StablePair: Index out of range");
        return swapStorage.balances[_index];
    }

    /**
     * @notice Return current balances of the pooled tokens
     * @return current balances of the pooled tokens
     */
    function getTokenBalances() external view virtual returns (uint256[] memory) {
        return swapStorage.balances;
    }

    /**
     * @notice Get the virtual price, to help calculate profit
     * @return the virtual price, scaled to the POOL_PRECISION_DECIMALS
     */
    function getVirtualPrice() external view virtual returns (uint256) {
        return swapStorage.getVirtualPrice();
    }

    /**
     * @notice Calculate amount of tokens you receive on swap
     * @param _tokenFrom the token address the user wants to sell
     * @param _tokenTo the token address the user wants to buy
     * @param _dx the amount of tokens the user wants to sell. If the token charges
     * a fee on transfers, use the amount that gets transferred after the fee.
     * @return amount of tokens the user will receive
     */
    function getAmountOut(address _tokenFrom, address _tokenTo, uint256 _dx) external view override returns (uint256) {
        return swapStorage.calculateSwap(tokenIndexes_[_tokenFrom], tokenIndexes_[_tokenTo], _dx);
    }

    /**
     * @notice Convert the array index, according to tokenIndexes_.
     * @param _tokens an array of all token addresses for the pair,
     * @param _amounts an array of token amounts, corresponding to param _tokens.
     * @return _newAmounts amount of tokens after conversion
     */
    function _convertIndex(
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) internal view returns (uint256[] memory _newAmounts) {
        _newAmounts = new uint256[](_amounts.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _newAmounts[getTokenIndex(_tokens[i])] = _amounts[i];
        }
    }

    /**
     * @notice A simple method to calculate prices from deposits or
     * withdrawals, excluding fees but including slippage. This is
     * helpful as an input into the various "min" parameters on calls
     * to fight front-running
     *
     * @dev This shouldn't be used outside frontends for user estimates.
     *
     * @param _tokens an array of all token addresses for the pair,
     * @param _amounts an array of token amounts to deposit or withdrawal,
     * corresponding to param _tokens. The amount should be in each
     * pooled token's native precision. If a token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @param _deposit whether this is a deposit or a withdrawal
     * @return token amount the user will receive
     */
    function calculateTokenAmount(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        bool _deposit
    ) external view virtual override returns (uint256) {
        return swapStorage.calculateTokenAmount(_convertIndex(_tokens, _amounts), _deposit);
    }

    /**
     * @notice A simple method to calculate amount of each underlying
     * tokens that is returned upon burning given amount of LP tokens
     * @param _tokens token address list
     * @param _amount the amount of LP tokens that would be burned on withdrawal
     * @return array of token balances that the user will receive
     */
    function calculateRemoveLiquidity(
        address[] calldata _tokens,
        uint256 _amount
    ) external view virtual override returns (uint256[] memory) {
        uint256[] memory _amounts = swapStorage.calculateRemoveLiquidity(_amount);
        uint256[] memory _actualAmounts = new uint256[](_amounts.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _actualAmounts[i] = _amounts[getTokenIndex(_tokens[i])];
        }
        return _actualAmounts;
    }

    /**
     * @notice Calculate the amount of underlying token available to withdraw
     * when withdrawing via only single token
     * @param _token address of tokens that will be withdrawn
     * @param _tokenAmount the amount of LP token to burn
     * @return calculated amount of underlying token
     * available to withdraw
     */
    function calculateRemoveLiquidityOneToken(
        address _token,
        uint256 _tokenAmount
    ) external view virtual override returns (uint256) {
        return swapStorage.calculateWithdrawOneToken(_tokenAmount, tokenIndexes_[_token]);
    }

    /**
     * @notice This function reads the accumulated amount of admin fees of the token with given index
     * @param _index Index of the pooled token
     * @return admin's token balance in the token's precision
     */
    function getAdminBalance(uint256 _index) external view virtual returns (uint256) {
        return swapStorage.getAdminBalance(_index);
    }

    /*** STATE MODIFYING FUNCTIONS ***/

    /**
     * @notice Calculate amount of tokens you receive on swap
     * @param _tokenFrom the token address the user wants to sell
     * @param _tokenTo the token address the user wants to buy
     * @param _dx the amount of tokens the user wants to swap from
     * @param _minDy the min amount the user would like to receive, or revert.
     * @param _receiver recipient address
     * @param _deadline latest timestamp to accept this transaction
     */
    function swap(
        address _tokenFrom,
        address _tokenTo,
        uint256 _dx,
        uint256 _minDy,
        address _receiver,
        uint256 _deadline
    ) external override lock deadlineCheck(_deadline) returns (uint256) {
        return swapStorage.swap(tokenIndexes_[_tokenFrom], tokenIndexes_[_tokenTo], _dx, _minDy, _receiver);
    }

    /**
     * @notice Add liquidity to the pool with the given amounts of tokens
     * @param _tokens token address list
     * @param _amounts the amounts of each token to add, in their native precision,corresponding to param _tokens
     * @param _minToMint the minimum LP tokens adding this amount of liquidity
     * should mint, otherwise revert. Handy for front-running mitigation
     * @param _receiver recipient address
     * @param _deadline latest timestamp to accept this transaction
     * @return amount of LP token user minted and received
     */
    function addLiquidity(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        uint256 _minToMint,
        address _receiver,
        uint256 _deadline
    ) external override lock deadlineCheck(_deadline) returns (uint256) {
        return swapStorage.addLiquidity(_convertIndex(_tokens, _amounts), _minToMint, _receiver);
    }

    /**
     * @notice Burn LP tokens to remove liquidity from the pool. Withdraw fee that decays linearly
     * over period of 4 weeks since last deposit will apply.
     * @dev Liquidity can always be removed, even when the pool is paused.
     * @param _amount the amount of LP tokens to burn
     * @param _tokens token address list
     * @param _minAmounts the minimum amounts of each token in the pool
     *        acceptable for this burn. Useful as a front-running mitigation
     * @param _receiver recipient address
     * @param _deadline latest timestamp to accept this transaction
     * @return amounts of tokens user received
     */
    function removeLiquidity(
        uint256 _amount,
        address[] calldata _tokens,
        uint256[] calldata _minAmounts,
        address _receiver,
        uint256 _deadline
    ) external virtual override lock deadlineCheck(_deadline) returns (uint256[] memory) {
        return swapStorage.removeLiquidity(_amount, _convertIndex(_tokens, _minAmounts), _receiver);
    }

    /**
     * @notice Remove liquidity from the pool all in one token. Withdraw fee that decays linearly
     * over period of 4 weeks since last deposit will apply.
     * @param _tokenAmount the amount of the token you want to receive
     * @param _token address of the token you want to receive
     * @param _minAmount the minimum amount to withdraw, otherwise revert
     * @param _receiver recipient address
     * @param _deadline latest timestamp to accept this transaction
     * @return amount of chosen token user received
     */
    function removeLiquidityOneToken(
        uint256 _tokenAmount,
        address _token,
        uint256 _minAmount,
        address _receiver,
        uint256 _deadline
    ) external override lock deadlineCheck(_deadline) returns (uint256) {
        return swapStorage.removeLiquidityOneToken(_tokenAmount, tokenIndexes_[_token], _minAmount, _receiver);
    }

    /**
     * @notice Remove liquidity from the pool, weighted differently than the
     * pool's current balances. Withdraw fee that decays linearly
     * over period of 4 weeks since last deposit will apply.
     * @param _tokens token address list
     * @param _amounts how much of each token to withdraw
     * @param _maxBurnAmount the max LP token provider is willing to pay to
     * remove liquidity. Useful as a front-running mitigation.
     * @param _receiver recipient address
     * @param _deadline latest timestamp to accept this transaction
     * @return amount of LP tokens burned
     */
    function removeLiquidityImbalance(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        uint256 _maxBurnAmount,
        address _receiver,
        uint256 _deadline
    ) external override lock deadlineCheck(_deadline) returns (uint256) {
        return swapStorage.removeLiquidityImbalance(_convertIndex(_tokens, _amounts), _maxBurnAmount, _receiver);
    }

    /*** ADMIN FUNCTIONS ***/

    /**
     * @notice Withdraw all admin fees to the contract factory manager
     */
    function claimFees() external returns (uint256[] memory) {
        return swapStorage.withdrawAdminFees(IPairFactory(factory).manager());
    }

    /**
     * @notice Update the admin fee. Admin fee takes portion of the swap fee.
     * @param _newAdminFee new admin fee to be applied on future transactions
     */
    function setAdminFeeRate(uint256 _newAdminFee) external onlyManager {
        swapStorage.setAdminFee(_newAdminFee);
    }

    /**
     * @notice Update the swap fee to be applied on swaps
     * @param _newSwapFee new swap fee to be applied on future transactions
     */
    function setSwapFee(uint256 _newSwapFee) external onlyManager {
        swapStorage.setSwapFee(_newSwapFee);
    }

    /**
     * @notice Start ramping up or down A parameter towards given futureA and futureTime
     * Checks if the change is too rapid, and commits the new A value only when it falls under
     * the limit range.
     * @param _futureA the new A to ramp towards
     * @param _futureTime timestamp when the new A should be reached
     */
    function rampA(uint256 _futureA, uint256 _futureTime) external onlyManager {
        swapStorage.rampA(_futureA, _futureTime);
    }

    /**
     * @notice Stop ramping A immediately. Reverts if ramp A is already stopped.
     */
    function stopRampA() external onlyManager {
        swapStorage.stopRampA();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./SwapUtils.sol";

/**
 * @title AmplificationUtils library
 * @notice A library to calculate and ramp the A parameter of a given `SwapUtils.Swap` struct.
 * This library assumes the struct is fully validated.
 */
library AmplificationUtils {
    using SafeMath for uint256;

    event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);
    event StopRampA(uint256 currentA, uint256 time);

    // Constant values used in ramping A calculations
    uint256 public constant A_PRECISION = 100;
    uint256 public constant MAX_A = 10 ** 6;
    uint256 private constant MAX_A_CHANGE = 2;
    uint256 private constant MIN_RAMP_TIME = 14 days;

    /**
     * @notice Return A, the amplification coefficient * n * (n - 1)
     * @dev See the StableSwap paper for details
     * @param self Swap struct to read from
     * @return A parameter
     */
    function getA(SwapUtils.Swap storage self) external view returns (uint256) {
        return _getAPrecise(self).div(A_PRECISION);
    }

    /**
     * @notice Return A in its raw precision
     * @dev See the StableSwap paper for details
     * @param self Swap struct to read from
     * @return A parameter in its raw precision form
     */
    function getAPrecise(SwapUtils.Swap storage self) external view returns (uint256) {
        return _getAPrecise(self);
    }

    /**
     * @notice Return A in its raw precision
     * @dev See the StableSwap paper for details
     * @param self Swap struct to read from
     * @return A parameter in its raw precision form
     */
    function _getAPrecise(SwapUtils.Swap storage self) internal view returns (uint256) {
        uint256 t1 = self.futureATime; // time when ramp is finished
        uint256 a1 = self.futureA; // final A value when ramp is finished

        if (block.timestamp < t1) {
            uint256 t0 = self.initialATime; // time when ramp is started
            uint256 a0 = self.initialA; // initial A value when ramp is started
            if (a1 > a0) {
                // a0 + (a1 - a0) * (block.timestamp - t0) / (t1 - t0)
                return a0.add(a1.sub(a0).mul(block.timestamp.sub(t0)).div(t1.sub(t0)));
            } else {
                // a0 - (a0 - a1) * (block.timestamp - t0) / (t1 - t0)
                return a0.sub(a0.sub(a1).mul(block.timestamp.sub(t0)).div(t1.sub(t0)));
            }
        } else {
            return a1;
        }
    }

    /**
     * @notice Start ramping up or down A parameter towards given futureA_ and futureTime_
     * Checks if the change is too rapid, and commits the new A value only when it falls under
     * the limit range.
     * @param self Swap struct to update
     * @param futureA_ the new A to ramp towards
     * @param futureTime_ timestamp when the new A should be reached
     */
    function rampA(SwapUtils.Swap storage self, uint256 futureA_, uint256 futureTime_) external {
        require(block.timestamp >= self.initialATime.add(1 days), "Wait 1 day before starting ramp");
        require(futureTime_ >= block.timestamp.add(MIN_RAMP_TIME), "Insufficient ramp time");
        require(futureA_ > 0 && futureA_ < MAX_A, "futureA_ must be > 0 and < MAX_A");

        uint256 initialAPrecise = _getAPrecise(self);
        uint256 futureAPrecise = futureA_.mul(A_PRECISION);

        if (futureAPrecise < initialAPrecise) {
            require(futureAPrecise.mul(MAX_A_CHANGE) >= initialAPrecise, "futureA_ is too small");
        } else {
            require(futureAPrecise <= initialAPrecise.mul(MAX_A_CHANGE), "futureA_ is too large");
        }

        self.initialA = initialAPrecise;
        self.futureA = futureAPrecise;
        self.initialATime = block.timestamp;
        self.futureATime = futureTime_;

        emit RampA(initialAPrecise, futureAPrecise, block.timestamp, futureTime_);
    }

    /**
     * @notice Stops ramping A immediately. Once this function is called, rampA()
     * cannot be called for another 24 hours
     * @param self Swap struct to update
     */
    function stopRampA(SwapUtils.Swap storage self) external {
        require(self.futureATime > block.timestamp, "Ramp is already stopped");

        uint256 currentA = _getAPrecise(self);
        self.initialA = currentA;
        self.futureA = currentA;
        self.initialATime = block.timestamp;
        self.futureATime = block.timestamp;

        emit StopRampA(currentA, block.timestamp);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library ERC20Call {
    /**
     * @dev Get the symbol of the ERC20 token
     * @param _token The address of the ERC20 token
     * @return _symbol The symbol of the ERC20 token
     */
    function callSymbol(address _token) internal view returns (string memory _symbol) {
        if (_token != address(0)) {
            (bool _success, bytes memory _res) = _token.staticcall(abi.encodeWithSignature("symbol()"));
            if (_success)
                _symbol = _res.length == 32 ? bytes32ToString(abi.decode(_res, (bytes32))) : abi.decode(_res, (string));
        }
    }

    /**
     * @dev Convert bytes32 to string
     * @param _bytes32 The bytes32 to be converted
     * @return _result The converted string
     */
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory _result) {
        uint8 _length = 0;
        while (_bytes32[_length] != 0 && _length < 32) {
            _length++;
        }
        assembly {
            _result := mload(0x40)
            // new "memory end" including padding (the string isn't larger than 32 bytes)
            mstore(0x40, add(_result, 0x40))
            // store length in memory
            mstore(_result, _length)
            // write actual data
            mstore(add(_result, 0x20), _bytes32)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../lib/PairERC20.sol";

/**
 * @title Liquidity Provider Token
 * @notice This token is an ERC20 detailed token with added capability to be minted by the owner.
 * It is used to represent user's shares when providing liquidity to swap contracts.
 * @dev Only Swap contracts should initialize and own LPToken contracts.
 */
contract LPToken is OwnableUpgradeable, PairERC20 {
    /**
     * @notice Initializes this LPToken contract with the given name and symbol
     * @dev The caller of this function will become the owner. A Swap contract should call this
     * in its initializer function.
     * @param name name of this token
     * @param symbol symbol of this token
     */
    function initialize(string memory name, string memory symbol) external initializer returns (bool) {
        __Context_init_unchained();
        __Ownable_init_unchained();
        _initialize(name, symbol);
        return true;
    }

    /**
     * @dev Modifier to check if the recipient is not the contract itself
     */
    modifier addressCheck(address recipient) {
        require(recipient != address(this), "LPToken: cannot send to itself");
        _;
    }

    /**
     * @notice Mints the given amount of LPToken to the recipient.
     * @dev only owner can call this mint function
     * @param recipient address of account to receive the tokens
     * @param amount amount of tokens to mint
     */
    function mint(address recipient, uint256 amount) external onlyOwner addressCheck(recipient) {
        require(amount != 0, "LPToken: cannot mint 0");
        _mint(recipient, amount);
    }

    /**
     * @dev Overrides the _transfer function to check if the recipient is not the contract itself
     */
    function _transfer(address from, address to, uint256 value) internal override addressCheck(to) {
        super._transfer(from, to, value);
    }

    /**
     * @notice Burns the given amount of LPToken from the specified account
     * @param from address of account to burn tokens from
     * @param value amount of tokens to burn
     */
    function burnFrom(address from, uint256 value) external {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _burn(from, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @title MathUtils library
 * @notice A library to be used in conjunction with SafeMath. Contains functions for calculating
 * differences between two uint256.
 */
library MathUtils {
    /**
     * @notice Compares a and b and returns true if the difference between a and b
     *         is less than 1 or equal to each other.
     * @param a uint256 to compare with
     * @param b uint256 to compare with
     * @return True if the difference between a and b is less than 1 or equal,
     *         otherwise return false
     */
    function within1(uint256 a, uint256 b) internal pure returns (bool) {
        return (difference(a, b) <= 1);
    }

    /**
     * @notice Calculates absolute difference between a and b
     * @param a uint256 to compare with
     * @param b uint256 to compare with
     * @return Difference between a and b
     */
    function difference(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a - b;
        }
        return b - a;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./AmplificationUtils.sol";
import "./LPToken.sol";
import "./MathUtils.sol";

/**
 * @title SwapUtils library
 * @notice A library to be used within Swap.sol. Contains functions responsible for custody and AMM functionalities.
 * @dev Contracts relying on this library must initialize SwapUtils.Swap struct then use this library
 * for SwapUtils.Swap struct. Note that this library contains both functions called by users and admins.
 * Admin functions should be protected within contracts using this library.
 */
library SwapUtils {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using MathUtils for uint256;

    /*** EVENTS ***/

    event TokenSwap(address indexed buyer, uint256 tokensSold, uint256 tokensBought, uint128 soldId, uint128 boughtId);
    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event RemoveLiquidity(address indexed provider, uint256[] tokenAmounts, uint256 lpTokenSupply);
    event RemoveLiquidityOne(
        address indexed provider,
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint256 boughtId,
        uint256 tokensBought
    );
    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );

    event SwapFee(address[] tokens, uint256[] swapFees);
    event NewAdminFee(uint256 newAdminFee);
    event NewSwapFee(uint256 newSwapFee);

    struct Swap {
        // variables around the ramp management of A,
        // the amplification coefficient * n * (n - 1)
        // see https://www.curve.fi/stableswap-paper.pdf for details
        uint256 initialA;
        uint256 futureA;
        uint256 initialATime;
        uint256 futureATime;
        // fee calculation
        uint256 swapFee;
        uint256 adminFee;
        LPToken lpToken;
        // contract references for all tokens being pooled
        IERC20[] pooledTokens;
        // multipliers for each pooled token's precision to get to POOL_PRECISION_DECIMALS
        // for example, TBTC has 18 decimals, so the multiplier should be 1. WBTC
        // has 8, so the multiplier should be 10 ** 18 / 10 ** 8 => 10 ** 10
        uint256[] tokenPrecisionMultipliers;
        // the pool balance of each token, in the token's precision
        // the contract's actual token balance might differ
        uint256[] balances;
    }

    // Struct storing variables used in calculations in the
    // calculateWithdrawOneTokenDY function to avoid stack too deep errors
    struct CalculateWithdrawOneTokenDYInfo {
        uint256 d0;
        uint256 d1;
        uint256 newY;
        uint256 feePerToken;
        uint256 preciseA;
    }

    // Struct storing variables used in calculations in the
    // {add,remove}Liquidity functions to avoid stack too deep errors
    struct ManageLiquidityInfo {
        uint256 d0;
        uint256 d1;
        uint256 d2;
        uint256 preciseA;
        LPToken lpToken;
        uint256 totalSupply;
        uint256[] balances;
        uint256[] multipliers;
    }

    struct SwapFeeInfo {
        uint256 adminFeeRate;
        uint256 adminFee;
        address[] tokens;
        uint256[] swapFees;
    }

    // the precision all pools tokens will be converted to
    uint8 public constant POOL_PRECISION_DECIMALS = 18;

    // the denominator used to calculate admin and LP fees. For example, an
    // LP fee might be something like tradeAmount.mul(fee).div(FEE_DENOMINATOR)
    uint256 private constant FEE_DENOMINATOR = 10 ** 10;

    // Max swap fee is 1% or 100bps of each swap
    uint256 public constant MAX_SWAP_FEE = 10 ** 8;

    // Max adminFee is 100% of the swapFee
    // adminFee does not add additional fee on top of swapFee
    // Instead it takes a certain % of the swapFee. Therefore it has no impact on the
    // users but only on the earnings of LPs
    uint256 public constant MAX_ADMIN_FEE = 10 ** 10;

    // Constant value used as max loop limit
    uint256 private constant MAX_LOOP_LIMIT = 256;

    /*** VIEW & PURE FUNCTIONS ***/

    function _getAPrecise(Swap storage self) internal view returns (uint256) {
        return AmplificationUtils._getAPrecise(self);
    }

    /**
     * @notice Calculate the dy, the amount of selected token that user receives and
     * the fee of withdrawing in one token
     * @param tokenAmount the amount to withdraw in the pool's precision
     * @param tokenIndex which token will be withdrawn
     * @param self Swap struct to read from
     * @return the amount of token user will receive
     */
    function calculateWithdrawOneToken(
        Swap storage self,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256) {
        (uint256 availableTokenAmount, ) = _calculateWithdrawOneToken(
            self,
            tokenAmount,
            tokenIndex,
            self.lpToken.totalSupply()
        );
        return availableTokenAmount;
    }

    function _calculateWithdrawOneToken(
        Swap storage self,
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 totalSupply
    ) internal view returns (uint256, uint256) {
        uint256 dy;
        uint256 newY;
        uint256 currentY;

        (dy, newY, currentY) = calculateWithdrawOneTokenDY(self, tokenIndex, tokenAmount, totalSupply);

        // dy_0 (without fees)
        // dy, dy_0 - dy

        uint256 dySwapFee = currentY.sub(newY).div(self.tokenPrecisionMultipliers[tokenIndex]).sub(dy);

        return (dy, dySwapFee);
    }

    /**
     * @notice Calculate the dy of withdrawing in one token
     * @param self Swap struct to read from
     * @param tokenIndex which token will be withdrawn
     * @param tokenAmount the amount to withdraw in the pools precision
     * @return the d and the new y after withdrawing one token
     */
    function calculateWithdrawOneTokenDY(
        Swap storage self,
        uint8 tokenIndex,
        uint256 tokenAmount,
        uint256 totalSupply
    ) internal view returns (uint256, uint256, uint256) {
        // Get the current D, then solve the stableswap invariant
        // y_i for D - tokenAmount
        uint256[] memory xp = _xp(self);

        require(tokenIndex < xp.length, "Token index out of range");

        CalculateWithdrawOneTokenDYInfo memory v = CalculateWithdrawOneTokenDYInfo(0, 0, 0, 0, 0);
        v.preciseA = _getAPrecise(self);
        v.d0 = getD(xp, v.preciseA);
        v.d1 = v.d0.sub(tokenAmount.mul(v.d0).div(totalSupply));

        require(tokenAmount <= xp[tokenIndex], "Withdraw exceeds available");

        v.newY = getYD(v.preciseA, tokenIndex, xp, v.d1);

        uint256[] memory xpReduced = new uint256[](xp.length);

        v.feePerToken = _feePerToken(self.swapFee, xp.length);
        for (uint256 i = 0; i < xp.length; i++) {
            uint256 xpi = xp[i];
            // if i == tokenIndex, dxExpected = xp[i] * d1 / d0 - newY
            // else dxExpected = xp[i] - (xp[i] * d1 / d0)
            // xpReduced[i] -= dxExpected * fee / FEE_DENOMINATOR
            xpReduced[i] = xpi.sub(
                ((i == tokenIndex) ? xpi.mul(v.d1).div(v.d0).sub(v.newY) : xpi.sub(xpi.mul(v.d1).div(v.d0)))
                    .mul(v.feePerToken)
                    .div(FEE_DENOMINATOR)
            );
        }

        uint256 dy = xpReduced[tokenIndex].sub(getYD(v.preciseA, tokenIndex, xpReduced, v.d1));
        dy = dy.sub(1).div(self.tokenPrecisionMultipliers[tokenIndex]);

        return (dy, v.newY, xp[tokenIndex]);
    }

    /**
     * @notice Calculate the price of a token in the pool with given
     * precision-adjusted balances and a particular D.
     *
     * @dev This is accomplished via solving the invariant iteratively.
     * See the StableSwap paper and Curve.fi implementation for further details.
     *
     * x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
     * x_1**2 + b*x_1 = c
     * x_1 = (x_1**2 + c) / (2*x_1 + b)
     *
     * @param a the amplification coefficient * n * (n - 1). See the StableSwap paper for details.
     * @param tokenIndex Index of token we are calculating for.
     * @param xp a precision-adjusted set of pool balances. Array should be
     * the same cardinality as the pool.
     * @param d the stableswap invariant
     * @return the price of the token, in the same precision as in xp
     */
    function getYD(uint256 a, uint8 tokenIndex, uint256[] memory xp, uint256 d) internal pure returns (uint256) {
        uint256 numTokens = xp.length;
        require(tokenIndex < numTokens, "Token not found");

        uint256 c = d;
        uint256 s;
        uint256 nA = a.mul(numTokens);

        for (uint256 i = 0; i < numTokens; i++) {
            if (i != tokenIndex) {
                s = s.add(xp[i]);
                c = c.mul(d).div(xp[i].mul(numTokens));
                // If we were to protect the division loss we would have to keep the denominator separate
                // and divide at the end. However this leads to overflow with large numTokens or/and D.
                // c = c * D * D * D * ... overflow!
            }
        }
        c = c.mul(d).mul(AmplificationUtils.A_PRECISION).div(nA.mul(numTokens));

        uint256 b = s.add(d.mul(AmplificationUtils.A_PRECISION).div(nA));
        uint256 yPrev;
        uint256 y = d;
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = y.mul(y).add(c).div(y.mul(2).add(b).sub(d));
            if (y.within1(yPrev)) {
                return y;
            }
        }
        revert("Approximation did not converge");
    }

    /**
     * @notice Get D, the StableSwap invariant, based on a set of balances and a particular A.
     * @param xp a precision-adjusted set of pool balances. Array should be the same cardinality
     * as the pool.
     * @param a the amplification coefficient * n * (n - 1) in A_PRECISION.
     * See the StableSwap paper for details
     * @return the invariant, at the precision of the pool
     */
    function getD(uint256[] memory xp, uint256 a) internal pure returns (uint256) {
        uint256 numTokens = xp.length;
        uint256 s;
        for (uint256 i = 0; i < numTokens; i++) {
            s = s.add(xp[i]);
        }
        if (s == 0) {
            return 0;
        }

        uint256 prevD;
        uint256 d = s;
        uint256 nA = a.mul(numTokens);

        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            uint256 dP = d;
            for (uint256 j = 0; j < numTokens; j++) {
                dP = dP.mul(d).div(xp[j].mul(numTokens));
                // If we were to protect the division loss we would have to keep the denominator separate
                // and divide at the end. However this leads to overflow with large numTokens or/and D.
                // dP = dP * D * D * D * ... overflow!
            }
            prevD = d;
            d = nA.mul(s).div(AmplificationUtils.A_PRECISION).add(dP.mul(numTokens)).mul(d).div(
                nA.sub(AmplificationUtils.A_PRECISION).mul(d).div(AmplificationUtils.A_PRECISION).add(
                    numTokens.add(1).mul(dP)
                )
            );
            if (d.within1(prevD)) {
                return d;
            }
        }

        // Convergence should occur in 4 loops or less. If this is reached, there may be something wrong
        // with the pool. If this were to occur repeatedly, LPs should withdraw via `removeLiquidity()`
        // function which does not rely on D.
        revert("D does not converge");
    }

    /**
     * @notice Given a set of balances and precision multipliers, return the
     * precision-adjusted balances.
     *
     * @param balances an array of token balances, in their native precisions.
     * These should generally correspond with pooled tokens.
     *
     * @param precisionMultipliers an array of multipliers, corresponding to
     * the amounts in the balances array. When multiplied together they
     * should yield amounts at the pool's precision.
     *
     * @return an array of amounts "scaled" to the pool's precision
     */
    function _xp(
        uint256[] memory balances,
        uint256[] memory precisionMultipliers
    ) internal pure returns (uint256[] memory) {
        uint256 numTokens = balances.length;
        require(numTokens == precisionMultipliers.length, "Balances must match multipliers");
        uint256[] memory xp = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            xp[i] = balances[i].mul(precisionMultipliers[i]);
        }
        return xp;
    }

    /**
     * @notice Return the precision-adjusted balances of all tokens in the pool
     * @param self Swap struct to read from
     * @return the pool balances "scaled" to the pool's precision, allowing
     * them to be more easily compared.
     */
    function _xp(Swap storage self) internal view returns (uint256[] memory) {
        return _xp(self.balances, self.tokenPrecisionMultipliers);
    }

    /**
     * @notice Get the virtual price, to help calculate profit
     * @param self Swap struct to read from
     * @return the virtual price, scaled to precision of POOL_PRECISION_DECIMALS
     */
    function getVirtualPrice(Swap storage self) external view returns (uint256) {
        uint256 d = getD(_xp(self), _getAPrecise(self));
        LPToken lpToken = self.lpToken;
        uint256 supply = lpToken.totalSupply();
        if (supply > 0) {
            return d.mul(10 ** uint256(POOL_PRECISION_DECIMALS)).div(supply);
        }
        return 0;
    }

    /**
     * @notice Calculate the new balances of the tokens given the indexes of the token
     * that is swapped from (FROM) and the token that is swapped to (TO).
     * This function is used as a helper function to calculate how much TO token
     * the user should receive on swap.
     *
     * @param preciseA precise form of amplification coefficient
     * @param tokenIndexFrom index of FROM token
     * @param tokenIndexTo index of TO token
     * @param x the new total amount of FROM token
     * @param xp balances of the tokens in the pool
     * @return the amount of TO token that should remain in the pool
     */
    function getY(
        uint256 preciseA,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 x,
        uint256[] memory xp
    ) internal pure returns (uint256) {
        uint256 numTokens = xp.length;
        require(tokenIndexFrom != tokenIndexTo, "Can't compare token to itself");
        require(tokenIndexFrom < numTokens && tokenIndexTo < numTokens, "Tokens must be in pool");

        uint256 d = getD(xp, preciseA);
        uint256 c = d;
        uint256 s;
        uint256 nA = numTokens.mul(preciseA);

        uint256 _x;
        for (uint256 i = 0; i < numTokens; i++) {
            if (i == tokenIndexFrom) {
                _x = x;
            } else if (i != tokenIndexTo) {
                _x = xp[i];
            } else {
                continue;
            }
            s = s.add(_x);
            c = c.mul(d).div(_x.mul(numTokens));
            // If we were to protect the division loss we would have to keep the denominator separate
            // and divide at the end. However this leads to overflow with large numTokens or/and D.
            // c = c * D * D * D * ... overflow!
        }
        c = c.mul(d).mul(AmplificationUtils.A_PRECISION).div(nA.mul(numTokens));
        uint256 b = s.add(d.mul(AmplificationUtils.A_PRECISION).div(nA));
        uint256 yPrev;
        uint256 y = d;

        // iterative approximation
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = y.mul(y).add(c).div(y.mul(2).add(b).sub(d));
            if (y.within1(yPrev)) {
                return y;
            }
        }
        revert("Approximation did not converge");
    }

    /**
     * @notice Externally calculates a swap between two tokens.
     * @param self Swap struct to read from
     * @param tokenIndexFrom the token to sell
     * @param tokenIndexTo the token to buy
     * @param dx the number of tokens to sell. If the token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @return dy the number of tokens the user will get
     */
    function calculateSwap(
        Swap storage self,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256 dy) {
        (dy, ) = _calculateSwap(self, tokenIndexFrom, tokenIndexTo, dx, self.balances);
    }

    /**
     * @notice Internally calculates a swap between two tokens.
     *
     * @dev The caller is expected to transfer the actual amounts (dx and dy)
     * using the token contracts.
     *
     * @param self Swap struct to read from
     * @param tokenIndexFrom the token to sell
     * @param tokenIndexTo the token to buy
     * @param dx the number of tokens to sell. If the token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @return dy the number of tokens the user will get
     * @return dyFee the associated fee
     */
    function _calculateSwap(
        Swap storage self,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256[] memory balances
    ) internal view returns (uint256 dy, uint256 dyFee) {
        uint256[] memory multipliers = self.tokenPrecisionMultipliers;
        uint256[] memory xp = _xp(balances, multipliers);
        require(tokenIndexFrom < xp.length && tokenIndexTo < xp.length, "Token index out of range");
        uint256 x = dx.mul(multipliers[tokenIndexFrom]).add(xp[tokenIndexFrom]);
        uint256 y = getY(_getAPrecise(self), tokenIndexFrom, tokenIndexTo, x, xp);
        dy = xp[tokenIndexTo].sub(y).sub(1);
        dyFee = dy.mul(self.swapFee).div(FEE_DENOMINATOR);
        dy = dy.sub(dyFee).div(multipliers[tokenIndexTo]);
    }

    /**
     * @notice A simple method to calculate amount of each underlying
     * tokens that is returned upon burning given amount of
     * LP tokens
     *
     * @param amount the amount of LP tokens that would to be burned on
     * withdrawal
     * @return array of amounts of tokens user will receive
     */
    function calculateRemoveLiquidity(Swap storage self, uint256 amount) external view returns (uint256[] memory) {
        return _calculateRemoveLiquidity(self.balances, amount, self.lpToken.totalSupply());
    }

    function _calculateRemoveLiquidity(
        uint256[] memory balances,
        uint256 amount,
        uint256 totalSupply
    ) internal pure returns (uint256[] memory) {
        require(amount <= totalSupply, "Cannot exceed total supply");

        uint256[] memory amounts = new uint256[](balances.length);

        for (uint256 i = 0; i < balances.length; i++) {
            amounts[i] = balances[i].mul(amount).div(totalSupply);
        }
        return amounts;
    }

    /**
     * @notice A simple method to calculate prices from deposits or
     * withdrawals, excluding fees but including slippage. This is
     * helpful as an input into the various "min" parameters on calls
     * to fight front-running
     *
     * @dev This shouldn't be used outside frontends for user estimates.
     *
     * @param self Swap struct to read from
     * @param amounts an array of token amounts to deposit or withdrawal,
     * corresponding to pooledTokens. The amount should be in each
     * pooled token's native precision. If a token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @param deposit whether this is a deposit or a withdrawal
     * @return if deposit was true, total amount of lp token that will be minted and if
     * deposit was false, total amount of lp token that will be burned
     */
    function calculateTokenAmount(
        Swap storage self,
        uint256[] calldata amounts,
        bool deposit
    ) external view returns (uint256) {
        if (deposit) return _calculateAddLiquidityTokenAmount(self, amounts);

        uint256 a = _getAPrecise(self);
        uint256[] memory balances = self.balances;
        uint256[] memory multipliers = self.tokenPrecisionMultipliers;

        uint256 d0 = getD(_xp(balances, multipliers), a);
        for (uint256 i = 0; i < balances.length; i++) {
            balances[i] = balances[i].sub(amounts[i], "Cannot withdraw more than available");
        }
        uint256 d1 = getD(_xp(balances, multipliers), a);
        uint256 totalSupply = self.lpToken.totalSupply();
        return d0.sub(d1).mul(totalSupply).div(d0);
    }

    /**
     * @notice A simple method to calculate prices from deposits, including fees and slippage.
     * This is helpful as an input into the various "min" parameters on calls to fight front-running
     *
     * @dev This shouldn't be used outside frontends for user estimates.
     *
     * @param self Swap struct to read from
     * @param amounts an array of token amounts to deposit,
     * corresponding to pooledTokens. The amount should be in each
     * pooled token's native precision. If a token charges a fee on transfers,
     * use the amount that gets transferred after the fee.
     * @return total amount of lp token that will be minted.
     */
    function _calculateAddLiquidityTokenAmount(
        Swap storage self,
        uint256[] memory amounts
    ) internal view returns (uint256) {
        IERC20[] memory pooledTokens = self.pooledTokens;
        require(amounts.length == pooledTokens.length, "Amounts must match pooled tokens");

        ManageLiquidityInfo memory v = ManageLiquidityInfo(
            0,
            0,
            0,
            _getAPrecise(self),
            self.lpToken,
            0,
            self.balances,
            self.tokenPrecisionMultipliers
        );
        v.totalSupply = v.lpToken.totalSupply();

        uint256[] memory newBalances = new uint256[](pooledTokens.length);
        for (uint256 i = 0; i < pooledTokens.length; i++) {
            require(v.totalSupply != 0 || amounts[i] > 0, "Must supply all tokens in pool");
            newBalances[i] = v.balances[i].add(amounts[i]);
        }

        if (v.totalSupply != 0) {
            v.d0 = getD(_xp(v.balances, v.multipliers), v.preciseA);
        }
        v.d1 = getD(_xp(newBalances, v.multipliers), v.preciseA);
        require(v.d1 > v.d0, "D should increase");

        if (v.totalSupply == 0) return v.d1;

        uint256 feePerToken = _feePerToken(self.swapFee, pooledTokens.length);
        for (uint256 i = 0; i < pooledTokens.length; i++) {
            newBalances[i] = newBalances[i].sub(
                feePerToken.mul(v.d1.mul(v.balances[i]).div(v.d0).difference(newBalances[i])).div(FEE_DENOMINATOR)
            );
        }

        v.d2 = getD(_xp(newBalances, v.multipliers), v.preciseA);
        return v.d2.sub(v.d0).mul(v.totalSupply).div(v.d0);
    }

    /**
     * @notice return accumulated amount of admin fees of the token with given index
     * @param self Swap struct to read from
     * @param index Index of the pooled token
     * @return admin balance in the token's precision
     */
    function getAdminBalance(Swap storage self, uint256 index) external view returns (uint256) {
        require(index < self.pooledTokens.length, "Token index out of range");
        return self.pooledTokens[index].balanceOf(address(this)).sub(self.balances[index]);
    }

    /**
     * @notice internal helper function to calculate fee per token multiplier used in
     * swap fee calculations
     * @param swapFee swap fee for the tokens
     * @param numTokens number of tokens pooled
     */
    function _feePerToken(uint256 swapFee, uint256 numTokens) internal pure returns (uint256) {
        return swapFee.mul(numTokens).div(numTokens.sub(1).mul(4));
    }

    /*** STATE MODIFYING FUNCTIONS ***/

    /**
     * @notice swap two tokens in the pool
     * @param self Swap struct to read from and write to
     * @param tokenIndexFrom the token the user wants to sell
     * @param tokenIndexTo the token the user wants to buy
     * @param dx the amount of tokens the user wants to sell
     * @param minDy the min amount the user would like to receive, or revert.
     * @return amount of token user received on swap
     */
    function swap(
        Swap storage self,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        address receiver
    ) external returns (uint256) {
        {
            IERC20 tokenFrom = self.pooledTokens[tokenIndexFrom];
            require(dx <= tokenFrom.balanceOf(msg.sender), "Cannot swap more than you own");
            // Transfer tokens first to see if a fee was charged on transfer
            uint256 beforeBalance = tokenFrom.balanceOf(address(this));
            tokenFrom.safeTransferFrom(msg.sender, address(this), dx);

            // Use the actual transferred amount for AMM math
            dx = tokenFrom.balanceOf(address(this)).sub(beforeBalance);
        }

        uint256 dy;
        uint256 dyFee;
        uint256[] memory balances = self.balances;
        (dy, dyFee) = _calculateSwap(self, tokenIndexFrom, tokenIndexTo, dx, balances);
        require(dy >= minDy, "Swap didn't result in min tokens");

        uint256 dyAdminFee = dyFee.mul(self.adminFee).div(FEE_DENOMINATOR).div(
            self.tokenPrecisionMultipliers[tokenIndexTo]
        );

        self.balances[tokenIndexFrom] = balances[tokenIndexFrom].add(dx);
        self.balances[tokenIndexTo] = balances[tokenIndexTo].sub(dy).sub(dyAdminFee);

        self.pooledTokens[tokenIndexTo].safeTransfer(receiver, dy);

        emit TokenSwap(receiver, dx, dy, tokenIndexFrom, tokenIndexTo);

        SwapFeeInfo memory swapFeeInfo;
        swapFeeInfo.tokens = new address[](1);
        swapFeeInfo.swapFees = new uint256[](1);
        swapFeeInfo.tokens[0] = address(self.pooledTokens[tokenIndexTo]);
        swapFeeInfo.swapFees[0] = dyFee.sub(dyAdminFee);
        emit SwapFee(swapFeeInfo.tokens, swapFeeInfo.swapFees);

        return dy;
    }

    /**
     * @notice Add liquidity to the pool
     * @param self Swap struct to read from and write to
     * @param amounts the amounts of each token to add, in their native precision
     * @param minToMint the minimum LP tokens adding this amount of liquidity
     * should mint, otherwise revert. Handy for front-running mitigation
     * allowed addresses. If the pool is not in the guarded launch phase, this parameter will be ignored.
     * @param receiver recipient address
     * @return amount of LP token user received
     */
    function addLiquidity(
        Swap storage self,
        uint256[] memory amounts,
        uint256 minToMint,
        address receiver
    ) external returns (uint256) {
        IERC20[] memory pooledTokens = self.pooledTokens;
        require(amounts.length == pooledTokens.length, "Amounts must match pooled tokens");

        // current state
        ManageLiquidityInfo memory v = ManageLiquidityInfo(
            0,
            0,
            0,
            _getAPrecise(self),
            self.lpToken,
            0,
            self.balances,
            self.tokenPrecisionMultipliers
        );
        v.totalSupply = v.lpToken.totalSupply();

        if (v.totalSupply != 0) {
            v.d0 = getD(_xp(v.balances, v.multipliers), v.preciseA);
        }

        uint256[] memory newBalances = new uint256[](pooledTokens.length);

        for (uint256 i = 0; i < pooledTokens.length; i++) {
            require(v.totalSupply != 0 || amounts[i] > 0, "Must supply all tokens in pool");

            // Transfer tokens first to see if a fee was charged on transfer
            if (amounts[i] != 0) {
                uint256 beforeBalance = pooledTokens[i].balanceOf(address(this));
                pooledTokens[i].safeTransferFrom(msg.sender, address(this), amounts[i]);

                // Update the amounts[] with actual transfer amount
                amounts[i] = pooledTokens[i].balanceOf(address(this)).sub(beforeBalance);
            }

            newBalances[i] = v.balances[i].add(amounts[i]);
        }

        // invariant after change
        v.d1 = getD(_xp(newBalances, v.multipliers), v.preciseA);
        require(v.d1 > v.d0, "D should increase");

        // updated to reflect fees and calculate the user's LP tokens
        v.d2 = v.d1;
        uint256[] memory fees = new uint256[](pooledTokens.length);

        if (v.totalSupply != 0) {
            uint256 feePerToken = _feePerToken(self.swapFee, pooledTokens.length);

            SwapFeeInfo memory swapFeeInfo;
            swapFeeInfo.tokens = new address[](fees.length);
            swapFeeInfo.swapFees = new uint256[](fees.length);
            swapFeeInfo.adminFeeRate = self.adminFee;
            for (uint256 i = 0; i < pooledTokens.length; i++) {
                uint256 idealBalance = v.d1.mul(v.balances[i]).div(v.d0);
                fees[i] = feePerToken.mul(idealBalance.difference(newBalances[i])).div(FEE_DENOMINATOR);

                swapFeeInfo.adminFee = fees[i].mul(swapFeeInfo.adminFeeRate).div(FEE_DENOMINATOR);

                self.balances[i] = newBalances[i].sub(swapFeeInfo.adminFee);
                newBalances[i] = newBalances[i].sub(fees[i]);

                swapFeeInfo.tokens[i] = address(pooledTokens[i]);
                swapFeeInfo.swapFees[i] = fees[i].sub(swapFeeInfo.adminFee);
            }

            emit SwapFee(swapFeeInfo.tokens, swapFeeInfo.swapFees);

            v.d2 = getD(_xp(newBalances, v.multipliers), v.preciseA);
        } else {
            // the initial depositor doesn't pay fees
            self.balances = newBalances;
        }

        uint256 toMint;
        if (v.totalSupply == 0) {
            toMint = v.d1;
        } else {
            toMint = v.d2.sub(v.d0).mul(v.totalSupply).div(v.d0);
        }

        require(toMint >= minToMint, "Couldn't mint min requested");

        // mint the user's LP tokens
        v.lpToken.mint(receiver, toMint);

        emit AddLiquidity(receiver, amounts, fees, v.d1, v.totalSupply.add(toMint));

        return toMint;
    }

    /**
     * @notice Burn LP tokens to remove liquidity from the pool.
     * @dev Liquidity can always be removed, even when the pool is paused.
     * @param self Swap struct to read from and write to
     * @param amount the amount of LP tokens to burn
     * @param minAmounts the minimum amounts of each token in the pool
     * acceptable for this burn. Useful as a front-running mitigation
     * @param receiver recipient address
     * @return amounts of tokens the user received
     */
    function removeLiquidity(
        Swap storage self,
        uint256 amount,
        uint256[] calldata minAmounts,
        address receiver
    ) external returns (uint256[] memory) {
        LPToken lpToken = self.lpToken;
        IERC20[] memory pooledTokens = self.pooledTokens;
        require(amount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");
        require(minAmounts.length == pooledTokens.length, "minAmounts must match poolTokens");

        uint256[] memory balances = self.balances;
        uint256 totalSupply = lpToken.totalSupply();

        uint256[] memory amounts = _calculateRemoveLiquidity(balances, amount, totalSupply);

        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] >= minAmounts[i], "amounts[i] < minAmounts[i]");
            self.balances[i] = balances[i].sub(amounts[i]);
            pooledTokens[i].safeTransfer(receiver, amounts[i]);
        }

        lpToken.burnFrom(msg.sender, amount);

        emit RemoveLiquidity(receiver, amounts, totalSupply.sub(amount));

        return amounts;
    }

    /**
     * @notice Remove liquidity from the pool all in one token.
     * @param self Swap struct to read from and write to
     * @param tokenAmount the amount of the lp tokens to burn
     * @param tokenIndex the index of the token you want to receive
     * @param minAmount the minimum amount to withdraw, otherwise revert
     * @param receiver recipient address
     * @return amount chosen token that user received
     */
    function removeLiquidityOneToken(
        Swap storage self,
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        address receiver
    ) external returns (uint256) {
        LPToken lpToken = self.lpToken;
        IERC20[] memory pooledTokens = self.pooledTokens;

        require(tokenAmount <= lpToken.balanceOf(msg.sender), ">LP.balanceOf");
        require(tokenIndex < pooledTokens.length, "Token not found");

        uint256 totalSupply = lpToken.totalSupply();

        (uint256 dy, uint256 dyFee) = _calculateWithdrawOneToken(self, tokenAmount, tokenIndex, totalSupply);

        require(dy >= minAmount, "dy < minAmount");

        uint256 dyAdminFee = dyFee.mul(self.adminFee).div(FEE_DENOMINATOR);

        self.balances[tokenIndex] = self.balances[tokenIndex].sub(dy.add(dyAdminFee));
        lpToken.burnFrom(msg.sender, tokenAmount);
        pooledTokens[tokenIndex].safeTransfer(receiver, dy);

        emit RemoveLiquidityOne(receiver, tokenAmount, totalSupply, tokenIndex, dy);

        SwapFeeInfo memory swapFeeInfo;
        swapFeeInfo.tokens = new address[](1);
        swapFeeInfo.swapFees = new uint256[](1);
        swapFeeInfo.tokens[0] = address(pooledTokens[tokenIndex]);
        swapFeeInfo.swapFees[0] = dyFee.sub(dyAdminFee);
        emit SwapFee(swapFeeInfo.tokens, swapFeeInfo.swapFees);

        return dy;
    }

    /**
     * @notice Remove liquidity from the pool, weighted differently than the
     * pool's current balances.
     *
     * @param self Swap struct to read from and write to
     * @param amounts how much of each token to withdraw
     * @param maxBurnAmount the max LP token provider is willing to pay to
     * remove liquidity. Useful as a front-running mitigation.
     * @param receiver recipient address
     * @return actual amount of LP tokens burned in the withdrawal
     */
    function removeLiquidityImbalance(
        Swap storage self,
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        address receiver
    ) external returns (uint256) {
        ManageLiquidityInfo memory v = ManageLiquidityInfo(
            0,
            0,
            0,
            _getAPrecise(self),
            self.lpToken,
            0,
            self.balances,
            self.tokenPrecisionMultipliers
        );
        v.totalSupply = v.lpToken.totalSupply();

        IERC20[] memory pooledTokens = self.pooledTokens;

        require(amounts.length == pooledTokens.length, "Amounts should match pool tokens");

        require(maxBurnAmount <= v.lpToken.balanceOf(msg.sender) && maxBurnAmount != 0, ">LP.balanceOf");

        uint256 feePerToken = _feePerToken(self.swapFee, pooledTokens.length);
        uint256[] memory fees = new uint256[](pooledTokens.length);
        {
            uint256[] memory balances1 = new uint256[](pooledTokens.length);
            v.d0 = getD(_xp(v.balances, v.multipliers), v.preciseA);
            for (uint256 i = 0; i < pooledTokens.length; i++) {
                balances1[i] = v.balances[i].sub(amounts[i], "Cannot withdraw more than available");
            }
            v.d1 = getD(_xp(balances1, v.multipliers), v.preciseA);

            SwapFeeInfo memory swapFeeInfo;
            swapFeeInfo.tokens = new address[](fees.length);
            swapFeeInfo.swapFees = new uint256[](fees.length);
            swapFeeInfo.adminFeeRate = self.adminFee;
            for (uint256 i = 0; i < pooledTokens.length; i++) {
                uint256 idealBalance = v.d1.mul(v.balances[i]).div(v.d0);
                uint256 difference = idealBalance.difference(balances1[i]);
                fees[i] = feePerToken.mul(difference).div(FEE_DENOMINATOR);

                swapFeeInfo.adminFee = fees[i].mul(swapFeeInfo.adminFeeRate).div(FEE_DENOMINATOR);

                self.balances[i] = balances1[i].sub(swapFeeInfo.adminFee);
                balances1[i] = balances1[i].sub(fees[i]);

                swapFeeInfo.tokens[i] = address(pooledTokens[i]);
                swapFeeInfo.swapFees[i] = fees[i].sub(swapFeeInfo.adminFee);
            }

            emit SwapFee(swapFeeInfo.tokens, swapFeeInfo.swapFees);

            v.d2 = getD(_xp(balances1, v.multipliers), v.preciseA);
        }
        uint256 tokenAmount = v.d0.sub(v.d2).mul(v.totalSupply).div(v.d0);
        require(tokenAmount != 0, "Burnt amount cannot be zero");
        tokenAmount = tokenAmount.add(1);

        require(tokenAmount <= maxBurnAmount, "tokenAmount > maxBurnAmount");

        v.lpToken.burnFrom(msg.sender, tokenAmount);

        for (uint256 i = 0; i < pooledTokens.length; i++) {
            pooledTokens[i].safeTransfer(receiver, amounts[i]);
        }

        emit RemoveLiquidityImbalance(receiver, amounts, fees, v.d1, v.totalSupply.sub(tokenAmount));

        return tokenAmount;
    }

    /**
     * @notice withdraw all admin fees to a given address
     * @param self Swap struct to withdraw fees from
     * @param to Address to send the fees to
     */
    function withdrawAdminFees(Swap storage self, address to) external returns (uint256[] memory) {
        IERC20[] memory pooledTokens = self.pooledTokens;
        uint256[] memory amounts = new uint256[](pooledTokens.length);
        for (uint256 i = 0; i < pooledTokens.length; i++) {
            IERC20 token = pooledTokens[i];
            uint256 balance = token.balanceOf(address(this)).sub(self.balances[i]);
            amounts[i] = balance;
            if (balance != 0) {
                token.safeTransfer(to, balance);
            }
        }
        return amounts;
    }

    /**
     * @notice Sets the admin fee
     * @dev adminFee cannot be higher than 100% of the swap fee
     * @param self Swap struct to update
     * @param newAdminFee new admin fee to be applied on future transactions
     */
    function setAdminFee(Swap storage self, uint256 newAdminFee) external {
        require(newAdminFee <= MAX_ADMIN_FEE, "Fee is too high");
        self.adminFee = newAdminFee;

        emit NewAdminFee(newAdminFee);
    }

    /**
     * @notice update the swap fee
     * @dev fee cannot be higher than 1% of each swap
     * @param self Swap struct to update
     * @param newSwapFee new swap fee to be applied on future transactions
     */
    function setSwapFee(Swap storage self, uint256 newSwapFee) external {
        require(newSwapFee <= MAX_SWAP_FEE, "Fee is too high");
        self.swapFee = newSwapFee;

        emit NewSwapFee(newSwapFee);
    }
}