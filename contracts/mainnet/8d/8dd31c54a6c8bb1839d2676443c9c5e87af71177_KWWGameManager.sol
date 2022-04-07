/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: MIT
// File: contracts/IKWWData.sol


pragma solidity ^0.8.4;

interface IKWWData { 
    struct KangarooDetails{
        //Timestamp of the date the kangaroo is born
        uint64 birthTime;
        //Dad token id 
        uint32 dadId;
        //Mom token id
        uint32 momId;
        //Couple token id 
        uint32 coupleId;
        //If the kangaroo is on boat, the boatId will be set here
        uint16 boatId;
        //If the kangaroo moved to another land, the new landId will be set here
	    uint16 landId;
        //The generation of the kangaroo (genesis - gen0) NOT CHANGING
		uint8 gen;
        //Status of the kangaroo in the game
        // 0 - Australian
        // 1 - Sailing
        // 2 - Kangaroo Island
        // 3 - Pregnant
		uint8 status;
        //Type of the kangaroo (Pirate, Native, etc.)
        uint8 bornState;
    }

    struct CoupleDetails{
        //Timestamp when the pregnancy started
        uint64 pregnancyStarted;
        uint8 babiesCounter;
        //false - wild world, true - hospital
        bool paidHospital;
        bool activePregnant;
    }

    function initKangaroo(uint32 tokenId, uint32 dadId, uint32 momId) external;
}
// File: contracts/IKWWGameManager.sol


pragma solidity ^0.8.4;


interface IKWWGameManager{
    enum ContractTypes {KANGAROOS, BOATS, LANDS, VAULT, VAULT_ETH, DATA, MOVING_BOATS, VOTING}

    function getContract(uint8 _type) external view returns(address);
}

interface Vault{
    function depositToVault(address owner, uint256[] memory tokens, uint8 assetsType, bool frozen) external;
    function withdrawFromVault(address owner, uint256[] calldata tokenIds) external ;
    function setAssetFrozen(uint256 token, bool isFrozen) external ;
    function getHolder(uint256 tokenId) external view returns (address);
}

interface VaultEth{
    function depositBoatFees(uint16 totalSupply) external payable;
    function depositLandFees(uint16 landId) external payable;
    function boatAvailableToWithdraw(uint16 totalSupply, uint16 boatId) external view returns(uint256);
    function landAvailableToWithdraw(uint16 landId, uint8 ownerTypeId) external view returns(uint256);
    function withdrawBoatFees(uint16 totalSupply, uint16 boatId, address addr) external;
    function withdrawLandFees(uint16 landId, uint8 ownerTypeId, address addr) external;
}

interface KangarooData{
    function setCouple(uint32 male, uint32 female) external ;
    function kangarooMoveLand(uint32 tokenId, uint16 landId) external;
    function kangarooTookBoat(uint32 tokenId, uint16 boatId) external;
    function kangarooReachedIsland(uint32 tokenId) external ;
    function kangarooStartPregnancy(uint32 dadId, uint32 momId, bool hospital) external ;
    function birthKangaroos(uint32 dadId, uint32 momId, address ownerAddress) external ;
    function getBackAustralian(uint32 dadId, uint32 momId, uint16 boatId) external;
    function kangaroosArrivedContinent(uint32 dadId, uint32 momId) external;
    function getKangaroo(uint32 tokenId) external view returns(IKWWData.KangarooDetails memory);
    function isCouples(uint32 male, uint32 female) external view returns(bool);
    function getCouple(uint32 tokenId) external view returns(uint32);
    function getBabiesCounter(uint32 male, uint32 female) external view returns(uint8);
    function doneMaxBabies(uint32 male, uint32 female) external view returns(bool);
    function kangarooIsMale(uint32 tokenId) external pure returns(bool);
    function updateBoatId(uint32 tokenId, uint16 boatId) external;
    function getKangarooGen(uint32 tokenId) external view returns(uint8);
    function baseMaxBabiesAllowed(uint32 token) external view returns(uint8);
    function getStatus(uint32 tokenId) external view returns(uint8);
    function isBaby(uint32 tokenId) external view returns(bool);
    function getBornState(uint32 tokenId) external view returns(uint8);
    function couplesData(uint64 coupleId) external view returns(IKWWData.CoupleDetails memory);
}

