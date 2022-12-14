// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "IRentalPool.sol";
import "IMissionManager.sol";
import "IWalletFactory.sol";
import "NFTRental.sol";
import "EnumerableSet.sol";
import "IERC721.sol";
import "AccessManager.sol";

contract RentalPool is AccessManager, IRentalPool {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => mapping(address => EnumerableSet.UintSet))
        private stakedNFTs;
    mapping(address => mapping(address => mapping(string => bool)))
        public ownerReadyMission;
    mapping(address => bool) public whitelistedOwners;

    address public missionManager;
    address public walletFactory;

    modifier onlyMissionManager() {
        require(
            msg.sender == missionManager,
            "Only mission manager is authorized"
        );
        _;
    }

    constructor(IRoleRegistry _roleRegistry) {
        setRoleRegistry(_roleRegistry);
    }

    function setMissionManager(address _missionManager)
        external
        override
        onlyRole(Roles.ADMIN)
    {
        require(missionManager == address(0), "Mission manager already set");
        missionManager = _missionManager;
    }

    function setWalletFactory(address _walletFactory)
        external
        override
        onlyRole(Roles.ADMIN)
    {
        walletFactory = _walletFactory;
    }

    function whitelistOwners(address[] calldata _owners)
        external
        override
        onlyRole(Roles.OWNER_WHITELISTER)
    {
        for (uint32 i = 0; i < _owners.length; i++) {
            whitelistedOwners[_owners[i]] = true;
        }
    }

    function removeWhitelistedOwners(address[] calldata _owners)
        external
        override
        onlyRole(Roles.OWNER_WHITELISTER)
    {
        for (uint32 i = 0; i < _owners.length; i++) {
            whitelistedOwners[_owners[i]] = false;
        }
    }

    function verifyAndStake(NFTRental.Mission calldata newMission)
        external
        override
        onlyMissionManager
    {
        require(
            whitelistedOwners[newMission.owner],
            "Owner is not whitelisted"
        );
        _verifyParam(
            newMission.dappId,
            newMission.collections,
            newMission.tokenIds
        );
        require(
            !ownerReadyMission[newMission.owner][newMission.tenant][
                newMission.dappId
            ],
            "Owner already have ready mission for tenant and dapp"
        );
        _stakeNFT(
            newMission.owner,
            newMission.collections,
            newMission.tokenIds
        );
        ownerReadyMission[newMission.owner][newMission.tenant][
            newMission.dappId
        ] = true;
    }

    function sendStartingMissionNFT(
        string calldata _uuid,
        address _gamingWallet
    ) external override onlyMissionManager {
        NFTRental.Mission memory curMission = IMissionManager(missionManager)
            .getReadyMission(_uuid);
        require(
            IWalletFactory(walletFactory).verifyCollectionForUniqueDapp(
                curMission.dappId,
                curMission.collections
            ),
            "Collection not linked to Dapp"
        );
        _transferAndUnstakeNFTs(
            curMission.owner,
            _gamingWallet,
            curMission.collections,
            curMission.tokenIds
        );
        delete ownerReadyMission[curMission.owner][curMission.tenant][
            curMission.dappId
        ];
    }

    function sendNFTsBack(NFTRental.Mission calldata curMission)
        external
        onlyMissionManager
    {
        _transferAndUnstakeNFTs(
            curMission.owner,
            curMission.owner,
            curMission.collections,
            curMission.tokenIds
        );
        delete ownerReadyMission[curMission.owner][curMission.tenant][
            curMission.dappId
        ];
    }

    function isNFTStaked(
        address _collection,
        address _owner,
        uint256 _tokenId
    ) external view returns (bool isStaked) {
        return stakedNFTs[_owner][_collection].contains(_tokenId);
    }

    function isOwnerWhitelisted(address _owner)
        external
        view
        returns (bool isWhitelisted)
    {
        return whitelistedOwners[_owner];
    }

    function _transferAndUnstakeNFTs(
        address _owner,
        address _recipient,
        address[] memory _collections,
        uint256[][] memory _tokenIds
    ) internal {
        uint256 collectionsLength = _collections.length;
        for (uint32 i; i < collectionsLength; i++) {
            uint256 tokenIdsLength = _tokenIds[i].length;
            for (uint32 j; j < tokenIdsLength; j++) {
                IERC721(_collections[i]).transferFrom(
                    address(this),
                    _recipient,
                    _tokenIds[i][j]
                );
                stakedNFTs[_owner][_collections[i]].remove(_tokenIds[i][j]);
                emit NFTUnstaked(_collections[i], _owner, _tokenIds[i][j]);
            }
        }
    }

    function _stakeNFT(
        address _owner,
        address[] calldata _collections,
        uint256[][] calldata _tokenIds
    ) internal {
        for (uint32 i; i < _tokenIds.length; i++) {
            for (uint32 j; j < _tokenIds[i].length; j++) {
                IERC721(_collections[i]).transferFrom(
                    _owner,
                    address(this),
                    _tokenIds[i][j]
                );
                stakedNFTs[_owner][_collections[i]].add(_tokenIds[i][j]);
                emit NFTStaked(_collections[i], _owner, _tokenIds[i][j]);
            }
        }
    }

    function _verifyParam(
        string calldata _dappId,
        address[] calldata _collections,
        uint256[][] calldata _tokenIds
    ) internal view {
        require(
            _collections.length == _tokenIds.length,
            "Incorrect lengths collections and tokenIds"
        );
        require(_tokenIds[0][0] != 0, "At least one NFT required");
        require(
            IWalletFactory(walletFactory).verifyCollectionForUniqueDapp(
                _dappId,
                _collections
            ),
            "Collections correspond to multiple dapp"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;
import "IERC721.sol";
import "NFTRental.sol";

// Pool to hold the staked NFTs of one collection that are not currently rented out
interface IRentalPool {
    event NFTStaked(address collection, address owner, uint256 tokenId);

    event NFTUnstaked(address collection, address owner, uint256 tokenId);

    function setMissionManager(address _rentalManager) external;

    function setWalletFactory(address _walletFactory) external;

    function whitelistOwners(address[] calldata _owners) external;

    function removeWhitelistedOwners(address[] calldata _owners) external;

    function verifyAndStake(NFTRental.Mission calldata newMission) external;

    function sendStartingMissionNFT(
        string calldata _uuid,
        address _gamingWallet
    ) external;

    function sendNFTsBack(NFTRental.Mission calldata mission) external;

    function isNFTStaked(
        address collection,
        address owner,
        uint256 tokenId
    ) external view returns (bool isStaked);

    function isOwnerWhitelisted(address _owner)
        external
        view
        returns (bool isWhitelisted);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

library NFTRental {
    struct Mission {
        string uuid;
        string dappId;
        address owner;
        address tenant;
        address[] collections;
        uint256[][] tokenIds;
        uint256 tenantShare;
    }

    struct MissionDates {
        uint256 postDate;
        uint256 startDate;
        uint256 cancelDate;
        uint256 stopDate;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;
import "IERC721.sol";
import "NFTRental.sol";

// Management contract for NFT rentals.
// This mostly stores rental agreements and does the transfer with the wallet contracts
interface IMissionManager {
    event MissionPosted(NFTRental.Mission mission);

    event MissionCanceled(NFTRental.Mission mission);

    event MissionStarted(NFTRental.Mission mission);

    event MissionTerminating(NFTRental.Mission mission);

    event MissionTerminated(NFTRental.Mission mission);

    function setWalletFactory(address _walletFactoryAdr) external;

    function oasisClaimForMission(
        address gamingWallet,
        address gameContract,
        bytes calldata data_
    ) external returns (bytes memory);

    function postMissions(NFTRental.Mission[] calldata mission) external;

    function cancelMissions(string[] calldata _uuid) external;

    function startMission(string calldata _uuid) external;

    function stopMission(string calldata _uuid) external;

    function terminateMission(string calldata _uuid) external;

    function terminateMissionFallback(string calldata _uuid) external;

    function getOngoingMission(string calldata _uuid)
        external
        view
        returns (NFTRental.Mission calldata mission);

    function getReadyMission(string calldata _uuid)
        external
        view
        returns (NFTRental.Mission memory mission);

    function getTenantOngoingMissionUuid(address _tenant)
        external
        view
        returns (string[] memory missionUuid);

    function getTenantReadyMissionUuid(address _tenant)
        external
        view
        returns (string[] memory missionUuid);

    function tenantHasOngoingMissionForDapp(
        address _tenant,
        string memory _dappId
    ) external view returns (bool hasMissionForDapp);

    function tenantHasReadyMissionForDapp(
        address _tenant,
        string memory _dappId
    ) external view returns (bool hasMissionForDapp);

    function getTenantReadyMissionUuidIndex(
        address _tenant,
        string calldata _uuid
    ) external view returns (uint256 uuidPosition);

    function getTenantOngoingMissionUuidIndex(
        address _tenant,
        string calldata _uuid
    ) external view returns (uint256 uuidPosition);

    function isMissionPosted(string calldata _uuid)
        external
        view
        returns (bool);

    function batchMissionsDates(string[] calldata _uuid)
        external
        view
        returns (NFTRental.MissionDates[] memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

// Factory to create gaming wallets
interface IWalletFactory {
    event WalletCreated(address owner, address walletAddress);

    function createWallet() external;

    function createWallet(address _owner) external;

    function resetTenantGamingWallet(address _tenant) external;

    function changeRentalPoolAddress(address _rentalPool) external;

    function changeProxyRegistryAddress(address _proxyRegistry) external;

    function changeRevenueManagerAddress(address _revenueManager) external;

    function addCollectionForDapp(string calldata _dappId, address _collection)
        external;

    function removeCollectionForDapp(
        string calldata _dappId,
        address _collection
    ) external;

    function verifyCollectionForUniqueDapp(
        string calldata _dappId,
        address[] calldata _collections
    ) external view returns (bool uniqueDapp);

    function getGamingWallet(address owner)
        external
        view
        returns (address gamingWalletAddress);

    function hasGamingWallet(address owner)
        external
        view
        returns (bool hasWallet);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "RoleLibrary.sol";

import "IRoleRegistry.sol";

/**
 * @notice Provides modifiers for authorization
 */
contract AccessManager {
    IRoleRegistry internal roleRegistry;
    bool public isInitialised = false;

    modifier onlyRole(bytes32 role) {
        require(roleRegistry.hasRole(role, msg.sender), "Unauthorized access");
        _;
    }

    modifier onlyGovernance() {
        require(
            roleRegistry.hasRole(Roles.ADMIN, msg.sender),
            "Unauthorized access"
        );
        _;
    }

    modifier onlyRoles2(bytes32 role1, bytes32 role2) {
        require(
            roleRegistry.hasRole(role1, msg.sender) ||
                roleRegistry.hasRole(role2, msg.sender),
            "Unauthorized access"
        );
        _;
    }

    function setRoleRegistry(IRoleRegistry _roleRegistry) public {
        require(!isInitialised, "RoleRegistry already initialised");
        roleRegistry = _roleRegistry;
        isInitialised = true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.10;

library Roles {
    bytes32 internal constant ADMIN = "admin";
    bytes32 internal constant REWARD_CLAIMER = "reward_claimer";
    bytes32 internal constant MISSION_TERMINATOR = "mission_terminator";
    bytes32 internal constant FUNCTION_WHITELISTER = "function_whitelister";
    bytes32 internal constant PROXY_SETTER = "proxy_setter";
    bytes32 internal constant OWNER_WHITELISTER = "owner_whitelister";
    bytes32 internal constant REWARD_DISTRIBUTOR = "reward_distributor";
    bytes32 internal constant GAMECOLLECTION_SETTER = "gamecollection_setter";
    bytes32 internal constant PROXY_REGISTRY = "proxy_registry";
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

interface IRoleRegistry {
    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 _role, address account) external;

    function hasRole(bytes32 _role, address account)
        external
        view
        returns (bool);
}