pragma solidity >=0.8.4;

interface IReverseRegistrar {
    function setDefaultResolver(address resolver) external;

    function claim(address owner) external returns (bytes32);

    function claimForAddr(
        address addr,
        address owner,
        address resolver
    ) external returns (bytes32);

    function claimWithResolver(
        address owner,
        address resolver
    ) external returns (bytes32);

    function setName(string memory name) external returns (bytes32);

    function setNameForAddr(
        address addr,
        address owner,
        address resolver,
        string memory name
    ) external returns (bytes32);

    function node(address addr) external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT

import "@ens/registry/IReverseRegistrar.sol";

pragma solidity ^0.8.16;

abstract contract PrimaryEns {
    IReverseRegistrar public immutable REVERSE_REGISTRAR;

    address private deployer;

    constructor() {
        deployer = msg.sender;
        REVERSE_REGISTRAR = IReverseRegistrar(
            0x084b1c3C81545d370f3634392De611CaaBFf8148
        );
    }

    /*
     * @description Set the primary name of the contract
     * @param _ens The ENS that is set to the contract address. Must be full name
     * including the .eth. Can also be a subdomain.
     */
    function setPrimaryName(string calldata _ens) public {
        require(msg.sender == deployer, "only deployer");
        REVERSE_REGISTRAR.setName(_ens);
    }
}

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IManager {
    function IdToLabelMap(
        uint256 _tokenId
    ) external view returns (string memory label);

    function IdToOwnerId(
        uint256 _tokenId
    ) external view returns (uint256 ownerId);

    function IdToDomain(
        uint256 _tokenId
    ) external view returns (string memory domain);

    function TokenLocked(uint256 _tokenId) external view returns (bool locked);

    function IdImageMap(
        uint256 _tokenId
    ) external view returns (string memory image);

    function IdToHashMap(
        uint256 _tokenId
    ) external view returns (bytes32 _hash);

    function text(
        bytes32 node,
        string calldata key
    ) external view returns (string memory _value);

    function DefaultMintPrice(
        uint256 _tokenId
    ) external view returns (uint256 _priceInWei);

    function transferDomainOwnership(uint256 _id, address _newOwner) external;

    function TokenOwnerMap(uint256 _id) external view returns (address);

    function registerSubdomain(
        uint256 _id,
        string calldata _label,
        bytes32[] calldata _proofs
    ) external payable;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IRegister {
    function canRegister(
        uint256 _tokenId,
        string memory _label,
        address _addr,
        uint256 _priceInWei,
        bytes32[] calldata _proofs
    ) external returns (bool);

    function mintPrice(
        uint256 _tokenId,
        string calldata _label,
        address _addr,
        bytes32[] calldata _proofs
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IRegister.sol";
import "./IManager.sol";
import "lib/EnsPrimaryContractNamer/src/PrimaryEns.sol";
import "openzeppelin-contracts/access/Ownable.sol";

interface IMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ProxyMetadata is IMetadata, PrimaryEns, Ownable {

    IManager public immutable domainManager;
    IMetadata public  defaultMetadata;

    mapping(uint256 => IMetadata) public metadataMap;

    constructor(address _esf, address _metadata) {
        domainManager = IManager(_esf);
        defaultMetadata = IMetadata(_metadata);
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        IMetadata metadata = getMetadata(tokenId);
        return metadata.tokenURI(tokenId);
    }

    function getMetadata(uint256 _tokenId) private view returns (IMetadata) {
        uint256 parentId = domainManager.IdToOwnerId(_tokenId);

        IMetadata metadata = metadataMap[_tokenId];
        if (address(metadata) == address(0)) {
            metadata = defaultMetadata;
        }
        return metadata;
    }

    function updateMetadata(uint256 _tokenId, address _metadata) external onlyOwner {
        metadataMap[_tokenId] = IMetadata(_metadata);
    }



}