// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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


import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import "@rari-capital/solmate/src/utils/SSTORE2.sol";


// interface of Le Anime V2 wrapper contract + IERC721Metadata

interface IWrapper is IERC721Metadata {

    function transferFromBatch(address from, address to, uint256[] calldata tokenId) external;

}

// interface for merger callback contract - for future implementation

interface IMerger {
    function afterDeposit(uint256 heroId) external;
    function afterWithdrawAll(uint256 heroId) external;
    function afterWithdrawBatch(uint256 heroId) external;
    function afterMergeHeroes(uint256 mainHeroId, uint256 mergedHeroId) external;

    function afterLayerDeposit(uint256 heroId) external;
    function afterLayerWithdrawal(uint256 heroId) external;
}

// Merging Rules

struct MergeParameters {
    uint256[] rankThresholds; // Hero levels thresholds

    mapping(uint256 => uint256) additionalExtrasForRank; // number of additional extra slots for Hero Level
    mapping(uint256 => mapping(uint256 => uint256[])) traitsLevelsCut; // traits levels thresholds
}

// Hero Storage of Traits and Parameters

struct heroParams { 
    uint32 score; // max score of merged heroes is 255*10627*20 = 54'197'700 and uint32 is 4'294'967'295
    uint32 extraScore; // same as above for additional scoring

    uint16 imageIdx; // image displayed - max is 10627 variants - uint16 is 65536
    uint8 visibleBG; // max is 255 - this is the full colour BG overlay
    bool state; // anime&spirits vs hero state
    bool locked; // locker 
    
    bytes params; // hero traits
    bytes upper; // hero more traits
    bytes extraLayers; // additional layers
    bytes[] moreParams; // more additional layers
}

///////////////////////
// LOCKER CONTRACT
///////////////////////

