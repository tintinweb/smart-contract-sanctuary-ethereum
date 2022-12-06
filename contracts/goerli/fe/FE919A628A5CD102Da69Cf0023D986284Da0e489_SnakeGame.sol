// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///////////////
//  Imports  //
///////////////
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./tokens/Token.sol";
import "./tokens/Nft.sol";

//////////////
//  Errors  //
//////////////
error SnakeGame__GameAlreadyStarted();
error SnakeGame__TransferFailed(address recipient);
error SnakeGame__SnakeBalanceTooLow(uint256 snakeBalance);
error SnakeGame__GameNotStarted();
error SnakeGame__SnakeAirdopAlreadyReceived();
error SnakeGame__NotEnoughCurrencySent(uint256 sentAmount, uint256 requiredAmount);
error SnakeGame__NoSuperNftToClaim();
error SnakeGame__NotEnoughMintFeeSent(uint256 mintFeeSent, uint256 mintFeeRequied);
error SnakeGame__SnakeNftBalanceTooLow(uint256 snakeNftBalance, uint256 requiredSnakeNftBalance);

////////////////////
// Smart Contract //
////////////////////

/**
 * @title SnakeGame contract
 * @author Dariusz Setlak
 * @notice The main Snake Game Smart Contract
 * @dev The main smart contract of Snake Game Dapp containing the following functions:
 * Deployment Functions: createToken, createNft
 * Game functions: finishRound, gameStart, gameOver
 * Token functions: snakeAirdrop, buySnake
 * NFT functions: _mintSnakeNft, mintSuperPetNft, _burnSnakeNfts, _checkSuperPetNft, _mintSuperPetNft
 * Private functions: _gameFeeCalculation, _randomNumber
 * Getter functions: getGameRound, getHighestScoreEver, getGamesPlayedTotal, getGameRoundData, getPlayerData,
 * getBalance, getRandomNumber
 * Other functions: receive, fallback
 */
