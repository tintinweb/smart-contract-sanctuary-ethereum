// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/INFT.sol";
import "../interfaces/ITOPIA.sol";
import "../interfaces/IHUB.sol";
import "../interfaces/IRandomizer.sol";

contract PYEMarket is Ownable, ReentrancyGuard, Pausable {

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
        uint80 stakedAt;
    }

    // struct to store a stake's token, owner, and earning values
    struct StakeAlpha {
        uint16 tokenId;
        uint80 value;
        address owner;
        uint80 stakedAt;
    }

    struct Migration {
        uint16 shopOwnerTokenId;
        address shopOwnerOwner;
        uint80 value;
        uint80 migrationTime;
    }

    mapping(uint16 => uint8) public genesisType;

    uint256 private numBakersStaked;
    // number of Foodie staked
    uint256 private numFoodieStaked;
    // number of ShopOwner staked
    uint256 private numShopOwnerStaked;
    // number of Alpha staked
    uint256 private numAlphasStaked;

    uint256 public PERIOD = 1 days;

    event TokenStaked(address indexed owner, uint256 indexed tokenId, uint8 tokenType, uint256 timeStamp);
    event BakerClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event BakerUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event FoodieClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event FoodieUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event ShopOwnerClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event ShopOwnerUnStaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event BoughtPYE(address indexed owner, uint8 boughtPYEType, uint256 rewardInPYE, uint256 timeStamp);
    event AlphaStaked(address indexed owner, uint256 indexed tokenId, uint256 value);
    event AlphaClaimed(uint256 indexed tokenId, bool indexed unstaked, uint256 earned);
    event AlphaUnstaked(address indexed owner, uint256 indexed tokenId, uint256 blockNum, uint256 timeStamp);
    event ShopOwnerMigrated(address indexed owner, uint16 id, bool returning);
    event GenesisStolen (uint16 indexed tokenId, address victim, address thief, uint8 nftType, uint256 timeStamp);

    // reference to the NFT contract
    INFT public lfGenesis;

    INFT public lfAlpha;

    IHUB public HUB;

    mapping(uint16 => Migration) public WastelandShopOwners; // for vets sent to wastelands
    mapping(uint16 => bool) public IsInWastelands; // if vet token ID is in the wastelands

    // reference to Randomizer
    IRandomizer public randomizer;
    address payable vrf;
    address payable dev;

    // maps Baker tokenId to stake
    mapping(uint256 => Stake) private baker;

    // maps Alpha tokenId to stakeAlpha
    mapping(uint256 => StakeAlpha) private alpha;

    // maps Foodie tokenId to stake
    mapping(uint256 => Stake) private foodie;
    // maps ShopOwner tokenId to stake
    mapping(uint256 => Stake) private shopOwner;

    mapping(uint16 => bool) public IsInUnion;

    mapping(address => bool) public HasUnion;

    // any rewards distributed when no Foodies are staked
    uint256 private unaccountedFoodieRewards;
    // amount of $TOPIA due for each foodie staked
    uint256 private TOPIAPerFoodie;
    // any rewards distributed when no ShopOwners are staked
    uint256 private unaccountedShopOwnerRewards;
    // amount of $TOPIA due for each ShopOwner staked
    uint256 private TOPIAPerShopOwner;

    // for staked tier 3 nfts
    uint256 public WASTELAND_BONUS = 100 * 10**18;

    // Bakers earn 20 $TOPIA per day
    uint256 public DAILY_BAKER_RATE = 5 * 10**18;

    // Bakers earn 35 $TOPIA per day
    uint256 public DAILY_ALPHA_RATE = 10 * 10**18;

    // rolling price
    uint256 public PYE_COST = 40 * 10**18;

    // ShopOwners take a 6.66% tax on all $TOPIA claimed
    uint256 public FOODIE_TAX_RATE = 666;

    // ShopOwners take a 3.33% tax on all $TOPIA from upgrades
    uint256 public SHOP_OWNER_TAX_RATE = 333;

    mapping(uint8 => uint256) public pyeFilling;

    // tx cost for getting random numbers
    uint256 public SEED_COST = .0005 ether;

    // tx cost
    uint256 public DEV_FEE = .0018 ether;

    // amount of $TOPIA earned so far
    uint256 public totalTOPIAEarned;
    // the last time $TOPIA was claimed
    uint80 public claimEndTime = 1669662000;

    uint8 public minimumForUnion;

    mapping(address => uint16) public GroupLength;

    /**
     */
    constructor(uint8 _minimumForUnion) {
        dev = payable(msg.sender);
        minimumForUnion = _minimumForUnion;
        pyeFilling[1] = 0;
        pyeFilling[2] = 20 ether;
        pyeFilling[3] = 80 ether;
        pyeFilling[4] = 200 ether;
    }

    /** CRITICAL TO SETUP */

    modifier requireContractsSet() {
        require(address(lfGenesis) != address(0) && address(randomizer) != address(0) && address(HUB) != address(0), "Contracts not set");
        _;
    }

    function setContracts(address _lfGenesis, address _lfAlpha, address _HUB, address payable _rand) external onlyOwner {
        lfGenesis = INFT(_lfGenesis);
        lfAlpha = INFT(_lfAlpha);
        randomizer = IRandomizer(_rand);
        HUB = IHUB(_HUB);
        vrf = _rand;
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    function setMinimumForUnion(uint8 _min) external onlyOwner {
        minimumForUnion = _min;
    }

    // mass update the nftType mapping
    function setBatchNFTType(uint16[] calldata tokenIds, uint8[] calldata _types) external onlyOwner {
        require(tokenIds.length == _types.length , " _idNumbers.length != _types.length: Each token ID must have exactly 1 corresponding type!");
        for (uint16 i = 0; i < tokenIds.length;) {
            require(_types[i] != 0 , "Invalid nft type - cannot be 0");
            genesisType[tokenIds[i]] = _types[i];
            unchecked{ i++; }
        }
    }

    function setWastelandsBonus(uint256 _bonus) external onlyOwner {
        WASTELAND_BONUS = _bonus;
    }

    /** STAKING */

    /**
     * adds Foodies and Baker
     * @param account the address of the staker
   * @param tokenIds the IDs of the Foodies and Baker to stake
   */
    function addManyToStakingPool(address account, uint16[] calldata tokenIds) external payable nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(account == tx.origin, "account to send mismatch");
        require(msg.value == DEV_FEE);
        uint8[] memory tokenTypes = new uint8[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length;) {
            require(lfGenesis.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");

            if (genesisType[tokenIds[i]] == 1) {
                tokenTypes[i] = 7;
                _addBakerToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 2) {
                tokenTypes[i] = 8;
                _addFoodieToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 3) {
                tokenTypes[i] = 9;
                _addShopOwnerToStakingPool(account, tokenIds[i]);
            } else if (genesisType[tokenIds[i]] == 0) {
                revert('invalid token id');
            }
            unchecked{ i++; }
        }
        HUB.receieveManyGenesis(msg.sender, tokenIds, tokenTypes, 4);
    }

    /**
     * adds a single Foodie to the Pool
     * @param account the address of the staker
   * @param tokenId the ID of the Foodie/ShopOwner to add to the Staking Pool
   */
    function _addFoodieToStakingPool(address account, uint16 tokenId) internal whenNotPaused {
        foodie[tokenId] = Stake({
        owner : account,
        tokenId : tokenId,
        value : uint80(TOPIAPerFoodie),
        stakedAt : uint80(block.timestamp)
        });
        numFoodieStaked += 1;
        emit TokenStaked(account, tokenId, 2, block.timestamp);
    }


    /**
     * adds a single ShopOwner to the Pool
     * @param account the address of the staker
   * @param tokenId the ID of the Foodie/ShopOwner to add to the Staking Pool
   */
    function _addShopOwnerToStakingPool(address account, uint16 tokenId) internal whenNotPaused {
        shopOwner[tokenId] = Stake({
        owner : account,
        tokenId : tokenId,
        value : uint80(TOPIAPerShopOwner),
        stakedAt : uint80(block.timestamp)
        });
        numShopOwnerStaked += 1;
        emit TokenStaked(account, tokenId, 3, block.timestamp);
    }


    /**
     * adds a single Baker to the Pool
     * @param account the address of the staker
   * @param tokenId the ID of the Baker to add to the Staking Pool
   */
    function _addBakerToStakingPool(address account, uint16 tokenId) internal {
        baker[tokenId] = Stake({
        owner : account,
        tokenId : tokenId,
        value : uint80(block.timestamp),
        stakedAt : uint80(block.timestamp)
        });
        // Add the baker to the Pool
        numBakersStaked += 1;
        emit TokenStaked(account, tokenId, 1, block.timestamp);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $TOPIA earnings and optionally unstake tokens from the Pool
     * to unstake a Baker it will require it has 2 days worth of $TOPIA unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
    function claimManyGenesis(uint16[] calldata tokenIds, uint8 _type, bool unstake) external payable whenNotPaused nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        uint256 numWords;
        uint256[] memory seed;
        if((_type == 1 || _type == 2) && unstake) {
            numWords = tokenIds.length;
            require(msg.value == DEV_FEE + (SEED_COST * numWords), "need more eth");
            uint256 remainingWords = randomizer.getRemainingWords();
            require(remainingWords >= numWords, "try again soon.");
            seed = randomizer.getRandomWords(numWords);
        } else {
            require(msg.value == DEV_FEE, "need more eth");
        }

        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length;) {
            require(!IsInUnion[tokenIds[i]]);
            if (genesisType[tokenIds[i]] == 1) {
                require(_type == 1, 'wrong type for call');
                owed += _claimBakerFromPool(tokenIds[i], unstake, unstake ? seed[i] : 0);
            } else if (genesisType[tokenIds[i]] == 2) {
                require(_type == 2, 'wrong type for call');
                owed += _claimFoodieFromPool(tokenIds[i], unstake, unstake ? seed[i] : 0);
            } else if (genesisType[tokenIds[i]] == 3) {
                require(_type == 3, 'wrong type for call');
                owed += _claimShopOwnerFromPool(tokenIds[i], unstake);
            } else if (genesisType[tokenIds[i]] == 0) {
                revert('invalid token id');
            }
            unchecked{ i++; }
        }
        uint256 vrfAmount = msg.value - DEV_FEE;
        if(vrfAmount > 0) { vrf.transfer(vrfAmount); }
        dev.transfer(DEV_FEE);

        if (owed == 0) {
            return;
        }
        totalTOPIAEarned += owed;
        HUB.pay(msg.sender, owed);
        
    }

    function getTXCost(uint16[] calldata tokenIds, uint8 _type, bool unstake) external view returns (uint256 txCost) {
        if((_type == 1 || _type == 2) && unstake) {
            txCost = DEV_FEE + (SEED_COST * tokenIds.length);
        } else {
            txCost = DEV_FEE;
        }
    }


    /**
     * realize $TOPIA earnings for a single Baker and optionally unstake it
     * if not unstaking, lose x% chance * y% percent of accumulated $TOPIA to the staked Foodies based on it's upgrade
     * if unstaking, there is a % chanc of losing Baker NFT
     * @param tokenId the ID of the Baker to claim earnings from
   * @param unstake whether or not to unstake the Baker
   * @return owed - the amount of $TOPIA earned
   */
    function _claimBakerFromPool(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed) {       
        require(baker[tokenId].owner == msg.sender, "Don't own the given token");
        if(block.timestamp <= claimEndTime) {
            owed = (block.timestamp - baker[tokenId].value) * DAILY_BAKER_RATE / PERIOD;
        } else if (baker[tokenId].value < claimEndTime) {
            owed = (claimEndTime - baker[tokenId].value) * DAILY_BAKER_RATE / PERIOD;
        } else {
            owed = 0;
        }

        uint256 shopOwnerTax = owed * SHOP_OWNER_TAX_RATE / 10000;
        _payShopOwnerTax(shopOwnerTax);
        uint256 foodieTax = owed * FOODIE_TAX_RATE / 10000;
        _payFoodieTax(foodieTax);
        owed = owed - shopOwnerTax - foodieTax;

        bool stolen = false;
        address thief;
        if (unstake) {
            if ((seed & 0xFFFF) % 100 < 10 && HUB.alphaCount(4) > 0) {
                HUB.stealGenesis(tokenId, seed, 4, 7, msg.sender);
                stolen = true;
            }
            delete baker[tokenId];
            numBakersStaked -= 1;

            if (stolen) {
                emit GenesisStolen (tokenId, msg.sender, thief, 1, block.timestamp);
            } else {
                // Always transfer last to guard against reentrance
                HUB.returnGenesisToOwner(msg.sender, tokenId, 7, 4);
            }
            emit BakerUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {// Claiming
            baker[tokenId].value = uint80(block.timestamp);
            // reset stake
        }
        emit BakerClaimed(tokenId, unstake, owed);
    }

    /**
     * realize $TOPIA earnings for a single Foodie and optionally unstake it
     * Foodies earn $TOPIA
     * @param tokenId the ID of the Foodie to claim earnings from
   * @param unstake whether or not to unstake the Foodie
   */
    function _claimFoodieFromPool(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed) {
        require(foodie[tokenId].owner == msg.sender, "Doesn't own given token");
        owed = TOPIAPerFoodie - foodie[tokenId].value;

        bool stolen = false;
        address thief;
        if (unstake) {
            if ((seed & 0xFFFF) % 100 < 10 && HUB.shopOwnerCount() > 0) {
                HUB.stealGenesis(tokenId, seed, 4, 8, msg.sender);
                stolen = true;
            }
            delete foodie[tokenId];
            numFoodieStaked -= 1;
            // reset baker to unarmed
            if (stolen) {
                emit GenesisStolen (tokenId, msg.sender, thief, 2, block.timestamp);
            } else {
                // Always transfer last to guard against reentrance
                HUB.returnGenesisToOwner(msg.sender, tokenId, 8, 4);
            }
            emit FoodieUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {
            foodie[tokenId].value = uint80(TOPIAPerFoodie);
            // reset stake
        }
        emit FoodieClaimed(tokenId, unstake, owed);
    }

    /**
     * realize $TOPIA earnings for a ShopOwner Foodie and optionally unstake it
     * Foodies earn $TOPIA
     * @param tokenId the ID of the Foodie to claim earnings from
   * @param unstake whether or not to unstake the ShopOwner Foodie
   */
    function _claimShopOwnerFromPool(uint16 tokenId, bool unstake) internal returns (uint256 owed) {
        require(shopOwner[tokenId].owner == msg.sender, "Doesn't own given token");
        owed = TOPIAPerShopOwner - shopOwner[tokenId].value;
        if (unstake) {
            delete shopOwner[tokenId];
            numShopOwnerStaked -= 1;
            // Always remove last to guard against reentrance
            HUB.returnGenesisToOwner(msg.sender, tokenId, 9, 4);
            // Send back ShopOwner
            emit ShopOwnerUnStaked(msg.sender, tokenId, block.number, block.timestamp);
        } else {
            shopOwner[tokenId].value = uint80(TOPIAPerShopOwner);
            // reset stake

        }
        emit ShopOwnerClaimed(tokenId, unstake, owed);
    }

    /*
  * implement foodie buy pye
  */
  function buyPYE() external payable whenNotPaused nonReentrant returns(uint8) {
    require(tx.origin == msg.sender, "Only EOA");         
    require(msg.value == SEED_COST + DEV_FEE, "Invalid value for randomness");

    HUB.burnFrom(msg.sender, PYE_COST);
    uint256 remainingWords = randomizer.getRemainingWords();
    require(remainingWords >= 1, "Not enough random numbers. Please try again soon.");
    uint256[] memory seed = randomizer.getRandomWords(1);
    uint8 boughtPYE;

    /*
    * Odds of PYE:
    * Dud: 70%
    * Filled PYE: 25%
    * Golden Ticket PYE: 5%
    */
    if ((seed[0] & 0xFFFF) % 100 < 5) {
      boughtPYE = 4;
    } else if((seed[0] & 0xFFFF) % 100 < 25) {
      boughtPYE = 3;
    } else if((seed[0] & 0xFFFF) % 100 < 75) {
      boughtPYE = 2;
    } else {
      boughtPYE = 1;
    }

    if(pyeFilling[boughtPYE] > 0) { 
        HUB.pay(msg.sender, pyeFilling[boughtPYE]); 
    }
    uint256 vrfAmount = msg.value - DEV_FEE;
    if(vrfAmount > 0) { vrf.transfer(vrfAmount); }
    dev.transfer(DEV_FEE);

    emit BoughtPYE(msg.sender, boughtPYE, pyeFilling[boughtPYE], block.timestamp);
    return boughtPYE;
  }

    /** ACCOUNTING */

    /**
     * add $TOPIA to claimable pot for the Foodie Pool
     * @param amount $TOPIA to add to the pot
   */
    function _payFoodieTax(uint256 amount) internal {
        if (numFoodieStaked == 0) {// if there's no staked Foodies
            unaccountedFoodieRewards += amount;
            // keep track of $TOPIA due to Foodies
            return;
        }
        // makes sure to include any unaccounted $GP
        TOPIAPerFoodie += (amount + unaccountedFoodieRewards) / numFoodieStaked;
        unaccountedFoodieRewards = 0;
    }

    /**
     * add $TOPIA to claimable pot for the ShopOwner Pool
     * @param amount $TOPIA to add to the pot
   */
    function _payShopOwnerTax(uint256 amount) internal {
        if (numShopOwnerStaked == 0) {// if there's no staked shopOwners
            unaccountedShopOwnerRewards += amount;
            // keep track of $TOPIA due to shopOwners
            return;
        }
        // makes sure to include any unaccounted $GP
        TOPIAPerShopOwner += (amount + unaccountedShopOwnerRewards) / numShopOwnerStaked;
        unaccountedShopOwnerRewards = 0;
    }

    /** ALPHA FUNCTIONS */

    /**
     * adds Foodies and Baker
     * @param account the address of the staker
   * @param tokenIds the IDs of the Foodies and Baker to stake
   */
    function addManyAlphaToStakingPool(address account, uint16[] calldata tokenIds) external payable nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(account == tx.origin, "account to send mismatch");
        require(msg.value == DEV_FEE, "need more eth");
        for (uint i = 0; i < tokenIds.length;) {
            require(lfAlpha.ownerOf(tokenIds[i]) == msg.sender, "You don't own this token");
            HUB.receiveAlpha(msg.sender, tokenIds[i], 4);

            alpha[tokenIds[i]] = StakeAlpha({
            owner : account,
            tokenId : uint16(tokenIds[i]),
            value : uint80(block.timestamp),
            stakedAt : uint80(block.timestamp)
            });

            numAlphasStaked += 1;
            emit AlphaStaked(account, tokenIds[i], block.timestamp);
            unchecked{ i++; }
        }
        dev.transfer(DEV_FEE);
    }

    /**
     * realize $TOPIA earnings and optionally unstake Alpha tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
    function claimManyAlphas(uint16[] calldata tokenIds, bool unstake) external payable whenNotPaused nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(msg.value == DEV_FEE, "need more eth");
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length;) { 
            require(alpha[tokenIds[i]].owner == msg.sender, "Don't own the given token");
            
            if(block.timestamp <= claimEndTime) {
                owed += (block.timestamp - alpha[tokenIds[i]].value) * DAILY_ALPHA_RATE / PERIOD;
            } else if (alpha[tokenIds[i]].value < claimEndTime) {
                owed += (claimEndTime - alpha[tokenIds[i]].value) * DAILY_ALPHA_RATE / PERIOD;
            } else {
                owed += 0;
            }

            if (unstake) {
                delete alpha[tokenIds[i]];
                numAlphasStaked -= 1;

                HUB.returnAlphaToOwner(msg.sender, tokenIds[i], 4);
                emit AlphaUnstaked(msg.sender, tokenIds[i], block.number, block.timestamp);
            } else {
                alpha[tokenIds[i]].value = uint80(block.timestamp);
            }
            emit AlphaClaimed(tokenIds[i], unstake, owed);
            unchecked{ i++; }
        }
        dev.transfer(DEV_FEE);
        if (owed == 0) {
            return;
        }
        HUB.pay(msg.sender, owed);
        totalTOPIAEarned += owed;
        
    }

    function isOwner(uint16 tokenId, address owner) external view returns (bool validOwner) {
        if (genesisType[tokenId] == 1) {
            return baker[tokenId].owner == owner;
        } else if (genesisType[tokenId] == 2) {
            return foodie[tokenId].owner == owner;
        } else if (genesisType[tokenId] == 3) {
            return shopOwner[tokenId].owner == owner;
        }
    }

    /**
     * enables owner to pause / unpause contract
     */
    function setPaused(bool _paused) external requireContractsSet onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /** READ ONLY */

    function getUnclaimedAlpha(uint16 tokenId) external view returns (uint256) {
        if(alpha[tokenId].value > 0) {
            if(block.timestamp <= claimEndTime) {
                return (block.timestamp - alpha[tokenId].value) * DAILY_ALPHA_RATE / PERIOD;
            } else if (alpha[tokenId].value < claimEndTime) {
                return (claimEndTime - alpha[tokenId].value) * DAILY_ALPHA_RATE / PERIOD;
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }

    function getUnclaimedGenesis(uint16 tokenId) external view returns (uint256 owed) {
        owed = 0;
        if (genesisType[tokenId] == 1 && baker[tokenId].value > 0) {
            if(block.timestamp <= claimEndTime) {
                return (block.timestamp - baker[tokenId].value) * DAILY_BAKER_RATE / PERIOD;
            } else if (baker[tokenId].value < claimEndTime) {
                return (claimEndTime - baker[tokenId].value) * DAILY_BAKER_RATE / PERIOD;
            } else {
                return 0;
            }
        } else if (genesisType[tokenId] == 2 && foodie[tokenId].owner != address(0)) {
            return TOPIAPerFoodie - foodie[tokenId].value;
        } else if (genesisType[tokenId] == 3) {
            if(IsInWastelands[tokenId]) {
                return WastelandShopOwners[tokenId].value;
            } else if(shopOwner[tokenId].owner != address(0)) {
                return TOPIAPerShopOwner - shopOwner[tokenId].value;
            }
        }
        return owed;
    }

    function updateDailyBakerRate(uint256 _rate) external onlyOwner {
        DAILY_BAKER_RATE = _rate;
    }

    function updateDailyAlphaRate(uint256 _rate) external onlyOwner {
        DAILY_ALPHA_RATE = _rate;
    }
    
    function updateTaxRates(uint16 _foodieRate, uint16 _vetRate) external onlyOwner {
        FOODIE_TAX_RATE = _foodieRate;
        SHOP_OWNER_TAX_RATE = _vetRate;
    }

    function updatePYEFillings(uint256 dudPYE, uint256 filledPYE, uint256 goldenTicketPYE, uint256 pumpkinPYE) external onlyOwner {
        pyeFilling[1] = dudPYE;
        pyeFilling[2] = filledPYE;
        pyeFilling[3] = goldenTicketPYE;
        pyeFilling[4] = pumpkinPYE;
    }
    
    function updatePYECost(uint256 _cost) external onlyOwner {
        PYE_COST = _cost;
    }

    function updateSeedCost(uint256 _cost) external onlyOwner {
        SEED_COST = _cost;
    }

    function updateDevCost(uint256 _cost) external onlyOwner {
        DEV_FEE = _cost;
    }

    function updateDev(address payable _dev) external onlyOwner {
        dev = _dev;
    }

    function closeSeasonEearnings(uint80 _timestamp) external onlyOwner {
        claimEndTime = _timestamp;
    }

    function createUnion(uint16[] calldata _tokenIds) external payable nonReentrant notContract() {
        require(!HasUnion[msg.sender] , "You already have a union");
        require(msg.value == DEV_FEE, "need more eth");
        uint16 length = uint16(_tokenIds.length);
        require(length >= minimumForUnion , "Not enough bakers to form a union");
        for (uint16 i = 0; i < length;) {
            require(lfGenesis.ownerOf(_tokenIds[i]) == msg.sender , "not owner");
            require(genesisType[_tokenIds[i]] == 1 , "only bakers can form a union");
            require(!IsInUnion[_tokenIds[i]], "NFT can only be in 1 union");
            baker[_tokenIds[i]] = Stake({
                owner : msg.sender,
                tokenId : _tokenIds[i],
                value : uint80(block.timestamp),
                stakedAt : uint80(block.timestamp)
            });
     
            emit TokenStaked(msg.sender, _tokenIds[i], 1, block.timestamp);
            IsInUnion[_tokenIds[i]] = true;
            unchecked{ i++; }
        }
        GroupLength[msg.sender]+= length;
        numBakersStaked += length;
        HUB.createGroup(_tokenIds, msg.sender, 4);
        HasUnion[msg.sender] = true;
        dev.transfer(DEV_FEE);
    }

    function addToUnion(uint16 _id) external payable nonReentrant notContract() {
        require(HasUnion[msg.sender], "Must have Union!");
        require(msg.value == DEV_FEE, "need more eth");
        require(lfGenesis.ownerOf(_id) == msg.sender, "not owner");
        require(genesisType[_id] == 1 , "must be baker");
        require(!IsInUnion[_id], "NFT can only be in 1 union");
        baker[_id] = Stake({
            owner : msg.sender,
            tokenId : _id,
            value : uint80(block.timestamp),
            stakedAt : uint80(block.timestamp)
            });
     
        emit TokenStaked(msg.sender, _id, 1, block.timestamp);
        GroupLength[msg.sender]++;
        IsInUnion[_id] = true;
        numBakersStaked++;
        HUB.addToGroup(_id, msg.sender, 4);
        dev.transfer(DEV_FEE);
    }

    function claimUnion(uint16[] calldata tokenIds, bool unstake) external payable notContract() {
        require(HasUnion[msg.sender] , "Must own Union");
        uint256 numWords = tokenIds.length;
        uint256[] memory seed;
        uint8 theftModifier;
        
        if(unstake) { 
            if (numWords <= 10) {
                theftModifier = uint8(numWords);
            } else {theftModifier = 10;}
            require(GroupLength[msg.sender] == numWords);
            require(msg.value == DEV_FEE + (SEED_COST * numWords), "need more eth");
            uint256 remainingWords = randomizer.getRemainingWords();
            require(remainingWords >= numWords, "Not enough random numbers try again soon.");
            seed = randomizer.getRandomWords(numWords);
        } else {
            require(msg.value == DEV_FEE, "need more eth");
        }
        
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length;) {
            require(genesisType[tokenIds[i]] == 1 , "Must be bakers");
            require(IsInUnion[tokenIds[i]] , "NFT must be in Union");
            require(baker[tokenIds[i]].owner == msg.sender, "!= owner");
            uint256 thisOwed;
   
            if(block.timestamp <= claimEndTime) {
                thisOwed = (block.timestamp - baker[tokenIds[i]].value) * DAILY_BAKER_RATE / PERIOD;
            } else if (baker[tokenIds[i]].value < claimEndTime) {
                thisOwed = (claimEndTime - baker[tokenIds[i]].value) * DAILY_BAKER_RATE / PERIOD;
            } else {
                thisOwed = 0;
            }

            if (unstake) {
                if ((seed[i] & 0xFFFF) % 100 < (10 - theftModifier) && HUB.alphaCount(4) > 0) {
                    address thief = HUB.stealGenesis(tokenIds[i], seed[i], 4, 7, msg.sender);
                    emit GenesisStolen (tokenIds[i], msg.sender, thief, 1, block.timestamp);
                } else {
                    HUB.returnGenesisToOwner(msg.sender, tokenIds[i], 7, 4);
                }
                delete baker[tokenIds[i]];
                IsInUnion[tokenIds[i]] = false;
                emit BakerUnStaked(msg.sender, tokenIds[i], block.number, block.timestamp);

            } else {// Claiming
                baker[tokenIds[i]].value = uint80(block.timestamp);
                // reset stake
            }
            emit BakerClaimed(tokenIds[i], unstake, owed);
            owed += thisOwed;
            unchecked{ i++; }
        }
        if (unstake) {
            HasUnion[msg.sender] = false;
            numBakersStaked -= numWords;
            HUB.unstakeGroup(msg.sender, 4);
            GroupLength[msg.sender] = 0;
        }

        uint256 shopOwnerTax = owed * SHOP_OWNER_TAX_RATE / 10000;
        _payShopOwnerTax(shopOwnerTax);
        uint256 foodieTax = owed * FOODIE_TAX_RATE / 10000;
        _payFoodieTax(foodieTax);
        owed = owed - shopOwnerTax - foodieTax;
        
        uint256 vrfAmount = msg.value - DEV_FEE;
        if (vrfAmount > 0) { vrf.transfer(vrfAmount); }
        dev.transfer(DEV_FEE);

        if (owed == 0) { return; }
        
        totalTOPIAEarned += owed;
        HUB.pay(msg.sender, owed);
    }

    function sendShopOwnerToWastelands(uint16[] calldata _ids) external payable notContract() {
        uint256 numWords = _ids.length;
        require(msg.value == DEV_FEE + (SEED_COST * numWords), "need more eth");
        require(randomizer.getRemainingWords() >= numWords, "Not enough random numbers; try again soon.");
        uint256[] memory seed = randomizer.getRandomWords(numWords);

        for (uint16 i = 0; i < numWords;) {
            require(lfGenesis.ownerOf(_ids[i]) == msg.sender, "not owner");
            require(genesisType[_ids[i]] == 3, "not a ShopOwner");
            require(!IsInWastelands[_ids[i]] , "NFT already in wastelands");

            if (HUB.alienCount() > 0 && (seed[i]) % 100 < 25) { // stolen
                address thief = HUB.stealMigratingGenesis(_ids[i], seed[i], 4, msg.sender, false);
                emit GenesisStolen (_ids[i], msg.sender, thief, 3, block.timestamp);
            } else {
                HUB.migrate(_ids[i], msg.sender, 4, false);
                WastelandShopOwners[_ids[i]].shopOwnerTokenId = _ids[i];
                WastelandShopOwners[_ids[i]].shopOwnerOwner = msg.sender;
                WastelandShopOwners[_ids[i]].value = uint80(WASTELAND_BONUS);
                WastelandShopOwners[_ids[i]].migrationTime = uint80(block.timestamp);
                IsInWastelands[_ids[i]] = true;
                emit ShopOwnerMigrated(msg.sender, _ids[i], false);
            }
            unchecked { i++; }
        }
        uint256 vrfAmount = msg.value - DEV_FEE;
        if (vrfAmount > 0) { vrf.transfer(vrfAmount); }
        dev.transfer(DEV_FEE);
    }

    function claimManyWastelands(uint16[] calldata _ids, bool unstake) external payable notContract() {
        uint256 numWords = _ids.length;
        uint256[] memory seed;

        if(unstake) { 
            require(msg.value == DEV_FEE + (SEED_COST * numWords), "need more eth");
            require(randomizer.getRemainingWords() >= numWords, "Not enough random numbers try again soon.");
            seed = randomizer.getRandomWords(numWords);
        } else {
            require(msg.value == DEV_FEE, "need more eth");
        }
        
        uint256 owed = 0;

        for (uint16 i = 0; i < numWords;) {
            require(IsInWastelands[_ids[i]] , "NFT not in wastelands");
            require(msg.sender == WastelandShopOwners[_ids[i]].shopOwnerOwner , "not owner");
            
            owed += WastelandShopOwners[_ids[i]].value;

            if (unstake) {
                if (HUB.alienCount() > 0 && (seed[i]) % 100 < 25) { // stolen
                    address thief = HUB.stealMigratingGenesis(_ids[i], seed[i], 4, msg.sender, true);
                    emit GenesisStolen (_ids[i], msg.sender, thief, 3, block.timestamp);
                } else {
                    HUB.migrate(_ids[i], msg.sender, 4, true);
                    emit ShopOwnerMigrated(msg.sender, _ids[i], true);
                }
                IsInWastelands[_ids[i]] = false;
                delete WastelandShopOwners[_ids[i]];
            } else {
                WastelandShopOwners[_ids[i]].value = uint80(block.timestamp); // reset value
            }
            emit ShopOwnerClaimed(_ids[i], unstake, owed);
            unchecked { i++; }
        }
        uint256 vrfAmount = msg.value - DEV_FEE;
        if (vrfAmount > 0) { vrf.transfer(vrfAmount); }
        dev.transfer(DEV_FEE);
        
        if (owed == 0) { return; }
        totalTOPIAEarned += owed;
        HUB.pay(msg.sender, owed);
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    function requestRandomWords() external returns (uint256);
    function requestManyRandomWords(uint256 numWords) external returns (uint256);
    function getRandomWords(uint256 number) external returns (uint256[] memory);
    function getRemainingWords() external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IHUB {
    function balanceOf(address owner) external view returns (uint256);
    function pay(address _to, uint256 _amount) external;
    function burnFrom(address _to, uint256 _amount) external;
    // *** STEAL
    function stealGenesis(uint16 _id, uint256 seed, uint8 _gameId, uint8 identifier, address _victim) external returns (address thief);
    function stealMigratingGenesis(uint16 _id, uint256 seed, uint8 _gameId, address _victim, bool returningFromWastelands) external returns (address thief);
    function migrate(uint16 _id, address _originalOwner, uint8 _gameId,  bool returningFromWastelands) external;
    // *** RETURN AND RECEIVE
    function returnGenesisToOwner(address _returnee, uint16 _id, uint8 identifier, uint8 _gameIdentifier) external;
    function receieveManyGenesis(address _originalOwner, uint16[] memory _ids, uint8[] memory identifiers, uint8 _gameIdentifier) external;
    function returnAlphaToOwner(address _returnee, uint16 _id, uint8 _gameIdentifier) external;
    function receiveAlpha(address _originalOwner, uint16 _id, uint8 _gameIdentifier) external;
    function returnRatToOwner(address _returnee, uint16 _id) external;
    function receiveRat(address _originalOwner, uint16 _id) external;
    // *** BULLRUN
    function getRunnerOwner(uint16 _id) external view returns (address);
    function getMatadorOwner(uint16 _id) external view returns (address);
    function getBullOwner(uint16 _id) external view returns (address);
    function bullCount() external view returns (uint16);
    function matadorCount() external view returns (uint16);
    function runnerCount() external view returns (uint16);
    // *** MOONFORCE
    function getCadetOwner(uint16 _id) external view returns (address); 
    function getAlienOwner(uint16 _id) external view returns (address);
    function getGeneralOwner(uint16 _id) external view returns (address);
    function cadetCount() external view returns (uint16); 
    function alienCount() external view returns (uint16); 
    function generalCount() external view returns (uint16);
    // *** DOGE WORLD
    function getCatOwner(uint16 _id) external view returns (address);
    function getDogOwner(uint16 _id) external view returns (address);
    function getVetOwner(uint16 _id) external view returns (address);
    function catCount() external view returns (uint16);
    function dogCount() external view returns (uint16);
    function vetCount() external view returns (uint16);
    // *** PYE MARKET
    function getBakerOwner(uint16 _id) external view returns (address);
    function getFoodieOwner(uint16 _id) external view returns (address);
    function getShopOwnerOwner(uint16 _id) external view returns (address);
    function bakerCount() external view returns (uint16);
    function foodieCount() external view returns (uint16);
    function shopOwnerCount() external view returns (uint16);
    // *** ALPHAS AND RATS
    function alphaCount(uint8 _gameIdentifier) external view returns (uint16);
    function ratCount() external view returns (uint16);
    // *** NFT GROUP FUNCTION
    function createGroup(uint16[] calldata _ids, address _creator, uint8 _gameIdentifier) external;
    function addToGroup(uint16 _id, address _creator, uint8 _gameIdentifier) external;
    function unstakeGroup(address _creator, uint8 _gameIdentifier) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITopia {

    function burn(uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;  
    function burnFrom(address _from, uint256 _amount) external;
    function decimals() external pure returns (uint8);
    function balanceOf(address owner) external view returns (uint);
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface INFT is IERC721Enumerable {
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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