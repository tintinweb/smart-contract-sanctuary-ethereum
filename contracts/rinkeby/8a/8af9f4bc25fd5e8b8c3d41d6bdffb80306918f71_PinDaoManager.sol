// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

// START https://github.com/JonahGroendal/ens-namehash
library ENSNamehash {

  function namehash(bytes memory domain) internal pure returns (bytes32) {
    return namehash(domain, 0);
  }

  function namehash(bytes memory domain, uint i) internal pure returns (bytes32) {
    if (domain.length <= i)
      return 0x0000000000000000000000000000000000000000000000000000000000000000;

    uint len = LabelLength(domain, i);

    return keccak256(abi.encodePacked(namehash(domain, i+len+1), keccak(domain, i, len)));
  }

  function LabelLength(bytes memory domain, uint i) private pure returns (uint) {
    uint len;
    while (i+len != domain.length && domain[i+len] != 0x2e) {
      len++;
    }
    return len;
  }

  function keccak(bytes memory data, uint offset, uint len) private pure returns (bytes32 ret) {
    require(offset + len <= data.length);
    assembly {
      ret := keccak256(add(add(data, 32), offset), len)
    }
  }
}
// END https://github.com/JonahGroendal/ens-namehash

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

abstract contract ENSRegistryWithFallback {
    function setSubnodeRecord(
        bytes32 node, 
        bytes32 label, 
        address owner, 
        address resolver, 
        uint64 ttl) external virtual;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external virtual returns (bytes32);

    function owner(bytes32 node) external view virtual returns (address);
}

abstract contract PublicResolver {
    function setContenthash(bytes32 node, bytes calldata hash) external virtual;
}

contract PinDaoManager is Ownable {
    string domain;
    string[] subdomainArray;
    ENSRegistryWithFallback registryContract;
    PublicResolver resolverContract;
    address private registryContractAddress = address(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    address private resolverAddress = address(0xf6305c19e814d2a75429Fd637d01F7ee0E77d615);

    using ENSNamehash for bytes;

    event EnsUpdated(string ensName);
    event EnsRemoved(string ensName);

    constructor() {
        domain = "web.pinnerdao.eth";
        registryContract = ENSRegistryWithFallback(registryContractAddress);
        resolverContract = PublicResolver(resolverAddress);
    }

    function recoverSubdomain(string memory subdomainName, string memory nodeDomain) public onlyOwner {
        registryContract.setSubnodeOwner(
            bytes(nodeDomain).namehash(),
            keccak256(bytes(subdomainName)),
            msg.sender
        );
    }

    function addContenthash(string memory nodeDomain, bytes calldata hash) public onlyOwner {
        resolverContract.setContenthash(
            bytes(nodeDomain).namehash(),
            hash
        );
    }

    // Testing purposes
    function addElement(string memory element) public onlyOwner {
        subdomainArray.push(element);
    }

    function addEns(string memory subdomainName, bytes calldata hash) public onlyOwner {
        bytes32 node = bytes(domain).namehash();
        //bytes32 node = 0x0245cc5c2a2d9a0b9089a4eb1a7c954176d6c8f51ce1b6a0e49dbc215c764d8f;
        bytes32 subdomain = keccak256(bytes(subdomainName));
        registryContract.setSubnodeRecord(
            node,
            subdomain,
            address(this),
            resolverAddress,
            0
        );
        string memory ens = string.concat(subdomainName, ".", domain);
        addContenthash(ens, hash);

        addElement(ens);
        emit EnsUpdated(ens);
    }

    // Testing purposes
    function removeLastElement() public onlyOwner {
        subdomainArray.pop();
    }

    function removeEns(string memory subdomainName) public onlyOwner {
        removeLastElement();
        emit EnsRemoved(string.concat(subdomainName, ".", domain));
    }

    // Testing purposes
    function getENSList() public view returns (string[] memory) {
        return (subdomainArray);
    }

    // Testing purposes
    function getNameHash(string calldata subdomain) public view returns (bytes32) {
        bytes32 node = bytes(string.concat(subdomain, domain)).namehash();
        return (node);
    }

    // Testing purposes
    function getNameHashString(string calldata s) public pure returns (bytes32) {
        bytes32 node = bytes(s).namehash();
        return (node);
    }

    // Testing purposes
    function getName(string calldata subdomain) public view returns (string memory) {
        return (string.concat(subdomain, ".", domain));
    }

    // Testing purposes
    function getSHA3(string calldata s) public pure returns (bytes32) {
        bytes32 coded = keccak256(bytes(s));
        return (coded);
    }

    // Testing purposes
    function getBytes(string calldata s) public pure returns (bytes memory) {
        return (bytes(s));
    }
}