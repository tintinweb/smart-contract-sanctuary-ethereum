// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';

/// @title Role-based access control for limiting access to some functions of the contract
/// @notice Assign roles to grant access to otherwise limited functions of the contract
contract AccessControlFacet {
	/// @notice An admin of the contract.
	/// @return Hashed value that represents this role.
	function ADMIN_ROLE() external view returns (bytes32) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.ADMIN_ROLE;
	}

	/// @notice Can mint root level Meems
	/// @return Hashed value that represents this role.
	function MINTER_ROLE() external view returns (bytes32) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.MINTER_ROLE;
	}

	/// @notice Grant a role to a user. The granting user must have the ADMIN_ROLE
	/// @param user The wallet address of the user to grant the role to
	/// @param role The role to grant
	function grantRole(address user, bytes32 role) external {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.ADMIN_ROLE);
		LibAccessControl._grantRole(role, user);
	}

	/// @notice Grant a role to a user. The granting user must have the ADMIN_ROLE
	/// @param user The wallet address of the user to revoke the role from
	/// @param role The role to revoke
	function revokeRole(address user, bytes32 role) external {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibAccessControl.requireRole(s.ADMIN_ROLE);
		LibAccessControl._revokeRole(role, user);
	}

	/// @notice Grant a role to a user. The granting user must have the ADMIN_ROLE
	/// @param user The wallet address of the user to revoke the role from
	/// @param role The role to revoke
	function hasRole(address user, bytes32 role) external view returns (bool) {
		return LibAccessControl.hasRole(role, user);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {LibMeta} from '../libraries/LibMeta.sol';
import {MeemBase, MeemProperties, Chain, BaseProperties} from '../interfaces/MeemStandard.sol';

library LibAppStorage {
	bytes32 constant DIAMOND_STORAGE_POSITION =
		keccak256('meemproject.app.storage');

	struct RoleData {
		mapping(address => bool) members;
	}

	struct AppStorage {
		/** AccessControl Role: Admin */
		bytes32 ADMIN_ROLE;
		/** AccessControl Role: Minter */
		bytes32 MINTER_ROLE;
		/** Counter of next incremental token */
		uint256 tokenCounter;
		/** ERC721 Name */
		string name;
		/** ERC721 Symbol */
		string symbol;
		/** Mapping of addresses => all tokens they own */
		mapping(address => uint256[]) ownerTokenIds;
		/** Mapping of addresses => number of tokens owned */
		mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndexes;
		/** Mapping of token to approved address */
		mapping(uint256 => address) approved;
		/** Mapping of address to operators */
		mapping(address => mapping(address => bool)) operators;
		/** Mapping of token => Meem data  */
		mapping(uint256 => MeemBase) meems;
		mapping(uint256 => MeemProperties) meemProperties;
		mapping(uint256 => MeemProperties) meemChildProperties;
		/** The minimum amount that must be allocated to non-owners of a token in splits */
		uint256 nonOwnerSplitAllocationAmount;
		/** The contract URI. Used to describe this NFT collection */
		string contractURI;
		/** The depth allowed for minting of children. If 0, no child copies are allowed. */
		int256 childDepth;
		/** Mapping of token => URIs for each token */
		mapping(uint256 => string) tokenURIs;
		/** Mapping of token to all children */
		mapping(uint256 => uint256[]) remixes;
		/** Mapping of token to all decendants */
		mapping(uint256 => uint256[]) decendants;
		/** Keeps track of assigned roles */
		mapping(bytes32 => RoleData) roles;
		/** Mapping from token ID to approved address */
		mapping(uint256 => address) tokenApprovals;
		/** Mapping from owner to operator approvals */
		mapping(address => mapping(address => bool)) operatorApprovals;
		/** All tokenIds that have been minted and the corresponding index in allTokens */
		uint256[] allTokens;
		/** Index of tokenId => allTokens index */
		mapping(uint256 => uint256) allTokensIndex;
		/** Keep track of whether a tokenId has been minted */
		mapping(uint256 => bool) mintedTokens;
		/** Keep track of tokens that have already been wrapped */
		mapping(Chain => mapping(address => mapping(uint256 => uint256))) chainWrappedNFTs;
		/** Mapping of (parent) tokenId to owners and the child tokenIds they own */
		mapping(uint256 => mapping(address => uint256[])) remixesOwnerTokens;
		/** Keep track of original Meems */
		uint256[] originalMeemTokens;
		/** Index of tokenId => allTokens index */
		mapping(uint256 => uint256) originalMeemTokensIndex;
		mapping(uint256 => uint256[]) copies;
		mapping(uint256 => mapping(address => uint256[])) copiesOwnerTokens;
		/** Keep track of "clipped" meems */
		/** tokenId => array of addresses that have clipped */
		mapping(uint256 => address[]) clippings;
		/** address => tokenIds */
		mapping(address => uint256[]) addressClippings;
		/** address => tokenId => index */
		mapping(address => mapping(uint256 => uint256)) clippingsIndex;
		/** address => tokenId => index */
		mapping(address => mapping(uint256 => uint256)) addressClippingsIndex;
		/** address => tokenId => index */
		mapping(address => mapping(uint256 => bool)) hasAddressClipped;
		/** token => reaction name => total */
		mapping(uint256 => mapping(string => uint256)) tokenReactions;
		/** token => reaction name => address => reactedAt */
		mapping(uint256 => mapping(string => mapping(address => uint256))) addressReactionsAt;
		/** address => token => reaction names[] */
		mapping(address => mapping(uint256 => string[])) addressReactions;
		/** address => token => reaction name => index */
		mapping(address => mapping(uint256 => mapping(string => uint256))) addressReactionsIndex;
		BaseProperties baseProperties;
		MeemProperties defaultProperties;
		MeemProperties defaultChildProperties;
		/** Keeping track of original tokens owner -> token -> isOwner */
		mapping(address => mapping(uint256 => bool)) originalOwnerTokens;
		/** Number of original tokens held by a wallet */
		mapping(address => uint256) originalOwnerCount;
		mapping(address => mapping(uint256 => uint256)) copiesOwnerTokenIndexes;
		mapping(address => mapping(uint256 => uint256)) remixesOwnerTokenIndexes;
		/** role -> addresses[] */
		mapping(bytes32 => address[]) rolesList;
		mapping(bytes32 => mapping(address => uint256)) rolesListIndex;
		bool isInitialized;
	}

	function diamondStorage() internal pure returns (AppStorage storage ds) {
		bytes32 position = DIAMOND_STORAGE_POSITION;
		assembly {
			ds.slot := position
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {Array} from '../utils/Array.sol';
import {Error} from './Errors.sol';
import {AccessControlEvents} from './Events.sol';

library LibAccessControl {
	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	// function supportsInterface(bytes4 interfaceId)
	// 	internal
	// 	view
	// 	virtual
	// 	returns (bool)
	// {
	// 	return
	// 		interfaceId == type(IAccessControlUpgradeable).interfaceId ||
	// 		super.supportsInterface(interfaceId);
	// }

	function requireRole(bytes32 role) internal view {
		if (!hasRole(role, msg.sender)) {
			revert(Error.MissingRequiredRole);
		}
	}

	/**
	 * @dev Returns `true` if `account` has been granted `role`.
	 */
	function hasRole(bytes32 role, address account)
		internal
		view
		returns (bool)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.roles[role].members[account];
	}

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
	function grantRole(bytes32 role, address account) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		requireRole(s.ADMIN_ROLE);
		_grantRole(role, account);
	}

	/**
	 * @dev Revokes `role` from `account`.
	 *
	 * If `account` had been granted `role`, emits a {RoleRevoked} event.
	 *
	 * Requirements:
	 *
	 * - the caller must have ``role``'s admin role.
	 */
	function revokeRole(bytes32 role, address account) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		requireRole(s.ADMIN_ROLE);
		_revokeRole(role, account);
	}

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
	function renounceRole(bytes32 role, address account) internal {
		if (account != msg.sender) {
			revert(Error.NoRenounceOthers);
		}

		_revokeRole(role, account);
	}

	/**
	 * @dev Grants `role` to `account`.
	 *
	 * If `account` had not been already granted `role`, emits a {RoleGranted}
	 * event. Note that unlike {grantRole}, this function doesn't perform any
	 * checks on the calling account.
	 *
	 * [WARNING]
	 * ====
	 * This function should only be called from the constructor when setting
	 * up the initial roles for the system.
	 *
	 * Using this function in any other way is effectively circumventing the admin
	 * system imposed by {AccessControl}.
	 * ====
	 */
	function _setupRole(bytes32 role, address account) internal {
		_grantRole(role, account);
	}

	/**
	 * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
	 */
	function toHexString(uint256 value) internal pure returns (string memory) {
		if (value == 0) {
			return '0x00';
		}
		uint256 temp = value;
		uint256 length = 0;
		while (temp != 0) {
			length++;
			temp >>= 8;
		}
		return toHexString(value, length);
	}

	/**
	 * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
	 */
	function toHexString(uint256 value, uint256 length)
		internal
		pure
		returns (string memory)
	{
		bytes16 _HEX_SYMBOLS = '0123456789abcdef';
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = '0';
		buffer[1] = 'x';
		for (uint256 i = 2 * length + 1; i > 1; --i) {
			buffer[i] = _HEX_SYMBOLS[value & 0xf];
			value >>= 4;
		}
		require(value == 0, 'Strings: hex length insufficient');
		return string(buffer);
	}

	function _grantRole(bytes32 role, address account) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (!hasRole(role, account)) {
			s.roles[role].members[account] = true;
			s.rolesList[role].push(account);
			s.rolesListIndex[role][account] = s.rolesList[role].length - 1;
			emit AccessControlEvents.MeemRoleGranted(role, account, msg.sender);
		}
	}

	function _revokeRole(bytes32 role, address account) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (hasRole(role, account)) {
			s.roles[role].members[account] = false;
			uint256 idx = s.rolesListIndex[role][account];
			Array.removeAt(s.rolesList[role], idx);

			emit AccessControlEvents.MeemRoleRevoked(role, account, msg.sender);
		}
	}

	function _setRole(bytes32 role, address[] memory accounts) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		requireRole(s.ADMIN_ROLE);
		for (uint256 i = 0; i < s.rolesList[role].length; i++) {
			address addy = s.rolesList[role][i];
			delete s.rolesListIndex[role][addy];
			s.roles[role].members[addy] = false;
		}
		delete s.rolesList[role];

		for (uint256 i = 0; i < accounts.length; i++) {
			address addy = accounts[i];
			if (!hasRole(role, addy)) {
				s.rolesList[role].push(addy);
				s.rolesListIndex[role][addy] = i;
				s.roles[role].members[addy] = true;
			}
		}

		emit AccessControlEvents.MeemRoleSet(role, accounts, msg.sender);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library LibMeta {
	bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
		keccak256(
			bytes(
				'EIP712Domain(string name,string version,uint256 salt,address verifyingContract)'
			)
		);

	function domainSeparator(string memory name, string memory version)
		internal
		view
		returns (bytes32 domainSeparator_)
	{
		domainSeparator_ = keccak256(
			abi.encode(
				EIP712_DOMAIN_TYPEHASH,
				keccak256(bytes(name)),
				keccak256(bytes(version)),
				getChainID(),
				address(this)
			)
		);
	}

	function getChainID() internal view returns (uint256 id) {
		assembly {
			id := chainid()
		}
	}

	function msgSender() internal view returns (address sender_) {
		if (msg.sender == address(this)) {
			bytes memory array = msg.data;
			uint256 index = msg.data.length;
			assembly {
				// Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
				sender_ := and(
					mload(add(array, index)),
					0xffffffffffffffffffffffffffffffffffffffff
				)
			}
		} else {
			sender_ = msg.sender;
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum Chain {
	Ethereum,
	Polygon,
	Cardano,
	Solana,
	Rinkeby
}

enum PermissionType {
	Copy,
	Remix,
	Read
}

enum Permission {
	Owner,
	Anyone,
	Addresses,
	Holders
}

enum PropertyType {
	Meem,
	Child,
	DefaultMeem,
	DefaultChild
}

enum MeemType {
	Original,
	Copy,
	Remix,
	Wrapped
}

enum URISource {
	Url,
	JSON
}

struct Split {
	address toAddress;
	uint256 amount;
	address lockedBy;
}

struct MeemPermission {
	Permission permission;
	address[] addresses;
	uint256 numTokens;
	address lockedBy;
	uint256 costWei;
}

struct MeemProperties {
	int256 totalRemixes;
	address totalRemixesLockedBy;
	int256 remixesPerWallet;
	address remixesPerWalletLockedBy;
	MeemPermission[] copyPermissions;
	MeemPermission[] remixPermissions;
	MeemPermission[] readPermissions;
	address copyPermissionsLockedBy;
	address remixPermissionsLockedBy;
	address readPermissionsLockedBy;
	Split[] splits;
	address splitsLockedBy;
	int256 totalCopies;
	address totalCopiesLockedBy;
	int256 copiesPerWallet;
	address copiesPerWalletLockedBy;
	bool isTransferrable;
	address isTransferrableLockedBy;
	int256 mintStartTimestamp;
	int256 mintEndTimestamp;
	address mintDatesLockedBy;
	uint256 transferLockupUntil;
	address transferLockupUntilLockedBy;
}

struct BaseProperties {
	int256 totalOriginalsSupply;
	address totalOriginalsSupplyLockedBy;
	MeemPermission[] mintPermissions;
	address mintPermissionsLockedBy;
	Split[] splits;
	address splitsLockedBy;
	int256 originalsPerWallet;
	address originalsPerWalletLockedBy;
	bool isTransferrable;
	address isTransferrableLockedBy;
	int256 mintStartTimestamp;
	int256 mintEndTimestamp;
	address mintDatesLockedBy;
	uint256 transferLockupUntil;
	address transferLockupUntilLockedBy;
}

// struct BasePropertiesInit {
// 	int256 totalOriginalsSupply;
// 	bool isTotalOriginalsSupplyLocked;
// 	MeemPermission[] mintPermissions;
// 	bool isMintPermissionsLocked;
// 	Split[] splits;
// 	bool isSplitsLocked;
// 	int256 originalsPerWallet;
// 	bool isOriginalsPerWalletLocked;
// 	bool isTransferrable;
// 	bool isIsTransferrableLocked;
// 	int256 mintStartTimestamp;
// 	int256 mintEndTimestamp;
// 	bool isMintDatesLocked;
// }

struct MeemBase {
	address owner;
	Chain parentChain;
	address parent;
	uint256 parentTokenId;
	Chain rootChain;
	address root;
	uint256 rootTokenId;
	uint256 generation;
	uint256 mintedAt;
	string data;
	address uriLockedBy;
	MeemType meemType;
	address mintedBy;
	URISource uriSource;
	string[] reactionTypes;
}

struct Meem {
	address owner;
	Chain parentChain;
	address parent;
	uint256 parentTokenId;
	Chain rootChain;
	address root;
	uint256 rootTokenId;
	uint256 generation;
	MeemProperties properties;
	MeemProperties childProperties;
	uint256 mintedAt;
	address uriLockedBy;
	MeemType meemType;
	address mintedBy;
	URISource uriSource;
	string[] reactionTypes;
}

struct WrappedItem {
	Chain chain;
	address contractAddress;
	uint256 tokenId;
}

struct MeemMintParameters {
	address to;
	string tokenURI;
	Chain parentChain;
	address parent;
	uint256 parentTokenId;
	MeemType meemType;
	bool isURILocked;
	address mintedBy;
	URISource uriSource;
	string[] reactionTypes;
}

struct Reaction {
	string reaction;
	uint256 count;
}

struct InitParams {
	string symbol;
	string name;
	string contractURI;
	BaseProperties baseProperties;
	MeemProperties defaultProperties;
	MeemProperties defaultChildProperties;
	address[] admins;
	uint256 tokenCounterStart;
	int256 childDepth;
	uint256 nonOwnerSplitAllocationAmount;
}

struct ContractInfo {
	string symbol;
	string name;
	string contractURI;
	BaseProperties baseProperties;
	MeemProperties defaultProperties;
	MeemProperties defaultChildProperties;
	int256 childDepth;
	uint256 nonOwnerSplitAllocationAmount;
}

interface IInitDiamondStandard {
	function init(InitParams memory params) external;
}

interface IMeemBaseStandard {
	function mint(
		MeemMintParameters memory params,
		MeemProperties memory properties,
		MeemProperties memory childProperties
	) external payable;

	function mintAndCopy(
		MeemMintParameters memory params,
		MeemProperties memory properties,
		MeemProperties memory childProperties,
		address toCopyAddress
	) external payable;

	function mintAndRemix(
		MeemMintParameters memory params,
		MeemProperties memory properties,
		MeemProperties memory childProperties,
		MeemMintParameters memory remixParams,
		MeemProperties memory remixProperties,
		MeemProperties memory remixChildProperties
	) external payable;

	// TODO: Implement child minting
	// function mintChild(
	// 	address to,
	// 	string memory mTokenURI,
	// 	Chain chain,
	// 	uint256 parentTokenId,
	// 	MeemProperties memory properties,
	// 	MeemProperties memory childProperties
	// ) external;
}

interface IMeemQueryStandard {
	// Get children meems
	function copiesOf(uint256 tokenId) external view returns (uint256[] memory);

	function ownedCopiesOf(uint256 tokenId, address owner)
		external
		view
		returns (uint256[] memory);

	function numCopiesOf(uint256 tokenId) external view returns (uint256);

	function remixesOf(uint256 tokenId)
		external
		view
		returns (uint256[] memory);

	function ownedRemixesOf(uint256 tokenId, address owner)
		external
		view
		returns (uint256[] memory);

	function numRemixesOf(uint256 tokenId) external view returns (uint256);

	function childDepth() external returns (int256);

	function tokenIdsOfOwner(address _owner)
		external
		view
		returns (uint256[] memory tokenIds_);

	function isNFTWrapped(
		Chain chain,
		address contractAddress,
		uint256 tokenId
	) external view returns (bool);

	function wrappedTokens(WrappedItem[] memory items)
		external
		view
		returns (uint256[] memory);

	function getMeem(uint256 tokenId) external view returns (Meem memory);

	function getBaseProperties() external view returns (BaseProperties memory);

	function getDefaultProperties(PropertyType propertyType)
		external
		view
		returns (MeemProperties memory);

	function getContractInfo() external view returns (ContractInfo memory);

	function getRoles(bytes32 role) external view returns (address[] memory);
}

interface IMeemAdminStandard {
	function setNonOwnerSplitAllocationAmount(uint256 amount) external;

	function setChildDepth(int256 newChildDepth) external;

	function setTokenCounter(uint256 tokenCounter) external;

	function setContractURI(string memory newContractURI) external;

	function setTokenRoot(
		uint256 tokenId,
		Chain rootChain,
		address root,
		uint256 rootTokenId
	) external;

	function setBaseSplits(Split[] memory splits) external;

	function setTotalOriginalsSupply(int256 totalSupply) external;

	function setOriginalsPerWallet(int256 originalsPerWallet) external;

	function setIsTransferrable(bool isTransferrable) external;

	function lockBaseSplits() external;

	function lockTotalOriginalsSupply() external;

	function lockOriginalsPerWallet() external;

	function lockIsTransferrable() external;

	function lockMintDates() external;

	function setMintDates(int256 startTimestamp, int256 endTimestamp) external;

	function setContractInfo(string memory name, string memory symbol) external;

	function setMintPermissions(MeemPermission[] memory permissions) external;

	function lockMintPermissions() external;

	function setTransferLockup(uint256 lockupUntil) external;

	function lockTransferLockup() external;

	function setProperties(
		PropertyType propertyType,
		MeemProperties memory props
	) external;

	function reInitialize(InitParams memory params) external;
}

interface IMeemSplitsStandard {
	function nonOwnerSplitAllocationAmount() external view returns (uint256);

	function lockSplits(uint256 tokenId, PropertyType propertyType) external;

	function setSplits(
		uint256 tokenId,
		PropertyType propertyType,
		Split[] memory splits
	) external;

	function addSplit(
		uint256 tokenId,
		PropertyType propertyType,
		Split memory split
	) external;

	function removeSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx
	) external;

	function updateSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx,
		Split memory split
	) external;
}

interface IMeemPermissionsStandard {
	function lockPermissions(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType
	) external;

	function setPermissions(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission[] memory permissions
	) external;

	function addPermission(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission memory permission
	) external;

	function removePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx
	) external;

	function updatePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx,
		MeemPermission memory permission
	) external;

	function setTotalCopies(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalCopies
	) external;

	function lockTotalCopies(uint256 tokenId, PropertyType propertyType)
		external;

	function setCopiesPerWallet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newChildrenPerWallet
	) external;

	function lockCopiesPerWallet(uint256 tokenId, PropertyType propertyType)
		external;

	function setTotalRemixes(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalRemixes
	) external;

	function lockTotalRemixes(uint256 tokenId, PropertyType propertyType)
		external;

	function setRemixesPerWallet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newChildrenPerWallet
	) external;

	function lockRemixesPerWallet(uint256 tokenId, PropertyType propertyType)
		external;

	function setData(uint256 tokenId, string memory data) external;

	function lockUri(uint256 tokenId) external;

	function setURISource(uint256 tokenId, URISource uriSource) external;

	function setTokenUri(uint256 tokenId, string memory uri) external;

	function setIsTransferrable(uint256 tokenId, bool isTransferrable) external;

	function lockIsTransferrable(uint256 tokenId) external;

	function lockMintDates(uint256 tokenId) external;

	function setMintDates(
		uint256 tokenId,
		int256 startTimestamp,
		int256 endTimestamp
	) external;

	function setTransferLockup(uint256 tokenId, uint256 lockupUntil) external;

	function lockTransferLockup(uint256 tokenId) external;
}

