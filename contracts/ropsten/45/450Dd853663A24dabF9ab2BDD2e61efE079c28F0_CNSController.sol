//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/Resolver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IBaseRegistrarImplementation.sol";
import "./structures/CNSStructure.sol";

contract CNSController {
    /**
     * ENS registry contract.
     */
    ENS internal ens;
    IBaseRegistrarImplementation internal registrar;
    Resolver internal resolver;
    address internal resolverAddress;

    mapping(string => domain) public domains;
    mapping(string => subdomain) public subdomains;
    mapping(string => uint256) public domain_count;
    mapping(string => uint256) public subdomain_count;
    mapping(string => policy) public domainPolicy;
    mapping(string => policy_1) internal policy1;
    mapping(string => policy_2) internal policy2;

    string[] public domainList;

    /**
     * Modefier Only domain owner will have permission to call function.
     */
    modifier onlyDomainOwner(string memory _domain) {
        require(msg.sender == domains[_domain].owner);
        _;
    }

    /**
     * Modifier to check registered domains.
     */
    modifier isRegistered(string memory _domain) {
        require(domains[_domain].owner != address(0));
        _;
    }

    modifier isNotRegistered(string memory _domain) {
        require(domains[_domain].owner == address(0));
        _;
    }

    modifier isNotCreatePolicy(string memory _domain) {
        require(
            domainPolicy[_domain].policy != 1 ||
                domainPolicy[_domain].policy != 2
        );
        _;
    }

    modifier isCreatePolicy(string memory _domain) {
        require(
            domainPolicy[_domain].policy == 1 ||
                domainPolicy[_domain].policy == 2
        );
        _;
    }

    modifier isPolicy1(string memory _domain) {
        require(domainPolicy[_domain].policy == 1);
        _;
    }

    modifier isPolicy2(string memory _domain) {
        require(domainPolicy[_domain].policy == 2);
        _;
    }

    modifier isSetTokenAddress(string memory _domain) {
        require(
            policy2[_domain].tokenAddress != address(0) &&
                policy2[_domain].tokenAmount != 0
        );
        _;
    }

    /**
     * Constructor.
     * @param ensAddr The address of the ENS registry.
     */
    constructor(
        address ensAddr,
        address baseRegistrarAddr,
        address resolverAddr
    ) {
        require(address(ensAddr) != address(0), "Invalid address");
        require(address(baseRegistrarAddr) != address(0), "Invalid address");
        require(address(resolverAddr) != address(0), "Invalid address");

        ens = ENS(ensAddr);
        registrar = IBaseRegistrarImplementation(baseRegistrarAddr);
        resolver = Resolver(resolverAddr);
        resolverAddress = resolverAddr;
    }

    /**
     * Register domain to CNS
     */
    function domainRegister(
        uint256 _tokenId,
        string memory _domain,
        bytes32 _node
    ) public isNotRegistered(_domain) {
        require(
            registrar.ownerOf(_tokenId) == msg.sender,
            "Only owner can register domain"
        );
        domains[_domain].owner = msg.sender;
        domains[_domain].node = _node;
        domains[_domain].tokenId = _tokenId;
        domains[_domain].domain = _domain;
        domain_count[_domain] = domain_count[_domain] + 1;
        domainList.push(_domain);
    }

    /**
     * Get Domain Owner.
     */
    function getDomainOwner(string memory _domain)
        public
        view
        returns (address)
    {
        return domains[_domain].owner;
    }

    /**
     * Get Domain Token Id.
     */
    function getDomainTokenId(string memory _domain)
        public
        view
        returns (uint256)
    {
        return domains[_domain].tokenId;
    }

    /**
     * Register a name, or change the owner of an existing registration.
     * @param _subdomain The hash of the label to register.
     * @param _tokenId if register with policy 2 please provide tokenId that user holding. if register with policy 1 please provide 0.
     */
    function setSubdomain(
        string memory _domain,
        string memory _subdomain,
        bytes32 _node,
        bytes32 _subnode,
        uint256 _tokenId
    ) public {
        require(
            _node == domains[_domain].node,
            "Node is not correct or this domain is not registered"
        );
        _setSubdomain(
            _domain,
            _node,
            keccak256(abi.encodePacked(_subdomain)),
            _subnode,
            _subdomain,
            _tokenId
        );
    }

    /**
     * Register a name, or change the owner of an existing registration.
     * @param label The hash of the label to register.
     */
    function _setSubdomain(
        string memory _domain,
        bytes32 _node,
        bytes32 label,
        bytes32 _subnode,
        string memory _subdomain,
        uint256 _tokenId
    ) internal isCreatePolicy(_domain) {
        uint256 _policy = domainPolicy[_domain].policy;
        if (_policy == 1) {
            require(canMintwithPolicy1(_domain), "Cannot mint subdomain");
            ens.setSubnodeRecord(
                _node,
                label,
                address(this),
                resolverAddress,
                0
            );
            //Set subdomain address to ENS
            resolver.setAddr(_subnode, msg.sender);
            //Register subdomain to CNS
            subdomain memory _subdomainData = subdomain(
                msg.sender,
                _domain,
                _subdomain,
                0
            );
            subdomains[_subdomain] = _subdomainData;
            subdomain_count[_domain] = subdomain_count[_domain] + 1;

            setMintPermissionToZero(_domain);
        } else if (_policy == 2) {
            require(_tokenId != 0, "Token Id is not set");
            require(
                IERC721(policy2[_domain].tokenAddress).ownerOf(_tokenId) ==
                    msg.sender,
                "You do not own this token"
            );
            require(
                canMintwithPolicy2(_domain, _tokenId, _subdomain),
                "Cannot mint subdomain"
            );

            ens.setSubnodeRecord(
                _node,
                label,
                address(this),
                resolverAddress,
                0
            );
            //Set subdomain address to ENS
            resolver.setAddr(_subnode, msg.sender);
            //Register subdomain to CNS
            subdomain memory _subdomainData = subdomain(
                msg.sender,
                _domain,
                _subdomain,
                _tokenId
            );
            subdomains[_subdomain] = _subdomainData;
            subdomain_count[_domain] = subdomain_count[_domain] + 1;
            setMintPermissionToZero(_domain);
        }
    }

    //set mintAmount to 0
    function setMintPermissionToZero(string memory _domain) internal {
        for (uint256 i = 0; i < policy1[_domain].allowlists.length; i++) {
            if (policy1[_domain].allowlists[i].account == msg.sender) {
                policy1[_domain].allowlists[i].mintAmount = 0;
            }
        }
    }

    /**
     * function check can mint subdomain for policy 1
     */
    function canMintwithPolicy1(string memory _domain)
        internal
        view
        isPolicy1(_domain)
        returns (bool)
    {
        bool _canMint = false;

        for (uint256 i = 0; i < policy1[_domain].allowlists.length; i++) {
            if (
                policy1[_domain].allowlists[i].account == msg.sender &&
                policy1[_domain].allowlists[i].mintAmount > 0
            ) {
                _canMint = true;
                break;
            }
        }

        return _canMint;
    }

    /**
     * function check can mint subdomain for policy 2
     */
    function canMintwithPolicy2(
        string memory _domain,
        uint256 _tokenId,
        string memory _subdomain
    )
        internal
        view
        isPolicy2(_domain)
        isSetTokenAddress(_domain)
        returns (bool)
    {
        bool _canMint = false;
        uint256 _holdingBalance = getTokenHoldingBalance(_domain, msg.sender);

        if (_holdingBalance >= policy2[_domain].tokenAmount) {
            //check minted with NFT tokenID
            if (
                subdomains[_subdomain].owner == msg.sender &&
                subdomains[_subdomain].tokenId == _tokenId
            ) {
                _canMint = false;
            } else {
                _canMint = true;
            }
        }

        return _canMint;
    }

    /**
     * Get Domain that users registered.
     */
    function getMembers() public view returns (string[] memory) {
        return domainList;
    }

    /**
     * Create policy to domain that registered
     */
    function createPolicy(string memory _domain, uint256 _policy)
        public
        onlyDomainOwner(_domain)
        isNotCreatePolicy(_domain)
    {
        require(_policy == 1 || _policy == 2, "Invalid policy");
        domainPolicy[_domain].policy = _policy;
        if (_policy == 1) {
            policy1[_domain].domain = _domain;
        } else if (_policy == 2) {
            policy2[_domain].domain = _domain;
        }
    }

    /**
     * function change policy to domain that registered and remove data of old policy
     */
    function changePolicy(string memory _domain, uint256 _policy)
        public
        onlyDomainOwner(_domain)
        isCreatePolicy(_domain)
    {
        require(_policy == 1 || _policy == 2, "Invalid policy");
        if (_policy == 1) {
            domainPolicy[_domain].policy = 1;
            delete policy2[_domain];
        } else if (_policy == 2) {
            domainPolicy[_domain].policy = 2;
            delete policy1[_domain];
        }
    }

    /**
     * function get domain policy
     */
    function getPolicy(string memory _domain) public view returns (uint256) {
        return domainPolicy[_domain].policy;
    }

    /**
     * Add allowlist for policy 1
     */
    function addAllowlist(string memory _domain, address _address)
        public
        onlyDomainOwner(_domain)
        isPolicy1(_domain)
    {
        allowlistDetail memory _allowlist = allowlistDetail(_address, 1);
        policy1[_domain].allowlists.push(_allowlist);
    }

    /**
     * Add multiple Allowlists with array of address
     */
    function addMultipleAllowlists(
        string memory _domain,
        address[] memory _address
    ) public onlyDomainOwner(_domain) isPolicy1(_domain) {
        for (uint256 i = 0; i < _address.length; i++) {
            allowlistDetail memory _allowlist = allowlistDetail(_address[i], 1);
            policy1[_domain].allowlists.push(_allowlist);
        }
    }

    /**
     * function remove allowlist
     */
    function removeAllowlist(string memory _domain, address _address)
        public
        onlyDomainOwner(_domain)
        isPolicy1(_domain)
    {
        require(_address != address(0), "Invalid address");
        for (uint256 i = 0; i < policy1[_domain].allowlists.length; i++) {
            if (policy1[_domain].allowlists[i].account == _address) {
                delete policy1[_domain].allowlists[i];
                break;
            }
        }
    }

    /**
     * get allowlist for policy 1
     */
    function getAllowlist(string memory _domain)
        public
        view
        returns (address[] memory)
    {
        address[] memory _allowlists;
        for (uint256 i = 0; i < policy1[_domain].allowlists.length; i++) {
            _allowlists[i] = policy1[_domain].allowlists[i].account;
        }
        return _allowlists;
    }

    /**
     * set Token address for policy 2
     */
    function setTokenAddressPolicy2(
        string memory _domain,
        address _tokenAddress,
        uint256 _amount
    ) public onlyDomainOwner(_domain) isPolicy2(_domain) {
        policy2[_domain].tokenAddress = _tokenAddress;
        policy2[_domain].tokenAmount = _amount;
    }

    /**
     * get token balance for policy 2
     */
    function getTokenHoldingBalance(string memory _domain, address _account)
        internal
        view
        returns (uint256)
    {
        return IERC721(policy2[_domain].tokenAddress).balanceOf(_account);
    }

    /**
     * get community person count
     */
    function getCommunityCount(string memory _domain)
        public
        view
        returns (uint256)
    {
        return subdomain_count[_domain];
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./profiles/IABIResolver.sol";
import "./profiles/IAddressResolver.sol";
import "./profiles/IAddrResolver.sol";
import "./profiles/IContentHashResolver.sol";
import "./profiles/IDNSRecordResolver.sol";
import "./profiles/IDNSZoneResolver.sol";
import "./profiles/IInterfaceResolver.sol";
import "./profiles/INameResolver.sol";
import "./profiles/IPubkeyResolver.sol";
import "./profiles/ITextResolver.sol";
import "./ISupportsInterface.sol";
/**
 * A generic resolver interface which includes all the functions including the ones deprecated
 */
interface Resolver is ISupportsInterface, IABIResolver, IAddressResolver, IAddrResolver, IContentHashResolver, IDNSRecordResolver, IDNSZoneResolver, IInterfaceResolver, INameResolver, IPubkeyResolver, ITextResolver {
    /* Deprecated events */
    event ContentChanged(bytes32 indexed node, bytes32 hash);

    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external;
    function setAddr(bytes32 node, address addr) external;
    function setAddr(bytes32 node, uint coinType, bytes calldata a) external;
    function setContenthash(bytes32 node, bytes calldata hash) external;
    function setDnsrr(bytes32 node, bytes calldata data) external;
    function setName(bytes32 node, string calldata _name) external;
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;
    function setText(bytes32 node, string calldata key, string calldata value) external;
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external;
    function multicall(bytes[] calldata data) external returns(bytes[] memory results);

    /* Deprecated functions */
    function content(bytes32 node) external view returns (bytes32);
    function multihash(bytes32 node) external view returns (bytes memory);
    function setContent(bytes32 node, bytes32 hash) external;
    function setMultihash(bytes32 node, bytes calldata hash) external;
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

interface IBaseRegistrarImplementation {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

struct domain {
    address owner;
    string domain;
    bytes32 node;
    uint256 tokenId;
}

struct subdomain {
    address owner;
    string domain;
    string subdomain;
    uint256 tokenId;
}

struct policy_1 {
    string domain;
    allowlistDetail[] allowlists;
}

struct allowlistDetail {
    address account;
    uint256 mintAmount;
}

struct policy_2 {
    string domain;
    address tokenAddress;
    uint256 tokenAmount;
}

struct policy {
    string domain;
    uint256 policy;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./IABIResolver.sol";
import "../ResolverBase.sol";

interface IABIResolver {
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the new (multicoin) addr function.
 */
interface IAddressResolver {
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the legacy (ETH-only) addr function.
 */
interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IContentHashResolver {
    event ContenthashChanged(bytes32 indexed node, bytes hash);

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDNSRecordResolver {
    // DNSRecordChanged is emitted whenever a given node/name/resource's RRSET is updated.
    event DNSRecordChanged(bytes32 indexed node, bytes name, uint16 resource, bytes record);
    // DNSRecordDeleted is emitted whenever a given node/name/resource's RRSET is deleted.
    event DNSRecordDeleted(bytes32 indexed node, bytes name, uint16 resource);
    // DNSZoneCleared is emitted whenever a given node's zone information is cleared.
    event DNSZoneCleared(bytes32 indexed node);

    /**
     * Obtain a DNS record.
     * @param node the namehash of the node for which to fetch the record
     * @param name the keccak-256 hash of the fully-qualified name for which to fetch the record
     * @param resource the ID of the resource as per https://en.wikipedia.org/wiki/List_of_DNS_record_types
     * @return the DNS record in wire format if present, otherwise empty
     */
    function dnsRecord(bytes32 node, bytes32 name, uint16 resource) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDNSZoneResolver {
    // DNSZonehashChanged is emitted whenever a given node's zone hash is updated.
    event DNSZonehashChanged(bytes32 indexed node, bytes lastzonehash, bytes zonehash);

    /**
     * zonehash obtains the hash for the zone.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function zonehash(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IInterfaceResolver {
    event InterfaceChanged(bytes32 indexed node, bytes4 indexed interfaceID, address implementer);

    /**
     * Returns the address of a contract that implements the specified interface for this name.
     * If an implementer has not been set for this interfaceID and name, the resolver will query
     * the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     * contract implements EIP165 and returns `true` for the specified interfaceID, its address
     * will be returned.
     * @param node The ENS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IPubkeyResolver {
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ITextResolver {
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISupportsInterface {
    function supportsInterface(bytes4 interfaceID) external pure returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./SupportsInterface.sol";

abstract contract ResolverBase is SupportsInterface {
    function isAuthorised(bytes32 node) internal virtual view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node));
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ISupportsInterface.sol";

abstract contract SupportsInterface is ISupportsInterface {
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(ISupportsInterface).interfaceId;
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