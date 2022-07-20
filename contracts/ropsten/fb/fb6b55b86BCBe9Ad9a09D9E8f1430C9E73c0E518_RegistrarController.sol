//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "../interfaces/ICNSController.sol";
import "../access/CNSAccessControl.sol";
import "../structures/Domain.sol";
import "../structures/Subdomain.sol";

contract RegistrarController is CNSAccessControl {
    constructor(
        address _CNSControlerAddr,
        address _ensAddr,
        address _baseRegistrarAddr,
        address _resolverAddr
    )
        CNSAccessControl(
            _CNSControlerAddr,
            _ensAddr,
            _baseRegistrarAddr,
            _resolverAddr
        )
    {
        require(_CNSControlerAddr != address(0), "Invalid address");
    }

    function registerDomain(
        uint256 _tokenId,
        string memory _domain,
        bytes32 _node,
        address _policy,
        address _sender
    ) public isNotRegisterDomain(_domain) onlyPolicy {
        cns.registerDomain(Domain(_domain, _tokenId, _sender, _node, _policy));
    }

    function registerSubdomain(
        string memory _domain,
        string memory _subdomain,
        bytes32 _subnode,
        address _owner
    ) public onlyPolicyOrDomainOwner(msg.sender, _domain) {
        cns.registerSubdomain(_domain, _subdomain, _subnode, _owner);
    }

    function unRegisterDomain(string memory _domain)
        public
        onlyPolicy
        isRegisterDomain(_domain)
    {
        cns.unRegisterDomain(_domain);
    }

    function unRegisterDomainWithoutBurn(string memory _domain)
        public
        onlyPolicy
        isRegisterDomain(_domain)
    {
        cns.unRegisterDomainWithoutBurn(_domain);
    }

    function removeSubdomainWithNode(bytes32 _subnode) public onlyPolicy {
        cns.removeSubdomainWithNode(_subnode);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "../structures/Domain.sol";

interface ICNSController {
    function isRegisterDomain(string memory _domain)
        external
        view
        returns (bool);

    function registerDomain(Domain memory _domain) external;

    function registerSubdomain(
        string memory _domain,
        string memory _subdomain,
        bytes32 _subnode,
        address _owner
    ) external;

    function isActivePolicy(address _policy) external view returns (bool);

    function getDomain(string memory _domain)
        external
        view
        returns (Domain memory);

    function isDomainOwner(string memory _domain, address _account)
        external
        view
        returns (bool);

    function unRegisterDomain(string memory _domain) external;

    function unRegisterDomainWithoutBurn(string memory _domain) external;

    function checkPolicy(string memory _domain) external view returns (address);

    function checkMintSubdomainWithPolicy(
        string memory _domain,
        address _account,
        address _policy
    ) external returns (bool);

    function removeSubdomainWithNode(bytes32 _subnode) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "../interfaces/ICNSController.sol";
import "../libs/ENSController.sol";

contract CNSAccessControl is ENSController {
    ICNSController internal cns;

    constructor(
        address _CNSControlerAddr,
        address _ensAddr,
        address _baseRegistrarAddr,
        address _resolverAddr
    ) ENSController(_ensAddr, _baseRegistrarAddr, _resolverAddr) {
        require(_CNSControlerAddr != address(0), "Invalid address");
        cns = ICNSController(_CNSControlerAddr);
    }

    modifier isNotRegisterDomain(string memory _domain) {
        require(!cns.isRegisterDomain(_domain), "Domain is already registered");
        _;
    }

    modifier isRegisterDomain(string memory _domain) {
        require(cns.isRegisterDomain(_domain));
        _;
    }

    modifier isDomainOwner(uint256 _tokenId, address _account) {
        require(_account == registrar.ownerOf(_tokenId));
        _;
    }

    modifier isPolicy(address _policy) {
        require(cns.isActivePolicy(_policy));
        _;
    }

    modifier onlyPolicyOrDomainOwner(address _sender, string memory _domain) {
        require(
            cns.isActivePolicy(_sender) || cns.isDomainOwner(_domain, _sender)
        );
        _;
    }

    modifier onlyPolicy() {
        require(cns.isActivePolicy(msg.sender));
        _;
    }

    modifier onlyDomainOwner(string memory _domain, address _sender) {
        require(cns.isDomainOwner(_domain, _sender));
        _;
    }

    modifier isUseThisPolicy(string memory _domain, address _policy) {
        require(cns.checkPolicy(_domain) == _policy);
        _;
    }

    modifier isNotMintWithPolicy(
        string memory _domain,
        address _account,
        address _policy
    ) {
        require(!cns.checkMintSubdomainWithPolicy(_domain, _account, _policy));
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

struct Domain {
    string domain;
    uint256 tokenId;
    address owner;
    bytes32 node;
    address policy;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

struct Subdomain {
    string domain;
    string subdomain;
    bytes32 subnode;
    address owner;
    address policy;
    uint256 cnsTokenId;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/Resolver.sol";
import "../interfaces/IRegistrar.sol";

contract ENSController {
    ENS public ens;
    Registrar internal registrar;
    Resolver internal resolver;

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
        registrar = Registrar(baseRegistrarAddr);
        resolver = Resolver(resolverAddr);
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

/**
 * @dev Interface of the Base Registrar Implementation of ENS.
 */
interface Registrar {
    function ownerOf(uint256 tokenId) external view returns (address owner);
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