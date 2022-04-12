pragma solidity ^0.8.0;

import {IBlocklistedRole} from "./IBlocklistedRole.sol";
import {IBlocklistedAdminRole} from "./IBlocklistedAdminRole.sol";
import {TokenExtension, TransferData} from "../../TokenExtension.sol";

contract BlockExtension is TokenExtension, IBlocklistedRole, IBlocklistedAdminRole {

    bytes32 constant BLOCKLIST_ROLE = keccak256("allowblock.roles.blocklisted");
    bytes32 constant BLOCKLIST_ADMIN_ROLE = keccak256("allowblock.roles.blocklisted.admin");

    modifier onlyBlocklistedAdmin {
        require(this.isBlocklistedAdmin(_msgSender()), "Not on block list admin");
        _;
    }

    
    modifier onlyNotBlocklisted {
        require(!this.isBlocklisted(_msgSender()), "Already on block list");
        _;
    }

    modifier onlyBlocklisted {
        require(this.isBlocklisted(_msgSender()), "Not on block list");
        _;
    }

    constructor() {
        _registerFunction(BlockExtension.addBlocklisted.selector);
        _registerFunction(BlockExtension.removeBlocklisted.selector);
        _registerFunction(BlockExtension.addBlocklistedAdmin.selector);
        _registerFunction(BlockExtension.removeBlocklistedAdmin.selector);
        _registerFunction(this.mockUpgradeTest.selector);

        _registerFunctionName('isBlocklisted(address)');
        _registerFunctionName('isBlocklistedAdmin(address)');

        _supportInterface(type(IBlocklistedRole).interfaceId);
        _supportInterface(type(IBlocklistedAdminRole).interfaceId);

        _supportsAllTokenStandards();

        _setPackageName("net.consensys.tokenext.BlockExtension");
        _setVersion(2);
        _setInterfaceLabel("BlockExtension");
    }

    function initialize() external override {
        _addRole(_msgSender(), BLOCKLIST_ADMIN_ROLE);
        _listenForTokenTransfers(this.onTransferExecuted);
    }

    function isBlocklisted(address account) external override view returns (bool) {
        return hasRole(account, BLOCKLIST_ROLE);
    }

    function addBlocklisted(address account) external override onlyBlocklistedAdmin {
        _addRole(account, BLOCKLIST_ROLE);
    }

    function removeBlocklisted(address account) external override onlyBlocklistedAdmin {
        _removeRole(account, BLOCKLIST_ROLE);
    }

    function isBlocklistedAdmin(address account) external override view returns (bool) {
        return hasRole(account, BLOCKLIST_ADMIN_ROLE);
    }

    function addBlocklistedAdmin(address account) external override onlyBlocklistedAdmin {
        _addRole(account, BLOCKLIST_ADMIN_ROLE);
    }

    function removeBlocklistedAdmin(address account) external override onlyBlocklistedAdmin {
        _removeRole(account, BLOCKLIST_ADMIN_ROLE);
    }

    function mockUpgradeTest() external view onlyBlocklistedAdmin returns (string memory) {
        return "This upgrade worked";
    }

    function onTransferExecuted(TransferData memory data) external eventGuard returns (bool) {
        if (data.from != address(0)) {
            require(!hasRole(data.from, BLOCKLIST_ROLE), "from address is blocklisted");
        }

        if (data.to != address(0)) {
            require(!hasRole(data.to, BLOCKLIST_ROLE), "to address is blocklisted");
        }
        
        return true;
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

/**
* @title Domain-Aware contract interface
* @notice This can be used to interact with a DomainAware contract of any type.
* @dev An interface that represents a DomainAware contract. This interface provides
* all public/external facing functions that the DomainAware contract implements.
*/
interface IDomainAware {
    /**
    * @dev Uses _domainName()
    * @notice The domain name for this contract used in the domain seperator. 
    * This value will not change and will have a length greater than 0.
    * @return bytes The domain name represented as bytes
    */
    function domainName() external view returns (bytes memory);

    /**
    * @dev The current version for this contract. Changing this value will
    * cause the domain separator to update and trigger a cache update.
    */
    function domainVersion() external view returns (bytes32);

    /**
    * @notice Generate the domain seperator hash for this contract using the contract's
    * domain name, current domain version and the current chain-id. This call bypasses the stored cache and
    * will always represent the current domain seperator for this Contract's name + version + chain id. 
    * @return bytes32 The domain seperator hash.
    */
    function generateDomainSeparator() external view returns (bytes32);

    /**
    * @notice Get the current domain seperator hash for this contract using the contract's
    * domain name, current domain version and the current chain-id. 
    * @dev This call is cached by the chain-id and contract version. If these two values do not 
    * change then the cached domain seperator hash is returned. If these two values do change,
    * then a new hash is generated and the cache is updated
    * @return bytes32 The current domain seperator hash
    */
    function domainSeparator() external returns (bytes32);
}

/**
* @title Domain-Aware contract
* @notice This should be inherited by any contract that plans on using the EIP712 
* typed structured data signing 
* @dev A generic contract to be used by contract plans on using the EIP712 typed structure
* data signing. This contract offers a way to generate the EIP712Domain seperator for the
* contract that extends from this. 
*
* The EIP712 domain seperator generated depends on the domain name and domain version of the child
* contract. Therefore, a child contract must implement the _domainName() and _domainVersion() functions in order
* to complete the implementation. 
* The child contract may return whatever it likes for the _domainName(), however this value should not change
* after deployment. Changing the result of the _domainName() function between calls may result in undefined behavior.
* The _domainVersion() must be a bytes32 and that _domainName() must have a length greater than 0.
*
* If a child contract changes the domain version after deployment, then the domain seperator will 
* update to reflect the new version.
*
* This contract stores the domain seperator for each chain-id detected after deployment. This
* means if the contract were to fork to a new blockchain with a new chain-id, then the domain-seperator
* of this contract would update to reflect the new domain context. 
*
*/
abstract contract DomainAware is IDomainAware {

    /**
    * @dev The storage slot the DomainData is stored in this contract
    */
    bytes32 constant DOMAIN_AWARE_SLOT = keccak256("consensys.contracts.domainaware.data");

    /**
    * @dev The cached DomainData for this chain & contract version.
    * @param domainSeparator The cached domainSeperator for this chain + contract version
    * @param version The contract version this DomainData is for
    */
    struct DomainData {
        bytes32 domainSeparator;
        bytes32 version; 
    }

    /**
    * @dev The struct storing all the DomainData cached for each chain-id.
    * This is a very gas efficient way to not recalculate the domain separator 
    * on every call, while still automatically detecting ChainID changes.
    * @param chainToDomainData Mapping of ChainID to domain separators. 
    */
    struct DomainAwareData {
        mapping(uint256 => DomainData) chainToDomainData;
    }

    /**
    * @dev If in the constructor we have a non-zero domain name, then update the domain seperator now.
    * Otherwise, the child contract will need to do this themselves
    */
    constructor() {
        if (_domainName().length > 0) {
            _updateDomainSeparator();
        }
    }

    /**
    * @dev The domain name for this contract. This value should not change at all and should have a length
    * greater than 0.
    * Changing this value changes the domain separator but does not trigger a cache update so may
    * result in undefined behavior
    * TODO Fix cache issue? Gas inefficient since we don't know if the data has updated?
    * We can't make this pure because ERC20 requires name() to be view.
    * @return bytes The domain name represented as a bytes
    */
    function _domainName() internal virtual view returns (bytes memory);

    /**
    * @dev The current version for this contract. Changing this value will
    * cause the domain separator to update and trigger a cache update.
    */
    function _domainVersion() internal virtual view returns (bytes32);

    /**
    * @dev Uses _domainName()
    * @notice The domain name for this contract used in the domain seperator. 
    * This value will not change and will have a length greater than 0.
    * @return bytes The domain name represented as bytes
    */
    function domainName() external override view returns (bytes memory) {
        return _domainName();
    }

    /**
    * @dev Uses _domainName()
    * @notice The current version for this contract. This is the domain version
    * used in the domain seperator
    */
    function domainVersion() external override view returns (bytes32) {
        return _domainVersion();
    }

    /**
    * @dev Get the DomainAwareData struct stored in this contract.
    */
    function domainAwareData() private pure returns (DomainAwareData storage ds) {
        bytes32 position = DOMAIN_AWARE_SLOT;
        assembly {
            ds.slot := position
        }
    }

    /**
    * @notice Generate the domain seperator hash for this contract using the contract's
    * domain name, current domain version and the current chain-id. This call bypasses the stored cache and
    * will always represent the current domain seperator for this Contract's name + version + chain id. 
    * @return bytes32 The domain seperator hash.
    */
    function generateDomainSeparator() public override view returns (bytes32) {
        uint256 chainID = _chainID();
        bytes memory dn = _domainName();
        bytes memory dv = abi.encodePacked(_domainVersion());
        require(dn.length > 0, "Domain name is empty");
        require(dv.length > 0, "Domain version is empty");

        // no need for assembly, running very rarely
        bytes32 domainSeparatorHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(dn), // ERC-20 Name
                keccak256(dv), // Version
                chainID,
                address(this)
            )
        );

        return domainSeparatorHash;
    }

    /**
    * @notice Get the current domain seperator hash for this contract using the contract's
    * domain name, current domain version and the current chain-id. 
    * @dev This call is cached by the chain-id and contract version. If these two values do not 
    * change then the cached domain seperator hash is returned. If these two values do change,
    * then a new hash is generated and the cache is updated
    * @return bytes32 The current domain seperator hash
    */
    function domainSeparator() public override returns (bytes32) {
        return _domainSeparator();
    }

    /**
    * @dev Generate and update the cached domain seperator hash for this contract 
    * using the contract's domain name, current domain version and the current chain-id. 
    * This call will always overwrite the cache even if the cached data of the same.
    * @return bytes32 The current domain seperator hash that was stored in cache
    */
    function _updateDomainSeparator() internal returns (bytes32) {
        uint256 chainID = _chainID();

        bytes32 newDomainSeparator = generateDomainSeparator();

        require(newDomainSeparator != bytes32(0), "Invalid domain seperator");

        domainAwareData().chainToDomainData[chainID] = DomainData(
            newDomainSeparator,
            _domainVersion()
        );

        return newDomainSeparator;
    }

    /**
    * @dev Get the current domain seperator hash for this contract using the contract's
    * domain name, current domain version and the current chain-id. 
    * This call is cached by the chain-id and contract version. If these two values do not 
    * change then the cached domain seperator hash is returned. If these two values do change,
    * then a new hash is generated and the cache is updated
    * @return bytes32 The current domain seperator hash
    */
    function _domainSeparator() private returns (bytes32) {
        uint256 chainID = _chainID();
        bytes32 reportedVersion = _domainVersion();

        DomainData memory currentDomainData = domainAwareData().chainToDomainData[chainID];

        if (currentDomainData.domainSeparator != 0x00 && currentDomainData.version == reportedVersion) {
            return currentDomainData.domainSeparator;
        }

        return _updateDomainSeparator();
    }

    /**
    * @dev Get the current chain-id. This is done using the chainid opcode.
    * @return uint256 The current chain-id as a number.
    */
    function _chainID() internal view returns (uint256) {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        return chainID;
    }
}

