/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// File: contracts/extensions/pausable/IPausable.sol

pragma solidity ^0.8.0;

interface IPausable {
    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);
    event Paused(address indexed pauser);
    event Unpaused(address indexed pauser);
    event PausedFor(address indexed pauser, address indexed account);
    event UnpausedFor(address indexed pauser, address indexed account);

    function isPaused() external view returns (bool);

    function pause() external;

    function unpause() external;

    function addPauser(address account) external;

    function removePauser(address account) external;

    function renouncePauser() external;

    function isPausedFor(address caller) external view returns (bool);

    function pauseFor(address caller) external;

    function unpauseFor(address caller) external;
}

// File: @openzeppelin/contracts/utils/StorageSlot.sol

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
library StorageSlot {
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

// File: contracts/extensions/ExtensionBase.sol

pragma solidity ^0.8.0;

abstract contract ExtensionBase {
    bytes32 constant PROXY_DATA_SLOT = keccak256("ext.proxy.data");
    bytes32 constant MSG_SENDER_SLOT = keccak256("ext.proxy.data.msgsender");

    struct ProxyData {
        address token;
        address extension;
        address callsite;
        bool initialized;
    }

    function _proxyData() internal pure returns (ProxyData storage ds) {
        bytes32 position = PROXY_DATA_SLOT;
        assembly {
            ds.slot := position
        }
    }

    function _extensionAddress() internal view returns (address) {
        ProxyData storage ds = _proxyData();
        return ds.extension;
    }

    function _tokenAddress() internal view returns (address payable) {
        ProxyData storage ds = _proxyData();
        return payable(ds.token);
    }

    function _authorizedCaller() internal view returns (address) {
        ProxyData storage ds = _proxyData();
        return ds.callsite;
    }

    modifier onlyToken {
        require(msg.sender == _tokenAddress(), "Token: Unauthorized");
        _;
    }

    modifier onlyAuthorizedCaller {
        require(msg.sender == _authorizedCaller(), "Caller: Unauthorized");
        _;
    }

    modifier onlyAuthorizedCallerOrExtension {
        require(msg.sender == _authorizedCaller() || msg.sender == _extensionAddress(), "Caller: Unauthorized");
        _;
    }

    modifier onlyAuthorizedCallerOrSelf {
        require(msg.sender == _authorizedCaller() || msg.sender == address(this), "Caller: Unauthorized");
        _;
    }

    function _msgSender() internal view returns (address) {
        return StorageSlot.getAddressSlot(MSG_SENDER_SLOT).value;
    }

    receive() external payable {}
}

// File: contracts/interface/IToken.sol

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

// File: contracts/interface/IExtensionMetadata.sol

pragma solidity ^0.8.0;

interface IExtensionMetadata {
    function externalFunctions() external view returns (bytes4[] memory);
    
    function requiredRoles() external view returns (bytes32[] memory);

    function isTokenStandardSupported(TokenStandard standard) external view returns (bool);

    function extensionDeployer() external view returns (address);

    function packageHash() external view returns (bytes32);

    function version() external view returns (uint256);
}

// File: contracts/interface/IExtension.sol


interface IExtension is IExtensionMetadata {
    function initialize() external;

    function onTransferExecuted(TransferData memory data) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol

/*
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

// File: @openzeppelin/contracts/access/Ownable.sol

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/roles/Roles.sol

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

// File: contracts/roles/RolesBase.sol

pragma solidity ^0.8.0;

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

// File: contracts/extensions/TokenExtension.sol

pragma solidity ^0.8.0;




abstract contract TokenExtension is IExtension, ExtensionBase, RolesBase {
    mapping(TokenStandard => bool) supportedTokenStandards;
    //Should only be modified inside the constructor
    bytes4[] private _exposedFuncSigs;
    mapping(bytes4 => bool) private _interfaceMap;
    bytes32[] private _requiredRoles;
    address private _deployer;
    uint256 private _version;
    string private _package;
    bytes32 private _packageHash;

    constructor() {
        _deployer = msg.sender;
    }

    function __update_package_hash() private {
        _packageHash = keccak256(abi.encodePacked(_deployer, _package));
    }

    function _setVersion(uint256 __version) internal {
        require(isInsideConstructorCall(), "Function must be called inside the constructor");

        _version = __version;
    }

    function _setPackageName(string memory package) internal {
        require(isInsideConstructorCall(), "Function must be called inside the constructor");

        _package = package;

        __update_package_hash();
    }
    
    function _supportsTokenStandard(TokenStandard tokenStandard) internal {
        require(isInsideConstructorCall(), "Function must be called inside the constructor");
        supportedTokenStandards[tokenStandard] = true;
    }

    function _supportsAllTokenStandards() internal {
        _supportsTokenStandard(TokenStandard.ERC20);
        _supportsTokenStandard(TokenStandard.ERC721);
        _supportsTokenStandard(TokenStandard.ERC1400);
        _supportsTokenStandard(TokenStandard.ERC1155);
    }

    function extensionDeployer() external override view returns (address) {
        return _deployer;
    }

    function packageHash() external override view returns (bytes32) {
        return _packageHash;
    }

    function version() external override view returns (uint256) {
        return _version;
    }

    function isTokenStandardSupported(TokenStandard standard) external override view returns (bool) {
        return supportedTokenStandards[standard];
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
        _requiredRoles.push(roleId);
    }

    function _supportInterface(bytes4 interfaceId) internal {
        require(isInsideConstructorCall(), "Function must be called inside the constructor");
        _interfaceMap[interfaceId] = true;
    }

    function _registerFunctionName(string memory selector) internal {
        _registerFunction(bytes4(keccak256(abi.encodePacked(selector))));
    }

    function _registerFunction(bytes4 selector) internal {
        require(isInsideConstructorCall(), "Function must be called inside the constructor");
        _exposedFuncSigs.push(selector);
    }

    
    function externalFunctions() external override view returns (bytes4[] memory) {
        return _exposedFuncSigs;
    }

    function requiredRoles() external override view returns (bytes32[] memory) {
        return _requiredRoles;
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

    function _tokenOwner() internal view returns (address) {
        Ownable token = Ownable(_tokenAddress());

        return token.owner();
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: contracts/extensions/pausable/PauseExtension.sol

pragma solidity ^0.8.0;



contract PauseExtension is TokenExtension, IPausable {

    bytes32 constant PAUSER_ROLE = keccak256("pausable.roles.pausers");

    bool private _isPaused;
    mapping(address => bool) private _pausedFor;

    constructor() {
        _registerFunction(PauseExtension.addPauser.selector);
        _registerFunction(PauseExtension.removePauser.selector);
        _registerFunction(PauseExtension.renouncePauser.selector);
        _registerFunction(PauseExtension.pause.selector);
        _registerFunction(PauseExtension.unpause.selector);
        _registerFunction(PauseExtension.pauseFor.selector);
        _registerFunction(PauseExtension.unpauseFor.selector);
        
        _registerFunctionName('isPaused()');
        _registerFunctionName('isPausedFor(address)');

        _supportInterface(type(IPausable).interfaceId);

        _supportsAllTokenStandards();
    }
    
    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!this.isPaused(), "Token must not be paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(this.isPaused(), "Token must be paused");
        _;
    }

    modifier onlyPauser() {
        require(hasRole(_msgSender(), PAUSER_ROLE), "Only pausers can use this function");
        _;
    }

    function isPaused() public override view returns (bool) {
        return _isPaused;
    }

    function initialize() external override {
        _addRole(_msgSender(), PAUSER_ROLE);
    }

    function pause() external override onlyPauser whenNotPaused {
        _isPaused = true;
        emit Paused(_msgSender());
    }

    function unpause() external override onlyPauser whenPaused {
        _isPaused = false;
        emit Unpaused(_msgSender());
    }

    function isPausedFor(address caller) public override view returns (bool) {
        return isPaused() || _pausedFor[caller];
    }

    function pauseFor(address caller) external override onlyPauser {
        _pausedFor[caller] = true;
    }

    function unpauseFor(address caller) external override onlyPauser {
        _pausedFor[caller] = false;
    }

    function addPauser(address account) external override onlyPauser {
        _addPauser(account);
    }

    function removePauser(address account) external override onlyPauser {
        _removePauser(account);
    }

    function renouncePauser() external override {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _addRole(account, PAUSER_ROLE);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _removeRole(account, PAUSER_ROLE);
        emit PauserRemoved(account);
    }

    function onTransferExecuted(TransferData memory data) external override returns (bool) {
        bool isPaused = isPausedFor(data.from);

        require(!isPaused, "Transfers are paused");

        return true;
    }
}