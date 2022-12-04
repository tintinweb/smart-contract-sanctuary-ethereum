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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

//@author: Mbimich

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
//import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
//import "./LibTime.sol";

contract PayPerTrustContract is ERC20, Ownable, ReentrancyGuard, Pausable {
    
    //using DateTime for uint;

    uint256 public StartDay;
    uint256 public EndDay;
    uint256 public Num_Journalists;
    uint256 public Num_Reviewers;
    uint256 public Total_Rating_Journalist;
    uint256 public Total_Rating_Reviewer;

    uint256 private constant MaxSupply = 1000 * 365 * 10 * 10 ** 18; // 1000 tokens per day * 365 days * 10 years * 10^18 decimals
    uint256 private constant MaxSupplyPerDay = 1000 * 10 ** 18; // 1000 tokens per day * 10^18 decimals
    uint256 private Last_Reviewer_Proposal;
    uint256 private Last_Journalist_Proposal;
    uint256 private TotalSupply;

    error InvalidAmount (uint256 sent, uint256 Required);
    error YouAreNotReviewer();
    error YouAreNotJournalist();
    error AlreadyReviewer();
    error AlreadyJournalist();
    error NoProposalReviewers();
    error NoProposalJournalists();
    error VoteNotCompleted();
    error UserNotExist();
    error NoUsers();
    error AlreadyPayed();
    error InvalidValueRating(uint256 rating, uint256 min_rating, uint256 max_rating);
    error ContractStopped();
    error AlreadyRatingTodayForReviewer();
    error AlreadyRatingTodayForJournalist();
    error WrongReviewer();
    error WrongJournalist();
    error NotEnoughToken();
    error AlreadyProposalToday();

    event BecomeReviewer(address indexed _address, string _names);
    event BecomeJournalist(address indexed _address, string _names);
    event RatingReviewer(address indexed _from, address indexed _to, uint256 _rating, string _CID);
    event RatingJournalist(address indexed _from, address indexed _to, uint256 _rating, string _CID);
    event New_Sponsor_Reviewer(address indexed _from, uint256 indexed _to, int256 _sponsor);
    event New_Sponsor_Journalist(address indexed _from, uint256 indexed _to, int256 _sponsor);

    struct proposal_reviewer {
        address _address;
        address _mean_sponsor;
        uint256 _num_sponsors;
        string  _names;
    }

    struct proposal_journalist {
        address _address;
        address _mean_sponsor;
        uint256 _num_sponsors;
        string  _names;
    }

    struct reviewer {
        string  _names;
        uint256 rating;
        uint256 first_day; //like id
        uint256 day_payed;
        //uint256 rating_weight;
        uint256 last_rating_day_reviewer;
        uint256 last_rating_day_journalist;
        uint256 last_day_sponsor_reviewer;
        uint256 last_day_sponsor_journalist;
    }

    struct journalist {
        string  _names;
        uint256 rating;
        uint256 first_day; //like id
        uint256 day_payed;
        //uint256 rating_weight;
    }

    mapping(uint256 => address) Journalists_ID;
    mapping(uint256 => address) Reviewers_ID;

    mapping(address => reviewer) public Reviewers;
    mapping(address => journalist) public Journalists;
    mapping(uint256 => proposal_reviewer) public Proposal_Reviewers;
    mapping(uint256 => proposal_journalist) public Proposal_Journalists;

    constructor() ERC20("PayPerTrustToken", "PPTT") {
        StartDay = block.timestamp / 1 days;
        EndDay = StartDay + 3650;       // 10 years

        Reviewers[msg.sender].rating = 50;
        Reviewers[msg.sender].first_day = StartDay;
        Reviewers[msg.sender].day_payed = StartDay;
       // Reviewers[msg.sender].rating_weight = 1;
        Reviewers[msg.sender].last_rating_day_reviewer = StartDay - 1;
        Reviewers[msg.sender].last_rating_day_journalist = StartDay - 1;
        Reviewers[msg.sender].last_day_sponsor_reviewer = StartDay - 1;
        Reviewers[msg.sender].last_day_sponsor_journalist = StartDay - 1;
        Reviewers_ID[StartDay] = msg.sender;

        Num_Reviewers = 1;
        Total_Rating_Reviewer = 50;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner not_finished{
        _unpause();
    }

    modifier only_reviewer() {
        if (Reviewers[msg.sender].rating == 0) {
            revert YouAreNotReviewer();
        }
        _;
    }

    modifier only_journalist() {
        if (Journalists[msg.sender].rating == 0) {
            revert YouAreNotJournalist();
        }
        _;
    }

    modifier not_finished() {
        if (block.timestamp / 1 days <= EndDay) {
            revert ContractStopped();
        }
        _;
    }

    function add_proposal_reviewer(address _address, string memory _names) nonReentrant only_reviewer whenNotPaused not_finished external payable {
        if (msg.value != 0.1 ether){
            revert InvalidAmount({
                sent: msg.value,
                Required: 0.1 ether
            });
        }
        if (Reviewers[_address].last_day_sponsor_reviewer == block.timestamp / 1 days) {
            revert AlreadyProposalToday();
        }
        Reviewers[_address].last_day_sponsor_reviewer = block.timestamp / 1 days;
        if (Last_Reviewer_Proposal < block.timestamp / 1 days)
            Last_Reviewer_Proposal = block.timestamp / 1 days;
        else
            Last_Reviewer_Proposal += 1 days;
        Proposal_Reviewers[Last_Reviewer_Proposal]._num_sponsors = 0;
        Proposal_Reviewers[Last_Reviewer_Proposal]._address = _address;
        Proposal_Reviewers[Last_Reviewer_Proposal]._mean_sponsor = msg.sender;
        Proposal_Reviewers[Last_Reviewer_Proposal]._names = _names;
    }

    function add_proposal_journalist(address _address, string memory _names) nonReentrant only_reviewer whenNotPaused not_finished external payable {
        if (msg.value != 0.1 ether){
            revert InvalidAmount({
                sent: msg.value,
                Required: 0.1 ether
            });
        }
        if (Reviewers[_address].last_day_sponsor_journalist == block.timestamp / 1 days) {
            revert AlreadyProposalToday();
        }
        Reviewers[_address].last_day_sponsor_journalist = block.timestamp / 1 days;
        if (Last_Journalist_Proposal < block.timestamp / 1 days)
            Last_Journalist_Proposal = block.timestamp / 1 days;
        else
            Last_Journalist_Proposal += 1 days;
        Proposal_Journalists[Last_Journalist_Proposal]._num_sponsors = 0;
        Proposal_Journalists[Last_Journalist_Proposal]._address = _address;
        Proposal_Journalists[Last_Journalist_Proposal]._mean_sponsor = msg.sender;
        Proposal_Journalists[Last_Journalist_Proposal]._names = _names;
    }

    function add_sponsors_reviewer(int256 _sponsor) nonReentrant only_reviewer whenNotPaused not_finished external {
        if (Last_Reviewer_Proposal == block.timestamp / 1 days)
            revert NoProposalReviewers();
        if (_sponsor > 0)
            Proposal_Reviewers[block.timestamp / 1 days]._num_sponsors += 1;
        else
            Proposal_Reviewers[block.timestamp / 1 days]._num_sponsors -= 1;
        emit New_Sponsor_Reviewer(msg.sender, block.timestamp / 1 days , _sponsor);
    }

    function add_sponsors_journalist(int256 _sponsor) nonReentrant only_reviewer whenNotPaused not_finished external {
        if (Last_Journalist_Proposal == block.timestamp / 1 days)
            revert NoProposalJournalists();
        if (_sponsor > 0)
            Proposal_Journalists[block.timestamp / 1 days]._num_sponsors += 1;
        else
            Proposal_Journalists[block.timestamp / 1 days]._num_sponsors -= 1;
        emit New_Sponsor_Journalist(msg.sender, block.timestamp / 1 days , _sponsor);
    }

    function become_reviewer(uint256 _id) nonReentrant whenNotPaused not_finished external {
        if (_id < block.timestamp / 1 days)
            revert VoteNotCompleted();
        if (Reviewers[msg.sender].rating != 0)
            revert AlreadyReviewer();
        if (Proposal_Reviewers[_id]._address != msg.sender || Proposal_Reviewers[_id]._num_sponsors < 0)
            revert YouAreNotReviewer();
        Reviewers[msg.sender].rating = Total_Rating_Reviewer / Num_Reviewers;
        Reviewers[msg.sender].first_day = _id;
        Reviewers[msg.sender].day_payed = _id;
        Reviewers[msg.sender]._names = Proposal_Reviewers[_id]._names;
      //  Reviewers[msg.sender].rating_weight = 1;
        ++Num_Reviewers;
        Total_Rating_Reviewer += Reviewers[msg.sender].rating;
        transfer(Proposal_Reviewers[_id]._mean_sponsor, 0.09 ether);
        Reviewers_ID[_id] = msg.sender;
        emit BecomeReviewer(msg.sender, Reviewers[msg.sender]._names);
    }

    function become_journalist(uint256 _id) nonReentrant whenNotPaused not_finished external {
        if (_id < block.timestamp / 1 days)
            revert VoteNotCompleted();
        if (Journalists[msg.sender].rating != 0)
            revert AlreadyJournalist();
        if (Proposal_Journalists[_id]._address != msg.sender || Proposal_Journalists[_id]._num_sponsors < 0)
            revert YouAreNotJournalist();
        Journalists[msg.sender].rating = Total_Rating_Journalist / Num_Journalists;
        Journalists[msg.sender].first_day = _id;
        Journalists[msg.sender].day_payed = _id;
        Journalists[msg.sender]._names = Proposal_Journalists[_id]._names;
      //  Journalists[msg.sender].rating_weight = 1;
        ++Num_Journalists;
        Total_Rating_Journalist += Journalists[msg.sender].rating;
        transfer(Proposal_Journalists[_id]._mean_sponsor, 0.09 ether);
        Journalists_ID[_id] = msg.sender;
        emit BecomeJournalist(msg.sender, Journalists[msg.sender]._names);
    }

    function pay_reviewer() nonReentrant only_reviewer whenNotPaused not_finished external {
        _mint(msg.sender, get_claimable_value(msg.sender)); // ??
        Reviewers[msg.sender].day_payed = block.timestamp / 1 days;
     }

    function rating_reviewer(address _address, uint256 _rating, string memory _CID) nonReentrant only_reviewer whenNotPaused not_finished external {
        if (Reviewers[_address].rating == 0)
            revert UserNotExist();
        uint256 first_reviewer;
        uint256 second_reviewer;
        (,first_reviewer,,second_reviewer) = pick_reviewer();
        if (first_reviewer != Reviewers[_address].first_day || second_reviewer != Reviewers[_address].first_day)
            revert WrongReviewer();
        if (Reviewers[msg.sender].last_rating_day_reviewer == block.timestamp / 1 days)
            revert AlreadyRatingTodayForReviewer();
        Reviewers[msg.sender].last_rating_day_reviewer = block.timestamp / 1 days;
        uint256 _min_rating;
        uint256 _max_rating;
        (_min_rating, _max_rating) = reviewer_voting_range(_address);
        if (_rating > _max_rating || _rating < _min_rating){
            revert InvalidValueRating({
                rating: _rating,
                min_rating: _min_rating,
                max_rating: _max_rating
            });
        }
        Total_Rating_Reviewer += (_rating - Reviewers[_address].rating);
        if (_rating == 0) {
       //     Reviewers[_address].rating_weight = 0;
            --Num_Reviewers;
        }
        Reviewers[_address].rating = _rating;
        emit RatingReviewer(msg.sender, _address, _rating, _CID);
    }

    function rating_journalist(address _address, uint256 _rating, string memory _CID) nonReentrant only_reviewer whenNotPaused not_finished external {
        if (Journalists[_address].rating == 0)
            revert UserNotExist();
        uint256 first_journalist;
        uint256 second_journalist;
        (,first_journalist,, second_journalist) = pick_journalist();
        if (first_journalist != Journalists[_address].first_day || second_journalist != Journalists[_address].first_day)
            revert WrongJournalist();
        if (Reviewers[msg.sender].last_rating_day_journalist == block.timestamp / 1 days)
            revert AlreadyRatingTodayForJournalist();
        Reviewers[msg.sender].last_rating_day_journalist = block.timestamp / 1 days;
        uint256 _min_rating;
        uint256 _max_rating;
        (_min_rating, _max_rating) = journalist_voting_range(_address);
        if (_rating > _max_rating || _rating < _min_rating){
            revert InvalidValueRating({
                rating: _rating,
                min_rating: _min_rating,
                max_rating: _max_rating
            });
        }
        Total_Rating_Journalist += (_rating - Journalists[_address].rating);
        if (_rating == 0){
         //   Journalists[_address].rating_weight = 0;
            --Num_Journalists;  
        }
        Journalists[_address].rating = _rating;
        emit RatingJournalist(msg.sender, _address, _rating, _CID);
    }

    function reviewer_voting_range(address _address) whenNotPaused not_finished public view returns (uint256, uint256) {
        if (Reviewers[_address].rating == 0)
            revert UserNotExist();
        uint256 min_rating = max(0, min(Reviewers[_address].rating - 10, Reviewers[_address].rating * 9 / 10));
        uint256 max_rating = max(Reviewers[_address].rating + 10, Reviewers[_address].rating * 11 / 10);
        return (min_rating, max_rating);
    }

    function journalist_voting_range(address _address) whenNotPaused not_finished public view returns (uint256, uint256) {
        if (Journalists[_address].rating == 0)
            revert UserNotExist();
        uint256 min_rating = max(0, min(Journalists[_address].rating - 10, Journalists[_address].rating * 9 / 10));
        uint256 max_rating = max(Journalists[_address].rating + 10, Journalists[_address].rating * 11 / 10);
        return (min_rating, max_rating);
    }

    function pick_reviewer() nonReentrant only_reviewer whenNotPaused not_finished public returns (address, uint256, address, uint256) {
        uint256 first_reviewer = (uint256(uint160(msg.sender)) * block.timestamp / 1 days);
        uint256 second_reviewer = first_reviewer + 42;

        first_reviewer = first_reviewer % Num_Reviewers;
        second_reviewer = second_reviewer % Num_Reviewers;
        return (
            Reviewers_ID[first_reviewer], first_reviewer,
            Reviewers_ID[second_reviewer], second_reviewer
        ); 
    }

    function pick_journalist() nonReentrant only_reviewer whenNotPaused not_finished public returns (address, uint256, address, uint256) {
        uint256 first_journalist = (uint256(uint160(msg.sender)) * block.timestamp / 1 days);
        uint256 second_journalist = first_journalist + 42;

        first_journalist = first_journalist % Num_Journalists;
        second_journalist = second_journalist % Num_Journalists;
        return (
            Journalists_ID[first_journalist], first_journalist,
            Journalists_ID[second_journalist], second_journalist
        );
    }
    
    function get_reviewer(address _address) external view returns(uint256, uint256, uint256, string memory) {
        if (Reviewers[_address].rating == 0)
            revert UserNotExist();
        return (Reviewers[_address].rating, Reviewers[_address].first_day, Reviewers[_address].day_payed, Reviewers[_address]._names); //, Reviewers[_address].rating_weight
    }

    function get_journalist(address _address) external view returns(uint256, uint256, uint256, string memory) {
        if (Journalists[_address].rating == 0)
            revert UserNotExist();
        return (Journalists[_address].rating, Journalists[_address].first_day, Journalists[_address].day_payed, Journalists[_address]._names); //, Reviewers[_address].rating_weight
    }

    function get_unpaid_days_reviewer(address _address) public view returns(uint256) {
        if (Reviewers[_address].rating == 0)
            revert UserNotExist();
        if (block.timestamp / 1 days == Reviewers[_address].day_payed)
            revert AlreadyPayed();
        return block.timestamp / 1 days - Reviewers[_address].day_payed;
    }

    function get_claimable_value(address _address) public view returns(uint256) {
        if (Reviewers[_address].rating == 0)
            revert UserNotExist();
        uint256 _claimable_value = get_unpaid_days_reviewer(_address) * MaxSupplyPerDay * (Reviewers[_address].rating / Total_Rating_Reviewer);
        if (_claimable_value > MaxSupply - TotalSupply)
            revert NotEnoughToken();
        return _claimable_value;
    }

    function get_mean_rating_journalist() external view returns(uint256) {
        if (Num_Journalists == 0)
            revert NoUsers();
        return (Total_Rating_Journalist / Num_Journalists);
    }

    function get_mean_rating_reviewer() external view returns(uint256) {
        if (Num_Reviewers == 0)
            revert NoUsers();
        return (Total_Rating_Reviewer / Num_Reviewers);
    }

    function get_num_reviewers() external view returns(uint256) {
        return Num_Reviewers;
    }

    function get_num_journalists() external view returns(uint256) {
        return Num_Journalists;
    }

    function get_reviewer_can_rate_reviewer(address _address) external view returns(bool) {
        if (Reviewers[_address].rating == 0)
            revert UserNotExist();
        return (Reviewers[_address].last_rating_day_reviewer != block.timestamp / 1 days);
    }

    function get_reviewer_can_rate_journalist(address _address) external view returns(bool) {
        if (Reviewers[_address].rating == 0)
            revert UserNotExist();
        return (Reviewers[_address].last_rating_day_journalist != block.timestamp / 1 days);
    }

    function get_proposal_reviewer(uint256 _id) external view returns (address, address, uint256) {
        if (Proposal_Reviewers[_id]._address == address(0))
            revert NoProposalReviewers();
        return (Proposal_Reviewers[_id]._address, Proposal_Reviewers[_id]._mean_sponsor, Proposal_Reviewers[_id]._num_sponsors);
    }

    function get_proposal_journalist(uint256 _id) external view returns (address, address, uint256) {
        if (Proposal_Journalists[_id]._address == address(0))
            revert NoProposalJournalists();
        return (Proposal_Journalists[_id]._address, Proposal_Journalists[_id]._mean_sponsor, Proposal_Journalists[_id]._num_sponsors);
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}