// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ICoinFlip.sol";
import "../interfaces/IRandomizer.sol";
import "../interfaces/IHUB.sol";

contract BullRun is Ownable, ReentrancyGuard {

    address payable public RandomizerContract = payable(0xF9439027c8A21E1375CCDFf31c46ca21f8603305); // VRF contract to decide nft stealing
    address payable dev;
    address public betContract = 0x3e8e72A8656F58Ec6ccD4984b1DD55c1a1530bf7;
    IERC721 public Genesis = IERC721(0x810FeDb4a6927D02A6427f7441F6110d7A1096d5); // Genesis NFT contract
    IERC721 public Alpha = IERC721(0x96Af517c414B3726c1B2Ecc744ebf9d292DCbF60); // Alpha NFT contract

    ICoinFlip private CoinFlipInterface = ICoinFlip(0xa8162F992941DabC27815d050621e71D8C0DC489);
    IRandomizer private RandomizerInterface = IRandomizer(0xF9439027c8A21E1375CCDFf31c46ca21f8603305);
    IHUB public HubInterface = IHUB(0x440D2083c9f84F66831383c386fF28A903657ca3);

    mapping(uint16 => uint8) public NFTType; // tokenID (ID #) => nftID (1 = runner, 2 = bull.. etc)
    mapping(uint8 => uint8) public Risk; // NFT TYPE (not NFT ID) => % chance to get stolen
    mapping(uint16 => bool) public IsNFTStaked; // whether or not an NFT ID # is staked
    mapping(uint16 => Stake) public StakedNFTInfo; // tokenID to stake info
    mapping(address => uint16) public NumberOfStakedNFTs; // the number of NFTs a wallet has staked;
    mapping(uint16 => Stake) public StakedAlphaInfo; // tokenID to stake info
    mapping(uint16 => Migration) public WastelandMatadors; // for matadors sent to wastelands
    mapping(uint16 => bool) public IsAlphaStaked; // whether or not an NFT ID # is staked
    mapping(address => uint16) public NumberOfStakedAlphas; // the number of NFTs a wallet has staked;
    mapping(uint16 => bool) public IsInWastelands; // if matador token ID is in the wastelands
    mapping(uint16 => bool) public IsInMob; // if NFT ID is in a mob or not
    mapping(address => bool) public HasMob; // if a wallet has a mob or not
    mapping(address => uint16) public GroupLength;

    // ID used to identify type of NFT being staked
    uint8 public constant RunnerId = 1;
    uint8 public constant BullId = 2;
    uint8 public constant MatadorId = 3;
    uint8 public minimumForMob;

    // keeps track of total NFT's staked
    uint16 public stakedRunners;
    uint16 public stakedBulls;
    uint16 public stakedMatadors;
    uint16 public stakedAlphas;
    uint16 public migratedMatadors;

    // any rewards distributed when no Alphas are staked
    uint256 private unaccountedAlphaRewards;
    // amount of $TOPIA due for each Alpha staked
    uint256 private TOPIAPerAlpha;

    uint256 public runnerRewardMult;
    uint256 public bullRewardMult;
    uint256 public matadorRewardMult;
    uint256 public alphaRewardMult;

    uint256 public totalTOPIAEarned;
    // the last time $TOPIA can be earned
    uint80 public claimEndTime = 1669662000;
    uint256 public constant PERIOD = 1440 minutes;
    uint256 public SEED_COST = 0.0005 ether;
    uint256 public DEV_FEE = .0018 ether;
    // for staked tier 3 nfts
    uint256 public WASTELAND_BONUS = 100 ether;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenID;
        address owner; // the wallet that staked it
        uint80 stakeTimestamp; // when this particular NFT is staked.
        uint8 typeOfNFT; // (1 = runner, 2 = bull, 3 = matador, etc)
        uint256 value; // for reward calcs.
    }

    struct Migration {
        uint16 matadorTokenId;
        address matadorOwner;
        uint80 value;
        uint80 migrationTime;
    }

    event RunnerStaked (address indexed staker, uint16[] stakedIDs);
    event BullStaked (address indexed staker, uint16[] stakedIDs);
    event MatadorStaked (address indexed staker, uint16[] stakedIDs);
    event AlphaStaked (address indexed staker, uint16 stakedID);
    event RunnerUnstaked (address indexed staker, uint16 unstakedID);
    event BullUnstaked (address indexed staker, uint16 unstakedID);
    event MatadorUnstaked (address indexed staker, uint16 unstakedID);
    event AlphaUnstaked (address indexed staker, uint16 unstakedID);
    event TopiaClaimed (address indexed claimer, uint256 amount);
    event AlphaClaimed(uint16 indexed tokenId, bool indexed unstaked, uint256 earned);
    event BetRewardClaimed (address indexed claimer, uint256 amount);
    event MatadorMigrated (address indexed migrator, uint16 id, bool returning);
    event MatadorClaimed (uint256 _amount);
    event GenesisStolen (uint16 indexed tokenId, address victim, address thief, uint8 nftType, uint256 timeStamp);
 
    // @param: _minStakeTime should be # of SECONDS (ex: if minStakeTime is 1 day, pass 86400)
    // @param: _runner/bull/alphaMult = number of topia per period
    constructor(uint8 _minimumForMob) {

        Risk[1] = 10; // runners
        Risk[2] = 10; // bulls

        runnerRewardMult = 5 ether;
        bullRewardMult = 8 ether;
        matadorRewardMult = 8 ether;
        alphaRewardMult = 10 ether;
        minimumForMob = _minimumForMob;

        dev = payable(msg.sender);
    }
     
    receive() external payable {}

    // INTERNAL HELPERS ----------------------------------------------------

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

    modifier onlyBetContract() {
        require(msg.sender == betContract, "Only Bet Contract can call");
        _;
    }

    // SETTERS ----------------------------------------------------

    function setRNGContract(address _coinFlipContract) external onlyOwner {
        CoinFlipInterface = ICoinFlip(_coinFlipContract);
    }

    function updateDevCost(uint256 _cost) external onlyOwner {
        DEV_FEE = _cost;
    }

    function updateDev(address payable _dev) external onlyOwner {
        dev = _dev;
    }

    function setHUB(address _hub) external onlyOwner {
        HubInterface = IHUB(_hub);
    }

    function setRandomizer(address _randomizer) external onlyOwner {
        RandomizerContract = payable(_randomizer);
        RandomizerInterface = IRandomizer(_randomizer);
    }

    function setBetContract(address _bet) external onlyOwner {
        betContract = _bet;
    }

    function setMinimumForMob(uint8 _min) external onlyOwner {
        minimumForMob = _min;
    }
    
    function setPaymentMultipliers(uint8 _runnerMult, uint8 _bullMult, uint8 _alphaMult) external onlyOwner {
        runnerRewardMult = _runnerMult;
        bullRewardMult = _bullMult;
        alphaRewardMult = _alphaMult;
    }

    function setRisks(uint8 _runnerRisk, uint8 _bullRisk) external onlyOwner {
        Risk[0] = _runnerRisk;
        Risk[1] = _bullRisk;
    }

    function setSeedCost(uint256 _cost) external onlyOwner {
        SEED_COST = _cost;
    }

    function setClaimEndTime(uint80 _time) external onlyOwner {
        claimEndTime = _time;
    }

    // mass update the nftType mapping
    function setBatchNFTType(uint16[] calldata _idNumbers, uint8[] calldata _types) external onlyOwner {
        require(_idNumbers.length == _types.length);
        for (uint16 i = 0; i < _idNumbers.length;) {
            require(_types[i] != 0 && _types[i] <= 3);
            NFTType[_idNumbers[i]] = _types[i];
            unchecked{ i++; }
        }
    }

    function setWastelandsBonus(uint256 _bonus) external onlyOwner {
        WASTELAND_BONUS = _bonus;
    }

    // CLAIM FUNCTIONS ----------------------------------------------------    

    function claimManyGenesis(uint16[] calldata tokenIds, uint8 _type, bool unstake) external payable nonReentrant {
        uint256 numWords = tokenIds.length;
        uint256[] memory seed;

        if((_type == 1 || _type == 2) && unstake) {
            uint256 remainingWords = RandomizerInterface.getRemainingWords();
            require(remainingWords >= numWords, "try again soon.");
            require(msg.value == DEV_FEE + (SEED_COST * numWords), "incorrect eth");
            RandomizerContract.transfer(SEED_COST * numWords);
            dev.transfer(DEV_FEE);
            seed = RandomizerInterface.getRandomWords(numWords);
        } else {
            require(msg.value == DEV_FEE, "incorrect eth");
            dev.transfer(DEV_FEE);
        }
        
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length;) {
            if (NFTType[tokenIds[i]] == 1) {
                require(!IsInMob[tokenIds[i]], "id in mob");
                (uint256 _owed) = claimRunner(tokenIds[i], unstake, unstake ? seed[i] : 0);
                owed += _owed;
            } else if (NFTType[tokenIds[i]] == 2) {
                (uint256 _owed) = claimBull(tokenIds[i], unstake, unstake ? seed[i] : 0);
                owed += _owed;
            } else if (NFTType[tokenIds[i]] == 3) {
                owed += claimMatador(tokenIds[i], unstake);
            } else if (NFTType[tokenIds[i]] == 0) {
                revert("Invalid Token Id");
            }
            unchecked{ i++; }
        }
        if (owed == 0) {
            return;
        }
        totalTOPIAEarned += owed;
        emit TopiaClaimed(msg.sender, owed);
        HubInterface.pay(msg.sender, owed);
    }

    function claimManyAlphas(uint16[] calldata _tokenIds, bool unstake) external payable nonReentrant {
        uint256 owed = 0;
        uint16 length = uint16(_tokenIds.length);
        require(msg.value == DEV_FEE, "need more eth");
        for (uint i = 0; i < length;) { 
            require(StakedAlphaInfo[_tokenIds[i]].owner == msg.sender, "not owner");
            owed += (block.timestamp - StakedAlphaInfo[_tokenIds[i]].stakeTimestamp) * alphaRewardMult / PERIOD;
            owed += (TOPIAPerAlpha - StakedAlphaInfo[_tokenIds[i]].value);
            if (unstake) {
                delete StakedAlphaInfo[_tokenIds[i]];
                stakedAlphas -= 1;
                HubInterface.returnAlphaToOwner(msg.sender, _tokenIds[i], 1);
                NumberOfStakedNFTs[msg.sender] -= uint16(_tokenIds.length);
                
                emit AlphaUnstaked(msg.sender, _tokenIds[i]);
            } else {
                StakedAlphaInfo[_tokenIds[i]].stakeTimestamp = uint80(block.timestamp);
                StakedAlphaInfo[_tokenIds[i]].value = TOPIAPerAlpha;
            }
            emit AlphaClaimed(_tokenIds[i], unstake, owed);
            unchecked{ i++; }
        }
        dev.transfer(DEV_FEE);
        if (owed == 0) {
            return;
        }
        HubInterface.pay(msg.sender, owed);
        emit TopiaClaimed(msg.sender, owed);
    }

    function getTXCost(uint16[] calldata tokenIds, uint8 _type) external view returns (uint256 txCost) {
        if(_type == 1) {
            txCost = DEV_FEE + (SEED_COST * tokenIds.length);
        } else {
            txCost = DEV_FEE;
        }
    } 

    // STAKING FUNCTIONS ----------------------------------------------------

    function stakeMany(uint16[] calldata _tokenIds) external payable nonReentrant notContract() {
        uint16 length = uint16(_tokenIds.length);
        uint8[] memory identifiers = new uint8[](length);
        require(msg.value == DEV_FEE, "need more eth");

        for (uint i = 0; i < _tokenIds.length;) {
            require(Genesis.ownerOf(_tokenIds[i]) == msg.sender, "not owner");

            if (NFTType[_tokenIds[i]] == 1) {
                identifiers[i] = 1;
                IsNFTStaked[_tokenIds[i]] = true;
                StakedNFTInfo[_tokenIds[i]].tokenID = _tokenIds[i];
                StakedNFTInfo[_tokenIds[i]].owner = msg.sender;
                StakedNFTInfo[_tokenIds[i]].stakeTimestamp = uint80(block.timestamp);
                StakedNFTInfo[_tokenIds[i]].value = uint80(block.timestamp);
                StakedNFTInfo[_tokenIds[i]].typeOfNFT = 1;
                stakedRunners++;
            } else if (NFTType[_tokenIds[i]] == 2) {
                identifiers[i] = 2;
                IsNFTStaked[_tokenIds[i]] = true;
                StakedNFTInfo[_tokenIds[i]].tokenID = _tokenIds[i];
                StakedNFTInfo[_tokenIds[i]].owner = msg.sender;
                StakedNFTInfo[_tokenIds[i]].stakeTimestamp = uint80(block.timestamp);
                StakedNFTInfo[_tokenIds[i]].value = uint80(block.timestamp);
                StakedNFTInfo[_tokenIds[i]].typeOfNFT = 2;
                stakedBulls++;
            } else if (NFTType[_tokenIds[i]] == 3) {
                identifiers[i] = 3;
                IsNFTStaked[_tokenIds[i]] = true;
                StakedNFTInfo[_tokenIds[i]].tokenID = _tokenIds[i];
                StakedNFTInfo[_tokenIds[i]].owner = msg.sender;
                StakedNFTInfo[_tokenIds[i]].stakeTimestamp = uint80(block.timestamp);
                StakedNFTInfo[_tokenIds[i]].value = uint80(block.timestamp);
                StakedNFTInfo[_tokenIds[i]].typeOfNFT = 3;
                stakedMatadors++;
            } else if (NFTType[_tokenIds[i]] == 0) {
                revert("invalid NFT");
            }
            unchecked{ i++; }
        }
        NumberOfStakedNFTs[msg.sender]+= length;
        dev.transfer(DEV_FEE);
        HubInterface.receieveManyGenesis(msg.sender, _tokenIds, identifiers, 1);
    }


    function claimRunner(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed) {
        require(StakedNFTInfo[tokenId].owner == msg.sender, "not owner");
        
        if(block.timestamp <= claimEndTime) {
            owed = (block.timestamp - StakedNFTInfo[tokenId].value) * runnerRewardMult / PERIOD;
        } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
            owed = (claimEndTime - StakedNFTInfo[tokenId].value) * runnerRewardMult / PERIOD;
        } else {
            owed = 0;
        }

        if(unstake) {
            IsNFTStaked[tokenId] = false;
            delete StakedNFTInfo[tokenId]; // reset the struct for this token ID

            if (HubInterface.alphaCount(1) > 0 && (seed % 100) < Risk[1]) { // nft gets stolen
                address thief = HubInterface.stealGenesis(tokenId, seed, 1, 1, msg.sender);
                emit GenesisStolen (tokenId, msg.sender, thief, 1, block.timestamp);
            } else {
                HubInterface.returnGenesisToOwner(msg.sender, tokenId, 1, 1);
                emit RunnerUnstaked(msg.sender, tokenId);
            }
            
            stakedRunners--;
            NumberOfStakedNFTs[msg.sender]--;
        } else {
            StakedNFTInfo[tokenId].value = uint80(block.timestamp); // reset the stakeTime for this NFT
        }
    }

    function claimBull(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed) {
        require(StakedNFTInfo[tokenId].owner == msg.sender, "not owner");
        
        if(block.timestamp <= claimEndTime) {
            owed = (block.timestamp - StakedNFTInfo[tokenId].value) * bullRewardMult / PERIOD;
        } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
            owed = (claimEndTime - StakedNFTInfo[tokenId].value) * bullRewardMult / PERIOD;
        } else {
            owed = 0;
        }

        if(unstake) {
            IsNFTStaked[tokenId] = false;
            delete StakedNFTInfo[tokenId]; // reset the struct for this token ID

            if (HubInterface.matadorCount() > 0 && (seed % 100) < Risk[2]) { // nft gets stolen
                address thief = HubInterface.stealGenesis(tokenId, seed, 1, 2, msg.sender);
                emit GenesisStolen (tokenId, msg.sender, thief, 2, block.timestamp);
            } else {
                HubInterface.returnGenesisToOwner(msg.sender, tokenId, 2, 1);
                emit BullUnstaked(msg.sender, tokenId);
            }

            stakedBulls--;
            NumberOfStakedNFTs[msg.sender]--;
        } else {
            StakedNFTInfo[tokenId].value = uint80(block.timestamp); // reset the stakeTime for this NFT 
        }
    }

    function claimMatador(uint16 tokenID, bool unstake) internal returns (uint256 owed) {
        require(StakedNFTInfo[tokenID].owner == msg.sender, "not owner");

        if(block.timestamp <= claimEndTime) {
            owed = (block.timestamp - StakedNFTInfo[tokenID].value) * matadorRewardMult / PERIOD;
        } else if (StakedNFTInfo[tokenID].value < claimEndTime) {
            owed = (claimEndTime - StakedNFTInfo[tokenID].value) * matadorRewardMult / PERIOD;
        } else {
            owed = 0;
        }

        if(unstake) {
            IsNFTStaked[tokenID] = false;
            delete StakedNFTInfo[tokenID]; // reset the struct for this token ID
            HubInterface.returnGenesisToOwner(msg.sender, tokenID, 3, 1);

            stakedMatadors--;
            NumberOfStakedNFTs[msg.sender]--;
            emit MatadorUnstaked(msg.sender, tokenID);
        } else {
            StakedNFTInfo[tokenID].value = uint80(block.timestamp);
        }
    }

    function stakeManyAlphas(uint16[] calldata _tokenIds) external payable nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        require(msg.value == DEV_FEE, "need more eth");
        for (uint i = 0; i < _tokenIds.length;) {
            require(Alpha.ownerOf(_tokenIds[i]) == msg.sender, "not owner");
            
            IsAlphaStaked[_tokenIds[i]] = true;
            StakedAlphaInfo[_tokenIds[i]].tokenID = _tokenIds[i];
            StakedAlphaInfo[_tokenIds[i]].owner = msg.sender;
            StakedAlphaInfo[_tokenIds[i]].stakeTimestamp = uint80(block.timestamp);
            StakedAlphaInfo[_tokenIds[i]].value = TOPIAPerAlpha;
            StakedAlphaInfo[_tokenIds[i]].typeOfNFT = 0;
            HubInterface.receiveAlpha(msg.sender, _tokenIds[i], 1);

            stakedAlphas++;
            NumberOfStakedAlphas[msg.sender]++;
            NumberOfStakedNFTs[msg.sender]++;
            emit AlphaStaked(msg.sender, _tokenIds[i]);
            unchecked{ i++; }
        }
        dev.transfer(DEV_FEE);
    }

    function getUnclaimedAlpha(uint16 tokenId) external view returns (uint256 owed) {
        owed += (block.timestamp - StakedAlphaInfo[tokenId].stakeTimestamp) * alphaRewardMult / PERIOD;
        owed += (TOPIAPerAlpha - StakedAlphaInfo[tokenId].value);
        return owed;
    }

    function getUnclaimedGenesis(uint16 tokenId) external view returns (uint256 owed) {
        if (!IsNFTStaked[tokenId]) { return 0; }
        if (NFTType[tokenId] == 1) {
            if (block.timestamp <= claimEndTime) {
                owed = (block.timestamp - StakedNFTInfo[tokenId].value) * runnerRewardMult / PERIOD;
            } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
                owed = (claimEndTime - StakedNFTInfo[tokenId].value) * runnerRewardMult / PERIOD;
            } else {
                owed = 0;
            }
        } else if (NFTType[tokenId] == 2) {
            if (block.timestamp <= claimEndTime) {
                owed = (block.timestamp - StakedNFTInfo[tokenId].value) * bullRewardMult / PERIOD;
            } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
                owed = (claimEndTime - StakedNFTInfo[tokenId].value) * bullRewardMult / PERIOD;
            } else {
                owed = 0;
            }
        } else if (NFTType[tokenId] == 3) {
            if (IsInWastelands[tokenId]) {
                owed = WastelandMatadors[tokenId].value;
            } else if(block.timestamp <= claimEndTime) {
                owed = (block.timestamp - StakedNFTInfo[tokenId].value) * matadorRewardMult / PERIOD;
            } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
                owed = (claimEndTime - StakedNFTInfo[tokenId].value) * matadorRewardMult / PERIOD;
            } else {
                owed = 0;
            }
        }
        return owed;
    }

    function createMob(uint16[] calldata _tokenIds) external payable nonReentrant notContract() {
        require(msg.value == DEV_FEE, "need more eth");
        require(!HasMob[msg.sender] , "already have a mob");
        uint16 length = uint16(_tokenIds.length);
        require(length >= minimumForMob , "Not enough runners");
        for (uint16 i = 0; i < length;) {
            require(Genesis.ownerOf(_tokenIds[i]) == msg.sender, "not owner");
            require(NFTType[_tokenIds[i]] == 1 , "only runner");
            require(!IsInMob[_tokenIds[i]], "NFT in mob");
            StakedNFTInfo[_tokenIds[i]].tokenID = _tokenIds[i];
            StakedNFTInfo[_tokenIds[i]].owner = msg.sender;
            StakedNFTInfo[_tokenIds[i]].stakeTimestamp = uint80(block.timestamp);
            StakedNFTInfo[_tokenIds[i]].value = uint80(block.timestamp);
            StakedNFTInfo[_tokenIds[i]].typeOfNFT = 1;
            IsInMob[_tokenIds[i]] = true;
            unchecked{ i++; }
        }
        GroupLength[msg.sender] = length;
        stakedRunners+= length;
        HubInterface.createGroup(_tokenIds, msg.sender, 1);
        HasMob[msg.sender] = true;
        dev.transfer(DEV_FEE);
    }

    function addToMob(uint16 _id) external payable nonReentrant notContract() {
        require(msg.value == DEV_FEE, "need more eth");
        require(HasMob[msg.sender], "Must have Mob!");
        require(Genesis.ownerOf(_id) == msg.sender, "not owner");
        require(NFTType[_id] == 1 , "must be runner");
        require(!IsInMob[_id], "NFT can only be in 1 mob");
        StakedNFTInfo[_id].tokenID = _id;
        StakedNFTInfo[_id].owner = msg.sender;
        StakedNFTInfo[_id].stakeTimestamp = uint80(block.timestamp);
        StakedNFTInfo[_id].value = uint80(block.timestamp);
        StakedNFTInfo[_id].typeOfNFT = 1;
        IsInMob[_id] = true;
        stakedRunners++;
        GroupLength[msg.sender]++;
        HubInterface.addToGroup(_id, msg.sender, 1);
        dev.transfer(DEV_FEE);
    }

    function claimMob(uint16[] calldata tokenIds, bool unstake) external payable notContract() {
        require(HasMob[msg.sender] , "Must have a Mob");
        uint256 numWords = tokenIds.length;
        uint256[] memory seed;
        uint8 theftModifier;

        if (unstake) {
            uint256 remainingWords = RandomizerInterface.getRemainingWords();
            require(remainingWords >= numWords, "Not enough random numbers; try again soon.");
            require(msg.value == DEV_FEE + (SEED_COST * numWords), "need more eth");
            require(uint16(numWords) == GroupLength[msg.sender]);
            RandomizerContract.transfer(SEED_COST * numWords);
            dev.transfer(DEV_FEE);
            seed = RandomizerInterface.getRandomWords(numWords);
            if (numWords <= 10) {
                theftModifier = uint8(numWords);
            } else { theftModifier = 10; }
        } else {
            require(msg.value == DEV_FEE, "need more eth");
            dev.transfer(DEV_FEE);
        }
        
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length;) {
            require(NFTType[tokenIds[i]] == 1, "must be runners");
            require(IsInMob[tokenIds[i]] , "must be in mob");
            require(StakedNFTInfo[tokenIds[i]].owner == msg.sender, "not owner");

            if(block.timestamp <= claimEndTime) {
                owed += (block.timestamp - StakedNFTInfo[tokenIds[i]].value) * runnerRewardMult / PERIOD;
            } else if (StakedNFTInfo[tokenIds[i]].value < claimEndTime) {
                owed += (claimEndTime - StakedNFTInfo[tokenIds[i]].value) * runnerRewardMult / PERIOD;
            } else {
                owed += 0;
            }
            if(unstake) {
                IsNFTStaked[tokenIds[i]] = false;
                delete StakedNFTInfo[tokenIds[i]]; // reset the struct for this token ID
                IsInMob[tokenIds[i]] = false;

                if (HubInterface.alphaCount(1) > 0 && (seed[i] % 100) < 10 - (theftModifier)) { // nft gets stolen
                    address thief = HubInterface.stealGenesis(tokenIds[i], seed[i], 1, 1, msg.sender);
                    emit GenesisStolen (tokenIds[i], msg.sender, thief, 1, block.timestamp);
                } else {
                    HubInterface.returnGenesisToOwner(msg.sender, tokenIds[i], 1, 1);
                    emit RunnerUnstaked(msg.sender, tokenIds[i]);
                }
            } else {
                StakedNFTInfo[tokenIds[i]].value = uint80(block.timestamp); // reset the stakeTime for this NFT
            }
        unchecked{ i++; }
        }

        if (unstake) { 
            HasMob[msg.sender] = false;
            stakedRunners -= uint16(numWords);
            HubInterface.unstakeGroup(msg.sender, 1);
            GroupLength[msg.sender] = 0;
        }
        
        if (owed == 0) { return; }
        totalTOPIAEarned += owed;
        HubInterface.pay(msg.sender, owed);
    }


    function sendMatadorToWastelands(uint16[] calldata _ids) external payable notContract() {
        uint256 numWords = _ids.length;
        require(msg.value == DEV_FEE + (SEED_COST * numWords) , "insufficient eth ");
        require(RandomizerInterface.getRemainingWords() >= numWords, "try again soon.");
        uint256[] memory seed = RandomizerInterface.getRandomWords(numWords);

        for (uint16 i = 0; i < numWords;) {
            require(Genesis.ownerOf(_ids[i]) == msg.sender, "not owner");
            require(NFTType[_ids[i]] == 3, "not Matador");
            require(!IsInWastelands[_ids[i]] , "in wastelands");

            if (HubInterface.alienCount() > 0 && (seed[i]) % 100 < 25) { // stolen
                address thief = HubInterface.stealMigratingGenesis(_ids[i], seed[i], 1, msg.sender, false);
                emit GenesisStolen (_ids[i], msg.sender, thief, 3, block.timestamp);
            } else {
                HubInterface.migrate(_ids[i], msg.sender, 1, false);
                WastelandMatadors[_ids[i]].matadorTokenId = _ids[i];
                WastelandMatadors[_ids[i]].matadorOwner = msg.sender;
                WastelandMatadors[_ids[i]].value = uint80(WASTELAND_BONUS);
                WastelandMatadors[_ids[i]].migrationTime = uint80(block.timestamp);
                IsInWastelands[_ids[i]] = true;
                migratedMatadors++;
                emit MatadorMigrated(msg.sender, _ids[i], false);
            }
            unchecked { i++; }
        }
        RandomizerContract.transfer(SEED_COST * numWords);
        dev.transfer(DEV_FEE);
    }

    function claimManyWastelands(uint16[] calldata _ids, bool unstake) external payable notContract() {
        uint256 numWords = _ids.length;
        uint256[] memory seed;

        if (unstake) {
            require(RandomizerInterface.getRemainingWords() >= numWords, "try again soon.");
            require(msg.value == DEV_FEE + (SEED_COST * numWords), "need more eth");
            RandomizerContract.transfer(SEED_COST * numWords);
            dev.transfer(DEV_FEE);
            seed = RandomizerInterface.getRandomWords(numWords);
        } else {
            require(msg.value == DEV_FEE, "need more eth");
            dev.transfer(DEV_FEE);
        }

        uint256 owed = 0;

        for (uint16 i = 0; i < numWords;) {
            require(IsInWastelands[_ids[i]] , "not in wastelands");
            require(msg.sender == WastelandMatadors[_ids[i]].matadorOwner , "not owner");
            
            owed += WastelandMatadors[_ids[i]].value;

            if (unstake) {
                if (HubInterface.alienCount() > 0 && (seed[i]) % 100 < 25) { // stolen
                    address thief = HubInterface.stealMigratingGenesis(_ids[i], seed[i], 1, msg.sender, true);
                    emit GenesisStolen (_ids[i], msg.sender, thief, 3, block.timestamp);
                } else {
                    HubInterface.migrate(_ids[i], msg.sender, 1, true);
                    emit MatadorMigrated(msg.sender, _ids[i], true);
                }
                IsInWastelands[_ids[i]] = false;
                delete WastelandMatadors[_ids[i]];
            } else {
                WastelandMatadors[_ids[i]].value = uint80(0); // reset value
            }
            emit MatadorClaimed(owed);
            unchecked { i++; }
        }
        if (unstake) {
            migratedMatadors -= uint16(numWords);
        }
        totalTOPIAEarned += owed;
        if(owed > 0) { HubInterface.pay(msg.sender, owed); }
    }

    function payAlphaTax(uint256 _amount) external onlyBetContract {
       if (stakedAlphas == 0) {// if there's no staked alphas
            unaccountedAlphaRewards += _amount;
            // keep track of $TOPIA due to alphas
            return;
        }
        // makes sure to include any unaccounted $TOPIA
        TOPIAPerAlpha += (_amount + unaccountedAlphaRewards) / stakedAlphas;
        unaccountedAlphaRewards = 0;
    }
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    function requestRandomWords() external returns (uint256);
    function requestManyRandomWords(uint256 numWords) external returns (uint256);
    function getRandomWords(uint256 number) external returns (uint256[] memory);
    function getRemainingWords() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICoinFlip {
    
    function oneOutOfTwo() external view returns (uint256);
    function requestRandomWords() external;
    
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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