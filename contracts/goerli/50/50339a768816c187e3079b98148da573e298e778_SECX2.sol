/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT
// SecureX (SecX) Smart Contract

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol

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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// Original ENS Domains Blacklist Contract: https://github.com/ensdomains/blacklist/blob/master/contracts/Blacklist.sol

// Modified code for brevity & versioning

// NOTE: Blacklisting is always enabled in this smart contract and will be the primary means for restricting user access. 
// Whitelisting (found below in the "Whitelisting" contract) can be toggled on and used instead if it is required to fit
// a specific use case or regulatory concerns.

pragma solidity ^0.8.0;

contract Blacklist is Ownable {

    mapping (address => bool) blacklisted;

    event Blacklisted(address indexed account);

    event Unblacklisted(address indexed account);
    
    /**
     * @dev Add an account to the blacklist.
     * @param account The account to add to the blacklist.
     */
    function blacklist(address account) public onlyOwner {
        blacklisted[account] = true;
        emit Blacklisted(account);
    }
    
    /** 
     * @dev Remove an account from the blacklist.
     * @param account The account to remove from the blacklist.
     */
    function unblacklist(address account) public onlyOwner {
        blacklisted[account] = false;
        emit Unblacklisted(account);
    }
    
    /**
     *  @dev Return true if the account is permitted, false otherwise. Every account, except the blacklisted ones, are permitted.
     *  @param account The account.
     */
    function isPermitted(address account) public view returns (bool) {
        return !blacklisted[account];
    }
}

// Modified blacklist contract code for whitelisting

pragma solidity ^0.8.0;