pragma solidity ^0.8.0;

import {IToken} from "../IToken.sol";
import {ITokenRoles} from "../../interface/ITokenRoles.sol";
import {IDomainAware} from "../../tools/DomainAware.sol";
import {IExtendable} from "../extension/IExtendable.sol";

interface ITokenProxy is IToken, ITokenRoles, IDomainAware, IExtendable {
    fallback() external payable;

    function upgradeTo(address logic, bytes memory data) external;
}

pragma solidity ^0.8.0;

import {IERC20MetadataUpgradeable} from "@gnus.ai/contracts-upgradeable-diamond/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {ITokenProxy} from "../ITokenProxy.sol";

/**
* @title Extendable ERC20 Proxy Interface
* @notice An interface to interact with an ERC20 Token (proxy).
*/
interface IERC20Proxy is IERC20MetadataUpgradeable, ITokenProxy {
    /**
    * @notice Returns true if minting is allowed on this token, otherwise false
    */
    function mintingAllowed() external view returns (bool);

    /**
    * @notice Returns true if burning is allowed on this token, otherwise false
    */
    function burningAllowed() external view returns (bool);


    /**
     * @notice Creates `amount` new tokens for `to`.
     *
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     * @param to The address to mint tokens to
     * @param amount The amount of new tokens to mint
     */
    function mint(address to, uint256 amount) external returns (bool);

