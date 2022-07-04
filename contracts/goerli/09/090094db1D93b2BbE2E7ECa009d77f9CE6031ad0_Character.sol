// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CharacterMetaData.sol";

contract Character {
    uint256 public _tokenId;
    // key: propertyId
    mapping(uint256 => uint256) public properties;
    CharacterMetaData private _metaData;

    constructor(uint256 tokenId, address characterMetaData) {
        _tokenId = tokenId;
        _metaData = CharacterMetaData(characterMetaData);
    }

    function setProperty(uint256 propertyId, uint256 value) public virtual {
        require(_metaData.isValidPropertyId(propertyId), 'invalid propertyId');

        properties[propertyId] = value;
    }

    function getProperties() public virtual view returns(uint256[] memory) {
        CharacterMetaData.PropertyType[] memory propertyTypes = _metaData.getPropertyTypes();
        uint256[] memory result = new uint256[](propertyTypes.length);
        for (uint256 i; i < propertyTypes.length; i++) {
            result[i] = properties[i];
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CharacterMetaData is Ownable {
    enum PropertyType { Invalid, Calculable, Reincarnationable, Replaceable }

    uint256 public worldId;
    // key: propertyId
    PropertyType[] propertyTypes;

    constructor(uint256 worldId_) {
        worldId = worldId_;
    }

    function addMetadata(PropertyType propertyType) public virtual onlyOwner {
        propertyTypes.push(propertyType);
    }

    function setMetadata(uint256 propertyId, PropertyType propertyType) public virtual onlyOwner {
        require(propertyId >= 0);
        require(propertyId < propertyTypes.length);

        propertyTypes[propertyId] = propertyType;
    }

    function isValidPropertyId(uint256 propertyId) public view virtual returns(bool) {
        return propertyId >= 0 && propertyId < propertyTypes.length && propertyTypes[propertyId] != PropertyType.Invalid;
    }

    function getPropertyTypes() public view virtual returns(PropertyType[] memory) {
        return propertyTypes;
    }
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