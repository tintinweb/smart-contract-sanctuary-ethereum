// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "./../utils/Governable.sol";
import "./../interfaces/payment/ISCP.sol";

/**
 * @title Solace Cover Points (SCP)
 * @author solace.fi
 * @notice **SCP** is a stablecoin pegged to **USD**. It is used to pay for coverage.
 *
 * **SCP** conforms to the ERC20 standard but cannot be minted or transferred by most users. Balances can only be modified by "SCP movers" such as SCP Tellers and coverage contracts. In some cases the user may be able to exchange **SCP** for the payment token, if not the balance will be marked non refundable. Some coverage contracts may have a minimum balance required to prevent abuse - these are called "SCP retainers" and may block [`withdraw()`](#withdraw).
 *
 * [**Governance**](/docs/protocol/governance) can add and remove SCP movers and retainers. SCP movers can modify token balances via [`mint()`](#mint), [`burn()`](#burn), [`transfer()`](#transfer), [`transferFrom()`](#transferfrom), and [`withdraw()`](#withdraw).
 */
contract SCP is ISCP, Multicall, Governable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /***************************************
    ERC20 DATA
    ***************************************/

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _balancesNonRefundable;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /***************************************
    MOVER AND RETAINER DATA
    ***************************************/

    EnumerableSet.AddressSet private _scpMovers;
    EnumerableSet.AddressSet private _scpRetainers;

    /***************************************
    CONSTRUCTOR
    ***************************************/

    /**
     * @notice Constructs the Solace Cover Points contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     */
    constructor(address governance_) Governable(governance_) {
        _name = "scp";
        _symbol = "SCP";
    }

    /***************************************
    ERC20 FUNCTIONS
    ***************************************/

    /// @notice The name of the token.
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @notice The symbol of the token.
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @notice The number of decimals in the numeric representation.
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /// @notice The amount of tokens in existence.
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /// @notice The amount of tokens owned by `account`.
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /// @notice Overwritten. Returns zero.
    function allowance(address, address) public view virtual override returns (uint256) {
        return 0;
    }

    /// @notice Overwritten. Reverts when called.
    function approve(address, uint256) public virtual override returns (bool) {
        revert("SCP: token not approvable");
    }

    /**
     * @notice Moves `amount` tokens from the caller's account to `recipient`.
     * Can only be called by a scp mover.
     * Requirements:
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @notice Moves `amount` tokens from `sender` to `recipient`.
     * Can only be called by a scp mover.
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @notice Moves `amount` of tokens from `sender` to `recipient`.
     * Requirements:
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(isScpMover(msg.sender), "!scp mover");
        require(sender != address(0), "SCP: transfer from the zero address");
        require(recipient != address(0), "SCP: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "SCP: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        // transfer nonrefundable amount first
        uint256 bnr1 = _balancesNonRefundable[sender];
        uint256 bnr2 = _subOrZero(bnr1, amount);
        if(bnr2 != bnr1) {
            _balancesNonRefundable[sender] = bnr2;
            _balancesNonRefundable[recipient] += (bnr1 - bnr2);
        }
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @notice Creates `amount` tokens and assigns them to `account`, increasing the total supply.
     * Requirements:
     * - `account` cannot be the zero address.
     */
    function mint(address account, uint256 amount, bool isRefundable) external override {
        require(isScpMover(msg.sender), "!scp mover");
        require(account != address(0), "SCP: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        if(!isRefundable) _balancesNonRefundable[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice Destroys `amounts` tokens from `accounts`, reducing the total supply.
     * Requirements:
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burnMultiple(address[] calldata accounts, uint256[] calldata amounts) external override {
        require(isScpMover(msg.sender), "!scp mover");
        uint256 length = accounts.length;
        require(length == amounts.length, "length mismatch");

        for (uint256 i = 0; i < length; i++) {
            _burn(accounts[i], amounts[i]);
        }
    }

    /**
     * @notice Destroys `amount` tokens from `account`, reducing the total supply.
     * Requirements:
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burn(address account, uint256 amount) external override {
        // checks
        require(isScpMover(msg.sender), "!scp mover");
        _burn(account, amount);
    }

    /**
     * @notice Withdraws funds from an account.
     * @dev Same as burn() except uses refundable amount and checks min scp required.
     * The user must have sufficient refundable balance.
     * @param account The account to withdraw from.
     * @param amount The amount to withdraw.
     */
    function withdraw(address account, uint256 amount) external override {
        // checks
        require(isScpMover(msg.sender), "!scp mover");
        require(account != address(0), "SCP: withdraw from the zero address");
        uint256 bal = _balances[account]; // total
        uint256 bnr = _balancesNonRefundable[account]; // nonrefundable
        uint256 br = _subOrZero(bal, bnr); // refundable
        require(br >= amount, "SCP: withdraw amount exceeds balance");
        uint256 minScp = minScpRequired(account);
        uint256 newBal = bal - amount;
        require(newBal >= minScp, "SCP: withdraw to below min");
        // effects
        _totalSupply -= amount;
        _balances[account] = newBal;
        emit Transfer(account, address(0), amount);
    }

    /***************************************
    MOVER AND RETAINER FUNCTIONS
    ***************************************/

    /// @notice Returns true if `account` has permissions to move balances.
    function isScpMover(address account) public view override returns (bool status) {
        return _scpMovers.contains(account);
    }

    /// @notice Returns the number of scp movers.
    function scpMoverLength() external view override returns (uint256 length) {
        return _scpMovers.length();
    }

    /// @notice Returns the scp mover at `index`.
    function scpMoverList(uint256 index) external view override returns (address scpMover) {
        return _scpMovers.at(index);
    }

    /// @notice Returns true if `account` may need to retain scp on behalf of a user.
    function isScpRetainer(address account) public view override returns (bool status) {
        return _scpRetainers.contains(account);
    }

    /// @notice Returns the number of scp retainers.
    function scpRetainerLength() external view override returns (uint256 length) {
        return _scpRetainers.length();
    }

    /// @notice Returns the scp retainer at `index`.
    function scpRetainerList(uint256 index) external view override returns (address scpRetainer) {
        return _scpRetainers.at(index);
    }

    /// @notice The amount of tokens owned by account that cannot be withdrawn.
    function balanceOfNonRefundable(address account) public view virtual override returns (uint256) {
        return _balancesNonRefundable[account];
    }

    /**
     * @notice Calculates the minimum amount of Solace Cover Points required by this contract for the account to hold.
     * @param account Account to query.
     * @return amount The amount of SCP the account must hold.
     */
    function minScpRequired(address account) public view override returns (uint256 amount) {
        amount = 0;
        uint256 len = _scpRetainers.length();
        for(uint256 i = 0; i < len; i++) {
            amount += ISCPRetainer(_scpRetainers.at(i)).minScpRequired(account);
        }
        return amount;
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds or removes a set of scp movers.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param scpMovers List of scp movers to set.
     * @param statuses Statuses to set.
     */
    function setScpMoverStatuses(address[] calldata scpMovers, bool[] calldata statuses) external override onlyGovernance {
        uint256 len = scpMovers.length;
        require(statuses.length == len, "length mismatch");
        for(uint256 i = 0; i < len; i++) {
            if(statuses[i]) _scpMovers.add(scpMovers[i]);
            else _scpMovers.remove(scpMovers[i]);
            emit ScpMoverStatusSet(scpMovers[i], statuses[i]);
        }
    }

    /**
     * @notice Adds or removes a set of scp retainers.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param scpRetainers List of scp retainers to set.
     * @param statuses Statuses to set.
     */
    function setScpRetainerStatuses(address[] calldata scpRetainers, bool[] calldata statuses) external override onlyGovernance {
        uint256 len = scpRetainers.length;
        require(statuses.length == len, "length mismatch");
        for(uint256 i = 0; i < len; i++) {
            if(statuses[i]) _scpRetainers.add(scpRetainers[i]);
            else _scpRetainers.remove(scpRetainers[i]);
            emit ScpRetainerStatusSet(scpRetainers[i], statuses[i]);
        }
    }

    /***************************************
    HELPER FUNCTIONS
    ***************************************/

    /**
     * @notice Destroys `amount` tokens from `account`, reducing the total supply.
     * Requirements:
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) private {
        require(account != address(0), "SCP: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "SCP: burn amount exceeds balance");
        // effects
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        // burn nonrefundable amount first
        uint256 bnr1 = _balancesNonRefundable[account];
        uint256 bnr2 = _subOrZero(bnr1, amount);
        if(bnr2 != bnr1) _balancesNonRefundable[account] = bnr2;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @notice Safely performs `c = a - b`.
     * If negative overflow returns 0.
     * @param a First operand.
     * @param b Second operand.
     * @param c Result.
     */
    function _subOrZero(uint256 a, uint256 b) internal pure returns (uint256 c) {
        return (a >= b)
            ? (a - b)
            : 0;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./../interfaces/utils/IGovernable.sol";

/**
 * @title Governable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
   * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setpendinggovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./../interfaces/utils/ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
contract Governable is IGovernable {

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    // Governor.
    address private _governance;

    // governance to take over.
    address private _pendingGovernance;

    bool private _locked;

    /**
     * @notice Constructs the governable contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     */
    constructor(address governance_) {
        require(governance_ != address(0x0), "zero address governance");
        _governance = governance_;
        _pendingGovernance = address(0x0);
        _locked = false;
    }

    /***************************************
    MODIFIERS
    ***************************************/

    // can only be called by governor
    // can only be called while unlocked
    modifier onlyGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _governance, "!governance");
        _;
    }

    // can only be called by pending governor
    // can only be called while unlocked
    modifier onlyPendingGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _pendingGovernance, "!pending governance");
        _;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() public view override returns (address) {
        return _governance;
    }

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view override returns (address) {
        return _pendingGovernance;
    }

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view override returns (bool) {
        return _locked;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external override onlyGovernance {
        _pendingGovernance = pendingGovernance_;
        emit GovernancePending(pendingGovernance_);
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the pending governor.
     */
    function acceptGovernance() external override onlyPendingGovernance {
        // sanity check against transferring governance to the zero address
        // if someone figures out how to sign transactions from the zero address
        // consider the entirety of ethereum to be rekt
        require(_pendingGovernance != address(0x0), "zero governance");
        address oldGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0x0);
        emit GovernanceTransferred(oldGovernance, _governance);
    }

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external override onlyGovernance {
        _locked = true;
        // intentionally not using address(0x0), see re-initialization exploit
        _governance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        _pendingGovernance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        emit GovernanceTransferred(msg.sender, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
        emit GovernanceLocked();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./ISCPRetainer.sol";
import "./../utils/IGovernable.sol";

/**
 * @title Solace Cover Points (SCP)
 * @author solace.fi
 * @notice **SCP** is a stablecoin pegged to **USD**. It is used to pay for coverage.
 *
 * **SCP** conforms to the ERC20 standard but cannot be minted or transferred by most users. Balances can only be modified by "SCP movers" such as SCP Tellers and coverage contracts. In some cases the user may be able to exchange **SCP** for the payment token, if not the balance will be marked non refundable. Some coverage contracts may have a minimum balance required to prevent abuse - these are called "SCP retainers" and may block [`withdraw()`](#withdraw).
 *
 * [**Governance**](/docs/protocol/governance) can add and remove SCP movers and retainers. SCP movers can modify token balances via [`mint()`](#mint), [`burn()`](#burn), [`transfer()`](#transfer), [`transferFrom()`](#transferfrom), and [`withdraw()`](#withdraw).
 */
interface ISCP is IERC20, IERC20Metadata, ISCPRetainer, IGovernable {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when the status of an SCP mover is set.
    event ScpMoverStatusSet(address indexed scpMover, bool status);
    /// @notice Emitted when the status of an SCP retainer is set.
    event ScpRetainerStatusSet(address indexed scpRetainer, bool status);

    /***************************************
    ERC20 FUNCTIONS
    ***************************************/

    /**
     * @notice Creates `amount` tokens and assigns them to `account`, increasing the total supply.
     * Requirements:
     * - `account` cannot be the zero address.
     */
    function mint(address account, uint256 amount, bool isRefundable) external;

    /**
     * @notice Destroys `amounts` tokens from `accounts`, reducing the total supply.
     * Requirements:
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burnMultiple(address[] calldata accounts, uint256[] calldata amounts) external;

    /**
     * @notice Destroys `amount` tokens from `account`, reducing the total supply.
     * Requirements:
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function burn(address account, uint256 amount) external;

    /**
     * @notice Withdraws funds from an account.
     * @dev Same as burn() except uses refundable amount and checks min scp required.
     * The user must have sufficient refundable balance.
     * @param account The account to withdraw from.
     * @param amount The amount to withdraw.
     */
    function withdraw(address account, uint256 amount) external;

    /***************************************
    MOVER AND RETAINER FUNCTIONS
    ***************************************/

    /// @notice Returns true if `account` has permissions to move balances.
    function isScpMover(address account) external view returns (bool status);
    /// @notice Returns the number of scp movers.
    function scpMoverLength() external view returns (uint256 length);
    /// @notice Returns the scp mover at `index`.
    function scpMoverList(uint256 index) external view returns (address scpMover);

    /// @notice Returns true if `account` may need to retain scp on behalf of a user.
    function isScpRetainer(address account) external view returns (bool status);
    /// @notice Returns the number of scp retainers.
    function scpRetainerLength() external view returns (uint256 length);
    /// @notice Returns the scp retainer at `index`.
    function scpRetainerList(uint256 index) external view returns (address scpRetainer);

    /// @notice The amount of tokens owned by account that cannot be withdrawn.
    function balanceOfNonRefundable(address account) external view returns (uint256);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds or removes a set of scp movers.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param scpMovers List of scp movers to set.
     * @param statuses Statuses to set.
     */
    function setScpMoverStatuses(address[] calldata scpMovers, bool[] calldata statuses) external;

    /**
     * @notice Adds or removes a set of scp retainers.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param scpRetainers List of scp retainers to set.
     * @param statuses Statuses to set.
     */
    function setScpRetainerStatuses(address[] calldata scpRetainers, bool[] calldata statuses) external;
}

// SPDX-License-Identifier: MIT

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IGovernable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
 * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setpendinggovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
interface IGovernable {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when pending Governance is set.
    event GovernancePending(address pendingGovernance);
    /// @notice Emitted when Governance is set.
    event GovernanceTransferred(address oldGovernance, address newGovernance);
    /// @notice Emitted when Governance is locked.
    event GovernanceLocked();

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() external view returns (address);

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view returns (address);

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view returns (bool);

    /***************************************
    MUTATORS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title Solace Cover Points Retainer
 * @author solace.fi
 * @notice An interface for contracts that require users to maintain a minimum balance of SCP.
 */
interface ISCPRetainer {

    /**
     * @notice Calculates the minimum amount of Solace Cover Points required by this contract for the account to hold.
     * @param account Account to query.
     * @return amount The amount of SCP the account must hold.
     */
    function minScpRequired(address account) external view returns (uint256 amount);
}