    /**
     * @notice Destroys `amount` tokens from the caller.
     *
     * @dev See {ERC20-_burn}.
     * @param amount The amount of tokens to burn from the caller.
     */
    function burn(uint256 amount) external returns (bool);
    
    /**
     * @notice Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * @dev See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     * @param account The account to burn from
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) external returns (bool);

    /** 
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * @dev This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * @param spender The address that will be given the allownace increase
     * @param addedValue How much the allowance should be increased by
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @notice Atomically decreases the allowance granted to `spender` by the caller.
     *
     * @dev This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     * @param spender The address that will be given the allownace decrease
     * @param subtractedValue How much the allowance should be decreased by
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

pragma solidity ^0.8.0;

import {IToken} from "../IToken.sol";

/**
* @title Token Logic Interface
* @dev An interface that all Token Logic contracts should implement
*/
interface ITokenLogic is IToken {
    function initialize(bytes memory data) external;

    function caller() external view returns (address);
}

pragma solidity ^0.8.0;


abstract contract TokenEventManagerStorage {
    bytes32 constant EVENT_MANAGER_DATA_SLOT = keccak256("consensys.contracts.token.eventmanager.data");
    
    struct ExtensionListeningCache {
        bool listening;
        uint256 listenIndex;
    }

    struct SavedCallbackFunction {
        address callbackAddress;
        bytes4 callbackSelector;
    }

    struct EventManagerData {
        uint256 eventFiringStack;
        mapping(address => bytes32[]) eventListForExtensions;
        mapping(address => mapping(bytes32 => ExtensionListeningCache)) listeningCache;
        mapping(bytes32 => SavedCallbackFunction[]) listeners;
        mapping(bytes32 => bool) isFiring;
    }

    function eventManagerData() internal pure returns (EventManagerData storage ds) {
        bytes32 position = EVENT_MANAGER_DATA_SLOT;
        assembly {
            ds.slot := position
        }
    }
}

pragma solidity ^0.8.0;

import {TokenEventManagerStorage} from "./TokenEventManagerStorage.sol";
import {TransferData} from "../../interface/IExtension.sol";
import {TokenEventConstants} from "./TokenEventConstants.sol";

abstract contract TokenEventListener is TokenEventManagerStorage, TokenEventConstants {
    /**
    * @dev Listen for an event hash and invoke a given callback function. This callback function
    * will be invoked with the TransferData for the event.
    */
    function _on(bytes32 eventId, function (TransferData memory) external returns (bool) callback) internal {
        _on(eventId, callback.address, callback.selector);
    }

    function _on(bytes32 eventId, address callbackAddress, bytes4 callbackSelector) internal {
        EventManagerData storage emd = eventManagerData();

        require(!emd.listeningCache[callbackAddress][eventId].listening, "Address already listening for event");

        uint256 eventIndex = emd.listeners[eventId].length;
        
        emd.listeners[eventId].push(SavedCallbackFunction(
                callbackAddress,
                callbackSelector
            )
        );

        ExtensionListeningCache storage elc = emd.listeningCache[callbackAddress][eventId];
        elc.listening = true;
        elc.listenIndex = eventIndex;

        emd.eventListForExtensions[callbackAddress].push(eventId);
    }
}

pragma solidity ^0.8.0;

abstract contract TokenEventConstants {
    /**
    * @dev The event hash for a token transfer event to be used by the ExtendableEventManager
    * and any extensions wanting to listen to the event
    */
    bytes32 constant TOKEN_TRANSFER_EVENT = keccak256("consensys.contracts.token.events.transfer");

    /**
    * @dev The event hash for a token transfer event to be used by the ExtendableEventManager
    * and any extensions wanting to listen to the event
    */
    bytes32 constant TOKEN_BEFORE_TRANSFER_EVENT = keccak256("consensys.contracts.token.events.before.transfer");

    /**
    * @dev The event hash for a token approval event to be used by the ExtendableEventManager
    * and any extensions wanting to listen to the event
    */
    bytes32 constant TOKEN_APPROVE_EVENT = keccak256("consensys.contracts.token.events.approve");
}

pragma solidity ^0.8.0;

/**
* @title IExtendable
* @notice Interface for token proxy that offers extensions
*/
interface IExtendable {
    /**
    * @dev Register the extension at the given global extension address. This will create a new
    * DiamondCut with the extension address being the facet. All external functions the extension
    * exposes will be registered with the DiamondCut. The DiamondCut will be initalized by calling
    * the initialize function on the extension through delegatecall
    * Registering an extension automatically enables it for use.
    *
    * @param extension The deployed extension address to register
    */
    function registerExtension(address extension) external;

