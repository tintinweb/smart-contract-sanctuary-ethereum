//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@ensdomains/ens-contracts/contracts/ethregistrar/BaseRegistrar.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "./Resolver.sol";
import "./RegistrarInterface.sol";

/**
 * @dev Implements an ENS registrar that sells subdomains on behalf of their owners.
 *
 * Users may register a subdomain by calling `register` with the name of the domain
 * they wish to register under, and the label hash of the subdomain they want to
 * register. They must also specify the new owner of the domain, and the referrer,
 * who is paid an optional finder's fee. The registrar then configures a simple
 * default resolver, which resolves `addr` lookups to the new owner, and sets
 * the `owner` account as the owner of the subdomain in ENS.
 *
 * New domains may be added by calling `configureDomain`, then transferring
 * ownership in the ENS registry to this contract. Ownership in the contract
 * may be transferred using `transfer`, and a domain may be unlisted for sale
 * using `unlistDomain`. There is (deliberately) no way to recover ownership
 * in ENS once the name is transferred to this registrar.
 *
 * Critically, this contract does not check one key property of a listed domain:
 *
 * - Is the name UTS46 normalised?
 *
 * User applications MUST check these two elements for each domain before
 * offering them to users for registration.
 *
 * Applications should additionally check that the domains they are offering to
 * register are controlled by this registrar, since calls to `register` will
 * fail if this is not the case.
 */

