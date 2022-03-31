/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/KWWMovingBoats.sol


pragma solidity ^0.8.4;


interface IKWWMovingBoats {
    struct MovingBoatDetails{
        uint256 id;
        //When the sail started
        uint64 startSailTime;
        //Kangaroos on the boat
        uint32[] kangaroos;
        //Types of the boat (Pirate, Native, etc.)
        uint8 boatState;
        //What is the route of the boat?
        uint8 route;
    }
}


contract KWWMovingBoats is Ownable, IKWWMovingBoats { 
    uint256 lastId = 0;
    address gameManager;

    mapping(uint256 => MovingBoatDetails) public boatsData;
    mapping(uint8 => uint8) public routeToDuration;

    /*
       EXECUTABLE FUNCTIONS
    */

    function startSail(uint8 boatState, uint8 route, uint32[] calldata kangaroos) public onlyGameManager{
        lastId = lastId + 1;
        boatsData[lastId] = MovingBoatDetails(lastId, uint64(block.timestamp), kangaroos, boatState, route);
    }


    /*
       GETTERS
    */

    function getLastId() public view returns(uint256) {
        return lastId;
    }

    function getBoatData(uint16 tokenId) public view returns(MovingBoatDetails memory){
        require(boatsData[tokenId].boatState != 0, "Token not exists");
        return boatsData[tokenId];
    }

    function getKangaroos(uint16 tokenId) public view returns(uint32[] memory){
      require(boatsData[tokenId].boatState != 0, "Token not exists");
      return boatsData[tokenId].kangaroos;
    }

    function getStartSailTime(uint16 tokenId) public view returns(uint64){
      require(boatsData[tokenId].startSailTime != 0, "Token not exists");
      return boatsData[tokenId].startSailTime;
    }
    
    function getBoatState(uint16 tokenId) public view returns(uint8){
      require(boatsData[tokenId].boatState != 0, "Token not exists");
      return boatsData[tokenId].boatState;
    }
 
    function getRoute(uint16 tokenId) public view returns(uint8){
      require(boatsData[tokenId].boatState != 0, "Token not exists");
      return boatsData[tokenId].route;
    }

    function sailEnd(uint16 tokenId) public view returns(uint64){
      require(boatsData[tokenId].startSailTime > 0, "Sail is not active");
      require(routeToDuration[boatsData[tokenId].route] > 0, "Route data not exists");
      return boatsData[tokenId].startSailTime + routeToDuration[boatsData[tokenId].route] * 1 days;
    }

    /*
        MODIFIERS
    */
    modifier onlyGameManager() {
        require(msg.sender == owner() || (gameManager != address(0) &&msg.sender == gameManager), "caller is not the game manager");
        _;
    }

    /*
        ONLY OWNER
    */

    function setGameManager(address _addr) public onlyOwner{
      gameManager = _addr;
    }
    
    function setRouteDuration(uint8 route, uint8 duration) public onlyOwner{
        routeToDuration[route] = duration;
    }
}