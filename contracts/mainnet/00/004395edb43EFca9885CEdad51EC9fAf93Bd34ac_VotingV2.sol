// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Arrays.sol";
import "../../../utils/Counters.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the begining of each new block. When overridding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MultiRole.sol";
import "../interfaces/ExpandedIERC20.sol";

/**
 * @title An ERC20 with permissioned burning and minting. The contract deployer will initially
 * be the owner who is capable of adding new roles.
 */
contract ExpandedERC20 is ExpandedIERC20, ERC20, MultiRole {
    enum Roles {
        // Can set the minter and burner.
        Owner,
        // Addresses that can mint new tokens.
        Minter,
        // Addresses that can burn tokens that address owns.
        Burner
    }

    uint8 _decimals;

    /**
     * @notice Constructs the ExpandedERC20.
     * @param _tokenName The name which describes the new token.
     * @param _tokenSymbol The ticker abbreviation of the name. Ideally < 5 chars.
     * @param _tokenDecimals The number of decimals to define token precision.
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) ERC20(_tokenName, _tokenSymbol) {
        _decimals = _tokenDecimals;
        _createExclusiveRole(uint256(Roles.Owner), uint256(Roles.Owner), msg.sender);
        _createSharedRole(uint256(Roles.Minter), uint256(Roles.Owner), new address[](0));
        _createSharedRole(uint256(Roles.Burner), uint256(Roles.Owner), new address[](0));
    }

    function decimals() public view virtual override(ERC20) returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Mints `value` tokens to `recipient`, returning true on success.
     * @param recipient address to mint to.
     * @param value amount of tokens to mint.
     * @return True if the mint succeeded, or False.
     */
    function mint(address recipient, uint256 value)
        external
        override
        onlyRoleHolder(uint256(Roles.Minter))
        returns (bool)
    {
        _mint(recipient, value);
        return true;
    }

    /**
     * @dev Burns `value` tokens owned by `msg.sender`.
     * @param value amount of tokens to burn.
     */
    function burn(uint256 value) external override onlyRoleHolder(uint256(Roles.Burner)) {
        _burn(msg.sender, value);
    }

    /**
     * @dev Burns `value` tokens owned by `recipient`.
     * @param recipient address to burn tokens from.
     * @param value amount of tokens to burn.
     * @return True if the burn succeeded, or False.
     */
    function burnFrom(address recipient, uint256 value)
        external
        override
        onlyRoleHolder(uint256(Roles.Burner))
        returns (bool)
    {
        _burn(recipient, value);
        return true;
    }

    /**
     * @notice Add Minter role to account.
     * @dev The caller must have the Owner role.
     * @param account The address to which the Minter role is added.
     */
    function addMinter(address account) external virtual override {
        addMember(uint256(Roles.Minter), account);
    }

    /**
     * @notice Add Burner role to account.
     * @dev The caller must have the Owner role.
     * @param account The address to which the Burner role is added.
     */
    function addBurner(address account) external virtual override {
        addMember(uint256(Roles.Burner), account);
    }

    /**
     * @notice Reset Owner role to account.
     * @dev The caller must have the Owner role.
     * @param account The new holder of the Owner role.
     */
    function resetOwner(address account) external virtual override {
        resetMember(uint256(Roles.Owner), account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";

/**
 * @title Library for fixed point arithmetic on uints
 */
library FixedPoint {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 private constant FP_SCALING_FACTOR = 10**18;

    // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
    struct Unsigned {
        uint256 rawValue;
    }

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(uint256 a) internal pure returns (Unsigned memory) {
        return Unsigned(a.mul(FP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 mulRaw = a.rawValue.mul(b.rawValue);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
        if (mod != 0) {
            return Unsigned(mulFloor.add(1));
        } else {
            return Unsigned(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Since b is an uint, there is no risk of truncation and we can just mul it normally
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
        uint256 divFloor = aScaled.div(b.rawValue);
        uint256 mod = aScaled.mod(b.rawValue);
        if (mod != 0) {
            return Unsigned(divFloor.add(1));
        } else {
            return Unsigned(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(a.rawValue.div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED -------------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 private constant SFP_SCALING_FACTOR = 10**18;

    struct Signed {
        int256 rawValue;
    }

    function fromSigned(Signed memory a) internal pure returns (Unsigned memory) {
        require(a.rawValue >= 0, "Negative value provided");
        return Unsigned(uint256(a.rawValue));
    }

    function fromUnsigned(Unsigned memory a) internal pure returns (Signed memory) {
        require(a.rawValue <= uint256(type(int256).max), "Unsigned too large");
        return Signed(int256(a.rawValue));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
        return Signed(a.mul(SFP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled int256 from an `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 mulRaw = a.rawValue.mul(b.rawValue);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(mulTowardsZero.add(valueToAdd));
        } else {
            return Signed(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Signed` by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled int256 by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by an `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
        int256 divTowardsZero = aScaled.div(b.rawValue);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % b.rawValue;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(divTowardsZero.add(valueToAdd));
        } else {
            return Signed(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(a.rawValue.div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises an `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(Signed memory a, uint256 b) internal pure returns (Signed memory output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
contract Lockable {
    bool private _notEntered;

    constructor() {
        // Storing an initial non-zero value makes deployment a bit more expensive, but in exchange the refund on every
        // call to nonReentrant will be lower in amount. Since refunds are capped to a percentage of the total
        // transaction's gas, it is best to keep them low in cases like this one, to increase the likelihood of the full
        // refund coming into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant` function is not supported. It is possible to
     * prevent this from happening by making the `nonReentrant` function external, and making it call a `private`
     * function that does the actual state modification.
     */
    modifier nonReentrant() {
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    /**
     * @dev Designed to prevent a view-only method from being re-entered during a call to a `nonReentrant()` state-changing method.
     */
    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    // Internal methods are used to avoid copying the require statement's bytecode to every `nonReentrant()` method.
    // On entry into a function, `_preEntranceCheck()` should always be called to check if the function is being
    // re-entered. Then, if the function modifies state, it should call `_postEntranceSet()`, perform its logic, and
    // then call `_postEntranceReset()`.
    // View-only methods can simply call `_preEntranceCheck()` to make sure that it is not being re-entered.
    function _preEntranceCheck() internal view {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }

    // These functions are intended to be used by child contracts to temporarily disable and re-enable the guard.
    // Intended use:
    // _startReentrantGuardDisabled();
    // ...
    // _endReentrantGuardDisabled();
    //
    // IMPORTANT: these should NEVER be used in a method that isn't inside a nonReentrant block. Otherwise, it's
    // possible to permanently lock your contract.
    function _startReentrantGuardDisabled() internal {
        _notEntered = true;
    }

    function _endReentrantGuardDisabled() internal {
        _notEntered = false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// This contract is taken from Uniswap's multi call implementation (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/base/Multicall.sol)
// and was modified to be solidity 0.8 compatible. Additionally, the method was restricted to only work with msg.value
// set to 0 to avoid any nasty attack vectors on function calls that use value sent with deposits.

/// @title MultiCaller
/// @notice Enables calling multiple methods in a single call to the contract
contract MultiCaller {
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

library Exclusive {
    struct RoleMembership {
        address member;
    }

    function isMember(RoleMembership storage roleMembership, address memberToCheck) internal view returns (bool) {
        return roleMembership.member == memberToCheck;
    }

    function resetMember(RoleMembership storage roleMembership, address newMember) internal {
        require(newMember != address(0x0), "Cannot set an exclusive role to 0x0");
        roleMembership.member = newMember;
    }

    function getMember(RoleMembership storage roleMembership) internal view returns (address) {
        return roleMembership.member;
    }

    function init(RoleMembership storage roleMembership, address initialMember) internal {
        resetMember(roleMembership, initialMember);
    }
}

library Shared {
    struct RoleMembership {
        mapping(address => bool) members;
    }

    function isMember(RoleMembership storage roleMembership, address memberToCheck) internal view returns (bool) {
        return roleMembership.members[memberToCheck];
    }

    function addMember(RoleMembership storage roleMembership, address memberToAdd) internal {
        require(memberToAdd != address(0x0), "Cannot add 0x0 to a shared role");
        roleMembership.members[memberToAdd] = true;
    }

    function removeMember(RoleMembership storage roleMembership, address memberToRemove) internal {
        roleMembership.members[memberToRemove] = false;
    }

    function init(RoleMembership storage roleMembership, address[] memory initialMembers) internal {
        for (uint256 i = 0; i < initialMembers.length; i++) {
            addMember(roleMembership, initialMembers[i]);
        }
    }
}

/**
 * @title Base class to manage permissions for the derived class.
 */
abstract contract MultiRole {
    using Exclusive for Exclusive.RoleMembership;
    using Shared for Shared.RoleMembership;

    enum RoleType { Invalid, Exclusive, Shared }

    struct Role {
        uint256 managingRole;
        RoleType roleType;
        Exclusive.RoleMembership exclusiveRoleMembership;
        Shared.RoleMembership sharedRoleMembership;
    }

    mapping(uint256 => Role) private roles;

    event ResetExclusiveMember(uint256 indexed roleId, address indexed newMember, address indexed manager);
    event AddedSharedMember(uint256 indexed roleId, address indexed newMember, address indexed manager);
    event RemovedSharedMember(uint256 indexed roleId, address indexed oldMember, address indexed manager);

    /**
     * @notice Reverts unless the caller is a member of the specified roleId.
     */
    modifier onlyRoleHolder(uint256 roleId) {
        require(holdsRole(roleId, msg.sender), "Sender does not hold required role");
        _;
    }

    /**
     * @notice Reverts unless the caller is a member of the manager role for the specified roleId.
     */
    modifier onlyRoleManager(uint256 roleId) {
        require(holdsRole(roles[roleId].managingRole, msg.sender), "Can only be called by a role manager");
        _;
    }

    /**
     * @notice Reverts unless the roleId represents an initialized, exclusive roleId.
     */
    modifier onlyExclusive(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Exclusive, "Must be called on an initialized Exclusive role");
        _;
    }

    /**
     * @notice Reverts unless the roleId represents an initialized, shared roleId.
     */
    modifier onlyShared(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Shared, "Must be called on an initialized Shared role");
        _;
    }

    /**
     * @notice Whether `memberToCheck` is a member of roleId.
     * @dev Reverts if roleId does not correspond to an initialized role.
     * @param roleId the Role to check.
     * @param memberToCheck the address to check.
     * @return True if `memberToCheck` is a member of `roleId`.
     */
    function holdsRole(uint256 roleId, address memberToCheck) public view returns (bool) {
        Role storage role = roles[roleId];
        if (role.roleType == RoleType.Exclusive) {
            return role.exclusiveRoleMembership.isMember(memberToCheck);
        } else if (role.roleType == RoleType.Shared) {
            return role.sharedRoleMembership.isMember(memberToCheck);
        }
        revert("Invalid roleId");
    }

    /**
     * @notice Changes the exclusive role holder of `roleId` to `newMember`.
     * @dev Reverts if the caller is not a member of the managing role for `roleId` or if `roleId` is not an
     * initialized, ExclusiveRole.
     * @param roleId the ExclusiveRole membership to modify.
     * @param newMember the new ExclusiveRole member.
     */
    function resetMember(uint256 roleId, address newMember) public onlyExclusive(roleId) onlyRoleManager(roleId) {
        roles[roleId].exclusiveRoleMembership.resetMember(newMember);
        emit ResetExclusiveMember(roleId, newMember, msg.sender);
    }

    /**
     * @notice Gets the current holder of the exclusive role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, exclusive role.
     * @param roleId the ExclusiveRole membership to check.
     * @return the address of the current ExclusiveRole member.
     */
    function getMember(uint256 roleId) public view onlyExclusive(roleId) returns (address) {
        return roles[roleId].exclusiveRoleMembership.getMember();
    }

    /**
     * @notice Adds `newMember` to the shared role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, SharedRole or if the caller is not a member of the
     * managing role for `roleId`.
     * @param roleId the SharedRole membership to modify.
     * @param newMember the new SharedRole member.
     */
    function addMember(uint256 roleId, address newMember) public onlyShared(roleId) onlyRoleManager(roleId) {
        roles[roleId].sharedRoleMembership.addMember(newMember);
        emit AddedSharedMember(roleId, newMember, msg.sender);
    }

    /**
     * @notice Removes `memberToRemove` from the shared role, `roleId`.
     * @dev Reverts if `roleId` does not represent an initialized, SharedRole or if the caller is not a member of the
     * managing role for `roleId`.
     * @param roleId the SharedRole membership to modify.
     * @param memberToRemove the current SharedRole member to remove.
     */
    function removeMember(uint256 roleId, address memberToRemove) public onlyShared(roleId) onlyRoleManager(roleId) {
        roles[roleId].sharedRoleMembership.removeMember(memberToRemove);
        emit RemovedSharedMember(roleId, memberToRemove, msg.sender);
    }

    /**
     * @notice Removes caller from the role, `roleId`.
     * @dev Reverts if the caller is not a member of the role for `roleId` or if `roleId` is not an
     * initialized, SharedRole.
     * @param roleId the SharedRole membership to modify.
     */
    function renounceMembership(uint256 roleId) public onlyShared(roleId) onlyRoleHolder(roleId) {
        roles[roleId].sharedRoleMembership.removeMember(msg.sender);
        emit RemovedSharedMember(roleId, msg.sender, msg.sender);
    }

    /**
     * @notice Reverts if `roleId` is not initialized.
     */
    modifier onlyValidRole(uint256 roleId) {
        require(roles[roleId].roleType != RoleType.Invalid, "Attempted to use an invalid roleId");
        _;
    }

    /**
     * @notice Reverts if `roleId` is initialized.
     */
    modifier onlyInvalidRole(uint256 roleId) {
        require(roles[roleId].roleType == RoleType.Invalid, "Cannot use a pre-existing role");
        _;
    }

    /**
     * @notice Internal method to initialize a shared role, `roleId`, which will be managed by `managingRoleId`.
     * `initialMembers` will be immediately added to the role.
     * @dev Should be called by derived contracts, usually at construction time. Will revert if the role is already
     * initialized.
     */
    function _createSharedRole(
        uint256 roleId,
        uint256 managingRoleId,
        address[] memory initialMembers
    ) internal onlyInvalidRole(roleId) {
        Role storage role = roles[roleId];
        role.roleType = RoleType.Shared;
        role.managingRole = managingRoleId;
        role.sharedRoleMembership.init(initialMembers);
        require(
            roles[managingRoleId].roleType != RoleType.Invalid,
            "Attempted to use an invalid role to manage a shared role"
        );
    }

    /**
     * @notice Internal method to initialize an exclusive role, `roleId`, which will be managed by `managingRoleId`.
     * `initialMember` will be immediately added to the role.
     * @dev Should be called by derived contracts, usually at construction time. Will revert if the role is already
     * initialized.
     */
    function _createExclusiveRole(
        uint256 roleId,
        uint256 managingRoleId,
        address initialMember
    ) internal onlyInvalidRole(roleId) {
        Role storage role = roles[roleId];
        role.roleType = RoleType.Exclusive;
        role.managingRole = managingRoleId;
        role.exclusiveRoleMembership.init(initialMember);
        require(
            roles[managingRoleId].roleType != RoleType.Invalid,
            "Attempted to use an invalid role to manage an exclusive role"
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ERC20 interface that includes burn and mint methods.
 */
abstract contract ExpandedIERC20 is IERC20 {
    /**
     * @notice Burns a specific amount of the caller's tokens.
     * @dev Only burns the caller's tokens, so it is safe to leave this method permissionless.
     */
    function burn(uint256 value) external virtual;

    /**
     * @dev Burns `value` tokens owned by `recipient`.
     * @param recipient address to burn tokens from.
     * @param value amount of tokens to burn.
     */
    function burnFrom(address recipient, uint256 value) external virtual returns (bool);

    /**
     * @notice Mints tokens and adds them to the balance of the `to` address.
     * @dev This method should be permissioned to only allow designated parties to mint tokens.
     */
    function mint(address to, uint256 value) external virtual returns (bool);

    function addMinter(address account) external virtual;

    function addBurner(address account) external virtual;

    function resetOwner(address account) external virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Stores common interface names used throughout the DVM by registration in the Finder.
 */
library OracleInterfaces {
    bytes32 public constant Oracle = "Oracle";
    bytes32 public constant IdentifierWhitelist = "IdentifierWhitelist";
    bytes32 public constant Store = "Store";
    bytes32 public constant FinancialContractsAdmin = "FinancialContractsAdmin";
    bytes32 public constant Registry = "Registry";
    bytes32 public constant CollateralWhitelist = "CollateralWhitelist";
    bytes32 public constant OptimisticOracle = "OptimisticOracle";
    bytes32 public constant OptimisticOracleV2 = "OptimisticOracleV2";
    bytes32 public constant OptimisticOracleV3 = "OptimisticOracleV3";
    bytes32 public constant Bridge = "Bridge";
    bytes32 public constant GenericHandler = "GenericHandler";
    bytes32 public constant SkinnyOptimisticOracle = "SkinnyOptimisticOracle";
    bytes32 public constant ChildMessenger = "ChildMessenger";
    bytes32 public constant OracleHub = "OracleHub";
    bytes32 public constant OracleSpoke = "OracleSpoke";
}

/**
 * @title Commonly re-used values for contracts associated with the OptimisticOracle.
 */
library OptimisticOracleConstraints {
    // Any price request submitted to the OptimisticOracle must contain ancillary data no larger than this value.
    // This value must be <= the Voting contract's `ancillaryBytesLimit` constant value otherwise it is possible
    // that a price can be requested to the OptimisticOracle successfully, but cannot be resolved by the DVM which
    // refuses to accept a price request made with ancillary data length over a certain size.
    uint256 public constant ancillaryBytesLimit = 8192;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

/**
 * @title Computes vote results.
 * @dev The result is the mode of the added votes. Otherwise, the vote is unresolved.
 */
library ResultComputationV2 {
    /****************************************
     *   INTERNAL LIBRARY DATA STRUCTURE    *
     ****************************************/

    struct Data {
        mapping(int256 => uint128) voteFrequency; // Maps price to number of tokens that voted for that price.
        uint128 totalVotes; // The total votes that have been added.
        int256 currentMode; // The price that is the current mode, i.e., the price with the highest frequency.
    }

    /****************************************
     *            VOTING FUNCTIONS          *
     ****************************************/

    /**
     * @notice Adds a new vote to be used when computing the result.
     * @param data contains information to which the vote is applied.
     * @param votePrice value specified in the vote for the given `numberTokens`.
     * @param numberTokens number of tokens that voted on the `votePrice`.
     */
    function addVote(
        Data storage data,
        int256 votePrice,
        uint128 numberTokens
    ) internal {
        data.totalVotes += numberTokens;
        data.voteFrequency[votePrice] += numberTokens;
        if (votePrice != data.currentMode && data.voteFrequency[votePrice] > data.voteFrequency[data.currentMode])
            data.currentMode = votePrice;
    }

    /****************************************
     *        VOTING STATE GETTERS          *
     ****************************************/

    /**
     * @notice Returns whether the result is resolved, and if so, what value it resolved to.
     * @dev `price` should be ignored if `isResolved` is false.
     * @param data contains information against which the `minTotalVotes` and `minModalVotes` thresholds are applied.
     * @param minTotalVotes min (exclusive) number of tokens that must have voted (in any direction) for the result
     * to be valid. Used to enforce a minimum voter participation rate, regardless of how the votes are distributed.
     * @param minModalVotes min (exclusive) number of tokens that must have voted for the modal outcome for it to result
     * in a resolution. This is used to avoid cases where the mode is a very small plurality.
     * @return isResolved indicates if the price has been resolved correctly.
     * @return price the price that the dvm resolved to.
     */
    function getResolvedPrice(
        Data storage data,
        uint128 minTotalVotes,
        uint128 minModalVotes
    ) internal view returns (bool isResolved, int256 price) {
        if (data.totalVotes > minTotalVotes && data.voteFrequency[data.currentMode] > minModalVotes) {
            isResolved = true; // minTotalVotes and minModalVotes are exceeded, so the resolved price is the mode.
            price = data.currentMode;
        }
    }

    /**
     * @notice Checks whether a `voteHash` is considered correct.
     * @dev Should only be called after a vote is resolved, i.e., via `getResolvedPrice`.
     * @param data contains information against which the `voteHash` is checked.
     * @param voteHash committed hash submitted by the voter.
     * @return bool true if the vote was correct.
     */
    function wasVoteCorrect(Data storage data, bytes32 voteHash) internal view returns (bool) {
        return voteHash == keccak256(abi.encode(data.currentMode));
    }

    /**
     * @notice Gets the total number of tokens whose votes are considered correct.
     * @dev Should only be called after a vote is resolved, i.e., via `getResolvedPrice`.
     * @param data contains all votes against which the correctly voted tokens are counted.
     * @return uint128 which indicates the frequency of the correctly voted tokens.
     */
    function getTotalCorrectlyVotedTokens(Data storage data) internal view returns (uint128) {
        return data.voteFrequency[data.currentMode];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../common/implementation/Lockable.sol";
import "../../common/implementation/MultiCaller.sol";

import "../../common/interfaces/ExpandedIERC20.sol";
import "../interfaces/StakerInterface.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title Staking contract enabling UMA to be locked up by stakers to earn a pro rata share of a fixed emission rate.
 * @dev Handles the staking, unstaking and reward retrieval logic.
 */
abstract contract Staker is StakerInterface, Ownable, Lockable, MultiCaller {
    /****************************************
     *             STAKING STATE            *
     ****************************************/

    // Identifies a "stake" for a given voter. Each staker has an instance of this struct.
    struct VoterStake {
        uint128 stake; // UMA staked by the staker.
        uint128 pendingUnstake; // UMA in unstake cooldown period, waiting to be unstaked.
        mapping(uint32 => uint128) pendingStakes; // If a voter stakes during an active reveal, stake is pending.
        uint128 rewardsPaidPerToken; // Internal tracker used in the calculation of pro-rata share of rewards.
        uint128 outstandingRewards; // Accumulated rewards that have not yet been claimed.
        int128 unappliedSlash; // Used to track unapplied slashing in the case of bisected rounds.
        uint64 nextIndexToProcess; // The next request index that a staker is susceptible to be slashed on.
        uint64 unstakeTime; // Time that a staker can unstake. Used to determine if cooldown has passed.
        address delegate; // Address a staker has delegated to. The delegate can commit/reveal/claimRestake rewards.
    }

    mapping(address => VoterStake) public voterStakes; // Each voter is mapped to staker struct for their position.

    mapping(address => address) public delegateToStaker; // Mapping of delegates to their delegators (staker).

    uint128 public emissionRate; // Number of UMA emitted per second to incentivize stakers.

    uint128 public cumulativeStake; // Total number of UMA staked within the system.

    uint128 public rewardPerTokenStored; // Tracker used to allocate pro-rata share of rewards to stakers.

    uint64 public unstakeCoolDown; // Delay, in seconds, a staker must wait when trying to unstake their UMA.

    uint64 public lastUpdateTime; // Tracks the last time the reward rate was updated, used in reward allocation.

    ExpandedIERC20 public immutable votingToken; // An instance of the UMA voting token to mint rewards for stakers

    /****************************************
     *                EVENTS                *
     ****************************************/

    event Staked(
        address indexed voter,
        address indexed from,
        uint128 amount,
        uint128 voterStake,
        uint128 voterPendingUnstake,
        uint128 cumulativeStake
    );

    event RequestedUnstake(address indexed voter, uint128 amount, uint64 unstakeTime, uint128 voterStake);

    event ExecutedUnstake(address indexed voter, uint128 tokensSent, uint128 voterStake);

    event WithdrawnRewards(address indexed voter, address indexed delegate, uint128 tokensWithdrawn);

    event UpdatedReward(address indexed voter, uint128 newReward, uint64 lastUpdateTime);

    event SetNewEmissionRate(uint128 newEmissionRate);

    event SetNewUnstakeCoolDown(uint64 newUnstakeCoolDown);

    event DelegateSet(address indexed delegator, address indexed delegate);

    event DelegatorSet(address indexed delegate, address indexed delegator);

    /**
     * @notice Construct the Staker contract
     * @param _emissionRate amount of voting tokens that are emitted per second, split pro rata to stakers.
     * @param _unstakeCoolDown time that a voter must wait to unstake after requesting to unstake.
     * @param _votingToken address of the UMA token contract used to commit votes.
     */
    constructor(
        uint128 _emissionRate,
        uint64 _unstakeCoolDown,
        address _votingToken
    ) {
        setEmissionRate(_emissionRate);
        setUnstakeCoolDown(_unstakeCoolDown);
        votingToken = ExpandedIERC20(_votingToken);
    }

    /****************************************
     *           STAKER FUNCTIONS           *
     ****************************************/

    /**
     * @notice Pulls tokens from the sender's wallet and stakes them on his behalf.
     * @param amount the amount of tokens to stake.
     */
    function stake(uint128 amount) external {
        _stakeTo(msg.sender, msg.sender, amount);
    }

    /**
     * @notice Pulls tokens from the sender's wallet and stakes them for the recipient.
     * @param recipient the recipient address.
     * @param amount the amount of tokens to stake.
     */
    function stakeTo(address recipient, uint128 amount) external {
        _stakeTo(msg.sender, recipient, amount);
    }

    // Pull an amount of votingToken from the from address and stakes them for the recipient address.
    // If we are in an active reveal phase the stake amount will be added to the pending stake.
    // If not, the stake amount will be added to the stake.
    function _stakeTo(
        address from,
        address recipient,
        uint128 amount
    ) internal {
        require(amount > 0, "Cannot stake 0");

        VoterStake storage voterStake = voterStakes[recipient];

        // If the staker has a cumulative staked balance of 0 then we can shortcut their nextIndexToProcess to
        // the most recent index. This means we don't need to traverse requests where the staker was not staked.
        // _getStartingIndexForStaker returns the appropriate index to start at.
        if (voterStake.stake == 0) voterStake.nextIndexToProcess = _getStartingIndexForStaker();
        _updateTrackers(recipient);

        // Compute pending stakes when needed.
        _computePendingStakes(recipient, amount);

        voterStake.stake += amount;
        cumulativeStake += amount;

        // Tokens are pulled from the from address and sent to this contract.
        // During withdrawAndRestake, from is the same as the address of this contract, so there is no need to transfer.
        if (from != address(this)) votingToken.transferFrom(from, address(this), amount);
        emit Staked(recipient, from, amount, voterStake.stake, voterStake.pendingUnstake, cumulativeStake);
    }

    /**
     * @notice Request a certain number of tokens to be unstaked. After the unstake time expires, the user may execute
     * the unstake. Tokens requested to unstake are not slashable nor subject to earning rewards.
     * This function cannot be called during an active reveal phase.
     * Note there is no way to cancel an unstake request, you must wait until after unstakeTime and re-stake.
     * @param amount the amount of tokens to request to be unstaked.
     */
    function requestUnstake(uint128 amount) external nonReentrant() {
        require(!_inActiveReveal(), "In an active reveal phase");
        require(amount > 0, "Cannot unstake 0");
        _updateTrackers(msg.sender);
        VoterStake storage voterStake = voterStakes[msg.sender];

        require(voterStake.stake >= amount && voterStake.pendingUnstake == 0, "Bad amount or pending unstake");

        cumulativeStake -= amount;
        voterStake.pendingUnstake = amount;
        voterStake.stake -= amount;
        voterStake.unstakeTime = uint64(getCurrentTime()) + unstakeCoolDown;

        emit RequestedUnstake(msg.sender, amount, voterStake.unstakeTime, voterStake.stake);
    }

    /**
     * @notice  Execute a previously requested unstake. Requires the unstake time to have passed.
     * @dev If a staker requested an unstake and time > unstakeTime then send funds to staker. If unstakeCoolDown is
     * set to 0 then the unstake can be executed immediately.
     */
    function executeUnstake() external nonReentrant() {
        VoterStake storage voterStake = voterStakes[msg.sender];
        require(
            voterStake.unstakeTime != 0 && (getCurrentTime() >= voterStake.unstakeTime || unstakeCoolDown == 0),
            "Unstake time not passed"
        );
        uint128 tokensToSend = voterStake.pendingUnstake;

        if (tokensToSend > 0) {
            voterStake.pendingUnstake = 0;
            voterStake.unstakeTime = 0;
            votingToken.transfer(msg.sender, tokensToSend);
        }

        emit ExecutedUnstake(msg.sender, tokensToSend, voterStake.stake);
    }

    /**
     * @notice Send accumulated rewards to the voter. Note that these rewards do not include slashing balance changes.
     * @return uint128 the amount of tokens sent to the voter.
     */
    function withdrawRewards() external returns (uint128) {
        return _withdrawRewards(msg.sender, msg.sender);
    }

    // Withdraws rewards for a given voter and sends them to the recipient.
    function _withdrawRewards(address voter, address recipient) internal returns (uint128) {
        _updateTrackers(voter);
        VoterStake storage voterStake = voterStakes[voter];

        uint128 tokensToMint = voterStake.outstandingRewards;
        if (tokensToMint > 0) {
            voterStake.outstandingRewards = 0;
            require(votingToken.mint(recipient, tokensToMint), "Voting token issuance failed");
            emit WithdrawnRewards(voter, msg.sender, tokensToMint);
        }
        return tokensToMint;
    }

    /**
     * @notice Stake accumulated rewards. This is merely a convenience mechanism that combines the voter's withdrawal
     * and stake in the same transaction if requested by a delegate or the voter.
     * @dev The rewarded tokens simply pass through this contract before being staked on the voter's behalf.
     *  The balance of the delegate remains unchanged.
     * @return uint128 the amount of tokens that the voter is staking.
     */
    function withdrawAndRestake() external returns (uint128) {
        address voter = getVoterFromDelegate(msg.sender);
        uint128 rewards = _withdrawRewards(voter, address(this));
        _stakeTo(address(this), voter, rewards);
        return rewards;
    }

    /**
     * @notice Sets the delegate of a voter. This delegate can vote on behalf of the staker. The staker will still own
     * all staked balances, receive rewards and be slashed based on the actions of the delegate. Intended use is using a
     * low-security available wallet for voting while keeping access to staked amounts secure by a more secure wallet.
     * @param delegate the address of the delegate.
     */
    function setDelegate(address delegate) external {
        voterStakes[msg.sender].delegate = delegate;
        emit DelegateSet(msg.sender, delegate);
    }

    /**
     * @notice Sets the delegator of a voter. Acts to accept a delegation. The delegate can only vote for the delegator
     * if the delegator also selected the delegate to do so (two-way relationship needed).
     * @param delegator the address of the delegator.
     */
    function setDelegator(address delegator) external {
        delegateToStaker[msg.sender] = delegator;
        emit DelegatorSet(msg.sender, delegator);
    }

    /****************************************
     *        OWNER ADMIN FUNCTIONS         *
     ****************************************/

    /**
     * @notice  Set the token's emission rate, the number of voting tokens that are emitted per second.
     * @param newEmissionRate the new amount of voting tokens that are emitted per second, split pro rata to stakers.
     */
    function setEmissionRate(uint128 newEmissionRate) public onlyOwner {
        _updateReward(address(0));
        emissionRate = newEmissionRate;
        emit SetNewEmissionRate(newEmissionRate);
    }

    /**
     * @notice  Set the amount of time a voter must wait to unstake after submitting a request to do so.
     * @param newUnstakeCoolDown the new duration of the cool down period in seconds.
     */
    function setUnstakeCoolDown(uint64 newUnstakeCoolDown) public onlyOwner {
        unstakeCoolDown = newUnstakeCoolDown;
        emit SetNewUnstakeCoolDown(newUnstakeCoolDown);
    }

    // Updates an account internal trackers.
    function _updateTrackers(address voter) internal virtual {
        _updateReward(voter);
    }

    /****************************************
     *            VIEW FUNCTIONS            *
     ****************************************/

    /**
     * @notice Gets the pending stake for a voter for a given round.
     * @param voter the voter address.
     * @param roundId round id.
     * @return uint128 amount of the pending stake.
     */
    function getVoterPendingStake(address voter, uint32 roundId) external view returns (uint128) {
        return voterStakes[voter].pendingStakes[roundId];
    }

    /**
     * @notice Gets the voter from the delegate.
     * @param caller caller of the function or the address to check in the mapping between a voter and their delegate.
     * @return address voter that corresponds to the delegate.
     */
    function getVoterFromDelegate(address caller) public view returns (address) {
        address delegator = delegateToStaker[caller];
        // The delegate chose to be a delegate for the staker.
        if (delegator != address(0) && voterStakes[delegator].delegate == caller) return delegator;
        else return caller; // The staker chose the delegate.
    }

    /**
     * @notice  Determine the number of outstanding token rewards that can be withdrawn by a voter.
     * @param voter the address of the voter.
     * @return uint256 the outstanding rewards.
     */
    function outstandingRewards(address voter) public view returns (uint256) {
        VoterStake storage voterStake = voterStakes[voter];

        return
            ((voterStake.stake * (rewardPerToken() - voterStake.rewardsPaidPerToken)) / 1e18) +
            voterStake.outstandingRewards;
    }

    /**
     * @notice  Calculate the reward per token based on the last time the reward was updated.
     * @return uint256 the reward per token.
     */
    function rewardPerToken() public view returns (uint256) {
        if (cumulativeStake == 0) return rewardPerTokenStored;
        return rewardPerTokenStored + ((getCurrentTime() - lastUpdateTime) * emissionRate * 1e18) / cumulativeStake;
    }

    /**
     * @notice Returns the total amount of tokens staked by the voter, after applying updateTrackers. Specifically used
     * by offchain apps to simulate the cumulative stake + unapplied slashing updates without sending a transaction.
     * @param voter the address of the voter.
     * @return uint128 the total stake.
     */
    function getVoterStakePostUpdate(address voter) external returns (uint128) {
        _updateTrackers(voter);
        return voterStakes[voter].stake;
    }

    /**
     * @notice Returns the current block timestamp.
     * @dev Can be overridden to control contract time.
     * @return the current block timestamp.
     */
    function getCurrentTime() public view virtual returns (uint256) {
        return block.timestamp;
    }

    /****************************************
     *          INTERNAL FUNCTIONS          *
     ****************************************/

    // This function must be called before any tokens are staked. Update the voter's pending stakes when necessary.
    // The contract that inherits from Staker (e.g. VotingV2) must implement this logic by overriding this function.
    function _computePendingStakes(address voter, uint128 amount) internal virtual;

    // Add a new stake amount to the voter's pending stake for a specific round id.
    function _incrementPendingStake(
        address voter,
        uint32 roundId,
        uint128 amount
    ) internal {
        voterStakes[voter].pendingStakes[roundId] += amount;
    }

    // Determine if we are in an active reveal phase. This function should be overridden by the child contract.
    function _inActiveReveal() internal view virtual returns (bool) {
        return false;
    }

    // Returns the starting index for a staker. This function should be overridden by the implementing contract.
    function _getStartingIndexForStaker() internal virtual returns (uint64) {
        return 0;
    }

    // Calculate the reward per token based on last time the reward was updated.
    function _updateReward(address voter) internal {
        uint128 newRewardPerToken = uint128(rewardPerToken());
        rewardPerTokenStored = newRewardPerToken;
        lastUpdateTime = uint64(getCurrentTime());
        if (voter != address(0)) {
            VoterStake storage voterStake = voterStakes[voter];
            voterStake.outstandingRewards = uint128(outstandingRewards(voter));
            voterStake.rewardsPaidPerToken = newRewardPerToken;
        }
        emit UpdatedReward(voter, newRewardPerToken, lastUpdateTime);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../interfaces/VotingInterface.sol";

/**
 * @title Library to compute rounds and phases for an equal length commit-reveal voting cycle.
 */
library VoteTiming {
    struct Data {
        uint256 phaseLength;
    }

    /**
     * @notice Initializes the data object. Sets the phase length based on the input.
     * @param data reference to the this library's data object.
     * @param phaseLength length of voting phase in seconds.
     */
    function init(Data storage data, uint256 phaseLength) internal {
        // This should have a require message but this results in an internal Solidity error.
        require(phaseLength > 0);
        data.phaseLength = phaseLength;
    }

    /**
     * @notice Computes the roundID based off the current time as floor(timestamp/roundLength).
     * @dev The round ID depends on the global timestamp but not on the lifetime of the system.
     * The consequence is that the initial round ID starts at an arbitrary number (that increments, as expected, for subsequent rounds) instead of zero or one.
     * @param data input data object.
     * @param currentTime input unix timestamp used to compute the current roundId.
     * @return roundId defined as a function of the currentTime and `phaseLength` from `data`.
     */
    function computeCurrentRoundId(Data storage data, uint256 currentTime) internal view returns (uint256) {
        uint256 roundLength = data.phaseLength * uint256(VotingAncillaryInterface.Phase.NUM_PHASES);
        return currentTime / roundLength;
    }

    /**
     * @notice compute the round end time as a function of the round Id.
     * @param data input data object.
     * @param roundId uniquely identifies the current round.
     * @return timestamp unix time of when the current round will end.
     */
    function computeRoundEndTime(Data storage data, uint256 roundId) internal view returns (uint256) {
        uint256 roundLength = data.phaseLength * uint256(VotingAncillaryInterface.Phase.NUM_PHASES);
        return roundLength * (roundId + 1);
    }

    /**
     * @notice Computes the current phase based only on the current time.
     * @param data input data object.
     * @param currentTime input unix timestamp used to compute the current roundId.
     * @return current voting phase based on current time and vote phases configuration.
     */
    function computeCurrentPhase(Data storage data, uint256 currentTime)
        internal
        view
        returns (VotingAncillaryInterface.Phase)
    {
        // This employs some hacky casting. We could make this an if-statement if we're worried about type safety.
        return
            VotingAncillaryInterface.Phase(
                (currentTime / data.phaseLength) % uint256(VotingAncillaryInterface.Phase.NUM_PHASES)
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../common/implementation/ExpandedERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

/**
 * @title Ownership of this token allows a voter to respond to price requests.
 * @dev Supports snapshotting and allows the Oracle to mint new tokens as rewards.
 */
contract VotingToken is ExpandedERC20, ERC20Snapshot {
    /**
     * @notice Constructs the VotingToken.
     */
    constructor() ExpandedERC20("UMA Voting Token v1", "UMA", 18) ERC20Snapshot() {}

    function decimals() public view virtual override(ERC20, ExpandedERC20) returns (uint8) {
        return super.decimals();
    }

    /**
     * @notice Creates a new snapshot ID.
     * @return uint256 Thew new snapshot ID.
     */
    function snapshot() external returns (uint256) {
        return _snapshot();
    }

    // _transfer, _mint and _burn are ERC20 internal methods that are overridden by ERC20Snapshot,
    // therefore the compiler will complain that VotingToken must override these methods
    // because the two base classes (ERC20 and ERC20Snapshot) both define the same functions

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20) {
        super._transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal virtual override(ERC20) {
        super._mint(account, value);
    }

    function _burn(address account, uint256 value) internal virtual override(ERC20) {
        super._burn(account, value);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/math/Math.sol";

import "./ResultComputationV2.sol";
import "./Staker.sol";
import "./VoteTiming.sol";
import "./Constants.sol";

import "../interfaces/MinimumVotingAncillaryInterface.sol";
import "../interfaces/FinderInterface.sol";
import "../interfaces/IdentifierWhitelistInterface.sol";
import "../interfaces/OracleAncillaryInterface.sol";
import "../interfaces/OracleGovernanceInterface.sol";
import "../interfaces/OracleInterface.sol";
import "../interfaces/VotingV2Interface.sol";
import "../interfaces/RegistryInterface.sol";
import "../interfaces/SlashingLibraryInterface.sol";

/**
 * @title VotingV2 contract for the UMA DVM.
 * @dev Handles receiving and resolving price requests via a commit-reveal voting schelling scheme.
 */

contract VotingV2 is Staker, OracleInterface, OracleAncillaryInterface, OracleGovernanceInterface, VotingV2Interface {
    using VoteTiming for VoteTiming.Data;
    using ResultComputationV2 for ResultComputationV2.Data;

    /****************************************
     *        VOTING DATA STRUCTURES        *
     ****************************************/

    // Identifies a unique price request. Tracks ongoing votes as well as the result of the vote.
    struct PriceRequest {
        uint32 lastVotingRound; // Last round that this price request was voted on. Updated when a request is rolled.
        bool isGovernance; // Denotes whether this is a governance request or not.
        uint64 time; // Timestamp used when evaluating the request.
        uint32 rollCount; // The number of rounds that a price request has rolled. Informs if a request can be deleted.
        bytes32 identifier; // Identifier that defines how the voters should resolve the request.
        mapping(uint32 => VoteInstance) voteInstances; // A map containing all votes for this price in various rounds.
        bytes ancillaryData; // Additional data used to resolve the request.
    }

    struct VoteInstance {
        mapping(address => VoteSubmission) voteSubmissions; // Maps (voter) to their submission.
        ResultComputationV2.Data results; // The data structure containing the computed voting results.
    }

    struct VoteSubmission {
        bytes32 commit; // A bytes32 of 0 indicates no commit or a commit that was already revealed.
        bytes32 revealHash; // The hash of the value that was revealed. This is only used for computation of rewards.
    }

    struct Round {
        SlashingLibraryInterface slashingLibrary; // Slashing library used to compute voter participation slash at this round.
        uint128 minParticipationRequirement; // Minimum staked tokens that must vote to resolve a request.
        uint128 minAgreementRequirement; // Minimum staked tokens that must agree on an outcome to resolve a request.
        uint128 cumulativeStakeAtRound; // Total staked tokens at the start of the round.
        uint32 numberOfRequestsToVote; // The number of requests to vote in this round.
    }

    struct SlashingTracker {
        uint256 wrongVoteSlashPerToken; // The amount of tokens slashed per token staked for a wrong vote.
        uint256 noVoteSlashPerToken; // The amount of tokens slashed per token staked for a no vote.
        uint256 totalSlashed; // The total amount of tokens slashed for a given request.
        uint256 totalCorrectVotes; // The total number of correct votes for a given request.
        uint32 lastVotingRound; // The last round that this request was voted on (when it resolved).
    }

    enum VoteParticipation {
        DidNotVote, // Voter did not vote.
        WrongVote, // Voter voted against the resolved price.
        CorrectVote // Voter voted with the resolved price.
    }

    // Represents the status a price request has.
    enum RequestStatus {
        NotRequested, // Was never requested.
        Active, // Is being voted on in the current round.
        Resolved, // Was resolved in a previous round.
        Future, // Is scheduled to be voted on in a future round.
        ToDelete // Is scheduled to be deleted.
    }

    // Only used as a return value in view methods -- never stored in the contract.
    struct RequestState {
        RequestStatus status;
        uint32 lastVotingRound;
    }

    /****************************************
     *            VOTING STATE              *
     ****************************************/

    uint32 public lastRoundIdProcessed; // The last round pendingPriceRequestsIds were traversed in.

    uint64 public nextPendingIndexToProcess; // Next pendingPriceRequestsIds index to process in lastRoundIdProcessed.

    FinderInterface public immutable finder; // Reference to the UMA Finder contract, used to find other UMA contracts.

    SlashingLibraryInterface public slashingLibrary; // Reference to Slashing Library, used to compute slashing amounts.

    VoteTiming.Data public voteTiming; // Vote timing library used to compute round timing related logic.

    OracleAncillaryInterface public immutable previousVotingContract; // Previous voting contract, if migrated.

    mapping(uint256 => Round) public rounds; // Maps round numbers to the rounds.

    mapping(bytes32 => PriceRequest) public priceRequests; // Maps price request IDs to the PriceRequest struct.

    bytes32[] public resolvedPriceRequestIds; // Array of resolved price requestIds. Used to track resolved requests.

    bytes32[] public pendingPriceRequestsIds; // Array of pending price requestIds. Can be resolved in the future.

    uint32 public maxRolls; // The maximum number of times a request can roll before it is deleted automatically.

    uint32 public maxRequestsPerRound; // The maximum number of requests that can be enqueued in a single round.

    address public migratedAddress; // If non-zero, this contract has been migrated to this address.

    uint128 public gat; // GAT: A minimum number of tokens that must participate to resolve a vote.

    uint64 public spat; // SPAT: Minimum percentage of staked tokens that must agree on the answer to resolve a vote.

    uint64 public constant UINT64_MAX = type(uint64).max; // Max value of an unsigned integer.

    uint256 public constant ANCILLARY_BYTES_LIMIT = 8192; // Max length in bytes of ancillary data.

    /****************************************
     *                EVENTS                *
     ****************************************/

    event VoteCommitted(
        address indexed voter,
        address indexed caller,
        uint32 roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData
    );

    event EncryptedVote(
        address indexed caller,
        uint32 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData,
        bytes encryptedVote
    );

    event VoteRevealed(
        address indexed voter,
        address indexed caller,
        uint32 roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData,
        int256 price,
        uint128 numTokens
    );

    event RequestAdded(
        address indexed requester,
        uint32 indexed roundId,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData,
        bool isGovernance
    );

    event RequestResolved(
        uint32 indexed roundId,
        uint256 indexed resolvedPriceRequestIndex,
        bytes32 indexed identifier,
        uint256 time,
        bytes ancillaryData,
        int256 price
    );

    event VotingContractMigrated(address newAddress);

    event RequestDeleted(bytes32 indexed identifier, uint256 indexed time, bytes ancillaryData, uint32 rollCount);

    event RequestRolled(bytes32 indexed identifier, uint256 indexed time, bytes ancillaryData, uint32 rollCount);

    event GatAndSpatChanged(uint128 newGat, uint64 newSpat);

    event SlashingLibraryChanged(address newAddress);

    event MaxRollsChanged(uint32 newMaxRolls);

    event MaxRequestsPerRoundChanged(uint32 newMaxRequestsPerRound);

    event VoterSlashApplied(address indexed voter, int128 slashedTokens, uint128 postStake);

    event VoterSlashed(address indexed voter, uint256 indexed requestIndex, int128 slashedTokens);

    /**
     * @notice Construct the VotingV2 contract.
     * @param _emissionRate amount of voting tokens that are emitted per second, split prorate between stakers.
     * @param _unstakeCoolDown time that a voter must wait to unstake after requesting to unstake.
     * @param _phaseLength length of the voting phases in seconds.
     * @param _maxRolls number of times a vote must roll to be auto deleted by the DVM.
     * @param _maxRequestsPerRound maximum number of requests that can be enqueued in a single round.
     * @param _gat number of tokens that must participate to resolve a vote.
     * @param _spat percentage of staked tokens that must agree on the result to resolve a vote.
     * @param _votingToken address of the UMA token contract used to commit votes.
     * @param _finder keeps track of all contracts within the system based on their interfaceName.
     * @param _slashingLibrary contract used to calculate voting slashing penalties based on voter participation.
     * @param _previousVotingContract previous voting contract address.
     */
    constructor(
        uint128 _emissionRate,
        uint64 _unstakeCoolDown,
        uint64 _phaseLength,
        uint32 _maxRolls,
        uint32 _maxRequestsPerRound,
        uint128 _gat,
        uint64 _spat,
        address _votingToken,
        address _finder,
        address _slashingLibrary,
        address _previousVotingContract
    ) Staker(_emissionRate, _unstakeCoolDown, _votingToken) {
        voteTiming.init(_phaseLength);
        finder = FinderInterface(_finder);
        previousVotingContract = OracleAncillaryInterface(_previousVotingContract);
        setGatAndSpat(_gat, _spat);
        setSlashingLibrary(_slashingLibrary);
        setMaxRequestPerRound(_maxRequestsPerRound);
        setMaxRolls(_maxRolls);
    }

    /***************************************
                    MODIFIERS
    ****************************************/

    modifier onlyRegisteredContract() {
        _requireRegisteredContract();
        _;
    }

    modifier onlyIfNotMigrated() {
        _requireNotMigrated();
        _;
    }

    /****************************************
     *  PRICE REQUEST AND ACCESS FUNCTIONS  *
     ****************************************/

    /**
     * @notice Enqueues a request (if a request isn't already present) for the identifier, time and ancillary data.
     * @dev Time must be in the past and the identifier must be supported. The length of the ancillary data is limited.
     * @param identifier uniquely identifies the price requested. E.g. BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     */
    function requestPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public override nonReentrant onlyIfNotMigrated onlyRegisteredContract {
        _requestPrice(identifier, time, ancillaryData, false);
    }

    /**
     * @notice Enqueues a governance action request (if not already present) for identifier, time and ancillary data.
     * @dev Only the owner of the Voting contract can call this. In normal operation this is the Governor contract.
     * @param identifier uniquely identifies the price requested. E.g. Admin 0 (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     */
    function requestGovernanceAction(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) external override onlyOwner onlyIfNotMigrated {
        _requestPrice(identifier, time, ancillaryData, true);
    }

    /**
     * @notice Enqueues a request (if a request isn't already present) for the identifier, time pair.
     * @dev Overloaded method to enable short term backwards compatibility when ancillary data is not included.
     * @param identifier uniquely identifies the price requested. E.g. BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     */
    function requestPrice(bytes32 identifier, uint256 time) external override {
        requestPrice(identifier, time, "");
    }

    // Enqueues a request (if a request isn't already present) for the given identifier, time and ancillary data.
    function _requestPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        bool isGovernance
    ) internal {
        require(time <= getCurrentTime(), "Can only request in past");
        require(isGovernance || _getIdentifierWhitelist().isIdentifierSupported(identifier), "Unsupported identifier");
        require(ancillaryData.length <= ANCILLARY_BYTES_LIMIT, "Invalid ancillary data");

        bytes32 priceRequestId = _encodePriceRequest(identifier, time, ancillaryData);
        PriceRequest storage priceRequest = priceRequests[priceRequestId];

        // Price has never been requested.
        uint32 currentRoundId = getCurrentRoundId();
        if (_getRequestStatus(priceRequest, currentRoundId) == RequestStatus.NotRequested) {
            uint32 roundIdToVoteOn = getRoundIdToVoteOnRequest(currentRoundId + 1);
            ++rounds[roundIdToVoteOn].numberOfRequestsToVote;
            priceRequest.identifier = identifier;
            priceRequest.time = uint64(time);
            priceRequest.ancillaryData = ancillaryData;
            priceRequest.lastVotingRound = roundIdToVoteOn;
            if (isGovernance) priceRequest.isGovernance = isGovernance;

            pendingPriceRequestsIds.push(priceRequestId);
            emit RequestAdded(msg.sender, roundIdToVoteOn, identifier, time, ancillaryData, isGovernance);
        }
    }

    /**
     * @notice Gets the round ID that a request should be voted on.
     * @param targetRoundId round ID to start searching for a round to vote on.
     * @return uint32 round ID that a request should be voted on.
     */
    function getRoundIdToVoteOnRequest(uint32 targetRoundId) public view returns (uint32) {
        while (rounds[targetRoundId].numberOfRequestsToVote >= maxRequestsPerRound) ++targetRoundId;
        return targetRoundId;
    }

    /**
     * @notice Returns whether the price for identifier, time and ancillary data is available.
     * @param identifier uniquely identifies the price requested. E.g. BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp of the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @return bool if the DVM has resolved to a price for the given identifier, timestamp and ancillary data.
     */
    function hasPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view override onlyRegisteredContract returns (bool) {
        (bool _hasPrice, , ) = _getPriceOrError(identifier, time, ancillaryData);
        return _hasPrice;
    }

    /**
     * @notice Whether the price for identifier and time is available.
     * @dev Overloaded method to enable short term backwards compatibility when ancillary data is not included.
     * @param identifier uniquely identifies the price requested. E.g. BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp of the price request.
     * @return bool if the DVM has resolved to a price for the given identifier and timestamp.
     */
    function hasPrice(bytes32 identifier, uint256 time) external view override returns (bool) {
        return hasPrice(identifier, time, "");
    }

    /**
     * @notice Gets the price for identifier, time and ancillary data if it has already been requested and resolved.
     * @dev If the price is not available, the method reverts.
     * @param identifier uniquely identifies the price requested. E.g. BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp of the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @return int256 representing the resolved price for the given identifier, timestamp and ancillary data.
     */
    function getPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view override onlyRegisteredContract returns (int256) {
        (bool _hasPrice, int256 price, string memory message) = _getPriceOrError(identifier, time, ancillaryData);

        // If the price wasn't available, revert with the provided message.
        require(_hasPrice, message);
        return price;
    }

    /**
     * @notice Gets the price for identifier and time if it has already been requested and resolved.
     * @dev Overloaded method to enable short term backwards compatibility when ancillary data is not included.
     * @dev If the price is not available, the method reverts.
     * @param identifier uniquely identifies the price requested. E.g. BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp of the price request.
     * @return int256 representing the resolved price for the given identifier and timestamp.
     */
    function getPrice(bytes32 identifier, uint256 time) external view override returns (int256) {
        return getPrice(identifier, time, "");
    }

    /**
     * @notice Gets the status of a list of price requests, identified by their identifier, time and ancillary data.
     * @dev If the status for a particular request is NotRequested, the lastVotingRound will always be 0.
     * @param requests array of pending requests which includes identifier, timestamp & ancillary data for the requests.
     * @return requestStates a list, in the same order as the input list, giving the status of the specified requests.
     */
    function getPriceRequestStatuses(PendingRequestAncillary[] memory requests)
        public
        view
        returns (RequestState[] memory)
    {
        RequestState[] memory requestStates = new RequestState[](requests.length);
        uint32 currentRoundId = getCurrentRoundId();
        for (uint256 i = 0; i < requests.length; i = unsafe_inc(i)) {
            PriceRequest storage priceRequest =
                _getPriceRequest(requests[i].identifier, requests[i].time, requests[i].ancillaryData);

            RequestStatus status = _getRequestStatus(priceRequest, currentRoundId);

            // If it's an active request, its true lastVotingRound is the current one, even if it hasn't been updated.
            if (status == RequestStatus.Active) requestStates[i].lastVotingRound = currentRoundId;
            else requestStates[i].lastVotingRound = priceRequest.lastVotingRound;
            requestStates[i].status = status;
        }
        return requestStates;
    }

    /****************************************
     *          VOTING FUNCTIONS            *
     ****************************************/

    /**
     * @notice Commit a vote for a price request for identifier at time.
     * @dev identifier, time must correspond to a price request that's currently in the commit phase.
     * Commits can be changed.
     * @dev Since transaction data is public, the salt will be revealed with the vote. While this is the system’s
     * expected behavior, voters should never reuse salts. If someone else is able to guess the voted price and knows
     * that a salt will be reused, then they can determine the vote pre-reveal.
     * @param identifier uniquely identifies the committed vote. E.g. BTC/USD price pair.
     * @param time unix timestamp of the price being voted on.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param hash keccak256 hash of the price, salt, voter address, time, ancillaryData, current roundId, identifier.
     */
    function commitVote(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        bytes32 hash
    ) public override nonReentrant {
        uint32 currentRoundId = getCurrentRoundId();
        address voter = getVoterFromDelegate(msg.sender);
        _updateTrackers(voter);

        require(hash != bytes32(0), "Invalid commit hash");
        require(getVotePhase() == Phase.Commit, "Cannot commit in reveal phase");
        PriceRequest storage priceRequest = _getPriceRequest(identifier, time, ancillaryData);
        require(_getRequestStatus(priceRequest, currentRoundId) == RequestStatus.Active, "Request must be active");

        priceRequest.voteInstances[currentRoundId].voteSubmissions[voter].commit = hash;

        emit VoteCommitted(voter, msg.sender, currentRoundId, identifier, time, ancillaryData);
    }

    /**
     * @notice Reveal a previously committed vote for identifier at time.
     * @dev The revealed price, salt, voter address, time, ancillaryData, current roundId, identifier must hash to the
     * latest hash that commitVote() was called with. Only the committer can reveal their vote.
     * @param identifier voted on in the commit phase. E.g. BTC/USD price pair.
     * @param time specifies the unix timestamp of the price being voted on.
     * @param price voted on during the commit phase.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param salt value used to hide the commitment price during the commit phase.
     */
    function revealVote(
        bytes32 identifier,
        uint256 time,
        int256 price,
        bytes memory ancillaryData,
        int256 salt
    ) public override nonReentrant {
        uint32 currentRoundId = getCurrentRoundId();
        _freezeRoundVariables(currentRoundId);
        VoteInstance storage voteInstance =
            _getPriceRequest(identifier, time, ancillaryData).voteInstances[currentRoundId];
        address voter = getVoterFromDelegate(msg.sender);
        VoteSubmission storage voteSubmission = voteInstance.voteSubmissions[voter];

        require(getVotePhase() == Phase.Reveal, "Reveal phase has not started yet"); // Can only reveal in reveal phase.

        // Zero hashes are blocked in commit; they indicate a different error: voter did not commit or already revealed.
        require(voteSubmission.commit != bytes32(0), "Invalid hash reveal");

        // Check that the hash that was committed matches to the one that was revealed. Note that if the voter had
        // then they must reveal with the same account they had committed with.
        require(
            keccak256(abi.encodePacked(price, salt, voter, time, ancillaryData, uint256(currentRoundId), identifier)) ==
                voteSubmission.commit,
            "Revealed data != commit hash"
        );

        delete voteSubmission.commit; // Small gas refund for clearing up storage.
        voteSubmission.revealHash = keccak256(abi.encode(price)); // Set the voter's submission.

        // Calculate the voters effective stake for this round as the difference between their stake and pending stake.
        // This allows for the voter to have staked during this reveal phase and not consider their pending stake.
        uint128 effectiveStake = voterStakes[voter].stake - voterStakes[voter].pendingStakes[currentRoundId];
        voteInstance.results.addVote(price, effectiveStake); // Add vote to the results.
        emit VoteRevealed(voter, msg.sender, currentRoundId, identifier, time, ancillaryData, price, effectiveStake);
    }

    /**
     * @notice Commits a vote and logs an event with a data blob, typically an encrypted version of the vote
     * @dev An encrypted version of the vote is emitted in an event EncryptedVote to allow off-chain infrastructure to
     * retrieve the commit. The contents of encryptedVote are never used on chain: it is purely for convenience.
     * @param identifier unique price pair identifier. E.g. BTC/USD price pair.
     * @param time unix timestamp of the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param hash keccak256 hash of the price you want to vote for and a int256 salt.
     * @param encryptedVote offchain encrypted blob containing the voter's amount, time and salt.
     */
    function commitAndEmitEncryptedVote(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        bytes32 hash,
        bytes memory encryptedVote
    ) public override {
        commitVote(identifier, time, ancillaryData, hash);
        emit EncryptedVote(msg.sender, getCurrentRoundId(), identifier, time, ancillaryData, encryptedVote);
    }

    /****************************************
     *        VOTING GETTER FUNCTIONS       *
     ****************************************/

    /**
     * @notice Gets the requests that are being voted on this round.
     * @dev This view method returns requests with Active status that may be ahead of the stored contract state as this
     * also filters out requests that would be resolvable or deleted if the resolvable requests were processed with the
     * processResolvablePriceRequests() method.
     * @return pendingRequests array containing identifiers of type PendingRequestAncillaryAugmented.
     */
    function getPendingRequests() public view override returns (PendingRequestAncillaryAugmented[] memory) {
        // Solidity memory arrays aren't resizable (and reading storage is expensive). Hence this hackery to filter
        // pendingPriceRequestsIds only to those requests that have an Active RequestStatus.
        PendingRequestAncillaryAugmented[] memory unresolved =
            new PendingRequestAncillaryAugmented[](pendingPriceRequestsIds.length);
        uint256 numUnresolved = 0;
        uint32 currentRoundId = getCurrentRoundId();

        for (uint256 i = 0; i < pendingPriceRequestsIds.length; i = unsafe_inc(i)) {
            PriceRequest storage priceRequest = priceRequests[pendingPriceRequestsIds[i]];
            if (_getRequestStatus(priceRequest, currentRoundId) == RequestStatus.Active) {
                unresolved[numUnresolved] = PendingRequestAncillaryAugmented({
                    lastVotingRound: priceRequest.lastVotingRound,
                    isGovernance: priceRequest.isGovernance,
                    time: priceRequest.time,
                    rollCount: _getActualRollCount(priceRequest, currentRoundId),
                    identifier: priceRequest.identifier,
                    ancillaryData: priceRequest.ancillaryData
                });
                numUnresolved++;
            }
        }

        PendingRequestAncillaryAugmented[] memory pendingRequests =
            new PendingRequestAncillaryAugmented[](numUnresolved);
        for (uint256 i = 0; i < numUnresolved; i = unsafe_inc(i)) pendingRequests[i] = unresolved[i];

        return pendingRequests;
    }

    /**
     * @notice Checks if there are current active requests.
     * @return bool true if there are active requests, false otherwise.
     */
    function currentActiveRequests() public view returns (bool) {
        uint32 currentRoundId = getCurrentRoundId();
        for (uint256 i = 0; i < pendingPriceRequestsIds.length; i = unsafe_inc(i))
            if (_getRequestStatus(priceRequests[pendingPriceRequestsIds[i]], currentRoundId) == RequestStatus.Active)
                return true;

        return false;
    }

    /**
     * @notice Returns the current voting phase, as a function of the current time.
     * @return Phase to indicate the current phase. Either { Commit, Reveal, NUM_PHASES }.
     */
    function getVotePhase() public view override returns (Phase) {
        return Phase(uint256(voteTiming.computeCurrentPhase(getCurrentTime())));
    }

    /**
     * @notice Returns the current round ID, as a function of the current time.
     * @return uint32 the unique round ID.
     */
    function getCurrentRoundId() public view override returns (uint32) {
        return uint32(voteTiming.computeCurrentRoundId(getCurrentTime()));
    }

    /**
     * @notice Returns the round end time, as a function of the round number.
     * @param roundId representing the unique round ID.
     * @return uint256 representing the round end time.
     */
    function getRoundEndTime(uint256 roundId) external view returns (uint256) {
        return voteTiming.computeRoundEndTime(roundId);
    }

    /**
     * @notice Returns the number of current pending price requests to be voted and the number of resolved price
       requests over all time.
     * @dev This method might return stale values if the state of the contract has changed since the last time
       `processResolvablePriceRequests()` was called. To get the most up-to-date values, call
       `getNumberOfPriceRequestsPostUpdate()` instead.
     * @return numberPendingPriceRequests the total number of pending prices requests.
     * @return numberResolvedPriceRequests the total number of prices resolved over all time.
     */
    function getNumberOfPriceRequests()
        public
        view
        returns (uint256 numberPendingPriceRequests, uint256 numberResolvedPriceRequests)
    {
        return (pendingPriceRequestsIds.length, resolvedPriceRequestIds.length);
    }

    /**
     * @notice Returns the number of current pending price requests to be voted and the number of resolved price
       requests over all time after processing any resolvable price requests.
     * @return numberPendingPriceRequests the total number of pending prices requests.
     * @return numberResolvedPriceRequests the total number of prices resolved over all time.
     */
    function getNumberOfPriceRequestsPostUpdate()
        external
        returns (uint256 numberPendingPriceRequests, uint256 numberResolvedPriceRequests)
    {
        processResolvablePriceRequests();
        return getNumberOfPriceRequests();
    }

    /**
     * @notice Returns aggregate slashing trackers for a given request index.
     * @param requestIndex requestIndex the index of the request to fetch slashing trackers for.
     * @return SlashingTracker Tracker object contains the slashed UMA per staked UMA per wrong vote and no vote, the
     * total UMA slashed in the round and the total number of correct votes in the round.
     */
    function requestSlashingTrackers(uint256 requestIndex) public view returns (SlashingTracker memory) {
        PriceRequest storage priceRequest = priceRequests[resolvedPriceRequestIds[requestIndex]];
        uint32 lastVotingRound = priceRequest.lastVotingRound;
        VoteInstance storage voteInstance = priceRequest.voteInstances[lastVotingRound];

        uint256 totalVotes = voteInstance.results.totalVotes;
        uint256 totalCorrectVotes = voteInstance.results.getTotalCorrectlyVotedTokens();
        uint256 totalStaked = rounds[lastVotingRound].cumulativeStakeAtRound;

        (uint256 wrongVoteSlash, uint256 noVoteSlash) =
            rounds[lastVotingRound].slashingLibrary.calcSlashing(
                totalStaked,
                totalVotes,
                totalCorrectVotes,
                requestIndex,
                priceRequest.isGovernance
            );

        uint256 totalSlashed =
            ((noVoteSlash * (totalStaked - totalVotes)) + (wrongVoteSlash * (totalVotes - totalCorrectVotes))) / 1e18;

        return SlashingTracker(wrongVoteSlash, noVoteSlash, totalSlashed, totalCorrectVotes, lastVotingRound);
    }

    /**
     * @notice Returns the voter's participation in the vote for a given request index.
     * @param requestIndex requestIndex the index of the request to fetch slashing trackers for.
     * @param lastVotingRound the round to get voter participation for.
     * @param voter the voter to get participation for.
     * @return VoteParticipation enum representing the voter's participation in the vote.
     */
    function getVoterParticipation(
        uint256 requestIndex,
        uint32 lastVotingRound,
        address voter
    ) public view returns (VoteParticipation) {
        VoteInstance storage voteInstance =
            priceRequests[resolvedPriceRequestIds[requestIndex]].voteInstances[lastVotingRound];
        bytes32 revealHash = voteInstance.voteSubmissions[voter].revealHash;
        if (revealHash == bytes32(0)) return VoteParticipation.DidNotVote;
        if (voteInstance.results.wasVoteCorrect(revealHash)) return VoteParticipation.CorrectVote;
        return VoteParticipation.WrongVote;
    }

    /****************************************
     *        OWNER ADMIN FUNCTIONS         *
     ****************************************/

    /**
     * @notice Disables this Voting contract in favor of the migrated one.
     * @dev Can only be called by the contract owner.
     * @param newVotingAddress the newly migrated contract address.
     */
    function setMigrated(address newVotingAddress) external override onlyOwner {
        migratedAddress = newVotingAddress;
        emit VotingContractMigrated(newVotingAddress);
    }

    /**
     * @notice Sets the maximum number of rounds to roll a request can have before the DVM auto deletes it.
     * @dev Can only be called by the contract owner.
     * @param newMaxRolls the new number of rounds to roll a request before the DVM auto deletes it.
     */
    function setMaxRolls(uint32 newMaxRolls) public override onlyOwner {
        // Changes to max rolls can impact unresolved requests. To protect against this process requests first.
        processResolvablePriceRequests();
        maxRolls = newMaxRolls;
        emit MaxRollsChanged(newMaxRolls);
    }

    /**
     * @notice Sets the maximum number of requests that can be made in a single round. Used to bound the maximum
     * sequential slashing that can be applied within a single round.
     * @dev Can only be called by the contract owner.
     * @param newMaxRequestsPerRound the new maximum number of requests that can be made in a single round.
     */
    function setMaxRequestPerRound(uint32 newMaxRequestsPerRound) public override onlyOwner {
        require(newMaxRequestsPerRound > 0);
        maxRequestsPerRound = newMaxRequestsPerRound;
        emit MaxRequestsPerRoundChanged(newMaxRequestsPerRound);
    }

    /**
     * @notice Resets the GAT number and SPAT percentage. GAT is the minimum number of tokens that must participate in a
     * vote for it to resolve (quorum number). SPAT is the minimum percentage of tokens that must agree on a result
     * for it to resolve (percentage of staked tokens) This change only applies to subsequent rounds.
     * @param newGat sets the next round's GAT and going forward.
     * @param newSpat sets the next round's SPAT and going forward.
     */
    function setGatAndSpat(uint128 newGat, uint64 newSpat) public override onlyOwner {
        require(newGat < votingToken.totalSupply() && newGat > 0);
        require(newSpat > 0 && newSpat < 1e18);
        gat = newGat;
        spat = newSpat;

        emit GatAndSpatChanged(newGat, newSpat);
    }

    /**
     * @notice Changes the slashing library used by this contract.
     * @param _newSlashingLibrary new slashing library address.
     */
    function setSlashingLibrary(address _newSlashingLibrary) public override onlyOwner {
        slashingLibrary = SlashingLibraryInterface(_newSlashingLibrary);
        emit SlashingLibraryChanged(_newSlashingLibrary);
    }

    /****************************************
     *          STAKING FUNCTIONS           *
     ****************************************/

    /**
     * @notice Updates the voter's trackers for staking and slashing. Applies all unapplied slashing to given staker.
     * @dev Can be called by anyone, but it is not necessary for the contract to function is run the other functions.
     * @param voter address of the voter to update the trackers for.
     */
    function updateTrackers(address voter) external {
        _updateTrackers(voter);
    }

    /**
     * @notice Updates the voter's trackers for staking and voting, specifying a maximum number of resolved requests to
     * traverse. This function can be used in place of updateTrackers to process the trackers in batches, hence avoiding
     * potential issues if the number of elements to be processed is large and the associated gas cost is too high.
     * @param voter address of the voter to update the trackers for.
     * @param maxTraversals maximum number of resolved requests to traverse in this call.
     */
    function updateTrackersRange(address voter, uint64 maxTraversals) external {
        processResolvablePriceRequests();
        _updateAccountSlashingTrackers(voter, maxTraversals);
    }

    // Updates the global and selected wallet's trackers for staking and voting. Note that the order of these calls is
    // very important due to the interplay between slashing and inactive/active liquidity.
    function _updateTrackers(address voter) internal override {
        processResolvablePriceRequests();
        _updateAccountSlashingTrackers(voter, UINT64_MAX);
        super._updateTrackers(voter);
    }

    /**
     * @notice Process and resolve all resolvable price requests. This function traverses all pending price requests and
     *  resolves them if they are resolvable. It also rolls and deletes requests, if required.
     */
    function processResolvablePriceRequests() public {
        _processResolvablePriceRequests(UINT64_MAX);
    }

    /**
     * @notice Process and resolve all resolvable price requests. This function traverses all pending price requests and
     * resolves them if they are resolvable. It also rolls and deletes requests, if required. This function can be used
     * in place of processResolvablePriceRequests to process the requests in batches, hence avoiding potential issues if
     * the number of elements to be processed is large and the associated gas cost is too high.
     * @param maxTraversals maximum number of resolved requests to traverse in this call.
     */
    function processResolvablePriceRequestsRange(uint64 maxTraversals) external {
        _processResolvablePriceRequests(maxTraversals);
    }

    // Starting index for a staker is the first value that nextIndexToProcess is set to and defines the first index that
    // a staker is suspectable to receiving slashing on. This is set to current length of the resolvedPriceRequestIds.
    // Note first call processResolvablePriceRequests to ensure that the resolvedPriceRequestIds array is up to date.
    function _getStartingIndexForStaker() internal override returns (uint64) {
        processResolvablePriceRequests();
        return SafeCast.toUint64(resolvedPriceRequestIds.length);
    }

    // Checks if we are in an active voting reveal phase (currently revealing votes). This impacts if a new staker's
    // stake should be activated immediately or if it should be frozen until the end of the reveal phase.
    function _inActiveReveal() internal view override returns (bool) {
        return (currentActiveRequests() && getVotePhase() == Phase.Reveal);
    }

    // This function must be called before any tokens are staked. It updates the voter's pending stakes to reflect the
    // new amount to stake. These updates are only made if we are in an active reveal. This is required to appropriately
    // calculate a voter's trackers and avoid slashing them for amounts staked during an active reveal phase.
    function _computePendingStakes(address voter, uint128 amount) internal override {
        if (_inActiveReveal()) {
            uint32 currentRoundId = getCurrentRoundId();
            // Freeze round variables to prevent cumulativeActiveStakeAtRound from changing based on the stakes during
            // the active reveal phase. This will happen if the first action within the reveal is someone staking.
            _freezeRoundVariables(currentRoundId);
            // Increment pending stake for voter by amount. With the omission of stake from cumulativeActiveStakeAtRound
            // for this round, ensure that the pending stakes is not included in the slashing calculation for this round.
            _incrementPendingStake(voter, currentRoundId, amount);
        }
    }

    // Updates the slashing trackers of a given account based on previous voting activity. This traverses all resolved
    // requests for each voter and for each request checks if the voter voted correctly or not. Based on the voters
    // voting activity the voters balance is updated accordingly. The caller can provide a maxTraversals parameter to
    // limit the number of resolved requests to traverse in this call to bound the gas used. Note each iteration of
    // this function re-uses a fresh slash variable to produce useful logs on the amount a voter is slashed.
    function _updateAccountSlashingTrackers(address voter, uint64 maxTraversals) internal {
        VoterStake storage voterStake = voterStakes[voter];
        uint64 requestIndex = voterStake.nextIndexToProcess; // Traverse all requests from the last considered request.

        // Traverse all elements within the resolvedPriceRequestIds array and update the voter's trackers according to
        // their voting activity. Bound the number of iterations to the maxTraversals parameter to cap the gas used.
        while (requestIndex < resolvedPriceRequestIds.length && maxTraversals > 0) {
            maxTraversals = unsafe_dec_64(maxTraversals); // reduce the number of traversals left & re-use the prop.

            // Get the slashing for this request. This comes from the slashing library and informs to the voter slash.
            SlashingTracker memory trackers = requestSlashingTrackers(requestIndex);

            // Use the effective stake as the difference between the current stake and pending stake. The staker will
            //have a pending stake if they staked during an active reveal for the voting round in question.
            uint256 effectiveStake = voterStake.stake - voterStake.pendingStakes[trackers.lastVotingRound];
            int256 slash; // The amount to slash the voter by for this request. Reset on each entry to emit useful logs.

            // Get the voter participation for this request. This informs if the voter voted correctly or not.
            VoteParticipation participation = getVoterParticipation(requestIndex, trackers.lastVotingRound, voter);

            // The voter did not reveal or did not commit. Slash at noVote rate.
            if (participation == VoteParticipation.DidNotVote)
                slash = -int256(Math.ceilDiv(effectiveStake * trackers.noVoteSlashPerToken, 1e18));

                // The voter did not vote with the majority. Slash at wrongVote rate.
            else if (participation == VoteParticipation.WrongVote)
                slash = -int256(Math.ceilDiv(effectiveStake * trackers.wrongVoteSlashPerToken, 1e18));

                // Else, the voter voted correctly. Receive a pro-rate share of the other voters slash.
            else slash = int256((effectiveStake * trackers.totalSlashed) / trackers.totalCorrectVotes);

            emit VoterSlashed(voter, requestIndex, int128(slash));
            voterStake.unappliedSlash += int128(slash);

            // If the next round is different to the current considered round, apply the slash to the voter.
            if (isNextRequestRoundDifferent(requestIndex)) _applySlashToVoter(voterStake, voter);

            requestIndex = unsafe_inc_64(requestIndex); // Increment the request index.
        }

        // Set the account's nextIndexToProcess to the requestIndex so the next entry starts where we left off.
        voterStake.nextIndexToProcess = requestIndex;
    }

    // Applies a given slash to a given voter's stake. In the event the sum of the slash and the voter's stake is less
    // than 0, the voter's stake is set to 0 to prevent the voter's stake from going negative. unappliedSlash tracked
    // all slashing the staker has received but not yet applied to their stake. Apply it then set it to zero.
    function _applySlashToVoter(VoterStake storage voterStake, address voter) internal {
        if (voterStake.unappliedSlash + int128(voterStake.stake) > 0)
            voterStake.stake = uint128(int128(voterStake.stake) + voterStake.unappliedSlash);
        else voterStake.stake = 0;
        emit VoterSlashApplied(voter, voterStake.unappliedSlash, voterStake.stake);
        voterStake.unappliedSlash = 0;
    }

    // Checks if the next round (index+1) is different to the current round (index).
    function isNextRequestRoundDifferent(uint64 index) internal view returns (bool) {
        if (index + 1 >= resolvedPriceRequestIds.length) return true;

        return
            priceRequests[resolvedPriceRequestIds[index]].lastVotingRound !=
            priceRequests[resolvedPriceRequestIds[index + 1]].lastVotingRound;
    }

    /****************************************
     *      MIGRATION SUPPORT FUNCTIONS     *
     ****************************************/

    /**
     * @notice Enable retrieval of rewards on a previously migrated away from voting contract. This function is intended
     * on being removed from future versions of the Voting contract and aims to solve a short term migration pain point.
     * @param voter voter for which rewards will be retrieved. Does not have to be the caller.
     * @param roundId the round from which voting rewards will be retrieved from.
     * @param toRetrieve array of PendingRequests which rewards are retrieved from.
     * @return uint256 the amount of rewards.
     */
    function retrieveRewardsOnMigratedVotingContract(
        address voter,
        uint256 roundId,
        MinimumVotingAncillaryInterface.PendingRequestAncillary[] memory toRetrieve
    ) external returns (uint256) {
        uint256 rewards =
            MinimumVotingAncillaryInterface(address(previousVotingContract))
                .retrieveRewards(voter, roundId, toRetrieve)
                .rawValue;
        return rewards;
    }

    /****************************************
     *    PRIVATE AND INTERNAL FUNCTIONS    *
     ****************************************/

    // Deletes a request from the pending requests array, based on index. Swap and pop.
    function _removeRequestFromPendingPriceRequestsIds(uint64 pendingRequestIndex) internal {
        pendingPriceRequestsIds[pendingRequestIndex] = pendingPriceRequestsIds[pendingPriceRequestsIds.length - 1];
        pendingPriceRequestsIds.pop();
    }

    // Returns the price for a given identifier. Three params are returns: bool if there was an error, int to represent
    // the resolved price and a string which is filled with an error message, if there was an error or "".
    // This method considers actual request status that might be ahead of the stored contract state that gets updated
    // only after processResolvablePriceRequests() is called.
    function _getPriceOrError(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    )
        internal
        view
        returns (
            bool,
            int256,
            string memory
        )
    {
        PriceRequest storage priceRequest = _getPriceRequest(identifier, time, ancillaryData);
        uint32 currentRoundId = getCurrentRoundId();
        RequestStatus requestStatus = _getRequestStatus(priceRequest, currentRoundId);

        if (requestStatus == RequestStatus.Active) return (false, 0, "Current voting round not ended");
        if (requestStatus == RequestStatus.Resolved) {
            VoteInstance storage voteInstance = priceRequest.voteInstances[priceRequest.lastVotingRound];
            (, int256 resolvedPrice) = _getResolvedPrice(voteInstance, priceRequest.lastVotingRound);
            return (true, resolvedPrice, "");
        }

        if (requestStatus == RequestStatus.Future) return (false, 0, "Price is still to be voted on");
        if (requestStatus == RequestStatus.ToDelete) return (false, 0, "Price will be deleted");
        (bool previouslyResolved, int256 previousPrice) =
            _getPriceFromPreviousVotingContract(identifier, time, ancillaryData);
        if (previouslyResolved) return (true, previousPrice, "");
        return (false, 0, "Price was never requested");
    }

    // Check the previousVotingContract to see if a given price request was resolved.
    // Returns true or false, and the resolved price or zero, depending on whether it was found or not.
    function _getPriceFromPreviousVotingContract(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) private view returns (bool, int256) {
        if (address(previousVotingContract) == address(0)) return (false, 0);
        if (previousVotingContract.hasPrice(identifier, time, ancillaryData))
            return (true, previousVotingContract.getPrice(identifier, time, ancillaryData));
        return (false, 0);
    }

    // Returns a price request object for a given identifier, time and ancillary data.
    function _getPriceRequest(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) private view returns (PriceRequest storage) {
        return priceRequests[_encodePriceRequest(identifier, time, ancillaryData)];
    }

    // Returns an encoded bytes32 representing a price request. Used when storing/referencing price requests.
    function _encodePriceRequest(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(identifier, time, ancillaryData));
    }

    // Stores ("freezes") variables that should not shift within an active voting round. Called on reveal but only makes
    // a state change if and only if the this is the first reveal.
    function _freezeRoundVariables(uint256 roundId) private {
        // Only freeze the round if this is the first request in the round.
        if (rounds[roundId].minParticipationRequirement == 0) {
            rounds[roundId].slashingLibrary = slashingLibrary;

            // The minimum required participation for a vote to settle within this round is the GAT (fixed number).
            rounds[roundId].minParticipationRequirement = gat;

            // The minimum votes on the modal outcome for the vote to settle within this round is the SPAT (percentage).
            rounds[roundId].minAgreementRequirement = uint128((spat * uint256(cumulativeStake)) / 1e18);
            rounds[roundId].cumulativeStakeAtRound = cumulativeStake; // Store the cumulativeStake to work slashing.
        }
    }

    // Traverse pending price requests and resolve any that are resolvable. If requests are rollable (they did not
    // resolve in the previous round and are to be voted in a subsequent round) then roll them. If requests can be
    // deleted (they have been rolled up to the maxRolls counter) then delete them. The caller can pass in maxTraversals
    // to limit the number of requests that are resolved in a single call to bound the total gas used by this function.
    // Note that the resolved index is stores for each round. This means that only the first caller of this function
    // per round needs to traverse the pending requests. After that subsequent calls to this are a no-op for that round.
    function _processResolvablePriceRequests(uint64 maxTraversals) private {
        uint32 currentRoundId = getCurrentRoundId();

        // Load in the last resolved index for this round to continue off from where the last caller left.
        uint64 requestIndex = lastRoundIdProcessed == currentRoundId ? nextPendingIndexToProcess : 0;
        // Traverse pendingPriceRequestsIds array and update the requests status according to the state of the request
        //(i.e settle, roll or delete request). Bound iterations to the maxTraversals parameter to cap the gas used.
        while (requestIndex < pendingPriceRequestsIds.length && maxTraversals > 0) {
            maxTraversals = unsafe_dec_64(maxTraversals);
            PriceRequest storage request = priceRequests[pendingPriceRequestsIds[requestIndex]];

            // If the last voting round is greater than or equal to the current round then this request is currently
            // being voted on or is enqueued for the next round. In this case, skip it and increment the request index.
            if (request.lastVotingRound >= currentRoundId) {
                requestIndex = unsafe_inc_64(requestIndex);
                continue; // Continue to the next request.
            }

            // Else, we are dealing with a request that can either be: a) deleted, b) rolled or c) resolved.
            VoteInstance storage voteInstance = request.voteInstances[request.lastVotingRound];
            (bool isResolvable, int256 resolvedPrice) = _getResolvedPrice(voteInstance, request.lastVotingRound);

            if (isResolvable) {
                // If resolvable, resolve. This involves a) moving the requestId from pendingPriceRequestsIds array to
                // resolvedPriceRequestIds array and b) removing requestId from pendingPriceRequestsIds. Don't need to
                // increment requestIndex as from pendingPriceRequestsIds amounts to decreasing the while loop bound.
                resolvedPriceRequestIds.push(pendingPriceRequestsIds[requestIndex]);
                _removeRequestFromPendingPriceRequestsIds(requestIndex);
                emit RequestResolved(
                    request.lastVotingRound,
                    resolvedPriceRequestIds.length - 1,
                    request.identifier,
                    request.time,
                    request.ancillaryData,
                    resolvedPrice
                );
                continue; // Continue to the next request.
            }
            // If not resolvable, but the round has passed its voting round, then it must be deleted or rolled. First,
            // increment the rollCount. Use the difference between the current round and the last voting round to
            // accommodate the contract not being touched for any number of rounds during the roll.
            request.rollCount += currentRoundId - request.lastVotingRound;

            // If the roll count exceeds the threshold and the request is not governance then it is deletable.
            if (_shouldDeleteRequest(request.rollCount, request.isGovernance)) {
                emit RequestDeleted(request.identifier, request.time, request.ancillaryData, request.rollCount);
                delete priceRequests[pendingPriceRequestsIds[requestIndex]];
                _removeRequestFromPendingPriceRequestsIds(requestIndex);
                continue;
            }
            // Else, the request should be rolled. This involves only moving forward the lastVotingRound.
            request.lastVotingRound = getRoundIdToVoteOnRequest(currentRoundId);
            ++rounds[request.lastVotingRound].numberOfRequestsToVote;
            emit RequestRolled(request.identifier, request.time, request.ancillaryData, request.rollCount);
            requestIndex = unsafe_inc_64(requestIndex);
        }

        lastRoundIdProcessed = currentRoundId; // Store the roundId that was processed.
        nextPendingIndexToProcess = requestIndex; // Store the index traversed up to for this round.
    }

    // Returns a price request status. A request is either: NotRequested, Active, Resolved, Future or ToDelete.
    function _getRequestStatus(PriceRequest storage priceRequest, uint32 currentRoundId)
        private
        view
        returns (RequestStatus)
    {
        if (priceRequest.lastVotingRound == 0) return RequestStatus.NotRequested;
        if (priceRequest.lastVotingRound < currentRoundId) {
            // Check if the request has already been resolved
            VoteInstance storage voteInstance = priceRequest.voteInstances[priceRequest.lastVotingRound];
            (bool isResolved, ) = _getResolvedPrice(voteInstance, priceRequest.lastVotingRound);
            if (isResolved) return RequestStatus.Resolved;
            if (_shouldDeleteRequest(_getActualRollCount(priceRequest, currentRoundId), priceRequest.isGovernance))
                return RequestStatus.ToDelete;
            return RequestStatus.Active;
        }
        if (priceRequest.lastVotingRound == currentRoundId) return RequestStatus.Active;

        return RequestStatus.Future; // Means than priceRequest.lastVotingRound > currentRoundId
    }

    function _getResolvedPrice(VoteInstance storage voteInstance, uint256 lastVotingRound)
        internal
        view
        returns (bool isResolved, int256 price)
    {
        return
            voteInstance.results.getResolvedPrice(
                rounds[lastVotingRound].minParticipationRequirement,
                rounds[lastVotingRound].minAgreementRequirement
            );
    }

    // Gas optimized uint256 increment.
    function unsafe_inc(uint256 x) internal pure returns (uint256) {
        unchecked { return x + 1; }
    }

    // Gas optimized uint64 increment.
    function unsafe_inc_64(uint64 x) internal pure returns (uint64) {
        unchecked { return x + 1; }
    }

    // Gas optimized uint64 decrement.
    function unsafe_dec_64(uint64 x) internal pure returns (uint64) {
        unchecked { return x - 1; }
    }

    // Returns the registered identifier whitelist, stored in the finder.
    function _getIdentifierWhitelist() private view returns (IdentifierWhitelistInterface) {
        return IdentifierWhitelistInterface(finder.getImplementationAddress(OracleInterfaces.IdentifierWhitelist));
    }

    // Reverts if the contract has been migrated. Used in a modifier, defined as a private function for gas savings.
    function _requireNotMigrated() private view {
        require(migratedAddress == address(0), "Contract migrated");
    }

    // Enforces that a calling contract is registered.
    function _requireRegisteredContract() private view {
        RegistryInterface registry = RegistryInterface(finder.getImplementationAddress(OracleInterfaces.Registry));
        require(registry.isContractRegistered(msg.sender) || msg.sender == migratedAddress, "Caller not registered");
    }

    // Checks if a request should be deleted. A non-gevernance request should be deleted if it has been rolled more than
    // the maxRolls.
    function _shouldDeleteRequest(uint256 rollCount, bool isGovernance) private view returns (bool) {
        return rollCount > maxRolls && !isGovernance;
    }

    // Returns the actual roll count of a request. This is the roll count plus the number of rounds that have passed
    // since the last voting round.
    function _getActualRollCount(PriceRequest storage priceRequest, uint32 currentRoundId)
        private
        view
        returns (uint32)
    {
        if (currentRoundId <= priceRequest.lastVotingRound) return priceRequest.rollCount;
        return priceRequest.rollCount + currentRoundId - priceRequest.lastVotingRound;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface FinderInterface {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Interface for whitelists of supported identifiers that the oracle can provide prices for.
 */
interface IdentifierWhitelistInterface {
    /**
     * @notice Adds the provided identifier as a supported identifier.
     * @dev Price requests using this identifier will succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function addSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Removes the identifier from the whitelist.
     * @dev Price requests using this identifier will no longer succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function removeSupportedIdentifier(bytes32 identifier) external;

    /**
     * @notice Checks whether an identifier is on the whitelist.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     * @return bool if the identifier is supported (or not).
     */
    function isIdentifierSupported(bytes32 identifier) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

interface MinimumVotingAncillaryInterface {
    struct Unsigned {
        uint256 rawValue;
    }

    struct PendingRequestAncillary {
        bytes32 identifier;
        uint256 time;
        bytes ancillaryData;
    }

    function retrieveRewards(
        address voterAddress,
        uint256 roundId,
        PendingRequestAncillary[] memory toRetrieve
    ) external returns (Unsigned memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OracleAncillaryInterface {
    /**
     * @notice Enqueues a request (if a request isn't already present) for the given `identifier`, `time` pair.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param time unix timestamp for the price request.
     */

    function requestPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public virtual;

    /**
     * @notice Whether the price for `identifier` and `time` is available.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @return bool if the DVM has resolved to a price for the given identifier and timestamp.
     */
    function hasPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view virtual returns (bool);

    /**
     * @notice Gets the price for `identifier` and `time` if it has already been requested and resolved.
     * @dev If the price is not available, the method reverts.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @return int256 representing the resolved price for the given identifier and timestamp.
     */

    function getPrice(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) public view virtual returns (int256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./OracleAncillaryInterface.sol";

/**
 * @title Financial contract facing extending the Oracle interface with governance actions.
 * @dev Interface used by financial contracts to interact with the Oracle extending governance actions. Voters will use a different interface.
 */
abstract contract OracleGovernanceInterface is OracleInterface, OracleAncillaryInterface {
    /**
     * @notice Enqueues a request (if a request isn't already present) for the given `identifier`, `time` pair.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param time unix timestamp for the price request.
     */
    function requestGovernanceAction(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData
    ) external virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OracleInterface {
    /**
     * @notice Enqueues a request (if a request isn't already present) for the given `identifier`, `time` pair.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     */
    function requestPrice(bytes32 identifier, uint256 time) external virtual;

    /**
     * @notice Whether the price for `identifier` and `time` is available.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @return bool if the DVM has resolved to a price for the given identifier and timestamp.
     */
    function hasPrice(bytes32 identifier, uint256 time) external view virtual returns (bool);

    /**
     * @notice Gets the price for `identifier` and `time` if it has already been requested and resolved.
     * @dev If the price is not available, the method reverts.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @return int256 representing the resolved price for the given identifier and timestamp.
     */
    function getPrice(bytes32 identifier, uint256 time) external view virtual returns (int256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Interface for a registry of contracts and contract creators.
 */
interface RegistryInterface {
    /**
     * @notice Registers a new contract.
     * @dev Only authorized contract creators can call this method.
     * @param parties an array of addresses who become parties in the contract.
     * @param contractAddress defines the address of the deployed contract.
     */
    function registerContract(address[] calldata parties, address contractAddress) external;

    /**
     * @notice Returns whether the contract has been registered with the registry.
     * @dev If it is registered, it is an authorized participant in the UMA system.
     * @param contractAddress address of the contract.
     * @return bool indicates whether the contract is registered.
     */
    function isContractRegistered(address contractAddress) external view returns (bool);

    /**
     * @notice Returns a list of all contracts that are associated with a particular party.
     * @param party address of the party.
     * @return an array of the contracts the party is registered to.
     */
    function getRegisteredContracts(address party) external view returns (address[] memory);

    /**
     * @notice Returns all registered contracts.
     * @return all registered contract addresses within the system.
     */
    function getAllRegisteredContracts() external view returns (address[] memory);

    /**
     * @notice Adds a party to the calling contract.
     * @dev msg.sender must be the contract to which the party member is added.
     * @param party address to be added to the contract.
     */
    function addPartyToContract(address party) external;

    /**
     * @notice Removes a party member to the calling contract.
     * @dev msg.sender must be the contract to which the party member is added.
     * @param party address to be removed from the contract.
     */
    function removePartyFromContract(address party) external;

    /**
     * @notice checks if an address is a party in a contract.
     * @param party party to check.
     * @param contractAddress address to check against the party.
     * @return bool indicating if the address is a party of the contract.
     */
    function isPartyMemberOfContract(address party, address contractAddress) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

interface SlashingLibraryInterface {
    /**
     * @notice Calculates the wrong vote slash per token.
     * @param totalStaked The total amount of tokens staked.
     * @param totalVotes The total amount of votes.
     * @param totalCorrectVotes The total amount of correct votes.
     * @param priceRequestIndex The price request index within the resolvedPriceRequestIds array.
     * @return uint256 The amount of tokens to slash per token staked.
     */
    function calcWrongVoteSlashPerToken(
        uint256 totalStaked,
        uint256 totalVotes,
        uint256 totalCorrectVotes,
        uint256 priceRequestIndex
    ) external view returns (uint256);

    /**
     * @notice Calculates the wrong vote slash per token for governance requests.
     * @param totalStaked The total amount of tokens staked.
     * @param totalVotes The total amount of votes.
     * @param totalCorrectVotes The total amount of correct votes.
     * @param priceRequestIndex The price request index within the resolvedPriceRequestIds array.
     * @return uint256 The amount of tokens to slash per token staked.
     */
    function calcWrongVoteSlashPerTokenGovernance(
        uint256 totalStaked,
        uint256 totalVotes,
        uint256 totalCorrectVotes,
        uint256 priceRequestIndex
    ) external view returns (uint256);

    /**
     * @notice Calculates the no vote slash per token.
     * @param totalStaked The total amount of tokens staked.
     * @param totalVotes The total amount of votes.
     * @param totalCorrectVotes The total amount of correct votes.
     * @param priceRequestIndex The price request index within the resolvedPriceRequestIds array.
     * @return uint256 The amount of tokens to slash per token staked.
     */
    function calcNoVoteSlashPerToken(
        uint256 totalStaked,
        uint256 totalVotes,
        uint256 totalCorrectVotes,
        uint256 priceRequestIndex
    ) external view returns (uint256);

    /**
     * @notice Calculates all slashing trackers in one go to decrease cross-contract calls needed.
     * @param totalStaked The total amount of tokens staked.
     * @param totalVotes The total amount of votes.
     * @param totalCorrectVotes The total amount of correct votes.
     * @param priceRequestIndex The price request index within the resolvedPriceRequestIds array.
     * @param isGovernance Whether the request is a governance request.
     * @return wrongVoteSlashPerToken The amount of tokens to slash for voting wrong.
     * @return noVoteSlashPerToken The amount of tokens to slash for not voting.
     */
    function calcSlashing(
        uint256 totalStaked,
        uint256 totalVotes,
        uint256 totalCorrectVotes,
        uint256 priceRequestIndex,
        bool isGovernance
    ) external view returns (uint256 wrongVoteSlashPerToken, uint256 noVoteSlashPerToken);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

import "../implementation/VotingToken.sol";
import "../../common/interfaces/ExpandedIERC20.sol";

interface StakerInterface {
    function votingToken() external returns (ExpandedIERC20);

    function stake(uint128 amount) external;

    function requestUnstake(uint128 amount) external;

    function executeUnstake() external;

    function withdrawRewards() external returns (uint128);

    function withdrawAndRestake() external returns (uint128);

    function setEmissionRate(uint128 newEmissionRate) external;

    function setUnstakeCoolDown(uint64 newUnstakeCoolDown) external;

    /**
     * @notice Sets the delegate of a voter. This delegate can vote on behalf of the staker. The staker will still own
     * all staked balances, receive rewards and be slashed based on the actions of the delegate. Intended use is using a
     * low-security available wallet for voting while keeping access to staked amounts secure by a more secure wallet.
     * @param delegate the address of the delegate.
     */
    function setDelegate(address delegate) external virtual;

    /**
     * @notice Sets the delegator of a voter. Acts to accept a delegation. The delegate can only vote for the delegator
     * if the delegator also selected the delegate to do so (two-way relationship needed).
     * @param delegator the address of the delegator.
     */
    function setDelegator(address delegator) external virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../common/implementation/FixedPoint.sol";

/**
 * @title Interface that voters must use to Vote on price request resolutions.
 */
abstract contract VotingAncillaryInterface {
    struct PendingRequestAncillary {
        bytes32 identifier;
        uint256 time;
        bytes ancillaryData;
    }

    // Captures the necessary data for making a commitment.
    // Used as a parameter when making batch commitments.
    // Not used as a data structure for storage.
    struct CommitmentAncillary {
        bytes32 identifier;
        uint256 time;
        bytes ancillaryData;
        bytes32 hash;
        bytes encryptedVote;
    }

    // Captures the necessary data for revealing a vote.
    // Used as a parameter when making batch reveals.
    // Not used as a data structure for storage.
    struct RevealAncillary {
        bytes32 identifier;
        uint256 time;
        int256 price;
        bytes ancillaryData;
        int256 salt;
    }

    // Note: the phases must be in order. Meaning the first enum value must be the first phase, etc.
    // `NUM_PHASES` is to get the number of phases. It isn't an actual phase, and it should always be last.
    enum Phase { Commit, Reveal, NUM_PHASES }

    /**
     * @notice Commit a vote for a price request for `identifier` at `time`.
     * @dev `identifier`, `time` must correspond to a price request that's currently in the commit phase.
     * Commits can be changed.
     * @dev Since transaction data is public, the salt will be revealed with the vote. While this is the system’s expected behavior,
     * voters should never reuse salts. If someone else is able to guess the voted price and knows that a salt will be reused, then
     * they can determine the vote pre-reveal.
     * @param identifier uniquely identifies the committed vote. E.G. BTC/USD price pair.
     * @param time unix timestamp of the price being voted on.
     * @param hash keccak256 hash of the `price`, `salt`, voter `address`, `time`, current `roundId`, and `identifier`.
     */
    function commitVote(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        bytes32 hash
    ) public virtual;

    /**
     * @notice Submit a batch of commits in a single transaction.
     * @dev Using `encryptedVote` is optional. If included then commitment is stored on chain.
     * Look at `project-root/common/Constants.js` for the tested maximum number of
     * commitments that can fit in one transaction.
     * @param commits array of structs that encapsulate an `identifier`, `time`, `hash` and optional `encryptedVote`.
     */
    function batchCommit(CommitmentAncillary[] memory commits) public virtual;

    /**
     * @notice commits a vote and logs an event with a data blob, typically an encrypted version of the vote
     * @dev An encrypted version of the vote is emitted in an event `EncryptedVote` to allow off-chain infrastructure to
     * retrieve the commit. The contents of `encryptedVote` are never used on chain: it is purely for convenience.
     * @param identifier unique price pair identifier. E.g. BTC/USD price pair.
     * @param time unix timestamp of for the price request.
     * @param hash keccak256 hash of the price you want to vote for and a `int256 salt`.
     * @param encryptedVote offchain encrypted blob containing the voters amount, time and salt.
     */
    function commitAndEmitEncryptedVote(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        bytes32 hash,
        bytes memory encryptedVote
    ) public virtual;

    /**
     * @notice snapshot the current round's token balances and lock in the inflation rate and GAT.
     * @dev This function can be called multiple times but each round will only every have one snapshot at the
     * time of calling `_freezeRoundVariables`.
     * @param signature  signature required to prove caller is an EOA to prevent flash loans from being included in the
     * snapshot.
     */
    function snapshotCurrentRound(bytes calldata signature) external virtual;

    /**
     * @notice Reveal a previously committed vote for `identifier` at `time`.
     * @dev The revealed `price`, `salt`, `address`, `time`, `roundId`, and `identifier`, must hash to the latest `hash`
     * that `commitVote()` was called with. Only the committer can reveal their vote.
     * @param identifier voted on in the commit phase. EG BTC/USD price pair.
     * @param time specifies the unix timestamp of the price is being voted on.
     * @param price voted on during the commit phase.
     * @param salt value used to hide the commitment price during the commit phase.
     */
    function revealVote(
        bytes32 identifier,
        uint256 time,
        int256 price,
        bytes memory ancillaryData,
        int256 salt
    ) public virtual;

    /**
     * @notice Reveal multiple votes in a single transaction.
     * Look at `project-root/common/Constants.js` for the tested maximum number of reveals.
     * that can fit in one transaction.
     * @dev For more information on reveals, review the comment for `revealVote`.
     * @param reveals array of the Reveal struct which contains an identifier, time, price and salt.
     */
    function batchReveal(RevealAncillary[] memory reveals) public virtual;

    /**
     * @notice Gets the queries that are being voted on this round.
     * @return pendingRequests `PendingRequest` array containing identifiers
     * and timestamps for all pending requests.
     */
    function getPendingRequests() external view virtual returns (PendingRequestAncillary[] memory);

    /**
     * @notice Returns the current voting phase, as a function of the current time.
     * @return Phase to indicate the current phase. Either { Commit, Reveal, NUM_PHASES }.
     */
    function getVotePhase() external view virtual returns (Phase);

    /**
     * @notice Returns the current round ID, as a function of the current time.
     * @return uint256 representing the unique round ID.
     */
    function getCurrentRoundId() external view virtual returns (uint256);

    /**
     * @notice Retrieves rewards owed for a set of resolved price requests.
     * @dev Can only retrieve rewards if calling for a valid round and if the
     * call is done within the timeout threshold (not expired).
     * @param voterAddress voter for which rewards will be retrieved. Does not have to be the caller.
     * @param roundId the round from which voting rewards will be retrieved from.
     * @param toRetrieve array of PendingRequests which rewards are retrieved from.
     * @return total amount of rewards returned to the voter.
     */
    function retrieveRewards(
        address voterAddress,
        uint256 roundId,
        PendingRequestAncillary[] memory toRetrieve
    ) public virtual returns (FixedPoint.Unsigned memory);

    // Voting Owner functions.

    /**
     * @notice Disables this Voting contract in favor of the migrated one.
     * @dev Can only be called by the contract owner.
     * @param newVotingAddress the newly migrated contract address.
     */
    function setMigrated(address newVotingAddress) external virtual;

    /**
     * @notice Resets the inflation rate. Note: this change only applies to rounds that have not yet begun.
     * @dev This method is public because calldata structs are not currently supported by solidity.
     * @param newInflationRate sets the next round's inflation rate.
     */
    function setInflationRate(FixedPoint.Unsigned memory newInflationRate) public virtual;

    /**
     * @notice Resets the Gat percentage. Note: this change only applies to rounds that have not yet begun.
     * @dev This method is public because calldata structs are not currently supported by solidity.
     * @param newGatPercentage sets the next round's Gat percentage.
     */
    function setGatPercentage(FixedPoint.Unsigned memory newGatPercentage) public virtual;

    /**
     * @notice Resets the rewards expiration timeout.
     * @dev This change only applies to rounds that have not yet begun.
     * @param NewRewardsExpirationTimeout how long a caller can wait before choosing to withdraw their rewards.
     */
    function setRewardsExpirationTimeout(uint256 NewRewardsExpirationTimeout) public virtual;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../common/implementation/FixedPoint.sol";
import "./VotingAncillaryInterface.sol";

/**
 * @title Interface that voters must use to Vote on price request resolutions.
 */
abstract contract VotingInterface {
    struct PendingRequest {
        bytes32 identifier;
        uint256 time;
    }

    // Captures the necessary data for making a commitment.
    // Used as a parameter when making batch commitments.
    // Not used as a data structure for storage.
    struct Commitment {
        bytes32 identifier;
        uint256 time;
        bytes32 hash;
        bytes encryptedVote;
    }

    // Captures the necessary data for revealing a vote.
    // Used as a parameter when making batch reveals.
    // Not used as a data structure for storage.
    struct Reveal {
        bytes32 identifier;
        uint256 time;
        int256 price;
        int256 salt;
    }

    /**
     * @notice Commit a vote for a price request for `identifier` at `time`.
     * @dev `identifier`, `time` must correspond to a price request that's currently in the commit phase.
     * Commits can be changed.
     * @dev Since transaction data is public, the salt will be revealed with the vote. While this is the system’s expected behavior,
     * voters should never reuse salts. If someone else is able to guess the voted price and knows that a salt will be reused, then
     * they can determine the vote pre-reveal.
     * @param identifier uniquely identifies the committed vote. EG BTC/USD price pair.
     * @param time unix timestamp of the price being voted on.
     * @param hash keccak256 hash of the `price`, `salt`, voter `address`, `time`, current `roundId`, and `identifier`.
     */
    function commitVote(
        bytes32 identifier,
        uint256 time,
        bytes32 hash
    ) external virtual;

    /**
     * @notice Submit a batch of commits in a single transaction.
     * @dev Using `encryptedVote` is optional. If included then commitment is stored on chain.
     * Look at `project-root/common/Constants.js` for the tested maximum number of
     * commitments that can fit in one transaction.
     * @param commits array of structs that encapsulate an `identifier`, `time`, `hash` and optional `encryptedVote`.
     */
    function batchCommit(Commitment[] memory commits) public virtual;

    /**
     * @notice commits a vote and logs an event with a data blob, typically an encrypted version of the vote
     * @dev An encrypted version of the vote is emitted in an event `EncryptedVote` to allow off-chain infrastructure to
     * retrieve the commit. The contents of `encryptedVote` are never used on chain: it is purely for convenience.
     * @param identifier unique price pair identifier. Eg: BTC/USD price pair.
     * @param time unix timestamp of for the price request.
     * @param hash keccak256 hash of the price you want to vote for and a `int256 salt`.
     * @param encryptedVote offchain encrypted blob containing the voters amount, time and salt.
     */
    function commitAndEmitEncryptedVote(
        bytes32 identifier,
        uint256 time,
        bytes32 hash,
        bytes memory encryptedVote
    ) public virtual;

    /**
     * @notice snapshot the current round's token balances and lock in the inflation rate and GAT.
     * @dev This function can be called multiple times but each round will only every have one snapshot at the
     * time of calling `_freezeRoundVariables`.
     * @param signature  signature required to prove caller is an EOA to prevent flash loans from being included in the
     * snapshot.
     */
    function snapshotCurrentRound(bytes calldata signature) external virtual;

    /**
     * @notice Reveal a previously committed vote for `identifier` at `time`.
     * @dev The revealed `price`, `salt`, `address`, `time`, `roundId`, and `identifier`, must hash to the latest `hash`
     * that `commitVote()` was called with. Only the committer can reveal their vote.
     * @param identifier voted on in the commit phase. EG BTC/USD price pair.
     * @param time specifies the unix timestamp of the price is being voted on.
     * @param price voted on during the commit phase.
     * @param salt value used to hide the commitment price during the commit phase.
     */
    function revealVote(
        bytes32 identifier,
        uint256 time,
        int256 price,
        int256 salt
    ) public virtual;

    /**
     * @notice Reveal multiple votes in a single transaction.
     * Look at `project-root/common/Constants.js` for the tested maximum number of reveals.
     * that can fit in one transaction.
     * @dev For more information on reveals, review the comment for `revealVote`.
     * @param reveals array of the Reveal struct which contains an identifier, time, price and salt.
     */
    function batchReveal(Reveal[] memory reveals) public virtual;

    /**
     * @notice Gets the queries that are being voted on this round.
     * @return pendingRequests `PendingRequest` array containing identifiers
     * and timestamps for all pending requests.
     */
    function getPendingRequests()
        external
        view
        virtual
        returns (VotingAncillaryInterface.PendingRequestAncillary[] memory);

    /**
     * @notice Returns the current voting phase, as a function of the current time.
     * @return Phase to indicate the current phase. Either { Commit, Reveal, NUM_PHASES }.
     */
    function getVotePhase() external view virtual returns (VotingAncillaryInterface.Phase);

    /**
     * @notice Returns the current round ID, as a function of the current time.
     * @return uint256 representing the unique round ID.
     */
    function getCurrentRoundId() external view virtual returns (uint256);

    /**
     * @notice Retrieves rewards owed for a set of resolved price requests.
     * @dev Can only retrieve rewards if calling for a valid round and if the
     * call is done within the timeout threshold (not expired).
     * @param voterAddress voter for which rewards will be retrieved. Does not have to be the caller.
     * @param roundId the round from which voting rewards will be retrieved from.
     * @param toRetrieve array of PendingRequests which rewards are retrieved from.
     * @return total amount of rewards returned to the voter.
     */
    function retrieveRewards(
        address voterAddress,
        uint256 roundId,
        PendingRequest[] memory toRetrieve
    ) public virtual returns (FixedPoint.Unsigned memory);

    // Voting Owner functions.

    /**
     * @notice Disables this Voting contract in favor of the migrated one.
     * @dev Can only be called by the contract owner.
     * @param newVotingAddress the newly migrated contract address.
     */
    function setMigrated(address newVotingAddress) external virtual;

    /**
     * @notice Resets the inflation rate. Note: this change only applies to rounds that have not yet begun.
     * @dev This method is public because calldata structs are not currently supported by solidity.
     * @param newInflationRate sets the next round's inflation rate.
     */
    function setInflationRate(FixedPoint.Unsigned memory newInflationRate) public virtual;

    /**
     * @notice Resets the Gat percentage. Note: this change only applies to rounds that have not yet begun.
     * @dev This method is public because calldata structs are not currently supported by solidity.
     * @param newGatPercentage sets the next round's Gat percentage.
     */
    function setGatPercentage(FixedPoint.Unsigned memory newGatPercentage) public virtual;

    /**
     * @notice Resets the rewards expiration timeout.
     * @dev This change only applies to rounds that have not yet begun.
     * @param NewRewardsExpirationTimeout how long a caller can wait before choosing to withdraw their rewards.
     */
    function setRewardsExpirationTimeout(uint256 NewRewardsExpirationTimeout) public virtual;
}

// TODO: add staking/snapshot interfaces to this interface file.

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

/**
 * @title Interface that voters must use to Vote on price request resolutions.
 */
abstract contract VotingV2Interface {
    struct PendingRequest {
        bytes32 identifier;
        uint256 time;
    }

    struct PendingRequestAncillary {
        bytes32 identifier;
        uint256 time;
        bytes ancillaryData;
    }

    struct PendingRequestAncillaryAugmented {
        uint32 lastVotingRound;
        bool isGovernance;
        uint64 time;
        uint32 rollCount;
        bytes32 identifier;
        bytes ancillaryData;
    }

    // Captures the necessary data for making a commitment.
    // Used as a parameter when making batch commitments.
    // Not used as a data structure for storage.
    struct Commitment {
        bytes32 identifier;
        uint256 time;
        bytes32 hash;
        bytes encryptedVote;
    }

    // Captures the necessary data for revealing a vote.
    // Used as a parameter when making batch reveals.
    // Not used as a data structure for storage.
    struct Reveal {
        bytes32 identifier;
        uint256 time;
        int256 price;
        int256 salt;
    }

    // Captures the necessary data for making a commitment.
    // Used as a parameter when making batch commitments.
    // Not used as a data structure for storage.
    struct CommitmentAncillary {
        bytes32 identifier;
        uint256 time;
        bytes ancillaryData;
        bytes32 hash;
        bytes encryptedVote;
    }

    // Captures the necessary data for revealing a vote.
    // Used as a parameter when making batch reveals.
    // Not used as a data structure for storage.
    struct RevealAncillary {
        bytes32 identifier;
        uint256 time;
        int256 price;
        bytes ancillaryData;
        int256 salt;
    }

    // Note: the phases must be in order. Meaning the first enum value must be the first phase, etc.
    // `NUM_PHASES` is to get the number of phases. It isn't an actual phase, and it should always be last.
    enum Phase { Commit, Reveal, NUM_PHASES }

    /**
     * @notice Commit a vote for a price request for `identifier` at `time`.
     * @dev `identifier`, `time` must correspond to a price request that's currently in the commit phase.
     * Commits can be changed.
     * @dev Since transaction data is public, the salt will be revealed with the vote. While this is the system’s expected behavior,
     * voters should never reuse salts. If someone else is able to guess the voted price and knows that a salt will be reused, then
     * they can determine the vote pre-reveal.
     * @param identifier uniquely identifies the committed vote. EG BTC/USD price pair.
     * @param time unix timestamp of the price being voted on.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param hash keccak256 hash of the `price`, `salt`, voter `address`, `time`, current `roundId`, and `identifier`.
     */
    function commitVote(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        bytes32 hash
    ) public virtual;

    /**
     * @notice commits a vote and logs an event with a data blob, typically an encrypted version of the vote
     * @dev An encrypted version of the vote is emitted in an event `EncryptedVote` to allow off-chain infrastructure to
     * retrieve the commit. The contents of `encryptedVote` are never used on chain: it is purely for convenience.
     * @param identifier unique price pair identifier. Eg: BTC/USD price pair.
     * @param time unix timestamp of for the price request.
     * @param ancillaryData  arbitrary data appended to a price request to give the voters more info from the caller.
     * @param hash keccak256 hash of the price you want to vote for and a `int256 salt`.
     * @param encryptedVote offchain encrypted blob containing the voters amount, time and salt.
     */
    function commitAndEmitEncryptedVote(
        bytes32 identifier,
        uint256 time,
        bytes memory ancillaryData,
        bytes32 hash,
        bytes memory encryptedVote
    ) external virtual;

    /**
     * @notice Reveal a previously committed vote for `identifier` at `time`.
     * @dev The revealed `price`, `salt`, `address`, `time`, `roundId`, and `identifier`, must hash to the latest `hash`
     * that `commitVote()` was called with. Only the committer can reveal their vote.
     * @param identifier voted on in the commit phase. EG BTC/USD price pair.
     * @param time specifies the unix timestamp of the price is being voted on.
     * @param price voted on during the commit phase.
     * @param ancillaryData arbitrary data appended to a price request to give the voters more info from the caller.
     * @param salt value used to hide the commitment price during the commit phase.
     */
    function revealVote(
        bytes32 identifier,
        uint256 time,
        int256 price,
        bytes memory ancillaryData,
        int256 salt
    ) public virtual;

    /**
     * @notice Gets the requests that are being voted on this round.
     * @return pendingRequests array containing identifiers of type PendingRequestAncillaryAugmented.
     */
    function getPendingRequests() external virtual returns (PendingRequestAncillaryAugmented[] memory);

    /**
     * @notice Returns the current voting phase, as a function of the current time.
     * @return Phase to indicate the current phase. Either { Commit, Reveal, NUM_PHASES }.
     */
    function getVotePhase() external view virtual returns (Phase);

    /**
     * @notice Returns the current round ID, as a function of the current time.
     * @return uint256 representing the unique round ID.
     */
    function getCurrentRoundId() external view virtual returns (uint32);

    // Voting Owner functions.

    /**
     * @notice Disables this Voting contract in favor of the migrated one.
     * @dev Can only be called by the contract owner.
     * @param newVotingAddress the newly migrated contract address.
     */
    function setMigrated(address newVotingAddress) external virtual;

    /**
     * @notice Sets the maximum number of rounds to roll a request can have before the DVM auto deletes it.
     * @dev Can only be called by the contract owner.
     * @param newMaxRolls the new number of rounds to roll a request before the DVM auto deletes it.
     */
    function setMaxRolls(uint32 newMaxRolls) external virtual;

    /**
     * @notice Sets the maximum number of requests that can be made in a single round. Used to bound the maximum
     * sequential slashing that can be applied within a single round.
     * @dev Can only be called by the contract owner.
     * @param newMaxRequestsPerRound the new maximum number of requests that can be made in a single round.
     */
    function setMaxRequestPerRound(uint32 newMaxRequestsPerRound) external virtual;

    /**
     * @notice Resets the GAT number and SPAT percentage. The GAT is the minimum number of tokens that must participate
     * in a vote for it to resolve (quorum number). The SPAT is is the minimum percentage of tokens that must agree
     * in a vote for it to resolve (percentage of staked tokens) Note: this change only applies to rounds that
     * have not yet begun.
     * @param newGat sets the next round's GAT and going forward.
     * @param newSpat sets the next round's SPAT and going forward.
     */
    function setGatAndSpat(uint128 newGat, uint64 newSpat) external virtual;

    /**
     * @notice Changes the slashing library used by this contract.
     * @param _newSlashingLibrary new slashing library address.
     */
    function setSlashingLibrary(address _newSlashingLibrary) external virtual;
}