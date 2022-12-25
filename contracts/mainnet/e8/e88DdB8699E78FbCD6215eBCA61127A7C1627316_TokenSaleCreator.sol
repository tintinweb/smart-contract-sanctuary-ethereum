pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./helpers/TransferHelper.sol";

contract Airdrop is Ownable {
  using Address for address;
  using SafeMath for uint256;

  struct AirdropItem {
    address to;
    uint256 amount;
  }

  uint256 public fee;

  constructor(uint256 _fee) {
    fee = _fee;
  }

  function setFee(uint256 _fee) external onlyOwner {
    fee = _fee;
  }

  function drop(address token, AirdropItem[] memory airdropItems) external payable {
    require(token.isContract(), "must_be_contract_address");
    require(msg.value >= fee, "fee");

    uint256 totalSent;

    for (uint256 i = 0; i < airdropItems.length; i++) totalSent = totalSent.add(airdropItems[i].amount);

    require(IERC20(token).allowance(_msgSender(), address(this)) >= totalSent, "not_enough_allowance");

    for (uint256 i = 0; i < airdropItems.length; i++) {
      TransferHelpers._safeTransferFromERC20(token, _msgSender(), airdropItems[i].to, airdropItems[i].amount);
    }
  }

  function retrieveEther(address to) external onlyOwner {
    TransferHelpers._safeTransferEther(to, address(this).balance);
  }

  function retrieveERC20(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    TransferHelpers._safeTransferERC20(token, to, amount);
  }

  receive() external payable {}
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

library TransferHelpers {
  using Address for address;

  function _safeTransferEther(address to, uint256 amount) internal returns (bool success) {
    (success, ) = to.call{value: amount}(new bytes(0));
    require(success, "failed to transfer ether");
  }

  function _safeTransferERC20(
    address token,
    address to,
    uint256 amount
  ) internal returns (bool success) {
    require(token.isContract(), "call_to_non_contract");
    (success, ) = token.call(abi.encodeWithSelector(bytes4(keccak256(bytes("transfer(address,uint256)"))), to, amount));
    require(success, "low_level_contract_call_failed");
  }

  function _safeTransferFromERC20(
    address token,
    address spender,
    address recipient,
    uint256 amount
  ) internal returns (bool success) {
    require(token.isContract(), "call_to_non_contract");
    (success, ) = token.call(abi.encodeWithSelector(bytes4(keccak256(bytes("transferFrom(address,address,uint256)"))), spender, recipient, amount));
    require(success, "low_level_contract_call_failed");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ITokenSaleCreator.sol";
import "./helpers/TransferHelper.sol";

contract TokenSaleCreator is ReentrancyGuard, Pausable, Ownable, AccessControl, ITokenSaleCreator {
  using Address for address;
  using SafeMath for uint256;

  bytes32[] public allTokenSales;
  bytes32 public pauserRole = keccak256(abi.encodePacked("PAUSER_ROLE"));
  bytes32 public withdrawerRole = keccak256(abi.encodePacked("WITHDRAWER_ROLE"));
  bytes32 public finalizerRole = keccak256(abi.encodePacked("FINALIZER_ROLE"));
  uint256 public withdrawable;

  uint8 public feePercentage;
  uint256 public saleCreationFee;

  mapping(bytes32 => TokenSaleItem) private tokenSales;
  mapping(bytes32 => uint256) private totalEtherRaised;
  mapping(bytes32 => mapping(address => bool)) private isNotAllowedToContribute;
  mapping(bytes32 => mapping(address => uint256)) public amountContributed;
  mapping(bytes32 => mapping(address => uint256)) public balance;

  modifier whenParamsSatisfied(bytes32 saleId) {
    TokenSaleItem memory tokenSale = tokenSales[saleId];
    require(!tokenSale.interrupted, "token_sale_paused");
    require(block.timestamp >= tokenSale.saleStartTime, "token_sale_not_started_yet");
    require(!tokenSale.ended, "token_sale_has_ended");
    require(!isNotAllowedToContribute[saleId][_msgSender()], "you_are_not_allowed_to_participate_in_this_sale");
    require(totalEtherRaised[saleId] < tokenSale.hardCap, "hardcap_reached");
    _;
  }

  constructor(uint8 _feePercentage, uint256 _saleCreationFee) {
    _grantRole(pauserRole, _msgSender());
    _grantRole(withdrawerRole, _msgSender());
    _grantRole(finalizerRole, _msgSender());
    feePercentage = _feePercentage;
    saleCreationFee = _saleCreationFee;
  }

  function initTokenSale(
    address token,
    uint256 tokensForSale,
    uint256 hardCap,
    uint256 softCap,
    uint256 presaleRate,
    uint256 minContributionEther,
    uint256 maxContributionEther,
    uint256 saleStartTime,
    uint256 daysToLast,
    address proceedsTo,
    address admin
  ) external payable whenNotPaused nonReentrant returns (bytes32 saleId) {
    {
      require(msg.value >= saleCreationFee, "fee");
      require(token.isContract(), "must_be_contract_address");
      require(saleStartTime > block.timestamp && saleStartTime.sub(block.timestamp) >= 24 hours, "sale_must_begin_in_at_least_24_hours");
      require(IERC20(token).allowance(_msgSender(), address(this)) >= tokensForSale, "not_enough_allowance_given");
      TransferHelpers._safeTransferFromERC20(token, _msgSender(), address(this), tokensForSale);
    }
    saleId = keccak256(
      abi.encodePacked(
        token,
        _msgSender(),
        block.timestamp,
        tokensForSale,
        hardCap,
        softCap,
        presaleRate,
        minContributionEther,
        maxContributionEther,
        saleStartTime,
        daysToLast,
        proceedsTo
      )
    );
    // Added to prevent 'stack too deep' error
    uint256 endTime;
    {
      endTime = saleStartTime.add(daysToLast.mul(1 days));
      tokenSales[saleId] = TokenSaleItem(
        token,
        tokensForSale,
        hardCap,
        softCap,
        presaleRate,
        saleId,
        minContributionEther,
        maxContributionEther,
        saleStartTime,
        endTime,
        false,
        proceedsTo,
        admin,
        tokensForSale,
        false
      );
    }
    allTokenSales.push(saleId);
    withdrawable = msg.value;
    emit TokenSaleItemCreated(
      saleId,
      token,
      tokensForSale,
      hardCap,
      softCap,
      presaleRate,
      minContributionEther,
      maxContributionEther,
      saleStartTime,
      endTime,
      proceedsTo,
      admin
    );
  }

  function contribute(bytes32 saleId) external payable whenNotPaused nonReentrant whenParamsSatisfied(saleId) {
    TokenSaleItem storage tokenSaleItem = tokenSales[saleId];
    require(
      msg.value >= tokenSaleItem.minContributionEther && msg.value <= tokenSaleItem.maxContributionEther,
      "contribution_must_be_within_min_and_max_range"
    );
    uint256 val = tokenSaleItem.presaleRate.mul(msg.value).div(1 ether);
    require(tokenSaleItem.availableTokens >= val, "tokens_available_for_sale_is_less");
    balance[saleId][_msgSender()] = balance[saleId][_msgSender()].add(val);
    amountContributed[saleId][_msgSender()] = amountContributed[saleId][_msgSender()].add(msg.value);
    totalEtherRaised[saleId] = totalEtherRaised[saleId].add(msg.value);
    tokenSaleItem.availableTokens = tokenSaleItem.availableTokens.sub(val);
  }

  function normalWithdrawal(bytes32 saleId) external whenNotPaused nonReentrant {
    TokenSaleItem storage tokenSaleItem = tokenSales[saleId];
    require(tokenSaleItem.ended || block.timestamp >= tokenSaleItem.saleEndTime, "sale_has_not_ended");
    TransferHelpers._safeTransferERC20(tokenSaleItem.token, _msgSender(), balance[saleId][_msgSender()]);
    delete balance[saleId][_msgSender()];
  }

  function emergencyWithdrawal(bytes32 saleId) external nonReentrant {
    TokenSaleItem storage tokenSaleItem = tokenSales[saleId];
    require(!tokenSaleItem.ended, "sale_has_already_ended");
    TransferHelpers._safeTransferEther(_msgSender(), amountContributed[saleId][_msgSender()]);
    tokenSaleItem.availableTokens = tokenSaleItem.availableTokens.add(balance[saleId][_msgSender()]);
    totalEtherRaised[saleId] = totalEtherRaised[saleId].sub(amountContributed[saleId][_msgSender()]);
    delete balance[saleId][_msgSender()];
    delete amountContributed[saleId][_msgSender()];
  }

  function interruptTokenSale(bytes32 saleId) external whenNotPaused onlyOwner {
    TokenSaleItem storage tokenSale = tokenSales[saleId];
    require(!tokenSale.ended, "token_sale_has_ended");
    tokenSale.interrupted = true;
  }

  function uninterruptTokenSale(bytes32 saleId) external whenNotPaused onlyOwner {
    TokenSaleItem storage tokenSale = tokenSales[saleId];
    tokenSale.interrupted = false;
  }

  function finalizeTokenSale(bytes32 saleId) external whenNotPaused {
    TokenSaleItem storage tokenSale = tokenSales[saleId];
    require(hasRole(finalizerRole, _msgSender()) || tokenSale.admin == _msgSender(), "only_finalizer_or_admin");
    require(!tokenSale.ended, "sale_has_ended");
    uint256 launchpadProfit = (totalEtherRaised[saleId] * uint256(feePercentage)).div(100);
    TransferHelpers._safeTransferEther(tokenSale.proceedsTo, totalEtherRaised[saleId].sub(launchpadProfit));
    withdrawable = withdrawable.add(launchpadProfit);

    if (tokenSale.availableTokens > 0) {
      TransferHelpers._safeTransferERC20(tokenSale.token, tokenSale.proceedsTo, tokenSale.availableTokens);
    }

    tokenSale.ended = true;
  }

  function barFromParticiption(bytes32 saleId, address account) external {
    TokenSaleItem memory tokenSale = tokenSales[saleId];
    require(tokenSale.admin == _msgSender(), "only_admin");
    require(!tokenSale.ended, "sale_has_ended");
    require(!isNotAllowedToContribute[saleId][account], "already_barred");
    isNotAllowedToContribute[saleId][account] = true;
  }

  function rescindBar(bytes32 saleId, address account) external {
    TokenSaleItem memory tokenSale = tokenSales[saleId];
    require(tokenSale.admin == _msgSender(), "only_admin");
    require(!tokenSale.ended, "sale_has_ended");
    require(isNotAllowedToContribute[saleId][account], "not_barred");
    isNotAllowedToContribute[saleId][account] = false;
  }

  function pause() external whenNotPaused {
    require(hasRole(pauserRole, _msgSender()), "must_have_pauser_role");
    _pause();
  }

  function unpause() external whenPaused {
    require(hasRole(pauserRole, _msgSender()), "must_have_pauser_role");
    _unpause();
  }

  function getTotalEtherRaisedForSale(bytes32 saleId) external view returns (uint256) {
    return totalEtherRaised[saleId];
  }

  function getExpectedEtherRaiseForSale(bytes32 saleId) external view returns (uint256) {
    TokenSaleItem memory tokenSaleItem = tokenSales[saleId];
    return tokenSaleItem.hardCap;
  }

  function getSoftCap(bytes32 saleId) external view returns (uint256) {
    TokenSaleItem memory tokenSaleItem = tokenSales[saleId];
    return tokenSaleItem.softCap;
  }

  function withdrawProfit(address to) external {
    require(hasRole(withdrawerRole, _msgSender()) || _msgSender() == owner(), "only_withdrawer_or_owner");
    TransferHelpers._safeTransferEther(to, withdrawable);
    withdrawable = 0;
  }

  function setFeePercentage(uint8 _feePercentage) external onlyOwner {
    feePercentage = _feePercentage;
  }

  function setSaleCreationFee(uint256 _saleCreationFee) external onlyOwner {
    saleCreationFee = _saleCreationFee;
  }

  receive() external payable {
    withdrawable = withdrawable.add(msg.value);
  }
}

pragma solidity ^0.8.0;

interface ITokenSaleCreator {
  struct TokenSaleItem {
    address token;
    uint256 tokensForSale;
    uint256 hardCap;
    uint256 softCap;
    uint256 presaleRate;
    bytes32 saleId;
    uint256 minContributionEther;
    uint256 maxContributionEther;
    uint256 saleStartTime;
    uint256 saleEndTime;
    bool interrupted;
    address proceedsTo;
    address admin;
    uint256 availableTokens;
    bool ended;
  }

  event TokenSaleItemCreated(
    bytes32 saleId,
    address token,
    uint256 tokensForSale,
    uint256 hardCap,
    uint256 softCap,
    uint256 presaleRate,
    uint256 minContributionEther,
    uint256 maxContributionEther,
    uint256 saleStartTime,
    uint256 saleEndTime,
    address proceedsTo,
    address admin
  );

  function initTokenSale(
    address token,
    uint256 tokensForSale,
    uint256 hardCap,
    uint256 softCap,
    uint256 presaleRate,
    uint256 minContributionEther,
    uint256 maxContributionEther,
    uint256 saleStartTime,
    uint256 daysToLast,
    address proceedsTo,
    address admin
  ) external payable returns (bytes32 saleId);

  function interruptTokenSale(bytes32 saleId) external;

  function allTokenSales(uint256) external view returns (bytes32);

  function feePercentage() external view returns (uint8);

  function balance(bytes32 saleId, address account) external view returns (uint256);

  function amountContributed(bytes32 saleId, address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./helpers/TransferHelper.sol";
import "./interfaces/IvToken.sol";

contract USDB is ERC20, AccessControl, Ownable, IvToken {
  using SafeMath for uint256;

  bytes32 public excludedFromTaxRole = keccak256(abi.encodePacked("EXCLUDED_FROM_TAX"));
  bytes32 public retrieverRole = keccak256(abi.encodePacked("RETRIEVER_ROLE"));
  bytes32 public minterRole = keccak256(abi.encodePacked("MINTER_ROLE"));
  address public taxCollector;
  uint8 public taxPercentage;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 amount,
    address tCollector,
    uint8 tPercentage
  ) ERC20(name_, symbol_) {
    _grantRole(excludedFromTaxRole, _msgSender());
    _grantRole(retrieverRole, _msgSender());
    _mint(_msgSender(), amount);
    {
      taxCollector = tCollector;
      taxPercentage = tPercentage;
    }
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override(ERC20) {
    if (!hasRole(excludedFromTaxRole, sender) && sender != address(this)) {
      uint256 tax = amount.mul(uint256(taxPercentage)).div(100);
      super._transfer(sender, taxCollector, tax);
      super._transfer(sender, recipient, amount.sub(tax));
    } else {
      super._transfer(sender, recipient, amount);
    }
  }

  function mint(address to, uint256 amount) external {
    require(hasRole(minterRole, _msgSender()), "only_minter");
    _mint(to, amount);
  }

  function burn(address account, uint256 amount) external {
    require(hasRole(minterRole, _msgSender()), "only_minter");
    _burn(account, amount);
  }

  function retrieveEther(address to) external {
    require(hasRole(retrieverRole, _msgSender()), "only_retriever");
    TransferHelpers._safeTransferEther(to, address(this).balance);
  }

  function retrieveERC20(
    address token,
    address to,
    uint256 amount
  ) external {
    require(hasRole(retrieverRole, _msgSender()), "only_retriever");
    TransferHelpers._safeTransferERC20(token, to, amount);
  }

  function excludeFromPayingTax(address account) external onlyOwner {
    require(!hasRole(excludedFromTaxRole, account), "already_excluded_from_paying_tax");
    _grantRole(excludedFromTaxRole, account);
  }

  function includeInPayingTax(address account) external onlyOwner {
    require(hasRole(excludedFromTaxRole, account), "not_paying_tax");
    _revokeRole(excludedFromTaxRole, account);
  }

  function addRetriever(address account) external onlyOwner {
    require(!hasRole(retrieverRole, account), "already_retriever");
    _grantRole(retrieverRole, account);
  }

  function removeRetriever(address account) external onlyOwner {
    require(hasRole(retrieverRole, account), "not_retriever");
    _revokeRole(retrieverRole, account);
  }

  function setTaxPercentage(uint8 tPercentage) external onlyOwner {
    require(tPercentage <= 10, "tax_must_be_ten_percent_or_less");
    taxPercentage = tPercentage;
  }

  function setMinter(address account) external onlyOwner {
    require(!hasRole(minterRole, account), "already_minter");
    _grantRole(minterRole, account);
  }

  function removeMinter(address account) external onlyOwner {
    require(hasRole(minterRole, account), "not_a_minter");
    _revokeRole(minterRole, account);
  }

  function setTaxCollector(address tCollector) external onlyOwner {
    taxCollector = tCollector;
  }

  receive() external payable {}
}

pragma solidity ^0.8.0;

interface IvToken {
  function mint(address to, uint256 amount) external;

  function burn(address account, uint256 amount) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./StakingPool.sol";
import "./helpers/TransferHelper.sol";

contract StakingPoolActions is Ownable, AccessControl {
  uint256 public deploymentFee;

  bytes32 public feeTakerRole = keccak256(abi.encodePacked("FEE_TAKER_ROLE"));
  bytes32 public feeSetterRole = keccak256(abi.encodePacked("FEE_SETTER_ROLE"));

  mapping(address => address[]) public stakingPools;

  event StakingPoolDeployed(address poolId, address owner, address token0, address token1, uint256 apy1, uint256 apy2, uint256 tax);

  constructor(uint256 _deploymentFee) {
    deploymentFee = _deploymentFee;
    _grantRole(feeTakerRole, _msgSender());
    _grantRole(feeSetterRole, _msgSender());
  }

  function deployStakingPool(
    address token0,
    address token1,
    uint16 apy1,
    uint16 apy2,
    uint8 taxPercentage,
    uint256 withdrawalIntervals
  ) external payable returns (address poolId) {
    require(msg.value >= deploymentFee);
    bytes memory bytecode = abi.encodePacked(
      type(StakingPool).creationCode,
      abi.encode(_msgSender(), token0, token1, apy1, apy2, taxPercentage, withdrawalIntervals)
    );
    bytes32 salt = keccak256(abi.encodePacked(token0, token1, apy1, apy2, _msgSender(), block.timestamp));

    assembly {
      poolId := create2(0, add(bytecode, 32), mload(bytecode), salt)
      if iszero(extcodesize(poolId)) {
        revert(0, 0)
      }
    }

    address[] storage usersPools = stakingPools[_msgSender()];
    usersPools.push(poolId);

    emit StakingPoolDeployed(poolId, _msgSender(), token0, token1, apy1, apy2, taxPercentage);
  }

  function withdrawEther(address to) external {
    require(hasRole(feeTakerRole, _msgSender()));
    TransferHelpers._safeTransferEther(to, address(this).balance);
  }

  function withdrawToken(
    address token,
    address to,
    uint256 amount
  ) external {
    require(hasRole(feeTakerRole, _msgSender()));
    TransferHelpers._safeTransferERC20(token, to, amount);
  }

  function setFee(uint256 _fee) external {
    require(hasRole(feeSetterRole, _msgSender()));
    deploymentFee = _fee;
  }

  function setFeeSetter(address account) external onlyOwner {
    require(!hasRole(feeSetterRole, account));
    _grantRole(feeSetterRole, account);
  }

  function removeFeeSetter(address account) external onlyOwner {
    require(hasRole(feeSetterRole, account));
    _revokeRole(feeSetterRole, account);
  }

  function setFeeTaker(address account) external onlyOwner {
    require(!hasRole(feeTakerRole, account));
    _grantRole(feeTakerRole, account);
  }

  function removeFeeTaker(address account) external onlyOwner {
    require(hasRole(feeTakerRole, account));
    _revokeRole(feeTakerRole, account);
  }

  receive() external payable {}
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStakingPool.sol";
import "./helpers/TransferHelper.sol";

contract StakingPool is Ownable, AccessControl, Pausable, ReentrancyGuard, IStakingPool {
  using SafeMath for uint256;
  using Address for address;

  bytes32 public pauserRole = keccak256(abi.encodePacked("PAUSER_ROLE"));
  address public immutable tokenA;
  address public immutable tokenB;
  uint16 public tokenAAPY;
  uint16 public tokenBAPY;
  uint8 public stakingPoolTax;
  uint256 public withdrawalIntervals;

  mapping(bytes32 => Stake) public stakes;
  mapping(address => bytes32[]) public poolsByAddresses;
  mapping(address => bool) public blockedAddresses;
  mapping(address => uint256) public nonWithdrawableERC20;

  bytes32[] public stakeIDs;

  constructor(
    address newOwner,
    address token0,
    address token1,
    uint16 apy1,
    uint16 apy2,
    uint8 poolTax,
    uint256 intervals
  ) {
    require(token0.isContract());
    require(token1.isContract());
    tokenA = token0;
    tokenB = token1;
    tokenAAPY = apy1;
    tokenBAPY = apy2;
    stakingPoolTax = poolTax;
    withdrawalIntervals = intervals;
    _grantRole(pauserRole, _msgSender());
    _grantRole(pauserRole, newOwner);
    _transferOwnership(newOwner);
  }

  function calculateReward(bytes32 stakeId) public view returns (uint256 reward) {
    Stake memory stake = stakes[stakeId];
    uint256 percentage;
    if (stake.tokenStaked == tokenA) {
      // How much percentage reward does this staker yield?
      percentage = uint256(tokenBAPY).mul(block.timestamp.sub(stake.since) / (60 * 60 * 24 * 7 * 4)).div(12);
    } else {
      percentage = uint256(tokenAAPY).mul(block.timestamp.sub(stake.since) / (60 * 60 * 24 * 7 * 4)).div(12);
    }

    reward = stake.amountStaked.mul(percentage) / 100;
  }

  function stakeAsset(address token, uint256 amount) external whenNotPaused nonReentrant {
    require(token == tokenA || token == tokenB);
    require(token.isContract());
    require(!blockedAddresses[_msgSender()]);
    require(amount > 0);
    uint256 tax = amount.mul(stakingPoolTax) / 100;
    require(IERC20(token).allowance(_msgSender(), address(this)) >= amount);
    TransferHelpers._safeTransferFromERC20(token, _msgSender(), address(this), amount);
    bytes32 stakeId = keccak256(abi.encodePacked(_msgSender(), address(this), token, block.timestamp));
    Stake memory stake = Stake({
      amountStaked: amount.sub(tax),
      tokenStaked: token,
      since: block.timestamp,
      staker: _msgSender(),
      stakeId: stakeId,
      nextWithdrawalTime: block.timestamp.add(withdrawalIntervals)
    });
    stakes[stakeId] = stake;
    bytes32[] storage stakez = poolsByAddresses[_msgSender()];
    stakez.push(stakeId);
    stakeIDs.push(stakeId);
    nonWithdrawableERC20[token] = nonWithdrawableERC20[token].add(stake.amountStaked);
    emit Staked(amount, token, stake.since, _msgSender(), stakeId);
  }

  function unstakeAmount(bytes32 stakeId, uint256 amount) external whenNotPaused nonReentrant {
    Stake storage stake = stakes[stakeId];
    require(_msgSender() == stake.staker);
    TransferHelpers._safeTransferERC20(stake.tokenStaked, _msgSender(), amount);
    stake.amountStaked = stake.amountStaked.sub(amount);
    nonWithdrawableERC20[stake.tokenStaked] = nonWithdrawableERC20[stake.tokenStaked].sub(amount);
    emit Unstaked(amount, stakeId);
  }

  function unstakeAll(bytes32 stakeId) external nonReentrant {
    Stake memory stake = stakes[stakeId];
    require(_msgSender() == stake.staker);
    TransferHelpers._safeTransferERC20(stake.tokenStaked, _msgSender(), stake.amountStaked);
    delete stakes[stakeId];

    bytes32[] storage stakez = poolsByAddresses[_msgSender()];

    for (uint256 i = 0; i < stakez.length; i++) {
      if (stakez[i] == stakeId) {
        stakez[i] = bytes32(0);
      }
    }
    nonWithdrawableERC20[stake.tokenStaked] = nonWithdrawableERC20[stake.tokenStaked].sub(stake.amountStaked);
    emit Unstaked(stake.amountStaked, stakeId);
  }

  function withdrawRewards(bytes32 stakeId) external whenNotPaused nonReentrant {
    Stake storage stake = stakes[stakeId];
    require(_msgSender() == stake.staker);
    require(block.timestamp >= stake.nextWithdrawalTime, "cannot_withdraw_now");
    uint256 reward = calculateReward(stakeId);
    address token = stake.tokenStaked == tokenA ? tokenB : tokenA;
    uint256 amount = stake.amountStaked.add(reward);
    TransferHelpers._safeTransferERC20(token, stake.staker, amount);
    stake.since = block.timestamp;
    stake.nextWithdrawalTime = block.timestamp.add(withdrawalIntervals);
    emit Withdrawn(amount, stakeId);
  }

  function retrieveEther(address to) external onlyOwner {
    TransferHelpers._safeTransferEther(to, address(this).balance);
  }

  function setStakingPoolTax(uint8 poolTax) external onlyOwner {
    stakingPoolTax = poolTax;
  }

  function retrieveERC20(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    require(token.isContract(), "must_be_contract_address");
    uint256 bal = IERC20(token).balanceOf(address(this));
    require(bal > nonWithdrawableERC20[token], "balance_lower_than_staked");

    if (nonWithdrawableERC20[token] > 0) {
      require(bal.sub(amount) < nonWithdrawableERC20[token], "amount_must_be_less_than_staked");
    }

    TransferHelpers._safeTransferERC20(token, to, amount);
  }

  function pause() external {
    require(hasRole(pauserRole, _msgSender()));
    _pause();
  }

  function unpause() external {
    require(hasRole(pauserRole, _msgSender()));
    _unpause();
  }

  receive() external payable {}
}

pragma solidity ^0.8.0;

interface IStakingPool {
  struct Stake {
    uint256 amountStaked;
    address tokenStaked;
    uint256 since;
    address staker;
    bytes32 stakeId;
    uint256 nextWithdrawalTime;
  }

  event Staked(uint256 amount, address token, uint256 since, address staker, bytes32 stakeId);
  event Unstaked(uint256 amount, bytes32 stakeId);
  event Withdrawn(uint256 amount, bytes32 stakeId);

  function stakes(bytes32)
    external
    view
    returns (
      uint256,
      address,
      uint256,
      address,
      bytes32,
      uint256
    );

  // function poolsByAddresses(address) external view returns (bytes32[] memory);

  function blockedAddresses(address) external view returns (bool);

  function stakeIDs(uint256) external view returns (bytes32);

  function stakingPoolTax() external view returns (uint8);

  function tokenA() external view returns (address);

  function tokenB() external view returns (address);

  function stakeAsset(address, uint256) external;

  function withdrawRewards(bytes32) external;

  function tokenAAPY() external view returns (uint16);

  function tokenBAPY() external view returns (uint16);

  function withdrawalIntervals() external view returns (uint256);

  function unstakeAmount(bytes32, uint256) external;

  function unstakeAll(bytes32) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./helpers/TransferHelper.sol";
import "./interfaces/IStakingPool.sol";
import "./interfaces/IvToken.sol";

contract SpecialStakingPool is Ownable, AccessControl, Pausable, ReentrancyGuard, IStakingPool {
  using SafeMath for uint256;
  using Address for address;

  address public immutable tokenA;
  address public immutable tokenB;

  uint16 public tokenAAPY;
  uint16 public tokenBAPY;
  uint8 public stakingPoolTax;
  uint256 public withdrawalIntervals;

  bytes32 public pauserRole = keccak256(abi.encodePacked("PAUSER_ROLE"));
  bytes32 public apySetterRole = keccak256(abi.encodePacked("APY_SETTER_ROLE"));

  mapping(bytes32 => Stake) public stakes;
  mapping(address => bytes32[]) public poolsByAddresses;
  mapping(address => bool) public blockedAddresses;
  mapping(address => uint256) public nonWithdrawableERC20;

  bytes32[] public stakeIDs;

  uint256 public withdrawable;

  constructor(
    address newOwner,
    address A,
    address B,
    uint16 aAPY,
    uint16 bAPY,
    uint8 stakingTax,
    uint256 intervals
  ) {
    require(A == address(0) || A.isContract(), "A_must_be_zero_address_or_contract");
    require(B.isContract(), "B_must_be_contract");
    tokenA = A;
    tokenB = B;
    tokenAAPY = aAPY;
    tokenBAPY = bAPY;
    stakingPoolTax = stakingTax;
    withdrawalIntervals = intervals;
    _transferOwnership(newOwner);
    _grantRole(pauserRole, newOwner);
    _grantRole(apySetterRole, newOwner);
  }

  function calculateReward(bytes32 stakeId) public view returns (uint256 reward) {
    Stake memory stake = stakes[stakeId];
    uint256 percentage;
    if (stake.tokenStaked == tokenA) {
      // How much percentage reward does this staker yield?
      percentage = uint256(tokenBAPY).mul(block.timestamp.sub(stake.since) / (60 * 60 * 24 * 7 * 4)).div(12);
    } else {
      percentage = uint256(tokenAAPY).mul(block.timestamp.sub(stake.since) / (60 * 60 * 24 * 7 * 4)).div(12);
    }

    reward = stake.amountStaked.mul(percentage) / 100;
  }

  function stakeEther() external payable whenNotPaused nonReentrant {
    require(!blockedAddresses[_msgSender()], "blocked");
    require(msg.value > 0, "must_stake_greater_than_0");
    uint256 tax = msg.value.mul(stakingPoolTax) / 100;
    bytes32 stakeId = keccak256(abi.encodePacked(_msgSender(), address(this), address(0), block.timestamp));
    Stake memory stake = Stake({
      amountStaked: msg.value.sub(tax),
      tokenStaked: address(0),
      since: block.timestamp,
      staker: _msgSender(),
      stakeId: stakeId,
      nextWithdrawalTime: block.timestamp.add(withdrawalIntervals)
    });
    stakes[stakeId] = stake;
    bytes32[] storage stakez = poolsByAddresses[_msgSender()];
    stakez.push(stakeId);
    stakeIDs.push(stakeId);
    withdrawable = withdrawable.add(tax);
    emit Staked(msg.value, address(0), stake.since, _msgSender(), stakeId);
  }

  function stakeAsset(address token, uint256 amount) external whenNotPaused nonReentrant {
    require(token.isContract(), "must_be_contract_address");
    require(token == tokenA, "cannot_stake_this_token");
    require(!blockedAddresses[_msgSender()], "blocked");
    require(amount > 0, "must_stake_greater_than_0");
    uint256 tax = amount.mul(stakingPoolTax) / 100;
    require(IERC20(token).allowance(_msgSender(), address(this)) >= amount, "not_enough_allowance");
    TransferHelpers._safeTransferFromERC20(token, _msgSender(), address(this), amount);
    bytes32 stakeId = keccak256(abi.encodePacked(_msgSender(), address(this), token, block.timestamp));
    Stake memory stake = Stake({
      amountStaked: amount.sub(tax),
      tokenStaked: token,
      since: block.timestamp,
      staker: _msgSender(),
      stakeId: stakeId,
      nextWithdrawalTime: block.timestamp.add(withdrawalIntervals)
    });
    stakes[stakeId] = stake;
    bytes32[] storage stakez = poolsByAddresses[_msgSender()];
    stakez.push(stakeId);
    stakeIDs.push(stakeId);
    nonWithdrawableERC20[token] = nonWithdrawableERC20[token].add(stake.amountStaked);
    emit Staked(amount, token, stake.since, _msgSender(), stakeId);
  }

  function unstakeAmount(bytes32 stakeId, uint256 amount) external whenNotPaused nonReentrant {
    Stake storage stake = stakes[stakeId];
    require(_msgSender() == stake.staker, "not_owner");
    if (stake.tokenStaked == address(0)) {
      TransferHelpers._safeTransferEther(_msgSender(), amount);
    } else {
      TransferHelpers._safeTransferERC20(stake.tokenStaked, _msgSender(), amount);
      nonWithdrawableERC20[stake.tokenStaked] = nonWithdrawableERC20[stake.tokenStaked].sub(amount);
    }

    stake.amountStaked = stake.amountStaked.sub(amount);
    emit Unstaked(amount, stakeId);
  }

  function unstakeAll(bytes32 stakeId) external whenNotPaused nonReentrant {
    Stake memory stake = stakes[stakeId];
    require(_msgSender() == stake.staker, "not_owner");
    if (stake.tokenStaked == address(0)) {
      TransferHelpers._safeTransferEther(_msgSender(), stake.amountStaked);
    } else {
      TransferHelpers._safeTransferERC20(stake.tokenStaked, _msgSender(), stake.amountStaked);
      nonWithdrawableERC20[stake.tokenStaked] = nonWithdrawableERC20[stake.tokenStaked].sub(stake.amountStaked);
    }
    delete stakes[stakeId];

    bytes32[] storage stakez = poolsByAddresses[_msgSender()];

    for (uint256 i = 0; i < stakez.length; i++) {
      if (stakez[i] == stakeId) {
        stakez[i] = bytes32(0);
      }
    }
    emit Unstaked(stake.amountStaked, stakeId);
  }

  function withdrawRewards(bytes32 stakeId) external whenNotPaused nonReentrant {
    Stake storage stake = stakes[stakeId];
    require(_msgSender() == stake.staker, "not_owner");
    require(block.timestamp >= stake.nextWithdrawalTime, "cannot_withdraw_now");
    uint256 reward = calculateReward(stakeId);
    address token = stake.tokenStaked == tokenA ? tokenB : tokenA;
    uint256 amount = stake.amountStaked.add(reward);

    if (token == tokenB) IvToken(token).mint(_msgSender(), amount);
    else {
      if (tokenA == address(0)) TransferHelpers._safeTransferEther(_msgSender(), amount);
      else TransferHelpers._safeTransferERC20(token, _msgSender(), amount);
    }

    stake.since = block.timestamp;
    stake.nextWithdrawalTime = block.timestamp.add(withdrawalIntervals);
    emit Withdrawn(amount, stakeId);
  }

  function retrieveEther(address to) external onlyOwner {
    TransferHelpers._safeTransferEther(to, withdrawable);
    withdrawable = 0;
  }

  function setStakingPoolTax(uint8 poolTax) external onlyOwner {
    stakingPoolTax = poolTax;
  }

  function retrieveERC20(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    require(token.isContract(), "must_be_contract_address");
    uint256 bal = IERC20(token).balanceOf(address(this));
    require(bal > nonWithdrawableERC20[token], "balance_lower_than_staked");

    if (nonWithdrawableERC20[token] > 0) require(bal.sub(amount) < nonWithdrawableERC20[token], "amount_must_be_less_than_staked");

    TransferHelpers._safeTransferERC20(token, to, amount);
  }

  function pause() external {
    require(hasRole(pauserRole, _msgSender()), "only_pauser");
    _pause();
  }

  function unpause() external {
    require(hasRole(pauserRole, _msgSender()), "only_pauser");
    _unpause();
  }

  function setTokenAAPY(uint8 aAPY) external {
    require(hasRole(apySetterRole, _msgSender()), "only_apy_setter");
    tokenAAPY = aAPY;
  }

  function setTokenBAPY(uint8 bAPY) external {
    require(hasRole(apySetterRole, _msgSender()), "only_apy_setter");
    tokenBAPY = bAPY;
  }

  function setAPYSetter(address account) external onlyOwner {
    require(!hasRole(apySetterRole, account), "already_apy_setter");
    _grantRole(apySetterRole, account);
  }

  function removeAPYSetter(address account) external onlyOwner {
    require(hasRole(apySetterRole, account), "not_apy_setter");
    _revokeRole(apySetterRole, account);
  }

  function setWithdrawalIntervals(uint256 intervals) external onlyOwner {
    withdrawalIntervals = intervals;
  }

  function setPauser(address account) external onlyOwner {
    require(!hasRole(pauserRole, account), "already_pauser");
    _grantRole(pauserRole, account);
  }

  function removePauser(address account) external onlyOwner {
    require(hasRole(pauserRole, account), "not_pauser");
    _revokeRole(pauserRole, account);
  }

  receive() external payable {
    withdrawable = withdrawable.add(msg.value);
  }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPrivateTokenSaleCreator.sol";
import "./helpers/TransferHelper.sol";

contract PrivateTokenSaleCreator is ReentrancyGuard, Pausable, Ownable, AccessControl, IPrivateTokenSaleCreator {
  using Address for address;
  using SafeMath for uint256;

  bytes32[] public allTokenSales;
  bytes32 public pauserRole = keccak256(abi.encodePacked("PAUSER_ROLE"));
  bytes32 public withdrawerRole = keccak256(abi.encodePacked("WITHDRAWER_ROLE"));
  bytes32 public finalizerRole = keccak256(abi.encodePacked("FINALIZER_ROLE"));
  uint256 public withdrawable;

  uint8 public feePercentage;
  uint256 public saleCreationFee;

  mapping(bytes32 => TokenSaleItem) private tokenSales;
  mapping(bytes32 => uint256) private totalEtherRaised;
  mapping(bytes32 => mapping(address => bool)) private isNotAllowedToContribute;
  mapping(bytes32 => mapping(address => uint256)) public amountContributed;
  mapping(bytes32 => mapping(address => uint256)) public balance;
  mapping(bytes32 => address[]) public whitelists;

  modifier whenParamsSatisfied(bytes32 saleId) {
    TokenSaleItem memory tokenSale = tokenSales[saleId];
    require(!tokenSale.interrupted, "token_sale_paused");
    require(block.timestamp >= tokenSale.saleStartTime, "token_sale_not_started_yet");
    require(!tokenSale.ended, "token_sale_has_ended");
    require(!isNotAllowedToContribute[saleId][_msgSender()], "you_are_not_allowed_to_participate_in_this_sale");
    require(indexOfList(whitelists[saleId], _msgSender()) > uint256(int256(-1)), "only_whitelisted_addresses_can_partake_in_this_sale");
    require(totalEtherRaised[saleId] < tokenSale.hardCap, "hardcap_reached");
    _;
  }

  constructor(uint8 _feePercentage, uint256 _saleCreationFee) {
    _grantRole(pauserRole, _msgSender());
    _grantRole(withdrawerRole, _msgSender());
    _grantRole(finalizerRole, _msgSender());
    feePercentage = _feePercentage;
    saleCreationFee = _saleCreationFee;
  }

  function initTokenSale(
    address token,
    uint256 tokensForSale,
    uint256 hardCap,
    uint256 softCap,
    uint256 presaleRate,
    uint256 minContributionEther,
    uint256 maxContributionEther,
    uint256 saleStartTime,
    uint256 daysToLast,
    address proceedsTo,
    address admin,
    address[] memory whiteList
  ) external payable whenNotPaused nonReentrant returns (bytes32 saleId) {
    {
      require(msg.value >= saleCreationFee, "fee");
      require(token.isContract(), "must_be_contract_address");
      require(saleStartTime > block.timestamp && saleStartTime.sub(block.timestamp) >= 24 hours, "sale_must_begin_in_at_least_24_hours");
      require(IERC20(token).allowance(_msgSender(), address(this)) >= tokensForSale, "not_enough_allowance_given");
      TransferHelpers._safeTransferFromERC20(token, _msgSender(), address(this), tokensForSale);
    }
    saleId = keccak256(
      abi.encodePacked(
        token,
        _msgSender(),
        block.timestamp,
        tokensForSale,
        hardCap,
        softCap,
        presaleRate,
        minContributionEther,
        maxContributionEther,
        saleStartTime,
        daysToLast,
        proceedsTo
      )
    );
    // Added to prevent 'stack too deep' error
    uint256 endTime;
    {
      endTime = saleStartTime.add(daysToLast.mul(1 days));
      tokenSales[saleId] = TokenSaleItem(
        token,
        tokensForSale,
        hardCap,
        softCap,
        presaleRate,
        saleId,
        minContributionEther,
        maxContributionEther,
        saleStartTime,
        endTime,
        false,
        proceedsTo,
        admin,
        tokensForSale,
        false
      );
    }
    allTokenSales.push(saleId);
    whitelists[saleId] = whiteList;
    withdrawable = msg.value;
    emit TokenSaleItemCreated(
      saleId,
      token,
      tokensForSale,
      hardCap,
      softCap,
      presaleRate,
      minContributionEther,
      maxContributionEther,
      saleStartTime,
      endTime,
      proceedsTo,
      admin
    );
  }

  function contribute(bytes32 saleId) external payable whenNotPaused nonReentrant whenParamsSatisfied(saleId) {
    TokenSaleItem storage tokenSaleItem = tokenSales[saleId];
    require(
      msg.value >= tokenSaleItem.minContributionEther && msg.value <= tokenSaleItem.maxContributionEther,
      "contribution_must_be_within_min_and_max_range"
    );
    uint256 val = tokenSaleItem.presaleRate.mul(msg.value).div(1 ether);
    require(tokenSaleItem.availableTokens >= val, "tokens_available_for_sale_is_less");
    balance[saleId][_msgSender()] = balance[saleId][_msgSender()].add(val);
    amountContributed[saleId][_msgSender()] = amountContributed[saleId][_msgSender()].add(msg.value);
    totalEtherRaised[saleId] = totalEtherRaised[saleId].add(msg.value);
    tokenSaleItem.availableTokens = tokenSaleItem.availableTokens.sub(val);
  }

  function normalWithdrawal(bytes32 saleId) external whenNotPaused nonReentrant {
    TokenSaleItem storage tokenSaleItem = tokenSales[saleId];
    require(tokenSaleItem.ended || block.timestamp >= tokenSaleItem.saleEndTime, "sale_has_not_ended");
    TransferHelpers._safeTransferERC20(tokenSaleItem.token, _msgSender(), balance[saleId][_msgSender()]);
    delete balance[saleId][_msgSender()];
  }

  function emergencyWithdrawal(bytes32 saleId) external nonReentrant {
    TokenSaleItem storage tokenSaleItem = tokenSales[saleId];
    require(!tokenSaleItem.ended, "sale_has_already_ended");
    TransferHelpers._safeTransferEther(_msgSender(), amountContributed[saleId][_msgSender()]);
    tokenSaleItem.availableTokens = tokenSaleItem.availableTokens.add(balance[saleId][_msgSender()]);
    totalEtherRaised[saleId] = totalEtherRaised[saleId].sub(amountContributed[saleId][_msgSender()]);
    delete balance[saleId][_msgSender()];
    delete amountContributed[saleId][_msgSender()];
  }

  function interruptTokenSale(bytes32 saleId) external whenNotPaused onlyOwner {
    TokenSaleItem storage tokenSale = tokenSales[saleId];
    require(!tokenSale.ended, "token_sale_has_ended");
    tokenSale.interrupted = true;
  }

  function uninterruptTokenSale(bytes32 saleId) external whenNotPaused onlyOwner {
    TokenSaleItem storage tokenSale = tokenSales[saleId];
    tokenSale.interrupted = false;
  }

  function finalizeTokenSale(bytes32 saleId) external whenNotPaused {
    TokenSaleItem storage tokenSale = tokenSales[saleId];
    require(hasRole(finalizerRole, _msgSender()) || tokenSale.admin == _msgSender(), "only_finalizer_or_admin");
    require(!tokenSale.ended, "sale_has_ended");
    uint256 launchpadProfit = (totalEtherRaised[saleId] * feePercentage).div(100);
    TransferHelpers._safeTransferEther(tokenSale.proceedsTo, totalEtherRaised[saleId].sub(launchpadProfit));
    withdrawable = withdrawable.add(launchpadProfit);

    if (tokenSale.availableTokens > 0) {
      TransferHelpers._safeTransferERC20(tokenSale.token, tokenSale.proceedsTo, tokenSale.availableTokens);
    }

    tokenSale.ended = true;
  }

  function barFromParticiption(bytes32 saleId, address account) external {
    TokenSaleItem memory tokenSale = tokenSales[saleId];
    require(tokenSale.admin == _msgSender(), "only_admin");
    require(!tokenSale.ended, "sale_has_ended");
    require(!isNotAllowedToContribute[saleId][account], "already_barred");
    isNotAllowedToContribute[saleId][account] = true;
  }

  function rescindBar(bytes32 saleId, address account) external {
    TokenSaleItem memory tokenSale = tokenSales[saleId];
    require(tokenSale.admin == _msgSender(), "only_admin");
    require(!tokenSale.ended, "sale_has_ended");
    require(isNotAllowedToContribute[saleId][account], "not_barred");
    isNotAllowedToContribute[saleId][account] = false;
  }

  function whitelist(bytes32 saleId) public view returns (address[] memory list) {
    list = whitelists[saleId];
  }

  function addToWhitelist(bytes32 saleId, address[] memory list) external {
    TokenSaleItem memory tokenSale = tokenSales[saleId];
    require(tokenSale.admin == _msgSender(), "only_admin");

    address[] storage l = whitelists[saleId];

    for (uint256 i = 0; i < list.length; i++) {
      if (indexOfList(l, list[i]) == uint256(int256(-1))) {
        l.push(list[i]);
      }
    }
  }

  function removeFromWhiteList(bytes32 saleId, address[] memory list) external {
    TokenSaleItem memory tokenSale = tokenSales[saleId];
    require(tokenSale.admin == _msgSender(), "only_admin");

    address[] storage l = whitelists[saleId];

    for (uint256 i = 0; i < list.length; i++) {
      uint256 index = indexOfList(l, list[i]);
      if (index > uint256(int256(-1))) {
        delete l[index];
      }
    }
  }

  function indexOfList(address[] memory list, address item) internal pure returns (uint256 index) {
    index = uint256(int256(-1));

    for (uint256 i = 0; i < list.length; i++) {
      if (list[i] == item) {
        index = i;
      }
    }
  }

  function pause() external whenNotPaused {
    require(hasRole(pauserRole, _msgSender()), "must_have_pauser_role");
    _pause();
  }

  function unpause() external whenPaused {
    require(hasRole(pauserRole, _msgSender()), "must_have_pauser_role");
    _unpause();
  }

  function getTotalEtherRaisedForSale(bytes32 saleId) external view returns (uint256) {
    return totalEtherRaised[saleId];
  }

  function getExpectedEtherRaiseForSale(bytes32 saleId) external view returns (uint256) {
    TokenSaleItem memory tokenSaleItem = tokenSales[saleId];
    return tokenSaleItem.hardCap;
  }

  function getSoftCap(bytes32 saleId) external view returns (uint256) {
    TokenSaleItem memory tokenSaleItem = tokenSales[saleId];
    return tokenSaleItem.softCap;
  }

  function withdrawProfit(address to) external {
    require(hasRole(withdrawerRole, _msgSender()), "only_withdrawer");
    TransferHelpers._safeTransferEther(to, withdrawable);
    withdrawable = 0;
  }

  function setFeePercentage(uint8 _feePercentage) external onlyOwner {
    feePercentage = _feePercentage;
  }

  function setSaleCreationFee(uint256 _saleCreationFee) external onlyOwner {
    saleCreationFee = _saleCreationFee;
  }

  receive() external payable {
    withdrawable = withdrawable.add(msg.value);
  }
}

pragma solidity ^0.8.0;

interface IPrivateTokenSaleCreator {
  struct TokenSaleItem {
    address token;
    uint256 tokensForSale;
    uint256 hardCap;
    uint256 softCap;
    uint256 presaleRate;
    bytes32 saleId;
    uint256 minContributionEther;
    uint256 maxContributionEther;
    uint256 saleStartTime;
    uint256 saleEndTime;
    bool interrupted;
    address proceedsTo;
    address admin;
    uint256 availableTokens;
    bool ended;
  }

  event TokenSaleItemCreated(
    bytes32 saleId,
    address token,
    uint256 tokensForSale,
    uint256 hardCap,
    uint256 softCap,
    uint256 presaleRate,
    uint256 minContributionEther,
    uint256 maxContributionEther,
    uint256 saleStartTime,
    uint256 saleEndTime,
    address proceedsTo,
    address admin
  );

  function initTokenSale(
    address token,
    uint256 tokensForSale,
    uint256 hardCap,
    uint256 softCap,
    uint256 presaleRate,
    uint256 minContributionEther,
    uint256 maxContributionEther,
    uint256 saleStartTime,
    uint256 daysToLast,
    address proceedsTo,
    address admin,
    address[] memory whitelist
  ) external payable returns (bytes32 saleId);

  function interruptTokenSale(bytes32 saleId) external;

  function allTokenSales(uint256) external view returns (bytes32);

  function feePercentage() external view returns (uint8);

  function balance(bytes32 saleId, address account) external view returns (uint256);

  function amountContributed(bytes32 saleId, address account) external view returns (uint256);

  function whitelist(bytes32) external view returns (address[] memory);
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {
  constructor(uint256 _totalSupply) ERC20("Test Token", "TT") {
    _mint(_msgSender(), _totalSupply);
  }
}