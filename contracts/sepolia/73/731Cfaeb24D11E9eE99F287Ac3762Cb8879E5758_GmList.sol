// SPDX-License-Identifier: Unlicensed

/*
    $$$$$$\  $$\      $$\       $$\       $$\             $$\     
    $$  __$$\ $$$\    $$$ |      $$ |      \__|            $$ |    
    $$ /  \__|$$$$\  $$$$ |      $$ |      $$\  $$$$$$$\ $$$$$$\   
    $$ |$$$$\ $$\$$\$$ $$ |      $$ |      $$ |$$  _____|\_$$  _|  
    $$ |\_$$ |$$ \$$$  $$ |      $$ |      $$ |\$$$$$$\    $$ |    
    $$ |  $$ |$$ |\$  /$$ |      $$ |      $$ | \____$$\   $$ |$$\ 
    \$$$$$$  |$$ | \_/ $$ |      $$$$$$$$\ $$ |$$$$$$$  |  \$$$$  |
    \______/ \__|     \__|      \________|\__|\_______/    \____/ 

    by 0xRebels                                                        
*/                                                      
                                                               
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/access/Ownable.sol";

contract GmList is Ownable {
    uint256 private  _wlCounter;
    address private _coldStorage;
    uint256 private _costPerWlCapacitySpot;
    uint256 private _maxCostPerWhitelist;
    uint256 private _freeWhitelistCpacityLimit;
    bool private _isPaused;

    struct Whitelist {
        address whitelistOwner;
        string whitelistName;
        string collectionName;
        uint256 whitelistCapacity;
        address collectionSmartContract;
        uint256 whitelistSpotCost;
        address whitelistCostWalletRecipient;
        uint256 mintLimit;
        uint256 collectionSupply;
        bool isEnabled;
        bool suspended;
    }

    mapping (uint256 => Whitelist) private _whitelists;
    //All whitelists beglonging to the a single owner
    mapping (address => uint256[]) _myWhitelists;

    //A single address can be whitelisted for multiple whitelists
    mapping (address => uint256[]) private _whitelisted;

    //All addresses in a signle whitelist
    mapping (uint256 => mapping(address => bool)) private _wlMembers; //For easier isWhitelisted verification
    mapping (uint256 => address[]) private _allWlMembers; //For easier counting

    //If WL spots are not free, or the NFT creator is running a pre-sale
    mapping (address => mapping(uint256 => uint256)) private _prepaidAmounts;

    constructor(uint256 wlCapacityLimit, uint256 maxCostPerWl, uint256 costPerWlCapacitySpot, address csAddress) {
        _wlCounter = 0;
        _freeWhitelistCpacityLimit = wlCapacityLimit;
        _maxCostPerWhitelist = maxCostPerWl;
        _costPerWlCapacitySpot = costPerWlCapacitySpot;
        _coldStorage = csAddress;
        _isPaused = false;
    }

    function createWhitelist (string calldata whitelistName, string calldata collectionName, uint256 whitelistCapacity, address collectionSmartContract, uint256 whitelistSpotCost, address whitelistCostWalletRecipient, uint256 mintLimit, uint256 collectionSupply)
    public
    payable
    returns (uint256)
    {
        uint256 newWlCost = getNewWhitelistCost(whitelistCapacity);
        require(!_isPaused, "GM List contract is currently paused");
        require(keccak256(abi.encodePacked(whitelistName)) != keccak256(abi.encodePacked("")), "Whitelist name is required.");
        require(keccak256(abi.encodePacked(collectionName)) != keccak256(abi.encodePacked("")), "Collection name is required.");
        require(msg.value >= newWlCost, "Insufficient funds sent for Whitelist creation.");
        require(whitelistCapacity <= collectionSupply, "No overallocating.");
        require(pay(newWlCost) == true, "Payment failed.");


        _wlCounter = _wlCounter + 1;
        uint256 whitelistId = _wlCounter;
        Whitelist memory whitelist;

        whitelist.whitelistOwner = msg.sender;
        whitelist.whitelistName = whitelistName;
        whitelist.collectionName = collectionName;
        whitelist.whitelistCapacity = whitelistCapacity;
        whitelist.collectionSmartContract = collectionSmartContract;
        whitelist.whitelistSpotCost = whitelistSpotCost;
        whitelist.whitelistCostWalletRecipient = whitelistCostWalletRecipient;
        whitelist.mintLimit = mintLimit;
        whitelist.collectionSupply = collectionSupply;
        whitelist.isEnabled = true;
        whitelist.suspended = false;

        uint256[] storage creatorWhitelists = _myWhitelists[msg.sender];
        creatorWhitelists.push(whitelistId);
        _myWhitelists[msg.sender] = creatorWhitelists;

        _whitelists[whitelistId] = whitelist;
        return whitelistId;
    }


    function joinWhitelist(uint256 whitelistId)
    public
    payable
    {
        uint256 whitelistSpotCost = _whitelists[whitelistId].whitelistSpotCost;
        uint256 whitelistLimit = _whitelists[whitelistId].whitelistCapacity;
        address whitelistCostRecepientWallet = _whitelists[whitelistId].whitelistCostWalletRecipient;
        bool isWlEnabled = _whitelists[whitelistId].isEnabled;

        uint256 currentWlMembersCount = getWhitelistMembersCount(whitelistId);
        require(!_isPaused, "GM List contract is currently paused");
        require(whitelistId <= _wlCounter, "Whitelist with this ID does not exist.");
        require(isWhitelisted(whitelistId, msg.sender) != true, "You are already on this Whitelist");
        require(msg.value == whitelistSpotCost, "Insufficient amount for joining this whitelist.");
        require(currentWlMembersCount < whitelistLimit, "This whitelist is full.");
        require(isWlEnabled == true, "Whitelist does not accept new entries at the moment.");
        require(isWhitelistSuspended(whitelistId) == false, "This whitelist is suspended at the moment.");
        require(payToJoinWhitelist(whitelistCostRecepientWallet, whitelistSpotCost) == true, "Payment failed.");

        //Add user to whitelist
        _wlMembers[whitelistId][msg.sender] = true;
        _allWlMembers[whitelistId].push(msg.sender);

        //Add whitelist to the list of WLs the sender is whitelisted for
        _whitelisted[msg.sender].push(whitelistId);

        //Record minter's payment. To be deducted during mint if needed, as implemented by NFT Creator
        _prepaidAmounts[msg.sender][whitelistId] = whitelistSpotCost;
    }

    function isWhitelisted(uint256 whitelistId, address minterAddress)
    public
    view
    returns(bool)
    {
        return _wlMembers[whitelistId][minterAddress];
    }

    function getPrepaidAmount(address minter, uint256 whitelistId)
    public
    view
    returns(uint256)
    {
        return _prepaidAmounts[minter][whitelistId];
    }

    function getMinterWhitelists(address minter)
    external
    view
    returns(uint256[] memory)
    {
        return _whitelisted[minter];
    }

    function getCreatorWhitelists(address creator)
    external
    view
    returns(uint256[] memory)
    {
        return _myWhitelists[creator];
    }

    function getWhitelistMembersCount(uint256 whitelistId)
    public
    view
    returns (uint256)
    {
        
        return _allWlMembers[whitelistId].length;
    }

    function getWhitelistName(uint256 whitelistId)
    public
    view
    returns (string memory)
    {
        return _whitelists[whitelistId].whitelistName;
    }

    function getWhitelistCollectionName(uint256 whitelistId)
    public
    view
    returns (string memory)
    {
        return _whitelists[whitelistId].collectionName;
    }

    function getWhitelistCollectionSupply(uint256 whitelistId)
    public
    view
    returns (uint256)
    {
        return _whitelists[whitelistId].collectionSupply;
    }

    function getWhitelistCollectionSc(uint256 whitelistId)
    public
    view
    returns (address)
    {
        return _whitelists[whitelistId].collectionSmartContract;
    }

    function getWhitelistPaymentRecipient(uint256 whitelistId)
    public
    view
    returns (address)
    {
        return _whitelists[whitelistId].whitelistCostWalletRecipient;
    }

    function getWhitelistMintLimit(uint256 whitelistId)
    public
    view
    returns (uint256)
    {
        return _whitelists[whitelistId].mintLimit;
    }

    function getWhitelistCapacity(uint256 whitelistId)
    public
    view
    returns (uint256)
    {
        return _whitelists[whitelistId].whitelistCapacity;
    }

    function getWhitelistSpotCost(uint256 whitelistId)
    public
    view
    returns (uint256)
    {
        return _whitelists[whitelistId].whitelistSpotCost;
    }

    function isWhitelistSuspended (uint256 whitelistId)
    public
    view
    returns(bool)
    {
        return _whitelists[whitelistId].suspended;
    }

    function isWhitelistEnabled (uint256 whitelistId)
    public
    view
    returns(bool)
    {
        return _whitelists[whitelistId].isEnabled;
    }

    function getUpgradeCost(uint256 currentCapacityLimit, uint256 newWlCapacityLimit)
    internal
    view
    returns (uint256)
    {
        uint256 oldCost = getNewWhitelistCost(currentCapacityLimit);
        uint256 newCost = getNewWhitelistCost(newWlCapacityLimit);
        uint256 cost = 0;
        if(oldCost <= newCost){
            cost = newCost - oldCost;
        }
        
        return cost;
    }

    function upgradeWhitelistSpotLimit(uint256 whitelistId, uint256 newWlCapacityLimit)
    public
    payable
    returns(bool)
    {
        uint256 currentMemberCount = getWhitelistMembersCount(whitelistId);
        uint256 currentCapacityLimit = getWhitelistCapacity(whitelistId);
        uint256 cost = getUpgradeCost(currentCapacityLimit, newWlCapacityLimit);
        require(!_isPaused, "GM List contract is currently paused");
        //First, you must own the whitelist to attempt the upgrade
        require(_whitelists[whitelistId].whitelistOwner == msg.sender, "You are not the owner of this whitelist.");
        //Next, you can only attempt to increase the limits 
        require(currentMemberCount < newWlCapacityLimit, "Not possible. Whitelist capacity must be greater than the number of registered minters.");
        require(currentCapacityLimit < newWlCapacityLimit, "Not possible. You can only increase the Whitelist capacity.");
        //But you can't overallocate.
        require(_whitelists[whitelistId].collectionSupply >= newWlCapacityLimit, "No overallocating.");
        //And eventually, you must send enough ETH to perform the upgrade
        require(msg.value >= cost, "Not enough ETH sent to perform the upgrade.");
        //And the payment must be a success
        require(pay(cost), "Upgrade payment failed.");

        _whitelists[whitelistId].whitelistCapacity = newWlCapacityLimit;
        return true;
    }

    function toggleWhitelist(uint256 whitelistId)
    public
    returns(bool)
    {
        require(!_isPaused, "GM List contract is currently paused");
        require(_whitelists[whitelistId].whitelistOwner == msg.sender, "You are not the owner of this whitelist.");
        _whitelists[whitelistId].isEnabled = !_whitelists[whitelistId].isEnabled;
        return true;
    }

    function setWhitelistCollectionSmartContract(address collectionSmartContract, uint256 whitelistId)
    public
    returns(bool)
    {
        require(!_isPaused, "GM List contract is currently paused");
        require(_whitelists[whitelistId].whitelistOwner == msg.sender, "You are not the owner of this whitelist.");
        _whitelists[whitelistId].collectionSmartContract = collectionSmartContract;
        return true;
    }

    function getNewWhitelistCost(uint256 whitelistCapacity)
    public
    view
    returns(uint256)
    {
        if(whitelistCapacity <= _freeWhitelistCpacityLimit) {
            return 0;
        }

        uint256 cost = whitelistCapacity * _costPerWlCapacitySpot;
        if(cost > _maxCostPerWhitelist) {
            return _maxCostPerWhitelist;
        } else {
            return cost;
        }
    }

    function suspendWhitelist (uint256 whitelistId)
    public
    onlyOwner
    {
        _whitelists[whitelistId].suspended = !_whitelists[whitelistId].suspended;
    }

    function setFreeWlCapacityLimit (uint256 freeWlLimit)
    public
    onlyOwner
    {
        _freeWhitelistCpacityLimit = freeWlLimit;
    }

    function setCostPerWlCapacitySpot (uint256 cost)
    public
    onlyOwner
    {
        _costPerWlCapacitySpot = cost;
    }

    function setMaxCostPerWl (uint256 maxCost)
    public
    onlyOwner
    {
        _maxCostPerWhitelist = maxCost;
    }

    function setColdStorage (address newCsAddress)
    public
    onlyOwner
    {
        _coldStorage = newCsAddress;
    }

    function getLatestWhitelistId()
    public
    view
    returns(uint256)
    {
        return _wlCounter;
    }

    function isQualified (uint256 whitelistId)
    public
    view
    returns (bool) {
        if(_freeWhitelistCpacityLimit < _whitelists[whitelistId].whitelistCapacity){
            return true;
        } else {
            return false;
        }
    }

    function toggleContract()
    public
    onlyOwner
    {
        _isPaused = !_isPaused;
    }
    function payToJoinWhitelist(address whitelistCostRecepientWallet, uint256 cost)
    public
    payable
    returns (bool)
    {
        if(cost == 0) {
            return true;
        }

        (bool wlOwnerPaid, ) = whitelistCostRecepientWallet.call{value: cost}("");

        if(wlOwnerPaid) {
            return true;
        } else {
            return false;
        }
    }

    function pay(uint256 amount)
    public 
    payable
    returns (bool) 
    {   
        if(amount == 0) {
            return true;
        }
        (bool csOne, ) = _coldStorage.call{value: amount}("");

        if(csOne) {
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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