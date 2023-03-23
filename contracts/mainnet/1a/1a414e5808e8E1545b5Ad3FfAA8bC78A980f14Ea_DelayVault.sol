/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

// SPDX-License-Identifier: MIT
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

interface ILockedDealV2 {
    function CreateNewPool(
        address _Token, //token to lock address
        uint256 _StartTime, //Until what time the pool will start
        uint256 _CliffTime, //Before CliffTime can't withdraw tokens
        uint256 _FinishTime, //Until what time the pool will end
        uint256 _StartAmount, //Total amount of the tokens to sell in the pool
        address _Owner // Who the tokens belong to
    ) external payable;

    function WithdrawToken(uint256 _PoolId)
        external
        returns (uint256 withdrawnAmount);
}


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




contract GovManager is Ownable {
    address public GovernerContract;

    modifier onlyOwnerOrGov() {
        require(
            msg.sender == owner() || msg.sender == GovernerContract,
            "Authorization Error"
        );
        _;
    }

    function setGovernerContract(address _address) external onlyOwnerOrGov {
        GovernerContract = _address;
    }

    constructor() {
        GovernerContract = address(0);
    }
}


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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


contract ERC20Helper {
    event TransferOut(uint256 Amount, address To, address Token);
    event TransferIn(uint256 Amount, address From, address Token);
    modifier TestAllownce(
        address _token,
        address _owner,
        uint256 _amount
    ) {
        require(
            ERC20(_token).allowance(_owner, address(this)) >= _amount,
            "no allowance"
        );
        _;
    }

    function TransferToken(
        address _Token,
        address _Reciver,
        uint256 _Amount
    ) internal {
        uint256 OldBalance = CheckBalance(_Token, address(this));
        emit TransferOut(_Amount, _Reciver, _Token);
        ERC20(_Token).transfer(_Reciver, _Amount);
        require(
            (CheckBalance(_Token, address(this)) + _Amount) == OldBalance,
            "recive wrong amount of tokens"
        );
    }

    function CheckBalance(address _Token, address _Subject)
        internal
        view
        returns (uint256)
    {
        return ERC20(_Token).balanceOf(_Subject);
    }

    function TransferInToken(
        address _Token,
        address _Subject,
        uint256 _Amount
    ) internal TestAllownce(_Token, _Subject, _Amount) {
        require(_Amount > 0);
        uint256 OldBalance = CheckBalance(_Token, address(this));
        ERC20(_Token).transferFrom(_Subject, address(this), _Amount);
        emit TransferIn(_Amount, _Subject, _Token);
        require(
            (OldBalance + _Amount) == CheckBalance(_Token, address(this)),
            "recive wrong amount of tokens"
        );
    }

    function ApproveAllowanceERC20(
        address _Token,
        address _Subject,
        uint256 _Amount
    ) internal {
        require(_Amount > 0);
        ERC20(_Token).approve(_Subject, _Amount);
    }
}

/// @title contain stores variables.
contract DelayData {
    address public LockedDealAddress;
    mapping(address => Delay) public DelayLimit; // delay limit for every token
    mapping(address => mapping(address => Vault)) public VaultMap;
    mapping(address => mapping(address => bool)) public Allowance;
    mapping(address => address[]) public MyTokens;
    mapping(address => address[]) public Users;
    
    struct Vault {
        uint256 Amount;
        uint256 StartDelay;
        uint256 CliffDelay;
        uint256 FinishDelay;
    }

    struct Delay {
        uint256[] Amounts;
        uint256[] StartDelays;
        uint256[] CliffDelays;
        uint256[] FinishDelays;
        bool isActive;
    }
}


