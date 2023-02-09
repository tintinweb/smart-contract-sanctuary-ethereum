// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
pragma solidity ^0.8.16;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/// @notice Platform theme registry modified from
///     the Zora Labs JSONExtensionRegistry implementation
///     deployed at 0xABCDEFEd93200601e1dFe26D6644758801D732E8
/// @author Max Bochman
contract PlatformThemeRegistry is Ownable {

    //////////////////////////////
    /// ENUMS + TYPES
    //////////////////////////////    

    /// @notice Access control roles
    /// NO_ROLE = 0, MANAGER = 1, ADMIN = 2
    enum Roles {
        NO_ROLE,
        MANAGER,
        ADMIN
    }       

    struct RoleDetails {
        address account;
        Roles role;
    } 
    
    //////////////////////////////
    /// STORAGE
    //////////////////////////////

    /// @notice Contract version
    uint256 public constant version = 1;

    // Stores link to docs for this contract
    string contractDocumentation = "https://docs.public---assembly.com/";

    // Stores platform counter
    uint256 public platformCounter = 0;

    // Platform index to string
    mapping(uint256 => string) platformThemeInfo;

    // Platform index to account to role
    mapping(uint256 => mapping(address => Roles)) roleInfo;

    //////////////////////////////
    /// ERRORS
    //////////////////////////////

    error RequiresAdmin();
    error RequiresHigherRole();
    error RoleDoesntExist();

    //////////////////////////////
    /// EVENTS
    //////////////////////////////

    event PlatformThemeUpdated(
        uint256 indexed platformIndex,
        address sender,
        string newTheme 
    );

    event RoleGranted(
        uint256 indexed platformIndex,
        address sender,
        address account,
        Roles role 
    );    

    event RoleRevoked(
        uint256 indexed platformIndex,
        address sender,
        address account,
        Roles role 
    );        

    //////////////////////////////
    /// CONTRACT INFO
    //////////////////////////////

    /// @notice Contract Name Getter
    /// @dev Used to identify contract
    /// @return string contract name
    function name() external pure returns (string memory) {
        return "PlatformThemeRegistry";
    }

    /// @notice Contract Information URI Getter
    /// @dev Used to provide contract information
    /// @return string contract information uri
    function contractDocs() external view returns (string memory) {
        // return contract information uri
        return contractDocumentation;
    }

    /// @notice Contract Information URI Getter
    /// @dev Used to provide contract information
    /// @return string contract information uri
    function setContractDocs(string memory newContractDocs) onlyOwner external returns (string memory) {
        contractDocumentation = newContractDocs;
        return contractDocumentation;
    }    

    //////////////////////////////
    /// ADMIN
    //////////////////////////////

    /// @notice isAdmin getter for a target index
    /// @param platformIndex target platform index
    /// @param account account to check
    function _isAdmin(uint256 platformIndex, address account)
        internal
        view
        returns (bool)
    {
        // Return true/false depending on whether account is an admin
        return roleInfo[platformIndex][account] != Roles.ADMIN ? false : true;
    }

    /// @notice isAdmin getter for a target index
    /// @param platformIndex target platform index
    /// @param account account to check
    function _isAdminOrManager(uint256 platformIndex, address account)
        internal
        view
        returns (bool)
    {
        // Return true/false depending on whether account is an admin or manager
        return roleInfo[platformIndex][account] != Roles.NO_ROLE ? true : false;
    }    

    /// @notice Only allowed for contract admin
    /// @param platformIndex target platform index
    /// @dev only allows approved admin of platform index (from msg.sender)
    modifier onlyAdmin(uint256 platformIndex) {
        if (!_isAdmin(platformIndex, msg.sender)) {
            revert RequiresAdmin();
        }

        _;
    }

    /// @notice Only allowed for contract admin
    /// @param platformIndex target platform index
    /// @dev only allows approved managers or admins of platform index (from msg.sender)
    modifier onlyAdminOrManager(uint256 platformIndex) {
        if (!_isAdminOrManager(platformIndex, msg.sender)) {
            revert RequiresHigherRole();
        }

        _;
    }    

    /// @notice Grants new roles for given platform index
    /// @param platformIndex target platform index
    /// @param roleDetails array of roleDetails structs
    function grantRoles(uint256 platformIndex, RoleDetails[] memory roleDetails) 
        onlyAdmin(platformIndex) 
        external
    {
        // grant roles to each [account, role] provided
        for (uint256 i; i < roleDetails.length; ++i) {
            // check that role being granted is a valid role
            if (roleDetails[i].role > Roles.ADMIN) {
                revert RoleDoesntExist();
            }
            // give role to account
            roleInfo[platformIndex][roleDetails[i].account] = roleDetails[i].role;

            emit RoleGranted({
                platformIndex: platformIndex,
                sender: msg.sender,
                account: roleDetails[i].account,
                role: roleDetails[i].role
            });
        }    
    }

    /// @notice Revokes roles for given platform index
    /// @param platformIndex target platform index
    /// @param accounts array of addresses to revoke roles from
    function revokeRoles(uint256 platformIndex, address[] memory accounts) 
        onlyAdmin(platformIndex) 
        external
    {
        // revoke roles from each account provided
        for (uint256 i; i < accounts.length; ++i) {
            // revoke role from account
            roleInfo[platformIndex][accounts[i]] = Roles.NO_ROLE;

            emit RoleRevoked({
                platformIndex: platformIndex,
                sender: msg.sender,
                account: accounts[i],
                role: Roles.NO_ROLE
            });
        }    
    } 

    /// @notice Get role for given platform index + account
    /// @param platformIndex target platform index
    /// @param account address to get role for
    /// @return Roles enum value
    function getRole(uint256 platformIndex, address account) external view returns (Roles) {
        return roleInfo[platformIndex][account];
    }

    //////////////////////////////
    /// PLATFORM THEMING
    //////////////////////////////

    /// @notice Create platform index -> string
    /// @dev Used to initialize string information for rendering
    /// @param account address account to give admin role for platformIndex
    /// @param uri uri to set metadata to
    function newPlatformIndex(address account, string memory uri) external {
        // increment platformIndex counter
        ++platformCounter;
        // cache platformCounter
        (uint256 currentPlatform, address sender) = (platformCounter, msg.sender);
        // set string for new platformIndex
        platformThemeInfo[currentPlatform] = uri;
        // grant admin role to account
        roleInfo[currentPlatform][account] = Roles.ADMIN;

        emit RoleGranted({
            platformIndex: currentPlatform,
            sender: sender,
            account: account,
            role: Roles.ADMIN
        });

        emit PlatformThemeUpdated({
            platformIndex: currentPlatform,
            sender: sender,
            newTheme: uri
        });
    }    

    /// @notice Set platform theme -> string
    /// @dev Used to provide string information for rendering
    /// @param platformIndex target platform index
    /// @param uri uri to set metadata to
    function setPlatformTheme(uint256 platformIndex, string memory uri)
        external
        onlyAdminOrManager(platformIndex)
    {
        platformThemeInfo[platformIndex] = uri;
        emit PlatformThemeUpdated({
            platformIndex: platformIndex,
            sender: msg.sender,
            newTheme: uri
        });
    }

    /// @notice Getter for platformIndex -> uri string
    /// @param platformIndex target platform index
    /// @return address string for target
    function getPlatformTheme(uint256 platformIndex)
        external
        view
        returns (string memory)
    {
        return platformThemeInfo[platformIndex];
    }
}