contract EthRegistrarSubdomainRegistrar is RegistrarInterface {
    
    struct Domain {
        string name;
        address payable owner;
        uint[] price;
        bool existed;
        uint entire_index;
        uint label_index;
        string[] reserves;
    }

    struct Reserve {
        bytes32 domain;
        address owner;
        uint subscription;
        uint index;
    }

    // namehash('eth')
    bytes32 constant public TLD_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    bool public stopped = false;

    address public registrarOwner;
    address public registrar;

    ENS public ens;

    uint256 public reserve_fee = 500;
    uint256 public list_fee = 0.01 ether;

    address payable treasury;

    bytes32[] public domains;
    mapping (bytes32 => Domain) domain_property;
    mapping (address => bytes32[]) labels;
    mapping (string => Reserve) reserve_property;

    modifier owner_only(bytes32 label) {
        require(owner(label) == msg.sender, "not domain owner");
        _;
    }

    modifier not_stopped() {
        require(!stopped);
        _;
    }

    modifier registrar_owner_only() {
        require(msg.sender == registrarOwner, "not registrar owner");
        _;
    }

    event DomainTransferred(bytes32 indexed label, string name);

    constructor(ENS _ens) {
        ens = _ens;
        registrar = ens.owner(TLD_NODE);
        registrarOwner = msg.sender;
        treasury = payable(msg.sender);
    }

    function doRegistration(bytes32 node, bytes32 label, address subdomainOwner, Resolver resolver) internal {
        // Get the subdomain so we can configure it
        ens.setSubnodeOwner(node, label, address(this));

        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        // Set the subdomain's resolver
        ens.setResolver(subnode, address(resolver));

        // Set the address record on the resolver
        resolver.setAddr(subnode, subdomainOwner);

        // Pass ownership of the new subdomain to the registrant
        ens.setOwner(subnode, subdomainOwner);
    }

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return (
            (interfaceID == 0x01ffc9a7) // supportsInterface(bytes4)
            || (interfaceID == 0xc1b15f5a) // RegistrarInterface
        );
    }

    /**
     * @dev Stops the registrar, disabling configuring of new domains.
     */
    function stop() public not_stopped registrar_owner_only {
        stopped = true;
    }

    function transferOwnership(address newOwner) public registrar_owner_only {
        registrarOwner = newOwner;
    }

    /**
     * @dev owner returns the address of the account that controls a domain.
     *      Initially this is a null address. If the name has been
     *      transferred to this contract, then the internal mapping is consulted
     *      to determine who controls it. If the owner is not set,
     *      the owner of the domain in the Registrar is returned.
     * @param label The label hash of the deed to check.
     * @return The address owning the deed.
     */
    function owner(bytes32 label) public view returns (address) {
        // if (domain_property[label].owner != address(0x0)) {
        //     return domain_property[label].owner;
        // }

        return BaseRegistrar(registrar).ownerOf(uint256(label));
    }

    /**
     * @dev Configures a domain, optionally transferring it to a new owner.
     * @param name The name to configure.
     * @param price The price in wei to charge for subdomain registrations.
     *        when the permanent registrar is replaced. Can only be set to a non-zero
     *        value once.
     */
    function configureDomainFor(string memory name, uint[] memory price) public owner_only(keccak256(bytes(name))) payable {
        require(msg.value >= list_fee, "not enough fee");
        require(price.length == 4, "not correct price list");
        
        treasury.transfer(msg.value);

        bytes32 label = keccak256(bytes(name));
        Domain storage domain = domain_property[label];

        // if (address(domain.owner) != msg.sender) {
        //     domain.owner = payable(msg.sender);
        // }

        // if (domains[domain.entire_index] != label) {
        //     domain.entire_index = domains.length;
        //     domains.push(label);
        // }

        // if (keccak256(bytes(domain.name)) != label) {
        //     domain.name = name;
        // }

        // domain.price = price;
        // if (!domain.existed) {
        //     domain.label_index = labels[msg.sender].length;
        //     labels[msg.sender].push(label);
        // }

        // else {
        //     if (labels[msg.sender][domain.label_index] != label) {
        //         if (labels[msg.sender].length < domain.label_index) {
        //             domain.label_index = labels[msg.sender].length;
        //             labels[msg.sender].push(label);
        //         }
        //     }
        // }

        emit DomainConfigured(label);
    }

    /**
     * @dev Unlists a domain
     * May only be called by the owner.
     * @param name The name of the domain to unlist.
     */
    function unlistDomain(string memory name) public owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        Domain memory domain = domain_property[label];
        require((domain.reserves).length == 0, "existing reserve yet");

        if (domains[domain.entire_index] == label) delete domains[domain.entire_index];
        if (labels[domain.owner][domain.label_index] == label) delete labels[domain.owner][domain.label_index];

        emit DomainUnlisted(label);
    }

    /**
     * @dev Registers a subdomain.
     * @param label The label hash of the domain to register a subdomain of.
     * @param subdomain The desired subdomain label.
     */

    function register(bytes32 label, string calldata subdomain, address resolver) external not_stopped owner_only(label) {
        Reserve memory _reserve = reserve_property[subdomain];
        Domain memory domain = domain_property[label];

        require(_reserve.owner != address(0), "no reserved");
        require(_reserve.domain == label, "not matched domain");
        require(keccak256(bytes(domain.name)) == label);

        address subdomainOwner = _reserve.owner;
        bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes32 subdomainLabel = keccak256(bytes(subdomain));

        // Subdomain must not be registered already.
        require(ens.owner(keccak256(abi.encodePacked(domainNode, subdomainLabel))) == address(0));
        // Send any referral fee
        uint256 total = domain.price[_reserve.subscription];
        if (reserve_fee > 0) {
            uint256 reserveFee = (domain.price[_reserve.subscription] * reserve_fee) / 10000;
            treasury.transfer(reserveFee);
            total -= reserveFee;
        }

        // Send the registration fee
        if (total > 0) {
            domain.owner.transfer(total);
        }

        doRegistration(domainNode, subdomainLabel, subdomainOwner, Resolver(resolver));

        emit NewRegistration(label, subdomain, subdomainOwner, treasury, domain.price[_reserve.subscription]);
    }

    function queryEntireDomains() public view returns(bytes32[] memory) {
        return domains;
    }

    function queryDomain(bytes32 name) public view returns(Domain memory) {
        return domain_property[name];
    }

    function queryLabels(address _owner) public view returns(bytes32[] memory) {
        return labels[_owner];
    }
    
    function queryReservesList(bytes32 label) public view returns(string[] memory) {
        return domain_property[label].reserves;
    }

    function queryReserves(string memory name) public view returns(Reserve memory) {
        return reserve_property[name];
    }
    
    function reserveSubdomain(bytes32 label, string calldata subdomain, uint subscription) external payable {
        require(domain_property[label].existed, "no domain listed");
        require(reserve_property[subdomain].domain == "", "someone already requested");
        require(msg.value >= domain_property[label].price[subscription], "not enough fee");

        string[] storage reserves = domain_property[label].reserves;
        reserves.push(subdomain);
        reserve_property[subdomain] = Reserve(label, msg.sender, subscription, reserves.length);
    }

    function declineSubdomain(string calldata subdomain) external {
        Reserve memory reserve = reserve_property[subdomain];
        require(reserve.owner != address(0), "no reserve exist");
        require(reserve.owner == msg.sender || msg.sender == owner(reserve.domain), "no reserve exist");
        delete reserve_property[subdomain];
        delete domain_property[reserve.domain].reserves[reserve.index];
    }

    function updateListFee(uint _fee) external registrar_owner_only {
        list_fee = _fee;
    }

    function updateReserveFee(uint _fee) external registrar_owner_only {
        reserve_fee = _fee;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";

/**
 * @dev A basic interface for ENS resolvers.
 */
interface Resolver {
    function supportsInterface(bytes4 interfaceID) external pure returns (bool);
    function addr(bytes32 node) external view returns (address);
    function setAddr(bytes32 node, address addr) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface RegistrarInterface {
    event OwnerChanged(bytes32 indexed label, address indexed oldOwner, address indexed newOwner);
    event DomainConfigured(bytes32 indexed label);
    event DomainUnlisted(bytes32 indexed label);
    event NewRegistration(bytes32 indexed label, string subdomain, address indexed owner, address indexed referrer, uint price);
    event RentPaid(bytes32 indexed label, string subdomain, uint amount, uint expirationDate);

    // InterfaceID of these four methods is 0xc1b15f5a
    // function query(bytes32 label, string calldata subdomain) external view returns (string memory domain, uint signupFee, uint rent, uint referralFeePPM);
    // function register(bytes32 label, string calldata subdomain) external payable;

    // function rentDue(bytes32 label, string calldata subdomain) external view returns (uint timestamp);
    // function payRent(bytes32 label, string calldata subdomain) external payable;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

pragma solidity >=0.8.4;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}

pragma solidity ^0.8.4;

import "../registry/ENS.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseRegistrar is Ownable, IERC721 {
    uint constant public GRACE_PERIOD = 90 days;

    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(uint256 indexed id, address indexed owner, uint expires);
    event NameRegistered(uint256 indexed id, address indexed owner, uint expires);
    event NameRenewed(uint256 indexed id, uint expires);

    // The ENS registry
    ENS public ens;

    // The namehash of the TLD this registrar owns (eg, .eth)
    bytes32 public baseNode;

    // A map of addresses that are authorised to register and renew names.
    mapping(address=>bool) public controllers;

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) virtual external;

    // Revoke controller permission for an address.
    function removeController(address controller) virtual external;

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) virtual external;

    // Returns the expiration timestamp of the specified label hash.
    function nameExpires(uint256 id) virtual external view returns(uint);

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) virtual public view returns(bool);

    /**
     * @dev Register a name.
     */
    function register(uint256 id, address owner, uint duration) virtual external returns(uint);

    function renew(uint256 id, uint duration) virtual external returns(uint);

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) virtual external;
}