/// @title contains array utility functions
library Array {
    /// @dev returns a new slice of the array
    function KeepNElementsInArray(uint256[] memory _arr, uint256 _n)
        internal
        pure
        returns (uint256[] memory newArray)
    {
        if (_arr.length == _n) return _arr;
        require(_arr.length > _n, "can't cut more then got");
        newArray = new uint256[](_n);
        for (uint256 i = 0; i < _n; i++) {
            newArray[i] = _arr[i];
        }
        return newArray;
    }

    function KeepNElementsInArray(address[] memory _arr, uint256 _n)
        internal
        pure
        returns (address[] memory newArray)
    {
        if (_arr.length == _n) return _arr;
        require(_arr.length > _n, "can't cut more then got");
        newArray = new address[](_n);
        for (uint256 i = 0; i < _n; i++) {
            newArray[i] = _arr[i];
        }
        return newArray;
    }

    /// @return true if the array is ordered
    function isArrayOrdered(uint256[] memory _arr)
        internal
        pure
        returns (bool)
    {
        require(_arr.length > 0, "array should be greater than zero");
        uint256 temp = _arr[0];
        for (uint256 i = 1; i < _arr.length; i++) {
            if (temp > _arr[i]) {
                return false;
            }
            temp = _arr[i];
        }
        return true;
    }

    /// @return sum of the array elements
    function getArraySum(uint256[] memory _array)
        internal
        pure
        returns (uint256)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < _array.length; i++) {
            sum = sum + _array[i];
        }
        return sum;
    }

    /// @return true if the element exists in the array
    function isInArray(address[] memory _arr, address _elem)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < _arr.length; i++) {
            if (_arr[i] == _elem) return true;
        }
        return false;
    }

    function addIfNotExsist(address[] storage _arr, address _elem) internal {
        if (!Array.isInArray(_arr, _elem)) {
            _arr.push(_elem);
        }
    }
}


/// @title contains modifiers.
contract DelayModifiers is DelayData {
    modifier uniqueAddress(address _addr, address _oldAddr) {
        require(_addr != _oldAddr, "can't set the same address");
        _;
    }

    modifier notZeroAddress(address _addr) {
        _notZeroAddress(_addr);
        _;
    }

    modifier isVaultNotEmpty(address _token, address _owner) {
        require(VaultMap[_token][_owner].Amount > 0, "vault is already empty");
        _;
    }

    modifier validAmount(uint256 _fAmount, uint256 _sAmount) {
        require(_fAmount >= _sAmount, "invalid amount");
        _;
    }

    ///@dev By default, each token is inactive
    modifier isTokenActive(address _token) {
        require(
            DelayLimit[_token].isActive,
            "there are no limits set for this token"
        );
        _;
    }

    modifier orderedArray(uint256[] memory _array) {
        require(Array.isArrayOrdered(_array), "array should be ordered");
        _;
    }

    function _shortStartDelay(address _token, uint256 _startDelay)
        internal
        view
    {
        require(
            _startDelay >= VaultMap[_token][msg.sender].StartDelay,
            "can't set a shorter start period than the last one"
        );
    }

    function _shortFinishDelay(address _token, uint256 _finishDelay)
        internal
        view
    {
        require(
            _finishDelay >= VaultMap[_token][msg.sender].FinishDelay,
            "can't set a shorter finish period than the last one"
        );
    }

    function _shortCliffDelay(address _token, uint256 _cliffDelay)
        internal
        view
    {
        require(
            _cliffDelay >= VaultMap[_token][msg.sender].CliffDelay,
            "can't set a shorter cliff period than the last one"
        );
    }

    function _notZeroAddress(address _addr) private pure {
        require(_addr != address(0), "address can't be null");
    }

    function _equalValue(uint256 _fLength, uint256 _sLength) internal pure {
        require(_fLength == _sLength, "invalid array length");
    }

    function _checkMinDelay(uint256 _delay, uint256 _minDelay) internal pure {
        require(_delay >= _minDelay, "delay less than min delay");
    }
}


/// @title contains all events.
contract DelayEvents {
    event VaultValueChanged(
        address indexed Token,
        address indexed Owner,
        uint256 Amount,
        uint256 StartDelay,
        uint256 CliffDelay,
        uint256 FinishDelay
    );
    event UpdatedMinDelays(
        address indexed Token,
        uint256[] Amounts,
        uint256[] StartDelays,
        uint256[] CliffDelays,
        uint256[] FinishDelays
    );
    event BoughtBackTokens(
        address indexed Token,
        uint256 Amount,
        uint256 RemaningAmount
    );
}

