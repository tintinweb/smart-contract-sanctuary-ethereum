// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//        ___       ___                    ___           ___                       ___           ___     
//       /\__\     /\  \                  /\  \         /\__\          ___        /\__\         /\  \    
//      /:/  /    /::\  \                /::\  \       /::|  |        /\  \      /::|  |       /::\  \   
//     /:/  /    /:/\:\  \              /:/\:\  \     /:|:|  |        \:\  \    /:|:|  |      /:/\:\  \  
//    /:/  /    /::\~\:\  \            /::\~\:\  \   /:/|:|  |__      /::\__\  /:/|:|__|__   /::\~\:\  \ 
//   /:/__/    /:/\:\ \:\__\          /:/\:\ \:\__\ /:/ |:| /\__\  __/:/\/__/ /:/ |::::\__\ /:/\:\ \:\__\
//   \:\  \    \:\~\:\ \/__/          \/__\:\/:/  / \/__|:|/:/  / /\/:/  /    \/__/~~/:/  / \:\~\:\ \/__/
//    \:\  \    \:\ \:\__\                 \::/  /      |:/:/  /  \::/__/           /:/  /   \:\ \:\__\  
//     \:\  \    \:\ \/__/                 /:/  /       |::/  /    \:\__\          /:/  /     \:\ \/__/  
//      \:\__\    \:\__\                  /:/  /        /:/  /      \/__/         /:/  /       \:\__\    
//       \/__/     \/__/                  \/__/         \/__/                     \/__/         \/__/    

import "@openzeppelin/contracts/access/Ownable.sol";

interface ISoulsLocker {
    function getSoulsInHero(uint256 heroId) external view returns (uint16[] memory);
}

interface IWrapper {
    function ownerOf(uint256 heroId) external view returns (address);
}

interface IAdditionalLayers {
    function mintAddLayer(uint256 heroId, AddLayer calldata newLayer, uint256 minterIdx) external;
    function isLayerInHero(uint256 heroId, uint256 layer, uint256 layerId) external view returns (bool);
}

interface IDelegationRegistry { // main: 0x00000000000076A84feF008CDAbe6409d2FE638B
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId) external view returns (bool);
}

struct HeroExpData {
    uint32 score; // total Score of the project = 1'676'762 - uint32 is 4'294'967'296
    uint64 lastTimestamp;
    uint64 expAvailable; // total max possible exp of the project with 6 decimals is less than uint64.max
}

struct AddLayer {
        uint128 layer;
        uint128 id;
}

