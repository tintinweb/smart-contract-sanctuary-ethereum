// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface ERC721 {
    function balanceOf(address owner) external view returns (uint256);
}

interface EnsResolver {
	function setAddr(bytes32 node, address addr) external;
	function addr(bytes32 node) external view returns (address);
}

interface EnsRegistry {
	function setOwner(bytes32 node, address owner) external;
	function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
	function setResolver(bytes32 node, address resolver) external;
	function owner(bytes32 node) external view returns (address);
	function resolver(bytes32 node) external view returns (address);
}

contract TDBCENSMapper {
    bytes32 private constant EMPTY_NAMEHASH = 0x00;

	address private owner;
    ERC721 private immutable tdbc;
    ERC721 private immutable tcbc;
	EnsRegistry private registry;
	EnsResolver private resolver;
	bool public locked;

	event SubdomainCreated(address indexed creator, address indexed owner, string subdomain, string domain, string topdomain);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event RegistryUpdated(address indexed previousRegistry, address indexed newRegistry);
	event ResolverUpdated(address indexed previousResolver, address indexed newResolver);
	event DomainTransfersLocked();

	constructor(ERC721 _topDogs, ERC721 _topCats, EnsRegistry _registry, EnsResolver _resolver) {
		owner = msg.sender;
        tdbc = _topDogs;
        tcbc = _topCats;
		registry = _registry;
		resolver = _resolver;
		locked = false;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 *
	 */
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	/**
	 * @dev Allows to create a subdomain (e.g. "dose.tdbc.eth"),
	 * set its resolver and set its target address
	 * @param _subdomain - sub domain name only e.g. "dose"
	 * @param _domain - domain name e.g. "tdbc"
	 * @param _topdomain - parent domain name e.g. "eth", "xyz"
	 * @param _owner - address that will become owner of this new subdomain
	 * @param _target - address that this new domain will resolve to
	 */
	function newSubdomain(string calldata _subdomain, string calldata  _domain, string calldata  _topdomain, address _owner, address _target) external {
        // must hold a top dog or top cat to claim
		require(tdbc.balanceOf(_owner) > 0 || tcbc.balanceOf(_owner) > 0, "UNAUTHORIZED");

        bytes32 topdomainNamehash = keccak256(abi.encodePacked(EMPTY_NAMEHASH, keccak256(abi.encodePacked(_topdomain))));
		bytes32 domainNamehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain))));
		require(registry.owner(domainNamehash) == address(this), "INVALID_DOMAIN");

		bytes32 subdomainLabelhash = keccak256(abi.encodePacked(_subdomain));
		bytes32 subdomainNamehash = keccak256(abi.encodePacked(domainNamehash, subdomainLabelhash));
		require(registry.owner(subdomainNamehash) == address(0) || registry.owner(subdomainNamehash) == msg.sender, "SUB_DOMAIN_ALREADY_OWNED");

		registry.setSubnodeOwner(domainNamehash, subdomainLabelhash, address(this));
		registry.setResolver(subdomainNamehash, address(resolver));
		resolver.setAddr(subdomainNamehash, _target);
		registry.setOwner(subdomainNamehash, _owner);

		emit SubdomainCreated(msg.sender, _owner, _subdomain, _domain, _topdomain);
	}

	/**
	 * @dev Returns the owner of a domain (e.g. "tdbc.eth"),
	 * @param _domain - domain name e.g. "tdbc"
	 * @param _topdomain - parent domain name e.g. "eth" or "xyz"
	 */
	function domainOwner(string calldata _domain, string calldata _topdomain) external view returns (address) {
		bytes32 topdomainNamehash = keccak256(abi.encodePacked(EMPTY_NAMEHASH, keccak256(abi.encodePacked(_topdomain))));
		bytes32 namehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain))));

		return registry.owner(namehash);
	}

	/**
	 * @dev Return the owner of a subdomain (e.g. "dose.tdbc.eth"),
	 * @param _subdomain - sub domain name only e.g. "dose"
	 * @param _domain - parent domain name e.g. "tdbc"
	 * @param _topdomain - parent domain name e.g. "eth", "xyz"
	 */
	function subdomainOwner(string calldata _subdomain, string calldata _domain, string calldata _topdomain) external view returns (address) {
		bytes32 topdomainNamehash = keccak256(abi.encodePacked(EMPTY_NAMEHASH, keccak256(abi.encodePacked(_topdomain))));
		bytes32 domainNamehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain))));
		bytes32 subdomainNamehash = keccak256(abi.encodePacked(domainNamehash, keccak256(abi.encodePacked(_subdomain))));

		return registry.owner(subdomainNamehash);
	}

    /**
    * @dev Return the target address where the subdomain is pointing to (e.g. "0x12345..."),
    * @param _subdomain - sub domain name only e.g. "dose"
    * @param _domain - parent domain name e.g. "tdbc"
    * @param _topdomain - parent domain name e.g. "eth", "xyz"
    */
    function subdomainTarget(string calldata _subdomain, string calldata _domain, string calldata _topdomain) external view returns (address) {
        bytes32 topdomainNamehash = keccak256(abi.encodePacked(EMPTY_NAMEHASH, keccak256(abi.encodePacked(_topdomain))));
        bytes32 domainNamehash = keccak256(abi.encodePacked(topdomainNamehash, keccak256(abi.encodePacked(_domain))));
        bytes32 subdomainNamehash = keccak256(abi.encodePacked(domainNamehash, keccak256(abi.encodePacked(_subdomain))));
        address currentResolver = registry.resolver(subdomainNamehash);

        return EnsResolver(currentResolver).addr(subdomainNamehash);
    }

	/**
	 * @dev The contract owner can take away the ownership of any domain owned by this contract.
	 * @param _node - namehash of the domain
	 * @param _owner - new owner for the domain
	 */
	function transferDomainOwnership(bytes32 _node, address _owner) public onlyOwner {
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
		require(registry != _registry, "INVALID_REGISTRY");
		emit RegistryUpdated(address(registry), address(_registry));
		registry = _registry;
	}

	/**
	 * @dev Allows to update to new ENS resolver.
	 * @param _resolver The address of new ENS resolver to use.
	 */
	function updateResolver(EnsResolver _resolver) public onlyOwner {
		require(resolver != _resolver, "INVALID_RESOLVER");
		emit ResolverUpdated(address(resolver), address(_resolver));
		resolver = _resolver;
	}

	/**
	 * @dev Allows the current owner to transfer control of the contract to a new owner.
	 * @param _owner The address to transfer ownership to.
	 */
	function transferContractOwnership(address _owner) public onlyOwner {
		require(_owner != address(0), "INVALID_ADDRESS");
		emit OwnershipTransferred(owner, _owner);
		owner = _owner;
	}
}