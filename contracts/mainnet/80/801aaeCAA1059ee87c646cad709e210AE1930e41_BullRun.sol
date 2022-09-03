// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IMetatopiaCoinFlipRNG.sol";
import "./interfaces/ITopia.sol";
import "./interfaces/IBullpen.sol";
import "./interfaces/IArena.sol";
import "./interfaces/IRandomizer.sol";
import "./interfaces/IHub.sol";

contract BullRun is IERC721Receiver, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet;

    address payable public RandomizerContract = payable(0xF9439027c8A21E1375CCDFf31c46ca21f8603305); // VRF contract to decide nft stealing
    address public BullpenContract = 0x9c215c9Ab78b544345047b9aB604c9c9AC391100; // stores staked Bulls
    address public ArenaContract = 0xF84BD9d391c9d4874032809BE3Fd121103de5F60; // stores staked Matadors
    IERC721 public Genesis = IERC721(0x810FeDb4a6927D02A6427f7441F6110d7A1096d5); // Genesis NFT contract
    IERC721 public Alpha = IERC721(0x96Af517c414B3726c1B2Ecc744ebf9d292DCbF60); // Alpha NFT contract

    IMetatopiaCoinFlipRNG private MetatopiaCoinFlipRNGInterface = IMetatopiaCoinFlipRNG(0xfe68e3F51F9c79569eB3679B750e617b423852F9);
    ITopia private TopiaInterface = ITopia(0x41473032b82a4205DDDe155CC7ED210B000b014D);
    IBullpen private BullpenInterface = IBullpen(0x9c215c9Ab78b544345047b9aB604c9c9AC391100);
    IArena private ArenaInterface = IArena(0xF84BD9d391c9d4874032809BE3Fd121103de5F60);
    IRandomizer private RandomizerInterface = IRandomizer(0xF9439027c8A21E1375CCDFf31c46ca21f8603305);
    IHub public HubInterface = IHub(0x69fdE1A7d6837cD7E82B0BbedcbAd40F487Fdb05);

    mapping(uint16 => uint8) public NFTType; // tokenID (ID #) => nftID (1 = runner, 2 = bull.. etc)
    mapping(uint8 => uint8) public Risk; // NFT TYPE (not NFT ID) => % chance to get stolen
    mapping(uint16 => bool) public IsNFTStaked; // whether or not an NFT ID # is staked
    mapping(address => mapping(uint256 => uint16[])) public BetNFTsPerEncierro; // keeps track of each players token IDs bet for each encierro
    mapping(uint16 => mapping(uint256 => NFTBet)) public BetNFTInfo; // tokenID to bet info (each staked NFT is its own separate bet) per session
    mapping(address => mapping(uint256 => bool)) public HasBet; // keeps track of whether or not a user has bet in a certain encierro
    mapping(address => mapping(uint256 => bool)) public HasClaimed; // keeps track of users and whether or not they have claimed reward for an encierro bet (not for daily topia)
    mapping(uint256 => Encierro) public Encierros; // mapping for Encierro id to unlock corresponding encierro params
    mapping(address => uint256[]) public EnteredEncierros; // list of Encierro ID's that a particular address has bet in
    mapping(uint16 => Stake) public StakedNFTInfo; // tokenID to stake info
    mapping(address => uint16) public NumberOfStakedNFTs; // the number of NFTs a wallet has staked;
    mapping(address => EnumerableSet.UintSet) StakedTokensOfWallet; // list of token IDs a user has staked
    mapping(address => EnumerableSet.UintSet) MatadorsStakedPerWallet; // list of matador IDs a user has staked
    mapping(address => EnumerableSet.UintSet) StakedAlphasOfWallet; // list of Alpha token IDs a user has staked
    mapping(uint16 => Stake) public StakedAlphaInfo; // tokenID to stake info
    mapping(uint16 => bool) public IsAlphaStaked; // whether or not an NFT ID # is staked
    mapping(address => uint16) public NumberOfStakedAlphas; // the number of NFTs a wallet has staked;

    // ID used to identify type of NFT being staked
    uint8 public constant RunnerId = 1;
    uint8 public constant BullId = 2;
    uint8 public constant MatadorId = 3;

    // keeps track of total NFT's staked
    uint16 public stakedRunners;
    uint16 public stakedBulls;
    uint16 public stakedMatadors;
    uint16 public stakedAlphas;
    uint256 public currentEncierroId;

    uint80 public minimumStakeTime = 0;
    uint256 public maxDuration = 300;
    uint256 public minDuration = 86400;

    // any rewards distributed when no Matadors are staked
    uint256 private unaccountedMatadorRewards;
    // amount of $TOPIA due for each Matador staked
    uint256 private TOPIAPerMatador;

    uint256 public runnerRewardMult;
    uint256 public bullRewardMult;
    uint256 public alphaRewardMult;
    uint256 public matadorCut; // numerator with 10000 divisor. ie 5% = 500 

    uint256 public totalTOPIAEarned;
    // the last time $TOPIA can be earned
    uint80 public claimEndTime;
    uint256 public constant PERIOD = 1440 minutes;

    uint256 public SEED_COST = 0.0038 ether;

    // an individual NFT being bet
    struct NFTBet {
        address player;
        uint256 amount; 
        uint8 choice; // (0) BULLS or (1) RUNNERS;
        uint16 tokenID;
        uint8 typeOfNFT;
    }

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenID;
        address owner; // the wallet that staked it
        uint80 stakeTimestamp; // when this particular NFT is staked.
        uint8 typeOfNFT; // (1 = runner, 2 = bull, 3 = matador, etc)
        uint256 value; // for matador reward calcs - irrelevant unless typeOfNFT = 3.
    }

    // status for bull run betting Encierros
    enum Status {
        Closed,
        Open,
        Standby,
        Claimable
    }

    // BULL RUN Encierro ( EL ENCIERRO ) ----------------------------------------------------

    struct Encierro {
        Status status;
        uint256 encierroId; // increments monotonically 
        uint256 startTime; // unix timestamp
        uint256 endTime; // unix timestamp
        uint256 minBet;
        uint256 maxBet;
        uint16 numRunners; // number of runners entered
        uint16 numBulls; // number of bulls entered
        uint16 numMatadors; // number of matadors entered
        uint16 numberOfBetsOnRunnersWinning; // # of people betting for runners
        uint16 numberOfBetsOnBullsWinning; // # of people betting for bulls
        uint256 topiaBetByRunners; // all TOPIA bet by runners
        uint256 topiaBetByBulls; // all TOPIA bet by bulls
        uint256 topiaBetByMatadors; // all TOPIA bet by matadors
        uint256 topiaBetOnRunners; // all TOPIA bet that runners will win
        uint256 topiaBetOnBulls; // all TOPIA bet that bulls will win
        uint256 totalTopiaCollected; // total TOPIA collected from bets for the entire round
        uint256 flipResult; // 0 for bulls, 1 for runners
    }

    event RunnerStolen (address indexed victim, address indexed theif);
    event BullStolen (address indexed victim, address indexed theif);
    event RunnerStaked (address indexed staker, uint16 stakedID);
    event BullStaked (address indexed staker, uint16 stakedID);
    event MatadorStaked (address indexed staker, uint16 stakedID);
    event AlphaStaked (address indexed staker, uint16 stakedID);
    event RunnerUnstaked (address indexed staker, uint16 unstakedID);
    event BullUnstaked (address indexed staker, uint16 unstakedID);
    event MatadorUnstaked (address indexed staker, uint16 unstakedID);
    event AlphaUnstaked (address indexed staker, uint16 unstakedID);
    event TopiaClaimed (address indexed claimer, uint256 amount);
    event AlphaClaimed(uint16 indexed tokenId, bool indexed unstaked, uint256 earned);
    event BetRewardClaimed (address indexed claimer, uint256 amount);
    event BullsWin (uint80 timestamp, uint256 encierroID);
    event RunnersWin (uint80 timestamp, uint256 encierroID);
   
    event EncierroOpened(
        uint256 indexed encierroId,
        uint256 startTime,
        uint256 endTime,
        uint256 minBet,
        uint256 maxBet
    );

    event BetPlaced(
        address indexed player, 
        uint256 indexed encierroId, 
        uint256 amount,
        uint8 choice,
        uint16[] tokenIDs
    );

    event EncierroClosed(
        uint256 indexed encierroId, 
        uint256 endTime,
        uint16 numRunners,
        uint16 numBulls,
        uint16 numMatadors,
        uint16 numberOfBetsOnRunnersWinning,
        uint16 numberOfBetsOnBullsWinning,
        uint256 topiaBetByRunners, // all TOPIA bet by runners
        uint256 topiaBetByBulls, // all TOPIA bet by bulls
        uint256 topiaBetByMatadors, // all TOPIA bet by matadors
        uint256 topiaBetOnRunners, // all TOPIA bet that runners will win
        uint256 topiaBetOnBulls, // all TOPIA bet that bulls will win
        uint256 totalTopiaCollected
    );

    event CoinFlipped(
        uint256 flipResult,
        uint256 indexed encierroId
    );

    // @param: _minStakeTime should be # of SECONDS (ex: if minStakeTime is 1 day, pass 86400)
    // @param: _runner/bull/alphaMult = number of topia per period
    constructor() {

        Risk[1] = 10; // runners
        Risk[2] = 10; // bulls

        runnerRewardMult = 18 ether;
        bullRewardMult = 20 ether;
        alphaRewardMult = 35 ether;
        matadorCut = 500;
    }

    receive() external payable {}

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // INTERNAL HELPERS ----------------------------------------------------

    function _flipCoin() internal returns (uint256) {
        uint256 result = MetatopiaCoinFlipRNGInterface.oneOutOfTwo();
        Encierros[currentEncierroId].status = Status.Standby;
        if (result == 0) {
            Encierros[currentEncierroId].flipResult = 0;
            emit BullsWin(uint80(block.timestamp), currentEncierroId);
        } else {
            Encierros[currentEncierroId].flipResult = 1;
            emit RunnersWin(uint80(block.timestamp), currentEncierroId);
        }
        emit CoinFlipped(result, currentEncierroId);
        return result;
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

    // SETTERS ----------------------------------------------------

    function setTopiaToken(address _topiaToken) external onlyOwner {
        TopiaInterface = ITopia(_topiaToken);
    }

    function setRNGContract(address _coinFlipContract) external onlyOwner {
        MetatopiaCoinFlipRNGInterface = IMetatopiaCoinFlipRNG(_coinFlipContract);
    }

    function setBullpenContract(address _bullpenContract) external onlyOwner {
        BullpenContract = _bullpenContract;
        BullpenInterface = IBullpen(_bullpenContract);
    }

    function setArenaContract(address _arenaContract) external onlyOwner {
        ArenaContract = _arenaContract;
        ArenaInterface = IArena(_arenaContract);
    }

    function setHUB(address _hub) external onlyOwner {
        HubInterface = IHub(_hub);
    }

    function setRandomizer(address _randomizer) external onlyOwner {
        RandomizerContract = payable(_randomizer);
        RandomizerInterface = IRandomizer(_randomizer);
    }

    // IN SECONDS
    function setMinStakeTime(uint80 _minStakeTime) external onlyOwner {
        minimumStakeTime = _minStakeTime;
    }
    
    function setPaymentMultipliers(uint8 _runnerMult, uint8 _bullMult, uint8 _alphaMult, uint8 _matadorCut) external onlyOwner {
        runnerRewardMult = _runnerMult;
        bullRewardMult = _bullMult;
        alphaRewardMult = _alphaMult;
        matadorCut = _matadorCut;
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
        for (uint16 i = 0; i < _idNumbers.length; i++) {
            require(_types[i] != 0 && _types[i] <= 3);
            NFTType[_idNumbers[i]] = _types[i];
        }
    }

    function setMinMaxDuration(uint256 _min, uint256 _max) external onlyOwner {
        minDuration = _min;
        maxDuration = _max;
    }

    // GETTERS ----------------------------------------------------

    function viewEncierroById(uint256 _encierroId) external view returns (Encierro memory) {
        return Encierros[_encierroId];
    }

    function getEnteredEncierrosLength(address _better) external view returns (uint256) {
        return EnteredEncierros[_better].length;
    }



    // CLAIM FUNCTIONS ----------------------------------------------------    

    function claimManyGenesis(uint16[] calldata tokenIds, bool unstake) external payable nonReentrant returns (uint16[] memory stolenNFTs) {
        uint256 numWords = tokenIds.length;
        uint256[] memory seed;

        if(unstake) {
            require(msg.value == SEED_COST * numWords, "Invalid value for randomness");
            RandomizerContract.transfer(msg.value);
            uint256 remainingWords = RandomizerInterface.getRemainingWords();
            require(remainingWords >= numWords, "Not enough random numbers. Please try again soon.");
            seed = RandomizerInterface.getRandomWords(numWords);
            HubInterface.emitGenesisUnstaked(msg.sender, tokenIds);
            stolenNFTs = new uint16[](numWords);
        } else {
            stolenNFTs = new uint16[](1);
            stolenNFTs[0] = 0;
        }
        
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (NFTType[tokenIds[i]] == 1) {
                (uint256 _owed, uint16 _stolenId) = claimRunner(tokenIds[i], unstake, unstake ? seed[i] : 0);
                owed += _owed;
                if(unstake) { stolenNFTs[i] = _stolenId; }
            } else if (NFTType[tokenIds[i]] == 2) {
                (uint256 _owed, uint16 _stolenId) = claimBull(tokenIds[i], unstake, unstake ? seed[i] : 0);
                owed += _owed;
                if(unstake) { stolenNFTs[i] = _stolenId; }
            } else if (NFTType[tokenIds[i]] == 3) {
                owed += claimMatador(tokenIds[i], unstake);
                if(unstake) { stolenNFTs[i] = 0;}
            } else if (NFTType[tokenIds[i]] == 0) {
                revert("Invalid Token Id");
            }
        }
        if (owed == 0) {
            return stolenNFTs;
        }
        totalTOPIAEarned += owed;
        emit TopiaClaimed(msg.sender, owed);
        TopiaInterface.mint(msg.sender, owed);
        HubInterface.emitTopiaClaimed(msg.sender, owed);
    }

    function claimManyAlphas(uint16[] calldata _tokenIds, bool unstake) external nonReentrant {
        uint256 owed = 0;
        for (uint i = 0; i < _tokenIds.length; i++) { 
            require(StakedAlphaInfo[_tokenIds[i]].owner == msg.sender, "not owner");
            owed += (block.timestamp - StakedAlphaInfo[_tokenIds[i]].value) * alphaRewardMult / PERIOD;
            if (unstake) {
                delete StakedAlphaInfo[_tokenIds[i]];
                stakedAlphas -= 1;
                StakedAlphasOfWallet[msg.sender].remove(_tokenIds[i]);
                Alpha.safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
                HubInterface.emitAlphaUnstaked(msg.sender, _tokenIds);
                emit AlphaUnstaked(msg.sender, _tokenIds[i]);
            } else {
                StakedAlphaInfo[_tokenIds[i]].value = uint80(block.timestamp);
            }
            emit AlphaClaimed(_tokenIds[i], unstake, owed);
        }
        if (owed == 0) {
            return;
        }
        TopiaInterface.mint(msg.sender, owed);
        HubInterface.emitTopiaClaimed(msg.sender, owed);
        emit TopiaClaimed(msg.sender, owed);
    }

    // this fxn allows caller to claim winnings from their BET (not daily TOPIA)
    // @param: the calldata array is each of the tokenIDs they are attempting to claim FOR
    function claimManyBetRewards() external 
    nonReentrant notContract() {

        uint256 owed; // what caller collects for winning
        for(uint i = 1; i <= EnteredEncierros[msg.sender].length; i++) {
            if(Encierros[i].status == Status.Claimable && !HasClaimed[msg.sender][i] && HasBet[msg.sender][i]) {
                uint8 winningResult = uint8(Encierros[i].flipResult);
                require(winningResult <= 1 , "Invalid flip result");
                for (uint16 z = 0; z < BetNFTsPerEncierro[msg.sender][i].length; z++) { // fetch their bet NFT ids for this encierro
                    require(BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].player == msg.sender , 
                    "not owner");
                    
                    // calculate winnings
                    if (BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].choice == winningResult && 
                        BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].typeOfNFT == 1) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].amount;
                            owed += (topiaBetOnThisNFT * 5) / 4;

                    } else if (BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].choice == winningResult && 
                               BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].typeOfNFT == 2) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].amount;
                            owed += (topiaBetOnThisNFT * 3) / 2;

                    } else if (BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].choice == winningResult && 
                               BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].typeOfNFT == 3) {
                            // get how much topia was bet on this NFT id in this session
                            uint256 topiaBetOnThisNFT = BetNFTInfo[BetNFTsPerEncierro[msg.sender][i][z]][i].amount;
                            owed += (topiaBetOnThisNFT * 2);
                    } else {
                        continue;
                    }
                }
                HasClaimed[msg.sender][i] = true;
            } else {
                continue;
            }
        }

        TopiaInterface.mint(msg.sender, owed);
        HubInterface.emitTopiaClaimed(msg.sender, owed);
        emit BetRewardClaimed(msg.sender, owed);
    }

    function getUserNFTsPerEncierro(address account, uint256 _id) external view returns (uint16[] memory tokenIds) {
        uint256 length = BetNFTsPerEncierro[account][_id].length;
        tokenIds = new uint16[](length);
        for(uint i = 0; i < length; i++) {
            tokenIds[i] = BetNFTsPerEncierro[account][_id][i];
        }
    }

    // STAKING FUNCTIONS ----------------------------------------------------

    function stakeMany(uint16[] calldata _tokenIds) external nonReentrant {
        require(msg.sender == tx.origin, "account to send mismatch");
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(Genesis.ownerOf(_tokenIds[i]) == msg.sender, "not owner");

            if (NFTType[_tokenIds[i]] == 1) {
                stakeRunner(_tokenIds[i]);
            } else if (NFTType[_tokenIds[i]] == 2) {
                stakeBull(_tokenIds[i]);
            } else if (NFTType[_tokenIds[i]] == 3) {
                stakeMatador(_tokenIds[i]);
            } else if (NFTType[_tokenIds[i]] == 0) {
                revert("invalid NFT");
            }

        }
        HubInterface.emitGenesisStaked(msg.sender, _tokenIds, 4);
    }

    function stakeRunner(uint16 tokenID) internal {

        IsNFTStaked[tokenID] = true;
        StakedTokensOfWallet[msg.sender].add(tokenID);
        StakedNFTInfo[tokenID].tokenID = tokenID;
        StakedNFTInfo[tokenID].owner = msg.sender;
        StakedNFTInfo[tokenID].stakeTimestamp = uint80(block.timestamp);
        StakedNFTInfo[tokenID].value = uint80(block.timestamp);
        StakedNFTInfo[tokenID].typeOfNFT = 1;
        Genesis.safeTransferFrom(msg.sender, address(this), tokenID);

        stakedRunners++;
        NumberOfStakedNFTs[msg.sender]++;
        emit RunnerStaked(msg.sender, tokenID);     
    }

    function stakeBull(uint16 tokenID) internal {
        
        IsNFTStaked[tokenID] = true;
        StakedTokensOfWallet[msg.sender].add(tokenID);
        StakedNFTInfo[tokenID].tokenID = tokenID;
        StakedNFTInfo[tokenID].owner = msg.sender;
        StakedNFTInfo[tokenID].stakeTimestamp = uint80(block.timestamp);
        StakedNFTInfo[tokenID].value = uint80(block.timestamp);
        StakedNFTInfo[tokenID].typeOfNFT = 2;
        Genesis.safeTransferFrom(msg.sender, BullpenContract, tokenID); // bulls go to the pen
        BullpenInterface.receiveBull(msg.sender, tokenID); // tell the bullpen they're getting a new bull

        stakedBulls++;
        NumberOfStakedNFTs[msg.sender]++;
        emit BullStaked(msg.sender, tokenID);    
    }

    function stakeMatador(uint16 tokenID) internal {

        IsNFTStaked[tokenID] = true;
        StakedTokensOfWallet[msg.sender].add(tokenID);
        MatadorsStakedPerWallet[msg.sender].add(tokenID);
        StakedNFTInfo[tokenID].tokenID = tokenID;
        StakedNFTInfo[tokenID].owner = msg.sender;
        StakedNFTInfo[tokenID].stakeTimestamp = uint80(block.timestamp);
        StakedNFTInfo[tokenID].typeOfNFT = 3;
        StakedNFTInfo[tokenID].value = TOPIAPerMatador; // for matadors only
        Genesis.safeTransferFrom(msg.sender, ArenaContract, tokenID); // matadors go to the arena
        ArenaInterface.receiveMatador(msg.sender, tokenID); // tell the arena they are receiving a new matador

        stakedMatadors++;
        NumberOfStakedNFTs[msg.sender]++;
        emit MatadorStaked(msg.sender, tokenID);   
    }

    function claimRunner(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed, uint16 stolenId) {
        require(StakedNFTInfo[tokenId].owner == msg.sender, "not owner");
        require(block.timestamp - StakedNFTInfo[tokenId].stakeTimestamp > minimumStakeTime, "Must wait minimum stake time");
        stolenId = 0;
        
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
            StakedTokensOfWallet[msg.sender].remove(tokenId);

            if (BullpenInterface.bullCount() > 0 && (seed % 100) < Risk[1]) { 
                // nft gets stolen
                address thief = BullpenInterface.selectRandomBullOwnerToReceiveStolenRunner(seed);
                Genesis.safeTransferFrom(address(this), thief, tokenId);
                stolenId = tokenId;
                emit RunnerStolen(msg.sender, thief);
            } else {
                Genesis.safeTransferFrom(address(this), msg.sender, tokenId);
                emit RunnerUnstaked(msg.sender, tokenId);
            }
            
            stakedRunners--;
            NumberOfStakedNFTs[msg.sender]--;
        } else {
            StakedNFTInfo[tokenId].value = uint80(block.timestamp); // reset the stakeTime for this NFT
        }
    }

    function claimBull(uint16 tokenId, bool unstake, uint256 seed) internal returns (uint256 owed, uint16 stolenId) {
        require(StakedNFTInfo[tokenId].owner == msg.sender, "not owner");
        require(block.timestamp - StakedNFTInfo[tokenId].stakeTimestamp > minimumStakeTime, "Must wait minimum stake time");
        stolenId = 0;
        
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
            StakedTokensOfWallet[msg.sender].remove(tokenId);

            if (ArenaInterface.matadorCount() > 0 && (seed % 100) < Risk[2]) { 
                // nft gets stolen
                address thief = ArenaInterface.selectRandomMatadorOwnerToReceiveStolenBull(seed);
                BullpenInterface.stealBull(thief, tokenId);
                stolenId = tokenId;
                emit BullStolen(msg.sender, thief);
            } else {
                BullpenInterface.returnBullToOwner(msg.sender, tokenId);
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
        require(block.timestamp - StakedNFTInfo[tokenID].stakeTimestamp > minimumStakeTime, "Must wait minimum stake time");

        owed += (TOPIAPerMatador - StakedNFTInfo[tokenID].value);

        if(unstake) {
            IsNFTStaked[tokenID] = false;
            delete StakedNFTInfo[tokenID]; // reset the struct for this token ID
            StakedTokensOfWallet[msg.sender].remove(tokenID);
            MatadorsStakedPerWallet[msg.sender].remove(tokenID);
            ArenaInterface.returnMatadorToOwner(msg.sender, tokenID);

            stakedMatadors--;
            NumberOfStakedNFTs[msg.sender]--;
            emit MatadorUnstaked(msg.sender, tokenID);
        } else {
            StakedNFTInfo[tokenID].value = TOPIAPerMatador;
        }
    }

    function stakeManyAlphas(uint16[] calldata _tokenIds) external nonReentrant {
        require(tx.origin == msg.sender, "Only EOA");
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(Alpha.ownerOf(_tokenIds[i]) == msg.sender, "not owner");
            
            IsAlphaStaked[_tokenIds[i]] = true;
            StakedAlphasOfWallet[msg.sender].add(_tokenIds[i]);
            StakedAlphaInfo[_tokenIds[i]].tokenID = _tokenIds[i];
            StakedAlphaInfo[_tokenIds[i]].owner = msg.sender;
            StakedAlphaInfo[_tokenIds[i]].stakeTimestamp = uint80(block.timestamp);
            StakedAlphaInfo[_tokenIds[i]].value = uint80(block.timestamp);
            StakedAlphaInfo[_tokenIds[i]].typeOfNFT = 0;
            Alpha.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);

            stakedAlphas++;
            NumberOfStakedAlphas[msg.sender]++;
            emit AlphaStaked(msg.sender, _tokenIds[i]);
            }
        
        HubInterface.emitAlphaStaked(msg.sender, _tokenIds, 4);
    }

    function getUnclaimedAlpha(uint16 tokenId) external view returns (uint256) {
        return (block.timestamp - StakedAlphaInfo[tokenId].value) * alphaRewardMult / PERIOD;
    }

    function getUnclaimedGenesis(uint16 tokenId) external view returns (uint256 owed) {
        if (!IsNFTStaked[tokenId]) { return 0; }
        if (NFTType[tokenId] == 1) {
            if(block.timestamp <= claimEndTime) {
                owed = (block.timestamp - StakedNFTInfo[tokenId].value) * runnerRewardMult / PERIOD;
            } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
                owed = (claimEndTime - StakedNFTInfo[tokenId].value) * runnerRewardMult / PERIOD;
            } else {
                owed = 0;
            }
        } else if (NFTType[tokenId] == 2) {
            if(block.timestamp <= claimEndTime) {
                owed = (block.timestamp - StakedNFTInfo[tokenId].value) * bullRewardMult / PERIOD;
            } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
                owed = (claimEndTime - StakedNFTInfo[tokenId].value) * bullRewardMult / PERIOD;
            } else {
                owed = 0;
            }
        } else if (NFTType[tokenId] == 3) {
            owed = (TOPIAPerMatador - StakedNFTInfo[tokenId].value);
        }
        return owed;
    }

    function getUnclaimedTopiaForUser(address _account) external view returns (uint256) {
        uint256 owed;
        uint256 genesisLength = StakedTokensOfWallet[_account].length();
        uint256 alphaLength = StakedAlphasOfWallet[_account].length();
        
        for (uint i = 0; i < genesisLength; i++) {
            uint16 tokenId = uint16(StakedTokensOfWallet[_account].at(i));
            if (NFTType[tokenId] == 1) {
                if(block.timestamp <= claimEndTime) {
                    owed += (block.timestamp - StakedNFTInfo[tokenId].value) * runnerRewardMult / PERIOD;
                } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
                    owed += (claimEndTime - StakedNFTInfo[tokenId].value) * runnerRewardMult / PERIOD;
                } else {
                    owed += 0;
                }
            } else if (NFTType[tokenId] == 2) {
                if(block.timestamp <= claimEndTime) {
                    owed += (block.timestamp - StakedNFTInfo[tokenId].value) * bullRewardMult / PERIOD;
                } else if (StakedNFTInfo[tokenId].value < claimEndTime) {
                    owed += (claimEndTime - StakedNFTInfo[tokenId].value) * bullRewardMult / PERIOD;
                } else {
                    owed += 0;
                }
            } else if (NFTType[tokenId] == 3) {
                owed += (TOPIAPerMatador - StakedNFTInfo[tokenId].value);
            } else if (NFTType[tokenId] == 0) {
                continue;
            }
        }
        for (uint i = 0; i < alphaLength; i++) {
            uint16 tokenId = uint16(StakedAlphasOfWallet[_account].at(i));
            owed += (block.timestamp - StakedAlphaInfo[tokenId].value) * alphaRewardMult / PERIOD;
        }

        return owed;
    }

    function getStakedGenesisForUser(address _account) external view returns (uint16[] memory stakedGensis) {
        uint256 length = StakedTokensOfWallet[_account].length();
        stakedGensis = new uint16[](length);
        for (uint i = 0; i < length; i++) {
            stakedGensis[i] = uint16(StakedTokensOfWallet[_account].at(i));
        }
    }

    function getStakedAlphasForUser(address _account) external view returns (uint16[] memory _stakedAlphas) {
        uint256 length = StakedAlphasOfWallet[_account].length();
        _stakedAlphas = new uint16[](length);
        for (uint i = 0; i < length; i++) {
            _stakedAlphas[i] = uint16(StakedAlphasOfWallet[_account].at(i));
        }
    }

    // BET FUNCTIONS ----------------------------------------------------

    // @param: choice is FOR ALL NFTS being passed. Each NFT ID gets assigned the same choice (0 = bulls, 1 = runners)
    // @param: betAmount is PER NFT. If 10 NFTs are bet, and amount passed in is 10 TOPIA, total is 100 TOPIA BET
    function betMany(uint16[] calldata _tokenIds, uint256 _encierroId, uint256 _betAmount, uint8 _choice) external 
    nonReentrant {
        require(Encierros[_encierroId].endTime > block.timestamp , "Betting has ended");
        require(_encierroId <= currentEncierroId, "Non-existent encierro id!");
        require(TopiaInterface.balanceOf(address(msg.sender)) >= (_betAmount * _tokenIds.length), "not enough TOPIA");
        require(_choice == 1 || _choice == 0, "Invalid choice");
        require(Encierros[_encierroId].status == Status.Open, "not open");
        require(_betAmount >= Encierros[_encierroId].minBet && _betAmount <= Encierros[_encierroId].maxBet, "Bet not within limits");

        uint16 numberOfNFTs = uint16(_tokenIds.length);
        uint256 totalBet = _betAmount * numberOfNFTs;
        for (uint i = 0; i < numberOfNFTs; i++) {
            require(StakedNFTInfo[_tokenIds[i]].owner == msg.sender, "not owner");

            if (NFTType[_tokenIds[i]] == 1) {
                betRunner(_tokenIds[i], _encierroId, _betAmount, _choice);
            } else if (NFTType[_tokenIds[i]] == 2) {
                betBull(_tokenIds[i], _encierroId, _betAmount, _choice);
            } else if (NFTType[_tokenIds[i]] == 3) {
                betMatador(_tokenIds[i], _encierroId, _betAmount, _choice);
            } else if (NFTType[_tokenIds[i]] == 0) {
                continue;
            }

        Encierros[_encierroId].totalTopiaCollected += totalBet;
        
        if (_choice == 0) {
            Encierros[_encierroId].numberOfBetsOnBullsWinning += numberOfNFTs; // increase the number of bets on bulls winning by # of NFTs being bet
            Encierros[_encierroId].topiaBetOnBulls += totalBet; // multiply the bet amount per NFT by the number of NFTs
        } else {
            Encierros[_encierroId].numberOfBetsOnRunnersWinning += numberOfNFTs; // increase number of bets on runners...
            Encierros[_encierroId].topiaBetOnRunners += totalBet;
        }

        if (!HasBet[msg.sender][_encierroId]) {
            HasBet[msg.sender][_encierroId] = true;
            EnteredEncierros[msg.sender].push(_encierroId);
        }
        TopiaInterface.burnFrom(msg.sender, totalBet);
        emit BetPlaced(msg.sender, _encierroId, totalBet, _choice, _tokenIds);
        }
    }

    function betRunner(uint16 _runnerID, uint256 _encierroId, uint256 _betAmount, uint8 _choice) internal {

        require(IsNFTStaked[_runnerID] , "not staked");
        require(StakedNFTInfo[_runnerID].owner == msg.sender , "not owner");
        BetNFTsPerEncierro[msg.sender][_encierroId].push(_runnerID); // add the token IDs being bet to their personal mapping for this session
        BetNFTInfo[_runnerID][_encierroId].player = msg.sender; // map bet token id to caller for this session
        BetNFTInfo[_runnerID][_encierroId].amount = _betAmount; // map bet token id to bet amount for this session
        BetNFTInfo[_runnerID][_encierroId].choice = _choice; // map bet token id to choice for this session
        BetNFTInfo[_runnerID][_encierroId].tokenID = _runnerID; // map bet token id to struct id for this session
        BetNFTInfo[_runnerID][_encierroId].typeOfNFT = 1; // 1 = runner

        Encierros[_encierroId].topiaBetByRunners += _betAmount;
        Encierros[_encierroId].numRunners++;
    }

    function betBull(uint16 _bullID, uint256 _encierroId, uint256 _betAmount, uint8 _choice) internal {

        require(IsNFTStaked[_bullID] , "not staked");
        require(StakedNFTInfo[_bullID].owner == msg.sender , "not owner");
        BetNFTsPerEncierro[msg.sender][_encierroId].push(_bullID); // add the token IDs being bet to their personal mapping for this session
        BetNFTInfo[_bullID][_encierroId].player = msg.sender; // map bet token id to caller for this session
        BetNFTInfo[_bullID][_encierroId].amount = _betAmount; // map bet token id to bet amount for this session
        BetNFTInfo[_bullID][_encierroId].choice = _choice; // map bet token id to choice for this session
        BetNFTInfo[_bullID][_encierroId].tokenID = _bullID; // map bet token id to struct id for this session
        BetNFTInfo[_bullID][_encierroId].typeOfNFT = 2; // 2 = bull

        Encierros[_encierroId].topiaBetByBulls += _betAmount;
        Encierros[_encierroId].numBulls++;
    }

    function betMatador(uint16 _matadorID, uint256 _encierroId, uint256 _betAmount, uint8 _choice) internal {

        require(IsNFTStaked[_matadorID] , "not staked");
        require(StakedNFTInfo[_matadorID].owner == msg.sender , "not owner");
        BetNFTsPerEncierro[msg.sender][_encierroId].push(_matadorID); // add the token IDs being bet to their personal mapping for this session
        BetNFTInfo[_matadorID][_encierroId].player = msg.sender; // map bet token id to caller for this session
        BetNFTInfo[_matadorID][_encierroId].amount = _betAmount; // map bet token id to bet amount for this session
        BetNFTInfo[_matadorID][_encierroId].choice = _choice; // map bet token id to choice for this session
        BetNFTInfo[_matadorID][_encierroId].tokenID = _matadorID; // map bet token id to struct id for this session
        BetNFTInfo[_matadorID][_encierroId].typeOfNFT = 3; // 3 = matador

        Encierros[_encierroId].topiaBetByMatadors += _betAmount;
        Encierros[_encierroId].numMatadors++;
    }

    // Encierro SESSION LOGIC ---------------------------------------------------- 

    function startEncierro(
        uint256 _endTime,
        uint256 _minBet,
        uint256 _maxBet) 
        external
        payable
        nonReentrant
        {
        require(
            (currentEncierroId == 0) || 
            (Encierros[currentEncierroId].status == Status.Claimable), "session not claimable");

        require(((_endTime - block.timestamp) >= minDuration) && ((_endTime - block.timestamp) <= maxDuration), "invalid time");
        require(msg.value == SEED_COST, "seed cost not met");

        currentEncierroId++;

        Encierros[currentEncierroId] = Encierro({
            status: Status.Open,
            encierroId: currentEncierroId,
            startTime: block.timestamp,
            endTime: _endTime,
            minBet: _minBet,
            maxBet: _maxBet,
            numRunners: 0,
            numBulls: 0,
            numMatadors: 0,
            numberOfBetsOnRunnersWinning: 0,
            numberOfBetsOnBullsWinning: 0,
            topiaBetByRunners: 0,
            topiaBetByBulls: 0,
            topiaBetByMatadors: 0,
            topiaBetOnRunners: 0,
            topiaBetOnBulls: 0,
            totalTopiaCollected: 0,
            flipResult: 2 // init to 2 to avoid conflict with 0 (bulls) or 1 (runners). is set to 0 or 1 later depending on coin flip result.
        });

        RandomizerContract.transfer(msg.value);
        
        emit EncierroOpened(
            currentEncierroId,
            block.timestamp,
            _endTime,
            _minBet,
            _maxBet
        );
    }

    // bulls = 0, runners = 1
    function closeEncierro(uint256 _encierroId) external nonReentrant {
        require(Encierros[_encierroId].status == Status.Open , "must be open first");
        require(block.timestamp > Encierros[_encierroId].endTime, "not over yet");
        MetatopiaCoinFlipRNGInterface.requestRandomWords();
        Encierros[_encierroId].status = Status.Closed;
        emit EncierroClosed(
            _encierroId,
            block.timestamp,
            Encierros[_encierroId].numRunners,
            Encierros[_encierroId].numBulls,
            Encierros[_encierroId].numMatadors,
            Encierros[_encierroId].numberOfBetsOnRunnersWinning,
            Encierros[_encierroId].numberOfBetsOnBullsWinning,
            Encierros[_encierroId].topiaBetByRunners,
            Encierros[_encierroId].topiaBetByBulls,
            Encierros[_encierroId].topiaBetByMatadors,
            Encierros[_encierroId].topiaBetOnRunners,
            Encierros[_encierroId].topiaBetOnBulls,
            Encierros[_encierroId].totalTopiaCollected
        );
    }

    /**
     * add $TOPIA to claimable pot for the Matador Yield
     * @param amount $TOPIA to add to the pot
   */
    function _payMatadorTax(uint256 amount) internal {
        if (stakedMatadors == 0) {// if there's no staked matadors
            unaccountedMatadorRewards += amount;
            return;
        }
        TOPIAPerMatador += (amount + unaccountedMatadorRewards) / stakedMatadors;
        unaccountedMatadorRewards = 0;
    }

    function flipCoinAndMakeClaimable(uint256 _encierroId) external nonReentrant notContract() returns (uint256) {
        require(_encierroId <= currentEncierroId , "Nonexistent session!");
        require(Encierros[_encierroId].status == Status.Closed , "must be closed first");
        uint256 encierroFlipResult = _flipCoin();
        Encierros[_encierroId].flipResult = encierroFlipResult;

        if (encierroFlipResult == 0) { // if bulls win
            uint256 amountToMatadors = (Encierros[_encierroId].topiaBetOnRunners * matadorCut) / 10000;
            _payMatadorTax(amountToMatadors);
        } else { // if runners win
            uint256 amountToMatadors = (Encierros[_encierroId].topiaBetOnBulls * matadorCut) / 10000;
            _payMatadorTax(amountToMatadors);
        }

        Encierros[_encierroId].status = Status.Claimable;
        return encierroFlipResult;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IHub {
    function emitGenesisStaked(address owner, uint16[] calldata tokenIds, uint8 gameId) external;
    function emitAlphaStaked(address owner, uint16[] calldata tokenIds, uint8 gameId) external;
    function emitGenesisUnstaked(address owner, uint16[] calldata tokenIds) external;
    function emitAlphaUnstaked(address owner, uint16[] calldata tokenIds) external;
    function emitTopiaClaimed(address owner, uint256 amount) external;
    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRandomizer {

    function requestRandomWords() external;
    function getRandomWords(uint256 number) external returns (uint256[] memory);
    function getRemainingWords() external view returns (uint256);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IArena {
    
    function matadorCount() external view returns (uint16);
    function receiveMatador(address _originalOwner, uint16 _id) external;
    function returnMatadorToOwner(address _returnee, uint16 _id) external;
    function getMatadorOwner(uint16 _id) external view returns (address);
    function selectRandomMatadorOwnerToReceiveStolenBull(uint256 seed) external view returns (address);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBullpen {
    
    function bullCount() external view returns (uint16);
    function receiveBull(address _originalOwner, uint16 _id) external;
    function returnBullToOwner(address _returnee, uint16 _id) external;
    function getBullOwner(uint16 _id) external view returns (address);
    function selectRandomBullOwnerToReceiveStolenRunner(uint256 seed) external returns (address);
    function stealBull(address _thief, uint16 _id) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITopia {

    function burn(uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;  
    function burnFrom(address _from, uint256 _amount) external;
    function decimals() external pure returns (uint8);
    function balanceOf(address owner) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMetatopiaCoinFlipRNG {
    
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
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