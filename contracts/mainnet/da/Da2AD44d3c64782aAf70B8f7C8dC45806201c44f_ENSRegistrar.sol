/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

pragma solidity 0.6.0;

// File: @openzeppelin/contracts-upgradeable/proxy/Initializable.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24 <0.7.0;
/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;
    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;
    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");
        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
        }
    }
    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}
// File: @openzeppelin/contracts-upgradeable/GSN/ContextUpgradeable.sol
// SPDX-License-Identifier: MIT
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }
    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}
// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol
// SPDX-License-Identifier: MIT
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
contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }
    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}
// File: contracts/ENSRegistrar.sol
// SPDX-License-Identifier: UNLICENSED
interface ENS {
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
    function setOwner(bytes32 node, address owner) external;
    function owner(bytes32 node) external view returns (address);
}
interface Resolver{
    function setAddr(bytes32 node, address addr) external;
    function setAddr(bytes32 node, uint coinType, bytes calldata a) external;
}
/**
 * A registrar that allocates subdomains to the first person to claim them.
 */
contract ENSRegistrar is Initializable, OwnableUpgradeable {
    event NameClaimed(address indexed series, string value);
    // Master ENS registry
    ENS ens;
    // The otoco.eth node reference
    bytes32 rootNode;
    // Default resolver to deal with data storage
    Resolver defaultResolver;
    // Mapping of Company address => Domains
    mapping(address => string[]) internal seriesDomains;
    modifier only_owner(bytes32 label) {
        address currentOwner = ens.owner(keccak256(abi.encodePacked(rootNode, label)));
        require(currentOwner == address(0x0) || currentOwner == msg.sender);
        _;
    }
    modifier only_series_manager(OwnableUpgradeable series) {
        require(series.owner() == msg.sender, 'Not the series manager.');
        _;
    }
    /**
     * Constructor.
     * @param ensAddr The address of the ENS registry.
     * @param resolverAddr The resolver where domains will use to register.
     * @param node The node that this registrar administers.
     * @param previousSeries Previous series to be migrated.
     * @param previousDomains Previous domains to be migrated.
     */
    function initialize(ENS ensAddr, Resolver resolverAddr, bytes32 node, address[] calldata previousSeries, bytes32[] calldata previousDomains) external {
        require(previousSeries.length == previousDomains.length, 'Previous series size different than previous tokens size.');
        __Ownable_init();
        ens = ensAddr;
        rootNode = node;
        defaultResolver = resolverAddr;
        for (uint i = 0; i < previousSeries.length; i++ ) {
            emit NameClaimed(previousSeries[i], bytes32ToString(previousDomains[i]));
            seriesDomains[previousSeries[i]].push(bytes32ToString(previousDomains[i]));
        }
    }
    /**
     * Register a name, or change the owner of an existing registration.
     * @param label The hash of the label to register.
     * @param owner The address of the new owner(Series Manager).
     * @param addr Address to redirect domain
     */
    function register(bytes32 label, address owner, address addr) public only_owner(label) {
        bytes32 node = keccak256(abi.encodePacked(rootNode, label));
        ens.setSubnodeRecord(rootNode, label, address(this), address(defaultResolver) ,63072000);
        defaultResolver.setAddr(node, addr);
        ens.setOwner(node, owner);
    }
    /**
     * Register a name, and store the domain to reverse lookup.
     * @param domain The string containing the domain.
     * @param target Series contract that registry will point.
     * @param addr Address to redirect domain
     */
    function registerAndStore(string memory domain, OwnableUpgradeable target, address addr) public only_series_manager(target) {
        bytes32 label = keccak256(abi.encodePacked(domain));
        register(label, msg.sender, addr);
        seriesDomains[address(target)].push(domain);
        emit NameClaimed(address(target), domain);
    }
    /**
     * Return some domain from a series. As a single series could claim multiple domains, 
     * the resolve function here has a index parameter to point a specific domain to be retrieved.
     * @param addr The string containing the addr.
     * @param index Domain index to be retrieved.
     */
    function resolve(address addr, uint8 index) public view returns(string memory) {
        return seriesDomains[addr][index];
    }
    /**
     * Return how much domains the Series has registered using this Registrar.
     * @param addr The string containing the series address.
     */
    function ownedDomains(address addr) public view returns(uint) {
        return seriesDomains[addr].length;
    }
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}