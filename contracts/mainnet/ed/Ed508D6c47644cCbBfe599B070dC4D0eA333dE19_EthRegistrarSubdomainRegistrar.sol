/**
 *Submitted for verification at Etherscan.io on 2022-06-24
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @ensdomains/ens-contracts/contracts/registry/ENS.sol

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

// File: @ensdomains/ens-contracts/contracts/ethregistrar/BaseRegistrar.sol

pragma solidity ^0.8.4;




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

// File: contracts/EthRegistrarSubdomainRegistrar.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;



contract EthRegistrarSubdomainRegistrar {
    
    struct Domain {
        string name;
        address payable owner;
        uint256[] price;
        uint256 reserve_count;
    }

    struct Reserve {
        string name;
        bytes32 domain;
        address owner;
        uint256 subscription;
    }

    struct Exist {
        uint256 index;
        bool existed;
    }

    struct SubIndex {
        uint256 index;
        uint256 expiration;
        address owner;
        bool existed;
        uint256 createdAt;
    }

    // namehash('eth')
    bytes32 constant public TLD_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    bool public stopped = false;

    address public registrarOwner;
    address public registrar;
    address payable treasury;

    ENS public ens;

    uint256 public reserve_fee = 500;
    uint256 public list_fee = 0.02 ether;
    uint256[4] expiration = [30 days, 180 days, 365 days, ~uint256(0)];

    Domain[] public domains;
    Reserve[] public reserves;

    mapping(bytes32 => Exist) domain_index;
    mapping(bytes32 => mapping(string => SubIndex)) reserve_indexes;

    event NewRegistration(string domain, string subdomain, address owner, address reserver, uint256 price, uint256 createdAt);
    event DomainConfigured(bytes32 indexed label);
    event DomainUnlisted(bytes32 indexed label);
    
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


    constructor(ENS _ens) {
        ens = _ens;
        registrar = ens.owner(TLD_NODE);
        registrarOwner = msg.sender;
        treasury = payable(msg.sender);
    }

    function doRegistration(bytes32 node, bytes32 label, address subdomainOwner, address resolver) internal {
        // Get the subdomain so we can configure it
        ens.setSubnodeRecord(node, label, subdomainOwner, resolver, getTTL(node));
    }

    function getTTL(bytes32 node) public view returns(uint64) {
        return ens.ttl(node);
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
        return BaseRegistrar(registrar).ownerOf(uint256(label));
    }

    /**
     * @dev Configures a domain, optionally transferring it to a new owner.
     * @param name The name to configure.
     * @param price The price in wei to charge for subdomain registrations.
     *        when the permanent registrar is replaced. Can only be set to a non-zero
     *        value once.
     */
    function configureDomainFor(string memory name, uint256[] memory price) public payable {
        bytes32 label = keccak256(bytes(name));
        Exist memory key = domain_index[label];

        require(!key.existed, "already listed");
        require(msg.value >= list_fee, "not enough fee");
        require(price.length == 4, "not correct price list");
        
        treasury.transfer(msg.value);

        domain_index[label] = Exist(domains.length, true);
        Domain memory new_domain = Domain(name, payable(msg.sender), price, 0);
        domains.push(new_domain);

        emit DomainConfigured(label);
    }

    /**
     * @dev Unlists a domain
     * May only be called by the owner.
     * @param name The name of the domain to unlist.
     */
    function unlistDomain(string memory name) public owner_only(keccak256(bytes(name))) {
        bytes32 label = keccak256(bytes(name));
        Exist memory key = domain_index[label];

        Domain memory domain = domains[key.index];

        require(key.existed, "no domain listed");
        require(domain.reserve_count == 0, "existing reserve yet");

        if (keccak256(bytes(domain.name)) == label) {
            domains[key.index] = domains[domains.length - 1];
            bytes32 lastLabel = keccak256(bytes(domains[domains.length - 1].name));
            domain_index[lastLabel].index = key.index;
            domains.pop();
            delete domain_index[label];
        }

        emit DomainUnlisted(label);
    }

    /**
     * @dev Registers a subdomain.
     * @param label The label hash of the domain to register a subdomain of.
     * @param subdomain The desired subdomain label.
     */

    function register(bytes32 label, string calldata subdomain, address resolver) external not_stopped owner_only(label) {
        Exist memory domain_key = domain_index[label];
        SubIndex memory reserve_key = reserve_indexes[label][subdomain];

        require(domain_key.existed, "no domain listed");
        
        Domain memory domain = domains[domain_key.index];
        Reserve memory reserve = reserves[reserve_key.index];
        
        require(reserve.owner != address(0) || !reserve_key.existed, "no reserved");
        require(reserve.domain == label, "not matched domain");

        uint256 expires = reserve.subscription < 3 ? block.timestamp + expiration[reserve.subscription] : expiration[reserve.subscription];
        reserves[reserve_key.index] = reserves[reserves.length - 1];
        reserve_indexes[label][reserves[reserve_key.index].name] = SubIndex(reserve_key.index, 0, reserves[reserve_key.index].owner, true, 0);
        reserve_indexes[label][subdomain] = SubIndex(0, expires, reserve.owner, false, block.timestamp);
        reserves.pop();

        address subdomainOwner = reserve.owner;
        bytes32 domainNode = keccak256(abi.encodePacked(TLD_NODE, label));
        bytes32 subdomainLabel = keccak256(bytes(subdomain));

        uint256 total = domain.price[reserve.subscription];
        
        if (reserve_fee > 0) {
            uint256 reserveFee = (domain.price[reserve.subscription] * reserve_fee) / 10000;
            treasury.transfer(reserveFee);
            total -= reserveFee;
        }

        // Send the registration fee
        if (total > 0) {
            domain.owner.transfer(total);
        }

        doRegistration(domainNode, subdomainLabel, subdomainOwner, resolver);
        
        emit NewRegistration(domain.name, subdomain, msg.sender, subdomainOwner, domain.price[reserve.subscription], block.timestamp);
    }

    function queryEntireDomains() public view returns(Domain[] memory) {
        return domains;
    }

    function queryDomain(bytes32 label) public view returns(Domain memory) {
        Exist memory key = domain_index[label];
        require(key.existed, "no domain listed");
        return domains[key.index];
    }

    function queryReservesList() public view returns(Reserve[] memory) {
        return reserves;
    }

    function reserveSubdomain(bytes32 label, string calldata subdomain, uint subscription) external payable {
        Exist memory domain_key = domain_index[label];
        SubIndex memory reserve_key = reserve_indexes[label][subdomain];

        require(domain_key.existed, "no domain listed");
        require(!reserve_key.existed, "no reserved");
        require(reserve_key.expiration < block.timestamp, "not available until expire");
        require(address(domains[domain_key.index].owner) != address(0), "no domain listed");
        // require(reserves[domain_key.index].domain == "", "someone already requested");
        require(msg.value >= domains[domain_key.index].price[subscription], "not enough fee");

        reserve_indexes[label][subdomain] = SubIndex(reserves.length, 0, msg.sender, true, 0);
        reserves.push(Reserve(subdomain, label, msg.sender, subscription));
    }

    function declineSubdomain(bytes32 label, string calldata subdomain) external {
        SubIndex memory reserve_key = reserve_indexes[label][subdomain];

        uint256 domain_inx = domain_index[label].index;
        uint256 index = reserve_key.index;

        require(reserve_key.existed, "no reserved");

        Reserve memory reserve = reserves[index];
        
        require(reserve.domain == label, "no domain exist");
        require(keccak256(bytes(domains[domain_inx].name)) == label, "no domain exist");
        require(reserve.owner == msg.sender || msg.sender == owner(label), "no reserve exist");

        Domain memory domain = domains[domain_inx];
        payable(reserve.owner).transfer(domain.price[reserve.subscription]);
        
        reserves[index] = reserves[reserves.length - 1];
        reserve_indexes[reserves[index].domain][reserves[index].name] = SubIndex(index, 0, reserves[index].owner, true, 0);

        reserves.pop();
        delete reserve_indexes[label][subdomain];
    }

    function updateListFee(uint _fee) external registrar_owner_only {
        list_fee = _fee;
    }

    function updateReserveFee(uint _fee) external registrar_owner_only {
        require(_fee < 10000);
        reserve_fee = _fee;
    }

    function updateTreasuryWallet(address account) external registrar_owner_only {
        require(account != address(0), "not valid account");
        treasury = payable(account);
    }

    function removeSubdomain(bytes32 label, string memory subdomain) external {
        SubIndex memory existed = reserve_indexes[label][subdomain];
        uint256 do_index = domain_index[label].index;

        require(existed.owner == msg.sender || address(domains[do_index].owner) == msg.sender, "only available reserver or domain owner");
        if (address(domains[do_index].owner) == msg.sender) {
            require(existed.expiration < block.timestamp, "not available until expire");
        }
        
        delete reserve_indexes[label][subdomain];
    }

    function getReserveIndex(bytes32 label, string memory subdomain) public view returns(SubIndex memory) {
        return reserve_indexes[label][subdomain];
    }
}