interface IClippingStandard {
	function clip(uint256 tokenId) external;

	function unClip(uint256 tokenId) external;

	function addressClippings(address addy)
		external
		view
		returns (uint256[] memory);

	function hasAddressClipped(uint256 tokenId, address addy)
		external
		view
		returns (bool);

	function clippings(uint256 tokenId)
		external
		view
		returns (address[] memory);

	function numClippings(uint256 tokenId) external view returns (uint256);
}

interface IReactionStandard {
	function addReaction(uint256 tokenId, string memory reaction) external;

	function removeReaction(uint256 tokenId, string memory reaction) external;

	function getReactedAt(
		uint256 tokenId,
		address addy,
		string memory reaction
	) external view returns (uint256);

	function setReactionTypes(uint256 tokenId, string[] memory reactionTypes)
		external;

	function getReactions(uint256 tokenId)
		external
		view
		returns (Reaction[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Array {
	function removeAt(uint256[] storage array, uint256 index)
		internal
		returns (uint256[] memory)
	{
		if (index >= array.length) {
			revert('Index out of range');
		}

		for (uint256 i = index; i < array.length - 1; i++) {
			array[i] = array[i + 1];
		}
		array.pop();
		return array;
	}

	function removeAt(address[] storage array, uint256 index)
		internal
		returns (address[] memory)
	{
		if (index >= array.length) {
			revert('Index out of range');
		}

		for (uint256 i = index; i < array.length - 1; i++) {
			array[i] = array[i + 1];
		}
		array.pop();
		return array;
	}

	function removeAt(string[] storage array, uint256 index)
		internal
		returns (string[] memory)
	{
		if (index >= array.length) {
			revert('Index out of range');
		}

		for (uint256 i = index; i < array.length - 1; i++) {
			array[i] = array[i + 1];
		}
		array.pop();
		return array;
	}

	function isEqual(address[] memory arr1, address[] memory arr2)
		internal
		pure
		returns (bool)
	{
		if (arr1.length != arr2.length) {
			return false;
		}

		for (uint256 i = 0; i < arr1.length; i++) {
			if (arr1[i] != arr2[i]) {
				return false;
			}
		}

		return true;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {LibMeta} from '../libraries/LibMeta.sol';
import {MeemBase, MeemProperties, Chain, BaseProperties} from '../interfaces/MeemStandard.sol';

library Error {
	string public constant MissingRequiredRole = 'MISSING_REQUIRED_ROLE';
	string public constant NotTokenOwner = 'NOT_TOKEN_OWNER';
	string public constant NotTokenAdmin = 'NOT_TOKEN_ADMIN';
	string public constant InvalidNonOwnerSplitAllocationAmount =
		'INVALID_NON_OWNER_SPLIT_ALLOCATION_AMOUNT';
	string public constant NoRenounceOthers = 'NO_RENOUNCE_OTHERS';
	string public constant InvalidZeroAddressQuery =
		'INVALID_ZERO_ADDRESS_QUERY';
	string public constant IndexOutOfRange = 'INDEX_OUT_OF_RANGE';
	string public constant TokenNotFound = 'TOKEN_NOT_FOUND';
	string public constant TokenAlreadyExists = 'TOKEN_ALREADY_EXISTS';
	string public constant NoApproveSelf = 'NO_APPROVE_SELF';
	string public constant NotApproved = 'NOT_APPROVED';
	string public constant ERC721ReceiverNotImplemented =
		'ERC721_RECEIVER_NOT_IMPLEMENTED';
	string public constant ToAddressInvalid = 'TO_ADDRESS_INVALID';
	string public constant TransfersLocked = 'TRANSFERS_LOCKED';
	string public constant NoTransferWrappedNFT = 'NO_TRANSFER_WRAPPED_NFT';
	string public constant NFTAlreadyWrapped = 'NFT_ALREADY_WRAPPED';
	string public constant PropertyLocked = 'PROPERTY_LOCKED';
	string public constant InvalidPropertyType = 'INVALID_PROPERTY_TYPE';
	string public constant InvalidPermissionType = 'INVALID_PERMISSION_TYPE';
	string public constant InvalidTotalCopies = 'INVALID_TOTAL_COPIES';
	string public constant TotalCopiesExceeded = 'TOTAL_COPIES_EXCEEDED';
	string public constant InvalidTotalRemixes = 'INVALID_TOTAL_REMIXES';
	string public constant TotalRemixesExceeded = 'TOTAL_REMIXES_EXCEEDED';
	string public constant CopiesPerWalletExceeded =
		'COPIES_PER_WALLET_EXCEEDED';
	string public constant RemixesPerWalletExceeded =
		'REMIXES_PER_WALLET_EXCEEDED';
	string public constant NoPermission = 'NO_PERMISSION';
	string public constant InvalidChildGeneration = 'INVALID_CHILD_GENERATION';
	string public constant InvalidParent = 'INVALID_PARENT';
	string public constant ChildDepthExceeded = 'CHILD_DEPTH_EXCEEDED';
	string public constant MissingRequiredPermissions =
		'MISSING_REQUIRED_PERMISSIONS';
	string public constant MissingRequiredSplits = 'MISSING_REQUIRED_SPLITS';
	string public constant NoChildOfCopy = 'NO_CHILD_OF_COPY';
	string public constant NoCopyUnverified = 'NO_COPY_UNVERIFIED';
	string public constant MeemNotVerified = 'MEEM_NOT_VERIFIED';
	string public constant InvalidURI = 'INVALID_URI';
	string public constant InvalidMeemType = 'INVALID_MEEM_TYPE';
	string public constant InvalidToken = 'INVALID_TOKEN';
	string public constant AlreadyClipped = 'ALREADY_CLIPPED';
	string public constant NotClipped = 'NOT_CLIPPED';
	string public constant URILocked = 'URI_LOCKED';
	string public constant AlreadyReacted = 'ALREADY_REACTED';
	string public constant ReactionNotFound = 'REACTION_NOT_FOUND';
	string public constant IncorrectMsgValue = 'INCORRECT_MSG_VALUE';
	string public constant TotalOriginalsSupplyExceeded =
		'TOTAL_ORIGINALS_SUPPLY_EXCEEDED';
	string public constant OriginalsPerWalletExceeded =
		'ORIGINALS_PER_WALLET_EXCEEDED';
	string public constant MintingNotStarted = 'MINTING_NOT_STARTED';
	string public constant MintingFinished = 'MINTING_FINISHED';
	string public constant InvalidTokenCounter = 'INVALID_TOKEN_COUNTER';
	string public constant NotOwner = 'NOT_OWNER';
	string public constant AlreadyInitialized = 'ALREADY_INITIALIZED';
}

// TODO: Use custom errors when more widely supported

// error MissingRequiredRole(bytes32 requiredRole);

// error NotTokenOwner(uint256 tokenId);

// error NotTokenAdmin(uint256 tokenId);

// error InvalidNonOwnerSplitAllocationAmount(
// 	uint256 minAmount,
// 	uint256 maxAmount
// );

// error NoRenounceOthers();

// error InvalidZeroAddressQuery();

// error IndexOutOfRange(uint256 idx, uint256 max);

// error TokenNotFound(uint256 tokenId);

// error TokenAlreadyExists(uint256 tokenId);

// error NoApproveSelf();

// error NotApproved();

// error ERC721ReceiverNotImplemented();

// error ToAddressInvalid(address to);

// error NoTransferWrappedNFT(address parentAddress, uint256 parentTokenId);

// error NFTAlreadyWrapped(address parentAddress, uint256 parentTokenId);

// error PropertyLocked(address lockedBy);

// error InvalidPropertyType();

// error InvalidPermissionType();

// error InvalidTotalCopies(uint256 currentTotalCopies);

// error TotalCopiesExceeded();

// error InvalidTotalRemixes(uint256 currentTotalRemixes);

// error TotalRemixesExceeded();

// error CopiesPerWalletExceeded();

// error RemixesPerWalletExceeded();

// error NoPermission();

// error InvalidChildGeneration();

// error InvalidParent();

// error ChildDepthExceeded();

// error MissingRequiredPermissions();

// error MissingRequiredSplits();

// error NoChildOfCopy();

// error NoCopyUnverified();

// error MeemNotVerified();

// error InvalidURI();

// error InvalidMeemType();

// error InvalidToken();

// error AlreadyClipped();

// error NotClipped();

// error URILocked();

// error AlreadyReacted();

// error ReactionNotFound();

// error IncorrectMsgValue();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PropertyType, MeemProperties, URISource, MeemPermission, Split, PermissionType} from '../interfaces/MeemStandard.sol';
import {LibPart} from '../../royalties/LibPart.sol';

library InitEvents {
	event MeemContractInitialized(address contractAddress);
}

library AccessControlEvents {
	/**
	 * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
	 *
	 * `ADMIN_ROLE` is the starting admin for all roles, despite
	 * {RoleAdminChanged} not being emitted signaling this.
	 *
	 * _Available since v3.1._
	 */
	event MeemRoleAdminChanged(
		bytes32 indexed role,
		bytes32 indexed previousAdminRole,
		bytes32 indexed newAdminRole
	);

	/**
	 * @dev Emitted when `account` is granted `role`.
	 *
	 * `sender` is the account that originated the contract call, an admin role
	 * bearer except when using {AccessControl-_setupRole}.
	 */
	event MeemRoleGranted(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);

	/**
	 * @dev Emitted when `account` is revoked `role`.
	 *
	 * `sender` is the account that originated the contract call:
	 *   - if using `revokeRole`, it is the admin role bearer
	 *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
	 */
	event MeemRoleRevoked(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);

	event MeemRoleSet(
		bytes32 indexed role,
		address[] indexed account,
		address indexed sender
	);
}

library MeemERC721Events {
	/**
	 * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
	 */
	event MeemTransfer(
		address indexed from,
		address indexed to,
		uint256 indexed tokenId
	);

	/**
	 * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
	 */
	event MeemApproval(
		address indexed owner,
		address indexed approved,
		uint256 indexed tokenId
	);

	/**
	 * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
	 */
	event MeemApprovalForAll(
		address indexed owner,
		address indexed operator,
		bool approved
	);
}

library MeemBaseEvents {
	event MeemTotalOriginalsSupplySet(int256 totalOriginalsSupply);
	event MeemTotalOriginalsSupplyLocked(address lockedBy);

	event MeemMintPermissionsSet(MeemPermission[] mintPermissions);
	event MeemMintPermissionsLocked(address lockedBy);

	event MeemSplitsSet(Split[] splits);
	event MeemSplitsLocked(address lockedBy);

	event MeemOriginalsPerWalletSet(int256 originalsPerWallet);
	event MeemOriginalsPerWalletLocked(address lockedBy);

	event MeemIsTransferrableSet(bool isTransferrable);
	event MeemIsTransferrableLocked(address lockedBy);

	event MeemBaseMintDatesSet(
		int256 mintStartTimestamp,
		int256 mintEndTimestamp
	);
	event MeemBaseMintDatesLocked(address lockedBy);
}

library MeemEvents {
	event MeemPropertiesSet(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties props
	);
	event MeemTotalCopiesSet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalCopies
	);
	event MeemTotalCopiesLocked(
		uint256 tokenId,
		PropertyType propertyType,
		address lockedBy
	);
	event MeemCopiesPerWalletSet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalCopies
	);
	event MeemTotalRemixesSet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalRemixes
	);
	event MeemTotalRemixesLocked(
		uint256 tokenId,
		PropertyType propertyType,
		address lockedBy
	);
	event MeemRemixesPerWalletSet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalRemixes
	);
	event MeemCopiesPerWalletLocked(
		uint256 tokenId,
		PropertyType propertyType,
		address lockedBy
	);
	event MeemRemixesPerWalletLocked(
		uint256 tokenId,
		PropertyType propertyType,
		address lockedBy
	);

	event MeemURISourceSet(uint256 tokenId, URISource uriSource);

	event MeemURISet(uint256 tokenId, string uri);

	event MeemURILockedBySet(uint256 tokenId, address lockedBy);

	event MeemDataSet(uint256 tokenId, string data);

	event MeemMintDatesSet(
		uint256 tokenId,
		int256 mintStartTimestamp,
		int256 mintEndTimestamp
	);

	event MeemMintDatesLocked(uint256 tokenId, address lockedBy);

	event MeemClipped(uint256 tokenId, address addy);

	event MeemUnClipped(uint256 tokenId, address addy);

	event MeemPermissionsSet(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission[] permission
	);

	event MeemTokenReactionAdded(
		uint256 tokenId,
		address addy,
		string reaction,
		uint256 newTotalReactions
	);

	event MeemTokenReactionRemoved(
		uint256 tokenId,
		address addy,
		string reaction,
		uint256 newTotalReactions
	);

	event MeemTokenReactionTypesSet(uint256 tokenId, string[] reactionTypes);

	event MeemSplitsSet(
		uint256 tokenId,
		PropertyType propertyType,
		Split[] splits
	);
	// Rarible royalties event
	event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library LibPart {
	bytes32 public constant TYPE_HASH =
		keccak256('Part(address account,uint96 value)');

	struct Part {
		address payable account;
		uint96 value;
	}

	function hash(Part memory part) internal pure returns (bytes32) {
		return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
	}
}