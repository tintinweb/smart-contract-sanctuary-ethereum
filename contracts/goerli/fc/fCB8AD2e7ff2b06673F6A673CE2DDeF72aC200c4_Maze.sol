// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IMaze.sol";
import "./interfaces/IBlacklist.sol";

/// @title ERC20 token with RFI logic
/// @dev NOTE: This contract uses the principals of RFI tokens
///            for detailed documentation please see:
///            https://reflect-contract-doc.netlify.app/#a-technical-whitepaper-for-reflect-contracts
contract Maze is IMaze, Ownable, Pausable {
    using SafeMath for uint256;

    /// @notice The address of the Blacklist contract
    address public blacklist;

    /// @dev Balances in r-space
    mapping(address => uint256) private _rOwned;
    /// @dev Balances in t-space
    mapping(address => uint256) private _tOwned;
    /// @dev Allowances in t-space
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @notice Marks that account is exluded from staking. Exluded accounts do not
    ///         get shares of distributed fees
    mapping(address => bool) public isExcluded;
    /// @dev The list of all exluded accounts
    address[] private _excluded;

    /// @dev Maximum possible amount of tokens is 100 million
    // TODO make it const if no burn
    uint256 private _tTotal = 100_000_000 * 1e18;

    /// @dev RFI-special variables
    uint256 private constant MAX = ~uint256(0);
    /// @dev _rTotal is multiple of _tTotal
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    /// @dev Total amount of fees collected in t-space
    uint256 private _tFeeTotal;

    // Basic token info
    string public name = "Maze";
    string public symbol = "MAZE";
    uint8 public decimals = 18;

    /// @dev Used to convert BPs to percents and vice versa
    uint256 private constant percentConverter = 1e4;

    /// @notice List of whitelisted accounts. Whitelisted accounts do not pay fees on token transfers.
    mapping(address => bool) public isWhitelisted;

    /// @notice The percentage of transferred tokens to be taken as fee for any token transfers
    ///         Fee is distributed among token holders
    ///         Expressed in basis points
    uint256 public feeInBP;

    /// @notice Checks that account is not blacklisted
    modifier ifNotBlacklisted(address account) {
        require(
            !IBlacklist(blacklist).checkBlacklisted(account),
            "Maze: Account is blacklisted"
        );
        _;
    }

    constructor(address blacklist_) {
        blacklist = blacklist_;

        // Whole supply of tokens is assigned to owner
        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _tTotal);

        // Set default fees to 2%
        setFees(200);
    }

    /// @notice See {IMaze-totalSupply}
    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    /// @notice See {IMaze-totalFee}
    function totalFee() public view returns (uint256) {
        return _tFeeTotal;
    }

    /// @notice See {IMaze-balanceOf}
    function balanceOf(address account) public view returns (uint256) {
        if (isExcluded[account]) {
            // If user is excluded from stakers, his balance is the amount of t-space tokens he owns
            return _tOwned[account];
        } else {
            // If users is one of stakers, his balance is calculated using r-space tokens
            uint256 reflectedBalance = _reflectToTSpace(_rOwned[account]);
            return reflectedBalance;
        }
    }

    /// @notice See {IMaze-allowance}
    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @notice See {IMaze-approve}
    function approve(
        address spender,
        uint256 amount
    ) public whenNotPaused returns (bool) {
        require(spender != address(0), "Maze: Spender cannot be zero address");
        require(amount != 0, "Maze: Allowance cannot be zero");
        _approve(msg.sender, spender, amount);
        return true;
    }

    /// @notice See {IMaze-burn}
    function burn(uint256 amount) public whenNotPaused {
        _burn(msg.sender, amount);
    }

    /// @notice See {IMaze-transfer}
    function transfer(
        address to,
        uint256 amount
    ) public whenNotPaused returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice See {IMaze-transferFrom}
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "Maze: Transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /// @notice See {IMaze-increaseAllowance}
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public whenNotPaused returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /// @notice See {IMaze-decreaseAllowance}
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public whenNotPaused returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "Maze: Allowance cannot be below zero"
            )
        );
        return true;
    }

    /// @notice See {IMaze-setFees}
    function setFees(
        uint256 _feeInBP
    ) public whenNotPaused ifNotBlacklisted(msg.sender) onlyOwner {
        require(_feeInBP < 1e4, "Maze: Fee too high");
        feeInBP = _feeInBP;
        emit SetFees(_feeInBP);
    }

    /// @notice See {IMaze-addToWhitelist}
    function addToWhitelist(
        address account
    ) public whenNotPaused ifNotBlacklisted(msg.sender) onlyOwner {
        require(!isWhitelisted[account], "Maze: Account already whitelisted");
        isWhitelisted[account] = true;
        emit AddToWhitelist(account);
    }

    /// @notice See {IMaze-removeFromWhitelist}
    function removeFromWhitelist(
        address account
    ) public whenNotPaused ifNotBlacklisted(msg.sender) onlyOwner {
        require(isWhitelisted[account], "Maze: Account not whitelisted");
        isWhitelisted[account] = false;
        emit RemoveFromWhitelist(account);
    }

    /// @notice See {IMaze-pause}
    function pause() public ifNotBlacklisted(msg.sender) onlyOwner {
        _pause();
    }

    /// @notice See {IMaze-unpause}
    function unpause() public ifNotBlacklisted(msg.sender) onlyOwner {
        _unpause();
    }

    /// @notice See {IMaze-includeIntoStakers}
    function includeIntoStakers(
        address account
    ) public whenNotPaused ifNotBlacklisted(msg.sender) onlyOwner {
        require(account != address(0), "Maze: Cannot include zero address");
        require(isExcluded[account], "Maze: Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            // Remove account from list of exluded
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _excluded.pop();
                break;
            }
        }
        // T-space balance gets reset when users joins r-space again
        _tOwned[account] = 0;
        isExcluded[account] = false;
        emit IncludeIntoStakers(account);
    }

    /// @notice See {IMaze-excludeFromStakers}
    function excludeFromStakers(
        address account
    ) public whenNotPaused ifNotBlacklisted(msg.sender) onlyOwner {
        require(account != address(0), "Maze: Cannot exclude zero address");
        require(!isExcluded[account], "Maze: Account is already excluded");
        // Update owned amount in t-space before excluding
        if (_rOwned[account] > 0) {
            _tOwned[account] = _reflectToTSpace(_rOwned[account]);
        }
        isExcluded[account] = true;
        _excluded.push(account);
        emit ExcludeFromStakers(account);
    }

    /// @notice Reflect twhole amount and fee okens amount from r-space to t-space
    /// @param rAmountWithFee Token amount in r-space
    /// @return The reflected amount of tokens (r-space)
    /// @dev tAmountWithFee = rAmountWithFee / rate
    function _reflectToTSpace(
        uint256 rAmountWithFee
    ) private view returns (uint256) {
        require(
            rAmountWithFee <= _rTotal,
            "Maze: Amount must be less than total reflections"
        );
        uint256 rate = _getRate();
        return rAmountWithFee.div(rate);
    }

    /// @dev Calculates 2 t-space and 3 r-space values based on one t-space amount
    /// @param tAmountNoFee The transferred amount without fees (t-space)
    /// @return The whole transferred amount including fees (r-space)
    /// @return Amount of tokens to be transferred to the recipient (r-space)
    /// @return Amount of tokens to be takes as fees (r-space)
    /// @return The whole transferred amount including fees (t-space)
    /// @return Amount of tokens to be taken as fees (t-space)
    function _getValues(
        uint256 tAmountNoFee
    ) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tAmountWithFee, uint256 tFee) = _getTValues(tAmountNoFee);
        uint256 rate = _getRate();
        (
            uint256 rAmountWithFee,
            uint256 rAmountNoFee,
            uint256 rFee
        ) = _getRValues(tAmountWithFee, tFee, rate);
        return (rAmountWithFee, rAmountNoFee, rFee, tAmountWithFee, tFee);
    }

    /// @dev Calculates transferred amount and fee amount in t-space
    /// @param tAmountNoFee The transferred amount without fees (t-space)
    /// @return Amount of tokens to be withdrawn from sender including fees (t-space)
    /// @return Amount of tokens to be taken as fees (t-space)
    function _getTValues(
        uint256 tAmountNoFee
    ) private view returns (uint256, uint256) {
        uint256 tFee = 0;
        // Whitelisted users don't pay fees
        if (!isWhitelisted[msg.sender]) {
            tFee = tAmountNoFee.mul(feeInBP).div(percentConverter);
        }
        // Withdrawn amount = whole amount + fees
        uint256 tAmountWithFee = tAmountNoFee.add(tFee);
        return (tAmountWithFee, tFee);
    }

    /// @dev Calculates reflected amounts (from t-space) in r-space
    /// @param tAmountWithFee The whole transferred amount including fees (t-space)
    /// @param tFee Fee amount (t-space)
    /// @param rate Rate of conversion between t-space and r-space
    /// @return The whole transferred amount including fees (r-space)
    /// @return Amount of tokens to be transferred to the recipient (r-space)
    /// @return Amount of tokens to be taken as fees (r-space)
    function _getRValues(
        uint256 tAmountWithFee,
        uint256 tFee,
        uint256 rate
    ) private pure returns (uint256, uint256, uint256) {
        // Reflect whole amount and fee from t-space into r-space
        uint256 rAmountWithFee = tAmountWithFee.mul(rate);
        uint256 rFee = tFee.mul(rate);
        // Received amount = whole amount - fees
        uint256 rAmountNoFee = rAmountWithFee.sub(rFee);
        return (rAmountWithFee, rAmountNoFee, rFee);
    }

    /// @dev Calculates current conversion rate
    /// @return Conversion rate
    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getSupplies();
        // Rate is a ratio of r-space supply and t-space supply
        return rSupply.div(tSupply);
    }

    /// @dev Calculates supplies of tokens in r-space and t-space
    ///      Supply is the total amount of tokens in the space minus amount of
    ///      tokens owned by non-stakers (exluded users)
    /// @return Supply of tokens (r-space)
    /// @return Supply of tokens (t-space)
    function _getSupplies() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        // Decrease supplies by amount owned by non-stakers
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) {
                return (_rTotal, _tTotal);
            }
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }

        if (rSupply < _rTotal.div(_tTotal)) {
            return (_rTotal, _tTotal);
        }
        return (rSupply, tSupply);
    }

    /// @dev Allows spender to spend tokens on behalf of the transaction sender via transferFrom
    /// @param owner Owner's address
    /// @param spender Spender's address
    /// @param amount The amount of tokens spender is allowed to spend
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private ifNotBlacklisted(owner) ifNotBlacklisted(spender) {
        require(owner != address(0), "Maze: Approve from the zero address");
        require(spender != address(0), "Maze: Approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // TODO add mint here???

    /// @dev Burns user's tokens decreasing supply in both t-space and r-space
    /// @param from The address to burn tokens from
    /// @param amount The amount of tokens to burn
    function _burn(
        address from,
        uint256 amount
    ) private ifNotBlacklisted(from) {
        require(from != address(0), "Maze: Burn from the zero address");
        require(balanceOf(from) >= amount, "Maze: Burn amount exceeds balance");
        uint256 rate = _getRate();
        if (isExcluded[from]) {
            // Decrease balances of excluded account in both r-space and t-space
            _rOwned[from] = _rOwned[from].sub(amount.mul(rate));
            _tOwned[from] = _tOwned[from].sub(amount);
        } else {
            // Decrease balance of included account only in r-space
            _rOwned[from] = _rOwned[from].sub(amount.mul(rate));
        }
        // Decrease supplies of tokens in both r-space and t-space
        // This does not distribute burnt tokens like fees
        // because both supplies are reduced and the rate stays the same
        _rTotal = _rTotal.sub(amount.mul(rate));
        _tTotal = _tTotal.sub(amount);
        emit Transfer(from, address(0), amount);
    }

    /// @dev Transfers tokens to the given address
    /// @param from Sender's address
    /// @param to Recipient's address
    /// @param amount The amount of tokens to send without fees
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private ifNotBlacklisted(from) ifNotBlacklisted(to) {
        require(from != address(0), "Maze: Transfer from the zero address");
        require(amount > 0, "Maze: Transfer amount must be greater than zero");
        require(
            balanceOf(from) >= amount,
            "Maze: Transfer amount exceeds balance"
        );

        // Next transfer logic depends on which accout is excluded (in any)
        // If account is excluded his t-space balance does not change
        if (isExcluded[from] && !isExcluded[to]) {
            _transferFromExcluded(from, to, amount);
        } else if (!isExcluded[from] && isExcluded[to]) {
            _transferToExcluded(from, to, amount);
        } else if (!isExcluded[from] && !isExcluded[to]) {
            _transferStandard(from, to, amount);
        } else if (isExcluded[from] && isExcluded[to]) {
            _transferBothExcluded(from, to, amount);
        } else {
            _transferStandard(from, to, amount);
        }
    }

    /// @dev Transfers tokens from included account to included account
    /// @param from Sender's address
    /// @param to Recipient's address
    /// @param tAmountNoFee The amount of tokens to send without fees
    function _transferStandard(
        address from,
        address to,
        uint256 tAmountNoFee
    ) private {
        (
            uint256 rAmountWithFee,
            uint256 rAmountNoFee,
            uint256 rFee,
            uint256 tAmountWithFee,
            uint256 tFee
        ) = _getValues(tAmountNoFee);
        // Only change sender's and recipient's balances in r-space (they are both included)
        // Sender looses whole amount plus fees
        _rOwned[from] = _rOwned[from].sub(rAmountWithFee);
        // Recipient recieves whole amount (fees are distributed automatically)
        _rOwned[to] = _rOwned[to].add(rAmountNoFee);
        _processFees(rFee, tFee);
        emit Transfer(from, to, tAmountNoFee);
    }

    /// @dev Transfers tokens from included account to excluded account
    /// @param from Sender's address
    /// @param to Recipient's address
    /// @param tAmountNoFee The amount of tokens to send without fees
    function _transferToExcluded(
        address from,
        address to,
        uint256 tAmountNoFee
    ) private {
        (
            uint256 rAmountWithFee,
            uint256 rAmountNoFee,
            uint256 rFee,
            uint256 tAmountWithFee,
            uint256 tFee
        ) = _getValues(tAmountNoFee);
        // Only decrease sender's balance in r-space (he is included)
        // Sender looses whole amount plus fees
        _rOwned[from] = _rOwned[from].sub(rAmountWithFee);
        // Increase recipient's balance in both t-space and r-space
        // Recipient recieves whole amount (fees are distributed automatically)
        _tOwned[to] = _tOwned[to].add(tAmountNoFee);
        _rOwned[to] = _rOwned[to].add(rAmountNoFee);
        _processFees(rFee, tFee);
        emit Transfer(from, to, tAmountNoFee);
    }

    /// @dev Transfers tokens from excluded to included account
    /// @param from Sender's address
    /// @param to Recipient's address
    /// @param tAmountNoFee The amount of tokens to send without fees
    function _transferFromExcluded(
        address from,
        address to,
        uint256 tAmountNoFee
    ) private {
        (
            uint256 rAmountWithFee,
            uint256 rAmountNoFee,
            uint256 rFee,
            uint256 tAmountWithFee,
            uint256 tFee
        ) = _getValues(tAmountNoFee);
        // Decrease sender's balances in both t-space and r-space
        // Sender looses whole amount plus fees
        _tOwned[from] = _tOwned[from].sub(tAmountWithFee);
        _rOwned[from] = _rOwned[from].sub(rAmountWithFee);
        // Only increase recipient's balance in r-space (he is included)
        // Recipient recieves whole amount (fees are distributed automatically)
        _rOwned[to] = _rOwned[to].add(rAmountNoFee);
        _processFees(rFee, tFee);
        emit Transfer(from, to, tAmountNoFee);
    }

    /// @dev Transfers tokens between two exluced accounts
    /// @param from Sender's address
    /// @param to Recipient's address
    /// @param tAmountNoFee The amount of tokens to send without fees
    function _transferBothExcluded(
        address from,
        address to,
        uint256 tAmountNoFee
    ) private {
        (
            uint256 rAmountWithFee,
            uint256 rAmountNoFee,
            uint256 rFee,
            uint256 tAmountWithFee,
            uint256 tFee
        ) = _getValues(tAmountNoFee);
        // Decrease sender's balances in both t-space and r-space
        // Sender looses whole amount plus fees
        _tOwned[from] = _tOwned[from].sub(tAmountWithFee);
        _rOwned[from] = _rOwned[from].sub(rAmountWithFee);
        // Increase recipient's balances in both t-space and r-space
        // Recipient recieves whole amount (fees are distributed automatically)
        _tOwned[to] = _tOwned[to].add(tAmountNoFee);
        _rOwned[to] = _rOwned[to].add(rAmountNoFee);
        _processFees(rFee, tFee);
        emit Transfer(from, to, tAmountNoFee);
    }

    /// @dev Distributes r-space fees among stakers
    /// @param rFee Fee amount (r-space)
    /// @param tFee Fee amount (t-space)
    function _processFees(uint256 rFee, uint256 tFee) private {
        // Decrease the total amount of r-space tokens.
        // This is the fees distribution.
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
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

pragma solidity ^0.8.12;

interface IBlacklist {
    /// @notice Indicates that account has been added to the blacklist
    /// @param account The account added to the blacklist
    event AddToBlacklist(address account);

    /// @notice Indicates that account has been removed from the blacklist
    /// @param account The account removed from the blacklist
    event RemoveFromBlacklist(address account);

    /// @notice Checks if account is blacklisted
    /// @param account The account to check
    /// @return True if account is blacklisted. Otherwise - false
    function checkBlacklisted(address account) external view returns (bool);

    /// @notice Adds a new account to the blacklist
    /// @param account The account to add to the blacklist
    function addToBlacklist(address account) external;

    /// @notice Removes account from the blacklist
    /// @param account The account to remove from the blacklist
    function removeFromBlacklist(address account) external;

    /// @notice Pause the contract
    function pause() external;

    /// @notice Unpause the contract
    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/// @notice Interface of the ERC20 standard as defined in the EIP.
interface IMaze {
    /// @notice Indicates that `amount` tokens has been transferred from `from` to `to`
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice Indicates that allowance from `owner` for `spender` is now equal to `allowance`
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 allowance
    );

    /// @notice Indicates that fee amount has been changed
    event SetFees(uint256 newFeeAmount);

    /// @notice Indicates that user has been added to whitelist
    event AddToWhitelist(address account);

    /// @notice Indicates that user has been removed from whitelist
    event RemoveFromWhitelist(address account);

    /// @notice Indicates that user has been included into stakers
    event IncludeIntoStakers(address account);

    /// @notice Indicates that user has been excluded from stakers
    event ExcludeFromStakers(address account);

    /// @notice Returns the amount of tokens in existence
    function totalSupply() external view returns (uint256);

    /// @notice Returns total collected fee
    function totalFee() external view returns (uint256);

    /// @notice Returns the balance of the user
    /// @param account The address of the user
    function balanceOf(address account) external view returns (uint256);

    /// @notice Returns the amount of tokens that spender is allowed to spend on behalf of owner
    /// @param owner Token owner's address
    /// @param spender Spender's address
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /// @notice Allows spender to spend tokens on behalf of the transaction sender via transferFrom
    /// @param spender Spender's address
    /// @param amount The amount of tokens spender is allowed to spend
    /// @return Boolean value indicating that operation succeded
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Increases the amount of tokens to spend on behalf of an owner
    /// @param spender Spender's address
    /// @param addedValue Amount of tokens to add to allowance
    /// @return Boolean value indicating that operation succeded
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    /// @notice Decrease the amount of tokens to spend on behalf of an owner
    /// @param spender Spender's address
    /// @param subtractedValue Amount of tokens to subtract from allowance
    /// @return Boolean value indicating that operation succeded
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool);

    /// @notice Transfers tokens to the given address
    /// @param to Recipient's address
    /// @param amount The amount of tokens to send
    /// @return Boolean value indicating that operation succeded
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Transfers tokens to a given address on behalf of the owner
    /// @param from Sender's address
    /// @param to Recipient's address
    /// @param amount The amount of tokens to send
    /// @return Boolean value indicating that operation succeded
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /// @notice Set transaction fee amount in basis points
    /// @param _feeInBP Fee amount in basis points
    function setFees(uint256 _feeInBP) external;

    /// @notice Adds a user to the whitelist
    ///         Whitelisted users do not pay fees
    /// @param account Address of the user
    function addToWhitelist(address account) external;

    /// @notice Remove a user from the whitelist
    ///         Whitelisted users do not pay fees
    /// @param account Address of the user
    function removeFromWhitelist(address account) external;

    /// @notice Pause the contract
    function pause() external;

    /// @notice Unpause the contract
    function unpause() external;

    /// @notice Includes the user to the stakers list.
    ///         Included users get shares of fees from tokens transfers
    /// @param account The address of the user to include into stakers
    function includeIntoStakers(address account) external;

    /// @notice Exclude the user from the stakers list.
    ///         Excluded users do not get shares of fees from tokens transfers
    /// @param account The address of the user to exlude from stakers
    function excludeFromStakers(address account) external;

    /// @notice Burns tokens of the user
    /// @param amount The amount of tokens to burn
    function burn(uint256 amount) external;
}