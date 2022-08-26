/**
 *Submitted for verification at Etherscan.io on 2022-08-26
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

pragma solidity ^0.8.9;

contract ARConference is Ownable {
    struct Event {
        string title;
        string location;
        uint256 startDate;
        uint256 endDate;
        string[] images;
        address[] witnessAddresses;
        bool exist;
    }

    struct ProvenanceInstance {
        uint256 nftID;
        uint256 creationDate;
        Event[] events;
        bool exist;
    }

    mapping(string => ProvenanceInstance) public instances;

    event provenanceInstanceCreated(string instanceName, uint256 nftID, uint256 creationDate);
    event eventCreated(string instanceName, string title, string location, uint256 startDate, uint256 endDate, string[] imagesArray);
    event eventImagesUpdated(string instanceName, uint256 eventID, string[] imagesArray);
    event garmentWitnessed(string instanceName, uint256 eventID, address witness);

    constructor() {}

    modifier isProvenanceExist(string memory instanceName) {
        require(instances[instanceName].exist == true, "Provenance instance with this name does not exist.");
        _;
    }

    modifier isEventsExist(string memory instanceName, uint256 eventID) {
        Event[] memory events = instances[instanceName].events;
        require(events.length > 0, "There are no events for this instance.");
        require(events[eventID].exist == true, "Event with this ID does not exist.");
        _;
    }

    function createProvenanceInstance(string memory instanceName, uint256 nftID) external onlyOwner {
        require(instances[instanceName].exist == false, "Provenance instance with this name already exists.");
        ProvenanceInstance storage instance = instances[instanceName];
        instance.nftID = nftID;
        instance.creationDate = block.timestamp;
        instance.exist = true;
        emit provenanceInstanceCreated(instanceName, nftID, block.timestamp);
    }

    function createEvent(string memory instanceName, string memory title, string memory location, uint256 startDate, uint256 endDate, string[] memory imagesArray, address[] memory witnessArray) external isProvenanceExist(instanceName) onlyOwner {
        Event memory eventElement = Event(title, location, startDate, endDate, imagesArray, witnessArray, true);
        instances[instanceName].events.push(eventElement);
        emit eventCreated(instanceName, title, location, startDate, endDate, imagesArray);
    }

    function updateEventImages(string memory instanceName, uint256 eventID, string[] memory imagesArray) external isProvenanceExist(instanceName) isEventsExist(instanceName, eventID) onlyOwner {
        instances[instanceName].events[eventID].images = imagesArray;
        emit eventImagesUpdated(instanceName, eventID, imagesArray);
    }

    function witness(string memory instanceName, uint256 eventID) external isProvenanceExist(instanceName) isEventsExist(instanceName, eventID) {
        require(instances[instanceName].events[eventID].startDate <= block.timestamp && block.timestamp <= instances[instanceName].events[eventID].endDate, "Event has not started yet.");
        instances[instanceName].events[eventID].witnessAddresses.push(msg.sender);
        emit garmentWitnessed(instanceName, eventID, msg.sender);
    }

    function getInstanceEventWitnessAddresses(string memory instanceName, uint256 eventID) external view isProvenanceExist(instanceName) isEventsExist(instanceName, eventID) returns(address[] memory) {
        return instances[instanceName].events[eventID].witnessAddresses;
    }

    function getEventInfo(string memory instanceName, uint256 eventID) external view isProvenanceExist(instanceName) isEventsExist(instanceName, eventID) returns(Event memory) {
        return instances[instanceName].events[eventID];
    }

    function getEvents(string memory instanceName) external view isProvenanceExist(instanceName) returns(Event[] memory) {
        return instances[instanceName].events;
    }
}