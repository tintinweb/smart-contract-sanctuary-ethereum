// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal INITIAL_CHAIN_ID;

    bytes32 internal INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { ERC20 } from "src/base/ERC20.sol";
import { SafeTransferLib } from "src/base/SafeTransferLib.sol";
import { Math } from "src/utils/Math.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using Math for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        beforeDeposit(assets, shares, receiver);

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares, receiver);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        beforeDeposit(assets, shares, receiver);

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares, receiver);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares, receiver, owner);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);

        afterWithdraw(assets, shares, receiver, owner);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares, receiver, owner);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);

        afterWithdraw(assets, shares, receiver, owner);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeDeposit(
        uint256 assets,
        uint256 shares,
        address receiver
    ) internal virtual {}

    function afterDeposit(
        uint256 assets,
        uint256 shares,
        address receiver
    ) internal virtual {}

    function beforeWithdraw(
        uint256 assets,
        uint256 shares,
        address receiver,
        address owner
    ) internal virtual {}

    function afterWithdraw(
        uint256 assets,
        uint256 shares,
        address receiver,
        address owner
    ) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { ERC20 } from "src/base/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { ERC20, SafeTransferLib } from "src/base/ERC4626.sol";
import { Math } from "src/utils/Math.sol";

/**
 * @title Cellar Vesting Timelock
 * @author Kevin Kennis
 * @notice A contract set as a position in a Sommelier cellar, with an adapter,
 *         that linearly releases deposited tokens in order to smooth
 *         out sudden TVL increases.
 */
