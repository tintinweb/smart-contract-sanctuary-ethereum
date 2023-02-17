/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/EmberSubdomainRegistrar.sol


pragma solidity 0.8.17;

interface ENSRegistry {

function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setOwner(bytes32 node, address owner) external;

     function owner(bytes32 node) external view  returns (address);
}

interface OwnedResolver {
     function addr(bytes32 node) external view returns (address payable);
     function setAddr(bytes32 node, address a) external;
    
}


/// @title Ember.eth Subdomain Registrar
/// @author @hammadghazi007
/// @notice An ENS registrar that allocates subdomains of ember.eth
contract EmberSubdomainRegistrar is Ownable {
    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the ENSRegistry contract.
    ENSRegistry public ens;

    /// @notice The address of the public resolver contract.
    OwnedResolver public resolver;

    /*//////////////////////////////////////////////////////////////
                           DOMAIN CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Output of namehash(".ember")
    bytes32 public constant domainNodeHash =
        0x3400f7f1ebe191e290b173723c7f7361b7cef3874ac766898f07be62c0b798ed;

    /// @notice Domain name owned by this contract.
    string public constant domainName = "ember";

    /*//////////////////////////////////////////////////////////////
                      SUBDOMAIN REGISTRATION STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping to store latest registered subdomain node hash of an address
    mapping(address => bytes32) public lastRegistered;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event ENSChanged(address);
    event ResolverChanged(address);
    event SubdomainRegistered(
        address indexed registrar,
        string indexed subdomainName,
        bytes32 subdomainNameHash,
        bytes32 subdomainNodeHash
    );

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error InputLengthMismatch();
    error SubdomainAlreadyRegistered();
    error ZeroAddress();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets ENS contracts addresses
    constructor(ENSRegistry ensRegistry, OwnedResolver ownedResolver) {
        ens = ENSRegistry(ensRegistry);
        resolver = OwnedResolver(ownedResolver);
    }

    /*//////////////////////////////////////////////////////////////
                            SETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets ENSRegistry contract address. Can only be called by the owner of this contract.
    /// @param _ens Address of the new ENS Registry contract.
    function setENS(ENSRegistry _ens) external onlyOwner {
        if (address(_ens) == address(0)) {
            revert ZeroAddress();
        }

        ens = _ens;
        emit ENSChanged(address(_ens));
    }

    /// @notice Sets Resolver contract address. Can only be called by the owner of this contract.
    /// @param _resolver Address of the new Resolver contract.
    function setResolver(OwnedResolver _resolver) external onlyOwner {
        if (address(_resolver) == address(0)) {
            revert ZeroAddress();
        }

        resolver = _resolver;
        emit ResolverChanged(address(_resolver));
    }


    /*//////////////////////////////////////////////////////////////
                        REGISTER SUBDOMAIN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Registers subdomain of emberWallet.eth.
    /// @dev Will revert if subdomain name is already registered
    /// or if caller address owns the latest registered subdomain name in ENS registry contract
    /// or if caller address is associated with the latest registered subdomain name.
    /// @param _subdomainOwners addresses of the subdomains owner.
    /// @param _subdomainNames names of the subdomains to register.
    function register(address[] calldata _subdomainOwners, string[] calldata _subdomainNames) external onlyOwner {
        if(_subdomainOwners.length!=_subdomainNames.length) {
            revert InputLengthMismatch();
        }

        for (uint256 i;i<_subdomainOwners.length;){
        // Label hash of this subdomain
        bytes32 subdomainNameHash = keccak256(bytes(_subdomainNames[i]));

        // The nodehash of this subdomain
        bytes32 subdomainNodeHash = keccak256(
            abi.encodePacked(domainNodeHash, subdomainNameHash)
        );

        // Subdomain must not be registered already.
        if (ens.owner(subdomainNodeHash) != address(0)) {
            revert SubdomainAlreadyRegistered();
        }

        // Registering subdomain. Registering at this address so we can configure it
        ens.setSubnodeRecord(
            domainNodeHash,
            subdomainNameHash,
            address(this),
            address(resolver),
            0
        );

        // Set the address record on the resolver contract
        resolver.setAddr(subdomainNodeHash, _subdomainOwners[i]);

        // Transfer ownership of the new subdomain to the registrant
        ens.setOwner(subdomainNodeHash, _subdomainOwners[i]);

        emit SubdomainRegistered(_subdomainOwners[i], _subdomainNames[i],subdomainNameHash,subdomainNodeHash);

        unchecked{
            ++i;
        }
        }
    }
}