    /**
    * @dev Upgrade a registered extension at the given global extension address. This will
    * perform a replacement DiamondCut. The new global extension address must have the same deployer and package hash.
    * @param extension The global extension address to upgrade
    * @param newExtension The new global extension address to upgrade the extension to
    */
    function upgradeExtension(address extension, address newExtension) external;

    /**
    * @dev Remove the extension at the provided address. This may either be the
    * global extension address or the deployed extension proxy address. 
    *
    * Removing an extension deletes all data about the deployed extension proxy address
    * and makes the extension's storage inaccessable forever.
    *
    * @param extension Either the global extension address or the deployed extension proxy address to remove
    */
    function removeExtension(address extension) external;

    /**
    * @dev Disable the extension at the provided address. This may either be the
    * global extension address or the deployed extension proxy address. 
    *
    * Disabling the extension keeps the extension + storage live but simply disables
    * all registered functions and transfer events
    *
    * @param extension Either the global extension address or the deployed extension proxy address to disable
    */
    function disableExtension(address extension) external;

    /**
    * @dev Enable the extension at the provided address. This may either be the
    * global extension address or the deployed extension proxy address. 
    *
    * Enabling the extension simply enables all registered functions and transfer events
    *
    * @param extension Either the global extension address or the deployed extension proxy address to enable
    */
    function enableExtension(address extension) external;

