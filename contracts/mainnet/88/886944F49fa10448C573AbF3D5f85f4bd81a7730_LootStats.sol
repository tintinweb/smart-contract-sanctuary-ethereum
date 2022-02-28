// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
/*
LootStats.sol
Lootverse Utility contract to gather stats for Loot (For Adventurers) Bags, Genesis Adventurers and other "bag" like contracts.

See OG Loot Contract for lists of all possible items.
https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7

All functions are made public incase they are useful but the expected use is through the main
4 stats functions:

- getGreatness()
- getLevel()
- getRating()
- getNumberOfItemsInClass()
- getGreatnessByItem()
- getLevelByItem()
- getRatingByItem()
- getClassByItem()

Each of these take a Loot Bag ID.  This contract relies and stores the most current LootClassification contract.

The LootStats(_TBD_) contract can be used to get "bag" level stats for Loot bag's tokenID.

So a typical use might be:

// get stats for loot bag# 1234
{
    LootStats stats = 
        LootStats(_TBD_);

    uint256 level = stats.getLevel(1234);
    uint256 greatness = stats.getGreatness(1234);
    uint256 rating = stats.getRating(1234);
    uint256 level = stats.getLevel([1234,1234,1234,1234,1234,1234,1234,1234]);
    uint256 greatness = stats.getGreatness([1234,1234,1234,1234,1234,1234,1234,1234]);
    uint256 rating = stats.getRating([1234,1234,1234,1234,1234,1234,1234,1234]);


}
*/
interface ILootClassification {
    enum Type
    {
        Weapon,
        Chest,
        Head,
        Waist,
        Foot,
        Hand,
        Neck,
        Ring
    }
    enum Class
    {
        Warrior,
        Hunter,
        Mage,
        Any
    }
    function getLevel(Type lootType, uint256 index) external pure returns (uint256);
    function getClass(Type lootType, uint256 index) external pure returns (Class);
    function weaponComponents(uint256 tokenId) external pure returns (uint256[6] memory);
    function chestComponents(uint256 tokenId) external pure returns (uint256[6] memory);
    function headComponents(uint256 tokenId) external pure returns (uint256[6] memory);
    function waistComponents(uint256 tokenId) external pure returns (uint256[6] memory);
    function footComponents(uint256 tokenId) external pure returns (uint256[6] memory);
    function handComponents(uint256 tokenId) external pure returns (uint256[6] memory);
    function ringComponents(uint256 tokenId) external pure returns (uint256[6] memory);
    function neckComponents(uint256 tokenId) external pure returns (uint256[6] memory);
}

contract LootStats is Ownable
{
    ILootClassification private lootClassification;    
    address public lootClassificationAddress;
    ILootClassification.Type[8] private itemTypes = [ILootClassification.Type.Weapon, ILootClassification.Type.Chest, ILootClassification.Type.Head, ILootClassification.Type.Waist, ILootClassification.Type.Foot, ILootClassification.Type.Hand, ILootClassification.Type.Neck, ILootClassification.Type.Ring];

    constructor(address lootClassification_) {
        lootClassificationAddress = lootClassification_;
        lootClassification = ILootClassification(lootClassificationAddress);
    }

    function setLootClassification(address lootClassification_) public onlyOwner {
        lootClassificationAddress = lootClassification_;
        lootClassification = ILootClassification(lootClassificationAddress);
    }

    function getLevel(uint256 tokenId) public view returns (uint256)
    {
        return getLevel([tokenId,tokenId,tokenId,tokenId,tokenId,tokenId,tokenId,tokenId]);
    }

    function getLevel(uint256[8] memory tokenId) public view returns (uint256)
    {
        uint256 level;
        for(uint8 i=0; i < itemTypes.length; i++) {
            if (tokenId[i] == 0) 
                level += 1;
            else
                level += getLevelByItem(itemTypes[i], tokenId[i]);    
        }     
    
        return level;
    }

    function getGreatness(uint256 tokenId) public view returns (uint256)
    {
        return getGreatness([tokenId,tokenId,tokenId,tokenId,tokenId,tokenId,tokenId,tokenId]);
    }

    function getGreatness(uint256[8] memory tokenId) public view returns (uint256)
    {
        uint256 greatness;
        for(uint8 i=0; i < itemTypes.length; i++) {
            if (tokenId[i] == 0) 
                greatness += 15;
            else
                greatness += getGreatnessByItem(itemTypes[i], tokenId[i]);    
        }

        return greatness;
    }

    function getRating(uint256 tokenId) public view returns (uint256)
    {   
        return getRating([tokenId,tokenId,tokenId,tokenId,tokenId,tokenId,tokenId,tokenId]);
    }

    function getRating(uint256[8] memory tokenId) public view returns (uint256)
    {   
        uint256 rating;
        for(uint8 i=0; i < itemTypes.length; i++) {
            if (tokenId[i] == 0) 
                rating += 15;
            else
                rating += getRatingByItem(itemTypes[i], tokenId[i]);    
        }

        return rating;
    }

    function getNumberOfItemsInClass(ILootClassification.Class classType, uint256 tokenId) public view returns (uint256)
    {   
        return getNumberOfItemsInClass(classType, [tokenId,tokenId,tokenId,tokenId,tokenId,tokenId,tokenId,tokenId]);
    }

    function getNumberOfItemsInClass(ILootClassification.Class classType, uint256[8] memory tokenId) public view returns (uint256)
    {   
        uint256 count;
        for(uint8 i=0; i < itemTypes.length; i++) {
            if (classType == getClassByItem(itemTypes[i], tokenId[i])) {
                count++;
            }   
        }
        return count;
    }

    function getGreatnessByItem(ILootClassification.Type lootType, uint256 tokenId) 
        public view returns (uint256) 
    {        
        return _getComponent(5, lootType, tokenId);
    }

    function getLevelByItem(ILootClassification.Type lootType, uint256 tokenId)
        public view returns (uint256) 
    {
        return lootClassification.getLevel(lootType, _getComponent(0, lootType, tokenId));
    }

    function getRatingByItem(ILootClassification.Type lootType, uint256 tokenId) 
        public view returns (uint256)
    {   
        return getLevelByItem(lootType, tokenId) * getGreatnessByItem(lootType, tokenId);
    }

    function getClassByItem(ILootClassification.Type lootType, uint256 tokenId) 
        public view returns (ILootClassification.Class) 
    {
        return lootClassification.getClass(lootType, _getComponent(0, lootType, tokenId));
    }
    function _getComponent(uint256 componentId, ILootClassification.Type lootType, uint256 tokenId)
        internal view returns (uint256)
    {
        if (lootType == ILootClassification.Type.Weapon) {
            return lootClassification.weaponComponents(tokenId)[componentId];
        } else if (lootType == ILootClassification.Type.Chest) {
            return lootClassification.chestComponents(tokenId)[componentId];
        } else if (lootType == ILootClassification.Type.Head) {
            return lootClassification.headComponents(tokenId)[componentId];
        } else if (lootType == ILootClassification.Type.Waist) {
            return lootClassification.waistComponents(tokenId)[componentId];
        } else if (lootType == ILootClassification.Type.Foot) {
            return lootClassification.footComponents(tokenId)[componentId];
        } else if (lootType == ILootClassification.Type.Hand) {
            return lootClassification.handComponents(tokenId)[componentId];
        } else if (lootType == ILootClassification.Type.Ring) {
            return lootClassification.ringComponents(tokenId)[componentId];
        } else {
            return lootClassification.neckComponents(tokenId)[componentId];
        }
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