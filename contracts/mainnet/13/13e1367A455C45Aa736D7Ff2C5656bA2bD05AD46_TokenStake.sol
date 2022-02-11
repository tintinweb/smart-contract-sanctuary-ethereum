/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// File: node_modules\@openzeppelin\contracts\GSN\Context.sol

// SPDX-License-Identifier: MIT

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

// File: node_modules\@openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX-License-Identifier: MIT

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

// File: node_modules\@openzeppelin\contracts\math\SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: node_modules\@openzeppelin\contracts\utils\Address.sol

// SPDX-License-Identifier: MIT

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin\contracts\token\ERC20\ERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;





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
    using Address for address;

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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
    function _setupDecimals(uint8 decimals_) internal {
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

// File: @openzeppelin\contracts\math\SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// File: @openzeppelin\contracts\access\Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\TokenStake.sol

pragma solidity ^0.6.0;




contract TokenStake is Ownable{

    using SafeMath for uint256;

    ERC20 public token; // Address of token contract
    address public tokenOperator; // Address to manage the Stake 

    uint256 public maxMigrationBlocks; // Block numbers to complete the migration

    mapping (address => uint256) public balances; // Useer Token balance in the contract

    uint256 public currentStakeMapIndex; // Current Stake Index to avoid math calc in all methods

    struct StakeInfo {
        bool exist;
        uint256 pendingForApprovalAmount;
        uint256 approvedAmount;
        uint256 rewardComputeIndex;

        mapping (uint256 => uint256) claimableAmount;
    }

    // Staking period timestamp (Debatable on timestamp vs blocknumber - went with timestamp)
    struct StakePeriod {
        uint256 startPeriod;
        uint256 submissionEndPeriod;
        uint256 approvalEndPeriod;
        uint256 requestWithdrawStartPeriod;
        uint256 endPeriod;

        uint256 minStake;

        bool openForExternal;

        uint256 windowRewardAmount;
        
    }

    mapping (uint256 => StakePeriod) public stakeMap;

    // List of Stake Holders
    address[] stakeHolders; 

    // All Stake Holders
    //mapping(address => mapping(uint256 => StakeInfo)) stakeHolderInfo;
    mapping(address => StakeInfo) stakeHolderInfo;

    // To store the total stake in a window
    uint256 public windowTotalStake;

    // Events
    event NewOperator(address tokenOperator);

    event WithdrawToken(address indexed tokenOperator, uint256 amount);

    event OpenForStake(uint256 indexed stakeIndex, address indexed tokenOperator, uint256 startPeriod, uint256 endPeriod, uint256 approvalEndPeriod, uint256 rewardAmount);
    event SubmitStake(uint256 indexed stakeIndex, address indexed staker, uint256 stakeAmount);
    event RequestForClaim(uint256 indexed stakeIndex, address indexed staker, bool autoRenewal);
    event ClaimStake(uint256 indexed stakeIndex, address indexed staker, uint256 totalAmount);   
    event RejectStake(uint256 indexed stakeIndex, address indexed staker, address indexed tokenOperator, uint256 returnAmount);
    event AddReward(address indexed staker, uint256 indexed stakeIndex, address tokenOperator, uint256 totalStakeAmount, uint256 rewardAmount, uint256 windowTotalStake);
    event WithdrawStake(uint256 indexed stakeIndex, address indexed staker, uint256 stakeAmount);



    // Modifiers
    modifier onlyOperator() {
        require(
            msg.sender == tokenOperator,
            "Only operator can call this function."
        );
        _;
    }

    // Token Operator should be able to do auto renewal
    modifier allowSubmission() {        
        require(
            now >= stakeMap[currentStakeMapIndex].startPeriod && 
            now <= stakeMap[currentStakeMapIndex].submissionEndPeriod && 
            stakeMap[currentStakeMapIndex].openForExternal == true, 
            "Staking at this point not allowed"
        );
        _;
    }

    modifier validStakeLimit(address staker, uint256 stakeAmount) {

        uint256 stakerTotalStake;
        stakerTotalStake = stakeAmount.add(stakeHolderInfo[staker].pendingForApprovalAmount);
        stakerTotalStake = stakerTotalStake.add(stakeHolderInfo[staker].approvedAmount);

        // Check for Min Stake
        require(
            stakeAmount > 0 && 
            stakerTotalStake >= stakeMap[currentStakeMapIndex].minStake,
            "Need to have min stake"
        );
        _;

    }

    // Check for auto renewal flag update
    modifier canRequestForClaim(uint256 stakeMapIndex) {
        require(
            (stakeHolderInfo[msg.sender].approvedAmount > 0 || stakeHolderInfo[msg.sender].claimableAmount[stakeMapIndex] > 0) &&  
            now >= stakeMap[stakeMapIndex].requestWithdrawStartPeriod &&
            now <= stakeMap[stakeMapIndex].endPeriod, 
            "Update to auto renewal at this point not allowed"
        );
        _;
    }

    // Check for claim - after the end period when opted out OR after grace period when no more stake windows
    modifier allowClaimStake(uint256 stakeMapIndex) {

        uint256 graceTime;
        graceTime = stakeMap[stakeMapIndex].endPeriod.sub(stakeMap[stakeMapIndex].requestWithdrawStartPeriod);

        require(
            (now > stakeMap[stakeMapIndex].endPeriod && stakeHolderInfo[msg.sender].claimableAmount[stakeMapIndex] > 0) ||
            (now > stakeMap[stakeMapIndex].endPeriod.add(graceTime) && stakeHolderInfo[msg.sender].approvedAmount > 0), "Invalid claim request"
        );
        _;

    }

    constructor(address _token, uint256 _maxMigrationBlocks)
    public
    {
        token = ERC20(_token);
        tokenOperator = msg.sender;
        currentStakeMapIndex = 0;
        windowTotalStake = 0;
        maxMigrationBlocks = _maxMigrationBlocks.add(block.number); 
    }

    function updateOperator(address newOperator) public onlyOwner {

        require(newOperator != address(0), "Invalid operator address");
        
        tokenOperator = newOperator;

        emit NewOperator(newOperator);
    }
    
    function withdrawToken(uint256 value) public onlyOperator
    {

        // Check if contract is having required balance 
        require(token.balanceOf(address(this)) >= value, "Not enough balance in the contract");
        require(token.transfer(msg.sender, value), "Unable to transfer token to the operator account");

        emit WithdrawToken(tokenOperator, value);
        
    }

    function openForStake(uint256 _startPeriod, uint256 _submissionEndPeriod,  uint256 _approvalEndPeriod, uint256 _requestWithdrawStartPeriod, uint256 _endPeriod, uint256 _windowRewardAmount, uint256 _minStake, bool _openForExternal) public onlyOperator {

        // Check Input Parameters
        require(_startPeriod >= now && _startPeriod < _submissionEndPeriod && _submissionEndPeriod < _approvalEndPeriod && _approvalEndPeriod < _requestWithdrawStartPeriod && _requestWithdrawStartPeriod < _endPeriod, "Invalid stake period");
        require(_windowRewardAmount > 0 && _minStake > 0, "Invalid inputs" );

        // Check Stake in Progress
        require(currentStakeMapIndex == 0 || (now > stakeMap[currentStakeMapIndex].approvalEndPeriod && _startPeriod >= stakeMap[currentStakeMapIndex].requestWithdrawStartPeriod), "Cannot have more than one stake request at a time");

        // Move the staking period to next one
        currentStakeMapIndex = currentStakeMapIndex + 1;
        StakePeriod memory stakePeriod;

        // Set Staking attributes
        stakePeriod.startPeriod = _startPeriod;
        stakePeriod.submissionEndPeriod = _submissionEndPeriod;
        stakePeriod.approvalEndPeriod = _approvalEndPeriod;
        stakePeriod.requestWithdrawStartPeriod = _requestWithdrawStartPeriod;
        stakePeriod.endPeriod = _endPeriod;
        stakePeriod.windowRewardAmount = _windowRewardAmount;
        stakePeriod.minStake = _minStake;        
        stakePeriod.openForExternal = _openForExternal;

        stakeMap[currentStakeMapIndex] = stakePeriod;

        // Add the current window reward to the window total stake 
        windowTotalStake = windowTotalStake.add(_windowRewardAmount);

        emit OpenForStake(currentStakeMapIndex, msg.sender, _startPeriod, _endPeriod, _approvalEndPeriod, _windowRewardAmount);

    }

    // To add the Stake Holder
    function _createStake(address staker, uint256 stakeAmount) internal returns(bool) {

        StakeInfo storage stakeInfo = stakeHolderInfo[staker];

        // Check if the user already staked in the past
        if(stakeInfo.exist) {

            stakeInfo.pendingForApprovalAmount = stakeInfo.pendingForApprovalAmount.add(stakeAmount);

        } else {

            StakeInfo memory req;

            // Create a new stake request
            req.exist = true;
            req.pendingForApprovalAmount = stakeAmount;
            req.approvedAmount = 0;
            req.rewardComputeIndex = 0;

            // Add to the Stake Holders List
            stakeHolderInfo[staker] = req;

            // Add to the Stake Holders List
            stakeHolders.push(staker);

        }

        return true;

    }


    // To submit a new stake for the current window
    function submitStake(uint256 stakeAmount) public allowSubmission validStakeLimit(msg.sender, stakeAmount) {

        // Transfer the Tokens to Contract
        require(token.transferFrom(msg.sender, address(this), stakeAmount), "Unable to transfer token to the contract");

        _createStake(msg.sender, stakeAmount);

        // Update the User balance
        balances[msg.sender] = balances[msg.sender].add(stakeAmount);

        // Update current stake period total stake - For Auto Approvals
        windowTotalStake = windowTotalStake.add(stakeAmount); 
       
        emit SubmitStake(currentStakeMapIndex, msg.sender, stakeAmount);

    }

    // To withdraw stake during submission phase
    function withdrawStake(uint256 stakeMapIndex, uint256 stakeAmount) public {

        require(
            (now >= stakeMap[stakeMapIndex].startPeriod && now <= stakeMap[stakeMapIndex].submissionEndPeriod),
            "Stake withdraw at this point is not allowed"
        );

        StakeInfo storage stakeInfo = stakeHolderInfo[msg.sender];

        // Validate the input Stake Amount
        require(stakeAmount > 0 &&
        stakeInfo.pendingForApprovalAmount >= stakeAmount,
        "Cannot withdraw beyond stake amount");

        // Allow withdaw not less than minStake or Full Amount
        require(
            stakeInfo.pendingForApprovalAmount.sub(stakeAmount) >= stakeMap[stakeMapIndex].minStake || 
            stakeInfo.pendingForApprovalAmount == stakeAmount,
            "Can withdraw full amount or partial amount maintaining min stake"
        );

        // Update the staker balance in the staking window
        stakeInfo.pendingForApprovalAmount = stakeInfo.pendingForApprovalAmount.sub(stakeAmount);

        // Update the User balance
        balances[msg.sender] = balances[msg.sender].sub(stakeAmount);

        // Update current stake period total stake - For Auto Approvals
        windowTotalStake = windowTotalStake.sub(stakeAmount); 

        // Return to User Wallet
        require(token.transfer(msg.sender, stakeAmount), "Unable to transfer token to the account");

        emit WithdrawStake(stakeMapIndex, msg.sender, stakeAmount);
    }

    // Reject the stake in the Current Window
    function rejectStake(uint256 stakeMapIndex, address staker) public onlyOperator {

        // Allow for rejection after approval period as well
        require(now > stakeMap[stakeMapIndex].submissionEndPeriod && currentStakeMapIndex == stakeMapIndex, "Rejection at this point is not allowed");

        StakeInfo storage stakeInfo = stakeHolderInfo[staker];

        // In case of if there are auto renewals reject should not be allowed
        require(stakeInfo.pendingForApprovalAmount > 0, "No staking request found");

        uint256 returnAmount;
        returnAmount = stakeInfo.pendingForApprovalAmount;

        // transfer back the stake to user account
        require(token.transfer(staker, stakeInfo.pendingForApprovalAmount), "Unable to transfer token back to the account");

        // Update the User Balance
        balances[staker] = balances[staker].sub(stakeInfo.pendingForApprovalAmount);

        // Update current stake period total stake - For Auto Approvals
        windowTotalStake = windowTotalStake.sub(stakeInfo.pendingForApprovalAmount);

        // Update the Pending Amount
        stakeInfo.pendingForApprovalAmount = 0;

        emit RejectStake(stakeMapIndex, staker, msg.sender, returnAmount);

    }

    // To update the Auto Renewal - OptIn or OptOut for next stake window
    function requestForClaim(uint256 stakeMapIndex, bool autoRenewal) public canRequestForClaim(stakeMapIndex) {

        StakeInfo storage stakeInfo = stakeHolderInfo[msg.sender];

        // Check for the claim amount
        require((autoRenewal == true && stakeInfo.claimableAmount[stakeMapIndex] > 0) || (autoRenewal == false && stakeInfo.approvedAmount > 0), "Invalid auto renew request");

        if(autoRenewal) {

            // Update current stake period total stake - For Auto Approvals
            windowTotalStake = windowTotalStake.add(stakeInfo.claimableAmount[stakeMapIndex]);

            stakeInfo.approvedAmount = stakeInfo.claimableAmount[stakeMapIndex];
            stakeInfo.claimableAmount[stakeMapIndex] = 0;

        } else {

            // Update current stake period total stake - For Auto Approvals
            windowTotalStake = windowTotalStake.sub(stakeInfo.approvedAmount);

            stakeInfo.claimableAmount[stakeMapIndex] = stakeInfo.approvedAmount;
            stakeInfo.approvedAmount = 0;

        }

        emit RequestForClaim(stakeMapIndex, msg.sender, autoRenewal);

    }


    function _calculateRewardAmount(uint256 stakeMapIndex, uint256 stakeAmount) internal view returns(uint256) {

        uint256 calcRewardAmount;
        calcRewardAmount = stakeAmount.mul(stakeMap[stakeMapIndex].windowRewardAmount).div(windowTotalStake.sub(stakeMap[stakeMapIndex].windowRewardAmount));
        return calcRewardAmount;
    }


    // Update reward for staker in the respective stake window
    function computeAndAddReward(uint256 stakeMapIndex, address staker) 
    public 
    onlyOperator
    returns(bool)
    {

        // Check for the Incubation Period
        require(
            now > stakeMap[stakeMapIndex].approvalEndPeriod && 
            now < stakeMap[stakeMapIndex].requestWithdrawStartPeriod, 
            "Reward cannot be added now"
        );

        StakeInfo storage stakeInfo = stakeHolderInfo[staker];

        // Check if reward already computed
        require((stakeInfo.approvedAmount > 0 || stakeInfo.pendingForApprovalAmount > 0 ) && stakeInfo.rewardComputeIndex != stakeMapIndex, "Invalid reward request");


        // Calculate the totalAmount
        uint256 totalAmount;
        uint256 rewardAmount;

        // Calculate the reward amount for the current window - Need to consider pendingForApprovalAmount for Auto Approvals
        totalAmount = stakeInfo.approvedAmount.add(stakeInfo.pendingForApprovalAmount);
        rewardAmount = _calculateRewardAmount(stakeMapIndex, totalAmount);
        totalAmount = totalAmount.add(rewardAmount);

        // Add the reward amount and update pendingForApprovalAmount
        stakeInfo.approvedAmount = totalAmount;
        stakeInfo.pendingForApprovalAmount = 0;

        // Update the reward compute index to avoid mulitple addition
        stakeInfo.rewardComputeIndex = stakeMapIndex;

        // Update the User Balance
        balances[staker] = balances[staker].add(rewardAmount);

        emit AddReward(staker, stakeMapIndex, tokenOperator, totalAmount, rewardAmount, windowTotalStake);

        return true;
    }

    function updateRewards(uint256 stakeMapIndex, address[] calldata staker) 
    external 
    onlyOperator
    {
        for(uint256 indx = 0; indx < staker.length; indx++) {
            require(computeAndAddReward(stakeMapIndex, staker[indx]));
        }
    }

    // To claim from the stake window
    function claimStake(uint256 stakeMapIndex) public allowClaimStake(stakeMapIndex) {

        StakeInfo storage stakeInfo = stakeHolderInfo[msg.sender];

        uint256 stakeAmount;
        
        // General claim
        if(stakeInfo.claimableAmount[stakeMapIndex] > 0) {
            
            stakeAmount = stakeInfo.claimableAmount[stakeMapIndex];
            stakeInfo.claimableAmount[stakeMapIndex] = 0;

        } else {
            
            // No more stake windows & beyond grace period
            stakeAmount = stakeInfo.approvedAmount;
            stakeInfo.approvedAmount = 0;

            // Update current stake period total stake
            windowTotalStake = windowTotalStake.sub(stakeAmount);
        }

        // Check for balance in the contract
        require(token.balanceOf(address(this)) >= stakeAmount, "Not enough balance in the contract");

        // Update the User Balance
        balances[msg.sender] = balances[msg.sender].sub(stakeAmount);

        // Call the transfer function
        require(token.transfer(msg.sender, stakeAmount), "Unable to transfer token back to the account");

        emit ClaimStake(stakeMapIndex, msg.sender, stakeAmount);

    }


    // Migration - Load existing Stake Windows & Stakers
    function migrateStakeWindow(uint256 _startPeriod, uint256 _submissionEndPeriod,  uint256 _approvalEndPeriod, uint256 _requestWithdrawStartPeriod, uint256 _endPeriod, uint256 _windowRewardAmount, uint256 _minStake, bool _openForExternal) public onlyOperator {

        // Add check for Block Number to restrict migration after certain block number
        require(block.number < maxMigrationBlocks, "Exceeds migration phase");

        // Check Input Parameters for past stake windows
        require(now > _startPeriod && _startPeriod < _submissionEndPeriod && _submissionEndPeriod < _approvalEndPeriod && _approvalEndPeriod < _requestWithdrawStartPeriod && _requestWithdrawStartPeriod < _endPeriod, "Invalid stake period");
        require(_windowRewardAmount > 0 && _minStake > 0, "Invalid inputs" );

        // Move the staking period to next one
        currentStakeMapIndex = currentStakeMapIndex + 1;
        StakePeriod memory stakePeriod;

        // Set Staking attributes
        stakePeriod.startPeriod = _startPeriod;
        stakePeriod.submissionEndPeriod = _submissionEndPeriod;
        stakePeriod.approvalEndPeriod = _approvalEndPeriod;
        stakePeriod.requestWithdrawStartPeriod = _requestWithdrawStartPeriod;
        stakePeriod.endPeriod = _endPeriod;
        stakePeriod.windowRewardAmount = _windowRewardAmount;
        stakePeriod.minStake = _minStake;        
        stakePeriod.openForExternal = _openForExternal;

        stakeMap[currentStakeMapIndex] = stakePeriod;


    }


    // Migration - Load existing stakes along with computed reward
    function migrateStakes(uint256 stakeMapIndex, address[] calldata staker, uint256[] calldata stakeAmount) external onlyOperator {

        // Add check for Block Number to restrict migration after certain block number
        require(block.number < maxMigrationBlocks, "Exceeds migration phase");

        // Check Input Parameters
        require(staker.length == stakeAmount.length, "Invalid Input Arrays");

        // Stakers should be for current window
        require(currentStakeMapIndex == stakeMapIndex, "Invalid Stake Window Index");

        for(uint256 indx = 0; indx < staker.length; indx++) {

            StakeInfo memory req;

            // Create a stake request with approvedAmount
            req.exist = true;
            req.pendingForApprovalAmount = 0;
            req.approvedAmount = stakeAmount[indx];
            req.rewardComputeIndex = stakeMapIndex;

            // Add to the Stake Holders List
            stakeHolderInfo[staker[indx]] = req;

            // Add to the Stake Holders List
            stakeHolders.push(staker[indx]);

            // Update the User balance
            balances[staker[indx]] = stakeAmount[indx];

            // Update current stake period total stake - Along with Reward
            windowTotalStake = windowTotalStake.add(stakeAmount[indx]);

        }

    }


    // Getter Functions    
    function getStakeHolders() public view returns(address[] memory) {
        return stakeHolders;
    }

    function getStakeInfo(uint256 stakeMapIndex, address staker) 
    public 
    view
    returns (bool found, uint256 approvedAmount, uint256 pendingForApprovalAmount, uint256 rewardComputeIndex, uint256 claimableAmount) 
    {

        StakeInfo storage stakeInfo = stakeHolderInfo[staker];
        
        found = false;
        if(stakeInfo.exist) {
            found = true;
        }

        pendingForApprovalAmount = stakeInfo.pendingForApprovalAmount;
        approvedAmount = stakeInfo.approvedAmount;
        rewardComputeIndex = stakeInfo.rewardComputeIndex;
        claimableAmount = stakeInfo.claimableAmount[stakeMapIndex];

    }


}