/// @title all admin settings
contract DelayManageable is
    Pausable,
    GovManager,
    DelayEvents,
    DelayModifiers,
    ERC20Helper,
    ReentrancyGuard
{
    function setLockedDealAddress(address _lockedDealAddress)
        external
        onlyOwnerOrGov
        uniqueAddress(_lockedDealAddress, LockedDealAddress)
    {
        LockedDealAddress = _lockedDealAddress;
    }

    function setMinDelays(
        address _token,
        uint256[] calldata _amounts,
        uint256[] calldata _startDelays,
        uint256[] calldata _cliffDelays,
        uint256[] calldata _finishDelays
    ) external onlyOwnerOrGov notZeroAddress(_token) orderedArray(_amounts) {
        {
            // Stack Too deep error fixing
            _equalValues(
                _amounts.length,
                _startDelays.length,
                _cliffDelays.length,
                _finishDelays.length
            );
        }
        DelayLimit[_token] = Delay(
            _amounts,
            _startDelays,
            _cliffDelays,
            _finishDelays,
            true
        );
        emit UpdatedMinDelays(
            _token,
            _amounts,
            _startDelays,
            _cliffDelays,
            _finishDelays
        );
    }

    function swapTokenStatusFilter(address _token)
        external
        onlyOwnerOrGov
        notZeroAddress(_token)
    {
        DelayLimit[_token].isActive = !DelayLimit[_token].isActive;
    }

    function Pause() external onlyOwnerOrGov {
        _pause();
    }

    function Unpause() external onlyOwnerOrGov {
        _unpause();
    }

    function _equalValues(
        uint256 _amountsL,
        uint256 _startDelaysL,
        uint256 _finishDelaysL,
        uint256 _cliffDelaysL
    ) private pure {
        _equalValue(_amountsL, _startDelaysL);
        _equalValue(_finishDelaysL, _startDelaysL);
        _equalValue(_cliffDelaysL, _startDelaysL);
    }

    /// @dev redemption of approved ERC-20 tokens from the contract
    function BuyBackTokens(
        address _token,
        address _owner,
        uint256 _amount
    )
        external
        onlyOwnerOrGov
        nonReentrant
        notZeroAddress(_token)
        isVaultNotEmpty(_token, _owner)
        validAmount(VaultMap[_token][_owner].Amount, _amount)
    {
        require(Allowance[_token][_owner], "permission not granted");
        Vault storage vault = VaultMap[_token][_owner];
        if ((vault.Amount -= _amount) == 0)
            vault.FinishDelay = vault.CliffDelay = vault.StartDelay = 0; // if Amount is zero, refresh vault values
        TransferToken(_token, msg.sender, _amount);
        emit BoughtBackTokens(_token, _amount, vault.Amount);
    }
}


/// @title DelayView - getter view functions
contract DelayView is DelayManageable {
    function GetAllUsersData(address _token)
        external
        view
        returns (address[] memory, Vault[] memory _vaults)
    {
        _vaults = new Vault[](Users[_token].length);
        for (uint256 i = 0; i < Users[_token].length; i++) {
            _vaults[i] = VaultMap[_token][Users[_token][i]];
        }
        return (Users[_token], _vaults);
    }

    function GetAllMyTokens(address _user)
        external
        view
        returns (address[] memory)
    {
        return MyTokens[_user];
    }

    function GetMyTokens(address _user)
        external
        view
        returns (address[] memory)
    {
        address[] storage allTokens = MyTokens[_user];
        address[] memory tokens = new address[](allTokens.length);
        uint256 index;
        for (uint256 i = 0; i < allTokens.length; i++) {
            if (VaultMap[allTokens[i]][_user].Amount > 0) {
                tokens[index++] = allTokens[i];
            }
        }
        return Array.KeepNElementsInArray(tokens, index);
    }

    function GetDelayLimits(address _token)
        external
        view
        returns (
            uint256[] memory _amount,
            uint256[] memory _startDelays,
            uint256[] memory _cliffDelays,
            uint256[] memory _finishDelays
        )
    {
        (_amount, _startDelays, _cliffDelays, _finishDelays) = (
            DelayLimit[_token].Amounts,
            DelayLimit[_token].StartDelays,
            DelayLimit[_token].CliffDelays,
            DelayLimit[_token].FinishDelays
        );
    }

    function GetMinDelays(address _token, uint256 _amount)
        public
        view
        isTokenActive(_token)
        returns (
            uint256 _startDelay,
            uint256 _cliffDelay,
            uint256 _finishDelay
        )
    {
        Delay memory delayLimit = DelayLimit[_token];
        uint256 arrLength = delayLimit.Amounts.length;
        if (arrLength == 0 || delayLimit.Amounts[0] > _amount) return (0, 0, 0);
        _startDelay = delayLimit.StartDelays[0];
        _cliffDelay = delayLimit.CliffDelays[0];
        _finishDelay = delayLimit.FinishDelays[0];
        for (uint256 i = 1; i < arrLength; i++) {
            if (_amount >= delayLimit.Amounts[i]) {
                _startDelay = delayLimit.StartDelays[i];
                _cliffDelay = delayLimit.CliffDelays[i];
                _finishDelay = delayLimit.FinishDelays[i];
            } else {
                break;
            }
        }
    }

    function GetTokenFilterStatus(address _token) external view returns (bool) {
        return DelayLimit[_token].isActive;
    }
}

