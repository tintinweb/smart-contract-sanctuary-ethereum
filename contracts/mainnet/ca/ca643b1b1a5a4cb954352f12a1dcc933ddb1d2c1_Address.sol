/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
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

interface iRewards {  

  function trackAction(address account, uint256 fromBalance, address to, uint256 toBalance) external;
  function trackBuy(address account, uint256 newBalance) external;
  function trackSell(address account, uint256 newBalance) external;
  function processClaims(uint256 gasLimit) external; 
  function withdrawFunds(address payable account) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

contract GHOST is ERC20,
                  Ownable,
                  Pausable,
                  ReentrancyGuard  {
  
  using SafeMath for uint256;
  using Address for address;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  address payable public rewards;
  address payable public marketingWallet;
  address payable public BBBWallet;
  address payable public stakeContract;

  uint256 public  FINAL_SUPPLY;
  uint256 public  MAX_WALLET;
  uint256 public  MAX_SELL;

  uint256 public gasLimit;
  uint256 public swapThreshold;

  uint256 private  taxDIV;
  uint256 private  taxLIQ;
  uint256 private  taxBBB;
  uint256 private  taxTEAM;
  uint256 private  taxDEV;
  uint256 private  taxMKT;
  uint256 private  taxSTK;
  uint256 private  taxREF;

  uint8 public  buy_TEAM;
  uint8 public  buy_LIQ;
  uint8 public  buy_BBB;
  uint8 public  buy_DIV;
  uint8 public  buy_STK;
  uint8 public  fee_BUY;

  uint8 public  sell_TEAM;
  uint8 public  sell_LIQ;
  uint8 public  sell_BBB;
  uint8 public  sell_DIV;
  uint8 public  sell_STK;
  uint8 public  fee_SELL;

  uint8 public  trf_TEAM;
  uint8 public  trf_LIQ;
  uint8 public  trf_DIV;
  uint8 public  trf_BBB;
  uint8 public  trf_STK;
  uint8 public  fee_TRF;

  uint256 public lapse;

  uint8 public fee_STK;
  uint8 public penalty;
  uint32 public openingDate;

  bool public isVestingOn;
  bool public isStakingOn;
  bool public restrictionsOn;
  bool public isOpenToPublic;
  bool private swapping;

  // MAPPINGS
  mapping (address => bool) public autoMarketMakers; // Any transfer to these addresses are likely sells
  mapping (address => bool) public feeExcempt; // exclude from all fees and maxes
  mapping (address => bool) public isPresale; // can trade in PreSale
  mapping (address => bool) public banned; // can trade in PreSale

  mapping ( address => uint256) public buyStamp; 

  // EVENTS
  event StakingContractChanged(address indexed from, address indexed to);
  event FundsReceived(address indexed from, uint amount);
  event FundsSentTo(uint256 tokens, uint256 value, address sendingTo);
  event GasLimitChanged(uint256 from, uint256 to);
  event IsExcemptChanged(address indexed account, bool excluded);
  event RewardsContractChanged(address indexed from, address indexed to);
  event SetAutomatedMarketMakerPair(address indexed pair, bool active);
  event MarketCapCalculated(uint256 price, uint256 marketCap, uint256 tokens, uint256 value);

  constructor() ERC20("GhOST", "GhOST") {

    FINAL_SUPPLY =  500_000_000 ether;
    MAX_WALLET = FINAL_SUPPLY * 2 /100;
    MAX_SELL =   FINAL_SUPPLY * 5 /1000;

    gasLimit =           300_000; // GAS FOR REWARDS PROCESSING
    swapThreshold =    MAX_SELL; // CONTRACT SWAPS TO BSD

    buy_TEAM = 5;
    buy_LIQ = 2;
    buy_BBB = 1;
    buy_DIV = 0;
    buy_STK = 2;

    sell_TEAM = 6;
    sell_LIQ = 3;
    sell_BBB = 1;
    sell_DIV = 0;
    sell_STK = 2;

    trf_TEAM = 0;
    trf_LIQ = 1;
    trf_BBB = 0;
    trf_DIV = 0;   
    trf_STK = 1;   

    fee_TRF = 2;
    fee_BUY = 10;
    fee_SELL = 12;
    fee_STK = 2 ; 

    isVestingOn = false;
    isStakingOn = false;
    restrictionsOn = true;

    lapse = 5 minutes;
    penalty = 3;
    
    address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  
    IUniswapV2Router02 router = IUniswapV2Router02(ROUTER);
    uniswapV2Router = router;

    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    
    autoMarketMakers[uniswapV2Pair] = true;
    autoMarketMakers[address(uniswapV2Router)] = true;
    autoMarketMakers[address(0)] = true;


    isPresale[owner()] = true;
    feeExcempt[address(this)] = true;
    feeExcempt[owner()] = true;

    marketingWallet = payable(0xbf593EBDac07287E392640A56CebF6e3e3dD59eC);
    rewards = payable(0xbf593EBDac07287E392640A56CebF6e3e3dD59eC);
    stakeContract = payable(0xbf593EBDac07287E392640A56CebF6e3e3dD59eC);
    BBBWallet = payable(0xbf593EBDac07287E392640A56CebF6e3e3dD59eC);

    _mint(owner(), FINAL_SUPPLY);
  }

  receive() external payable {
    emit FundsReceived(msg.sender, msg.value);
  }

  function _beforeTokenTransfer( address from, address to, uint256 amount) whenNotPaused internal override virtual {
 
        require( !banned[from] && !banned[to], 'Banned' );

        bool canSwap = balanceOf(address(this)) >= swapThreshold;

        if( canSwap &&
            !swapping &&
            !autoMarketMakers[from] &&
            from != owner() &&
            to != owner() ) {     

          swapping = true;
          if ( taxDIV > 0 ){
              swapSendTo(taxDIV, rewards);
              taxDIV = 0 ;
              }

          if ( taxLIQ > 0 ) {
            swapLiquify(taxLIQ);
            taxLIQ = 0;
            }

          if ( taxTEAM > 0 ) {
              swapSendTo(taxTEAM, marketingWallet);
              taxTEAM = 0 ;
              }

          if ( taxTEAM > 0 ) {
              super._transfer(from, BBBWallet, taxBBB);
              taxBBB = 0 ;
              }

          if ( taxSTK > 0 ) {
              swapSendTo(taxSTK, stakeContract);
              taxSTK = 0 ;
              } 

          swapping = false;
        }
    }

  function _transfer(address from, address to, uint256 amount) internal override {

    if (!feeExcempt[from] || !feeExcempt[to] )
        amount -= computeTax(from, to , amount);

    super._transfer(from, to, amount);

  }

  function burning(address from, uint256 amount) public {
    
    amount -= computeTax(from, address(0), amount);

    super._burn(from,amount);
  }
  function computeTax(address from, address to, uint256 amount) internal returns (uint256) {

    uint8 _TEAM;
    uint8 _LIQ;
    uint8 _BBB;
    uint8 _DIV;
    uint8 _STK;

    uint256 fees = 0 ;    

    if (autoMarketMakers[from]) { // buy
      require(balanceOf(to).add(amount) <= MAX_WALLET, "Wallet over limit");

      fees = fee_BUY ;
      _TEAM = buy_TEAM;
      _LIQ = buy_LIQ;
      _BBB = buy_BBB;
      _DIV = buy_DIV;
      _STK = buy_STK;
      buyStamp[to] = block.timestamp + lapse;
    } else if (!autoMarketMakers[to]) {   // transfer
        fees = fee_TRF ;
        _TEAM = trf_TEAM;
        _LIQ = trf_LIQ;
        _DIV = trf_DIV;
        _STK = trf_DIV;
        } 
        else 
          {          //Sell / burn
          
          require( amount < MAX_SELL );

          if ( ! isOpenToPublic || buyStamp[from] < block.timestamp)  {
            fees = fee_SELL * penalty ;
            _TEAM = sell_TEAM * penalty;
            _LIQ = sell_LIQ * penalty;
            _BBB = sell_BBB * penalty;
            _DIV = sell_DIV * penalty;
            _STK = sell_STK * penalty ;
            } 
            else 
              {
              fees = fee_SELL ;
              _TEAM = sell_TEAM;
              _LIQ = sell_LIQ;
              _BBB = sell_BBB;
              _DIV = sell_DIV;
              _STK = sell_STK;
              }
          }
  
    taxTEAM += amount.mul(_TEAM).div(100);
    taxDIV += amount.mul(_DIV).div(100);
    taxSTK += amount.mul(_STK).div(100);
    taxBBB += amount.mul(_BBB).div(100);
    taxLIQ += amount.mul(_LIQ).div(100);
    
    return amount * fees / 100 ;
  }
  function _afterTokenTransfer( address from, address to, uint256 amount) internal override virtual {
    super._afterTokenTransfer( from, to, amount);

    process();
        //try iRewards(rewards).trackAction(from, balanceOf(from),to, balanceOf(to)) {} catch {}

  }

  function swapLiquify(uint256 _taxLIQ) nonReentrant internal{
      uint256 half = _taxLIQ / 2;
      uint256 swappedETH = swapTokensForETH(half);
      addLiquidity(half, swappedETH);
  }
  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.addLiquidityETH{value: ethAmount}(
      address(this), 
      tokenAmount, 
      0, 
      0, 
      payable(owner()), 
      block.timestamp);
  }
  function swapSendTo(uint256 tokens, address sendingTo) nonReentrant private {
    if ( tokens > 0 ){
        uint256 swappedETH = swapTokensForETH(tokens);
        if (swappedETH > 0) {
            (bool success,) = sendingTo.call{value: swappedETH}("");
            if (success) 
            emit FundsSentTo(tokens, swappedETH, sendingTo);
          }
    }
  }
  function swapTokensForETH(uint256 tokens) private returns(uint256) {
    address[] memory pair = new address[](2);
    pair[0] = address(this);
    pair[1] = uniswapV2Router.WETH();
    _approve(address(this), address(uniswapV2Router), tokens);
    uint256 currentETH = address(this).balance;
    uniswapV2Router.swapExactTokensForETH(tokens, 0, pair, address(this), block.timestamp);
    return address(this).balance.sub(currentETH);
  }

