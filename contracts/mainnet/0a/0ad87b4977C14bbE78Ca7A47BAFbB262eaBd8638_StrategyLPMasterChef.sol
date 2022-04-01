/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT

// File contracts/autocompounder/common/IMasterChef.sol

// File: contracts/BIFI/interfaces/pancake/IMasterChef.sol

pragma solidity ^0.8.0;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);
    function emergencyWithdraw(uint256 _pid) external;

    // pending* function changes names often (e.g. pendingYEL, pendingReward).
    // This is only called in the tests, so no need to include it in the contract's interface
    // function pendingCake(uint256 _pid, address _user) external view returns (uint256);

}


// File contracts/autocompounder/common/Context.sol

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.8.0;

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/autocompounder/common/IERC20.sol

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.8.0;

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


// File contracts/autocompounder/common/Ownable.sol

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;
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
    constructor () {
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


// File contracts/autocompounder/common/Address.sol

// File: @openzeppelin/contracts/utils/Address.sol


pragma solidity ^0.8.0;

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


// File contracts/autocompounder/common/ERC20.sol

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.8.0;
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
     *
     * #ANDREW: arguments name/symbols to nameFoo/SymbolFoo to avoid "This declaration shadows an existing declaration." warning
     **/
    constructor (string memory nameFoo, string memory symbolFoo) {
        _name = nameFoo;
        _symbol = symbolFoo;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
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

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
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

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
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

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
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


// File contracts/autocompounder/common/SafeERC20.sol

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.8.0;
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
        uint256 newAllowance = token.allowance(address(this), spender) +  value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
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


// File contracts/autocompounder/common/Pausable.sol

// File: @openzeppelin/contracts/utils/Pausable.sol

pragma solidity ^0.8.0;
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
        _;
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


// File contracts/autocompounder/common/FullMath.sol

// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/FullMath.sol
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = (type(uint256).max - denominator + 1) & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}


// File contracts/autocompounder/common/IUniswapRouterETH.sol

// File: contracts/BIFI/interfaces/common/IUniswapRouterETH.sol

pragma solidity ^0.8.0;

interface IUniswapRouterETH {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    // For TraderJoeRouter on AVAX, needed for UnirouterShim.sol
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


// File contracts/autocompounder/common/IUniswapV2Pair.sol

// File: contracts/BIFI/interfaces/common/IUniswapV2Pair.sol
pragma solidity ^0.8.0;

interface IUniswapV2Pair is IERC20 {
    function token0() external view returns (address);
    function token1() external view returns (address);
}


// File contracts/autocompounder/common/StratManager.sol

pragma solidity ^0.8.0;
contract StratManager is Ownable, Pausable {
    /**
     * @dev Crack Contracts:
     * {keeper} - Address to manage a few lower risk features of the strat
     * {strategist} - Address of the strategy author/deployer where strategist fee will go.
     * {vault} - Address of the vault that controls the strategy's funds.
     * {unirouter} - Address of exchange to execute swaps.
     */
    address public keeper;
    address public strategist;
    address public unirouter;
    address public vault;
    /**
     * @dev Initializes the base strategy.
     * @param _keeper address to use as alternative owner.
     * @param _strategist address where strategist fees go.
     * @param _unirouter router to use for swaps
     * @param _vault address of parent vault.
     */
    constructor(
        address _keeper,
        address _strategist,
        address _unirouter,
        address _vault
    ) {
        keeper = _keeper;
        strategist = _strategist;
        unirouter = _unirouter;
        vault = _vault;
    }

    // checks that caller is either owner or keeper.
    modifier onlyManager() {
        require(msg.sender == owner() || msg.sender == keeper, "!manager");
        _;
    }

    // verifies that the caller is not a contract.
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "!EOA");
        _;
    }

    /**
     * @dev Updates address of the strat keeper.
     * @param _keeper new keeper address.
     */
    function setKeeper(address _keeper) external onlyManager {
        keeper = _keeper;
    }

    /**
     * @dev Updates address where strategist fee earnings will go.
     * @param _strategist new strategist address.
     */
    function setStrategist(address _strategist) external {
        require(msg.sender == strategist, "!strategist");
        strategist = _strategist;
    }

    /**
     * @dev Updates router that will be used for swaps.
     * @param _unirouter new unirouter address.
     */
    function setUnirouter(address _unirouter) external onlyOwner {
        unirouter = _unirouter;
    }

    /**
     * @dev Updates parent vault.
     * @param _vault new vault address.
     */
    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    /**
     * @dev Function to synchronize balances before new user deposit.
     * Can be overridden in the strategy.
     */
    function beforeDeposit() external virtual {}
}