/// @title DelayVault core logic
/// @author The-Poolz contract team
contract DelayVault is DelayView {
    function CreateVault(
        address _token,
        uint256 _amount,
        uint256 _startDelay,
        uint256 _cliffDelay,
        uint256 _finishDelay
    )
        external
        whenNotPaused
        nonReentrant
        notZeroAddress(_token)
        isTokenActive(_token)
    {
        _shortDelay(_token, _startDelay, _cliffDelay, _finishDelay); // Stack Too deep error fixing
        Vault storage vault = VaultMap[_token][msg.sender];
        require( // for the possibility of increasing only the time parameters
            _amount > 0 ||
                _startDelay > vault.StartDelay ||
                _cliffDelay > vault.CliffDelay ||
                _finishDelay > vault.FinishDelay,
            "amount should be greater than zero"
        );
        (
            uint256 _startMinDelay,
            uint256 _cliffMinDelay,
            uint256 _finishMinDelay
        ) = GetMinDelays(_token, vault.Amount + _amount);
        {
            // Checking the minimum delay for each timing parameter.
            _checkMinDelay(_startDelay, _startMinDelay);
            _checkMinDelay(_cliffDelay, _cliffMinDelay);
            _checkMinDelay(_finishDelay, _finishMinDelay);
        }
        TransferInToken(_token, msg.sender, _amount);
        vault.StartDelay = _startDelay;
        vault.CliffDelay = _cliffDelay;
        vault.FinishDelay = _finishDelay;
        Array.addIfNotExsist(Users[_token], msg.sender);
        Array.addIfNotExsist(MyTokens[msg.sender], _token);
        emit VaultValueChanged(
            _token,
            msg.sender,
            vault.Amount += _amount,
            _startDelay,
            _cliffDelay,
            _finishDelay
        );
    }

    /** @dev Creates a new pool of tokens for a specified period or,
         if there is no Locked Deal address, sends tokens to the owner.
    */
    function Withdraw(address _token)
        external
        nonReentrant
        isVaultNotEmpty(_token, msg.sender)
    {
        Vault storage vault = VaultMap[_token][msg.sender];
        uint256 startDelay = block.timestamp + vault.StartDelay;
        uint256 finishDelay = startDelay + vault.FinishDelay;
        uint256 cliffDelay = startDelay + vault.CliffDelay;
        uint256 lockAmount = vault.Amount;
        vault.Amount = 0;
        vault.FinishDelay = vault.CliffDelay = vault.StartDelay = 0;
        if (LockedDealAddress != address(0)) {
            ApproveAllowanceERC20(_token, LockedDealAddress, lockAmount);
            ILockedDealV2(LockedDealAddress).CreateNewPool(
                _token,
                startDelay,
                cliffDelay,
                finishDelay,
                lockAmount,
                msg.sender
            );
        } else {
            TransferToken(_token, msg.sender, lockAmount);
        }
        emit VaultValueChanged(_token, msg.sender, 0, 0, 0, 0);
    }

    /// @dev the user can approve the redemption of their tokens by the admin
    function SwapBuyBackStatus(address _token) external {
        Allowance[_token][msg.sender] = !Allowance[_token][msg.sender];
    }

    /// @dev the user can't set a time parameter less than the last one
    function _shortDelay(
        address _token,
        uint256 _startDelay,
        uint256 _cliffDelay,
        uint256 _finishDelay
    ) private view {
        _shortStartDelay(_token, _startDelay);
        _shortCliffDelay(_token, _cliffDelay);
        _shortFinishDelay(_token, _finishDelay);
    }
}