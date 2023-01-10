// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../dispatcher/IDispatcher.sol";

/// @title AddressListRegistry Contract
/// @author Enzyme Council <[email protected]>
/// @notice A contract for creating and updating lists of addresses
contract AddressListRegistry {
    enum UpdateType {
        None,
        AddOnly,
        RemoveOnly,
        AddAndRemove
    }

    event ItemAddedToList(uint256 indexed id, address item);

    event ItemRemovedFromList(uint256 indexed id, address item);

    event ListAttested(uint256 indexed id, string description);

    event ListCreated(
        address indexed creator,
        address indexed owner,
        uint256 id,
        UpdateType updateType
    );

    event ListOwnerSet(uint256 indexed id, address indexed nextOwner);

    event ListUpdateTypeSet(
        uint256 indexed id,
        UpdateType prevUpdateType,
        UpdateType indexed nextUpdateType
    );

    struct ListInfo {
        address owner;
        UpdateType updateType;
        mapping(address => bool) itemToIsInList;
    }

    address private immutable DISPATCHER;

    ListInfo[] private lists;

    modifier onlyListOwner(uint256 _id) {
        require(__isListOwner(msg.sender, _id), "Only callable by list owner");
        _;
    }

    constructor(address _dispatcher) public {
        DISPATCHER = _dispatcher;

        // Create the first list as completely empty and immutable, to protect the default `id`
        lists.push(ListInfo({owner: address(0), updateType: UpdateType.None}));
    }

    // EXTERNAL FUNCTIONS

    /// @notice Adds items to a given list
    /// @param _id The id of the list
    /// @param _items The items to add to the list
    function addToList(uint256 _id, address[] calldata _items) external onlyListOwner(_id) {
        UpdateType updateType = getListUpdateType(_id);
        require(
            updateType == UpdateType.AddOnly || updateType == UpdateType.AddAndRemove,
            "addToList: Cannot add to list"
        );

        __addToList(_id, _items);
    }

    /// @notice Attests active ownership for lists and (optionally) a description of each list's content
    /// @param _ids The ids of the lists
    /// @param _descriptions The descriptions of the lists' content
    /// @dev Since UserA can create a list on behalf of UserB, this function provides a mechanism
    /// for UserB to attest to their management of the items therein. It will not be visible
    /// on-chain, but will be available in event logs.
    function attestLists(uint256[] calldata _ids, string[] calldata _descriptions) external {
        require(_ids.length == _descriptions.length, "attestLists: Unequal arrays");

        for (uint256 i; i < _ids.length; i++) {
            require(
                __isListOwner(msg.sender, _ids[i]),
                "attestLists: Only callable by list owner"
            );

            emit ListAttested(_ids[i], _descriptions[i]);
        }
    }

    /// @notice Creates a new list
    /// @param _owner The owner of the list
    /// @param _updateType The UpdateType for the list
    /// @param _initialItems The initial items to add to the list
    /// @return id_ The id of the newly-created list
    /// @dev Specify the DISPATCHER as the _owner to make the Enzyme Council the owner
    function createList(
        address _owner,
        UpdateType _updateType,
        address[] calldata _initialItems
    ) external returns (uint256 id_) {
        id_ = getListCount();

        lists.push(ListInfo({owner: _owner, updateType: _updateType}));

        emit ListCreated(msg.sender, _owner, id_, _updateType);

        __addToList(id_, _initialItems);

        return id_;
    }

    /// @notice Removes items from a given list
    /// @param _id The id of the list
    /// @param _items The items to remove from the list
    function removeFromList(uint256 _id, address[] calldata _items) external onlyListOwner(_id) {
        UpdateType updateType = getListUpdateType(_id);
        require(
            updateType == UpdateType.RemoveOnly || updateType == UpdateType.AddAndRemove,
            "removeFromList: Cannot remove from list"
        );

        // Silently ignores items that are not in the list
        for (uint256 i; i < _items.length; i++) {
            if (isInList(_id, _items[i])) {
                lists[_id].itemToIsInList[_items[i]] = false;

                emit ItemRemovedFromList(_id, _items[i]);
            }
        }
    }

    /// @notice Sets the owner for a given list
    /// @param _id The id of the list
    /// @param _nextOwner The owner to set
    function setListOwner(uint256 _id, address _nextOwner) external onlyListOwner(_id) {
        lists[_id].owner = _nextOwner;

        emit ListOwnerSet(_id, _nextOwner);
    }

    /// @notice Sets the UpdateType for a given list
    /// @param _id The id of the list
    /// @param _nextUpdateType The UpdateType to set
    /// @dev Can only change to a less mutable option (e.g., both add and remove => add only)
    function setListUpdateType(uint256 _id, UpdateType _nextUpdateType)
        external
        onlyListOwner(_id)
    {
        UpdateType prevUpdateType = getListUpdateType(_id);
        require(
            _nextUpdateType == UpdateType.None || prevUpdateType == UpdateType.AddAndRemove,
            "setListUpdateType: _nextUpdateType not allowed"
        );

        lists[_id].updateType = _nextUpdateType;

        emit ListUpdateTypeSet(_id, prevUpdateType, _nextUpdateType);
    }

    // PRIVATE FUNCTIONS

    /// @dev Helper to add items to a list
    function __addToList(uint256 _id, address[] memory _items) private {
        for (uint256 i; i < _items.length; i++) {
            if (!isInList(_id, _items[i])) {
                lists[_id].itemToIsInList[_items[i]] = true;

                emit ItemAddedToList(_id, _items[i]);
            }
        }
    }

    /// @dev Helper to check if an account is the owner of a given list
    function __isListOwner(address _who, uint256 _id) private view returns (bool isListOwner_) {
        address owner = getListOwner(_id);
        return
            _who == owner ||
            (owner == getDispatcher() && _who == IDispatcher(getDispatcher()).getOwner());
    }

    /////////////////
    // LIST SEARCH //
    /////////////////

    // These functions are concerned with exiting quickly and do not consider empty params.
    // Developers should sanitize empty params as necessary for their own use cases.

    // EXTERNAL FUNCTIONS

    // Multiple items, single list

    /// @notice Checks if multiple items are all in a given list
    /// @param _id The list id
    /// @param _items The items to check
    /// @return areAllInList_ True if all items are in the list
    function areAllInList(uint256 _id, address[] memory _items)
        external
        view
        returns (bool areAllInList_)
    {
        for (uint256 i; i < _items.length; i++) {
            if (!isInList(_id, _items[i])) {
                return false;
            }
        }

        return true;
    }

    /// @notice Checks if multiple items are all absent from a given list
    /// @param _id The list id
    /// @param _items The items to check
    /// @return areAllNotInList_ True if no items are in the list
    function areAllNotInList(uint256 _id, address[] memory _items)
        external
        view
        returns (bool areAllNotInList_)
    {
        for (uint256 i; i < _items.length; i++) {
            if (isInList(_id, _items[i])) {
                return false;
            }
        }

        return true;
    }

    // Multiple items, multiple lists

    /// @notice Checks if multiple items are all in all of a given set of lists
    /// @param _ids The list ids
    /// @param _items The items to check
    /// @return areAllInAllLists_ True if all items are in all of the lists
    function areAllInAllLists(uint256[] memory _ids, address[] memory _items)
        external
        view
        returns (bool areAllInAllLists_)
    {
        for (uint256 i; i < _items.length; i++) {
            if (!isInAllLists(_ids, _items[i])) {
                return false;
            }
        }

        return true;
    }

    /// @notice Checks if multiple items are all in one of a given set of lists
    /// @param _ids The list ids
    /// @param _items The items to check
    /// @return areAllInSomeOfLists_ True if all items are in one of the lists
    function areAllInSomeOfLists(uint256[] memory _ids, address[] memory _items)
        external
        view
        returns (bool areAllInSomeOfLists_)
    {
        for (uint256 i; i < _items.length; i++) {
            if (!isInSomeOfLists(_ids, _items[i])) {
                return false;
            }
        }

        return true;
    }

    /// @notice Checks if multiple items are all absent from all of a given set of lists
    /// @param _ids The list ids
    /// @param _items The items to check
    /// @return areAllNotInAnyOfLists_ True if all items are absent from all lists
    function areAllNotInAnyOfLists(uint256[] memory _ids, address[] memory _items)
        external
        view
        returns (bool areAllNotInAnyOfLists_)
    {
        for (uint256 i; i < _items.length; i++) {
            if (isInSomeOfLists(_ids, _items[i])) {
                return false;
            }
        }

        return true;
    }

    // PUBLIC FUNCTIONS

    // Single item, multiple lists

    /// @notice Checks if an item is in all of a given set of lists
    /// @param _ids The list ids
    /// @param _item The item to check
    /// @return isInAllLists_ True if item is in all of the lists
    function isInAllLists(uint256[] memory _ids, address _item)
        public
        view
        returns (bool isInAllLists_)
    {
        for (uint256 i; i < _ids.length; i++) {
            if (!isInList(_ids[i], _item)) {
                return false;
            }
        }

        return true;
    }

    /// @notice Checks if an item is in at least one of a given set of lists
    /// @param _ids The list ids
    /// @param _item The item to check
    /// @return isInSomeOfLists_ True if item is in one of the lists
    function isInSomeOfLists(uint256[] memory _ids, address _item)
        public
        view
        returns (bool isInSomeOfLists_)
    {
        for (uint256 i; i < _ids.length; i++) {
            if (isInList(_ids[i], _item)) {
                return true;
            }
        }

        return false;
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `DISPATCHER` variable
    /// @return dispatcher_ The `DISPATCHER` variable value
    function getDispatcher() public view returns (address dispatcher_) {
        return DISPATCHER;
    }

    /// @notice Gets the total count of lists
    /// @return count_ The total count
    function getListCount() public view returns (uint256 count_) {
        return lists.length;
    }

    /// @notice Gets the owner of a given list
    /// @param _id The list id
    /// @return owner_ The owner
    function getListOwner(uint256 _id) public view returns (address owner_) {
        return lists[_id].owner;
    }

    /// @notice Gets the UpdateType of a given list
    /// @param _id The list id
    /// @return updateType_ The UpdateType
    function getListUpdateType(uint256 _id) public view returns (UpdateType updateType_) {
        return lists[_id].updateType;
    }

    /// @notice Checks if an item is in a given list
    /// @param _id The list id
    /// @param _item The item to check
    /// @return isInList_ True if the item is in the list
    function isInList(uint256 _id, address _item) public view returns (bool isInList_) {
        return lists[_id].itemToIsInList[_item];
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../../release/interfaces/ICompoundV3Configurator.sol";
import "./utils/AddOnlyAddressListOwnerBase.sol";

/// @title CompoundV3CTokenListOwner Contract
/// @author Enzyme Council <[email protected]>
/// @notice The AddressListRegistry owner of a Compound v3 cToken list
contract CompoundV3CTokenListOwner is AddOnlyAddressListOwnerBase {
    ICompoundV3Configurator private immutable CONFIGURATOR_CONTRACT;

    constructor(
        address _addressListRegistry,
        string memory _listDescription,
        address _compoundV3Configurator
    ) public AddOnlyAddressListOwnerBase(_addressListRegistry, _listDescription) {
        CONFIGURATOR_CONTRACT = ICompoundV3Configurator(_compoundV3Configurator);
    }

    /// @dev Required virtual helper to validate items prior to adding them to the list
    function __validateItems(address[] calldata _items) internal override {
        for (uint256 i; i < _items.length; i++) {
            require(
                CONFIGURATOR_CONTRACT.getConfiguration(_items[i]).baseToken != address(0),
                "__validateItems: Invalid cToken"
            );
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../AddressListRegistry.sol";

/// @title AddOnlyAddressListOwnerBase Contract
/// @author Enzyme Council <[email protected]>
/// @notice Base contract for an owner of an AddressListRegistry list that is add-only
abstract contract AddOnlyAddressListOwnerBase {
    AddressListRegistry internal immutable ADDRESS_LIST_REGISTRY_CONTRACT;
    uint256 internal immutable LIST_ID;

    constructor(address _addressListRegistry, string memory _listDescription) public {
        ADDRESS_LIST_REGISTRY_CONTRACT = AddressListRegistry(_addressListRegistry);

        // Create new list
        uint256 listId = AddressListRegistry(_addressListRegistry).createList({
            _owner: address(this),
            _updateType: AddressListRegistry.UpdateType.AddOnly,
            _initialItems: new address[](0)
        });
        LIST_ID = listId;

        // Attest to new list
        uint256[] memory listIds = new uint256[](1);
        string[] memory descriptions = new string[](1);
        listIds[0] = listId;
        descriptions[0] = _listDescription;

        AddressListRegistry(_addressListRegistry).attestLists({
            _ids: listIds,
            _descriptions: descriptions
        });
    }

    /// @notice Add items to the list after subjecting them to validation
    /// @param _items Items to add
    /// @dev Override if access control needed
    function addValidatedItemsToList(address[] calldata _items) external virtual {
        __validateItems(_items);

        ADDRESS_LIST_REGISTRY_CONTRACT.addToList({_id: LIST_ID, _items: _items});
    }

    /// @dev Required virtual helper to validate items prior to adding them to the list
    function __validateItems(address[] calldata _items) internal virtual;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IDispatcher Interface
/// @author Enzyme Council <[email protected]>
interface IDispatcher {
    function cancelMigration(address _vaultProxy, bool _bypassFailure) external;

    function claimOwnership() external;

    function deployVaultProxy(
        address _vaultLib,
        address _owner,
        address _vaultAccessor,
        string calldata _fundName
    ) external returns (address vaultProxy_);

    function executeMigration(address _vaultProxy, bool _bypassFailure) external;

    function getCurrentFundDeployer() external view returns (address currentFundDeployer_);

    function getFundDeployerForVaultProxy(address _vaultProxy)
        external
        view
        returns (address fundDeployer_);

    function getMigrationRequestDetailsForVaultProxy(address _vaultProxy)
        external
        view
        returns (
            address nextFundDeployer_,
            address nextVaultAccessor_,
            address nextVaultLib_,
            uint256 executableTimestamp_
        );

    function getMigrationTimelock() external view returns (uint256 migrationTimelock_);

    function getNominatedOwner() external view returns (address nominatedOwner_);

    function getOwner() external view returns (address owner_);

    function getSharesTokenSymbol() external view returns (string memory sharesTokenSymbol_);

    function getTimelockRemainingForMigrationRequest(address _vaultProxy)
        external
        view
        returns (uint256 secondsRemaining_);

    function hasExecutableMigrationRequest(address _vaultProxy)
        external
        view
        returns (bool hasExecutableRequest_);

    function hasMigrationRequest(address _vaultProxy)
        external
        view
        returns (bool hasMigrationRequest_);

    function removeNominatedOwner() external;

    function setCurrentFundDeployer(address _nextFundDeployer) external;

    function setMigrationTimelock(uint256 _nextTimelock) external;

    function setNominatedOwner(address _nextNominatedOwner) external;

    function setSharesTokenSymbol(string calldata _nextSymbol) external;

    function signalMigration(
        address _vaultProxy,
        address _nextVaultAccessor,
        address _nextVaultLib,
        bool _bypassFailure
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/// @title ICompoundV3Configurator Interface
/// @author Enzyme Council <[email protected]>
/// @dev Source: https://github.com/compound-finance/comet/blob/main/contracts/CometConfigurator.sol
interface ICompoundV3Configurator {
    struct Configuration {
        address governor;
        address pauseGuardian;
        address baseToken;
        address baseTokenPriceFeed;
        address extensionDelegate;
        uint64 supplyKink;
        uint64 supplyPerYearInterestRateSlopeLow;
        uint64 supplyPerYearInterestRateSlopeHigh;
        uint64 supplyPerYearInterestRateBase;
        uint64 borrowKink;
        uint64 borrowPerYearInterestRateSlopeLow;
        uint64 borrowPerYearInterestRateSlopeHigh;
        uint64 borrowPerYearInterestRateBase;
        uint64 storeFrontPriceFactor;
        uint64 trackingIndexScale;
        uint64 baseTrackingSupplySpeed;
        uint64 baseTrackingBorrowSpeed;
        uint104 baseMinForRewards;
        uint104 baseBorrowMin;
        uint104 targetReserves;
        AssetConfig[] assetConfigs;
    }

    struct AssetConfig {
        address asset;
        address priceFeed;
        uint8 decimals;
        uint64 borrowCollateralFactor;
        uint64 liquidateCollateralFactor;
        uint64 liquidationFactor;
        uint128 supplyCap;
    }

    function getConfiguration(address _cToken)
        external
        view
        returns (Configuration memory configuration_);
}