contract ExperienceManager is Ownable {

    //////
    // EVENTS
    //////
    
    event ExpClaimed(uint256 indexed heroId, uint256 expTotal);
    event ExpSpent(uint256 indexed heroId, uint256 expTotal);
    event ExpSlashed(uint256 indexed heroId);

    //////
    // STORAGE
    //////

    // Le Anime contracts
    address public immutable wrapper;
    address public immutable locker;

    // Scores of tokens SSTORE2 contract
    address public immutable pointerScores; 

    // Exp start and end timestamps
    uint64 public immutable expStart;
    uint64 public immutable expEnd;

    // Contract to lock single Hero - future use
    address public heroLock;

    // Contract to extend exp - future use
    address public expExtension;

    // Contracts allowed to use EXP
    address[] public expSpenders;

    // Contracts allowed to add EXP
    address[] public expMinters;

    // Exp Data Storage
    mapping(uint256 => HeroExpData) public heroExpData;

    // Exp initialized
    bool public expInitialized;

    // Are all withdrawals locked
    bool public withdrawalsUnlocked; 

    // Single hero withdrawals locked - IDs are 1 to 10627 
    bool[10628] public heroWithdrawalsUnlocked;

    constructor(
        address wrapper_, // main: 0x03BEbcf3D62C1e7465f8a095BFA08a79CA2892A1
        address locker_, // main: 0x1eb4490091bd0fFF6c3973623C014D082936EA03
        address pointerScores_ // main: 0xB6c6De2C865bC497A5CF8A9480Dd2e67504425ae
        ) 
        {
        expStart = uint64(1651738261); // 5 May 2022
        expEnd = uint64(1735689599); // 31 Dec 2024

        wrapper = wrapper_;
        locker = locker_;
        pointerScores = pointerScores_;

        expSpenders.push(msg.sender);
    }

    //////
    // ADMIN - SPENDERS, MINTERS, LOCKER
    //////

    function addSpender(address spenderAddress) external onlyOwner {
        expSpenders.push(spenderAddress);
    }

    function updateSpender(address spenderAddress, uint256 spenderIdx) external onlyOwner {
        expSpenders[spenderIdx] = spenderAddress;
    }

    function addMinter(address minterAddress) external onlyOwner {
        expMinters.push(minterAddress);
    }

    function updateMinter(address minterAddress, uint256 minterIdx) external onlyOwner {
        expMinters[minterIdx] = minterAddress;
    }

    // Set contract to lock heroes - for future use
    function updateHeroLock(address heroLock_) external onlyOwner {
        heroLock = heroLock_;
    }

    // Set Exp Extension contract - for future use
    function updateExpExtension(address expExtension_) external onlyOwner {
        expExtension = expExtension_;
    }

    //////
    // ADMIN - EXPERIENCE INITIALIZATION
    //////

    function setInitialHeroScoreBatch(
        uint256[] calldata heroId, 
        uint32[] calldata score, 
        uint64[] calldata experience, 
        uint64 lastTimestamp
        ) public onlyOwner 
        {
        require(expInitialized == false, "Exp init locked");
        require(lastTimestamp >= expStart, "Invalid timestamp");

        for(uint256 i = 0; i < heroId.length;) {
            heroExpData[heroId[i]] = HeroExpData(score[i], lastTimestamp, experience[i]);

            emit ExpClaimed(heroId[i], experience[i]);

            // length can't be larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }
    }

    function expInitializeLock() external onlyOwner {
        expInitialized = true;
    }

    //////
    // GET EXPERIENCE DATA
    //////

    function getHeroExpData(uint256 heroId) external view returns (HeroExpData memory) {
        return heroExpData[heroId];
    }

    //////
    // SET EXPERIENCE DATA (only exp extension)
    //////

    function setHeroExpData(uint256 heroId, HeroExpData calldata newHeroData) external  {
        require(msg.sender == expExtension, "Extension not valid");
        heroExpData[heroId] = newHeroData;
    }

    //////
    // EXP CALCULATOR AND CLAIM
    //////

    function calculateBonusExp(uint256 score) public pure returns (uint256 bonus) {
        if(score >= 100000) bonus = 50;
        else if(score >= 50000) bonus = 45;
        else if(score >= 25000) bonus = 32;
        else if(score >= 10000) bonus = 25;
        else if(score >= 5000) bonus = 20;
        else if(score >= 2500) bonus = 16;
        else if(score >= 1000) bonus = 13;
        else if(score >= 500) bonus = 10;
        else if(score >= 250) bonus = 8;
        else if(score >= 100) bonus = 6;
        else if(score >= 50) bonus = 4;
        else if(score >= 25) bonus = 2;
        else bonus = 0;
    }

    function calculateClaimableExp(uint256 heroId) public view returns (uint256 claimableExp) {
        // Get Hero EXP data into memory
        HeroExpData memory currentData = heroExpData[heroId];

        // Handle un-initialized first claim and claim after the expEnd
        if(currentData.lastTimestamp == 0 || currentData.lastTimestamp >= expEnd) {
            return 0;
        }
        else {
            // Max timestamp claimable is expEnd
            uint256 currentTimestamp = block.timestamp >= expEnd ? expEnd : block.timestamp;

            // Exp is proportional to the Hero Score + bonus
            uint256 expMultiplier = currentData.score * (100 + calculateBonusExp(currentData.score));

            // Max exp per second - 100000 * 150 = 15000000 -> only happens with score 100'000 and 50% bonus, the cap
            if(expMultiplier > 15000000) { 
                expMultiplier = 15000000;
            }

            uint256 deltaT = currentTimestamp - currentData.lastTimestamp;
            uint256 deltaT2 = currentTimestamp - expStart;
            uint256 deltaT1 = currentData.lastTimestamp - expStart;
            uint256 duration = expEnd - expStart;
            
            return expMultiplier * deltaT - expMultiplier * (deltaT2 * deltaT2 - deltaT1 * deltaT1) / (duration * 4);
        }
    }
    
    function claimExp(uint256 heroId) public {
        // check that heroID is a 2+ tokens Hero
        if (heroExpData[heroId].score > 0) {

            // claim from lastTimestamp to Now, and then update lastTimestamp
            heroExpData[heroId].expAvailable += uint64(calculateClaimableExp(heroId));
            heroExpData[heroId].lastTimestamp = uint64(block.timestamp);

            emit ExpClaimed(heroId, heroExpData[heroId].expAvailable);
        }
        else {
            // if not a 2+ Hero - only update lastTimestamp
            heroExpData[heroId].lastTimestamp = uint64(block.timestamp);
        }

    }

    //////
    // USE AND ADD EXPERIENCE
    //////

    function useExperience(uint256 heroId, uint64 expUsed, uint256 spenderIdx)
    external
    {
        require(msg.sender == expSpenders[spenderIdx], "Spender not valid");

        require(expUsed <= heroExpData[heroId].expAvailable, "Not enough EXP");
        // subtraction with underflow already checked 
        unchecked {
            heroExpData[heroId].expAvailable -= expUsed;
        }

        emit ExpSpent(heroId, heroExpData[heroId].expAvailable);    
    }

    function creditExperience(uint256 heroId, uint64 expToCredit, uint256 minterIdx)
    external
    {
        require(msg.sender == expMinters[minterIdx], "Minter not valid");

        heroExpData[heroId].expAvailable += expToCredit;
        
        emit ExpClaimed(heroId, heroExpData[heroId].expAvailable);  
    }

    //////
    // ADMIN LOCK WITHDRAWALS
    //////

    // unlock all Withdrawals - for future mechanics
    function unlockAllWithdrawals(bool state) external onlyOwner {
        withdrawalsUnlocked = state;
    }

    // Single Hero unlocker - for future mechanics
    function unlockHeroWithdrawals(uint256 heroId, bool state) external {
        require(msg.sender == heroLock, "Not allowed");
        heroWithdrawalsUnlocked[heroId] = state;
    }

    //////
    // SCORE FUNCTIONS
    //////

    // Returns heroId Score or returns 0 if is not a 2+ Hero
    function getHeroScoreEXP(uint256 heroId) public view returns (uint256 totScore){
        uint16[] memory tokenId = ISoulsLocker(locker).getSoulsInHero(heroId);

        // Identify single tokens from merged Heroes by returning 0 score
        if(tokenId.length == 0) { 
            return 0; 
        }

        // Load scores of all 10627 tokenIds
        bytes memory allData; // = SSTORE2.read(pointerScores);

        address pointer = pointerScores;

        // load scores from external storage contract - from SSTORE2 
        assembly {
            // Get the pointer to the free memory and allocate
            allData := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // Allocate enough 32-byte words for the data and the length of the data
            // This is the new "memory end" including padding
            // mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(0x40, add(allData, 10688))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(allData, 10627) 

            // Copy the code into memory right after the 32 bytes used to store the size.
            extcodecopy(pointer, add(allData, 32), 1, 10627)
        }
        
        // Scores are bounded, and highest possible score is less than uint32.max
        unchecked {
            // starts the count with the main token associated with heroId 
            // use correct multiplier - 20 for Le Anime and 1 for Spirits
            totScore = uint8(allData[heroId - 1]) * uint256(heroId <= 1573 ? 20 : 1);
            
            // add the score for each token contained
            for (uint256 i = 0; i < tokenId.length; ++i){  
                totScore += uint8(allData[tokenId[i] - 1]) * uint256(tokenId[i] <= 1573 ? 20 : 1);
            }
    
        }  
        
    }

    //////
    // CALLBACKS FUNCTIONS FROM SOULSLOCKER 
    //////

    // Callback for depositSoulsBatch
    function afterDeposit(uint256 heroId) external {
        require(msg.sender == locker);

        // First claimExp, with the score settings pre-deposit
        claimExp(heroId); 

        // Then, update the score of the Hero - timestamp and expAvailable are already updated by claimExp()
        heroExpData[heroId].score = uint32(getHeroScoreEXP(heroId));
    }

    // Callback for mergeHeroes
    function afterMergeHeroes(uint256 mainHeroId, uint256 mergedHeroId) external { 
        require(msg.sender == locker);

        // First claim Exp on both heroes 
        claimExp(mainHeroId); 
        claimExp(mergedHeroId);

        // Add the Exp of mergedHeroId to mainHeroId and sets mergedHeroId Exp to zero
        heroExpData[mainHeroId].expAvailable += heroExpData[mergedHeroId].expAvailable;
        heroExpData[mergedHeroId].expAvailable = 0;

        // Updates score of mainHeroId and sets the mergedHero score to zero
        heroExpData[mainHeroId].score = uint32(getHeroScoreEXP(mainHeroId));
        heroExpData[mergedHeroId].score = 0;
    }

    // Callback for withdrawAll
    function afterWithdrawAll(uint256 heroId) external {
        require(msg.sender == locker);
        require(withdrawalsUnlocked, "locked");
        require(heroWithdrawalsUnlocked[heroId], "locked hero");

        // Set Score and Exp to 0, and update timestamp
        heroExpData[heroId].expAvailable = 0;
        heroExpData[heroId].lastTimestamp = uint64(block.timestamp);
        heroExpData[heroId].score = 0;

        emit ExpSlashed(heroId); 
    }

    // Callback for withdrawSoulsBatch
    function afterWithdrawBatch(uint256 heroId) external {
        require(msg.sender == locker);
        require(withdrawalsUnlocked, "locked");
        require(heroWithdrawalsUnlocked[heroId], "locked hero");

        heroExpData[heroId].expAvailable = 0;
        heroExpData[heroId].lastTimestamp = uint64(block.timestamp);

        // Sets to new score - getHeroScore_EXP returns 0 when not a merged 2+ token
        heroExpData[heroId].score = uint32(getHeroScoreEXP(heroId));

        emit ExpSlashed(heroId);
    }

}

// The Emporium allows users to redeem Additional Layers in exchange for EXP
contract Emporium is Ownable {

    struct AddLayerItem {
        uint64 layer;
        uint64 id;
        uint64 expCost;
        uint64 qtyAvailable;
    }

    uint256 public constant AL_MINTER_ID = 1;
    uint256 public constant EXP_SPENDER_ID = 1;

    // Delegate Cash Registry
    IDelegationRegistry public immutable delegateCash;

    // Wrapper Interface
    IWrapper public immutable wrapper;

    // AddLayers Interface
    IAdditionalLayers public immutable additionalLayers;

    // Experience Interface
    ExperienceManager public immutable experience;

    // Inventory of available Additional Layers in the Emporium
    AddLayerItem[] public addLayersInventory;

    constructor(address wrapperAddress_, address additionalLayers_, address experience_) {
        wrapper = IWrapper(wrapperAddress_); // main: 0x03BEbcf3D62C1e7465f8a095BFA08a79CA2892A1
        additionalLayers = IAdditionalLayers(additionalLayers_); // main: 0xE93D07a731FEdF4F676Aaa057Bd534832d3012F0
        experience = ExperienceManager(experience_); // main: 0x55124b7C32Ab50932725ec6e34bDB53725e2bbd2
        delegateCash = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);
    }

    //////
    // ADMIN ADD/MODIFY ITEMS
    //////

    // Add new item to the inventory
    // Reminder that EXP has 6 digits precision: 1 EXP is 1'000'000
    function addNewItem(uint64 layer, uint64 id, uint64 expCost, uint64 maxQuantity) external onlyOwner {
        addLayersInventory.push(AddLayerItem(layer, id, expCost, maxQuantity));
    }

    function modifyItem(uint256 itemIdx, uint64 layer, uint64 id, uint64 expCost, uint64 maxQuantity) external onlyOwner {
        addLayersInventory[itemIdx] = AddLayerItem(layer, id, expCost, maxQuantity);
    }

    function addNewItemBatch(uint64[4][] calldata newItems) external onlyOwner {
        for(uint256 i = 0; i < newItems.length; ) {
            addLayersInventory.push(AddLayerItem(newItems[i][0], newItems[i][1], newItems[i][2], newItems[i][3]));

            unchecked {
                ++i;
            }
        } 
    }

    //////
    // GET INVENTORY
    //////

    function getInventory() external view returns (AddLayerItem[] memory) {
        return addLayersInventory;
    }

    //////
    // USER GET ITEM WITH EXP
    //////

    function getNewItem(uint256 heroId, uint256 itemIdx, address vault) external {
        address requester = msg.sender;

        if (vault != address(0)) { 
            bool isDelegateValid = delegateCash.checkDelegateForToken(msg.sender, vault, address(wrapper), heroId + 100000);
            require(isDelegateValid, "invalid delegate-vault pairing");
            requester = vault;
        }

        require(wrapper.ownerOf(heroId + 100000) == requester, "Not the owner");

        AddLayerItem memory newItem = addLayersInventory[itemIdx];

        // check if hero already has it to avoid multiple redemption
        require(!additionalLayers.isLayerInHero(heroId, newItem.layer, newItem.id), "Already in Hero");

        // Mint AdditionalLayer in heroId
        additionalLayers.mintAddLayer(heroId, AddLayer(newItem.layer, newItem.id), AL_MINTER_ID);

        // "Spend" exp from heroId - Reverts if exp balance is not enough
        experience.useExperience(heroId, newItem.expCost, EXP_SPENDER_ID);

        // If supply is >= 10627, the supply is infinite
        if(newItem.qtyAvailable < 10627) {
            require(newItem.qtyAvailable > 0, "Out of stock");
            // no underflow for qtyAvailable > 0 
            unchecked {
                --addLayersInventory[itemIdx].qtyAvailable;  
            }     
        }
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