interface MovingBoatsData{
    // function startSail(uint8 boatState, uint8 route, uint32[] calldata kangaroos) external;
    function startSail(uint8 boatState, bool direction) external;
    function getLastId() external view returns(uint256);
    function getKangaroos(uint16 tokenId) external view returns(uint32[] memory);
    function getBoatState(uint16 tokenId) external view returns(uint8);
    function getDirection(uint16 tokenId) external view returns(bool);
    function sailEnd(uint16 tokenId) external view returns(uint64);
}

interface Voting{
    function getBoatPrice(uint16 token) external view returns(uint256);
}

interface LandsData { 
    struct LandDetails{
        //Price of land taxes
        uint256 price;
        //prince token id (kangaroo)
		uint32 princeId;
        //princess token id (kangaroo)
        uint32 princessId;
    }

    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function getLandData(uint16 tokenId) external view returns(LandDetails memory);
    function getPrice(uint16 tokenId) external view returns(uint256);
    function getPrince(uint16 tokenId) external view returns(uint32);
    function getPrincess(uint16 tokenId) external view returns(uint32);
}


interface INFT{
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
}

// interface KangaroosNFT{
//     function totalSupply() external view returns (uint256);
//     function ownerOf(uint256 tokenId) external view returns (address);
// }

// interface BoatsNFT{
//     function totalSupply() external view returns (uint256);
//     function ownerOf(uint256 tokenId) external view returns (address);
// }

// interface LandsNFT{
//     function totalSupply() external view returns (uint256);
//     function ownerOf(uint256 tokenId) external view returns (address);
// }


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

// File: contracts/KWWGameManager.sol


pragma solidity ^0.8.4;




