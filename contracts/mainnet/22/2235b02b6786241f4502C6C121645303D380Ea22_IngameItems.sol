// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Composable.sol";

contract IngameItems is Composable {
    mapping(address => uint256) gemMap;
    uint256 public gemCount;

    mapping(address => uint256) totemMap;
    uint256 public totemCount;

    mapping(address => uint256) ghostMap;
    uint256 public ghostCount;

    mapping(uint256 => mapping(address => uint256)) gemWinsByMonsterBattle; 
    mapping(uint256 => mapping(address => uint256)) totemWinsByMonsterBattle;
    mapping(uint256 => mapping(address => uint256)) ghostWinsByMonsterBattle;

    function getGemWinsInMonsterBattle(uint256 battleId, address winner) external returns (uint256) {
        return gemWinsByMonsterBattle[battleId][winner];
    }

    function getTotemWinsInMonsterBattle(uint256 battleId, address winner) external returns (uint256) {
        return totemWinsByMonsterBattle[battleId][winner];
    }

    function getGhostWinsInMonsterBattle(uint256 battleId, address winner) external returns (uint256) {
        return ghostWinsByMonsterBattle[battleId][winner];
    }

    function addGemToPlayer(uint256 battleId, address _address) external onlyComponent {
        gemWinsByMonsterBattle[battleId][_address] += 1;
        gemMap[_address] += 1;
        gemCount++;
    }

    function removeGemFromPlayer(address _address) external onlyComponent {
        if (gemMap[_address] > 0) {
            gemMap[_address] -= 1;
            gemCount--;
        }
    }

    function moveGem(address fromAddress, address toAddress)
        external
        onlyComponent
    {
        if (gemMap[fromAddress] > 0) {
            gemMap[fromAddress] -= 1;
            gemMap[toAddress] += 1;
        }
    }

    function adminAddGemToPlayerForBattle(uint256 battleId, address _address) external onlyOwner {
        gemWinsByMonsterBattle[battleId][_address] += 1;
        gemMap[_address] += 1;
        gemCount++;
    }

    function adminAddGemToPlayer(address _address) external onlyOwner {
        gemMap[_address] += 1;
        gemCount++;
    }

    function viewGemCountForPlayer(address owner) public view returns (uint256){
        return gemMap[owner];
    }

    // Totems

    function addTotemToPlayer(uint256 battleId, address _address) external onlyComponent {
        totemWinsByMonsterBattle[battleId][_address] += 1;
        totemMap[_address] += 1;
        totemCount++;
    }

    function removeTotemFromPlayer(address _address) external onlyComponent {
        if (totemMap[_address] > 0) {
            totemMap[_address] -= 1;
            totemCount--;
        }
    }

    function moveTotem(address fromAddress, address toAddress)
        external
        onlyComponent
    {
        if (totemMap[fromAddress] > 0) {
            totemMap[fromAddress] -= 1;
            totemMap[toAddress] += 1;
        }
    }

    function adminAddTotemToPlayerForBattle(uint256 battleId, address _address) external onlyOwner {
        totemWinsByMonsterBattle[battleId][_address] += 1;
        totemMap[_address] += 1;
        totemCount++;
    }

    function adminAddTotemToPlayer(address _address) external onlyOwner {
        totemMap[_address] += 1;
        totemCount++;
    }

    function viewTotemCountForPlayer(address owner) public view returns (uint256){
        return totemMap[owner];
    }

    // Ghost

    function addGhostToPlayer(uint256 battleId, address _address) external onlyComponent {
        ghostWinsByMonsterBattle[battleId][_address] += 1;
        ghostMap[_address] += 1;
        ghostCount++;
    }

    function removeGhostFromPlayer(address _address) external onlyComponent {
        if (ghostMap[_address] > 0) {
            ghostMap[_address] -= 1;
            ghostCount--;
        }
    }

    function moveGhost(address fromAddress, address toAddress)
        external
        onlyComponent
    {
        if (ghostMap[fromAddress] > 0) {
            ghostMap[fromAddress] -= 1;
            ghostMap[toAddress] += 1;
        }
    }

    function adminAddGhostToPlayerForBattle(uint256 battleId, address _address) external onlyOwner {
        ghostWinsByMonsterBattle[battleId][_address] += 1;
        ghostMap[_address] += 1;
        ghostCount++;
    }

    function adminAddGhostToPlayer(address _address) external onlyOwner {
        ghostMap[_address] += 1;
        ghostCount++;
    }

    function viewGhostCountForPlayer(address owner) public view returns (uint256){
        return ghostMap[owner];
    }

    // All
    function viewAllCountsForPlayer(address owner) public view returns (uint256[] memory){
        uint256[] memory arr = new uint256[](3);
        arr[0] = gemMap[owner];
        arr[1] = totemMap[owner];
        arr[2] = ghostMap[owner];
        return arr;
    }

    function viewAllWinsForPlayerInBattle(uint256 battleId, address owner) public view returns (uint256[] memory){
        uint256[] memory arr = new uint256[](3);
        arr[0] = gemWinsByMonsterBattle[battleId][owner];
        arr[1] = totemWinsByMonsterBattle[battleId][owner];
        arr[2] = ghostWinsByMonsterBattle[battleId][owner];
        return arr;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Composable is Ownable {
    mapping(address => bool) components;

    modifier onlyComponent() {
       if (!components[msg.sender]) revert();
        _;
    }

    function addComponent(address component, bool value) external onlyOwner {
        components[component] = value;
    }

    function isComponent(address _address) public view returns (bool) {
        return components[_address];
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