// File contracts/autocompounder/common/FeeManager.sol

pragma solidity ^0.8.0;
abstract contract FeeManager is StratManager {
    uint constant public MAXFEE = 1000;
    uint public withdrawalFee = 0; // fee taken out on withdraw
    uint public strategistFee = 69; // 6.9% stratigest fee
    uint public sideProfitFee = 0; // amount of rewardToken swapped to stable
    uint public callFee = 4; // .4% fee paid to caller

    function setWithdrawalFee(uint256 _fee) external onlyManager {
        require(_fee <= MAXFEE, "fee too high");
        withdrawalFee = _fee;
    }

    function setStratFee(uint256 _fee) external onlyManager {
        require(_fee < MAXFEE, "fee too high");
        strategistFee = _fee;
    }

    function setProfitFees(uint256 _fee) external onlyManager {
      require(_fee < MAXFEE, "fee too high");
      sideProfitFee = _fee;
    }

    function setCallFee(uint256 _fee) external onlyManager {
        require(_fee < MAXFEE, "fee too high");
        callFee = _fee;
    }
}


// File contracts/autocompounder/LP-Strategy/StrategyLPBase.sol

pragma solidity ^0.8.0;
//import "hardhat/console.sol";

abstract contract StrategyLPBase is StratManager, FeeManager {
    using SafeERC20 for IERC20;
    using SafeERC20 for IUniswapV2Pair;

    // Tokens
    IERC20 public swapToken;
    IERC20 public rewardToken;
    IUniswapV2Pair public stakedToken;
    IERC20 public lpAsset0;
    IERC20 public lpAsset1;
    IERC20 public sideProfitToken;

    // Routes
    address[] public rewardTokenToLp0Route;
    address[] public rewardTokenToLp1Route;
    address[] public rewardTokenToProfitRoute;

    uint256 MAX_INT = type(uint256).max;
    uint256 public lastHarvest;

    // Event that is fired each time someone harvests the strat.
    event StratHarvest(address indexed harvester);

    // Virtual functions should be overwritten by derived contracts.
    function farmAddress() public virtual returns (address) {}
    function setFarmAddress(address newAddr) internal virtual {}
    function farmDeposit(uint256 amount) internal virtual {}
    function farmWithdraw(uint256 amount) internal virtual {}
    function farmEmergencyWithdraw() internal virtual {}
    function beforeHarvest() internal virtual {}
    function balanceOfPool() public view virtual returns (uint256) {}
    function giveAllowances() internal virtual {}
    function removeAllowances() internal virtual {}
    function resetValues(address _swapToken, address _rewardToken, address _farmAddr, address _lpToken, uint256 _poolId, address _sideProfitToken) public virtual {}

    constructor(
        address _swapToken, // Should be what rewardToken gets routed through when swapping for profit and LP halves.
        address _rewardToken, // rewardToken Token
        address _lpToken, // LP Token
        address _vault, // Crack Vault that uses this strategy
        address _unirouter, // Unirouter on this chain to call for swaps
        address _keeper, // address to use as alternative owner
        address _strategist, // address where strategist fees go
        address _sideProfitToken // address of sideProfitToken token
    ) StratManager(_keeper, _strategist, _unirouter, _vault) {
        swapToken = IERC20(_swapToken);
        rewardToken = IERC20(_rewardToken);
        stakedToken = IUniswapV2Pair(_lpToken);
        lpAsset0 = IERC20(stakedToken.token0());
        lpAsset1 = IERC20(stakedToken.token1());
        sideProfitToken = IERC20(_sideProfitToken);

        if (swapToken == sideProfitToken) {
            rewardTokenToProfitRoute = [address(rewardToken), address(sideProfitToken)];
        } else {
            rewardTokenToProfitRoute = [address(rewardToken), address(swapToken), address(sideProfitToken)];
        }

        if (lpAsset0 == swapToken) {
            rewardTokenToLp0Route = [address(rewardToken), address(swapToken)];
        } else if (lpAsset0 != rewardToken) {
            rewardTokenToLp0Route = [address(rewardToken), address(swapToken), address(lpAsset0)];
        }

        if (lpAsset1 == swapToken) {
            rewardTokenToLp1Route = [address(rewardToken), address(swapToken)];
        } else if (lpAsset1 != rewardToken) {
            rewardTokenToLp1Route = [address(rewardToken), address(swapToken), address(lpAsset1)];
        }
    }

    // puts the funds to work
    function deposit() public whenNotPaused {
        uint256 lpTokenBal = stakedToken.balanceOf(address(this));
        if (lpTokenBal > 0) {
            farmDeposit(lpTokenBal);
        }
    }

    function beforeDeposit() external override whenNotPaused {
        //_harvestInternal();
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, "!vault");

        uint256 lpTokenBal = stakedToken.balanceOf(address(this));

        if (lpTokenBal < _amount) {
            farmWithdraw(_amount - lpTokenBal);
            lpTokenBal = stakedToken.balanceOf(address(this));
        }

        if (lpTokenBal > _amount) {
            lpTokenBal = _amount;
        }

        if (tx.origin == owner() || paused()) {
            stakedToken.safeTransfer(vault, lpTokenBal);
        } else {
            uint256 withdrawalFeeAmount = ((lpTokenBal * withdrawalFee) / MAXFEE);
            stakedToken.safeTransfer(vault, lpTokenBal - withdrawalFeeAmount);
        }
    }

    // compounds earnings and charges performance fee
    function harvest() external whenNotPaused onlyEOA {
        _harvestInternal();
    }

    function _harvestInternal() internal whenNotPaused {
        beforeHarvest();

        chargeFees();
        addLiquidity();
        deposit();

        lastHarvest = block.timestamp;
        emit StratHarvest(msg.sender);
    }

    function chargeFees() internal {
        uint256 totalFee = (strategistFee + sideProfitFee + callFee);
        require (totalFee < 1000, "fees too high");
        uint256 toProfit = FullMath.mulDiv(rewardToken.balanceOf(address(this)), totalFee, MAXFEE);
        if (toProfit > 0)
        {
            IUniswapRouterETH(unirouter).swapExactTokensForTokens(toProfit, 0, rewardTokenToProfitRoute, address(this), block.timestamp);
            uint256 sideProfitBalance = sideProfitToken.balanceOf(address(this));
            sideProfitToken.safeTransfer(msg.sender, FullMath.mulDiv(sideProfitBalance, callFee, totalFee));
            sideProfitToken.safeTransfer(strategist, FullMath.mulDiv(sideProfitBalance, strategistFee, totalFee));
            sideProfitToken.safeTransfer(vault, FullMath.mulDiv(sideProfitBalance, sideProfitFee, totalFee));
        }
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 rewardTokenHalf = rewardToken.balanceOf(address(this)) / 2;
        if (rewardTokenHalf > 0)
        {
            if (lpAsset0 != rewardToken) {
                IUniswapRouterETH(unirouter).swapExactTokensForTokens(rewardTokenHalf, 0, rewardTokenToLp0Route, address(this), block.timestamp);
            }

            if (lpAsset1 != rewardToken) {
                IUniswapRouterETH(unirouter).swapExactTokensForTokens(rewardTokenHalf, 0, rewardTokenToLp1Route, address(this), block.timestamp);
            }
        }
        uint256 lp0Bal = lpAsset0.balanceOf(address(this));
        uint256 lp1Bal = lpAsset1.balanceOf(address(this));
        if ((lp0Bal > 0) && (lp1Bal > 0))
        {
            IUniswapRouterETH(unirouter).addLiquidity(address(lpAsset0), address(lpAsset1), lp0Bal, lp1Bal, 1, 1, address(this), block.timestamp);
        }
    }

    // calculate the total underlaying 'lpToken' held by the strat.
    function totalBalanceOfStaked() public view returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    // it calculates how much 'lpToken' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return stakedToken.balanceOf(address(this));
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        require(msg.sender == vault, "!vault");

        farmEmergencyWithdraw();

        uint256 lpTokenBal = stakedToken.balanceOf(address(this));
        stakedToken.transfer(vault, lpTokenBal);
    }

    /**
     * @dev Rescues random funds stuck that the strat can't handle.
     * @param _token address of the token to rescue.
     */
    function inCaseTokensGetStuck(address _token) external onlyManager {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public onlyManager {
        pause();
        farmEmergencyWithdraw();
    }

    function pause() public onlyManager {
        _pause();
        removeAllowances();
    }

    function unpause() external onlyManager {
        _unpause();
        giveAllowances();
        deposit();
    }
}