    /**
    * @dev Get an array of all deployed extension proxy addresses, regardless of if they are
    * enabled or disabled
    */
    function allExtensionsRegistered() external view returns (address[] memory);
}

pragma solidity ^0.8.0;

/**
* @dev A struct containing information about the current token transfer.
* @param token Token address that is executing this extension.
* @param payload The full payload of the initial transaction.
* @param partition Name of the partition (left empty for ERC20 transfer).
* @param operator Address which triggered the balance decrease (through transfer or redemption).
* @param from Token holder.
* @param to Token recipient for a transfer and 0x for a redemption.
* @param value Number of tokens the token holder balance is decreased by.
* @param data Extra information (if any).
* @param operatorData Extra information, attached by the operator (if any).
*/
struct TransferData {
    address token;
    bytes payload;
    bytes32 partition;
    address operator;
    address from;
    address to;
    uint256 value;
    uint256 tokenId;
    bytes data;
    bytes operatorData;
}

/**
* @notice An enum of different token standards by name
*/
enum TokenStandard {
    ERC20,
    ERC721,
    ERC1400,
    ERC1155
}

/**
* @title Token Interface
* @dev A standard interface all token standards must inherit from. Provides token standard agnostic 
* functions
*/
interface IToken {
    /**
    * @notice Perform a transfer given a TransferData struct. Only addresses with the token controllers 
    * role should be able to invoke this function.
    * @return bool If this contract does not support the transfer requested, it should return false. 
    * If the contract does support the transfer but the transfer is impossible, it should revert. 
    * If the contract does support the transfer and successfully performs the transfer, it should return true
    */
    function tokenTransfer(TransferData calldata transfer) external returns (bool);

    /**
    * @notice A function to determine what token standard this token implements. This
    * is a pure function, meaning the value should not change
    * @return TokenStandard The token standard this token implements
    */
    function tokenStandard() external pure returns (TokenStandard);
}

pragma solidity ^0.8.0;

abstract contract TokenRolesConstants {
    /**
    * @dev The storage slot for the burn/burnFrom toggle
    */
    bytes32 constant TOKEN_ALLOW_BURN = keccak256("consensys.contracts.token.storage.core.burn");
    /**
    * @dev The storage slot for the mint toggle
    */
    bytes32 constant TOKEN_ALLOW_MINT = keccak256("consensys.contracts.token.storage.core.mint");
    /**
    * @dev The storage slot that holds the current Owner address
    */
    bytes32 constant TOKEN_OWNER = keccak256("consensys.contracts.token.storage.core.owner");
    /**
    * @dev The access control role ID for the Minter role
    */
    bytes32 constant TOKEN_MINTER_ROLE = keccak256("consensys.contracts.token.storage.core.mint.role");
    /**
    * @dev The storage slot that holds the current Manager address
    */
    bytes32 constant TOKEN_MANAGER_ADDRESS = bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1);
    /**
    * @dev The access control role ID for the Controller role
    */
    bytes32 constant TOKEN_CONTROLLER_ROLE = keccak256("consensys.contracts.token.storage.controller.address");
}

pragma solidity ^0.8.0;

import {Roles} from "./Roles.sol";

