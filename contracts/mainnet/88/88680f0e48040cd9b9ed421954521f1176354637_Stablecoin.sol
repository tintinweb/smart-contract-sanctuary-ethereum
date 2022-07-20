/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

/*
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

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
contract ERC20 is Context, IERC20, IERC20Metadata {
    event Name(string name);
    event Symbol(string symbol);
    event Describe(string description);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string internal _name;
    string internal _symbol;
    string internal _description;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function initializeERC20(string memory name_, string memory symbol_, uint8 decimals_) internal {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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
    * @notice Returns the '_description' of the token
    * @return '_description'
    */
    function description() public view returns (string memory) {
      return _description;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeExecution(recipient);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _beforeExecution(spender);

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

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
    function _beforeExecution(
        address destination
    ) internal virtual {}
}

/**
 * @title ProxyOwnable
 * @author Amir Shirif Telcoin, LLC.
 * @dev Implements Openzeppelin Audited Contracts
 * @notice Provides simple ownership properties to a contract. Compatible with proxies
 */
abstract contract ProxyOwnable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @notice Creates contract, caller is original owner
   * @param owner_ address is original owner
   */
  function createOwner(address owner_) internal {
    _setOwner(owner_);
  }

  /**
   * @notice Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
      return _owner;
  }

  /**
   * @notice Prevents any non-owner from performing restricted function calls
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
      require(owner() == _msgSender(), "ProxyOwnable: caller is not the owner");
      _;
  }

  /**
   * @notice Transfers ownership of the contract to a new account (`newOwner`).
   * @dev Can only be called by the current owner.
   * @param newOwner is the address receiving ownership
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
      require(newOwner != address(0), "ProxyOwnable: new owner cannot be the zero address");
      _setOwner(newOwner);
  }

  /**
   * @notice reasignes ownership
   *
   * Emits a {OwnershipTransferred} event.
   */
  function _setOwner(address newOwner) private {
      address oldOwner = _owner;
      _owner = newOwner;
      emit OwnershipTransferred(oldOwner, newOwner);
  }
}

/**
 * @title IMintable
 * @author Amir Shirif Telcoin, LLC.
 * @dev Implements Openzeppelin Audited Contracts
 * @notice Provides the ability for an ERC20 token to increase its total supply
 */
interface IMintable {
  /**
   * @notice Introduces tokens into circulation
   * @param 'amount' the quantity that is to be added
   * @return a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Mint} event.
   */
  function mint(uint256 amount) external returns (bool);

  /**
   * @notice Introduces tokens into circulation at the address provided
   * @param 'account' the recipient of the newly minted tokens
   * @param 'amount' the quantity that is to be added
   * @return a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Mint} event.
   */
  function mintTo(address account, uint256 amount) external returns (bool);
}

/**
 * @title IBurnable
 * @author Amir Shirif Telcoin, LLC.
 * @dev Implements Openzeppelin Audited Contracts
 * @notice Provides the ability for an ERC20 token to decrease its total supply
 */
interface IBurnable {
  /**
   * @notice Removes tokens from circulation from the owner's address
   * @param 'amount' is the quantity that is to be removed
   * @return a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Burn} event.
   */
  function burn(uint256 amount) external returns (bool);

  /**
   * @notice Removes tokens from circulation from a source other than token owner, with owner's approval
   * @param 'account' the address the tokens are being burned from
   * @param 'amount' the quantity that is to be removed
   * @return a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Burn} event.
   */
  function burnFrom(address account, uint256 amount) external returns (bool);
}

/**
 * @title IBlacklist
 * @author Amir Shirif Telcoin, LLC.
 * @dev Implements Openzeppelin Audited Contracts
 * @notice Provides the ability for an ERC20 token to blacklist an address
 */
interface IBlacklist {
  /**
  * @notice Returns a boolean representing that an address is blacklisted
  * @param holder is the address being evaluated
  * @return true if the address is blacklisted
  */
  function blacklisted(address holder) external view returns (bool);