contract Whitelist is Ownable {

    mapping (address => bool) whitelisted;

    event Whitelisted(address indexed account);

    event Unwhitelisted(address indexed account);
    
    /**
     * @dev Add an account to the blacklist.
     * @param account The account to add to the blacklist.
     */
    function whitelist(address account) public onlyOwner {
        whitelisted[account] = true;
        emit Whitelisted(account);
    }
    
    /** 
     * @dev Remove an account from the blacklist.
     * @param account The account to remove from the blacklist.
     */
    function unwhitelist(address account) public onlyOwner {
        whitelisted[account] = false;
        emit Unwhitelisted(account);
    }
    
    /**
     *  @dev Return true if the account is whitelisted, false otherwise. Every account, except the blacklisted ones, are permitted.
     *  @param account The account.
     */
    function isWhitelisted(address account) public view returns (bool) {
        return whitelisted[account];
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

// _pause & _unpause functions modified to be public functions, callable after deployment

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
    function pause() public virtual whenNotPaused {
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
    function unpause() public virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: secx1-4.sol

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {mint}.
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


contract ERC20 is Context, IERC20, IERC20Metadata, Pausable, Blacklist, Whitelist {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;

    address[] private _excluded;

    address private feeWallet = 0xa069f077f2DeC4948DF681Cdbd30ef2249e6c3dD; // Sets initial fee wallet, can be changed later with setFeeWallet()

    uint256 private _totalSupply;
    uint256 txFee = 500; // Sets initial transaction fee on all transactions (uint256)
    uint256 percentConversion = 10000; // Correction for percentages in uint256
    bool enabled = true; //Boolean to set whether or not fees are enabled
    bool whitelistEnabled = false; //Boolean to set whether or not whitelist is enabled

    uint8 private _decimals = 8; 

    string private _name;
    string private _symbol;
    
    /**
     * Creation of non-standard events required by our contract
     */

    event FeeUpdated(bool enabled, uint256 txFee); 
    event FeeWalletUpdated(address feeWallet); 
    event WhitelistEnabled(bool whitelistEnabled);

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return (_totalSupply);
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return (_balances[account]);
    }
    
    /**
     * @dev Allows developers or users to view the current transaction fee in place on each transaction.
     * 
     * Modified to display traditional percentages instead of uint256 equivalents.
     */

    function viewFee() public view virtual returns (bool, uint256) {
        return (enabled, txFee/100);
    }
    /**
     * @dev Allows developers or users to view the current transaction fee in place on each transaction.
     */

    function viewFeeWallet() public view virtual returns (address) {
        return (feeWallet);
    }
    /**
     * @dev Allows developers or users to view if whitelisting is currently enabled.
     */

    function viewWhitelistEnabled() public view virtual returns (bool) {
        return (whitelistEnabled);
    }
    /**
     * @dev Allows developers or users to view if an account is excluded from transaction fees.
     */

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    /**
     * @dev Allows the owner to set transaction fees.
     *
     * NOTE: input must be set in full percentages between 0-99.
     *
     * e.g. 0, 1, 2, ... 99, etc
     */
    function setFee (bool _enabled, uint256 _txFee) external onlyOwner {
        enabled = _enabled;
        txFee= _txFee * 100;
        emit FeeUpdated(enabled, txFee);
    }
    /**
     * @dev Allows the owner to change the transaction fee wallet destination.
     */
    function setFeeWallet (address _feeWallet) external onlyOwner {
        feeWallet = _feeWallet;
        emit FeeWalletUpdated(feeWallet);
    }
    /**
     * @dev Allows the owner to exclude an account from transaction fees.
     */
    function excludeAccount(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    /**
     * @dev Allows the owner to include an account to require transaction fees.
     *
     * NOTE: All users are included by default.
     */
    function includeAccount(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");
        _isExcluded[account] = false;
        _excluded.push(account);
    }
    /**
     * @dev Allows to toggle on or off whitelisting in the Smart Contract.
     */
    function toggleWhitelist () external onlyOwner {
        if (whitelistEnabled != false) {
        whitelistEnabled = false;
        } else {
        whitelistEnabled = true;    
        }
        emit WhitelistEnabled(whitelistEnabled);
    }
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual whenNotPaused override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    /**
     * @dev Modified transfer function that allows the smart contract owner to transfer tokens while it is paused.
     */
    function devTransfer(address recipient, uint256 amount) public virtual onlyOwner returns (bool) {
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
     * - `sender` and `recipient` cannot be blacklisted.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual whenNotPaused override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
     * - If whitelisting is enabled: `sender` must be whitelisted.
     * - If whitelisting is enabled: `recipient` must be whitelisted.
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - `sender` and `recipient` cannot be blacklisted.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        if (whitelistEnabled == true) {
            require(!isWhitelisted(sender) == false, "Whitelisting is enabled. The sender's address is not whitelisted.");
            require(!isWhitelisted(recipient) == false, "Whitelisting is enabled. The recipient's address is not whitelisted."); }
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(isPermitted(sender) != false, "Sender's address is blacklisted");
        require(isPermitted(recipient) != false, "Recipient's address is blacklisted");
        _beforeTokenTransfer(sender, recipient, amount);
        if (_isExcluded[sender] || _isExcluded[recipient]) {
            _transferExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);  
        }
    }
    /**
     * @dev Moves tokens `amount` from `sender` to `recipient` without incurring transaction fees.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     */
    function _transferExcluded(address sender, address recipient, uint256 amount) private {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    /**
     * @dev Moves tokens `amount` from `sender` to `recipient` while incurring
     * the stated transaction fee. Not used for addresses excluded from fees.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     */
    function _transferStandard(address sender, address recipient, uint256 amount) private {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        uint256 Fee = amount / percentConversion * txFee;
        uint256 afterFee = amount - Fee;
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += afterFee;
        _balances[feeWallet] += Fee;
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
    function mint(address account, uint256 amount) public virtual onlyOwner{
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
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
    function _burn(address account, uint256 amount) internal virtual onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
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

// Original File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol

// (Modified burnFrom to review user balance, not allowance)

pragma solidity ^0.8.0;

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20  {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public onlyOwner {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the account's 
     * tokens and removing the tokens from the total supply.
     *
     * Used for burning tokens from non-deployer wallets. Note: this will not work to remove 
     * tokens from the deployer wallet.
     *
     * See {ERC20-_burn}.
     *
     * Requirements: (Modified from ERC20 burnable to review user balance, not allowance)
     *
     * - the caller must have balance for ``accounts``'s tokens to be greater than the burn
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public onlyOwner {
        uint256 balance = balanceOf(account);
        _approve(account, _msgSender(), balance - amount);
        _burn(account, amount);
    }
}

pragma solidity ^0.8.0;

contract SECX2 is ERC20, ERC20Burnable {
    constructor() ERC20("SecX Test 2.0", "SecX 2.0") {
        mint(msg.sender, 100_000_000 * 10**8 );
    }
}