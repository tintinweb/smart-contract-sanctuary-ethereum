// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Strings.sol";
import './AppStorage.sol';

/// @title  RAIR Metadata facet contract
/// @notice You can use this contract to administrate the metadata asociated to the Rair facet
/// @author Juan M. Sanchez M.
/// @dev 	Notice that this contract is inheriting from AccessControlAppStorageEnumerable721
contract RAIRMetadataFacet is AccessControlAppStorageEnumerable721 {
	bytes32 public constant CREATOR = keccak256("CREATOR");
	using Strings for uint256;

	/// @notice This event stores in the blockchain when the base code of all the tokens has an update in its URI
    /// @param  newURI 				Contains the new  base identifier for all the tokens
	/// @param  appendTokenIndex 	Contains the index of the tokens appended to the URI
	/// @param 	metadataExtension 	File extension (if exists)
	event UpdatedBaseURI(string newURI, bool appendTokenIndex, string metadataExtension);
	/// @notice This event stores in the blockchain when a token has a change in its URI
	/// @param  tokenId 			Contains the index of the token appended to the URI
    /// @param  newURI 				Contains the new identifier for the token
	event UpdatedTokenURI(uint tokenId, string newURI);
	/// @notice This event stores in the blockchain when a product has a change in its URI
	/// @param 	productId 			Contains the index of the product to change
    /// @param  newURI 				Contains the new identifier for the product
	/// @param  appendTokenIndex 	Contains the index of the token appended to the URI
	/// @param 	metadataExtension 	File extension (if exists)
	event UpdatedProductURI(uint productId, string newURI, bool appendTokenIndex, string metadataExtension);
	/// @notice This event stores in the blockchain when a range has a change in its URI
	/// @param 	rangeId 			Contains the index of the product to change
    /// @param  newURI 				Contains the new identifier for the product
	/// @param  appendTokenIndex 	Contains the index of the token appended to the URI
	/// @param 	metadataExtension 	File extension (if exists)
	event UpdatedRangeURI(uint rangeId, string newURI, bool appendTokenIndex, string metadataExtension);
	/// @notice This event stores in the blockchain when a contract has a change in its URI
    /// @param  newURI 				Contains the new identifier for the contract 
	event UpdatedContractURI(string newURI);
	/// @notice This event informs the new extension all metadata URIs will have appended at the end
	/// @dev 	It will be appended ONLY if the token ID has to also be appended
	/// @param 	newExtension The new extension for all the URIs
    event UpdatedURIExtension(string newExtension);


	// For OpenSea's Freezing
	event PermanentURI(string _value, uint256 indexed _id);

	/// @notice This function allows us to check if the token exist or not
	/// @param	tokenId	Contains the index of the token that we want to verify 
	/// @return bool Answer true if the token exist or false if not 
	function _exists(uint256 tokenId) internal view virtual returns (bool) {
		return s._owners[tokenId] != address(0);
	}

	/// @notice	Returns the token index inside the product
	/// @param	token	Token ID to find
	/// @return tokenIndex which contains the corresponding token index
	function tokenToCollectionIndex(uint token) public view returns (uint tokenIndex) {
		return token - s.products[s.tokenToProduct[token]].startingToken;
	}

	/// @notice	Updates the unique URI of all the tokens, but in a single transaction
	/// @dev 	This function is only available to an account with a `CREATOR` role
	/// @dev	Uses the single function so it also emits an event
	/// @dev 	This function requires that all the tokens have a corresponding URI
	/// @param	tokenIds	Token Indexes that will be given an URI
	/// @param	newURIs		New URIs to be set
	function setUniqueURIBatch(uint[] calldata tokenIds, string[] calldata newURIs) external onlyRole(CREATOR) {
		require(tokenIds.length == newURIs.length, "RAIR ERC721: Token IDs and URIs should have the same length");
		for (uint i = 0; i < tokenIds.length; i++) {
			setUniqueURI(tokenIds[i], newURIs[i]);
		}
	}
	
	/// @notice	Gives an individual token an unique URI
	/// @dev 	This function is only available to an account with a `CREATOR` role
	/// @dev	Emits an event so there's provenance
	/// @param	tokenId	Token Index that will be given an URI
	/// @param	newURI	New URI to be given
	function setUniqueURI(uint tokenId, string calldata newURI) public onlyRole(CREATOR) {
		s.uniqueTokenURI[tokenId] = newURI;
		emit UpdatedTokenURI(tokenId, newURI);
	}

	/// @notice  Updates the metadata extension added at the end of all tokens
    /// @dev     Must include the . before the extension
    /// @param extension     Extension to be added at the end of all contract wide tokens
    function setMetadataExtension(string calldata extension) external onlyRole(CREATOR) {
        require(bytes(extension)[0] == '.', "RAIR ERC721: Extension must start with a '.'");
        s._metadataExtension = extension;
        emit UpdatedURIExtension(s._metadataExtension);
    }

	/// @notice	Gives all tokens within a range a specific URI
    /// @dev	Emits an event so there's provenance
    /// @param	rangeId				Token Index that will be given an URI
    /// @param	newURI		    	New URI to be given
    /// @param	appendTokenIndex	Flag to append the token index at the end of the new URI
    function setRangeURI(
        uint rangeId,
        string calldata newURI,
        bool appendTokenIndex
    ) public onlyRole(CREATOR) {
        s.rangeURI[rangeId] = newURI;
        s.appendTokenIndexToRangeURI[rangeId] = appendTokenIndex;
        emit UpdatedRangeURI(rangeId, newURI, appendTokenIndex, s._metadataExtension);
    }

	/// @notice	Gives an individual token an unique URI
	/// @dev 	This function is only available to an account with a `CREATOR` role
	/// @dev	Emits an event so there's provenance
	/// @param	productId						Token Index that will be given an URI
	/// @param	newURI							New URI to be given
	/// @param	appendTokenIndexToProductURI 	If true, it will append the token index to the URI
	function setProductURI(uint productId, string calldata newURI, bool appendTokenIndexToProductURI) public onlyRole(CREATOR) {
		s.productURI[productId] = newURI;
		s.appendTokenIndexToProductURI[productId] = appendTokenIndexToProductURI;
		emit UpdatedProductURI(productId, newURI, appendTokenIndexToProductURI, s._metadataExtension);
	}

	/// @notice	This function use OpenSea's to freeze the metadata
	/// @dev 	This function is only available to an account with a `CREATOR` role
	/// @param tokenId Token Index that will be given an URI
	function freezeMetadata(uint tokenId) public onlyRole(CREATOR) {
		emit PermanentURI(tokenURI(tokenId), tokenId);
	}

	/// @notice	This function allow us to set a new contract URI
	/// @dev 	This function is only available to an account with a `CREATOR` role
	/// @param newURI New URI to be given
	function setContractURI(string calldata newURI) external onlyRole(CREATOR) {
		s.contractMetadataURI = newURI;
		emit UpdatedContractURI(newURI);
	}

	/// @notice	This function allow us to see the current URI of the contract
	/// @return string with the URI of the contract 
	function contractURI() public view returns (string memory) {
		return s.contractMetadataURI;
	}
	
	/// @notice	Sets the Base URI for ALL tokens
	/// @dev 	This function is only available to an account with a `CREATOR` role
	/// @dev	Can be overriden by the specific token URI
	/// @param	newURI	URI to be used
	/// @param	appendTokenIndexToBaseURI	URI to be used
	function setBaseURI(string calldata newURI, bool appendTokenIndexToBaseURI) external onlyRole(CREATOR) {
		s.baseURI = newURI;
		s.appendTokenIndexToBaseURI = appendTokenIndexToBaseURI;
		emit UpdatedBaseURI(newURI, appendTokenIndexToBaseURI, s._metadataExtension);
	}

	/// @notice	Returns a token's URI
    /// @dev	Will return unique token URI or product URI or contract URI
    /// @param	tokenId		Token Index to look for
	/// @return string with the URI of the toke that we are using
    function tokenURI(uint tokenId)
        public
        view
        returns (string memory)
    {
        // Unique token URI
        string memory URI = s.uniqueTokenURI[tokenId];
        if (bytes(URI).length > 0) {
            return URI;
        }

        // Range wide URI
        URI = s.rangeURI[s.tokenToRange[tokenId]];
        if (bytes(URI).length > 0) {
            if (s.appendTokenIndexToRangeURI[s.tokenToRange[tokenId]]) {
                return
                    string(
                        abi.encodePacked(
                            URI,
                            tokenToCollectionIndex(tokenId).toString(),
                            s._metadataExtension
                        )
                    );
            }
            return URI;
        }

        // Collection wide URI
        URI = s.productURI[s.tokenToProduct[tokenId]];
        if (bytes(URI).length > 0) {
            if (s.appendTokenIndexToProductURI[s.tokenToProduct[tokenId]]) {
                return
                    string(
                        abi.encodePacked(
                            URI,
                            tokenToCollectionIndex(tokenId).toString(),
                            s._metadataExtension
                        )
                    );
            }
            return URI;
        }

        URI = s.baseURI;
        if (s.appendTokenIndexToBaseURI) {
            return
                string(
                    abi.encodePacked(
                        URI,
                        tokenId.toString(),
                        s._metadataExtension
                    )
                );
        }
        return URI;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
	// August 2022 - Metadata File Extension Update
	mapping(uint => string) rangeURI;
	mapping(uint => bool) appendTokenIndexToRangeURI;
	string _metadataExtension;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}