  /**
  * @notice Adds an address to the mapping of blacklisted addresses
  * @dev Intended to trigger a call to removeBlackFunds()
  * @param holder is the address being added to the blacklist
  * @return a boolean value indicating whether the operation succeeded.
  *
  * Emits a {AddedBlacklist} event.
  */
  function addBlackList(address holder) external returns (bool);

  /**
  * @notice Removes an address to the mapping of blacklisted addresses
  * @param holder is the address being removed from the blacklist
  * @return a boolean value indicating whether the operation succeeded.
  *
  * Emits a {RemovedBlacklist} event.
  */
  function removeBlackList(address holder) external returns (bool);

  /**
   * @dev Emitted when the address of a `holder` is added to the blacklist by
   * a call to {addBlackList}. `holder` is the blacklist address
   */
  event AddedBlacklist(address holder);

  /**
   * @dev Emitted when the address of a `holder` is removed to the blacklist by
   * a call to {removeBlackList}. `holder` is the blacklist address
   */
  event RemovedBlacklist(address holder);
}

/**
 * @title Stablecoin
 * @author Amir Shirif Telcoin, LLC.
 * @dev Implements Openzeppelin Audited Contracts
 *
 * @notice This is an ERC20 standard coin with advanced capabilities to allow for
 * minting and burning. This coin is pegged to a fiat currency and its value is
 * intended to reflect the value of its native currency
 * @dev Blacklisting has been included to prevent this currency from being used for illicit or nefarious activities
 * @dev Ownership allows for the appropriate minting or burning of tokens, as well as, blacklisting
 */