contract VestingSimple {
    using SafeTransferLib for ERC20;
    using EnumerableSet for EnumerableSet.UintSet;
    using Math for uint256;

    /// @notice Emitted when tokens are deposited for vesting.
    ///
    /// @param user The user making the deposit.
    /// @param receiver The user receiving the shares.
    /// @param amount The amount of tokens deposited.
    event VestingDeposit(address indexed user, address indexed receiver, uint256 amount);

    /// @notice Emitted when vested tokens are withdrawn.
    ///
    /// @param user The owner of the deposit.
    /// @param receiver The user receiving the deposit.
    /// @param depositId The ID of the deposit specified.
    /// @param amount The amount of tokens deposited.
    event VestingWithdraw(address indexed user, address indexed receiver, uint256 depositId, uint256 amount);

    // ============================================= ERRORS =============================================

    /// @notice Contract was deployed with no asset.
    error Vesting_ZeroAsset();

    /// @notice Contract was deployed with no vesting period.
    error Vesting_ZeroVestingPeriod();

    /// @notice Contract was deployed with a minimum deposit lower
    ///         then the vesting period.
    ///
    /// @param lowestMinimum The lowest minimum deposit possible,
    ///                      based on the vesting period.
    error Vesting_MinimumTooSmall(uint256 lowestMinimum);

    /// @notice User attempted to deposit 0 tokens.
    error Vesting_ZeroDeposit();

    /// @notice User attempted to deposit an amount of tokens
    ///         under the minimum.
    ///
    /// @param minimumDeposit The minimum deposit amount.
    error Vesting_DepositTooSmall(uint256 minimumDeposit);

    /// @notice User attempted to withdraw 0 tokens.
    error Vesting_ZeroWithdraw();

    /// @notice User attempted to withdraw from a fully-vested deposit.
    ///
    /// @param depositId The deposit ID specified.
    error Vesting_DepositFullyVested(uint256 depositId);

    /// @notice User attempted to withdraw more than the amount vested,
    ///         from any deposit.
    ///
    /// @param available The amount of token available for withdrawal.
    error Vesting_NotEnoughAvailable(uint256 available);

    /// @notice User attempted to withdraw more than the amount vested.
    ///
    /// @param depositId The deposit ID specified.
    /// @param available The amount of token available for withdrawal.
    error Vesting_DepositNotEnoughAvailable(uint256 depositId, uint256 available);

    /// @notice User specified a deposit that does not exist.
    ///
    /// @param depositId The deposit ID specified.
    error Vesting_NoDeposit(uint256 depositId);

    // ============================================= TYPES =============================================

    /// @notice Contains all information needed to vest
    ///         tokens for each deposited.
    struct VestingSchedule {
        uint256 amountPerSecond; // The amount of tokens vested per second.
        uint128 until; // The time vesting will finish.
        uint128 lastClaimed; // The last time vesting accrued.
        uint256 vested; // The amount of vested tokens still not withdrawn.
    }

    // ============================================= STATE =============================================

    /// @notice Used for retaining maximum precision in amountPerSecond.
    uint256 internal constant ONE = 1e18;

    /// @notice The deposit token for the vesting contract.
    ERC20 public immutable asset;
    /// @notice The vesting period for the contract, in seconds.
    uint256 public immutable vestingPeriod;
    /// @notice Used to preclude rounding errors. Should be equal to 0.0001 tokens of asset.
    uint256 public immutable minimumDeposit;

    /// @notice All vesting schedules for a user
    mapping(address => mapping(uint256 => VestingSchedule)) public vests;
    /// @notice Enumeration of user deposit ID
    mapping(address => EnumerableSet.UintSet) private allUserDepositIds;
    /// @notice The current user's last deposited vest
    mapping(address => uint256) public currentId;

    /// @notice The total amount of deposits to the contract.
    uint256 public totalDeposits;
    /// @notice The total amount of deposits to the contract that haven't vested
    ///         through withdrawals. Note that based on point-of-time calculations,
    ///         some of these tokens may be available for withdrawal.
    uint256 public unvestedDeposits;

    // ========================================== CONSTRUCTOR ==========================================

    /**
     * @notice Instantiate the contract with a vesting period.
     *
     * @param _asset                        The token the vesting contract will hold.
     * @param _vestingPeriod                The length of time, in seconds, that tokens should vest over.
     * @param _minimumDeposit               The minimum amount of tokens that can be deposited for vesting.
     */
    constructor(
        ERC20 _asset,
        uint256 _vestingPeriod,
        uint256 _minimumDeposit
    ) {
        if (address(_asset) == address(0)) revert Vesting_ZeroDeposit();
        if (_vestingPeriod == 0) revert Vesting_ZeroVestingPeriod();
        if (_minimumDeposit < _vestingPeriod) revert Vesting_MinimumTooSmall(_vestingPeriod);

        asset = _asset;
        vestingPeriod = _vestingPeriod;
        minimumDeposit = _minimumDeposit;
    }

    // ====================================== DEPOSIT/WITHDRAWAL =======================================

    /**
     * @notice Deposit tokens to vest, which will instantly
     *         start emitting linearly over the defined lock period. Each deposit
     *         tracked separately such that new deposits don't reset the vesting
     *         clocks of the old deposits.
     *
     * @param assets                        The amount of tokens to deposit.
     * @param receiver                      The account credited for the deposit.
     *
     * @return shares                       The amount of tokens deposited (for compatibility).
     */
    function deposit(uint256 assets, address receiver) public returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        if (assets == 0) revert Vesting_ZeroDeposit();
        if (assets < minimumDeposit) revert Vesting_DepositTooSmall(minimumDeposit);

        // Used for compatibility
        shares = assets;

        // Add deposit info
        uint256 newDepositId = ++currentId[receiver];
        allUserDepositIds[receiver].add(newDepositId);
        VestingSchedule storage s = vests[receiver][newDepositId];

        s.amountPerSecond = assets.mulDivDown(ONE, vestingPeriod);
        s.until = uint128(block.timestamp + vestingPeriod);
        s.lastClaimed = uint128(block.timestamp);

        // Update global accounting
        totalDeposits += assets;
        unvestedDeposits += assets;

        // Collect tokens
        ERC20(asset).safeTransferFrom(msg.sender, address(this), assets);

        emit VestingDeposit(msg.sender, receiver, assets);
    }

    /**
     * @notice Withdraw vesting tokens, winding the vesting clock
     *         and releasing newly earned tokens since the last claim.
     *         Reverts if there are not enough assets available.
     *
     * @param depositId                     The deposit ID to withdraw from.
     * @param assets                        The amount of assets to withdraw.
     *
     * @return shares                       The amount of tokens withdrawn (for compatibility).
     */
    function withdraw(uint256 depositId, uint256 assets) public returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        if (assets == 0) revert Vesting_ZeroWithdraw();

        // Used for compatibility
        shares = assets;

        VestingSchedule storage s = vests[msg.sender][depositId];
        uint256 newlyVested = _vestDeposit(msg.sender, depositId);

        if (newlyVested == 0 && s.vested == 0) revert Vesting_DepositFullyVested(depositId);
        if (assets > s.vested) revert Vesting_DepositNotEnoughAvailable(depositId, s.vested);

        // Update accounting
        s.vested -= assets;
        totalDeposits -= assets;

        // Remove deposit if needed, including 1-wei deposits (rounding)
        if (s.vested <= 1 && block.timestamp >= s.until) {
            allUserDepositIds[msg.sender].remove(depositId);
        }

        emit VestingWithdraw(msg.sender, msg.sender, depositId, assets);

        asset.safeTransfer(msg.sender, assets);
    }

    /**
     * @notice Withdraw all tokens across all deposits that have vested.
     *         Winds the vesting clock to release newly earned tokens since the last claim.
     *
     * @return shares                       The amount of tokens withdrawn (for compatibility).
     */
    function withdrawAll() public returns (uint256 shares) {
        uint256[] memory depositIds = allUserDepositIds[msg.sender].values();
        uint256 numDeposits = depositIds.length;

        for (uint256 i = 0; i < numDeposits; i++) {
            VestingSchedule storage s = vests[msg.sender][depositIds[i]];

            if (s.amountPerSecond > 0 && (s.vested > 0 || s.lastClaimed < s.until)) {
                _vestDeposit(msg.sender, depositIds[i]);

                uint256 vested = s.vested;
                shares += vested;
                s.vested = 0;

                // Remove deposit if needed
                // Will not affect loop logic because values are pre-defined
                if (s.vested == 0 && block.timestamp >= s.until) {
                    allUserDepositIds[msg.sender].remove(depositIds[i]);
                }

                emit VestingWithdraw(msg.sender, msg.sender, depositIds[i], vested);
            }
        }

        totalDeposits -= shares;
        asset.safeTransfer(msg.sender, shares);
    }

    /**
     * @notice Withdraw a specified amount of tokens, sending them to the specified
     *         receiver. Withdraws from all deposits in order until the current amount
     *         is met.
     *
     * @param assets                        The amount of assets to withdraw.
     * @param receiver                      The address that will receive the assets.
     *
     * @return shares                       The amount of tokens withdrawn (for compatibility).
     */
    function withdrawAnyFor(uint256 assets, address receiver) public returns (uint256 shares) {
        uint256[] memory depositIds = allUserDepositIds[msg.sender].values();
        uint256 numDeposits = depositIds.length;

        shares = assets;

        for (uint256 i = 0; assets > 0 && i < numDeposits; i++) {
            VestingSchedule storage s = vests[msg.sender][depositIds[i]];

            if (s.amountPerSecond > 0 && (s.vested > 0 || s.lastClaimed < s.until)) {
                _vestDeposit(msg.sender, depositIds[i]);

                uint256 payout = s.vested >= assets ? assets : s.vested;

                if (payout == assets) {
                    // Can end here - only withdraw the amount we need
                    s.vested -= payout;
                    assets = 0;
                } else {
                    // Withdraw full deposit and go to next one
                    assets -= payout;
                    s.vested = 0;
                }

                emit VestingWithdraw(msg.sender, receiver, depositIds[i], payout);

                // Remove deposit if needed
                // Will not affect loop logic because values are pre-defined
                if (s.vested == 0 && block.timestamp >= s.until) {
                    allUserDepositIds[msg.sender].remove(depositIds[i]);
                }
            }
        }

        // Could not collect enough
        if (assets > 0) revert Vesting_NotEnoughAvailable(shares - assets);

        totalDeposits -= shares;
        asset.safeTransfer(receiver, shares);
    }

    // ======================================= VIEW FUNCTIONS =========================================

    /**
     * @notice Reports all tokens which are vested and can be withdrawn for a user.
     *
     * @param user                          The user whose balance should be reported.
     *
     * @return balance                      The user's vested total balance.
     */
    function vestedBalanceOf(address user) public view returns (uint256 balance) {
        uint256[] memory depositIds = allUserDepositIds[user].values();
        uint256 numDeposits = depositIds.length;

        for (uint256 i = 0; i < numDeposits; i++) {
            VestingSchedule storage s = vests[user][depositIds[i]];

            if (s.amountPerSecond > 0 && (s.vested > 0 || s.lastClaimed < s.until)) {
                uint256 lastTimestamp = block.timestamp <= s.until ? block.timestamp : s.until;
                uint256 timeElapsed = lastTimestamp - s.lastClaimed;
                uint256 newlyVested = timeElapsed.mulDivDown(s.amountPerSecond, ONE);

                balance += (s.vested + newlyVested);
            }
        }
    }

    /**
     * @notice Reports all tokens which are vested and can be withdrawn for a user.
     *
     * @param user                          The user whose balance should be reported.
     * @param depositId                     The depositId to report.
     *
     * @return balance                      The user's vested balance for the specified deposit.
     */
    function vestedBalanceOfDeposit(address user, uint256 depositId) public view returns (uint256) {
        VestingSchedule storage s = vests[user][depositId];

        if (s.amountPerSecond == 0) revert Vesting_NoDeposit(depositId);

        uint256 lastTimestamp = block.timestamp <= s.until ? block.timestamp : s.until;
        uint256 timeElapsed = lastTimestamp - s.lastClaimed;
        uint256 newlyVested = timeElapsed.mulDivDown(s.amountPerSecond, ONE);

        return s.vested + newlyVested;
    }

    /**
     * @notice Reports all tokens deposited by a user which have not been withdrawn yet.
     *         Includes unvested tokens.
     *
     * @param user                          The user whose balance should be reported.
     *
     * @return balance                      The user's total balance, both vested and unvested.
     */
    function totalBalanceOf(address user) public view returns (uint256 balance) {
        uint256[] memory depositIds = allUserDepositIds[user].values();
        uint256 numDeposits = depositIds.length;

        for (uint256 i = 0; i < numDeposits; i++) {
            VestingSchedule storage s = vests[user][depositIds[i]];

            if (s.amountPerSecond > 0 && (s.vested > 0 || s.lastClaimed < s.until)) {
                uint256 startTime = s.until - vestingPeriod;
                uint256 timeElapsedBeforeClaim = s.lastClaimed - startTime;

                uint256 totalAmount = (s.amountPerSecond * vestingPeriod) / ONE;
                uint256 previouslyVested = timeElapsedBeforeClaim.mulDivDown(s.amountPerSecond, ONE);
                uint256 claimed = previouslyVested - s.vested;

                balance += (totalAmount - claimed);
            }
        }
    }

    /**
     * @notice Returns all deposit IDs in an array. Only contains active deposits.
     *
     * @param user                          The user whose IDs should be reported.
     *
     * @return ids                          An array of the user's active deposit IDs.
     */
    function userDepositIds(address user) public view returns (uint256[] memory) {
        return allUserDepositIds[user].values();
    }

    /**
     * @notice Returns the vesting info for a given sdeposit.
     *
     * @param user                          The user whose vesting info should be reported.
     * @param depositId                     The deposit to report.
     *
     * @return amountPerSecond              The amount of tokens released per second.
     * @return until                        The timestamp at which all coins will be released.
     * @return lastClaimed                  The last time vesting occurred.
     * @return amountPerSecond              The amount of tokens released per second.
     */
    function userVestingInfo(address user, uint256 depositId)
        public
        view
        returns (
            uint256,
            uint128,
            uint128,
            uint256
        )
    {
        VestingSchedule memory s = vests[user][depositId];

        return (s.amountPerSecond, s.until, s.lastClaimed, s.vested);
    }

    // ===================================== INTERNAL FUNCTIONS =======================================

    /**
     * @dev Wind the vesting clock for a given deposit, based on how many seconds have
     *      elapsed in the vesting schedule since the last claim.
     *
     * @param user                          The user whose deposit will be vested.
     * @param depositId                     The deposit ID to vest for.
     *
     * @return newlyVested                  The newly vested tokens since the last vest.
     */
    function _vestDeposit(address user, uint256 depositId) internal returns (uint256 newlyVested) {
        // Add deposit info
        VestingSchedule storage s = vests[user][depositId];

        if (s.amountPerSecond == 0) revert Vesting_NoDeposit(depositId);

        // No new vesting
        if (s.lastClaimed >= s.until) return 0;

        uint256 lastTimestamp = block.timestamp <= s.until ? block.timestamp : s.until;
        uint256 timeElapsed = lastTimestamp - s.lastClaimed;

        // In case there were rounding errors due to accrual times,
        // round up on the last vest to collect anything lost.
        if (lastTimestamp == s.until) {
            newlyVested = timeElapsed.mulDivUp(s.amountPerSecond, ONE);
        } else {
            newlyVested = timeElapsed.mulDivDown(s.amountPerSecond, ONE);
        }

        s.vested += newlyVested;
        s.lastClaimed = uint128(lastTimestamp);

        unvestedDeposits -= newlyVested;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

library Math {
    /**
     * @notice Substract with a floor of 0 for the result.
     */
    function subMinZero(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x - y : 0;
    }

    /**
     * @notice Used to change the decimals of precision used for an amount.
     */
    function changeDecimals(
        uint256 amount,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256) {
        if (fromDecimals == toDecimals) {
            return amount;
        } else if (fromDecimals < toDecimals) {
            return amount * 10**(toDecimals - fromDecimals);
        } else {
            return amount / 10**(fromDecimals - toDecimals);
        }
    }

    // ===================================== OPENZEPPELIN'S MATH =====================================

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // ================================= SOLMATE's FIXEDPOINTMATHLIB =================================

    uint256 public constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }
}