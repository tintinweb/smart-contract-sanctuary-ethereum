/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// Winding Tree
// Web:     https://windingtree.com/
// Discord: https://discord.gg/5Q3qde6Gr9
// File: @openzeppelin/contracts/introspection/IERC165.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/introspection/ERC165.sol

pragma solidity ^0.5.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: @openzeppelin/contracts/introspection/ERC165Checker.sol

pragma solidity ^0.5.10;

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function _supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function _supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return _supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function _supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!_supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with the `supportsERC165` method in this library.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall.gas(30000)(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @windingtree/org.id/contracts/OrgIdInterface.sol

pragma solidity >=0.5.16;

/**
 * @title ORGiD Registry Smart Contract Interface
 */
contract OrgIdInterface {

    /**
     * @dev Create organization
     * @param solt Unique hash required for identifier creation
     * @param orgJsonHash ORG.JSON's keccak256 hash
     * @param orgJsonUri ORG.JSON URI (stored off-chain)
     * @param orgJsonUriBackup1 ORG.JSON URI backup (stored off-chain)
     * @param orgJsonUriBackup2 ORG.JSON URI backup (stored off-chain)
     * @return {
         "id": "ORGiD byte32 hash"
     }
     */
    function createOrganization(
        bytes32 solt,
        bytes32 orgJsonHash,
        string calldata orgJsonUri,
        string calldata orgJsonUriBackup1,
        string calldata orgJsonUriBackup2
    ) external returns (bytes32 id);

    /**
     * @dev Create organizational unit
     * @param solt Unique hash required for identifier creation
     * @param parentOrgId Parent ORGiD hash
     * @param director Unit director address
     * @param orgJsonHash ORG.JSON keccak256 hash
     * @param orgJsonUri Unit ORG.JSON URI
     * @param orgJsonUriBackup1 Unit ORG.JSON URI backup
     * @param orgJsonUriBackup2 Unit ORG.JSON URI backup
     */
    function createUnit(
        bytes32 solt,
        bytes32 parentOrgId,
        address director,
        bytes32 orgJsonHash,
        string calldata orgJsonUri,
        string calldata orgJsonUriBackup1,
        string calldata orgJsonUriBackup2
    )
        external
        returns (bytes32 newUnitOrgId);

    /**
     * @dev Toggle ORGiD's active/inactive state
     * @param orgId ORGiD hash
     */
    function toggleActiveState(bytes32 orgId) external;

    /**
     * @dev Accept director role
     * @param orgId Unit's ORGiD hash
     */
    function acceptDirectorship(bytes32 orgId) external;

    /**
     * @dev Transfer director role
     * @param orgId Unit's ORGiD hash
     * @param newDirector New director's address
     */
    function transferDirectorship(
        bytes32 orgId,
        address newDirector
    ) external;

    /**
     * @dev Unit directorship renounce
     * @param orgId Unit's ORGiD hash
     */
    function renounceDirectorship(bytes32 orgId)
        external;

    /**
     * @dev Ownership transfer
     * @param orgId ORGiD hash
     * @param newOwner New owner's address
     */
    function transferOrganizationOwnership(
        bytes32 orgId,
        address newOwner
    ) external;

    /**
     * @dev Shorthand method to change ORG.JSON URI and hash at once
     * @param orgId ORGiD hash
     * @param orgJsonHash New ORG.JSON's keccak256 hash
     * @param orgJsonUri New ORG.JSON URI
     * @param orgJsonUriBackup1 New ORG.JSON URI backup
     * @param orgJsonUriBackup2 New ORG.JSON URI backup
     */
    function setOrgJson(
        bytes32 orgId,
        bytes32 orgJsonHash,
        string calldata orgJsonUri,
        string calldata orgJsonUriBackup1,
        string calldata orgJsonUriBackup2
    ) external;

    /**
     * @dev Get all active organizations' ORGiD hashes
     * @param includeInactive Includes not active units into response
     * @return {
         "organizationsList": "Array of all active organizations' ORGiD hashes"
     }
     */
    function getOrganizations(bool includeInactive)
        external
        view
        returns (bytes32[] memory organizationsList);

    /**
     * @dev Get organization or unit's info by ORGiD hash
     * @param _orgId ORGiD hash
     * @dev Return parameters marked by (*) are only applicable to units
     * @return {
         "exists": "Returns `false` if ORGiD doesn't exist",
         "orgId": "ORGiD hash",
         "orgJsonHash": "ORG.JSON keccak256 hash",
         "orgJsonUri": "ORG.JSON URI",
         "orgJsonUriBackup1": "ORG.JSON URI backup",
         "orgJsonUriBackup2": "ORG.JSON URI backup",
         "parentOrgId": "Parent ORGiD (*)",
         "owner": "Owner's address",
         "director": "Unit director's address (*)",
         "isActive": "Indicates whether ORGiD is active",
         "isDirectorshipAccepted": "Indicates whether director accepted the role (*)"
     }
     */
    function getOrganization(bytes32 _orgId)
        external
        view
        returns (
            bool exists,
            bytes32 orgId,
            bytes32 orgJsonHash,
            string memory orgJsonUri,
            string memory orgJsonUriBackup1,
            string memory orgJsonUriBackup2,
            bytes32 parentOrgId,
            address owner,
            address director,
            bool isActive,
            bool isDirectorshipAccepted
        );

    /**
     * @dev Get all active organizational units of a particular ORGiD
     * @param parentOrgId Parent ORGiD hash
     * @param includeInactive Includes not active units into response
     * @return {
         "organizationsList": "Array of ORGiD hashes of active organizational units"
     }
     */
    function getUnits(bytes32 parentOrgId, bool includeInactive)
        external
        view
        returns (bytes32[] memory);
}

// File: contracts/LifDepositInterface.sol

pragma solidity >=0.5.16;

/**
 * @title LifDeposit contract interface
 * @dev A contract that manages deposits in Lif tokens 
 */
contract LifDepositInterface {

    /**
     * @dev Returns Lif token address
     * @return {
         "lifToken": "Address of the Lif token"
     }
     */
    function getLifTokenAddress() external view returns (address lifToken);

    /**
     * @dev Returns withdrawDelay value
     * @return {
         "delay": "Delay time in seconds before the requested withdrawal will be possible"
     }
     */
    function getWithdrawDelay() external view returns (uint256 delay);

    /**
     * @dev Changing withdrawDelay value
     * @param _withdrawDelay New withdrawDelay value in seconds
     */
    function setWithdrawDelay(uint256 _withdrawDelay) external;

    /**
     * @dev Makes deposit of Lif tokens
     * @param organization The organization Id
     * @param value The value to be deposited
     */
    function addDeposit(
        bytes32 organization,
        uint256 value
    ) external;

    /**
     * @dev Submits withdrawal request
     * @param organization The organization Id
     * @param value The value to withdraw
     */
    function submitWithdrawalRequest(
        bytes32 organization,
        uint256 value
    ) external;

    /**
     * @dev Returns information about deposit withdrawal request
     * @param organization The organization Id
     * @return {
         "exists": "The request existence flag",
         "value": "Deposit withdrawal value",
         "withdrawTime": "Withraw time on seconds"
     }
     */
    function getWithdrawalRequest(bytes32 organization)
        external
        view 
        returns (
            bool exists,
            uint256 value,
            uint256 withdrawTime
        );

    /**
     * @dev Trunsfers deposited tokens to the sender
     * @param organization The organization OrgId
     */
    function withdrawDeposit(
        bytes32 organization
    ) external;
}

// File: contracts/LifDeposit.sol

pragma solidity >=0.5.16;










/**
 * @title LifDeposit contract
 * @dev A contract that manages deposits in Lif tokens
 */
contract LifDeposit is LifDepositInterface, Ownable, ERC165, Initializable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Withdrawal request structure
    struct WithdrawalRequest {
        uint256 value;
        uint256 withdrawTime;
    }

    /// @dev OrgId instance
    OrgIdInterface internal orgId;

    /// @dev Lif token instance
    IERC20 internal lif;

    /// @dev Delay in seconds between withdrawal request and withdrawal
    uint256 internal withdrawDelay;

    /// @dev Mapped list of deposits
    mapping (bytes32 => uint256) internal deposits;

    /// @dev Deposits wiwdrawal requests
    mapping (bytes32 => WithdrawalRequest) internal withdrawalRequests;

    /**
     * @dev Event emitted when Lif deposit has been added
     */
    event LifDepositAdded(
        bytes32 indexed organization,
        address indexed sender,
        uint256 value
    );

    /**
     * @dev Event emitted when withdrawDelay has been changed
     */
    event WithdrawDelayChanged(
        uint256 previousWithdrawDelay,
        uint256 newWithdrawDelay
    );

    /**
     * @dev Event emitted when withdrawal requested has been sent
     */
    event WithdrawalRequested(
        bytes32 indexed organization,
        address indexed sender,
        uint256 value,
        uint256 withdrawTime
    );

    /**
     * @dev Event emitted when deposit has been withdrawn
     */
    event DepositWithdrawn(
        bytes32 indexed organization,
        address indexed sender,
        uint256 value
    );

    /**
     * @dev Throws if called by any account other than the owner or entity director.
     */
    modifier onlyOrganizationOwnerOrDirector(bytes32 organization) {
        (
            bool exists,
            ,
            ,
            ,
            ,
            ,
            ,
            address organizationOwner,
            address organizationDirector,
            ,
            
        ) = orgId.getOrganization(organization);
        require(exists, "LifDeposit: Organization not found");
        require(
            organizationOwner == msg.sender || 
            organizationDirector == msg.sender, 
            "LifDeposit: action not authorized (must be owner or director)"
        );
        _;
    }

    /**
     * @dev Initializer for upgradeable contracts
     * @param __owner The address of the contract owner
     * @param _orgId Address of the OrgId contract
     * @param _lif Address of the Lif token
     */
    function initialize(
        address payable __owner,
        address _orgId,
        address _lif
    ) public initializer {
        _transferOwnership(__owner);
        require(
            ERC165Checker._supportsInterface(_orgId, 0x0f4893ef),
            "LifDeposit: OrgId contract must support ORGiD interface"
        );
        orgId = OrgIdInterface(_orgId);
        lif = IERC20(_lif);
        setInterfaces(); 
    }

    /**
     * @dev Returns Lif token address
     * @return {
         "lifToken": "Address of the Lif token"
     }
     */
    function getLifTokenAddress() external view returns (address lifToken) {
        lifToken = address(lif);
    }

    /**
     * @dev Returns withdrawDelay value
     * @return {
         "delay": "Delay time in seconds before the requested withdrawal will be possible"
     }
     */
    function getWithdrawDelay() external view returns (uint256 delay) {
        delay = withdrawDelay;
    }

    /**
     * @dev Changing withdrawDelay value
     * @param _withdrawDelay New withdrawDelay value in seconds
     */
    function setWithdrawDelay(uint256 _withdrawDelay) external onlyOwner {
        emit WithdrawDelayChanged(withdrawDelay, _withdrawDelay);
        withdrawDelay = _withdrawDelay;
    }

    /**
     * @dev Makes deposit of Lif tokens
     * @param organization The organization OrgId
     * @param value The value to be deposited
     */
    function addDeposit(
        bytes32 organization,
        uint256 value
    )
        external 
        onlyOrganizationOwnerOrDirector(organization)
    {
        require(value > 0, "LifDeposit: Invalid deposit value");
        lif.safeTransferFrom(msg.sender, address(this), value);
        deposits[organization] = deposits[organization].add(value);
        emit LifDepositAdded(organization, msg.sender, value);
    }

    /**
     * @dev Submits withdrawal request
     * @param organization The organization OrgId
     * @param value The value to withdraw
     */
    function submitWithdrawalRequest(
        bytes32 organization,
        uint256 value
    )
        external 
        onlyOrganizationOwnerOrDirector(organization)
    {
        require(value > 0, "LifDeposit: Invalid withdrawal value");
        require(
            value <= deposits[organization],
            "LifDeposit: Insufficient balance"
        );
        uint256 withdrawTime = time().add(withdrawDelay);
        withdrawalRequests[organization] = WithdrawalRequest(value, withdrawTime);
        emit WithdrawalRequested(organization, msg.sender, value, withdrawTime);
    }

    /**
     * @dev Returns information about deposit withdrawal request
     * @param organization The organization Id
     * @return {
         "exists": "The request existence flag",
         "value": "Deposit withdrawal value",
         "withdrawTime": "Withraw time on seconds"
     }
     */
    function getWithdrawalRequest(bytes32 organization)
        external
        view 
        returns (
            bool exists,
            uint256 value,
            uint256 withdrawTime
        )
    {
        exists = 
            organization != bytes32(0) &&
            deposits[organization] > 0 &&
            withdrawalRequests[organization].value != 0;
        value = withdrawalRequests[organization].value;
        withdrawTime = withdrawalRequests[organization].withdrawTime;
    }

    /**
     * @dev Returns deposit value of the organization
     * @param organization The organization Id
     * @return {
         "balance": "Deposit value"
     }
     */
    function balanceOf(bytes32 organization)
        external
        view
        returns (uint256 balance)
    {
        balance = deposits[organization];
    }

    /**
     * @dev Trunsfers deposited tokens to the sender
     * @param organization The organization OrgId
     */
    function withdrawDeposit(
        bytes32 organization
    )
        external 
        onlyOrganizationOwnerOrDirector(organization)
    {
        require(
            withdrawalRequests[organization].value != 0,
            "LifDeposit: Withdrawal request not found"
        );
        require(
            withdrawalRequests[organization].withdrawTime <= time(),
            "LifDeposit: Withdrawal request delay period not passed"
        );
        uint256 withdrawalValue = withdrawalRequests[organization].value;
        deposits[organization] = deposits[organization].sub(withdrawalValue);
        delete withdrawalRequests[organization];
        lif.safeTransfer(msg.sender, withdrawalValue);
        emit DepositWithdrawn(organization, msg.sender, withdrawalValue);
    }

    /**
     * @dev Set the list of contract interfaces supported
     */
    function setInterfaces() public {
        LifDepositInterface ldp;
        Ownable own;
        bytes4[3] memory interfaceIds = [
            // ERC165 interface: 0x01ffc9a7
            bytes4(0x01ffc9a7),

            // ownable interface: 0x7f5828d0
            own.owner.selector ^ 
            own.transferOwnership.selector, 

            // Lif deposit interface: 0xe936be58
            ldp.getLifTokenAddress.selector ^
            ldp.getWithdrawDelay.selector ^
            ldp.setWithdrawDelay.selector ^
            ldp.addDeposit.selector ^
            ldp.submitWithdrawalRequest.selector ^
            ldp.getWithdrawalRequest.selector ^
            ldp.withdrawDeposit.selector
        ];
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            _registerInterface(interfaceIds[i]);
        }
    }

    /**
     * @dev Get current time
     * This function can be overriden for testing purposes
     * @return uint256 Current block time
     */
    function time() internal view returns (uint256) {
        return now;// solhint-disable-line not-rely-on-time
    }
}