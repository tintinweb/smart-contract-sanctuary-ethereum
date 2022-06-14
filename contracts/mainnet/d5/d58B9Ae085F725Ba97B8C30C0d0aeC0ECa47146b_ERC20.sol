/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

pragma solidity 0.8.0;

/**
* @dev Interface of the ERC20 standard as defined in the EIP.
*/
interface IERC20 {
    /**
    * @dev Returns the amount of tokens in existence.
    */
    function totalSupply() external view returns (uint256);

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

    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view returns (address);

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

/**
* @dev Contract module which provides a manager access control mechanism, where
* there is owner and manager, that can be granted exclusive access to
* specific functions.
*
* Both owner and manager accounts need to be specified when deploying the contract. This
* can later be changed with {setOwner} and {setManager}.
*
* This module is used through inheritance. Modifiers `onlyOwner` and `ownerOrManager`
* will be available, which can be applied to your functions to restrict their use.
*/
abstract contract Managed is Context
{
    event OwnershipTransfered(address indexed previousOwner, address indexed newOwner);
    event ManagementTransferred(address indexed previousManager, address indexed newManager);

    address private _owner;
    address private _manager;

    /**
    * @dev Initializes the contract, setting owner and manager.
    */
    constructor(address owner_, address manager_)
    {
        require(owner_ != address(0), "Owner address can't be a zero address");
        require(manager_ != address(0), "Manager address can't be a zero address");

        _setOwner(owner_);
        _setManager(manager_);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address)
    { return _owner; }

    /**
    * @dev Returns the address of the current manager.
    */
    function manager() public view returns (address)
    { return _manager; }

    /**
    * @dev Transfers owner permissions to a new account (`newOwner`).
    * Can only be called by owner.
    */
    function setOwner(address newOwner) external onlyOwner
    {
        require(newOwner != address(0), "Managed: new owner can't be zero address");
        _setOwner(newOwner);
    }

    /**
    * @dev Transfers manager permissions to a new account (`newManager`).
    * Can only be called by owner.
    */
    function setManager(address newManager) external onlyOwner
    {
        require(newManager != address(0), "Managed: new manager can't be zero address");
        _setManager(newManager);
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner()
    {
        require(_msgSender() == _owner, "Managed: caller is not the owner");
        _;
    }

    /**
    * @dev Throws if called by any account other than owner or manager.
    */
    modifier ownerOrManager()
    {
        require(_msgSender() == _owner || _msgSender() == _manager, "Managed: caller is not the owner or manager");
        _;
    }

    /**
    * @dev Transfers owner permissions to a new account (`newOwner`).
    * Internal function without access restriction.
    */
    function _setOwner(address newOwner) internal
    {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransfered(oldOwner, newOwner);
    }

    /**
    * @dev Transfers manager permissions to a new account (`newManager`).
    * Internal function without access restriction.
    */
    function _setManager(address newManager) internal
    {
        address oldManager = _manager;
        _manager = newManager;
        emit ManagementTransferred(oldManager, newManager);
    }
}

/**
* @dev Contract module which provides a locking mechanism that allows
* a total token lock, or lock of a specific address.
*
* This module is used through inheritance. Modifier `isUnlocked`
* will be available, which can be applied to your functions to restrict their use.
*/
abstract contract Lockable is Managed
{
    event AddressLockChanged(address indexed addr, bool newLock);
    event TokenLockChanged(bool newLock);

    mapping(address => bool) private _addressLocks;
    bool private _locked;

    /**
    * @dev Completely locks any transfers of the token.
    * Can only be called by owner.
    */
    function lockToken() external onlyOwner
    {
        _locked = true;
        emit TokenLockChanged(true);
    }

    /**
    * @dev Completely unlocks any transfers of the token.
    * Can only be called by owner.
    */
    function unlockToken() external onlyOwner
    {
        _locked = false;
        emit TokenLockChanged(false);
    }

    /**
    * @dev Return whether the token is currently locked.
    */
    function isLocked() public view returns (bool)
    { return _locked; }

    /**
    * @dev Throws if a function is called while the token is locked.
    */
    modifier isUnlocked()
    {
        require(!_locked, "All token transfers are currently locked");
        _;
    }

    /**
    * @dev Completely locks sending and receiving of token for a specific address.
    * Can only be called by owner or manager
    */
    function lockAddress(address addr) external onlyOwner
    {
        _addressLocks[addr] = true;
        emit AddressLockChanged(addr, true);
    }

    /**
    * @dev Completely unlocks sending and receiving of token for a specific address.
    * Can only be called by owner or manager
    */
    function unlockAddress(address addr) external onlyOwner
    {
        _addressLocks[addr] = false;
        emit AddressLockChanged(addr, false);
    }

    /**
    * @dev Returns whether the account (`addr`) is currently locked.
    */
    function isAddressLocked(address addr) public view returns (bool)
    { return _addressLocks[addr]; }
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
contract ERC20 is Context, IERC20, Managed, Lockable
{
    event Burn(address indexed from, uint256 amount);
    event Release(address indexed to, uint256 amount);
    event Halving(uint256 oldReleaseAmount, uint256 newReleaseAmount);
    event ReleaseAddressChanged(address indexed oldAddress, address indexed newAddress);

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;

    uint256 private _releaseAmount;
    uint256 private _nextReleaseDate;
    uint256 private _nextReducementDate;
    address private _releaseAddress;

    uint256 private _week = 600000; // 10 000 minutes
    uint256 private _4years = 126000000; // 2 100 000 minutes

    /**
    * @dev Sets the values for {owner}, {manager} and {initialDepositAddress}.
    *
    * Sets the {_releaseAmount} to 50538 coins, and timestamp for {_nextReleaseDate} and {_nextReducementDate}.
    * Sends first released amount to the {initialDepositAddress}, and locks the remaining supply within contract.
    *
    * The default value of {decimals} is 18. To select a different value for
    * {decimals} you should overload it.
    *
    * All values for token parameters are immutable: they can only be set once during
    * construction.
    */
    constructor(string memory name_, string memory symbol_, uint8 decimals_, address owner_, address manager_, address initialDepositAddress) Managed(owner_, manager_)
    {
        require(initialDepositAddress != address(0), "Initial unlock address can't be a zero address");

        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        _totalSupply = 21000000 * uint256(10**decimals_);
        _releaseAmount = 50000 * uint256(10**decimals_);

        _nextReleaseDate = block.timestamp + _week;
        _nextReducementDate = block.timestamp + _4years;

        _balances[address(this)] = _totalSupply - _releaseAmount;
        emit Transfer(address(0), address(this), _balances[address(this)]);

        _releaseAddress = initialDepositAddress;

        _balances[initialDepositAddress] = _releaseAmount;
        emit Transfer(address(0), initialDepositAddress, _balances[initialDepositAddress]);

        emit Release(initialDepositAddress, _balances[initialDepositAddress]);
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
        return _decimals;
    }

    /**
    * @dev See {IERC20-getOwner}.
    */
    function getOwner() public view virtual override returns (address)
    { return owner(); }

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
    * - the caller must have an available balance of at least `amount`.
    */
    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
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
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
    * @dev Destroys `amount` tokens from the caller.
    *
    * See {ERC20-_burn}.
    */
    function burn(uint256 amount) external virtual
    { _burn(_msgSender(), amount); }

    /**
    * @dev Destroys `amount` tokens from `account`, deducting from the caller's
    * allowance.
    *
    * See {ERC20-_burn} and {ERC20-allowance}.
    *
    * Requirements:
    *
    * - the caller must have allowance for `accounts`'s tokens of at least
    * `amount`.
    */
    function burnFrom(address account, uint256 amount) external virtual
    {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
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
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
    * @dev Sets {_releaseAddress} to {newReleaseAddress}.
    *
    * Emits a {ReleaseAddressChanged} event containing old and a new release addresses.
    */
    function setReleaseAddress(address newReleaseAddress) external onlyOwner
    {
        require(newReleaseAddress != address(0), "New release address can't be a zero address");

        address oldAddress = _releaseAddress;
        _releaseAddress = newReleaseAddress;

        emit ReleaseAddressChanged(oldAddress, _releaseAddress);
    }

    /**
    * @dev Calculates and releases new coins into circulation.
    * If multiple weeks have passed, releases all the coins that should be
    * released within those weeks.
    *
    * Emits a {Release} event containing the address {_releaseAddress} the coins were released to,
    * and the amount {toRelease} of coins the function released.
    */
    function release() external ownerOrManager
    {
        require(block.timestamp > _nextReleaseDate, "Next coin release is not yet scheduled");
        require(balanceOf(address(this)) > 0, "There are no more coins to release");

        uint256 toRelease = 0;
        uint256 currentRelease = 0;

        while((currentRelease = _calculateReleaseAmount()) > 0)
        { toRelease += currentRelease; }

        _transfer(address(this), _releaseAddress, toRelease);
        emit Release(_releaseAddress, toRelease);
    }

    /**
    * @dev Calculates the exact amount of coins that should be released for one release cycle.
    * If the next release will be after the halving date, it also calculates a new {_releaseAmount}
    * for future releases.
    *
    * Emits a {Halving} event if halving happens, containing the old release amount {oldReleaseAmount},
    * and new release amount {_releaseAmount}
    */
    function _calculateReleaseAmount() internal returns (uint256)
    {
        if(block.timestamp < _nextReleaseDate || balanceOf(address(this)) == 0)
            return 0;

        uint256 amount = _releaseAmount > balanceOf(address(this)) ? balanceOf(address(this)) : _releaseAmount;

        _nextReleaseDate += _week;
        if(_nextReleaseDate >= _nextReducementDate)
        {
            _nextReducementDate += _4years;

            uint256 oldReleaseAmount = _releaseAmount;
            _releaseAmount = (_releaseAmount * 500000) / 1000000;

            emit Halving(oldReleaseAmount, _releaseAmount);
        }

        return amount;
    }

    /**
    * @dev Moves `amount` of tokens from `sender` to `recipient`.
    *
    * This internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * If the `recipient` address is zero address, calls {_burn} instead.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `sender` must have an available balance of at least `amount`.
    */
    function _transfer(address sender, address recipient, uint256 amount) internal isUnlocked virtual
    {
        require(recipient != address(0), "ERC20: transfer to zero address");
        require(sender != address(0), "ERC20: transfer from the zero address");

        require(!isAddressLocked(sender), "Sender address is currently locked and can't send funds");
        require(!isAddressLocked(recipient), "Recipient address is currently locked and can't receive funds");

        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds available balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
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
    * @dev Destroys `amount` tokens from `account`, reducing the
    * total supply.
    *
    * Emits a {Transfer} event with `to` set to the zero address.
    * Emits a {Burn} event with `amount` burned.
    *
    * Requirements:
    *
    * - `account` cannot be the zero address.
    * - `account` must have at least `amount` tokens.
    * - `account` can't be locked.
    */
    function _burn(address account, uint256 amount) internal isUnlocked virtual
    {
        require(account != address(0), "ERC20: burn from the zero address");

        require(!isAddressLocked(account), "Sender address is currently locked and can't burn funds");

        require(_balances[account] >= amount, "ERC20: burn amount exceeds available balance");

        _balances[account] -= amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
        emit Burn(account, amount);
    }
}