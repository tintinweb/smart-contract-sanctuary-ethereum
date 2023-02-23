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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Whitelist.sol";

contract GRPresale is Ownable, Whitelist, ReentrancyGuard {
    bool public isInit;
    bool public isDeposit;
    bool public isFinish;
    bool public isTGE;
    bool public burnTokens;
    bool public isWhitelist;
    address public creatorWallet;
    address public teamWallet;
    address public weth;
    uint8 private constant FEE = 2;
    uint8 public tokenDecimals;
    uint256 public presaleTokens;
    uint256 public ethRaised;
    uint256 public vestingStartTime;
    uint256 public vestingCliff;
    uint256 public vestingPeriod;
    uint256 public vestingEndTime;

    struct Pool {
        uint64 startTime;
        uint64 endTime;
        uint256 saleRate;
        uint256 hardCap;
        uint256 softCap;
        uint256 maxBuy;
        uint256 minBuy;
    }

    struct Vesting {
        uint256 totalAmount;
        uint256 totalAmountInEth;
        uint256 claimedAmount;
        uint256 lastClaim;
    }

    IERC20 public tokenInstance;
    Pool public pool;

    mapping(address => Vesting) public userVesting;


    modifier onlyActive() {
        require(block.timestamp >= pool.startTime, "Sale must be active.");
        require(block.timestamp <= pool.endTime, "Sale must be active.");
        _;
    }

    modifier onlyInactive() {
        require(
            block.timestamp < pool.startTime ||
                block.timestamp > pool.endTime ||
                ethRaised >= pool.hardCap,
            "Sale must be inactive."
        );
        _;
    }
    modifier isEligibleSender() {
        require(
            msg.sender == tx.origin,
            "Contracts are not allowed to snipe the sale"
        );
        _;
    }

    constructor(
        IERC20 _tokenInstance,
        uint8 _tokenDecimals,
        address _teamWallet,
        address _weth,
        bool _burnTokens,
        bool _isWhitelist
    ) {
        require(_tokenDecimals >= 0, "Decimals not supported.");
        require(_tokenDecimals <= 18, "Decimals not supported.");

        isInit = false;
        isDeposit = false;
        isFinish = false;
        isTGE = false;
        ethRaised = 0;

        teamWallet = _teamWallet;
        weth = _weth;
        burnTokens = _burnTokens;
        isWhitelist = _isWhitelist;
        tokenInstance = _tokenInstance;
        creatorWallet = address(payable(msg.sender));
        tokenDecimals = _tokenDecimals;
    }

    event Liquified(
        address indexed _token,
        address indexed _router,
        address indexed _pair
    );

    event Canceled(
        address indexed _inititator,
        address indexed _token,
        address indexed _presale
    );

    event Bought(address indexed _buyer, uint256 _tokenAmount);

    event Deposited(address indexed _initiator, uint256 _totalDeposit);

    event Claimed(address indexed _participent, uint256 _tokenAmount);

    event BurntRemainder(address indexed _initiator, uint256 _amount);

    event Withdraw(address indexed _creator, uint256 _amount);

    /*
     * Reverts ethers sent to this address whenever requirements are not met
     */
    receive() external payable {
        if (
            block.timestamp >= pool.startTime && block.timestamp <= pool.endTime
        ) {
            buyTokens();
        } else {
            revert("Presale is closed");
        }
    }

    /*
    * Initiates the arguments of the sale
    @dev arguments must be passed in wei (amount*10**18)
    */
    function initSale(
        uint64 _startTime,
        uint64 _endTime,
        uint256 _saleRate,
        uint256 _hardCap,
        uint256 _softCap,
        uint256 _maxBuy,
        uint256 _minBuy,
        uint256 _vestingStartTime,
        uint256 _vestingCliff,
        uint256 _vestingPeriod
    ) external onlyOwner onlyInactive {
        require(isInit == false, "Sale no initialized");
        require(_startTime >= block.timestamp, "Invalid start time.");
        require(_endTime > block.timestamp, "Invalid end time.");
        require(_softCap >= _hardCap / 2, "SC must be >= HC/2.");
        require(_minBuy < _maxBuy, "Min buy must greater than max.");
        require(_minBuy > 0, "Min buy must exceed 0.");
        require(_saleRate > 0, "Invalid sale rate.");
        require(_vestingStartTime > _endTime, "Invalid vesting start time.");
        require(_vestingCliff > 0, "Invalid vesting cliff.");
        require(_vestingPeriod > 0, "Invalid vesting period.");

        vestingStartTime = _vestingStartTime + _vestingCliff;
        vestingEndTime = _vestingStartTime + _vestingCliff + _vestingPeriod;
        vestingCliff = _vestingCliff;
        vestingPeriod = _vestingPeriod;

        Pool memory newPool = Pool( 
            _startTime,
            _endTime,
            _saleRate,
            _hardCap,
            _softCap,
            _maxBuy,
            _minBuy
        );

        pool = newPool;

        isInit = true;
    }

    /*
    * Change TGE status
    */
    function changeTGEStatus(bool _isTGE) external onlyOwner {
        isTGE = _isTGE;
    }

    /*
    * Change vesting start time
    */
    function changeVestingStartTime(uint256 _vestingStartTime)
        external
        onlyOwner
        onlyInactive
    {
        require(_vestingStartTime > pool.endTime, "Invalid vesting start time.");
        vestingStartTime = _vestingStartTime + vestingCliff;
        vestingEndTime = _vestingStartTime + vestingCliff + vestingPeriod;
    }

    /*   
     * Once called the owner deposits tokens into pool
     */
    function deposit() external onlyOwner {
        require(!isDeposit, "Tokens already deposited.");
        require(isInit, "Not initialized yet.");
        uint256 tokensForSale = (pool.hardCap * (pool.saleRate)) /
            (10 ** 18) /
            (10 ** (18 - tokenDecimals));

        presaleTokens = tokensForSale;
        uint256 totalDeposit = _getTokenDeposit();

        isDeposit = true;
        require(
            tokenInstance.transferFrom(msg.sender, address(this), totalDeposit),
            "Deposit failed."
        );
        emit Deposited(msg.sender, totalDeposit);
    }

    /*
     * Finish the sale - take fees, withrdawal funds, burn/refund unused tokens
     */
    function finishSale() external onlyOwner onlyInactive {
        require(
            block.timestamp > pool.startTime,
            "Can not finish before start"
        );
        require(!isFinish, "Sale already launched.");

        isFinish = true;

        //take the Fees
        uint256 teamShareEth = _getFeeEth();
        payable(teamWallet).transfer(teamShareEth);

        //withrawal eth
        uint256 ownerShareEth = _getOwnerEth();
        if (ownerShareEth > 0) {
            payable(creatorWallet).transfer(ownerShareEth);
        }

        //burn/refund unused tokens
        uint256 tokensForSale = (ethRaised * (pool.saleRate)) /
            (10 ** 18) /
            (10 ** (18 - tokenDecimals));
        uint256 tokenDeposit = _getTokenDeposit() - tokensForSale;
        if (tokenDeposit > 0) {
            if (burnTokens) {
                require(
                    tokenInstance.transfer(
                        0x000000000000000000000000000000000000dEaD,
                        tokenDeposit
                    ),
                    "Unable to burn."
                );
                emit BurntRemainder(msg.sender, tokenDeposit);
            } else {
                require(
                    tokenInstance.transfer(msg.sender, tokenDeposit),
                    "Unable to refund."
                );
                emit Withdraw(msg.sender, tokenDeposit);
            }
        }
    }

    /*
    * The owner can decide to close the sale if it is still active
    NOTE: Creator may call this function even if the Hard Cap is reached, to prevent it use:
     require(ethRaised < pool.hardCap)
    */
    function cancelSale() external onlyOwner onlyActive {
        require(!isFinish, "Sale finished.");
        pool.endTime = 0;

        if (tokenInstance.balanceOf(address(this)) > 0) {
            uint256 tokenDeposit = _getTokenDeposit();
            tokenInstance.transfer(msg.sender, tokenDeposit);
            emit Withdraw(msg.sender, tokenDeposit);
        }
        emit Canceled(msg.sender, address(tokenInstance), address(this));
    }

    /*
     * Allows participents to claim the tokens they purchased
     */
    function claimTokens() external onlyInactive {
        require(isFinish, "Sale is still active.");
        require(isTGE, "TGE not started yet.");
        uint256 tokensToClaim = _claimableAmount(msg.sender);
        require(tokensToClaim > 0, "No tokens to claim.");

        userVesting[msg.sender].claimedAmount += tokensToClaim;

        require(
            tokenInstance.transfer(msg.sender, tokensToClaim),
            "Claim failed."
        );

        emit Claimed(msg.sender, tokensToClaim);
    }

    /*
     * Withdrawal tokens
     */
    function withrawTokens() external onlyOwner onlyInactive {
        if (tokenInstance.balanceOf(address(this)) > 0) {
            uint256 tokenDeposit = _getTokenDeposit();
            require(
                tokenInstance.transfer(msg.sender, tokenDeposit),
                "Withdraw failed."
            );
            emit Withdraw(msg.sender, tokenDeposit);
        }
    }

    /*
     * Disables WL
     */
    function disableWhitelist() external onlyOwner {
        require(isWhitelist, "WL already disabled.");

        isWhitelist = false;
    }

    /*
     * If requirements are passed, updates user"s token balance based on their eth contribution
     */
    function buyTokens()
        public
        payable
        onlyActive
        isEligibleSender
        nonReentrant
    {
        require(isDeposit, "Tokens not deposited.");

        uint256 weiAmount = msg.value;
        _checkSaleRequirements(weiAmount);
        uint256 tokensAmount = _getUserTokens(weiAmount);
        ethRaised += weiAmount;
        presaleTokens -= tokensAmount;

        // add vesting
        if (userVesting[msg.sender].totalAmount > 0) {
            userVesting[msg.sender].totalAmount += tokensAmount;
            userVesting[msg.sender].totalAmountInEth += weiAmount;
        } else {
            userVesting[msg.sender] = Vesting(
                tokensAmount,
                weiAmount,
                0,
                vestingStartTime
            );
        }

        emit Bought(_msgSender(), tokensAmount);
    }

    /*
     * Checks whether a user passes token purchase requirements, called internally on buyTokens function
     */
    function _checkSaleRequirements(uint256 _amount) internal view {
        if (isWhitelist) {
            require(whitelists[_msgSender()], "User not Whitelisted.");
        }

        require(_msgSender() != address(0), "Transfer to 0 address.");
        require(_amount != 0, "Wei Amount is 0");
        require(_amount >= pool.minBuy, "Min buy is not met.");
        require(
            _amount + userVesting[_msgSender()].totalAmountInEth <= pool.maxBuy,
            "Max buy limit exceeded."
        );
        require(ethRaised + _amount <= pool.hardCap, "HC Reached.");
        this;
    }

    /*
     * Internal functions, called when calculating balances
     *
     */
    function _getUserTokens(uint256 _amount) internal view returns (uint256) {
        return
            (_amount * (pool.saleRate)) /
            (10 ** 18) /
            (10 ** (18 - tokenDecimals));
    }

    function _getFeeEth() internal view returns (uint256) {
        return ((ethRaised * FEE) / 100);
    }

    function _getOwnerEth() internal view returns (uint256) {
        uint256 etherFee = _getFeeEth();
        return (ethRaised - etherFee);
    }

    function _getTokenDeposit() internal view returns (uint256) {
        uint256 tokensForSale = (pool.hardCap * pool.saleRate) /
            (10 ** 18) /
            (10 ** (18 - tokenDecimals));
        return (tokensForSale);
    }

    function _claimableAmount(address user) internal returns (uint256) {
        Vesting memory _user = userVesting[user];
        require(_user.totalAmount > 0, "Nothing to claim");
        uint256 amount = _user.totalAmount - _user.claimedAmount;
        require(amount > 0, "Already claimed");

        if (_user.claimedAmount == 0) {
            return (amount * 20) / 100;
        }

        if (block.timestamp < vestingStartTime) return 0;
        if (block.timestamp >= vestingEndTime) return amount;

        if (_user.lastClaim < vestingStartTime) {
            _user.lastClaim = vestingStartTime;
        }

        // calculate 20% of all user tokens to claim per 2 months from last claim
        uint256 amountToClaim = (_user.totalAmount * 20) / 100;
        uint256 timePassed = block.timestamp - _user.lastClaim;
        uint256 timePassedInMonths = timePassed / 5184000;
        amountToClaim = amountToClaim * timePassedInMonths;

        require(timePassedInMonths > 0, "Time passed is less than 2 month");
        require(
            amountToClaim < _user.totalAmount - _user.claimedAmount,
            "Amount to claim is more than available"
        );
        userVesting[user].lastClaim = block.timestamp;
        return amountToClaim;
    }
}

// solhint-disable-next-line
pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed
// A+G = VNL
// https://github.com/kirilradkov14

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Whitelist is Ownable {
    mapping(address => bool) public whitelists;

    function wlAddress(address _user) external onlyOwner {
        require(whitelists[_user] == false, "Address already WL");
        require(_user != address(0), "Can not WL 0 address");

        whitelists[_user] = true;
    }

    function wlMultipleAddresses(address[] calldata _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            whitelists[_users[i]] = true;
        }
    }

    function removeAddress(address _user) external onlyOwner {
        require(whitelists[_user] == true, "User not WL");
        require(_user != address(0), "Can not delist 0 address");

        whitelists[_user] = false;
    }

    function removeMultipleAddresses(
        address[] calldata _users
    ) external onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            whitelists[_users[i]] = false;
        }
    }
}