abstract contract RolesBase {
    using Roles for Roles.Role;

    event RoleAdded(address indexed caller, bytes32 indexed roleId);
    event RoleRemoved(address indexed caller, bytes32 indexed roleId);
    
    function hasRole(address caller, bytes32 roleId) public view returns (bool) {
        return Roles.roleStorage(roleId).has(caller);
    }

    function _addRole(address caller, bytes32 roleId) internal {
        Roles.roleStorage(roleId).add(caller);

        emit RoleAdded(caller, roleId);
    }

    function _removeRole(address caller, bytes32 roleId) internal {
        Roles.roleStorage(roleId).remove(caller);

        emit RoleRemoved(caller, roleId);
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function roleStorage(bytes32 _rolePosition) internal pure returns (Role storage ds) {
        bytes32 position = _rolePosition;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity ^0.8.0;

interface ITokenRoles {
    function manager() external view returns (address);

    function isController(address caller) external view returns (bool);

    function isMinter(address caller) external view returns (bool);

    function addController(address caller) external;

    function removeController(address caller) external;

    function addMinter(address caller) external;

    function removeMinter(address caller) external;

    function changeManager(address newManager) external;

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external;

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;
}

pragma solidity ^0.8.0;

import {TokenStandard} from "../tokens/IToken.sol";

/**
* @title Extension Metadata Interface
* @dev An interface that extensions must implement that provides additional
* metadata about the extension. 
*/
interface IExtensionMetadata {
    /**
    * @notice An array of function signatures this extension adds when
    * registered when a TokenProxy
    * @dev This function is used by the TokenProxy to determine what
    * function selectors to add to the TokenProxy
    */
    function externalFunctions() external view returns (bytes4[] memory);
    
    /**
    * @notice An array of role IDs that this extension requires from the Token
    * in order to function properly
    * @dev This function is used by the TokenProxy to determine what
    * roles to grant to the extension after registration and what roles to remove
    * when removing the extension
    */
    function requiredRoles() external view returns (bytes32[] memory);

    /**
    * @notice Whether a given Token standard is supported by this Extension
    * @param standard The standard to check support for
    */
    function isTokenStandardSupported(TokenStandard standard) external view returns (bool);

    /**
    * @notice The address that deployed this extension.
    */
    function extensionDeployer() external view returns (address);

    /**
    * @notice The hash of the package string this extension was deployed with
    */
    function packageHash() external view returns (bytes32);

    /**
    * @notice The version of this extension, represented as a number
    */
    function version() external view returns (uint256);

    /**
    * @notice The ERC1820 interface label the extension will be registered as in the ERC1820 registry
    */
    function interfaceLabel() external view returns (string memory);
}

pragma solidity ^0.8.0;

import {TransferData} from "../tokens/IToken.sol";
import {IExtensionMetadata, TokenStandard} from "./IExtensionMetadata.sol";

/**
* @title Extension Interface
* @dev An interface to be implemented by Extensions
*/
interface IExtension is IExtensionMetadata {
    /**
    * @notice This function cannot be invoked directly
    * @dev This function is invoked when the Extension is registered
    * with a TokenProxy 
    */
    function initialize() external;
}

pragma solidity ^0.8.0;

interface IBlocklistedRole {
    event BlocklistedAdded(address indexed account);
    event BlocklistedRemoved(address indexed account);

    function isBlocklisted(address account) external view returns (bool);

    function addBlocklisted(address account) external;

    function removeBlocklisted(address account) external;
}

pragma solidity ^0.8.0;

interface IBlocklistedAdminRole {
    event BlocklistedAdminAdded(address indexed account);
    event BlocklistedAdminRemoved(address indexed account);

    function isBlocklistedAdmin(address account) external view returns (bool);

    function addBlocklistedAdmin(address account) external;

    function removeBlocklistedAdmin(address account) external;
}

pragma solidity ^0.8.0;

import {ExtensionBase} from "./ExtensionBase.sol";
import {IExtension, TransferData, TokenStandard} from "../interface/IExtension.sol";
import {OwnableUpgradeable} from "@gnus.ai/contracts-upgradeable-diamond/access/OwnableUpgradeable.sol";
import {RolesBase} from "../roles/RolesBase.sol";
import {IERC20Proxy} from "../tokens/proxy/ERC20/IERC20Proxy.sol";
import {TokenRolesConstants} from "../roles/TokenRolesConstants.sol";
import {IToken} from "../tokens/IToken.sol";
import {TokenEventListener} from "../tokens/extension/TokenEventListener.sol";

abstract contract TokenExtension is TokenRolesConstants, TokenEventListener, IExtension, ExtensionBase, RolesBase {
    bytes32 constant EXT_DATA_SLOT = keccak256("consensys.contracts.token.ext.storage.meta");

    /**
    * @dev The Metadata associated with the Extension that identifies it on-chain and provides
    * information about the Extension. This information includes what function selectors it exposes,
    * what token roles are required for the extension, and extension metadata such as the version, deployer address
    * and package hash
    * This data should only be modified inside the constructor
    * @param _packageHash Hash of the package namespace for this Extension
    * @param _requiredRoles An array of token role IDs that are required for this Extension's registration
    * @param _deployer The address that deployed this Extension
    * @param _version The version of this Extension
    * @param _exposedFuncSigs An array of function selectors this Extension exposes to a Proxy or Diamond
    * @param _package The unhashed version of the package namespace for this Extension
    * @param _interfaceMap A mapping of interface IDs this Extension implements
    * @param supportedTokenStandards A mapping of token standards this Extension supports
    */
    struct TokenExtensionData {
        bytes32 _packageHash;
        bytes32[] _requiredRoles;
        address _deployer;
        uint256 _version;
        bytes4[] _exposedFuncSigs;
        string _package;
        string _interfaceLabel;
        mapping(bytes4 => bool) _interfaceMap;
        mapping(TokenStandard => bool) supportedTokenStandards;
    }

    constructor() {
        _extensionData()._deployer = msg.sender;
        __update_package_hash();
    }

    /**
    * @dev The ProxyData struct stored in this registered Extension instance.
    */
    function _extensionData() internal pure returns (TokenExtensionData storage ds) {
        bytes32 position = EXT_DATA_SLOT;
        assembly {
            ds.slot := position
        }
    }

    function __update_package_hash() private {
        TokenExtensionData storage data = _extensionData();
        data._packageHash = keccak256(abi.encodePacked(data._deployer, data._package));
    }

    function _setVersion(uint256 __version) internal {
        require(isInsideConstructorCall(), "Function must be called inside the constructor");

        _extensionData()._version = __version;
    }

    function _setInterfaceLabel(string memory interfaceLabel_) internal {
        require(isInsideConstructorCall(), "Function must be called inside the constructor");

        _extensionData()._interfaceLabel = interfaceLabel_;
    }

    function _setPackageName(string memory package) internal {
        require(isInsideConstructorCall(), "Function must be called inside the constructor");

        _extensionData()._package = package;

        __update_package_hash();
    }
    
    function _supportsTokenStandard(TokenStandard tokenStandard) internal {
        require(isInsideConstructorCall(), "Function must be called inside the constructor");
        _extensionData().supportedTokenStandards[tokenStandard] = true;
    }

    function _supportsAllTokenStandards() internal {
        _supportsTokenStandard(TokenStandard.ERC20);
        _supportsTokenStandard(TokenStandard.ERC721);
        _supportsTokenStandard(TokenStandard.ERC1400);
        _supportsTokenStandard(TokenStandard.ERC1155);
    }

    function extensionDeployer() external override view returns (address) {
        return _extensionData()._deployer;
    }

    function packageHash() external override view returns (bytes32) {
        return _extensionData()._packageHash;
    }

    function version() external override view returns (uint256) {
        return _extensionData()._version;
    }

    function isTokenStandardSupported(TokenStandard standard) external override view returns (bool) {
        return _extensionData().supportedTokenStandards[standard];
    }

    modifier onlyOwner {
        require(_msgSender() == _tokenOwner(), "Only the token owner can invoke");
        _;
    }

    modifier onlyTokenOrOwner {
        address msgSender = _msgSender();
        require(msgSender == _tokenOwner() || msgSender == _tokenAddress(), "Only the token or token owner can invoke");
        _;
    }

    function _requireRole(bytes32 roleId) internal {
        require(isInsideConstructorCall(), "Function must be called inside the constructor");
        _extensionData()._requiredRoles.push(roleId);
    }

    function _supportInterface(bytes4 interfaceId) internal {
        require(isInsideConstructorCall(), "Function must be called inside the constructor");
        _extensionData()._interfaceMap[interfaceId] = true;
    }

    function _registerFunctionName(string memory selector) internal {
        _registerFunction(bytes4(keccak256(abi.encodePacked(selector))));
    }

    function _registerFunction(bytes4 selector) internal {
        require(isInsideConstructorCall(), "Function must be called inside the constructor");
        _extensionData()._exposedFuncSigs.push(selector);
    }

    
    function externalFunctions() external override view returns (bytes4[] memory) {
        return _extensionData()._exposedFuncSigs;
    }

    function requiredRoles() external override view returns (bytes32[] memory) {
        return _extensionData()._requiredRoles;
    }

    /**
    * @notice The ERC1820 interface label the extension will be registered as in the ERC1820 registry
    */
    function interfaceLabel() external override view returns (string memory) {
        return _extensionData()._interfaceLabel;
    }

    function isInsideConstructorCall() internal view returns (bool) {
        uint size;
        address addr = address(this);
        assembly { size := extcodesize(addr) }
        return size == 0;
    }

    function _isTokenOwner(address addr) internal view returns (bool) {
        return addr == _tokenOwner();
    }

    function _erc20Token() internal view returns (IERC20Proxy) {
        return IERC20Proxy(_tokenAddress());
    }

    function _tokenOwner() internal view returns (address) {
        OwnableUpgradeable token = OwnableUpgradeable(_tokenAddress());

        return token.owner();
    }

    function _tokenStandard() internal view returns (TokenStandard) {
        //TODO Optimize this
        return IToken(_tokenAddress()).tokenStandard();
    }

    function _buildTransfer(address from, address to, uint256 amountOrTokenId) internal view returns (TransferData memory) {
        uint256 amount = amountOrTokenId;
        uint256 tokenId = 0;
        if (_tokenStandard() == TokenStandard.ERC721) {
            amount = 0;
            tokenId = amountOrTokenId;
        }

        address token = _tokenAddress();
        return TransferData(
            token,
            _msgData(),
            bytes32(0),
            _extensionAddress(),
            from,
            to,
            amount,
            tokenId,
            bytes(""),
            bytes("")
        );
    }

    function _buildTransferWithData(address from, address to, uint256 amountOrTokenId, bytes memory data) internal view returns (TransferData memory) {
        TransferData memory t = _buildTransfer(from, to, amountOrTokenId);
        t.data = data;
        return t;
    }

    function _buildTransferWithOperatorData(address from, address to, uint256 amountOrTokenId, bytes memory data) internal view returns (TransferData memory) {
        TransferData memory t = _buildTransfer(from, to, amountOrTokenId);
        t.operatorData = data;
        return t;
    }

    function _tokenTransfer(TransferData memory tdata) internal returns (bool) {
        return IToken(_tokenAddress()).tokenTransfer(tdata);
    }

    function _listenForTokenTransfers(function (TransferData memory) external returns (bool) callback) internal {
        _on(TOKEN_TRANSFER_EVENT, _extensionAddress(), callback.selector);
    }

    function _listenForTokenBeforeTransfers(function (TransferData memory) external returns (bool) callback) internal {
        _on(TOKEN_BEFORE_TRANSFER_EVENT, _extensionAddress(), callback.selector);
    }

    function _listenForTokenApprovals(function (TransferData memory) external returns (bool) callback) internal {
        _on(TOKEN_APPROVE_EVENT, _extensionAddress(), callback.selector);
    }
}

pragma solidity ^0.8.0;

import {TokenStandard} from "../interface/IExtension.sol";
import {ContextUpgradeable} from "@gnus.ai/contracts-upgradeable-diamond/utils/ContextUpgradeable.sol";
import {StorageSlotUpgradeable} from "@gnus.ai/contracts-upgradeable-diamond/utils/StorageSlotUpgradeable.sol";
import {ITokenLogic} from "../tokens/logic/ITokenLogic.sol";

/**
* @title Extension Base Contract
* @notice This shouldn't be used directly, it should be extended by child contracts
* @dev This contract setups the base of every Extension contract (including proxies). It
* defines a set data structure for holding important information about the current Extension
* registration instance. This includes the current Token address, the current Extension
* global address and an "authorized caller" (callsite).
*
* The _msgSender() function is also defined and should be used instead of the msg.sender variable.
*  _msgSender() has a different behavior depending on who the msg.sender variable is, 
* this is to allow meta-transactions
*
* The "callsite" can be used to support meta transactions through a trusted forwarder. Currently
* not implemented
*
* The ExtensionBase also provides several function modifiers to restrict function
* invokation
*/
abstract contract ExtensionBase is ContextUpgradeable {

    function _logicAddress() internal view returns (address) {
        bytes32 EIP1967_LOCATION = bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1);
        
        //Update EIP1967 Storage Slot
        return StorageSlotUpgradeable.getAddressSlot(EIP1967_LOCATION).value;
    }

    /**
    * @dev The current Extension logic contract address
    */
    function _extensionAddress() internal pure returns (address ret) {
        if (msg.data.length >= 24) {
            // At this point we know that the sender is a token proxy,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = address(0);
        }
    }

    /**
    * @dev The current token address that registered this extension instance
    */
    function _tokenAddress() internal view returns (address payable) {
        return payable(this); //we are the token address
    }

    /**
    * @dev A function modifier to only allow a function only used for events to be
    * guarded by ensuring that the function is only invoked if we are the token.
    * This ensures that only a delegatecall to this function from the token address
    * is valid
    */
    modifier eventGuard {
        require(address(this) == _tokenAddress(), "Token: Unauthorized");
        _;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

library InitializableStorage {

  struct Layout {
    /*
     * @dev Indicates that the contract has been initialized.
     */
    bool _initialized;

    /*
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool _initializing;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzepplin.contracts.storage.Initializable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";
import { InitializableStorage } from "./InitializableStorage.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(InitializableStorage.layout()._initializing ? _isConstructor() : !InitializableStorage.layout()._initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !InitializableStorage.layout()._initializing;
        if (isTopLevelCall) {
            InitializableStorage.layout()._initializing = true;
            InitializableStorage.layout()._initialized = true;
        }

        _;

        if (isTopLevelCall) {
            InitializableStorage.layout()._initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(InitializableStorage.layout()._initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import { OwnableStorage } from "./OwnableStorage.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    using OwnableStorage for OwnableStorage.Layout;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return OwnableStorage.layout()._owner;
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
        address oldOwner = OwnableStorage.layout()._owner;
        OwnableStorage.layout()._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import { OwnableUpgradeable } from "./OwnableUpgradeable.sol";

library OwnableStorage {

  struct Layout {
    address _owner;
  
  }
  
  bytes32 internal constant STORAGE_SLOT = keccak256('openzepplin.contracts.storage.Ownable');

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}