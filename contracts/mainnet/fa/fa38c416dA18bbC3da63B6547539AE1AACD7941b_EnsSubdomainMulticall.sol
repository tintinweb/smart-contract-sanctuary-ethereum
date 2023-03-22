// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct NamehashMap {
    bytes32 domainNamehash;
    bytes32 subdomainLabelhash;
    bytes32 subdomainNamehash;
}

struct SubdomainRegistrationRecord {
    NamehashMap hashes;
    // Primary owner of the ENS domain
    address owner;
    // Address to which the subdomain should resolve to
    address target;
}

interface EnsRegistry {
    function setOwner(bytes32 node, address owner) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external;

    function setResolver(bytes32 node, address resolver) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);
}

interface EnsResolver {
    function setAddr(bytes32 node, address addr) external;

    function addr(bytes32 node) external view returns (address);
}

/**
 * @title EnsSubdomainMulticall
 * Allows bulk registration of subdomains
 */
contract EnsSubdomainMulticall {
    address public owner;
    EnsRegistry public registry;
    EnsResolver public resolver;
    bool public locked;
    bytes32 emptyNamehash = 0x00;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event RegistryUpdated(
        address indexed previousRegistry,
        address indexed newRegistry
    );
    event ResolverUpdated(
        address indexed previousResolver,
        address indexed newResolver
    );
    event DomainTransfersLocked();

    constructor(EnsRegistry _registry, EnsResolver _resolver) {
        owner = msg.sender;
        registry = _registry;
        resolver = _resolver;
        locked = false;
    }

    /**
     * @dev Throws if called by any account other than the owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Utility function returns hashes for subdomain, domain and topdomain
     * @param _subdomain - subdomain name e.g. "terminal"
     * @param _domain - domain name e.g. "aurox"
     * @param _topdomain - e.g. "eth"
     */
    function getSubdomainHashes(
        string calldata _subdomain,
        string calldata _domain,
        string calldata _topdomain
    ) public view returns (NamehashMap memory) {
        bytes32 topdomainNamehash = keccak256(
            abi.encodePacked(
                emptyNamehash,
                keccak256(abi.encodePacked(_topdomain))
            )
        );

        bytes32 domainNamehash = keccak256(
            abi.encodePacked(
                topdomainNamehash,
                keccak256(abi.encodePacked(_domain))
            )
        );

        bytes32 subdomainLabelhash = keccak256(abi.encodePacked(_subdomain));
        bytes32 subdomainNamehash = keccak256(
            abi.encodePacked(domainNamehash, subdomainLabelhash)
        );

        return (
            NamehashMap(domainNamehash, subdomainLabelhash, subdomainNamehash)
        );
    }

    /**
     * @dev Registers single subdomain to provided domain
     * @param _registration - registration payload
     */
    function registerSubdomain(
        SubdomainRegistrationRecord calldata _registration
    ) public {
        require(
            registry.owner(_registration.hashes.domainNamehash) ==
                address(this),
            "This contract should own the domain"
        );

        require(
            registry.owner(_registration.hashes.subdomainNamehash) ==
                address(0) ||
                registry.owner(_registration.hashes.subdomainNamehash) ==
                msg.sender,
            "Subdomain is already owned"
        );

        registry.setSubnodeOwner(
            _registration.hashes.domainNamehash,
            _registration.hashes.subdomainLabelhash,
            address(this)
        );

        registry.setResolver(
            _registration.hashes.subdomainNamehash,
            address(resolver)
        );

        resolver.setAddr(
            _registration.hashes.subdomainNamehash,
            _registration.target
        );

        registry.setOwner(
            _registration.hashes.subdomainNamehash,
            _registration.target
        );
    }

    function registerSubdomains(SubdomainRegistrationRecord[] calldata _records)
        public
    {
        for (uint256 i = 0; i < _records.length; i++) {
            registerSubdomain(_records[i]);
        }
    }

    /**
     * @param _domain - domain name e.g. "aurox"
     * @param _topdomain - parent domain name e.g. "eth" or "xyz"
     */
    function domainOwner(string calldata _domain, string calldata _topdomain)
        public
        view
        returns (address)
    {
        bytes32 topdomainNamehash = keccak256(
            abi.encodePacked(
                emptyNamehash,
                keccak256(abi.encodePacked(_topdomain))
            )
        );

        bytes32 namehash = keccak256(
            abi.encodePacked(
                topdomainNamehash,
                keccak256(abi.encodePacked(_domain))
            )
        );

        return registry.owner(namehash);
    }

    /**
     * @dev Return the owner of a subdomain
     * @param _subdomain - sub domain name only
     * @param _domain - parent domain name
     * @param _topdomain - parent domain name e.g. "eth", "xyz"
     */
    function subdomainOwner(
        string calldata _subdomain,
        string calldata _domain,
        string calldata _topdomain
    ) public view returns (address) {
        bytes32 topdomainNamehash = keccak256(
            abi.encodePacked(
                emptyNamehash,
                keccak256(abi.encodePacked(_topdomain))
            )
        );
        bytes32 domainNamehash = keccak256(
            abi.encodePacked(
                topdomainNamehash,
                keccak256(abi.encodePacked(_domain))
            )
        );
        bytes32 subdomainNamehash = keccak256(
            abi.encodePacked(
                domainNamehash,
                keccak256(abi.encodePacked(_subdomain))
            )
        );
        return registry.owner(subdomainNamehash);
    }

    /**
     * @dev Return the target address where the subdomain is pointing to
     * @param _subdomain - subdomain name
     * @param _domain - domain name
     * @param _topdomain - parent domain name e.g. "eth", "xyz"
     */
    function subdomainTarget(
        string calldata _subdomain,
        string calldata _domain,
        string calldata _topdomain
    ) public view returns (address) {
        bytes32 topdomainNamehash = keccak256(
            abi.encodePacked(
                emptyNamehash,
                keccak256(abi.encodePacked(_topdomain))
            )
        );

        bytes32 domainNamehash = keccak256(
            abi.encodePacked(
                topdomainNamehash,
                keccak256(abi.encodePacked(_domain))
            )
        );

        bytes32 subdomainNamehash = keccak256(
            abi.encodePacked(
                domainNamehash,
                keccak256(abi.encodePacked(_subdomain))
            )
        );

        address currentResolver = registry.resolver(subdomainNamehash);

        return EnsResolver(currentResolver).addr(subdomainNamehash);
    }

    /**
     * @dev The contract owner can take away the ownership of any domain owned by this contract.
     * @param _node - namehash of the domain
     * @param _owner - new owner for the domain
     */
    function transferDomainOwnership(bytes32 _node, address _owner)
        public
        onlyOwner
    {
        require(!locked);
        registry.setOwner(_node, _owner);
    }

    /**
     * @dev The contract owner can lock and prevent any future domain ownership transfers.
     */
    function lockDomainOwnershipTransfers() public onlyOwner {
        require(!locked);
        locked = true;
        emit DomainTransfersLocked();
    }

    /**
     * @dev Allows to update to new ENS registry.
     * @param _registry The address of new ENS registry to use.
     */
    function updateRegistry(EnsRegistry _registry) public onlyOwner {
        require(
            registry != _registry,
            "new registry should be different from old"
        );
        emit RegistryUpdated(address(registry), address(_registry));
        registry = _registry;
    }

    /**
     * @dev Allows to update to new ENS resolver.
     * @param _resolver The address of new ENS resolver to use.
     */
    function updateResolver(EnsResolver _resolver) public onlyOwner {
        require(
            resolver != _resolver,
            "new resolver should be different from old"
        );
        emit ResolverUpdated(address(resolver), address(_resolver));
        resolver = _resolver;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a new owner.
     * @param _owner The address to transfer ownership to.
     */
    function transferContractOwnership(address _owner) public onlyOwner {
        require(_owner != address(0), "cannot transfer to address(0)");
        emit OwnershipTransferred(owner, _owner);
        owner = _owner;
    }
}