// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "./interfaces/external/IKeep3r.sol";

import "./DepositManager.sol";

contract DepositManagerJob is DepositManager {
    /// @notice Address of Keeper Network V2
    address public immutable keep3r;

    constructor(
        address _keep3r,
        address _registry,
        uint16 _maxLossInBP,
        uint32 _depositInterval
    ) DepositManager(_registry, _maxLossInBP, _depositInterval) {
        keep3r = _keep3r;
    }

    /// @inheritdoc IDepositManager
    function updateDeposits() public override {
        require(IKeep3r(keep3r).isKeeper(msg.sender), "DepositManager: !KEEP3R");

        super.updateDeposits();

        IKeep3r(keep3r).worked(msg.sender);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

interface IKeep3r {
    function isKeeper(address _keeper) external returns (bool _isKeeper);

    function worked(address _keeper) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IvToken.sol";
import "./interfaces/IDepositManager.sol";
import "./interfaces/IVaultController.sol";

contract DepositManager is IDepositManager {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Base point number
    uint16 internal constant BP = 10_000;

    /// @notice Role allows configure reserve related data/components
    bytes32 internal immutable RESERVE_MANAGER_ROLE;
    /// @inheritdoc IDepositManager
    address public immutable override registry;

    /// @notice vTokens to deposit for
    EnumerableSet.AddressSet internal vTokens;

    /// @inheritdoc IDepositManager
    uint32 public override depositInterval;

    /// @inheritdoc IDepositManager
    uint16 public override maxLossInBP;

    /// @inheritdoc IDepositManager
    mapping(address => uint96) public override lastDepositTimestamp;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "DepositManager: FORBIDDEN");
        _;
    }

    /// @notice Checks if max loss is within an acceptable range
    modifier isValidMaxLoss(uint16 _maxLossInBP) {
        require(_maxLossInBP <= BP, "DepositManager: MAX_LOSS");
        _;
    }

    constructor(
        address _registry,
        uint16 _maxLossInBP,
        uint32 _depositInterval
    ) isValidMaxLoss(_maxLossInBP) {
        RESERVE_MANAGER_ROLE = keccak256("RESERVE_MANAGER_ROLE");

        registry = _registry;
        maxLossInBP = _maxLossInBP;
        depositInterval = _depositInterval;
    }

    /// @inheritdoc IDepositManager
    function addVToken(address _vToken) external override onlyRole(RESERVE_MANAGER_ROLE) {
        require(vTokens.add(_vToken), "DepositManager: EXISTS");
    }

    /// @inheritdoc IDepositManager
    function removeVToken(address _vToken) external override onlyRole(RESERVE_MANAGER_ROLE) {
        require(vTokens.remove(_vToken), "DepositManager: !FOUND");
    }

    /// @inheritdoc IDepositManager
    function setDepositInterval(uint32 _interval) external override onlyRole(RESERVE_MANAGER_ROLE) {
        require(_interval > 0, "DepositManager: INVALID");
        depositInterval = _interval;
    }

    /// @inheritdoc IDepositManager
    function setMaxLoss(uint16 _maxLossInBP) external isValidMaxLoss(_maxLossInBP) onlyRole(RESERVE_MANAGER_ROLE) {
        maxLossInBP = _maxLossInBP;
    }

    /// @inheritdoc IDepositManager
    function canUpdateDeposits() external view override returns (bool) {
        uint count = vTokens.length();
        for (uint i; i < count; ++i) {
            address vToken = vTokens.at(i);
            if (block.timestamp - lastDepositTimestamp[vToken] >= depositInterval) {
                return true;
            }
        }
        return false;
    }

    /// @inheritdoc IDepositManager
    function containsVToken(address _vToken) external view override returns (bool) {
        return vTokens.contains(_vToken);
    }

    /// @inheritdoc IDepositManager
    function updateDeposits() public virtual override {
        bool deposited;
        uint count = vTokens.length();
        for (uint i; i < count; ++i) {
            IvToken vToken = IvToken(vTokens.at(i));
            if (block.timestamp - lastDepositTimestamp[address(vToken)] >= depositInterval) {
                uint _depositedBefore = vToken.deposited();
                uint _totalBefore = vToken.totalAssetSupply();

                vToken.deposit();

                require(
                    _isValidMaxLoss(_depositedBefore, _totalBefore, vToken.totalAssetSupply()),
                    "DepositManager: MAX_LOSS"
                );

                lastDepositTimestamp[address(vToken)] = uint96(block.timestamp);
                deposited = true;
            }
        }

        require(deposited, "DepositManager: !DEPOSITED");
    }

    function _isValidMaxLoss(
        uint _depositedBefore,
        uint _totalBefore,
        uint _totalAfter
    ) internal view returns (bool) {
        if (_totalAfter < _totalBefore) {
            return _totalBefore - _totalAfter <= (_depositedBefore * maxLossInBP) / BP;
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Vault token interface
/// @notice Contains logic for index's asset management
interface IvToken {
    struct AssetData {
        uint maxShares;
        uint amountInAsset;
    }

    event UpdateDeposit(address indexed account, uint depositedAmount);
    event SetVaultController(address vaultController);
    event VTokenTransfer(address indexed from, address indexed to, uint amount);

    /// @notice Initializes vToken with the given parameters
    /// @param _asset Asset that will be stored
    /// @param _registry Index registry address
    function initialize(address _asset, address _registry) external;

    /// @notice Sets vault controller for the vault
    /// @param _vaultController Vault controller to set
    function setController(address _vaultController) external;

    /// @notice Updates reserve to expected deposit target
    function deposit() external;

    /// @notice Withdraws all deposited amount
    function withdraw() external;

    /// @notice Transfers shares between given accounts
    /// @param _from Account to transfer shares from
    /// @param _to Account to transfer shares to
    /// @param _shares Amount of shares to transfer
    function transferFrom(
        address _from,
        address _to,
        uint _shares
    ) external;

    /// @notice Transfers asset to the given recipient
    /// @dev Method is restricted to orderer
    /// @param _recipient Recipient address
    /// @param _amount Amount to transfer
    function transferAsset(address _recipient, uint _amount) external;

    /// @notice Mints shares for the current sender
    /// @return shares Amount of minted shares
    function mint() external returns (uint shares);

    /// @notice Burns shares for the given recipient and returns assets to the given recipient
    /// @param _recipient Recipient to send assets to
    /// @return amount Amount of sent assets
    function burn(address _recipient) external returns (uint amount);

    /// @notice Transfers shares from the sender to the given recipient
    /// @param _recipient Account to transfer shares to
    /// @param _amount Amount of shares to transfer
    function transfer(address _recipient, uint _amount) external;

    /// @notice Manually synchronizes shares balances
    function sync() external;

    /// @notice Mints shares for the given recipient
    /// @param _recipient Recipient to mint shares for
    /// @return Returns minted shares amount
    function mintFor(address _recipient) external returns (uint);

    /// @notice Burns shares and sends assets to the given recipient
    /// @param _recipient Recipient to send assets to
    /// @return Returns amount of sent assets
    function burnFor(address _recipient) external returns (uint);

    /// @notice Virtual supply amount: current balance + expected to be withdrawn using vault controller
    /// @return Returns virtual supply amount
    function virtualTotalAssetSupply() external view returns (uint);

    /// @notice Total supply amount: current balance + deposited using vault controller
    /// @return Returns total supply amount
    function totalAssetSupply() external view returns (uint);

    /// @notice Amount deposited using vault controller
    /// @return Returns amount deposited using vault controller
    function deposited() external view returns (uint);

    /// @notice Returns mintable amount of shares for given asset's amount
    /// @param _amount Amount of assets to mint shares for
    /// @return Returns amount of shares available for minting
    function mintableShares(uint _amount) external view returns (uint);

    /// @notice Returns amount of assets for the given account with the given shares amount
    /// @return Amount of assets for the given account with the given shares amount
    function assetDataOf(address _account, uint _shares) external view returns (AssetData memory);

    /// @notice Returns amount of assets for the given shares amount
    /// @param _shares Amount of shares
    /// @return Amount of assets
    function assetBalanceForShares(uint _shares) external view returns (uint);

    /// @notice Asset balance of the given address
    /// @param _account Address to check balance of
    /// @return Returns asset balance of the given address
    function assetBalanceOf(address _account) external view returns (uint);

    /// @notice Last asset balance for the given address
    /// @param _account Address to check balance of
    /// @return Returns last asset balance for the given address
    function lastAssetBalanceOf(address _account) external view returns (uint);

    /// @notice Last asset balance
    /// @return Returns last asset balance
    function lastAssetBalance() external view returns (uint);

    /// @notice Total shares supply
    /// @return Returns total shares supply
    function totalSupply() external view returns (uint);

    /// @notice Shares balance of the given address
    /// @param _account Address to check balance of
    /// @return Returns shares balance of the given address
    function balanceOf(address _account) external view returns (uint);

    /// @notice Returns the change in shares for a given amount of an asset
    /// @param _account Account to calculate shares for
    /// @param _amountInAsset Amount of asset to calculate shares
    /// @return newShares New shares value
    /// @return oldShares Old shares value
    function shareChange(address _account, uint _amountInAsset) external view returns (uint newShares, uint oldShares);

    /// @notice Vault controller address
    /// @return Returns vault controller address
    function vaultController() external view returns (address);

    /// @notice Stored asset address
    /// @return Returns stored asset address
    function asset() external view returns (address);

    /// @notice Index registry address
    /// @return Returns index registry address
    function registry() external view returns (address);

    /// @notice Percentage deposited using vault controller
    /// @return Returns percentage deposited using vault controller
    function currentDepositedPercentageInBP() external view returns (uint);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

interface IDepositManager {
    /// @notice Adds vToken to vTokens list
    /// @param _vToken Address of vToken
    function addVToken(address _vToken) external;

    /// @notice Removes vToken from vTokens list
    /// @param _vToken Address of vToken
    function removeVToken(address _vToken) external;

    /// @notice Sets deposit interval
    /// @param _interval deposit interval
    function setDepositInterval(uint32 _interval) external;

    /// @notice Sets maximum loss
    /// @dev Max loss range is [0 - 10_000]
    /// @param _maxLoss Maximum loss allowed
    function setMaxLoss(uint16 _maxLoss) external;

    /// @notice Updates deposits for vTokens
    function updateDeposits() external;

    /// @notice Address of Registry
    /// @return Returns address of Registry
    function registry() external view returns (address);

    /// @notice Maximum loss allowed during depositing and withdrawal
    /// @return Returns maximum loss allowed
    function maxLossInBP() external view returns (uint16);

    /// @notice Deposit interval
    /// @return Returns deposit interval
    function depositInterval() external view returns (uint32);

    /// @notice Last deposit timestamp of given vToken address
    /// @param _vToken Address of vToken
    /// @return Returns last deposit timestamp
    function lastDepositTimestamp(address _vToken) external view returns (uint96);

    /// @notice Checks if deposits can be updated
    /// @return Returns if deposits can be updated
    function canUpdateDeposits() external view returns (bool);

    /// @notice Checks if vTokens list contains vToken
    /// @param _vToken Address of vToken
    /// @return Returns if vTokens list contains vToken
    function containsVToken(address _vToken) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Vault controller interface
/// @notice Contains common logic for VaultControllers
interface IVaultController {
    event Deposit(uint amount);
    event Withdraw(uint amount);
    event SetDepositInfo(uint _targetDepositPercentageInBP, uint percentageInBPPerStep, uint stepDuration);

    /// @notice Sets deposit info for the vault
    /// @param _targetDepositPercentageInBP Target deposit percentage
    /// @param _percentageInBPPerStep Deposit percentage per step
    /// @param _stepDuration Deposit interval duration
    function setDepositInfo(
        uint16 _targetDepositPercentageInBP,
        uint16 _percentageInBPPerStep,
        uint32 _stepDuration
    ) external;

    /// @notice Deposits asset using vault controller
    function deposit() external;

    /// @notice Withdraws asset using vault controller
    function withdraw() external;

    /// @notice vToken's asset address
    /// @return Returns vToken's asset address
    function asset() external view returns (address);

    /// @notice vToken address
    /// @return Returns vToken address
    function vToken() external view returns (address);

    /// @notice Index Registry address
    /// @return Returns Index Registry address
    function registry() external view returns (address);

    /// @notice Expected amount of asset that can be withdrawn using vault controller
    /// @return Returns expected amount of token that can be withdrawn using vault controller
    function expectedWithdrawableAmount() external view returns (uint);

    /// @notice Total percentage of token amount that will be deposited using vault controller to earn interest
    /// @return Returns total percentage of token amount that will be deposited using vault controller to earn interest
    function targetDepositPercentageInBP() external view returns (uint16);

    /// @notice Percentage of token amount that will be deposited using vault controller per deposit step
    /// @return Returns percentage of token amount that will be deposited using vault controller per deposit step
    function percentageInBPPerStep() external view returns (uint16);

    /// @notice Deposit interval duration
    /// @return Returns deposit interval duration
    /// @dev    vToken deposit is updated gradually at defined intervals (steps). Every interval has time duration defined.
    ///         Deposited amount is calculated as timeElapsedFromLastDeposit / stepDuration * percentageInBPPerStep
    function stepDuration() external view returns (uint32);

    /// @notice Calculates deposit amount
    /// @param _currentDepositedPercentageInBP Current deposited percentage
    /// @return Returns deposit amount
    function calculatedDepositAmount(uint _currentDepositedPercentageInBP) external view returns (uint);
}