contract SoulsLocker is Ownable {

    event DepositedSouls(uint256 indexed heroId, uint256[] tokenId);
    event ReleasedAllSouls(uint256 indexed heroId);
    event ReleasedSouls(uint256 indexed heroId, uint256[] index);
    event MergedHeroes(uint256 indexed mainHeroId, uint256 indexed mergedHeroId);

    uint256 private constant OFFSETAN2 = 100000;

    // WRAPPER CONTRACT
    IWrapper public wrapper;

    // MERGER CONTRACT - for callback implementation
    IMerger public merger;

    // Is merger contract closed? allows to render that immutable
    bool public closedMergerUpdate = false;

    // SOULS IN HERO
    mapping(uint256 => uint16[]) public soulsInHero;

    // Max units that can be merged
    uint256 public maxMergeUnits = 1000;

    // activate extra functionalities
    bool public isMergeHeroesActive = false;

    bool public isMergeHeroesBatchActive = false;

    bool public isWithdrawSoulsBatchActive = false;

    // EMERGENCY RECOVER FUNCTION TO BE REVOKED
    bool public emergencyRevoked = false;

    constructor(address wrapperAddress_) {
        wrapper = IWrapper(wrapperAddress_);
    }

    /*///////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function updateMerger(address mergerAddress_) external onlyOwner {
        require(!closedMergerUpdate, "Update Closed");
        merger = IMerger(mergerAddress_);
    }

    function closeUpdateMerger() external onlyOwner {
        closedMergerUpdate = true;
    }

    function changeMaxMergeUnits(uint256 maxMergeUnits_) external onlyOwner {
        require(!closedMergerUpdate, "Update Closed");
        maxMergeUnits = maxMergeUnits_;
    }

    function activateMergeHeroes() external onlyOwner {
        isMergeHeroesActive = true;
    }

    function activateMergeHeroesBatch() external onlyOwner {
        isMergeHeroesBatchActive = true;
    }

    function activateWithdrawSoulBatch() external onlyOwner {
        isWithdrawSoulsBatchActive = true;
    }

    /*///////////////////////////////////////////////////////////////
                            EMERGENCY FUNCTION
    //////////////////////////////////////////////////////////////*/

    
    // revokes the temporary emergency function - only owner can trigger it and will be disabled in the future
    function revokeEmergency() external onlyOwner  {
        emergencyRevoked = true;
    }

    // *** EMERGENCY FUNCTION *** emergency withdrawal to recover stuck ERC721 sent to the contract
    function emergencyRecoverBatch(address to, uint256[] calldata tokenId) external onlyOwner {
        require(emergencyRevoked == false, "Emergency power revoked");

        wrapper.transferFromBatch(address(this), to, tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                            STORAGE GETTERS
    //////////////////////////////////////////////////////////////*/

    function getSoulsInHero(uint256 heroId) external view returns (uint16[] memory) {
        return soulsInHero[heroId];
    }

    /*///////////////////////////////////////////////////////////////
                            DEPOSIT/WITHDRAW
    //////////////////////////////////////////////////////////////*/

    // deposit only Souls And Spirits into Main token
    function depositSoulsBatch(uint256 heroId, uint256[] calldata tokenId) external {
        
        require(msg.sender == wrapper.ownerOf(heroId + OFFSETAN2), "Not the owner");

        uint256 totalHeroLength = soulsInHero[heroId].length + 1;

        require(totalHeroLength + tokenId.length <= maxMergeUnits, "Max units: 1000");

        // Max id mintable in anime contract is 110627 so (max - OFFSETAN2) is 10627
        wrapper.transferFromBatch(msg.sender, address(this), tokenId);

        uint16 currTokenId;

        for (uint256 i = 0; i < tokenId.length ; i++){

            currTokenId = uint16(tokenId[i] - OFFSETAN2);

            require(heroId != currTokenId, "Cannot add itself");
            require(soulsInHero[currTokenId].length == 0, "Cannot add a hero");

            soulsInHero[heroId].push(currTokenId);  
            
        }

        // call function after deposit - future implementation
        if (address(merger) != address(0)) {
            merger.afterDeposit(heroId);
        }

        emit DepositedSouls(heroId, tokenId);
        
    }

    // deposit Souls, Spirits and Heroes into Main token - activate later
    function depositSoulsBatchHeroes(uint256 heroId, uint256[] calldata tokenId) external {
        require(isMergeHeroesBatchActive, "Hero batch merge not active");
        
        // check if caller is the owner of the hero
        require(msg.sender == wrapper.ownerOf(heroId + OFFSETAN2), "Not the owner");

        // batch transfer tokens into this contract
        wrapper.transferFromBatch(msg.sender, address(this), tokenId);

        // store variable for the temporary current token id to add to the hero
        uint16 currTokenId;

        for (uint256 i = 0; i < tokenId.length ; i++){
            currTokenId = uint16(tokenId[i] - OFFSETAN2);

            // check hero is not adding itself
            require(heroId != currTokenId, "Cannot add itself");
            
            // check if the token to add contains already tokens or not
            // if not simply add token, else process internal tokens

            if (soulsInHero[currTokenId].length == 0) {

                soulsInHero[heroId].push(currTokenId); 
            }
            else {
                // process hero into hero
                // add main hero token - this one is outside the contract
                soulsInHero[heroId].push(currTokenId); 

                // adds the internal tokens already in the contract, into the new hero
                uint16[] memory currentSouls = soulsInHero[currTokenId];

                // add all internal tokens to new hero and counts length
                for (uint256 j = 0; j < currentSouls.length ; j++){
                    soulsInHero[heroId].push(currentSouls[j]);
                }
                
                // clears the added hero
                delete soulsInHero[currTokenId];
                
            }

        }

        // check the hero is not larger than max units
        require(soulsInHero[heroId].length + 1 <= maxMergeUnits, "Max units: 1000");
        
        // callback function after deposit
        if (address(merger) != address(0)) {
            merger.afterDeposit(heroId);
        }

        emit DepositedSouls(heroId, tokenId);  
    }

    // Withdraw all the tokens from main token
    function withdrawSoulsBatchAll(uint256 heroId) external {

        // check caller is the Hero owner
        require(msg.sender == wrapper.ownerOf(heroId + OFFSETAN2), "Not the owner");
        
        uint16[] memory soulsToWithdraw = soulsInHero[heroId];

        // transfer all the souls out
        for (uint256 i = 0; i < soulsToWithdraw.length; i++) {
            wrapper.transferFrom(address(this), msg.sender, soulsToWithdraw[i] + OFFSETAN2);
        }

        //removes the list of locked souls
        delete soulsInHero[heroId];

        // callback - for future implementation
        if (address(merger) != address(0)) {
            merger.afterWithdrawAll(heroId);
        }

        emit ReleasedAllSouls(heroId);
    }

    function withdrawSoulsBatch(uint256 heroId, uint256[] calldata index) external {
        require(isWithdrawSoulsBatchActive, "Batch withdrawal not active");
        // check the  caller is the hero owner
        require(msg.sender == wrapper.ownerOf(heroId + OFFSETAN2), "Not the owner");

        // pointer to storage for easy access
        uint16[] storage array = soulsInHero[heroId];

        wrapper.transferFrom(address(this), msg.sender, array[index[0]] + OFFSETAN2);
        
        array[index[0]] = array[array.length - 1];
        array.pop();

        for (uint256 i = 1; i < index.length; i++) {

            // makes sure the indexes are in descending order 
            require(index[i] < index[i - 1], "not in descending order");

            // first transfer
            wrapper.transferFrom(address(this), msg.sender, array[index[i]] + OFFSETAN2);

            array[index[i]] = array[array.length - 1];
            array.pop();
        }

        //cALLBACK
        if (address(merger) != address(0)) {
            merger.afterWithdrawBatch(heroId);
        }

        emit ReleasedSouls(heroId, index);
    }

    // merge hero 2 into hero 1 - activate later
    function mergeHeroes(uint256 mainHeroId, uint256 mergedHeroId) external {
        require(isMergeHeroesActive, "Hero merge not active");
        require(mainHeroId != mergedHeroId, "Cannot add itself");

        require(msg.sender == wrapper.ownerOf(mainHeroId + OFFSETAN2), "Not the owner");
        require(msg.sender == wrapper.ownerOf(mergedHeroId + OFFSETAN2), "Not the owner");

        uint16[] storage mainHeroSouls = soulsInHero[mainHeroId];

        uint16[] memory mergedHeroSouls = soulsInHero[mergedHeroId];

        require(mainHeroSouls.length + 1 + mergedHeroSouls.length + 1 <= maxMergeUnits, "Max units: 1000");

        // transfer the mergedHero token
        wrapper.transferFrom(msg.sender, address(this), mergedHeroId + OFFSETAN2);

        // adds the mergedHero token
        mainHeroSouls.push(uint16(mergedHeroId));

        // adds tokens inside mergedHero token - already locked
        for (uint256 i = 0; i < mergedHeroSouls.length ; i++){ 
            mainHeroSouls.push(mergedHeroSouls[i]);
        }

        // delete token list in mergedHero
        delete soulsInHero[mergedHeroId];

        // After Merge Callback - future implementation
        if (address(merger) != address(0)) {
            merger.afterMergeHeroes(mainHeroId, mergedHeroId);
        }

    }
}

///////////////////////
// HERO DATA CONTRACT
///////////////////////

contract HeroDataStorage is Ownable {

    event NewHeroData(uint256 indexed heroId, heroParams newParams);

    uint256 private constant OFFSETAN2 = 100000;

    // WRAPPER CONTRACT
    IWrapper public wrapper;

    // MERGER CONTRACT ADDRESS
    address public mergerAddress;

    // merger contract update closed?
    bool public closedMergerUpdate = false;

    // HERO STORAGE
    heroParams[10628] public dataHero;

    constructor(address wrapperAddress_) {
        
        wrapper = IWrapper(wrapperAddress_);

    }

    /*///////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function updateMerger(address mergerAddress_) external onlyOwner {
        require(!closedMergerUpdate, "Update Closed");
        mergerAddress = mergerAddress_;    
    }

    function closeUpdateMerger() external onlyOwner {
        closedMergerUpdate = true;
    }

    
    /*///////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getData(uint256 heroId) external view returns (heroParams memory) {
        return dataHero[heroId];
    }

    /*///////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    //this function will be used by the merge contracts to set data
    function setData(uint256 heroId, heroParams calldata newHeroData) external { 
        require(msg.sender == mergerAddress, "Not allowed - only merger");
        dataHero[heroId] = newHeroData;

        emit NewHeroData(heroId, dataHero[heroId]);
    }

    //this functions will be used by the hero owner to set data
    function setDataOwner(uint256 heroId, bytes calldata params_) external { 
        require(msg.sender == wrapper.ownerOf(heroId + OFFSETAN2), "Not the owner");

        dataHero[heroId].params = params_;

        emit NewHeroData(heroId, dataHero[heroId]);

    }

    function setDataOwner(uint256 heroId, bytes calldata params_, uint8 bg_) external { 
        require(msg.sender == wrapper.ownerOf(heroId + OFFSETAN2), "Not the owner");

        dataHero[heroId].params = params_;

        dataHero[heroId].visibleBG = bg_;

        emit NewHeroData(heroId, dataHero[heroId]);

    }

    function setDataOwner(uint256 heroId, bytes calldata params_, uint16 image_, uint8 bg_) external { 
        require(msg.sender == wrapper.ownerOf(heroId + OFFSETAN2), "Not the owner");

        dataHero[heroId].params = params_;

        dataHero[heroId].imageIdx = image_;

        dataHero[heroId].visibleBG = bg_;

        emit NewHeroData(heroId, dataHero[heroId]);

    }

    function setDataOwner(uint256 heroId, bytes[3] calldata heroP_, uint16 image_, uint8 bg_) external { 
        require(msg.sender == wrapper.ownerOf(heroId + OFFSETAN2), "Not the owner");

        dataHero[heroId].params = heroP_[0];
        dataHero[heroId].extraLayers = heroP_[1];
        dataHero[heroId].upper = heroP_[2];

        dataHero[heroId].imageIdx = image_;
        dataHero[heroId].visibleBG = bg_;

        emit NewHeroData(heroId, dataHero[heroId]);

    }

    function setDataOwner(uint256 heroId, heroParams calldata newHeroData) external { 
        require(msg.sender == wrapper.ownerOf(heroId + OFFSETAN2), "Not the owner");

        dataHero[heroId] = newHeroData;

        emit NewHeroData(heroId, dataHero[heroId]);
    }
  
}

///////////////////////
// MERGE DATA CONTRACTS
///////////////////////

contract StoreCharacters is Ownable {

    // ANIME / SPIRITS - METADATA STORAGE IN A CONTRACT
    address[] public pointers;

    // is the contract closed to modify souls and spirits data?
    bool public closedCharacters = false;

    /*///////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS MERGE
    //////////////////////////////////////////////////////////////*/
    
    function closeCharacters() external onlyOwner  {
        closedCharacters = true;
    }

    /*///////////////////////////////////////////////////////////////
                       STORE METADATA IN CONTRACTS
    //////////////////////////////////////////////////////////////*/

    function setTraitsBytes(bytes calldata params) external onlyOwner {
            require(!closedCharacters, "Closed");
            pointers.push(SSTORE2.write(params));   
    }

    function setPointers(address[] calldata pointersList) external onlyOwner {
        require(!closedCharacters, "Closed");
        pointers = pointersList;
    }

    /*///////////////////////////////////////////////////////////////
                       READ METADATA FROM CONTRACTS
    //////////////////////////////////////////////////////////////*/

    function getTraitsData(uint256 pointerId) external view returns (bytes memory) {
        return SSTORE2.read(pointers[pointerId]);
    }

    function getCharTraits(uint256 tokenId) external view returns (bytes memory) {
        //you can save 3000 tokens traits per contract
        uint256 pointer = (tokenId - 1) / 3000;
        uint256 idx = (tokenId - 1) % 3000 * 8;
        return SSTORE2.read(pointers[pointer], idx, idx + 8);
    }

    function getCharTraitsUInt8(uint256 tokenId) external view returns (uint8[8] memory) {
        uint256 pointer = (tokenId - 1) / 3000;
        uint256 idx = (tokenId - 1) % 3000 * 8;
        bytes memory temp =  SSTORE2.read(pointers[pointer], idx, idx + 8);
        
        return [
            uint8(temp[0]), uint8(temp[1]), uint8(temp[2]), uint8(temp[3]), 
            uint8(temp[4]), uint8(temp[5]), uint8(temp[6]), uint8(temp[7])
            ];
    }

}

contract LeAnimeV2MergerLAB is StoreCharacters {

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    // SETTING MERGE CONSTANTS
    uint256 private constant OFFSETAN2 = 100000;

    // MERGE PARAMETERS
    MergeParameters private mergeP;

    bool public mergeActive;

    // WRAPPER CONTRACT
    IWrapper public wrapper;

    // SOULS LOCKER
    SoulsLocker public locker;

    // HERO STORAGE 
    HeroDataStorage public heroStorage;
    
    constructor(address wrapperAddr) {  
        wrapper = IWrapper(wrapperAddr);
       
        mergeP.rankThresholds = [1,30,70,170,390,800,1500,2000,2500,2900,6000,10000,15000,20000,25000];
        
        // Set additionalExtrasForRank slots -  mapping(uint256 => uint256)
        mergeP.additionalExtrasForRank[0] = 0;
        mergeP.additionalExtrasForRank[1] = 1;
        mergeP.additionalExtrasForRank[2] = 1;
        mergeP.additionalExtrasForRank[3] = 2;
        mergeP.additionalExtrasForRank[4] = 2;
        mergeP.additionalExtrasForRank[5] = 3;
        mergeP.additionalExtrasForRank[6] = 3;
        mergeP.additionalExtrasForRank[7] = 3;
        mergeP.additionalExtrasForRank[8] = 4;
        mergeP.additionalExtrasForRank[9] = 4;
        mergeP.additionalExtrasForRank[10] = 4;
        mergeP.additionalExtrasForRank[11] = 5;
        mergeP.additionalExtrasForRank[12] = 5;
        mergeP.additionalExtrasForRank[13] = 5;
        mergeP.additionalExtrasForRank[14] = 6;
        
        // extra levels thresholds
        mergeP.traitsLevelsCut[7][0] = [1]; // 0 invisible
        mergeP.traitsLevelsCut[7][1] = [1,4,7,14,27,53,103,201]; // 1 book
        mergeP.traitsLevelsCut[7][2] = [1,5,12,28,64]; // 2 sword
        mergeP.traitsLevelsCut[7][3] = [1,6,16,39,98]; // 3 laurel
        mergeP.traitsLevelsCut[7][4] = [1,4,9,18,36,74,152,312]; // 4 heart
        mergeP.traitsLevelsCut[7][5] = [1,4,7,13,25,47,89,170,323,613]; // 5 skull
        mergeP.traitsLevelsCut[7][6] = [1,4,8,17,35,72,147,300]; // 6 lyre
        mergeP.traitsLevelsCut[7][7] = [1,4,8,15,30,58,115,227,447]; // 7 crystal
        mergeP.traitsLevelsCut[7][8] = [1]; // 8 upOnly
        mergeP.traitsLevelsCut[7][9] = [1]; // 9 69
        mergeP.traitsLevelsCut[7][10] = [1]; // 10 777
        mergeP.traitsLevelsCut[7][11] = [1]; // Lightsaber
        mergeP.traitsLevelsCut[7][12] = [1]; // Gold Book
        mergeP.traitsLevelsCut[7][13] = [1]; // Gold Bow
        mergeP.traitsLevelsCut[7][14] = [1]; // Gold Lyre
        mergeP.traitsLevelsCut[7][15] = [1]; // Gold Scyte
        mergeP.traitsLevelsCut[7][16] = [1]; // Gold Staff
        mergeP.traitsLevelsCut[7][17] = [1]; // Gold Sword
        mergeP.traitsLevelsCut[7][18] = [1]; // Gold Wings
        mergeP.traitsLevelsCut[7][19] = [1]; // 420 special!
            
    
        // runes levels thresholds    
        mergeP.traitsLevelsCut[6][0] = [1]; // 0 invisible
        mergeP.traitsLevelsCut[6][1] = [1,3,6,11,21,39,71,131,242,445]; // 1 fish
        mergeP.traitsLevelsCut[6][2] = [1,3,5,10,17,30,52,92,162,285]; // 2 R
        mergeP.traitsLevelsCut[6][3] = [1,3,6,10,18,33,59,105,189,338]; // 3 I
        mergeP.traitsLevelsCut[6][4] = [1,3,6,12,22,41,77,143,266,496]; // 4 Mother
        mergeP.traitsLevelsCut[6][5] = [1,3,5,9,15,26,45,77,132,227]; // 5 Up Only
        mergeP.traitsLevelsCut[6][6] = [1,3,5,8,14,23,39,67,112,190]; // 6 Burning S
        mergeP.traitsLevelsCut[6][7] = [1]; // 7 Daemon Face
        mergeP.traitsLevelsCut[6][8] = [1]; // 8 Up Only fish
        mergeP.traitsLevelsCut[6][9] = [1,3,4,7,11,18,29,47,77,124]; // 9 roman
        mergeP.traitsLevelsCut[6][10] = [1,2,4,6,10,16,25,39,61,97]; // 10 hieroglyphs
        mergeP.traitsLevelsCut[6][11] = [1]; // Andrea  
        mergeP.traitsLevelsCut[6][12] = [1]; // gm
        mergeP.traitsLevelsCut[6][13] = [1]; // Loom
        mergeP.traitsLevelsCut[6][14] = [1]; // path
        mergeP.traitsLevelsCut[6][15] = [1]; // Abana
    }


    /*///////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS MERGE
    //////////////////////////////////////////////////////////////*/
    
    // set the SoulsLocker and HeroDataStorage modules
    function setupModules(address locker_, address heroStorage_) external onlyOwner {
        locker = SoulsLocker(locker_);
        
        heroStorage = HeroDataStorage(heroStorage_);
    }

    function activateMerge() external onlyOwner  {
        mergeActive = true;
    }

    function activateMergeLABMaster() external {
        require(callerIsLabMaster(), "Not the L.A.B Master");
        mergeActive = true;
    }

    function callerIsLabMaster() public view returns (bool) {
        // gets owner of The L.A.B. from SuperRare contract
        address labMaster = IERC721Metadata(0xb932a70A57673d89f4acfFBE830E8ed7f75Fb9e0).ownerOf(28554);
        return (labMaster == msg.sender);
    }

    // Get and Set Merge parameters functions
    function getRankThresholds() external view returns (uint256[] memory) {
        return mergeP.rankThresholds;
    }

    function setRankThresholds(uint256[] calldata newRanks) external onlyOwner {
        mergeP.rankThresholds = newRanks;
    }

    function getTraitsLevelsCut(uint256 idx1, uint256 idx2) external view returns (uint256[] memory) {
        return mergeP.traitsLevelsCut[idx1][idx2];
    }

    function setTraitsLevelsCut(uint256 idx1, uint256 idx2, uint256[] calldata traitsCuts) external onlyOwner {
        mergeP.traitsLevelsCut[idx1][idx2] = traitsCuts;
    }

    function getAdditionalExtras(uint256 idx1) external view returns (uint256) {
        return mergeP.additionalExtrasForRank[idx1];
    }

    function setAdditionalExtras(uint256 idx1, uint256 additionalSlots) external onlyOwner {
        mergeP.additionalExtrasForRank[idx1] = additionalSlots;
    }
    
    /*///////////////////////////////////////////////////////////////
                        CHECK HERO FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function checkParamsValidity(
        uint256 heroId,
        uint16[] memory tokenId,
        bytes memory params
    )   public view returns (uint256)
    {   
        // merge is not active yet
        if (mergeActive == false) {
            return 0;
        }
        
        //makes sure the params encoding is valid
        if (params.length < 10 || params.length % 2 != 0) { 
            return 0; // not a valid hero
        }

        // block to check for extra duplicates - doing it at the beginning to avoid computing more if this fails
        {
            bytes memory usedExtras = new bytes(7);
                
            usedExtras[0] = params[8]; //first extra

            
            //returns false if additional there is a duplicate extra
            for (uint256 i = 10; i < params.length; i+=2) {
                for (uint256 j = 0; j < (i-8)/2; j++) {
                    if (params[i] == usedExtras[j]) { 
                        return 0; //false
                    }
                }
                usedExtras[(i-8)/2] = params[i];   
            }
        }

        
        uint256 totScore;

        //number of additional extras:
        uint256 addExtraSlots = (params.length - 10)/2;

        uint256[] memory rarityCount = new uint256[](7 + addExtraSlots);

        
        //block to count traits
        {
            // load Allcharacters from on chain contracts in one go
            bytes[4] memory allData = [
                SSTORE2.read(pointers[0]), 
                SSTORE2.read(pointers[1]), 
                SSTORE2.read(pointers[2]), 
                SSTORE2.read(pointers[3])
            ];
            
            //count the heroId first
            uint256 idx = (heroId - 1) % 3000 * 8;
            uint256 ptr = (heroId - 1) / 3000;

            // checks anime vs spirit multiplier
            uint256 multiplier = heroId <= 1573 ? 20 : 1;

            //starts the count with the token associated with heroId
            totScore += uint8(allData[ptr][idx]) * multiplier;

            if (allData[ptr][idx+1] == params[1]) { // skin
                rarityCount[0] += multiplier;
            }
            if (allData[ptr][idx+2] == params[2]) { // clA
                rarityCount[1] += multiplier;
            }
            if (allData[ptr][idx+3] == params[3]) { // clB
                rarityCount[2] += multiplier;
            }
            if (allData[ptr][idx+4] == params[4]) { // bg
                rarityCount[3] += multiplier;
            }
            if (allData[ptr][idx+5] == params[5]) { // halo
                rarityCount[4] += multiplier;
            }
            if (allData[ptr][idx+6] == params[6]) { // runes
                rarityCount[5] += multiplier;
            }
            if (allData[ptr][idx+7] == params[8]) { // extra
                rarityCount[6] += multiplier;
            }
            
            // additional extras
            for (uint256 j = 0;  j < addExtraSlots; j++) {
                    if (allData[ptr][idx+7] == params[j*2 + 10]) {
                        rarityCount[j + 7] += multiplier;
                    }
                    
            }
            
            
            for (uint256 i = 0; i < tokenId.length ; i++){
        
                idx = (tokenId[i] - 1) % 3000 * 8;
                ptr = (tokenId[i] - 1) / 3000;

                multiplier = tokenId[i] <= 1573 ? 20 : 1;

                totScore += uint8(allData[ptr][idx]) * multiplier;

                if (allData[ptr][idx+1] == params[1]) { // skin
                    rarityCount[0] += multiplier;
                }
                if (allData[ptr][idx+2] == params[2]) { // clA
                    rarityCount[1] += multiplier;
                }
                if (allData[ptr][idx+3] == params[3]) { // clB
                    rarityCount[2] += multiplier;
                }
                if (allData[ptr][idx+4] == params[4]) { // bg
                    rarityCount[3] += multiplier;
                }
                if (allData[ptr][idx+5] == params[5]) { // halo
                    rarityCount[4] += multiplier;
                }
                if (allData[ptr][idx+6] == params[6]) { // runes
                    rarityCount[5] += multiplier;
                }
                if (allData[ptr][idx+7] == params[8]) { // extra
                    rarityCount[6] += multiplier;
                }
                
                // additional extras - if any
                for (uint256 j = 0;  j < addExtraSlots; j++) { 
                        if (allData[ptr][idx+7] == params[j*2 + 10]) {
                            rarityCount[j + 7] += multiplier;
                        }     
                }
                    

            }
        }

        //check that rank is valid - not above the MAX rank possible at the time
        if (uint8(params[0]) >= mergeP.rankThresholds.length) {
            return 0; //false
        }

        //check if rarity sum of souls is enough to match the rank of the requested hero
        if (totScore < mergeP.rankThresholds[uint8(params[0])]) {
            return 0; //false
        }

        // block that finds the max rank possible for the current total score
        // need to know to allocate the right nr of extras
        {
            uint8 maxRank = uint8(params[0]);

            for (uint8 i = uint8(params[0]); i < mergeP.rankThresholds.length; i++) {
                if (totScore >= mergeP.rankThresholds[i]) {
                    maxRank = i;
                }
            }
            
            //check that add extra slots are not more than the allowed ones for the rank
            if (addExtraSlots > mergeP.additionalExtrasForRank[maxRank]) {
                return 0;
            }
        }
        

        // block that checks that the level of the extras are allowed
        {
            uint256 levelCut;
            
            //cycle through traits with no leveling up (skin to halo)
            for (uint256 i = 1; i <= 5; i++) { 
                //check that there is at least one occurence of the trait or return 0
                if (rarityCount[i-1] == 0) {
                    return 0;
                }
            }

            //check that runes level is valid - not above the MAX level possible for the specific rune
            if (uint8(params[7]) >= mergeP.traitsLevelsCut[6][uint8(params[6])].length) {
                return 0; //false
            }

            // checks runes (leveling up and not)
            if (mergeP.traitsLevelsCut[6][uint8(params[6])].length > 1) {
                    levelCut = mergeP.traitsLevelsCut[6][uint8(params[6])][uint8(params[7])];
                    
                    //check if you have enough points on this trait
                    if (rarityCount[5] < levelCut) { 
                       return 0;
                    }                  
                    
            }
            else { //this is for unique traits that are not possible to level up 
                //check that the level is 0 and that there is one available
                if (rarityCount[5] == 0 || params[7] > 0) {
                    return 0;
                }
            }


            //cycle through extras with possible leveling up 
            for (uint256 i = 0; i < 1 + addExtraSlots; i++) {
                uint256 slotIdx = 8 + i * 2;

                //check that extra level is valid - not above the MAX level possible for the specific extra
                if (uint8(params[slotIdx + 1]) >= mergeP.traitsLevelsCut[7][uint8(params[slotIdx])].length) {
                    return 0; //false
                }
                
                if (mergeP.traitsLevelsCut[7][uint8(params[slotIdx])].length > 1) {
                    levelCut = mergeP.traitsLevelsCut[7][uint8(params[slotIdx])][uint8(params[slotIdx + 1])];
                    
                    // check if you have enough points on this trait
                    if (rarityCount[i + 6] < levelCut) { 
                       return 0;
                    }                  
                    
                }
                else { //this is for unique traits that are not possible to level up 
                    //check that the level is 0 and that there is one available
                    if (rarityCount[i + 6] == 0 || params[slotIdx + 1] > 0) {
                        return 0;
                    }
                }
                
                
            }
            
        }
        // if all the checks pass you get here and return the totScore
        return totScore;
    }

    function checkHeroValidity(uint256 heroId) external view returns (uint256){
        uint16[] memory soulsLocked = locker.getSoulsInHero(heroId);
       
        heroParams memory currentHero = heroStorage.getData(heroId);
        
        return checkParamsValidity(heroId, soulsLocked, currentHero.params);

    }

    function getHeroScore(uint256 heroId) external view returns (uint256){
        uint256 totScore;
        uint16[] memory tokenId = locker.getSoulsInHero(heroId);

        // block to count score
        {
            // loadAllcharacters in one go
            bytes[4] memory allData = [
                SSTORE2.read(pointers[0]), 
                SSTORE2.read(pointers[1]), 
                SSTORE2.read(pointers[2]), 
                SSTORE2.read(pointers[3])
            ];

            //count the heroId first
            uint256 idx = (heroId - 1) % 3000 * 8;
            uint256 ptr = (heroId - 1) / 3000;

            // checks anime vs spirit multiplier
            uint256 multiplier = heroId <= 1573 ? 20 : 1;

            //starts the count with the token associated with heroId
            totScore += uint8(allData[ptr][idx]) * multiplier;

            // add the score for each token contained
            for (uint256 i = 0; i < tokenId.length ; i++){

                idx = (tokenId[i] - 1) % 3000 * 8;
                ptr = (tokenId[i] - 1) / 3000;

                multiplier = tokenId[i] <= 1573 ? 20 : 1;

                totScore += uint8(allData[ptr][idx]) * multiplier;

            }
        }

        return totScore;
    }

}

///////////////////////
// CUSTOM URI CONTRACT
///////////////////////

interface IMergerURI {
    function checkHeroValidity(uint256 heroId) external view returns (uint256);
}

contract TokenURICustom {
    // Merger Interface
    IMergerURI public merger;

    // Hero Data Storage 
    HeroDataStorage public heroStorage;

    string public baseURI = "https://leanime.art/heroes/metadata/";

    string public heroURI = "https://api.leanime.art/heroes/metadata/";

    constructor(address mergerAddress_, address heroStorage_) {
        merger = IMergerURI(mergerAddress_);
        heroStorage = HeroDataStorage(heroStorage_);
    }

    function constructTokenURI(uint256 tokenId) external view returns (string memory) {
        string memory str = "H";

        uint256 heroId = tokenId - 100000;
        
        // minimal hero parameters
        uint256 score = merger.checkHeroValidity(heroId);
        
        if (score > 0) {
            str = string(abi.encodePacked(Strings.toString(heroId), "S" , Strings.toString(score), str));
            heroParams memory dataHero = heroStorage.getData(heroId);
            
            
            bytes memory params = dataHero.params;

            for (uint256 i = 0; i < params.length; i++){
                str = string(abi.encodePacked(str, itoh8(uint8(params[i]))));
            }
            
            //fixed BG
            str = string(abi.encodePacked(str, "G"));
            str = string(abi.encodePacked(str, itoh8(dataHero.visibleBG)));
            
            
            str = string(abi.encodePacked(heroURI, str));
        }
        else {
            str = string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        }
        return str;
    }
    
    // convert uint8 into hex string
    function itoh8(uint8 x) private pure returns (string memory) {
        if (x > 0) {
            string memory str;
            
            str = string(abi.encodePacked(uint8(x % 16 + (x % 16 < 10 ? 48 : 87)), str));
            x /= 16;
            str = string(abi.encodePacked(uint8(x % 16 + (x % 16 < 10 ? 48 : 87)), str));
            
            return str;
        }
        return "00";
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}