contract SnakeGame is Ownable, ReentrancyGuard {
    //////////////
    //  Events  //
    //////////////
    event GameStarted(address indexed player);
    event GameOver(address indexed player);
    event SnakeAirdropReceived(address indexed player, uint256 indexed snakeAmount);
    event SnakeTokensBought(address indexed player, uint256 indexed snakeAmount);
    event SnakeNftMinted(address indexed player);
    event SuperPetNftUnlocked(address indexed player);
    event SuperPetNftMinted(address indexed player);
    event TransferReceived(uint256 indexed amount);

    ///////////////
    //  Scructs  //
    ///////////////

    /**
     * @dev Struct of Game round parameters.
     * uint32 roundGamesPlayed - the number of games played in this round (sum of all Player's played games)
     * uint32 roundHighestScore - the highest game score in this round
     * address roundBestPlayer - address of the Player with the highest score in this round
     */
    struct GameRoundData {
        uint32 roundGamesPlayed;
        uint32 roundHighestScore;
        address roundBestPlayer;
    }

    /**
     * @dev Struct of Player's gameplay parameters.
     * bool snakeAirdropFlag - the status of free SNAKE tokens airdrop: false - not received, true - received.
     * bool gameStartedFlag - the game running status: false - game not started (or finished), true - game started.
     * bool superPetNftClaimFlag - the Super Pet NFT claim status: 0 - nothing to claim, 1 - claim avaliable
     * uint32 playerGamesPlayed - the total number of games played by the Player so far
     * uint32 playerLastScore - the last game score
     * uint32 playerBestScore - the highest Player's score ever
     * uint32 mintedSnakeNfts - the number of Snake NFTs minted by the Player at all
     * uint32 mintedSuperPetNfts - the number of Super Pet NFTs minted by the Player at all
     */
    struct PlayerData {
        bool snakeAirdropFlag;
        bool gameStartedFlag;
        bool superPetNftClaimFlag;
        uint32 playerGamesPlayed;
        uint32 playerLastScore;
        uint32 playerBestScore;
        uint32 mintedSnakeNfts;
        uint32 mintedSuperPetNfts;
    }

    ////////////////
    //  Mappings  //
    ////////////////

    /// @dev Mapping Game round consecutive number to game's current round parameters struct.
    mapping(uint32 => GameRoundData) public s_gameRounds;

    /// @dev Mapping Player's address to Player's game parameters struct.
    mapping(address => PlayerData) public s_players;

    //////////////////////
    // Global variables //
    //////////////////////

    /// @dev The total number of players
    uint64 private s_playersNumberTotal;

    /// @dev The total number of played games
    uint64 private s_gamesPlayedTotal;

    /// @dev The Game highest score ever
    uint32 private s_highestScoreEver;

    /// @dev The Player's address with the Game highest score ever
    address private s_bestPlayerEver;

    /// @dev Current Game round (Game round counter)
    uint32 private s_currentRound;

    ////////////////////////
    // Contract variables //
    ////////////////////////

    /// @dev Deployed Token contract instance `SnakeToken`.
    Token public immutable i_snakeToken;

    /// @dev Deployed Nft contract instance `SnakeNft`.
    Nft public immutable i_snakeNft;

    /// @dev Deployed Nft contract instance `SuperPetNft`.
    Nft public immutable i_superPetNft;

    /////////////////////////
    // Immutable variables //
    /////////////////////////

    /// @dev Minimum game score required to mint Snake NFT [SNFT].
    uint32 public immutable i_scoreRequired; // default: 100

    /// @dev Minimum balance of Snake NFT [SNFT] required to unlock Super Pet NFT [SPET].
    uint32 public immutable i_snakeNftRequired; // default: 5

    /**
     * @dev SNAKE token exchange rate. Depends on the type of deployment network:
     * Ethereum TESTNET Goerli: 1 ETH => 100 SNAKE, 0.01 ETH => 1 SNAKE = about $12 (11.2022)
     * Polygon TESTNET Mumbai: 1 MATIC => 0.1 SNAKE, 10 MATIC => 1 SNAKE = about $9 (11.2022)
     */
    uint256 public immutable i_snakeExchangeRate; // default: ETH - 1e16 = 0.01, MATIC - 1e19 = 1

    /**
     * @dev Mint fee in ETH required to mint Super Pet NFT. Depends on the type of deployment network:
     * Ethereum TESTNET Goerli: 0.1 ETH = about $120 (11.2022)
     * Polygon TESTNET Mumbai: 10 MATIC = about $9 (11.2022)
     */
    uint256 public immutable i_superPetNftMintFee; // default: ETH - 1e17 = 0.1, MATIC - 1e19 = 10

    ////////////////////////
    // Constant variables //
    ////////////////////////

    /// @dev SNAKE tokens airdrop amount
    uint32 public constant SNAKE_AIRDROP = 12;

    /// @dev Game base fee paid in SNAKE tokens.
    uint32 public constant GAME_BASE_FEE = 4;

    /// @dev Maximum number of Snake NFT tokens possible to mint in the Game by one Player.
    uint32 public constant MAX_SNAKE_NFTS = 18;

    /// @dev Maximum number of Super Pet NFT tokens possible to mint in the Game by one Player.
    uint32 public constant MAX_SUPER_PET_NFTS = 3;

    /// @dev Developer account address.
    address public constant DEV = 0xEb79FD91fc34F9A74c5A046eB0c88a20B9D8f778;

    ///////////////////
    //  Constructor  //
    ///////////////////

    /**
     * @dev SnakeGame contract constructor. Sets given parameters to appropriate variables, when contract deploys.
     * // NFT Tokens URI data arrays
     * @param snakeNftUris given uris array parameter to create Snake NFT using `Nft` contract
     * @param superPetNftUris given uris array parameter to create Super Pet NFT using `Nft` contract
     * // Game immutable parameters
     * @param scoreRequired given minimum game score required to mint Snake NFT
     * @param snakeNftRequired given minimum balance of Snake NFT [SNFT] required to unlock Super Pet NFT [SPET].
     * @param snakeExchangeRate given SNAKE token exchange rate, depends on the type of deployment network
     * @param superPetNftMintFee given mint fee in native blockchain currency required to mint Super Pet NFT,
     * depends on the type of deployment network
     */
    constructor(
        // NFT Tokens URI data arrays
        string[] memory snakeNftUris,
        string[] memory superPetNftUris,
        // Game immutable parameters
        uint32 scoreRequired,
        uint32 snakeNftRequired,
        uint256 snakeExchangeRate,
        uint256 superPetNftMintFee
    ) {
        // Create game tokens
        i_snakeToken = createToken("Snake Token", "SNAKE");
        i_snakeNft = createNft("Snake NFT", "SNFT", snakeNftUris);
        i_superPetNft = createNft("Super Pet NFT", "SPET", superPetNftUris);
        // Set game immutable parameters
        i_scoreRequired = scoreRequired;
        i_snakeNftRequired = snakeNftRequired;
        i_snakeExchangeRate = snakeExchangeRate;
        i_superPetNftMintFee = superPetNftMintFee;
        // Set current game round as a first round
        s_currentRound = 1;
    }

    //////////////////////////
    // Deployment Functions //
    //////////////////////////

    /**
     * @dev Function deploys `Token` contract and using given constructor parameters creates contract instance,
     * which is a standard ERC-20 token implementation.
     * @param _name token name constructor parameter
     * @param _symbol token symbol constructor parameter
     */
    function createToken(string memory _name, string memory _symbol) private returns (Token) {
        Token token = new Token(_name, _symbol);
        return token;
    }

    /**
     * @dev Function deploys `Nft` contract and using given constructor parameters creates contract instance,
     * which is a standard ERC-721 token implementation.
     * @param _name token name constructor parameter
     * @param _symbol token symbol constructor parameter
     * @param _uris token uris array constructor parameter
     */
    function createNft(
        string memory _name,
        string memory _symbol,
        string[] memory _uris
    ) private returns (Nft) {
        Nft nft = new Nft(_name, _symbol, _uris);
        return nft;
    }

    ////////////////////
    // Game Functions //
    ////////////////////

    /**
     * @notice Function to start the game.
     * @dev Function allows Player to pay for the game and start the game.
     * This is an external function called by the Player, using front-end application.
     *
     * Function execution:
     * 1) Check if Player hasn't already started the Game before.
     * 2) Call private function _gameFeeCalculation to calculate Player's game fee.
     * 3) Check if Player's SNAKE tokens balance is enough to pay gameFee, if not then transaction reverts.
     * 4) Transfer gameFee in SNAKE tokens to `SnakeGame` contract.
     * 5) Set Player's parameter gameStartedFlag to true.
     * 6) Burn gameFee amount of SNAKE tokens from Player's account.
     * 7) Emit an event GameStarted.
     *
     * Function is protected from reentrancy attack, by using nonReentrant modifier from OpenZeppelin library.
     */
    function gameStart() external nonReentrant {
        // Check if Player hasn't already started the Game before
        if (s_players[msg.sender].gameStartedFlag == true) {
            revert SnakeGame__GameAlreadyStarted();
        }
        uint256 snakeBalance = i_snakeToken.balanceOf(msg.sender);
        uint256 gameFee = gameFeeCalculation(msg.sender);
        // Check if Player has enough SNAKE tokens to pay game fee
        if (snakeBalance < gameFee) {
            revert SnakeGame__SnakeBalanceTooLow(snakeBalance);
        }
        // Switch gameStartedFlag parameter to true
        s_players[msg.sender].gameStartedFlag = true;
        // Burn gameFee amount of SNAKE tokens from Player's account
        i_snakeToken.burnFrom(msg.sender, gameFee);
        emit GameStarted(msg.sender);
    }

    /**
     * @notice Function to end the current game.
     * @dev Function allows Player to pay for the Game and start the Game.
     * This is an external function called by the Player, using front-end application.
     *
     * IMPORTANT: Player can't save high score if game was played using airdropped SNAKE tokens, even
     * if it was the highest score! That forces every Player to pay for a game at least once to be able
     * to win the highest score prize when the Game round ends. SNAKE airdrop token's purpose is to use
     * them to learn how to play, not to use them for competition in the game to win the prize.
     *
     * Function execution:
     * 1) Check if Player started the game before call gameOver function.
     * 2) Update Player's game parameters: gameStartedFlag, playerGamesPlayed, playerLastScore and playerBestScore.
     * 3) Update Game round parameters: roundGamesPlayed, roundBestPlayer and roundHighestScore
     * 4) Mint Snake NFT if the game score is at least `i_scoreRequired`.
     * 5) Call private function to check Super Pet NFT mint eligibility.
     * 6) Emit an event GameOver.
     *
     * Function is protected from reentrancy attack, by using nonReentrant modifier from OpenZeppelin library.
     */
    function gameOver(uint32 _score) external nonReentrant {
        // Check if Player started the game before
        if (s_players[msg.sender].gameStartedFlag != true) {
            revert SnakeGame__GameNotStarted();
        }
        // Update Player's game parameters: gameStartedFlag, playerGamesPlayed, playerLastScore and playerBestScore
        s_players[msg.sender].gameStartedFlag = false;
        s_players[msg.sender].playerGamesPlayed++;
        s_players[msg.sender].playerLastScore = _score;
        if (_score > s_players[msg.sender].playerBestScore) {
            s_players[msg.sender].playerBestScore = _score;
        }
        // Update Game round parameters: roundGamesPlayed
        s_gameRounds[s_currentRound].roundGamesPlayed++;
        // IMPORTANT: Player can't save high score and mint Snake NFT, if game was played using airdropped SNAKE tokens
        if (
            (s_players[msg.sender].snakeAirdropFlag == false) ||
            (s_players[msg.sender].snakeAirdropFlag == true && s_players[msg.sender].playerGamesPlayed > 3)
        ) {
            // Update Game round parameters: roundBestPlayer and roundHighestScore
            if (_score > s_gameRounds[s_currentRound].roundHighestScore) {
                s_gameRounds[s_currentRound].roundBestPlayer = msg.sender;
                s_gameRounds[s_currentRound].roundHighestScore = _score;
            }
            // Mint Snake NFT if the conditions are met: required score and under Snake NFT mint limit.
            if (_score >= i_scoreRequired) {
                _mintSnakeNft(msg.sender);
            }
        }
        // Check Super Pet NFT mint eligibility
        _checkSuperPetNft(msg.sender);
        //
        emit GameOver(msg.sender);
    }

    /**
     * @notice Function to automaticly operate game rounds, pick the best player to send him a prize.
     * @dev Function to automaticly operate Game rounds by using Chainlink Automation time-based trigger
     * mechanism. The time of execution is immutable and set in variable i_roundDuration.
     * This is an external function called by Chainlink Automation node, when the fixed time has passed.
     *
     * Function execution:
     * 1) Update global Game parameters: s_gamesPlayedTotal, s_highestScoreEver and s_bestPlayerEver.
     * 2) Set `SnakeGame` contract balance transfer amounts.
     * 3) Transfer prize to current best Player's account - 60% of current contract balance.
     * 4) Transfer prize to best ever Player's account - 30% of current contract balance.
     * 5) Transfer tip to developer's account - 10% of current contract balance.
     * 6) Update current Game round counter - next Game round START.
     *
     * Function is protected from reentrancy attack, by using nonReentrant modifier from OpenZeppelin library.
     */
    function finishRound() external nonReentrant {
        // Update global Game parameters: s_gamesPlayedTotal, s_highestScoreEver, s_bestPlayerEver
        // Update global number of played games parameter
        s_gamesPlayedTotal += s_gameRounds[s_currentRound].roundGamesPlayed;
        // Update global highest score ever and best Player's address parameters
        if (s_gameRounds[s_currentRound].roundHighestScore > s_highestScoreEver) {
            s_highestScoreEver = s_gameRounds[s_currentRound].roundHighestScore;
            s_bestPlayerEver = s_gameRounds[s_currentRound].roundBestPlayer;
        }
        // Set `SnakeGame` contract balance transfer amounts
        uint256 snakeGameBalance = address(this).balance;
        uint256 latestBestPlayerPrize = (snakeGameBalance / 10) * 7; // 70%
        uint256 bestPlayerEverPrize = (snakeGameBalance / 10) * 2; // 20%
        uint256 developerTip = snakeGameBalance / 10; // 10%
        // Current best Player prize transfer
        address currentBestPlayer = s_gameRounds[s_currentRound].roundBestPlayer;
        (bool successTransferCurrentBestPlayer, ) = currentBestPlayer.call{value: latestBestPlayerPrize}("");
        if (!successTransferCurrentBestPlayer) {
            revert SnakeGame__TransferFailed(currentBestPlayer);
        }
        // Best Player ever prize transfer
        address bestPlayerEver = s_bestPlayerEver;
        (bool successTransferBestPlayerEver, ) = bestPlayerEver.call{value: bestPlayerEverPrize}("");
        if (!successTransferBestPlayerEver) {
            revert SnakeGame__TransferFailed(bestPlayerEver);
        }
        // Developer tip transfer
        address developer = DEV;
        (bool successTransferDeveloperTip, ) = developer.call{value: developerTip}("");
        if (!successTransferDeveloperTip) {
            revert SnakeGame__TransferFailed(developer);
        }
        // Update current Game round counter
        s_currentRound++;
    }

    /////////////////////
    // Token Functions //
    /////////////////////

    /**
     * @notice Free SNAKE tokens airdrop for every new Player.
     * @dev Function allows every new Player claim for free SNAKE airdrop. Airdrop amount equals immutable
     * variable SNAKE_AIRDROP.
     * This is an external function called by the Player, using front-end application.
     *
     * Function execution:
     * 1) Check if Player already received SNAKE airdrop, if yes then transaction reverts.
     * 2) Mint SNAKE tokens to Player's account.
     * 3) Emit an event SnakeAirdropReceived.
     *
     * Function is protected from reentrancy attack, by using nonReentrant modifier from OpenZeppelin library.
     */
    function snakeAirdrop() external nonReentrant {
        // Check if Player already received SNAKE airdrop.
        if (s_players[msg.sender].snakeAirdropFlag == true) {
            revert SnakeGame__SnakeAirdopAlreadyReceived();
        }
        // Mint SNAKE tokens to Player's account
        s_players[msg.sender].snakeAirdropFlag = true;
        i_snakeToken.mint(msg.sender, SNAKE_AIRDROP);
        emit SnakeAirdropReceived(msg.sender, SNAKE_AIRDROP);
    }

    /**
     * @notice Buy SNAKE tokens for native blockchain currency.
     * @dev Function allows buy SNAKE tokens for native blockchain currency using fixed price. Exchange rate
     * is stored in an immutable variable i_snakeExchangeRate. This is a payable function, which allows Player
     * to send currency with function call.
     * This is an external function called by the Player, using front-end application.
     *
     * Function execution:
     * 1) Check if Player sent enough currency amount with function call, if not then transaction reverts.
     * 2) Mint bought amount of SNAKE tokens to Player's account.
     * 3) Emit an event SnakeTokensBought.
     *
     * Function is protected from reentrancy attack, by using nonReentrant modifier from OpenZeppelin library.
     *
     * @param _snakeAmount SNAKE tokens amount that Player wants to buy
     */
    function buySnake(uint256 _snakeAmount) public payable nonReentrant {
        uint256 payment = _snakeAmount * i_snakeExchangeRate;
        // Check if Player sent enough currency amount with function call.
        if (msg.value < payment) {
            revert SnakeGame__NotEnoughCurrencySent(msg.value, payment);
        }
        // Mint bought amount of SNAKE tokens to Player's account
        i_snakeToken.mint(msg.sender, _snakeAmount);
        emit SnakeTokensBought(msg.sender, _snakeAmount);
    }

    ///////////////////
    // NFT Functions //
    ///////////////////

    /**
     * @dev Function mints Snake NFT if Player reached required score and hasn't reached Snake NFT mint limit.
     * Private function called ONLY by this `SnakeGame` contract.
     * @param _player the Player's address
     */
    function _mintSnakeNft(address _player) private {
        // Check if Player hasn't already mint maximum number of Snake NFTs
        if (s_players[msg.sender].mintedSnakeNfts < MAX_SNAKE_NFTS) {
            // Random choice of Snake NFT URI's array index
            uint256 snakeNftUriIndex = _randomNumber(i_snakeNft.getNftUrisArrayLength());
            // Update Player's game parameter: number of minted Snake NFTs
            s_players[msg.sender].mintedSnakeNfts++;
            // SafeMint Snake NFT with randomly chosen URI data
            i_snakeNft.safeMint(_player, snakeNftUriIndex);
            emit SnakeNftMinted(_player);
        }
    }

    /**
     * @dev Function checks the Player's Super Pet NFT mint eligibility.
     * Private function called ONLY by this `SnakeGame` contract.
     * @param _player the Player's address
     */
    function _checkSuperPetNft(address _player) private {
        uint256 snakeNftBalance = i_snakeNft.balanceOf(_player);
        // Check maximum Super Pet NFTs mint limit && required Snake NFT balance
        if (s_players[_player].mintedSuperPetNfts < MAX_SUPER_PET_NFTS && snakeNftBalance >= i_snakeNftRequired) {
            s_players[_player].superPetNftClaimFlag = true;
            emit SuperPetNftUnlocked(_player);
        }
    }

    /**
     * @notice Function to mint Super Pet NFT.
     * @dev Function allows Player to mint Super Pet NFT if he met the conditions. This is a payable function,
     * which allows Player to send currency with function call.
     * This is an external function called by the Player, using front-end application.
     *
     * Function execution:
     * 1) Call private function to check Super Pet NFT mint eligibility.
     * 2) Check if Player has unlocked Super Pet NFT for minting.
     * 3) Check if Player has sent enough currency amount with function call, to pay Super Pet NFT mint fee.
     * If not then transaction reverts.
     * 4) Check if Player's Snake NFT balance is enough to pay Super Pet NFT mint fee (burn Snake NFTs).
     * If not then transaction reverts.
     * 5) Burn required amount of Snake NFTs as Super Pet NFT mint fee.
     * 6) Mint Super Pet NFT with randomly chosen URI data
     * 7) Call private function to check Super Pet NFT mint eligibility - in the case that before function call
     * Player's Snake NFT balans was at least 10.
     *
     * Function is protected from reentrancy attack, by using nonReentrant modifier from OpenZeppelin library.
     */
    function mintSuperPetNft() external payable nonReentrant {
        // Check Super Pet NFT mint eligibility
        _checkSuperPetNft(msg.sender);
        // Check if Player has unlocked Super Pet NFT for minting
        if (s_players[msg.sender].superPetNftClaimFlag == false) {
            revert SnakeGame__NoSuperNftToClaim();
        }
        // Check if Player has sent enough currency amount with function call, to pay Super Pet NFT mint fee.
        if (msg.value < i_superPetNftMintFee) {
            revert SnakeGame__NotEnoughMintFeeSent(msg.value, i_superPetNftMintFee);
        }
        // Check if Player's Snake NFT balance is enough to pay Super Pet NFT mint fee (burn Snake NFTs)
        uint256 snakeNftBalance = i_snakeNft.balanceOf(msg.sender);
        if (snakeNftBalance < i_snakeNftRequired) {
            revert SnakeGame__SnakeNftBalanceTooLow(snakeNftBalance, i_snakeNftRequired);
        }
        // Burn required amount of Snake NFTs as Super Pet NFT mint fee.
        _burnSnakeNfts(msg.sender);
        // Mint Super Pet NFT
        _mintSuperPetNft(msg.sender);
        // Check Super Pet NFT mint eligibility
        _checkSuperPetNft(msg.sender);
    }

    /**
     * @dev Function burns Snake NFT as a SuperPetNft mint fee.
     * Private function called ONLY by this `SnakeGame` contract.
     *
     * Function execution:
     * 1) Create new burnTokenIds memory array.
     * 2) Fill the array with Snake NFT IDs by calling tokenOfOwnerByIndex function in the FOR loop.
     * 3) Burn i_snakeNftRequired amount of Snake NFTs in the FOR loop
     *
     * @param _player the Player's address
     */
    function _burnSnakeNfts(address _player) private {
        // Get Snake NFTs tokenIds loop
        uint256[] memory burnTokenIds = new uint256[](i_snakeNftRequired);
        for (uint256 i; i < i_snakeNftRequired; i++) {
            burnTokenIds[i] = i_snakeNft.tokenOfOwnerByIndex(_player, i);
        }
        // Burn Snake NFTs loop
        for (uint256 i; i < i_snakeNftRequired; i++) {
            i_snakeNft.burn(burnTokenIds[i]);
        }
    }

    /**
     * @dev Function mints Super Pet NFT.
     * Private function called ONLY by this `SnakeGame` contract.
     *
     * Function execution:
     * 1) Random choice of Super Pet NFT URI's array index.
     * 2) Update Player's game parameters: superPetNftClaimFlag and mintedSuperPetNfts.
     * 3) Mint Super Pet NFT with randomly chosen URI data from Super Pet NFT URI datas array.
     * 4) Emit an event SuperPetNftMinted.
     *
     * @param _player the Player's address
     */
    function _mintSuperPetNft(address _player) private {
        // Check if Player hasn't already mint maximum number of Super Pet NFTs
        if (s_players[msg.sender].mintedSuperPetNfts < MAX_SUPER_PET_NFTS) {
            // Random choice of Super Pet NFT URI's array index
            uint256 superNftUriIndex = _randomNumber(i_superPetNft.getNftUrisArrayLength());
            // Update Player's game parameters: superPetNftClaimFlag and mintedSuperPetNfts
            s_players[_player].superPetNftClaimFlag = false;
            s_players[_player].mintedSuperPetNfts++;
            // SafeMint Super Pet NFT with randomly chosen URI data
            i_superPetNft.safeMint(_player, superNftUriIndex);
            //
            emit SuperPetNftMinted(_player);
        }
    }

    //////////////////////
    // Helper Functions //
    //////////////////////

    /**
     * @dev Function calculates gameFee depending on the baseGameFee and Player's superPetNft balance.
     * Public function called both by the smart contract and by the Player, using front-end application.
     * @return gameFee the calculated fee in SNAKE tokens
     */
    function gameFeeCalculation(address _player) public view returns (uint256) {
        uint256 superPetNftBalance = i_superPetNft.balanceOf(_player);
        if (superPetNftBalance <= 3) {
            return GAME_BASE_FEE - superPetNftBalance;
        } else return 1;
    }

    /**
     * @dev Function generates random integer number within the range specified in _range input parameter.
     * Can be replaced by random number delivered by Chainlink VRF, to ensure more reliable randomness.
     * Private function called ONLY by this `SnakeGame` contract.
     *
     * Function uses keccak256 hash function to generate pseudo random integer number, in the range specified
     * by input variable _range.
     *
     * @param _range range of the random number
     * @return random the random integer number within specified range
     */
    function _randomNumber(uint256 _range) private view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % _range;
        return random;
    }

    //////////////////////
    // Getter Functions //
    //////////////////////

    /**
     * @dev Getter function to get current game round.
     * @return Game round.
     */
    function getGameRound() public view returns (uint32) {
        return s_currentRound;
    }

    /**
     * @dev Getter function to get the Game highest score ever.
     * @return Game highest score ever.
     */
    function getHighestScoreEver() public view returns (uint64) {
        return s_highestScoreEver;
    }

    /**
     * @dev Getter function to get the Game best Player's ever address.
     * @return Game best Player's ever address
     */
    function getBestPlayerEver() public view returns (address) {
        return s_bestPlayerEver;
    }

    /**
     * @dev Getter function to get the total number of Players.
     * @return Total players number.
     */
    function getPlayersNumberTotal() public view returns (uint64) {
        return s_playersNumberTotal;
    }

    /**
     * @dev Getter function to get the total number of games played by all Players.
     * @return Game total games played.
     */
    function getGamesPlayedTotal() public view returns (uint64) {
        return s_gamesPlayedTotal;
    }

    /**
     * @dev Getter function to get GameRoundData parameters of given round.
     * @return Game parameters of given game round.
     */
    function getGameRoundData(uint32 _gameRound) public view returns (GameRoundData memory) {
        return s_gameRounds[_gameRound];
    }

    /**
     * @dev Getter function to get PlayerData parameters.
     * @return Player's game parameters of given Player's address.
     */
    function getPlayerData(address _player) public view returns (PlayerData memory) {
        return s_players[_player];
    }

    /**
     * @dev Getter function to get this `SnakeGame` smart contract balance.
     * @return Balnace of this smart contract.
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Getter function to get private `_randomNumber` result of given range
     * Mainly for test purposes
     *
     * @param _range range of random number
     * @return Function `_randomNumber` result.
     */
    function getRandomNumber(uint256 _range) public view returns (uint256) {
        return _randomNumber(_range);
    }

    /////////////////////
    // Other Functions //
    /////////////////////

    /**
     * @notice Receive transfer
     * @dev Function allows to receive funds sent to smart contract.
     */
    receive() external payable {
        // console.log("Function `receive` invoked");
        emit TransferReceived(msg.value);
    }

    /**
     * @notice Fallback function
     * @dev Function executes if none of the contract functions (function selector) match the intended
     * function calls.
     */
    fallback() external payable {
        // console.log("Function `fallback` invoked");
        emit TransferReceived(msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///////////////
//  Imports  //
///////////////
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//////////////
//  Errors  //
//////////////
error Token__ReceivedTransferReverted();
error Token__InvalidFunctionCall();

////////////////////
// Smart Contract //
////////////////////

/**
 * @title Token contract
 * @author Dariusz Setlak
 * @dev Smart contract based on Ethereum ERC-20 token standard, created using OpenZeppelin Wizard. Contract inherits
 * all ERC-20 token standard functions from OpenZeppelin library contracts.
 *
 * `Token` contract inherits `Ownable` contract from OpenZeppelin library, which sets `deployer` as contract `owner`.
 * This means, that ONLY owner will be authorized to call some sensitive contract functions like `mint` or `burn`,
 * which can be obtained by using `onlyOwner` modifier for these functions.
 *
 * Smart contract functions:
 * Override functions: mint, decimals
 * Other functions: receive, fallback
 */
contract Token is ERC20, ERC20Burnable, Ownable {
    ///////////////////
    //  Constructor  //
    ///////////////////

    /**
     * @dev `Token` contract constructor passes given parameters to OpenZeppelin library ERC20 constructor,
     * which use them to construct a standard ERC-20 token.
     * @param name token name
     * @param symbol token symbol
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /////////////////////////
    // Override Functions //
    /////////////////////////

    /**
     * @dev Function `mint` allows ONLY `owner` mint new tokens (modifier onlyOwner used).
     * Function calls `_mint` function from standard OpenZeppelin library ERC20.
     */
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    /**
     * @dev Function `decimals` override OpenZeppelin ERC20 contract function and returns new token decimal value `0`,
     * instead of default and standard value `18`.
     * @return Number of token decimals.
     */
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    /////////////////////
    // Other Functions //
    /////////////////////

    /**
     * @notice Receive ETH
     * @dev Functoin executes if unintended ETH transfer received.
     * This contract doesn't allows to receive ETH transfers, thererfore `receive` function
     * reverts all unintended ETH transfers.
     */
    receive() external payable {
        revert Token__ReceivedTransferReverted();
    }

    /**
     * @notice Fallback function
     * @dev Function executes if none of the contract functions match the intended function calls.
     * Function reverts transaction if called function is not found in the contract.
     */
    fallback() external payable {
        revert Token__InvalidFunctionCall();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///////////////
//  Imports  //
///////////////
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//////////////
//  Errors  //
//////////////
error Nft__AlreadyInitialized();
error Nft__ReceivedTransferReverted();
error Nft__InvalidFunctionCall();

////////////////////
// Smart Contract //
////////////////////

/**
 * @title Nft contract
 * @author Dariusz Setlak
 * @dev Smart contract based on Ethereum ERC-721 token standard, created using OpenZeppelin Wizard. Contract inherits
 * all ERC-721 token standard functions from OpenZeppelin library contracts.
 *
 * `Nft` contract inherits `Ownable` contract from OpenZeppelin library, which sets `deployer` as contract `owner`.
 * This means, that ONLY owner will be authorized to call some sensitive contract functions like `mint` or `burn`,
 * which can be obtained by using `onlyOwner` modifier for these functions.
 *
 * Smart contract functions:
 * Init functions: _initializeContract
 * Main functions: safeMint
 * Getter functions: getNftUris, getNftUrisArrayLength, getInitialized, getLatestTokenId
 * Override functions: _burn, tokenURI, supportsInterface, _beforeTokenTransfer
 * Other functions: receive, fallback
 */
contract Nft is ERC721, ERC721URIStorage, ERC721Burnable, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    /////////////////////
    //  NFT variables  //
    /////////////////////

    /// @dev Counter of tokenIds
    Counters.Counter private s_tokenIdCounter;

    /// @dev Array of all avaliable token uris.
    string[] internal s_uris;

    /// @dev Contract initialization flag.
    bool private s_initialized;

    ///////////////////
    //  Constructor  //
    ///////////////////

    /**
     * @dev `Nft` contract constructor passes given parameters to OpenZeppelin library ERC721
     * constructor, which then use them to construct a standard ERC-721 token.
     * @param name token name
     * @param symbol token symbol
     * @param uris token uris array
     */
    constructor(
        string memory name,
        string memory symbol,
        string[] memory uris
    ) ERC721(name, symbol) {
        _initializeContract(uris);
    }

    ///////////////////
    // Init Function //
    ///////////////////

    /**
     * @dev Initialization of token URI parameters
     * @param _uris token URI's array
     */
    function _initializeContract(string[] memory _uris) private {
        // if (s_initialized) {
        //     revert Nft__AlreadyInitialized();
        // }
        s_uris = _uris;
        s_initialized = true;
    }

    ////////////////////
    // Main Functions //
    ////////////////////

    /**
     * @dev Function `safeMint` allows ONLY `owner` mint new tokens (used `onlyOwner` modifier).
     * Function calls `_safeMint` function from OpenZeppelin contract ERC721 to mint new token to
     * Player's account. After that function calls `_setTokenURI` function from contract
     * ERC721URIStorage to set token URI from `s_uris` array at the index of given number.
     * @param _to Player's address
     * @param _uriIndex `s_uris` array index
     */
    function safeMint(address _to, uint256 _uriIndex) external onlyOwner {
        uint256 newTokenId = s_tokenIdCounter.current();
        s_tokenIdCounter.increment();
        _safeMint(_to, newTokenId);
        _setTokenURI(newTokenId, s_uris[_uriIndex]);
    }

    //////////////////////
    // Getter Functions //
    //////////////////////

    /**
     * @dev Getter function to get token URI of given index from token URI's array.
     * @param _index URI's array index
     * @return Value of token URI of given index from token URI's array
     */
    function getNftUris(uint256 _index) public view returns (string memory) {
        return s_uris[_index];
    }

    /**
     * @dev Getter function to get length of token URIs array.
     * @return Public value of token URIs array length.
     */
    function getNftUrisArrayLength() public view returns (uint256) {
        return s_uris.length;
    }

    /**
     * @notice Function checks, if token contract is initialized properly.
     * @dev Getter function to get value of bool variable `s_initialized`, which indicates
     * if token contract is initialized properly.
     * @return Status of `Nft` contract initialization.
     */
    function getInitialized() public view returns (bool) {
        return s_initialized;
    }

    ////////////////////////
    // Override Functions //
    ////////////////////////

    /// @dev The following functions are overrides required by Solidity.

    /**
     * @dev Function overrides _burn function from ERC721 and ERC721URIStorage libraries.
     * @param _tokenId unique id of new minted token
     */
    function _burn(uint256 _tokenId) internal override(ERC721, ERC721URIStorage) {
        ERC721URIStorage._burn(_tokenId);
    }

    /**
     * @dev Function overrides tokenURI function from ERC721 and ERC721URIStorage libraries.
     * Function allows to get NFT token URI of given tokenId.
     * @param _tokenId unique id of new minted token
     * @return Value of NFT token URI of given _tokenId
     */
    function tokenURI(uint256 _tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(_tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /////////////////////
    // Other Functions //
    /////////////////////

    /**
     * @notice Receive ETH
     * @dev Function executes if unintended ETH transfer received.
     * This contract doesn't allows to receive ETH transfers, thererfore `receive` function
     * reverts all unintended ETH transfers.
     */
    receive() external payable {
        revert Nft__ReceivedTransferReverted();
    }

    /**
     * @notice Fallback function
     * @dev Function executes if none of the contract functions match the intended function calls.
     * Function reverts transaction if called function is not found in the contract.
     */
    fallback() external payable {
        revert Nft__InvalidFunctionCall();
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
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