contract Stablecoin is Initializable, ERC20, ProxyOwnable, IMintable, IBurnable, IBlacklist {
  mapping (address => bool) private _blacklist;

  /**
   * @notice initializes the contract
   * @dev this function is called with proxy deployment to update state data
   * @dev uses initializer modifier to only allow one initialization per proxy
   * @param name_ is a string representing the token name
   * @param symbol_ is a string representing the token symbol
   * @param decimal_ is an int representing the number of decimals for the token
   * @param owner_ is the address of the token
   * @return a boolean value indicating whether the operation succeeded.
   */
  function initialize(string memory name_, string memory symbol_, uint8 decimal_, address owner_) external initializer() returns (bool) {
    initializeERC20(name_, symbol_, decimal_);
    createOwner(owner_);
    return true;
  }

 /**
  * @notice Updates the _name field to a new string
  * @dev Only an owner is allowed to make this function call
  * @param name_ is the new _name
  * @return a boolean value indicating whether the operation succeeded.
  */
  function updateName(string memory name_) external onlyOwner() returns (bool) {
    _name = name_;
    emit Name(_name);
    return true;
  }

 /**
  * @notice Updates the _symbol field to a new string
  * @dev Only an owner is allowed to make this function call
  * @param symbol_ is the new _symbol
  * @return a boolean value indicating whether the operation succeeded.
  */
  function updateSymbol(string memory symbol_) external onlyOwner() returns (bool) {
    _symbol = symbol_;
    emit Symbol(_symbol);
    return true;
  }

 /**
  * @notice Updates the _description field to a new string
  * @dev Only an owner is allowed to make this function call
  * @param description_ is the new _description
  * @return a boolean value indicating whether the operation succeeded.
  */
  function updateDescription(string memory description_) external onlyOwner() returns (bool) {
    _description = description_;
    emit Describe(_description);
    return true;
  }

  /**
   * @notice introduces tokens into circulation
   * @dev See {IMintable-mint}.
   * @dev Only an owner is allowed to make this function call
   * @param amount the quantity that is to be added
   * @return a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function mint(uint256 amount) external override onlyOwner() returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }

  /**
   * @notice introduces tokens into circulation at the address provided
   * @dev See {IMintable-mintTo}.
   * @dev Only an owner is allowed to make this function call
   * @param account the recipient of the newly minted tokens
   * @param amount the quantity that is to be added
   * @return a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function mintTo(address account, uint256 amount) external override onlyOwner() returns (bool) {
    _mint(account, amount);
    return true;
  }

  /**
   * @notice Removes tokens from circulation from the owner's address
   * @dev See {IBurnable-burn}.
   * @dev Only an owner is allowed to make this function call
   * @param amount is the quantity that is to be removed
   * @return a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function burn(uint256 amount) external override onlyOwner() returns (bool) {
    _burn(_msgSender(), amount);
    return true;
  }

  /**
   * @notice Removes tokens from circulation from a source other than token owner, with owner's approval
   * @dev See {IBurnable-burnFrom}.
   * @dev Only an owner is allowed to make this function call
   * @param account the address the tokens are being burned from
   * @param amount the quantity that is to be removed
   * @return a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function burnFrom(address account, uint256 amount) external override onlyOwner() returns (bool) {
    uint256 currentAllowance = allowance(account, _msgSender());
    require(currentAllowance >= amount, "Stablecoin: burn amount exceeds allowance");
    unchecked {
        _approve(account, _msgSender(), currentAllowance - amount);
    }
    _burn(account, amount);

    return true;
  }

 /**
  * @notice Returns a boolean representing that an address is blacklisted
  * @dev See {IBlacklist-blacklisted}.
  * @param holder is the address being evaluated
  * @return a boolean value indicating whether the address is blacklisted
  */
  function blacklisted(address holder) public view override returns (bool) {
    return _blacklist[holder];
  }

 /**
  * @notice Adds an address to the mapping of blacklisted addresses
  * @dev See {IBlacklist-addBlackList}.
  * @dev Only an owner is allowed to make this function call
  * @dev Triggers a call to removeBlackFunds()
  * @param holder is the address being added to the blacklist
  * @return a boolean value indicating whether the operation succeeded.
  *
  * Emits a {AddedBlacklist} event.
  * Emits a {Transfer} event.
  */
  function addBlackList(address holder) external onlyOwner() override returns (bool) {
    _blacklist[holder] = true;
    emit AddedBlacklist(holder);
    removeBlackFunds(holder);
    return true;
  }

 /**
  * @notice Removes an address to the mapping of blacklisted addresses
  * @dev See {IBlacklist-removeBlackList}.
  * @dev Only an owner is allowed to make this function call
  * @param holder is the address being removed from the blacklist
  * @return a boolean value indicating whether the operation succeeded.
  *
  * Emits a {RemovedBlacklist} event.
  */
  function removeBlackList(address holder) external onlyOwner() override returns (bool) {
    _blacklist[holder] = false;
    emit RemovedBlacklist(holder);
    return true;
  }

 /**
  * @notice Removes funds from blacklisted address
  * @param holder is the address having its funds removed
  */
  function removeBlackFunds(address holder) internal {
    uint256 funds = balanceOf(holder);
    _transfer(holder, _msgSender(), funds);
  }

 /**
  * @notice checks if destination has been previously blacklisted
  * @param destination is the address being checked for status
  */
  function _beforeExecution(address destination) internal view override {
    require(!blacklisted(destination), "Stablecoin: destination cannot be blacklisted address");
  }

 /**
  * @notice Sends ERC20 tokens trapped in contract to external address
  * @dev Only an owner is allowed to make this function call
  * @param 'account' is the receiving address
  * @param 'externalToken' is the token being sent
  * @param 'amount' is the quantity being sent
  * @return a boolean value indicating whether the operation succeeded.
  *
  * Emits a {Transfer} event.
  */
  function rescueERC20(address account, address externalToken, uint256 amount) external onlyOwner() returns (bool) {
    ERC20(externalToken).transfer(account, amount);
    return true;
  }
}