// File contracts/autocompounder/LP-Strategy/StrategyLPMasterChef.sol

pragma solidity ^0.8.0;
//import "hardhat/console.sol";

contract StrategyLPMasterChef is StrategyLPBase {
    using SafeERC20 for IERC20;

    uint256 public poolId;
    IMasterChef farm;

    constructor(
        uint256 _poolId,
        address _farm,
        address _swapToken, // intermediary swap Token
        address _rewardToken, // rewardToken Token
        address _lpToken, // LP Token
        address _vault, // Crack Vault that uses this strategy
        address _unirouter, // Unirouter on this chain to call for swaps
        address _keeper, // address to use as alternative owner.
        address _strategist, // address where strategist fees go.
        address _sideProfit // address of sideProfit token
    ) StrategyLPBase(
        _swapToken,
        _rewardToken,
        _lpToken,
        _vault,
        _unirouter,
        _keeper,
        _strategist,
        _sideProfit
    ) {
        poolId = _poolId;
        farm = IMasterChef(_farm);
        giveAllowances();
    }

    function farmAddress() public view override(StrategyLPBase) returns (address) {
        return address(farm);
    }
    function setFarmAddress(address newAddr) internal override(StrategyLPBase) {
        farm = IMasterChef(newAddr);
    }

    function farmWithdraw(uint256 _amount) internal override(StrategyLPBase) {
        farm.withdraw(poolId, _amount);
    }

    function balanceOfPool() public view override(StrategyLPBase) returns (uint256) {
        (uint256 _amount, ) = farm.userInfo(poolId, address(this));
        return _amount;
    }

    function beforeHarvest() internal override(StrategyLPBase) {
        farm.deposit(poolId, 0);
    }

    function farmEmergencyWithdraw() internal override(StrategyLPBase) {
        farm.emergencyWithdraw(poolId);
    }

    function farmDeposit(uint256 amount) internal whenNotPaused override(StrategyLPBase) {
        farm.deposit(poolId, amount);
    }

    function giveAllowances() internal override(StrategyLPBase) {
        IERC20(stakedToken).safeApprove(farmAddress(), MAX_INT);
        rewardToken.safeApprove(address(unirouter), MAX_INT);
        sideProfitToken.safeApprove(address(unirouter), MAX_INT);

        lpAsset0.safeApprove(address(unirouter), 0);
        lpAsset0.safeApprove(address(unirouter), MAX_INT);

        lpAsset1.safeApprove(address(unirouter), 0);
        lpAsset1.safeApprove(address(unirouter), MAX_INT);
    }

    function removeAllowances() internal override(StrategyLPBase) {
        IERC20(stakedToken).safeApprove(farmAddress(), 0);
        rewardToken.safeApprove(address(unirouter), 0);
        sideProfitToken.safeApprove(address(unirouter), 0);
        lpAsset0.safeApprove(address(unirouter), 0);
        lpAsset1.safeApprove(address(unirouter), 0);
    }

    function resetValues(address _swapToken, address _rewardToken, address _farmAddr, address _lpToken, uint256 _poolId, address _sideProfitToken) public onlyOwner override(StrategyLPBase) {
        removeAllowances();
        swapToken = IERC20(_swapToken);
        rewardToken = IERC20(_rewardToken);
        setFarmAddress(_farmAddr);
        stakedToken = IUniswapV2Pair(_lpToken);
        lpAsset0 = IERC20(stakedToken.token0());
        lpAsset1 = IERC20(stakedToken.token1());
        sideProfitToken = IERC20(_sideProfitToken);
        poolId = _poolId;

        if (swapToken == sideProfitToken) {
            rewardTokenToProfitRoute = [address(rewardToken), address(sideProfitToken)];
        } else {
            rewardTokenToProfitRoute = [address(rewardToken), address(swapToken), address(sideProfitToken)];
        }

        if (lpAsset0 == swapToken) {
            rewardTokenToLp0Route = [address(rewardToken), address(swapToken)];
        } else if (lpAsset0 != rewardToken) {
            rewardTokenToLp0Route = [address(rewardToken), address(swapToken), address(lpAsset0)];
        }

        if (lpAsset1 == swapToken) {
            rewardTokenToLp1Route = [address(rewardToken), address(swapToken)];
        } else if (lpAsset1 != rewardToken) {
            rewardTokenToLp1Route = [address(rewardToken), address(swapToken), address(lpAsset1)];
        }
        giveAllowances();
    }
}