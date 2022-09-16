// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CommonConstGen0 is Ownable {
    struct IngredientType {
        uint8 from;
        uint8 to;
        uint8[] tokenIds;
    }
    mapping(uint => IngredientType) private ingredientTypes;
    uint256 public nonce;
    uint8 public typeCount;
    uint8[] private common;
    uint8[] private uncommon;
    uint8[] private rare;
    uint8[] private epic;
    uint8[] private legendary;

    constructor()  {
        common = [1,2,3,4,5];
        uncommon = [6,7,8];
        rare = [9,10,11,12,13,14,15,16,17,18,19];
        epic = [20,21,22,23,24];
        legendary = [25];
        ingredientTypes[1] = IngredientType({from:1,to:46, tokenIds:common});
        ingredientTypes[2] = IngredientType({from:47,to:76, tokenIds:uncommon});
        ingredientTypes[3] = IngredientType({from:77,to:91, tokenIds:rare});
        ingredientTypes[4] = IngredientType({from:92,to:99, tokenIds:epic});
        ingredientTypes[5] = IngredientType({from:100,to:100, tokenIds:legendary});
        nonce = 1;
        typeCount=5;
    }

    function random(uint8 from, uint256 to) private returns (uint8) {
        uint256 randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % to;
        randomnumber = from + randomnumber;
        nonce++;
        return uint8(randomnumber);
    }

    function setCategory(uint8 category,uint8 from, uint8 to, uint8[] memory tokenIds) external onlyOwner{
        require(category <= typeCount, "only 5 categories exist");
        require(from <= to, "Invalid range");
        ingredientTypes[category] = IngredientType({from:from,to:to,tokenIds:tokenIds});
    }


    function getIngredientNftId(uint8 category) private returns(uint){
        IngredientType memory ingredient = ingredientTypes[category];
        uint to = ingredient.tokenIds.length;
        uint num = random(1, to);
        return ingredient.tokenIds[num-1];
    }

    function getCategory(uint number) private view returns(uint8){
        uint8 index = 0;
        for(uint8 i = 1; i <= typeCount; i++) {
            if(number >= ingredientTypes[i].from &&  number <= ingredientTypes[i].to) {
                index = i;
            }
        }
        return index;
    }

    function revealIngredientNftId() external returns(uint256){
        uint8 number = random(1,100);
        uint8 category = getCategory(number);
        return getIngredientNftId(category);
    }

    function printCategory(uint8 category) external view returns(IngredientType memory){
        return ingredientTypes[category];
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