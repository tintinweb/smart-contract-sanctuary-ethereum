// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import './AppStorage.sol';
/// @title  This is contract to manage the Rair token ranges facet
/// @notice You can use this contract to administrate ranges, transfers & minting of the tokens
/// @author Juan M. Sanchez M.
/// @dev 	Notice that this contract is inheriting from AccessControlAppStorageEnumerable721
contract RAIRRangesFacet is AccessControlAppStorageEnumerable721 {
	bytes32 public constant CREATOR = keccak256("CREATOR");

	/// @notice This event stores in the blockchain when the NFT range is correctly created
    /// @param  productIndex Contains the position where the product was indexed
	/// @param  start Contains the start position of the range of nft collection
	/// @param  end Contains the last NFT of the range collection
	/// @param  price Contains the selling price for the range of NFT
	/// @param  tokensAllowed Contains all the allowed NFT tokens in the range that are available for sell
	/// @param  lockedTokens Contains all the NFT tokens in the range that are unavailable for sell
	/// @param  name Contains the name for the created NFT collection range
	/// @param  rangeIndex Contains the position where the range was indexed
	event CreatedRange(uint productIndex, uint start, uint end, uint price, uint tokensAllowed, uint lockedTokens, string name, uint rangeIndex);
	/// @notice This event stores in the blockchain when the NFT range is correctly updated
    /// @param  rangeIndex Contains the position where the range was indexed
	/// @param  name Contains the name for the created NFT collection range
	/// @param  price Contains the selling price for the range of NFT
	/// @param  tokensAllowed Contains all the allowed NFT tokens in the range that are available for sell
	/// @param  lockedTokens Contains all the NFT tokens in the range that are unavailable for sell
	event UpdatedRange(uint rangeIndex, string name, uint price, uint tokensAllowed, uint lockedTokens);
	/// @notice This event stores in the blockchain when the NFT range trading is effectively locked  
    /// @param  rangeIndex Contains the position where the range was indexed
	/// @param  from Contains the starting NFT of the range that we want to lock
	/// @param  to Contains the last NFT of the range that we want to lock
	/// @param  lockedTokens Contains all the NFT tokens in the range that are unavailable for sell
	event TradingLocked(uint indexed rangeIndex, uint from, uint to, uint lockedTokens);
	/// @notice This event stores in the blockchain when the NFT range trading is effectively unlocked 
    /// @param  rangeIndex Contains the position where the range was indexed
	/// @param  from Contains the starting NFT of the range that we want to lock
	/// @param  to Contains the last NFT of the range that we want to lock
	event TradingUnlocked(uint indexed rangeIndex, uint from, uint to);

	// Auxiliary struct used to avoid Stack too deep errors
	struct rangeData {
		uint rangeLength;
		uint price;
		uint tokensAllowed;
		uint lockedTokens;
		string name;
	}

	/// @notice Verifies that the range exists
	/// @param	rangeID	Identification of the range to verify
	modifier rangeExists(uint rangeID) {
		require(s.ranges.length > rangeID, "RAIR ERC721 Ranges: Range does not exist");
		_;
	}

	/// @notice This functions verify if the current colecction exist or not
	/// @param	collectionId	Identification of the collection that we want to use
	modifier collectionExists(uint collectionId) {
		require(s.products.length > collectionId, "RAIR ERC721 Ranges: Collection does not exist");
		_;
	}

	/// @notice This functions return us the product that containt the selected range
	/// @dev 	This function requires that the rangeIndex_ points to an existing range 
	/// @param	rangeIndex_		Identification of the range to verify
	/// @return uint which indicates the index of the product
	function rangeToProduct(uint rangeIndex_) public view rangeExists(rangeIndex_) returns (uint) {
		return s.rangeToProduct[rangeIndex_];
	}

	/// @notice This functions allow us to check the information of the range
	/// @dev 	This function requires that the rangeIndex_ points to an existing range 
	/// @param	rangeId	Identification of the range to verify
	/// @return data 			Information about the range
	/// @return productIndex 	Contains the index of the product in the range
	function rangeInfo(uint rangeId) external view rangeExists(rangeId) returns(range memory data, uint productIndex) {
		data = s.ranges[rangeId];
		productIndex = s.rangeToProduct[rangeId];
	}

	/// @notice This functions shows is the range is currently locked or not 
	/// @dev 	This function requires that the rangeIndex_ points to an existing range 
	/// @param	rangeId	Identification of the range to verify
	/// @return bool with the current status of the range lock
	///			true for lock and false for unlocked
	function isRangeLocked(uint rangeId) external view rangeExists(rangeId) returns (bool) {
		return s.ranges[rangeId].lockedTokens > 0;
	}

	/// @notice This functions shows the information for the range of a product
	/// @param	collectionId	Index of the product to verify
	/// @param	rangeIndex		Index of the range to verify
	/// @return data 			Information about the range
	function productRangeInfo(uint collectionId, uint rangeIndex) external view collectionExists(collectionId) returns(range memory data) {
		require(s.products[collectionId].rangeList.length > rangeIndex, "RAIR ERC721 Ranges: Invalid range index");
		data = s.ranges[s.products[collectionId].rangeList[rangeIndex]];
	}

	/// @notice This functions allow us to update the information about a range
	/// @dev 	This function requires that the rangeIndex_ points to an existing range
	/// @dev 	This function is only available to an account with a `CREATOR` role
	/// @param	rangeId			Identification of the range to verify
	/// @param	name			Contains the name for the created NFT collection range
	/// @param	price_			Contains the selling price for the range of NFT
	/// @param	tokensAllowed_	Contains all the allowed NFT tokens in the range that are available for sell
	/// @param	lockedTokens_	Contains all the NFT tokens in the range that are unavailable for sell
	function updateRange(uint rangeId, string memory name, uint price_, uint tokensAllowed_, uint lockedTokens_) public rangeExists(rangeId) onlyRole(CREATOR) {
		require(price_ >= 100, "RAIR ERC721: Minimum price allowed is 100 wei");
		range storage selectedRange = s.ranges[rangeId];
		require(selectedRange.rangeEnd - selectedRange.rangeStart + 1 >= tokensAllowed_, "RAIR ERC721: Allowed tokens should be less than range's length");
		require(selectedRange.rangeEnd - selectedRange.rangeStart + 1 >= lockedTokens_, "RAIR ERC721: Locked tokens should be less than range's length");
		selectedRange.tokensAllowed = tokensAllowed_;
		if (lockedTokens_ > 0) {
			emit TradingLocked(rangeId, selectedRange.rangeStart, selectedRange.rangeEnd, lockedTokens_);
			selectedRange.lockedTokens = lockedTokens_;
		}
		selectedRange.rangeName = name;
		selectedRange.rangePrice = price_;
		emit UpdatedRange(rangeId, name, price_, tokensAllowed_, lockedTokens_);
	}

	/// @notice This functions allow us to know if a desidred range can be created or not
	/// @param	productId_	Contains the identification for the product
	/// @param	rangeStart_	Contains the tentative NFT to use as starting point of the range 
	/// @param	rangeEnd_	Contains the tentative NFT to use as ending point of the range
	/// @return bool With the answer if the range cant be creater or not
	function canCreateRange(uint productId_, uint rangeStart_, uint rangeEnd_) public view returns (bool) {
		uint[] memory rangeList = s.products[productId_].rangeList;
		for (uint i = 0; i < rangeList.length; i++) {
			if ((s.ranges[rangeList[i]].rangeStart <= rangeStart_ &&
					s.ranges[rangeList[i]].rangeEnd >= rangeStart_) || 
				(s.ranges[rangeList[i]].rangeStart <= rangeEnd_ &&
					s.ranges[rangeList[i]].rangeEnd >= rangeEnd_)) {
				return false;
			}
		}
		return true;
	}
	
	/// @notice This is a internal function that will create the NFT range if the requirements are meet
	/// @param	productId_		Contains the identification for the product
	/// @param	rangeLength_	Number of tokens contained in the range
	/// @param 	price_ 			Contains the selling price for the range of NFT
	/// @param 	tokensAllowed_ 	Contains all the allowed NFT tokens in the range that are available for sell
	/// @param 	lockedTokens_ 	Contains all the NFT tokens in the range that are unavailable for sell
	/// @param 	name_ 			Contains the name for the created NFT collection range
	function _createRange(
		uint productId_,
		uint rangeLength_,
		uint price_,
		uint tokensAllowed_,
		uint lockedTokens_,
		string memory name_
	) internal {
		// Sanity checks
		require(price_ >= 100, "RAIR ERC721: Minimum price allowed is 100 wei");
		require(rangeLength_ >= tokensAllowed_, "RAIR ERC721: Allowed tokens should be less than range's length");
		require(rangeLength_ >= lockedTokens_, "RAIR ERC721: Locked tokens should be less than range's length");
		product storage selectedProduct = s.products[productId_];
		uint lastTokenFromPreviousRange;
		if (selectedProduct.rangeList.length > 0) {
			lastTokenFromPreviousRange = s.ranges[selectedProduct.rangeList[selectedProduct.rangeList.length - 1]].rangeEnd + 1;
		}

		range storage newRange = s.ranges.push();
		uint rangeIndex = s.ranges.length - 1;

		require(lastTokenFromPreviousRange + rangeLength_ - 1 <= selectedProduct.endingToken , "RAIR ERC721: Range length exceeds collection limits!");

		newRange.rangeStart = lastTokenFromPreviousRange;
		// -1 because it includes the starting token
		newRange.rangeEnd = lastTokenFromPreviousRange + rangeLength_ - 1;
		newRange.tokensAllowed = tokensAllowed_;
		newRange.mintableTokens = rangeLength_;
		newRange.lockedTokens = lockedTokens_;
		if (lockedTokens_ > 0) {
			emit TradingLocked(rangeIndex, newRange.rangeStart, newRange.rangeEnd, newRange.lockedTokens);
		} else if (lockedTokens_ == 0) {
			emit TradingUnlocked(rangeIndex, newRange.rangeStart, newRange.rangeEnd);
		}
		newRange.rangePrice = price_;
		newRange.rangeName = name_;
		s.rangeToProduct[rangeIndex] = productId_;
		selectedProduct.rangeList.push(rangeIndex);

		emit CreatedRange(
			productId_,
			newRange.rangeStart,
			newRange.rangeEnd,
			newRange.rangePrice,
			newRange.tokensAllowed,
			newRange.lockedTokens,
			newRange.rangeName,
			rangeIndex
		);
	}

	/// @notice This function that will create the NFT range if the requirements are meet
	/// @dev 	This function is only available to an account with a `CREATOR` role
	/// @dev 	This function require thar the collection ID match a valid collection 
	/// @param	collectionId	Contains the identification for the product
	/// @param	rangeLength		Number of tokens contained in the range
	/// @param 	price 			Contains the selling price for the range of NFT
	/// @param 	tokensAllowed 	Contains all the allowed NFT tokens in the range that are available for sell
	/// @param 	lockedTokens 	Contains all the NFT tokens in the range that are unavailable for sell
	/// @param 	name 			Contains the name for the created NFT collection range
	function createRange(
		uint collectionId,
		uint rangeLength,
		uint price,
		uint tokensAllowed,
		uint lockedTokens,
		string calldata name
	) external onlyRole(CREATOR) collectionExists(collectionId) {
		_createRange(collectionId, rangeLength, price, tokensAllowed, lockedTokens, name);
	}

	/// @notice This function will create as many ranges as the data array requires
	/// @dev 	This function is only available to an account with a `CREATOR` role
	/// @dev 	This function require thar the collection ID match a valid collection 
	/// @param	collectionId	Contains the identification for the product
	/// @param	data 			An array with the data for all the ranges that we want to implement 
	function createRangeBatch(
		uint collectionId,
		rangeData[] calldata data
	) external onlyRole(CREATOR) collectionExists(collectionId) {
		require(data.length > 0, "RAIR ERC721: Empty array");
		for (uint i = 0; i < data.length; i++) {
			_createRange(collectionId, data[i].rangeLength, data[i].price, data[i].tokensAllowed, data[i].lockedTokens, data[i].name);
		}
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11; 

import '../../common/AccessControl.sol';

struct range {
	uint rangeStart;
	uint rangeEnd;
	uint tokensAllowed;
	uint mintableTokens;
	uint lockedTokens;
	uint rangePrice;
	string rangeName;
}

struct product {
	uint startingToken;
	uint endingToken;
	uint mintableTokens;
	string name;
	uint[] rangeList;
}

struct AppStorage721 {
	// ERC721
	string _name;
	string _symbol;
	mapping(uint256 => address) _owners;
	mapping(address => uint256) _balances;
	mapping(uint256 => address) _tokenApprovals;
	mapping(address => mapping(address => bool)) _operatorApprovals;
	// ERC721 Enumerable
	mapping(address => mapping(uint256 => uint256)) _ownedTokens;
	mapping(uint256 => uint256) _ownedTokensIndex;
	uint256[] _allTokens;
	mapping(uint256 => uint256) _allTokensIndex;
	// Access Control Enumerable
	mapping(bytes32 => RoleData) _roles;
	mapping(bytes32 => EnumerableSet.AddressSet) _roleMembers;
	// App
	string baseURI;
	address factoryAddress;
	uint16 royaltyFee;
	product[] products;
	range[] ranges;
	mapping(uint => uint) tokenToProduct;
	mapping(uint => uint) tokenToRange;
	mapping(uint => string) uniqueTokenURI;
	mapping(uint => string) productURI;
	mapping(uint => bool) appendTokenIndexToProductURI;
	bool appendTokenIndexToBaseURI;
	mapping(uint => uint[]) tokensByProduct;
	string contractMetadataURI;
	mapping(uint => uint) rangeToProduct;
	mapping(uint => bool) _minted;
	// Always add new variables at the end of the struct
}

library LibAppStorage721 {
	/// @notice this funtion set the storage of the diamonds 721 contracts 
	function diamondStorage() internal pure	returns (AppStorage721 storage ds) {
		assembly {
			ds.slot := 0
		}
	}
}

/// @title  This is contract to manage the access control of the RAIR token facet
/// @notice You can use this contract to administrate roles of the app market
/// @author Juan M. Sanchez M.
/// @dev 	Notice that this contract is inheriting from Context
contract AccessControlAppStorageEnumerable721 is Context {
	AppStorage721 internal s;

	using EnumerableSet for EnumerableSet.AddressSet;

	/// @notice This event stores in the blockchain when we change an admin role
    /// @param  role Contains the role we want to update
    /// @param  previousAdminRole contains the previous status of the role
	/// @param  newAdminRole contains the new status of the role
	event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
	/// @notice This event stores in the blockchain when we grant a role
    /// @param  role Contains the role we want to update
    /// @param  account contains the address that we want to grant the role
	/// @param  sender contains the address that is changing the role of the account
	event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
	/// @notice This event stores in the blockchain when we revoke a role
    /// @param  role Contains the role we want to update
    /// @param  account contains the address that we want to revoke the role
	/// @param  sender contains the address that is changing the role of the account
	event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

	modifier onlyRole(bytes32 role) {
		_checkRole(role, _msgSender());
		_;
	}

	/// @notice Allow us to renounce to a role
	/// @dev 	Currently you can only renounce to your own roles
	/// @param 	role Contains the role to remove from our account
	/// @param 	account Contains the account that has the role we want to update
	function renounceRole(bytes32 role, address account) public {
		require(account == _msgSender(), "AccessControl: can only renounce roles for self");
		_revokeRole(role, account);
	}

	/// @notice Allow us to grant a role to an account
	/// @dev 	This function is only available to an account with an Admin role
	/// @param 	role Contains the role that we want to grant
	/// @param 	account Contains the account that has the role we want to update
	function grantRole(bytes32 role, address account) public onlyRole(getRoleAdmin(role)) {
		_grantRole(role, account);
	}

	/// @notice Allow us to revoke a role to an account
	/// @dev 	This function is only available to an account with an Admin role
	/// @param 	role Contains the role that we want to revoke
	/// @param 	account Contains the account that has the role we want to update
	function revokeRole(bytes32 role, address account) public onlyRole(getRoleAdmin(role)) {
		_revokeRole(role, account);
	}

	/// @notice Allow us to check the if and account has a selected role
	/// @param 	role Contains the role that we want to verify
	/// @param 	account Contains the account address thay we want to verify
	function _checkRole(bytes32 role, address account) internal view {
		if (!hasRole(role, account)) {
			revert(
				string(
					abi.encodePacked(
						"AccessControl: account ",
						Strings.toHexString(uint160(account), 20),
						" is missing role ",
						Strings.toHexString(uint256(role), 32)
					)
				)
			);
		}
	}

	/// @notice Allow us to check the if and account has a selected role
	/// @param 	role Contains the role that we want to verify
	/// @param 	account Contains the account address thay we want to verify
	/// @return bool that indicates if an account has or not a role
	function hasRole(bytes32 role, address account) public view returns (bool) {
		return s._roles[role].members[account];
	}

	/// @notice Allow us to check the admin role that contains a role
	/// @param 	role Contains the role that we want to verify
	/// @return bytes that indicates if an account has or not an admin role
	function getRoleAdmin(bytes32 role) public view returns (bytes32) {
		return s._roles[role].adminRole;
	}

	/// @notice Allow us to check the address of an indexed position for the role list
	/// @param 	role Contains the role that we want to verify
	/// @param 	index Contains the indexed position to verify inside the role members list
	/// @return address that indicates the address indexed in that position
	function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
		return s._roleMembers[role].at(index);
	}

	/// @notice Allow us to check total members that has an selected role
	/// @param 	role Contains the role that we want to verify
	/// @return uint256 that indicates the total accounts with that role
	function getRoleMemberCount(bytes32 role) public view returns (uint256) {
		return s._roleMembers[role].length();
	}

	/// @notice Allow us to modify a rol and set it as an admin role
	/// @param 	role Contains the role that we want to modify
	/// @param 	adminRole Contains the admin role that we want to set
	function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
		bytes32 previousAdminRole = getRoleAdmin(role);
		s._roles[role].adminRole = adminRole;
		emit RoleAdminChanged(role, previousAdminRole, adminRole);
	}

	/// @notice Allow us to revoke a role to an account
	/// @param 	role Contains the role that we want to revoke
	/// @param 	account Contains the account that has the role we want to update
	function _revokeRole(bytes32 role, address account) internal {
		if (hasRole(role, account)) {
			s._roles[role].members[account] = false;
			emit RoleRevoked(role, account, _msgSender());
			s._roleMembers[role].remove(account);
		}
	}

	/// @notice Allow us to grant a new role to an account
	/// @dev 	Notice that this function override the behavior of
	/// @dev 	the _grantRole function inherited from AccessControlEnumerable
	/// @param 	role Contains the facet addresses and function selectors
    /// @param 	account Contains the facet addresses and function selectors
	function _grantRole(bytes32 role, address account) internal {
		if (!hasRole(role, account)) {
			s._roles[role].members[account] = true;
			emit RoleGranted(role, account, _msgSender());
			s._roleMembers[role].add(account);
		}
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11; 

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct RoleData {
	mapping(address => bool) members;
	bytes32 adminRole;
}
 
/// @title  A contract that administrate roles & access
/// @notice You can use this contract to modify and define the role of an user
abstract contract AccessControlEnumerable is Context {	
    /// @notice This event stores in the blockchain when an admin role changes
    /// @param  role Contains the admin role that we want to use 
    /// @param  previousAdminRole Contains the previous admin role
    /// @param  newAdminRole Contains the new admin role
	event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
	/// @notice This event stores in the blockchain when a role is granted
    /// @param  role Contains the admin role that we want to use 
    /// @param  account Contains the account we want to add to a new role
    /// @param  sender Contains the sender of the role petition
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    /// @notice This event stores in the blockchain when a role is revoked
    /// @param  role Contains the admin role that we want to use 
    /// @param  account Contains the account we want to add to a new role
    /// @param  sender Contains the sender of the role petition
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /// @notice Allow an user to quit an owned role
    /// @notice The account that sends the petition needs to be the same that will renounce to a role
    /// @param  role Contains the role that we want to use 
    /// @param  account Contains the account address to use.    
    function renounceRole(bytes32 role, address account) public {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");
        _revokeRole(role, account);
    }

    /// @notice Allow an admin to asign a new role to an account
    /// @param  role Contains the role that we want to use 
    /// @param  account Contains the account address to use. 
    function grantRole(bytes32 role, address account) public onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /// @notice Allow an admin to revoke a role to an account
    /// @param  role Contains the role that we want to use 
    /// @param  account Contains the account address to use. 
    function revokeRole(bytes32 role, address account) public onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /// @notice Allow to verify if the account has a role
    /// @param  role Contains the role that we want to use 
    /// @param  account Contains the account address to use. 
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /// @notice Allow to verify if the account has a role
    /// @param  role Contains the role that we want to verify 
    /// @param  account Contains the account address to check. 
    /// @return role in boolean, if the account has the selected role
    function hasRole(bytes32 role, address account) public view virtual returns (bool);

	/// @notice Allow us to verify the branch of roles asociated to an father role
    /// @param  role Contains the role that we want to verify
    /// @return bytes32 with the child role
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32);

    /// @notice Check if the account with the index has the desired role
    /// @param  role Contains the role that we want to use 
    /// @param  index Contains the index asociated to an account
    /// @return address of the account with the index position in the list of the desired role
	function getRoleMember(bytes32 role, uint256 index) public view virtual returns (address);

    /// @notice Allow to verify if the account has a role
    /// @param  role Contains the role that we want to verify
    /// @return uint256 wuth he total of members with the desired role 
	function getRoleMemberCount(bytes32 role) public view virtual returns (uint256);

    /// @param role Contains the role that we want to use 
    /// @param adminRole Contains the new admin role to use
	function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual;

    /// @notice Grants a role to an account
    /// @param  role Contains the role that we want to use 
    /// @param  account Contains the account address to use. 
	function _grantRole(bytes32 role, address account) internal virtual;

    /// @notice Revokes a role to an account 
    /// @param  role Contains the role that we want to use 
    /// @param  account Contains the account address to use. 
	function _revokeRole(bytes32 role, address account) internal virtual;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
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
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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