contract KWWGameManager is IKWWGameManager, Ownable{
    event CoupleMovedLand(uint32 indexed _male, uint32 indexed _female, uint16 _landId);
    event CoupleStartedSailing(uint32 indexed _male, uint32 indexed _female, uint16 _boatId);
    event ArrivedIsland(uint32 indexed _male, uint32 indexed _female);
    event PregnancyStarted(uint32 indexed _male, uint32 indexed _female, bool isHospital);
    event BabiesBorn(uint32 indexed _male, uint32 indexed _female);
    event ArrivedContinent(uint32 indexed _male, uint32 indexed _female);
    event SailBackStarted(uint32 indexed _male, uint32 indexed _female, uint16 _boatId);


    mapping(uint8 => address) contracts;

    /*
        GAME
    */

    //Move land
    function coupleMoveLand(uint32 male, uint32 female, uint16 landId) public payable {
        //Check ownership
        require(isOwnerOrStaked(male, ContractTypes.KANGAROOS) && isOwnerOrStaked(female, ContractTypes.KANGAROOS), "Missing permissions - you're not the owner of one of the tokens");
        //check land exists
        require(getLandNFT().ownerOf(landId) != address(0), "Land not Exists");
        //Check if not babies
        require(!getData().isBaby(male) && !getData().isBaby(female), "One of the kangaroos is baby");
        //Check if from same state
        require(getData().getBornState(male) == getData().getBornState(female),"Couple not from the same born state");
        //Check if from same gen
        require(getData().getKangarooGen(male) == getData().getKangarooGen(female),"Couple not from the same generation");
        //Check if genders match - male is really male 
        require(getData().kangarooIsMale(male) == true && getData().kangarooIsMale(female) == false,"Couple genders mismatched");
        //Pay to boat owners
        require(getLandNFT().getPrice(landId) <= msg.value, "Tax fee is too low");
        getVaultEth().depositLandFees{value:msg.value}(landId);
        //Change status of kangaroos
        getData().kangarooMoveLand(male, landId);
        getData().kangarooMoveLand(female, landId);
        //Trigger event "CoupleMovedLand(uint32 male, uint32 female, uint8 landId)"
        emit CoupleMovedLand(male, female, landId);
    }

    //Step 1 - Couple pick boat and start sail
    function coupleStartJourney(uint32 male, uint32 female) public payable {
        //Check ownership
        require(isOwnerOrStaked(male, ContractTypes.KANGAROOS) && isOwnerOrStaked(female, ContractTypes.KANGAROOS), "Missing permissions - you're not the owner of one of the tokens");
        //Check if not babies
        require(!getData().isBaby(male) && !getData().isBaby(female), "One of the kangaroos is baby");
        //Check if from same state
        require(getData().getBornState(male) == getData().getBornState(female),"Couple not from the same born state");
        //Check if from same gen
        require(getData().getKangarooGen(male) == getData().getKangarooGen(female),"Couple not from the same generation");
        //Check if genders match - male is really male 
        require(getData().kangarooIsMale(male) == true && getData().kangarooIsMale(female) == false,"Couple genders mismatched");
        //Check status == 0
        require(getData().getStatus(male) == 0 && getData().getStatus(female) == 0, "Status doesn't fit this step");
        //Is single before starting the journey
        require(getData().getCouple(male) == 0 && getData().getCouple(female) == 0, "Can't change couple");
        //Pay to boat owners
        require(getVoting().getBoatPrice(1) <= msg.value, "Renting fee is too low");
        getVaultEth().depositBoatFees{value:msg.value}(uint16(getBoatNFT().totalSupply()) - 1);
        //Change status of boat - active + update num kangaroos
        uint32[] memory kangaroosArr = new uint32[](2);
        kangaroosArr[0] = male;
        kangaroosArr[1] = female;
        getMovingBoats().startSail(getData().getBornState(male), true);
        uint16 movingBoatId = uint16(getMovingBoats().getLastId());
        //deposit kangaroos vault - with freezing
        depositCouple(male, female, true);
        //SAVE THEM AS A COUPLE - Create couples journey mapping(uint64=>coupleData)
        getData().setCouple(male, female);
        //Change status of kangaroos
        getData().kangarooTookBoat(male, movingBoatId);
        getData().kangarooTookBoat(female, movingBoatId);
        //Trigger event "CoupleStartedSailing(uint32 male, uint32 female, uint8 boatId)"
        emit CoupleStartedSailing(male, female, movingBoatId);
    }

    function pregnancyOnWildWorld(uint32 male, uint32 female) public {
        //Check ownership
        require(isOwnerOrStaked(male, ContractTypes.KANGAROOS) && isOwnerOrStaked(female, ContractTypes.KANGAROOS), "Missing permissions - you're not the owner of one of the tokens");
        //Check status == 1 (on sail)
        require(getData().getStatus(male) == 1 && getData().getStatus(female) == 1, "Status doesn't fit this step");
        //Is Couples
        require(getData().isCouples(male, female), "Not Couples");
        //Check that the time really passed, and they arrived
        uint16 boatId = getData().getKangaroo(male).boatId;
        require(getMovingBoats().sailEnd(boatId) <= block.timestamp, "Still on sail");
        //Check boat route is to island
        require(getMovingBoats().getDirection(boatId) == true, "not in the route to kangaroo island");
        //Change status of kangaroos
        getData().updateBoatId(male, 0);
        getData().updateBoatId(female, 0);
        getData().kangarooStartPregnancy(male, female, false);
        //Trigger event "PregnancyStarted(uint32 male, uint32 female, Wild World)"
        emit PregnancyStarted(male, female, false);
    }

    function pregnancyOnHospital(uint32 male, uint32 female) public payable{
        //Check ownership
        require(isOwnerOrStaked(male, ContractTypes.KANGAROOS) && isOwnerOrStaked(female, ContractTypes.KANGAROOS), "Missing permissions - you're not the owner of one of the tokens");
        //Check status == 1 (on sail)
        require(getData().getStatus(male) == 1 && getData().getStatus(female) == 1, "Status doesn't fit this step");
        //Is Couples
        require(getData().isCouples(male, female), "Not Couples");
        //Check that the time really passed, and they arrived
        uint16 boatId = getData().getKangaroo(male).boatId;
        require(getMovingBoats().sailEnd(boatId) <= block.timestamp, "Still on sail");
        //Check boat route is to island
        require(getMovingBoats().getDirection(boatId) == true, "not in the route to kangaroo island");
        //Check full payment
        require(getHospitalPrice() <= msg.value, "Hospital fee too low");
        //Deposit Land fees to kangaroo island
        getVaultEth().depositLandFees{value:msg.value}(1);
        //Change status of kangaroos
        getData().updateBoatId(male, 0);
        getData().updateBoatId(female, 0);
        getData().kangarooStartPregnancy(male, female, true);
        //Trigger event "PregnancyStarted(uint32 male, uint32 female, Hospital)"
        emit PregnancyStarted(male, female, true);
    }

    function birthBabies(uint32 male, uint32 female) public {
        //Check ownership
        require(isOwnerOrStaked(male, ContractTypes.KANGAROOS) && isOwnerOrStaked(female, ContractTypes.KANGAROOS), "Missing permissions - you're not the owner of one of the tokens");
        //Check status == 3
        require(getData().getStatus(male) == 3 && getData().getStatus(female) == 3, "Status doesn't fit this step");
        //Is Couples
        require(getData().isCouples(male, female), "Not Couples");
        //Change status of kangaroos
        getData().birthKangaroos(male, female, msg.sender);
        //Trigger event "Babies Born(uint32 male, uint32 female)"
        emit BabiesBorn(male, female);
    }

    function coupleSailBack(uint32 male, uint32 female) public {
        //Check ownership
        require(isOwnerOrStaked(male, ContractTypes.KANGAROOS) && isOwnerOrStaked(female, ContractTypes.KANGAROOS), "Missing permissions - you're not the owner of one of the tokens");
        //Is Couples
        require(getData().isCouples(male, female), "Not Couples");
        //Check made maximum babies
        require(getData().doneMaxBabies(male, female), "You need to make maximum amount of babies before you leave");
        //Check status == 2 (on kangaroo island)
        require(getData().getStatus(male) == 2 && getData().getStatus(female) == 2, "Status doesn't fit this step");
        //Get on boat (Return back direction)
        getMovingBoats().startSail(getData().getBornState(male), false);
        uint16 movingBoatId = uint16(getMovingBoats().getLastId());
        //Change status of kangaroos
        getData().getBackAustralian(male, female, movingBoatId);
        //Trigger event "SailBackStarted(uint32 male, uint32 female, uint8 boatId)"
        emit SailBackStarted(male, female, movingBoatId);
    }

    function arrivedToContinent(uint32 male, uint32 female) public {
        //Check ownership
        require(isOwnerOrStaked(male, ContractTypes.KANGAROOS) && isOwnerOrStaked(female, ContractTypes.KANGAROOS), "Missing permissions - you're not the owner of one of the tokens");
        //Check that the time really passed, and they arrived
        uint16 boatId = getData().getKangaroo(male).boatId;
        require(getMovingBoats().sailEnd(boatId) <= block.timestamp, "Still on sail");
        //Check boat route is to island (route == 2)
        require(getMovingBoats().getDirection(boatId) == false, "not on the route to Australian");
        //Check status == 1 (On Boat)
        require(getData().getStatus(male) == 1 && getData().getStatus(female) == 1, "Status doesn't fit this step");
        //Change status of kangaroos
        getData().kangaroosArrivedContinent(male, female);
        //Trigger event "ArrivedContinent(uint32 male, uint32 female)
        emit ArrivedContinent(male, female);
    }

    /*
        HELPERS
    */

    function getCurrentState(uint32 kangarooId) public view returns(uint8){
        IKWWData.KangarooDetails memory data = getData().getKangaroo(kangarooId);
        if(data.landId != 0){
            return uint8(data.landId);
        }
        return data.bornState;
    }

    function getFirstBoatIdFromState(uint8 stateId) public pure returns(uint16){
        return 1+((stateId - 1) * 100);
    }

    function pack(uint32 a, uint32 b) public pure returns(uint64) {
        return (uint64(a) << 32) | uint64(b);
    }

    function boatAvailableToWithdraw(uint16 boatId) public view returns(uint256) {
        return getVaultEth().boatAvailableToWithdraw(uint16(getBoatNFT().totalSupply()), boatId);
    }

    function landAvailableToWithdraw(uint16 landId, uint8 ownerTypeId) public view returns(uint256) {
        return getVaultEth().landAvailableToWithdraw(landId, ownerTypeId);
    }

    function withdrawBoatFees(uint16 boatId) public {
        require(getBoatNFT().ownerOf(boatId) == msg.sender, "caller is not the owner of the boat");
        getVaultEth().withdrawBoatFees(uint16(getBoatNFT().totalSupply()), boatId, getBoatNFT().ownerOf(boatId));
    }
    
    function withdrawLandFees(uint16 landId, uint8 ownerTypeId) public {
        address addr = getLandOwnerAddress(landId, ownerTypeId);
        require(addr != address(0) && addr == msg.sender, "caller is not the owner of the land");
        getVaultEth().withdrawLandFees(landId, ownerTypeId, addr);
    }

    function depositCouple(uint32 dadId, uint32 momId, bool frozen) internal {
        uint256[] memory arr = new uint256[](2);
        arr[0] = uint256(dadId);
        arr[1] = uint256(momId);
        getVault().depositToVault(msg.sender, arr, uint8(ContractTypes.KANGAROOS), frozen);
    }

    /*
        GETTERS
    */

    function getHospitalPrice() view public returns(uint256){
        return getLandNFT().getPrice(1);
    }

    function getContract(uint8 _type) override view public returns(address){
        require(contracts[_type] != address(0),"Contract not exists");
        return contracts[_type];
    }

    function getLandData(uint16 tokenId) public view returns(LandsData.LandDetails memory){
        return getLandNFT().getLandData(tokenId);
    }

    function getLandOwnerAddress(uint16 landId, uint8 ownerType) public view returns(address){
        address addr = address(0);
        LandsData.LandDetails memory landData = getLandData(landId);
        //Prince
        if(ownerType == 0){
            getKangaroosNFT().ownerOf(landData.princeId);
        }
        //Princess
        else if(ownerType == 1){
            getKangaroosNFT().ownerOf(landData.princessId);
        }
        //Landlord
        else if(ownerType == 2){
            getLandNFT().ownerOf(landId);
        }

        return addr;
    }

    function getKangaroosNFT() view public returns(INFT){
        return INFT(getContract(uint8(ContractTypes.KANGAROOS)));
    }

    function getBoatNFT() view public returns(INFT){
        return INFT(getContract(uint8(ContractTypes.BOATS)));
    }
    
    function getLandNFT() view public returns(LandsData){
        return LandsData(getContract(uint8(ContractTypes.LANDS)));
    }
    
    function getVault() view public returns(Vault){
        return Vault(getContract(uint8(ContractTypes.VAULT)));
    }

    function getVaultEth() view public returns(VaultEth){
        return VaultEth(getContract(uint8(ContractTypes.VAULT_ETH)));
    }

    function getData() view public returns(KangarooData){
        return KangarooData(getContract(uint8(ContractTypes.DATA)));
    }

    function getMovingBoats() view public returns(MovingBoatsData){
        return MovingBoatsData(getContract(uint8(ContractTypes.MOVING_BOATS)));
    }

    function getVoting() view public returns(Voting){
        return Voting(getContract(uint8(ContractTypes.VOTING)));
    }


    function isOwnerOrStaked(uint256 tokenId, ContractTypes _type) internal view returns(bool){
        require(contracts[uint8(_type)] != address(0) && contracts[uint8(ContractTypes.VAULT)]  != address(0) , "One of the contract not initialized");

        bool isOwner = INFT(contracts[uint8(_type)]).ownerOf(tokenId) == msg.sender;
        bool isStaked = Vault(contracts[uint8(ContractTypes.VAULT)]).getHolder(tokenId) == msg.sender;
        return isOwner || isStaked;
    }

    /*
        ONLY OWNER
    */
    function addContractType(uint8 typeId, address _addr) public onlyOwner{
        contracts[typeId] = _addr;
    }

    function addMultipleContracts(uint8[] calldata types, address[] calldata addresses) public onlyOwner{
        for (uint256 i = 0; i < types.length; i++) {
            addContractType(types[i], addresses[i]);
        }
    }
}