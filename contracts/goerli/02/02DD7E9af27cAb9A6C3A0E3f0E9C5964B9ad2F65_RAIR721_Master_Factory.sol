// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13; 

// Interfaces
import "latest-openzeppelin-contracts/utils/introspection/IERC1820Registry.sol";
import "latest-openzeppelin-contracts/token/ERC777/IERC777.sol";
import {IRAIR721_Deployer} from './RAIR721_Deployer.sol';
// Parent classes
import "latest-openzeppelin-contracts/token/ERC777/IERC777Recipient.sol";
import 'latest-openzeppelin-contracts/access/AccessControlEnumerable.sol';

// We only need the name of the deployment, there's no need to import the entire ERC721Metadata Interface
interface RAIR721Metadata {
	function name() external returns(string memory);
}

// 
interface IRAIR721_Single_Factory {
	// These are arrays on the real contract
	function creators(uint) external returns(address);
	function ownerToContracts(address, uint) external returns(address);
	// These are actual functions in the real contract
	function getCreatorsCount() external view returns(uint count);
	function getContractCountOf(address deployer) external view returns(uint count);
}

/// @title  RAIR ERC721 Factory
/// @notice Handles the deployment of ERC721 RAIR Tokens
/// @author Juan M. Sanchez M.
/// @dev 	Uses AccessControl for the reception of ERC777 tokens!
contract RAIR721_Master_Factory is IERC777Recipient, AccessControlEnumerable {
	IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
	
	bytes32 public constant OWNER = keccak256("OWNER");
	bytes32 public constant ERC777 = keccak256("ERC777");

	mapping(address => address[]) public ownerToContracts;
	mapping(address => address) public contractToOwner;

	mapping(address => uint) public deploymentCostForERC777;

	address public deployerAddress;
	address[] public creators;

	event NewTokensAccepted(address erc777, uint priceForNFT);
	event TokenNoLongerAccepted(address erc777);
	event DeploymentPriceUpdated(address erc777, uint priceToDeploy);

	event NewContractDeployed(address owner, uint id, address token, string contractName);
	
	event TokensWithdrawn(address recipient, address erc777, uint amount);

	/// @notice Factory Constructor
	/// @param  _pricePerToken    Tokens required for the deployment
	/// @param  _rairAddress 	  Address of the primary ERC777 contract (RAIR contract)
	constructor(uint _pricePerToken, address _rairAddress) {
		_ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
		_setRoleAdmin(OWNER, OWNER);
		_setRoleAdmin(ERC777, OWNER);
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(OWNER, msg.sender);
		_setupRole(ERC777, _rairAddress);
		deploymentCostForERC777[_rairAddress] = _pricePerToken;
		emit NewTokensAccepted(_rairAddress, _pricePerToken);
	}

	function setDeployerAddress(address deployerAddress_) public onlyRole(OWNER) {
		deployerAddress = deployerAddress_;
	}

	/// @notice Returns the number of addresses that have deployed a contract
	function getCreatorsCount() public view returns(uint count) {
		return creators.length;
	}

	/// @notice Returns the number of contracts deployed by an address
	/// @dev	Use alongside ownerToContracts for the full list of tokens 
	/// @param	deployer	Wallet address to query
	function getContractCountOf(address deployer) public view returns(uint count) {
		return ownerToContracts[deployer].length;
	}

	/// @notice Transfers tokens from the factory to any of the OWNER addresses
	/// @dev 	If the contract has less than the amount, the ERC777 contract will revert
	/// @dev 	AccessControl makes sure only an OWNER can withdraw
	/// @param 	erc777	Address of the ERC777 contract
	/// @param 	amount	Amount of tokens to withdraw
	function withdrawTokens(address erc777, uint amount) public onlyRole(OWNER) {
		require(hasRole(ERC777, erc777), "RAIR Factory: Specified contract isn't an approved erc777 contract");
		IERC777(erc777).send(msg.sender, amount, "Factory Withdraw");
		emit TokensWithdrawn(msg.sender, erc777, amount);
	}

	/// @notice	Adds an address to the list of allowed minters
	/// @param	_erc777Address	Address of the new Token
	function add777Token(address _erc777Address, uint _pricePerToken) public onlyRole(OWNER) {
		grantRole(ERC777, _erc777Address);
		deploymentCostForERC777[_erc777Address] = _pricePerToken;
		emit NewTokensAccepted(_erc777Address, _pricePerToken);
	}

	/// @notice	Removes an address from the list of allowed minters
	/// @param	_erc777Address	Address of the Token
	function remove777Token(address _erc777Address) public onlyRole(OWNER) {
		revokeRole(ERC777, _erc777Address);
		deploymentCostForERC777[_erc777Address] = 0;
		emit TokenNoLongerAccepted(_erc777Address);
	}

	function updateDeploymentPrice(address _erc777Address, uint _deploymentPrice) public onlyRole(OWNER) {
		_checkRole(ERC777, _erc777Address);
		deploymentCostForERC777[_erc777Address] = _deploymentPrice;
		emit DeploymentPriceUpdated(_erc777Address, _deploymentPrice);
	}

	/// @notice Function called by an ERC777 when they send tokens
	/// @dev    This is our deployment mechanism for ERC721 contracts!
	/// @param operator		The operator calling the send() function
	/// @param from			The owner of the tokens
	/// @param to			The recipient of the tokens
	/// @param amount		The number of tokens sent
	/// @param userData		bytes sent from the send call
	/// @param operatorData	bytes sent from the operator
	function tokensReceived(
		address operator,
		address from,
		address to,
		uint256 amount,
		bytes calldata userData,
		bytes calldata operatorData
	) external onlyRole(ERC777) override {
		require(to == address(this), "RAIR Factory: Token received is not this address");
		require(deploymentCostForERC777[msg.sender] > 0, "RAIR Factory: Deployments for this token are currently disabled");
		require(amount >= deploymentCostForERC777[msg.sender], 'RAIR Factory: not enough RAIR tokens to deploy a contract');
		require(deployerAddress != address(0), "RAIR Factory: No deployer found!");

		if (amount - (deploymentCostForERC777[msg.sender]) > 0) {
			IERC777(msg.sender).send(from, amount - (deploymentCostForERC777[msg.sender]), userData);
		}
		address[] storage tokensFromOwner = ownerToContracts[from];
		
		if (tokensFromOwner.length == 0) {
			creators.push(from);
		}

		address newToken = IRAIR721_Deployer(deployerAddress).deployContract(from, string(userData));

		tokensFromOwner.push(newToken);
		contractToOwner[newToken] = from;
		emit NewContractDeployed(from, tokensFromOwner.length, newToken, string(userData));
	}

	/// @notice 	Imports deployment data from previous factories
	/// @dev 		This way we can recover data in case of an update / bugfix
	/// @dev 		We are not removing data from the imported factories, so don't run this twice!
	/// @param 		factoryAddress   	Address of the factory to import
	function importData(address factoryAddress) public onlyRole(OWNER) {
		IRAIR721_Single_Factory instance = IRAIR721_Single_Factory(factoryAddress);
		
		uint numberOfCreators = instance.getCreatorsCount();
		
		for (uint i; i < numberOfCreators; i++) {
			
			address creatorAddress = instance.creators(i);
			uint numberOfDeployments = instance.getContractCountOf(creatorAddress);
			
			for (uint j; j < numberOfDeployments; j++) {
				address deploymentAddress = instance.ownerToContracts(creatorAddress, j);
				
				if (ownerToContracts[creatorAddress].length == 0) {
					creators.push(creatorAddress);
				}
				ownerToContracts[creatorAddress].push(deploymentAddress);
				contractToOwner[deploymentAddress] = creatorAddress;

				emit NewContractDeployed(
					creatorAddress,
					ownerToContracts[creatorAddress].length,
					deploymentAddress,
					RAIR721Metadata(deploymentAddress).name()
				);
			}
		}
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

// Parents
import "latest-openzeppelin-contracts/access/AccessControlEnumerable.sol";
import "../Tokens/RAIR721_Contract.sol";

interface IRAIR721_Deployer {
    function deployContract(address creator, string calldata title)
        external
        returns (address deploymentAddress);
}

// @title   RAIR ERC721 Deployer
// @notice  This contract is in charge of the deployment of the ERC721 RAIR Tokens
// @dev     This contract should be called by the master factory
contract RAIR721_Deployer is IRAIR721_Deployer, AccessControlEnumerable {
    bytes32 public constant MAINTAINER = keccak256("MAINTAINER");
    bytes32 public constant FACTORY = keccak256("FACTORY");

    /// @notice Factory Constructor
    /// @param  factoryAddress 		Address of the factory able to call the deploy function
    constructor(address factoryAddress) {
        _setRoleAdmin(MAINTAINER, MAINTAINER);
        _setRoleAdmin(FACTORY, MAINTAINER);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MAINTAINER, msg.sender);
        _setupRole(FACTORY, factoryAddress);
    }

    // @notice  Deploys the RAIR721 contracts
    // @dev     Can only be called by a FACTORY
    // @param   creator Contains the address of the sender of the ERC777 tokens
    // @param   title   Contains the name of the contract deployment
    function deployContract(address creator, string calldata title)
        external
        override
        onlyRole(FACTORY)
        returns (address deploymentAddress)
    {
        RAIR721_Contract newToken = new RAIR721_Contract(title, creator);
        return address(newToken);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import 'latest-openzeppelin-contracts/token/ERC721/ERC721.sol';
import 'latest-openzeppelin-contracts/access/AccessControl.sol';
import "latest-openzeppelin-contracts/utils/introspection/ERC165.sol";
import "latest-openzeppelin-contracts/utils/Strings.sol";
import "./IERC2981.sol";
import "./IRAIR721_Contract.sol";

/// @title  Extended ERC721 contract for the RAIR system
/// @notice Uses ERC2981 and ERC165 for standard royalty info
/// @notice Uses AccessControl for the minting mechanisms
/// @author Juan M. Sanchez M.
/// @dev    Ideally generated by a RAIR Token Factory
contract RAIR721_Contract is IERC2981, ERC165, IRAIR721_Contract, ERC721, AccessControl {
	// Allows the conversion of numbers to strings (used in the token URI functions)
	using Strings for uint;

	// Auxiliary struct used to avoid Stack too deep errors
	struct rangeData {
		uint rangeLength;
		uint price;
		uint tokensAllowed;
		uint lockedTokens;
		string name;
	}
	
	mapping(uint => uint) public tokenToCollection;
	mapping(uint => uint) public tokenToRange;
	mapping(uint => uint) public rangeToCollection;
	
	//URIs
	mapping(uint => string) internal uniqueTokenURI;
	mapping(uint => string) internal collectionURI;
	mapping(uint => bool) internal appendTokenIndexToCollectionURI;
	
	string internal baseURI;
	string internal contractMetadataURI;

	bool appendTokenIndexToContractURI;
	bool _requireTrader;

	range[] private _ranges;
	collection[] private _collections;

	// Roles
	bytes32 public constant MINTER = keccak256("MINTER");
	bytes32 public constant TRADER = keccak256("TRADER");
	
	address public creatorAddress;
	address public factory;
	string private _symbol;
	uint16 private _royaltyFee;

	/// @notice	Makes sure the collection exists before doing changes to it
	/// @param	collectionID	Collection to verify
	modifier collectionExists(uint collectionID) {
		require(_collections.length > collectionID, "RAIR ERC721: Collection does not exist");
		_;
	}

	/// @notice	Makes sure the range exists
	/// @param	rangeIndex	Range to verify
	modifier rangeExists(uint rangeIndex) {
		require(_ranges.length > rangeIndex, "RAIR ERC721: Range does not exist");
		_;
	}

	/// @notice	Sets up the role system from AccessControl
	/// @dev	RAIR is the default symbol for the token, this can be updated with setTokenSymbol
	/// @param	_contractName	Name of the contract
	/// @param	_creatorAddress	Address of the creator of the contract
	constructor(
		string memory _contractName,
		address _creatorAddress
	) ERC721(_contractName, "RAIR") {
		factory = msg.sender;
		_symbol = "RAIR";
		_royaltyFee = 30000;
		_setupRole(DEFAULT_ADMIN_ROLE, _creatorAddress);
		_setupRole(MINTER, _creatorAddress);
		_setupRole(TRADER, _creatorAddress);
		_requireTrader = true;
		creatorAddress = _creatorAddress;
	}

	// @notice 	Transfers the ownership of a contract to a new address
	// @param 	newOwner 	Address of the new owner of the contract
	function transferOwnership(address newOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
		_grantRole(DEFAULT_ADMIN_ROLE, newOwner);
		creatorAddress = newOwner;
		renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	// @notice 	Updates the royalty fee used by the 2981 standard
	// @param 	newRoyalty 	Percentage that should be sent to the owner of the contract (3 decimals, 30% = 30000)
	function setRoyaltyFee(uint16 newRoyalty) public onlyRole(DEFAULT_ADMIN_ROLE) {
		_royaltyFee = newRoyalty;
	}

	// @notice 	Updates the token symbol
	// @param 	newSymbol 	New symbol to be returned from the symbol() function
	function setTokenSymbol(string calldata newSymbol) external onlyRole(DEFAULT_ADMIN_ROLE) {
		_symbol = newSymbol;
	}

	// @notice 	Returns the symbol for this contract
	// @dev 	By default, the symbol is RAIR
	function symbol() public view override returns (string memory) {
		return _symbol;
	}

	// @notice 	Enables or disables the requirement of the TRADER role to do NFT transfers 
	function requireTrader(bool required) public onlyRole(DEFAULT_ADMIN_ROLE) {
		_requireTrader = required;
	}

	// @notice 	Emits an event that OpenSea recognizes as a signal to never update the metadata for this token
	// @dev 	The metadata can still be updated, but OpenSea won't update it on their platform
	// @param 	tokenId 	Identifier of the token to be frozen
	function freezeMetadata(uint tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
		emit PermanentURI(tokenURI(tokenId), tokenId);
	}

	// @notice 	Updates the URL that OpenSea uses to fetch the contract's metadata
	// @param 	newURI 	URL of the metadata for the token
	function setContractURI(string calldata newURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
		contractMetadataURI = newURI;
		emit UpdatedContractURI(newURI);
	}

	// @notice 	Returns the metadata for the entire contract
	// @dev 	Not the NFTs, this is information about the contract itself
	function contractURI() public view returns (string memory) {
		return contractMetadataURI;
    }
	
	/// @notice	Sets the Base URI for ALL tokens
	/// @dev	Can be overriden by the collection-wide URI or the specific token URI
	/// @param	newURI	URI to be used
	function setBaseURI(string calldata newURI, bool appendTokenIndex) external onlyRole(DEFAULT_ADMIN_ROLE) {
		baseURI = newURI;
		appendTokenIndexToContractURI = appendTokenIndex;
		emit UpdatedBaseURI(newURI, appendTokenIndex);
	}

	/// @notice	Overridden function from the ERC721 contract that returns our
	///			variable base URI instead of the hardcoded URI
	function _baseURI() internal view override(ERC721) returns (string memory) {
		return baseURI;
	}

	/// @notice	Updates the unique URI of a token, but in a single transaction
	/// @dev	Uses the single function so it also emits an event
	/// @param	tokenIds	Token Indexes that will be given an URI
	/// @param	newURIs		New URIs to be set
	function setUniqueURIBatch(uint[] calldata tokenIds, string[] calldata newURIs) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(tokenIds.length == newURIs.length, "RAIR ERC721: Token IDs and URIs should have the same length");
		for (uint i = 0; i < tokenIds.length; i++) {
			setUniqueURI(tokenIds[i], newURIs[i]);
		}
	}
	
	/// @notice	Gives an individual token an unique URI
	/// @dev	Emits an event so there's provenance
	/// @param	tokenId	Token Index that will be given an URI
	/// @param	newURI	New URI to be given
	function setUniqueURI(uint tokenId, string calldata newURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
		uniqueTokenURI[tokenId] = newURI;
		emit UpdatedTokenURI(tokenId, newURI);
	}

	/// @notice	Gives an individual token an unique URI
	/// @dev	Emits an event so there's provenance
	/// @param	collectionId	Token Index that will be given an URI
	/// @param	newURI		New URI to be given
	function setCollectionURI(uint collectionId, string calldata newURI, bool appendTokenIndex) public onlyRole(DEFAULT_ADMIN_ROLE) {
		collectionURI[collectionId] = newURI;
		appendTokenIndexToCollectionURI[collectionId] = appendTokenIndex;
		emit UpdatedProductURI(collectionId, newURI, appendTokenIndex);
	}

	/// @notice	Returns a token's URI
	/// @dev	Will return unique token URI or product URI or contract URI
	/// @param	tokenId		Token Index to look for
	function tokenURI(uint tokenId) public view override(ERC721) returns (string memory) {
		// Unique token URI
		string memory URI = uniqueTokenURI[tokenId];
		if (bytes(URI).length > 0) {
			return URI;
		}

		// Collection wide URI
		URI = collectionURI[tokenToCollection[tokenId]];
		if (bytes(URI).length > 0) {
			if (appendTokenIndexToCollectionURI[tokenToCollection[tokenId]]) {
				return string(abi.encodePacked(URI, tokenToCollectionIndex(tokenId).toString()));
			}
			return URI;
		}

		URI = baseURI;
		if (appendTokenIndexToContractURI) {
			return super.tokenURI(tokenId);
		}
		return URI;
	}

	/// @notice	Creates a subdivision of tokens inside the contract (collection is the same as product)
	/// @dev	The collections are generated sequentially, there can be no gaps between collections
	/// @param	_collectionName 	Name of the collection
	/// @param	_copies				Amount of tokens inside the collection
	function createProduct(string memory _collectionName, uint _copies) public onlyRole(DEFAULT_ADMIN_ROLE) {
		uint lastTokenFromPreviousCollection;
		if (_collections.length != 0) {
			lastTokenFromPreviousCollection = _collections[_collections.length - 1].endingToken + 1;
		}
		
		collection storage newCollection = _collections.push();

		newCollection.startingToken = lastTokenFromPreviousCollection;
		// -1 because we include the initial token
		newCollection.endingToken = newCollection.startingToken + _copies - 1;
		newCollection.name = string(_collectionName);

		emit CreatedCollection(_collections.length - 1, _collectionName, lastTokenFromPreviousCollection, _copies);
	}

	/// @notice This function will create ranges in batches
	/// @dev 	There isn't any gas savings here
	/// @param	collectionId	Contains the identification for the product
	/// @param	data 			An array with the data for all the ranges that we want to implement 
	function createRangeBatch(
		uint collectionId,
		rangeData[] calldata data
	) external onlyRole(DEFAULT_ADMIN_ROLE) collectionExists(collectionId) {
		require(data.length > 0, "RAIR ERC721: Empty array");
		for (uint i = 0; i < data.length; i++) {
			_createRange(
				collectionId,
				data[i].rangeLength,
				data[i].tokensAllowed,
				data[i].lockedTokens,
				data[i].price,
				data[i].name
			);
		}
	}

	/// @notice Creates a range inside a collection
	/// @dev 	This function is only available to an account with the `DEFAULT_ADMIN_ROLE` role
	/// @dev 	This function require thar the collection ID match a valid collection
	/// @param	collectionId	Contains the identification for the product
	/// @param	rangeLength		Number of tokens to be contained in this new range
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
	) external onlyRole(DEFAULT_ADMIN_ROLE) collectionExists(collectionId) {
		_createRange(collectionId, rangeLength, price, tokensAllowed, lockedTokens, name);
	}

	/// @notice This is a internal function that will create the NFT range if the requirements are met
	/// @param	collectionIndex		Collection identifier
	/// @param	_rangeLength		Number of NFTs in the range 
	/// @param 	_allowedTokens 		Contains all the allowed NFT tokens in the range that are available for sell
	/// @param 	_lockedTokens 		Contains all the NFT tokens in the range that are unavailable for sell
	/// @param 	_price 				Contains the selling price for the range of NFT
	/// @param 	_name 				Contains the name for the created NFT collection range
	function _createRange(
		uint collectionIndex,
		uint _rangeLength,
		uint _allowedTokens,
		uint _lockedTokens,
		uint _price,
		string calldata _name
	) internal {
		collection storage selectedCollection =  _collections[collectionIndex];

		uint nextSequentialToken = selectedCollection.startingToken;
		if (selectedCollection.rangeList.length > 0) {
			nextSequentialToken = (_ranges[selectedCollection.rangeList[selectedCollection.rangeList.length - 1]]).rangeEnd;
			nextSequentialToken++;
		}

		// -1 because it includes the first token inside the range
		require(nextSequentialToken + _rangeLength - 1 <= selectedCollection.endingToken, 'RAIR ERC721: Invalid range length');
		require(_allowedTokens <= _rangeLength, "RAIR ERC721: Number of allowed tokens must be less or equal than the range's length");
		require(_lockedTokens <= _rangeLength, "RAIR ERC721: Number of locked tokens must be less or equal than the range's length");
		require(_price >= 100, "RAIR ERC721: Minimum price for a range is 100");

		range storage newRange = _ranges.push();

		newRange.rangeStart = nextSequentialToken;
		newRange.rangeEnd = nextSequentialToken + _rangeLength - 1;
		newRange.mintableTokens = _rangeLength;
		newRange.tokensAllowed = _allowedTokens;
		newRange.lockedTokens = _lockedTokens;
		newRange.rangePrice = _price;
		newRange.rangeName = _name;

		rangeToCollection[_ranges.length - 1] = collectionIndex;
		
		// No need to initialize minted tokens, the default value is 0

		selectedCollection.rangeList.push(_ranges.length - 1);

		emit CreatedRange(
			collectionIndex,
			newRange.rangeStart,
			newRange.rangeEnd,
			newRange.rangePrice,
			newRange.tokensAllowed,
			newRange.lockedTokens,
			newRange.rangeName,
			_ranges.length - 1
		);
	}

	/// @notice	Updates a range
	/// @dev 	Because they are sequential, the length of the range can't be modified
	/// @param	rangeId 			Index of the collection on the contract
	/// @param	name 				Name of the range
	/// @param	price_ 				Price for the tokens in the range
	/// @param	tokensAllowed_ 		Number of tokens allowed to be sold
	/// @param	lockedTokens_ 		Number of tokens that have to be minted in order to unlock transfers
	function updateRange(
		uint rangeId,
		string memory name,
		uint price_,
		uint tokensAllowed_,
		uint lockedTokens_
	) external onlyRole(DEFAULT_ADMIN_ROLE) rangeExists(rangeId) {
		range storage selectedRange =  _ranges[rangeId];

		require(price_ >= 100, "RAIR ERC721: Minimum price for a range is 100");
		require(tokensAllowed_ <= selectedRange.mintableTokens, "RAIR ERC721: Tokens allowed should be less than the number of mintable tokens");
		require(lockedTokens_ <= selectedRange.mintableTokens, "RAIR ERC721: Locked tokens should be less than the number of mintable tokens");

		selectedRange.tokensAllowed = tokensAllowed_;
		if (lockedTokens_ > 0) {
			emit TradingLocked(rangeId, selectedRange.rangeStart, selectedRange.rangeEnd, lockedTokens_);
			selectedRange.lockedTokens = lockedTokens_;
		}
		selectedRange.rangePrice = price_;
		selectedRange.rangeName = name;

		emit UpdatedRange(
			rangeId,
			name,
			price_,
			tokensAllowed_,
			lockedTokens_
		);
	}

	/// @notice	Returns the number of collections on the contract
	/// @dev	Use with get collection to list all of the collections
	function getCollectionCount() external view override(IRAIR721_Contract) returns(uint) {
		return _collections.length;
	}

	/// @notice	Returns information about a collection
	/// @param	collectionIndex	Index of the collection
	function getCollection(uint collectionIndex) external override(IRAIR721_Contract) view returns(collection memory) {
		return  _collections[collectionIndex];
	}

	/// @notice	Returns whether or not an address has an NFT in a collection
	/// @param	userAddress			User to search
	/// @param	collectionIndex		Collection to search
	/// @param	startingToken		Starting token within the collection
	/// @param	endingToken			Ending token within the collection
	function hasTokenInCollection(
		address userAddress,
		uint collectionIndex,
		uint startingToken,
		uint endingToken
	) public view returns (bool) {
		collection memory aux = _collections[collectionIndex];
		require(endingToken + aux.startingToken < aux.endingToken, "RAIR721: Token validation out of bounds!");
		return _hasTokenInRange(userAddress, startingToken + aux.startingToken, endingToken + aux.startingToken);
	}

	/// @notice 	Loops over the tokens in a specific range of tokens looking for one that belongs to the user
	/// @dev 		Loops are expensive in solidity, do not use this in a function that requires gas.
	/// @param 		userAddress 	Address that must be found in the range of tokens
	/// @param 		startingToken 	Start of the range
	/// @param 		endingToken 	End of the range
	function _hasTokenInRange(
		address userAddress,
		uint startingToken,
		uint endingToken
	) internal view returns (bool) {
		for (uint i = startingToken; i < endingToken; i++) {
			if (ownerOf(i) == userAddress) {
				return true;
			}
		}
		return false;
	}

	/// @notice	Translates the unique index of an NFT to it's collection index
	/// @param	token	Token ID to find
	function tokenToCollectionIndex(uint token) public view returns (uint tokenIndex) {
		return token - _collections[tokenToCollection[token]].startingToken;
	} 

	/// @notice	Finds the first token inside a collection that doesn't have an owner
	/// @param	collectionID	Index of the collection to search
	/// @param	startingIndex	Starting token for the search
	/// @param	endingIndex		Ending token for the search
	function getNextSequentialIndex(uint collectionID, uint startingIndex, uint endingIndex) public view collectionExists(collectionID) returns(uint nextIndex) {
		collection memory currentCollection = _collections[collectionID];
		return _getNextSequentialIndexInRange(currentCollection.startingToken + startingIndex, currentCollection.startingToken + endingIndex);
	}

	/// @notice		Loops through a range of tokens and returns the first token without an owner
	/// @dev 		Loops are expensive in solidity, do not use this in a gas-consuming function
	/// @param 		startingToken 	Starting token for the search
	/// @param 		endingToken 	Ending token for the search
	function _getNextSequentialIndexInRange(uint startingToken, uint endingToken) internal view returns (uint nextIndex) {
		for (nextIndex = startingToken; nextIndex <= endingToken; nextIndex++) {
			if (!_exists(nextIndex)) {
				break;
			}
		}
		require(startingToken <= nextIndex && nextIndex <= endingToken, "RAIR ERC721: There are no available tokens in this range.");
	}

	/// @notice This functions allow us to check the information of the range
	/// @dev 	This function requires that the rangeIndex_ points to an existing range 
	/// @param	rangeIndex		Identification of the range to verify
	/// @return data 			Information about the range
	/// @return productIndex 	Contains the index of the product in the range
	function rangeInfo(uint rangeIndex) external view override(IRAIR721_Contract) rangeExists(rangeIndex) returns(range memory data, uint productIndex) {
		data = _ranges[rangeIndex];
		productIndex = rangeToCollection[rangeIndex];
	}

	/// @notice	Verifies if the range where a token is located is locked or not
	/// @param	_tokenId	Index of the token to search
	function isTokenLocked(uint256 _tokenId) public view returns (bool) {
		return _ranges[tokenToRange[_tokenId]].lockedTokens > 0;
	}

	/// @notice	Mints a specific token within a range
	/// @dev	Has to be used alongside getNextSequentialIndex to simulate a sequential minting
	/// @dev	Anyone that wants a specific token just has to call this function with the index they want
	/// @param	buyerAddress		Address of the new token's owner
	/// @param	rangeIndex			Index of the range
	/// @param	indexInCollection	Index of the token inside the collection
	function mintFromRange(
		address buyerAddress,
		uint rangeIndex,
		uint indexInCollection
	)
		external
		override(IRAIR721_Contract)
		onlyRole(MINTER)
		rangeExists(rangeIndex)
	{
		range storage selectedRange = _ranges[rangeIndex];
		collection storage selectedCollection = _collections[rangeToCollection[rangeIndex]];

		require(selectedRange.tokensAllowed > 0, "RAIR ERC721: Cannot mint more tokens from this range");
		require(
			selectedRange.rangeStart <= selectedCollection.startingToken + indexInCollection &&
				selectedCollection.startingToken + indexInCollection <= selectedRange.rangeEnd,
			"RAIR ERC721: Invalid token index"
		);
		
		_safeMint(buyerAddress,  selectedCollection.startingToken + indexInCollection );
		
		tokenToRange[ selectedCollection.startingToken + indexInCollection ] = rangeIndex;
		tokenToCollection[ selectedCollection.startingToken + indexInCollection ] = rangeToCollection[rangeIndex];
		selectedRange.tokensAllowed--;
		
		if (selectedRange.lockedTokens > 0) {
			selectedRange.lockedTokens--;
			if (selectedRange.lockedTokens == 0) {
				emit TradingUnlocked(rangeIndex, selectedRange.rangeStart, selectedRange.rangeEnd);
			}
		}
	}

	/// @notice Returns the fee for the NFT sale
	/// @param _tokenId - the NFT asset queried for royalty information
	/// @param _salePrice - the sale price of the NFT asset specified by _tokenId
	/// @return receiver - address of who should be sent the royalty payment
	/// @return royaltyAmount - the royalty payment amount for _salePrice sale price
	function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
		external
		view
		override(IRAIR721_Contract, IERC2981)
		returns
		(address receiver, uint256 royaltyAmount)
	{
		require(_exists(_tokenId), "RAIR ERC721: Royalty query for a non-existing token");
		return (creatorAddress, (_salePrice * _royaltyFee) / 100000);
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165, AccessControl, ERC721, IERC2981) returns (bool) {
		return interfaceId == type(IERC2981).interfaceId
			|| super.supportsInterface(interfaceId);
	}

	/// @notice Hook being called before every transfer
	/// @dev	Locks and the requirement of the TRADER role happe here
	/// @param	_from		Token's original owner
	/// @param	_to			Token's new owner
	/// @param	_tokenId	Token's ID
	function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override(ERC721) {
		// If the transfer isn't to mint (from = address(0)) and it's not a burn (to = address(0))
		if (_from != address(0) && _to != address(0)) {
			// 
			if (_ranges.length > 0 && rangeToCollection[tokenToRange[_tokenId]] == tokenToCollection[_tokenId]) {
				require(_ranges[tokenToRange[_tokenId]].lockedTokens == 0, "RAIR ERC721: Transfers for this range are currently locked");
			}
			if (_requireTrader) {
				_checkRole(TRADER, msg.sender);
			}
		} 
		super._beforeTokenTransfer(_from, _to, _tokenId);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10; 

interface IERC2981 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256,bytes)")) == 0xc155531d
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0xc155531d;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _value sale price
    function royaltyInfo(
    	uint256 _tokenId,
    	uint256 _salePrice)
    external returns (
    	address receiver,
    	uint256 royaltyAmount);

    /// @notice Informs callers that this contract supports ERC2981
    /// @dev If `_registerInterface(_INTERFACE_ID_ERC2981)` is called
    ///      in the initializer, this should be automatic
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @return `true` if the contract implements
    ///         `_INTERFACE_ID_ERC2981` and `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13; 

import 'latest-openzeppelin-contracts/token/ERC721/IERC721.sol';

interface IRAIR721_Contract is IERC721 {
	struct range {
		uint rangeStart;
		uint rangeEnd;
		uint tokensAllowed;
		uint mintableTokens;
		uint lockedTokens;
		uint rangePrice;
		string rangeName;
	}

	struct collection {
		uint startingToken;
		uint endingToken;
		string name;
		uint[] rangeList;
	}

	event CreatedCollection(uint indexed collectionIndex, string collectionName, uint startingToken, uint collectionLength);

	event CreatedRange(
		uint collectionIndex,
		uint start,
		uint end,
		uint price,
		uint tokensAllowed,
		uint lockedTokens,
		string name,
		uint rangeIndex
	);
	event UpdatedRange(uint rangeIndex, string name, uint price, uint tokensAllowed, uint lockedTokens);
	event TradingLocked(uint indexed rangeIndex, uint from, uint to, uint lockedTokens);
	event TradingUnlocked(uint indexed rangeIndex, uint from, uint to);

	event UpdatedBaseURI(string newURI, bool appendTokenIndex);
	event UpdatedTokenURI(uint tokenId, string newURI);
	event UpdatedProductURI(uint productId, string newURI, bool appendTokenIndex);
	event UpdatedContractURI(string newURI);

	// For OpenSea's Freezing
	event PermanentURI(string _value, uint256 indexed _id);

	// Get the total number of collections in the contract
	function getCollectionCount() external view returns(uint);

	// Get a specific collection in the contract
	function getCollection(uint collectionIndex) external view returns(collection memory);
	function rangeInfo(uint rangeIndex) external view returns(range memory data, uint collectionIndex);
	
	// Mint a token inside a collection
	function mintFromRange(address to, uint collectionID, uint index) external;

	// Ask for the royalty info of the creator
	function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
		external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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