  function process() private {

    if (!isContract(rewards)) 
        try iRewards(rewards).processClaims(gasLimit) {} catch {}
  
    if (!isContract(stakeContract)) 
        try iRewards(stakeContract).processClaims(gasLimit) {} catch {}
  }


  function stake(address from,uint256 amount) external nonReentrant{

      require(isStakingOn);
        super._transfer(from, stakeContract, amount);
        try iRewards(stakeContract).trackBuy(from, amount) {} catch {}
        process();
    }
  function claim(address from) external {
      require(isStakingOn);
    }
  function withdraw(address from) external {
      require(isStakingOn);
  }
  function unstake(address from,uint256 amount) external nonReentrant {

      require(isStakingOn);

      uint256 fees =  taxSTK += amount.mul(fee_STK).div(100);
      taxSTK += fees;
      amount -= fees;

      super._transfer(stakeContract, from, amount);
      super._transfer(stakeContract, address(this), fees);

      try iRewards(stakeContract).trackSell(from, amount) {} catch {}
      process();
  }
  function setMax(uint256 _maxWallet,uint256 _maxSell) public onlyOwner {
        MAX_WALLET = _maxWallet * 1 ether;
        MAX_SELL = _maxSell * 1 ether;
    }
  function openToPublic() external onlyOwner {
    require(!isOpenToPublic, "Value unchanged");

    MAX_WALLET = FINAL_SUPPLY * 2 /100;
    MAX_SELL =   FINAL_SUPPLY * 5 /1000;

    isVestingOn = false;
    isStakingOn = false;

    openingDate = stamp(); //block.timestamp;
    isOpenToPublic = true;
  }
  function setAutomatedMarketMakerPair(address pair, bool setting) external onlyOwner {
    require(pair != uniswapV2Pair, "Value invalid");
    require(autoMarketMakers[pair] != setting, "Value unchanged");

    autoMarketMakers[pair] = setting;
    emit SetAutomatedMarketMakerPair(pair, setting);
  }
  function setFeeExcempt(address account, bool setting) external onlyOwner {
    require(feeExcempt[account]!=setting, "Value unchanged");

    feeExcempt[account] = setting;
    emit IsExcemptChanged(account, setting);
  }
  function setGasLimit(uint256 gas) external onlyOwner {
    require(gas >= 250_000 && gas <= 750_000, "Value invalid");
    require(gas != gasLimit, "Value unchanged");

    emit GasLimitChanged(gasLimit, gas);
    gasLimit = gas;
  }
  function setRewardsContract(address newContract) external onlyOwner {
    require(newContract != rewards, "Value unchanged");
    require(isContract(newContract), "Not a contract");
    require(Ownable(newContract).owner() == address(this), "Token must own tracker");

    if (isContract(rewards)) Ownable(rewards).transferOwnership(owner());
    emit RewardsContractChanged(rewards, newContract);
    rewards = payable(newContract);
  }
  function setStakingContract(address newContract) external onlyOwner {
      require(newContract != rewards, "Value unchanged");
      require(isContract(newContract), "Not a contract");
      require(Ownable(newContract).owner() == address(this), "Token must own tracker");

      if (isContract(stakeContract)) Ownable(stakeContract).transferOwnership(owner());
      emit StakingContractChanged(stakeContract, newContract);
      stakeContract = payable(newContract);
  }
  function isContract(address key) private view returns (bool) {
    return key.code.length > 0;
  }
  function stamp() private view returns (uint32) {
    return uint32(block.timestamp); // - 1231006505 seconds past BTC epoch
  }
  function setSellFees(uint8 _TEAM, uint8 _LIQ, uint8 _BBB, uint8 _DIV, uint8 _STK) external onlyOwner {
      
      fee_SELL = _TEAM + _LIQ + _BBB + _DIV + _STK;

      require(fee_SELL < 16 , "sell tax must be less than 15");      

      sell_TEAM = _TEAM;
      sell_LIQ = _LIQ;
      sell_BBB = _BBB;
      sell_DIV = _DIV;
      sell_STK = _STK;

  }
  function setBuyFees(uint8 _TEAM, uint8 _LIQ, uint8 _BBB, uint8 _DIV, uint8 _STK) external onlyOwner {
      
      fee_BUY = _TEAM + _LIQ + _BBB + _DIV + _STK;

      require(fee_BUY < 16 , "buy tax must be less than 15");      

      buy_TEAM = _TEAM;
      buy_LIQ = _LIQ;
      buy_BBB = _BBB;
      buy_DIV = _DIV;
      buy_STK = _STK;

  }
  function setTrfFees(uint8 _TEAM, uint8 _LIQ, uint8 _BBB, uint8 _DIV, uint8 _STK) external onlyOwner {
      
      fee_TRF = _TEAM + _LIQ + _BBB + _DIV + _STK;

      require(fee_TRF < 10, "trf tax must be less than 15");      

      trf_TEAM = _TEAM;
      trf_LIQ = _LIQ;
      trf_BBB = _BBB;
      trf_DIV = _DIV;
      trf_STK = _STK;
  }
  function setLapseRestrictions( bool _restrictions, uint256 _lapse, uint8 _penalty) public onlyOwner {
    lapse = _lapse * 1 minutes;
    penalty = _penalty;
    restrictionsOn = _restrictions;
  }
  function setBanned(address who,bool _banned) external onlyOwner {
    banned[who] = _banned;
  }
}