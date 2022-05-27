/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// Part: OpenZeppelin/[email protected]/Context

/*
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

// Part: OpenZeppelin/[email protected]/Strings

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

// Part: smartcontractkit/[email protected]/LinkTokenInterface

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// Part: smartcontractkit/[email protected]/VRFRequestIDBase

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// Part: OpenZeppelin/[email protected]/Ownable

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Part: smartcontractkit/[email protected]/VRFConsumerBase

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// File: CryptoRoulette.sol

contract CryptoRoulette is Ownable, VRFConsumerBase {
    ///event declarations

    //indexed strings are hashed to allow the search to work
    //so also include a readable string gameKey
    //without the indexed modifier
    event newGameStarted(
        address indexed dealer,
        string indexed gameKeyHash,
        string gameKey,
        uint256 timeStamp,
        uint256 ante
    );

    event gameStatusChanged(
        address indexed dealer,
        string indexed gameKeyHash,
        string gameKey,
        uint256 timeStamp,
        string newStatus
    );

    event playerJoined(
        address indexed player,
        string indexed gameKeyHash,
        string gameKey,
        uint256 timeStamp
    );

    event playerSubmittedNumbers(
        address indexed player,
        string indexed gameKeyHash,
        string gameKey,
        uint256 timeStamp,
        uint256 highLow,
        uint256 oddEven,
        uint256[10] numbers,
        uint256 ante,
        uint256 playersStack
    );

    event rouletteWheelSpun(
        string indexed gameKeyHash,
        string gameKey,
        uint256 timeStamp,
        uint256 currentRound
    );

    event playerWon(
        address indexed player,
        string indexed gameKeyHash,
        string gameKey,
        string category,
        uint256 amountWon,
        uint256 playerStack,
        uint256 currentRound
    );

    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    ///enum declarations
    enum GameStatus {
        WAITING_FOR_PLAYERS,
        IN_PROGRESS,
        ENDED
    }
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    ///struct definitions

    struct DealerGame {
        address dealer;
        uint256 startTime;
        uint256 endTime;
        string gameKey;
        uint256 ante;
        GameStatus gameStatus;
        uint256 potAmount;
        bool locked;
        address[6] players;
        uint256[6] playerStacks;
        uint256 playerCount;
        uint256 currentRound;
    }

    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    ///Game data
    string[] internal currentGames; //list of gameKeys for games not ended
    string[] internal gameKeys; //list of all gameKeys used
    mapping(address => string[]) internal dealerGameKeys; //all game keys for dealer
    mapping(string => DealerGame) internal gameKeyDealerGame; //list of all games
    //used for matching random number requests to the game making the request
    mapping(bytes32 => string) internal requestIDGameKey;

    //Need to keep track of submitted numbers by players
    //The parent mapping uses the gameKey as the key
    //The mapping will be reset for every round in a game

    //highLowPlayers mapping holds the choices in a round for the high/low bets
    //players who choose "low numbers (1 - 18) will have their
    //addresses stored in the array with 0 as the key
    //players who choose "high numbers (19 - 36) will have their
    //addresses stored in the array with 1 as the key
    mapping(string => mapping(uint256 => address[])) internal highLowPlayers;

    //oddEvenPlayers mapping holds the choices in a round for the odd/even bets
    //players who choose "odd numbers will have their
    //addresses stored in the array with 0 as the key
    //players who choose "even numbers will have their
    //addresses stored in the array with 1 as the key
    mapping(string => mapping(uint256 => address[])) internal oddEvenPlayers;

    //numberPickPlayers mapping holds the choices in a round for the numbers bets
    //for each game round there is a mapping with keys 1 - 36
    //the address array will hold all players who picked the
    //number corresponding to the key
    mapping(string => mapping(uint256 => address[])) internal numberPickPlayers;

    //the three mappings above used to efficiently find winners
    //but they are not good for efficiently returning
    //a player's choices. So a fourth mapping will hold
    //an array of the player's choices
    //the key will be the gameKey with a dash and the round (e.g. mygamekey-3)
    mapping(string => mapping(address => uint256[12])) internal playersPicks;

    //save off the winning numbers
    //the key will be the gameKey with a dash and the round (e.g. mygamekey-3)
    mapping(string => uint256) internal winningNumbers;
    //save details of winners and amounts won
    address[] internal winners;
    string[] internal winType;
    uint256[] internal winAmount;
    uint256[] internal winRound;
    uint256[] internal winnerStack;

    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    ///public variables
    //not sure if these need to be public
    address public VRFCoordinator;
    address public LinkToken;

    uint256 public randomnumber; //just for testing
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    ///private variables
    uint256 private cryptoRouletteBank = 0; //keep track of dealer fees added
    uint256 private dealerFee = ONE_ONEHUNDREDTH_ETH;
    bool private allowNewGames = true;
    bytes32 private keyHash;
    uint256 private linkFee;
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    ///constants
    uint256 private constant ONE_ONETHOUSANDTH_ETH = 1000000000000000;
    uint256 private constant ONE_ONEHUNDREDTH_ETH = 10000000000000000;
    uint256 private constant ONE_TENTH_ETH = 100000000000000000;
    address private constant NULL_ADDRESS =
        0x0000000000000000000000000000000000000000;
    uint256 private constant HIGHLOW_HIGH = 0;
    uint256 private constant HIGHLOW_LOW = 1;
    uint256 private constant ODDEVEN_ODD = 0;
    uint256 private constant ODDEVEN_EVEN = 1;

    string private constant WAITING_FOR_PLAYERS_STRING = "Waiting for players";
    string private constant IN_PROGRESS_STRING = "In progress";
    string private constant GAME_ENDED_STRING = "Game ended";
    string private constant GAME_NOT_FOUND_STRING = "Game not found";

    uint256 private constant THREE_HOURS_IN_MILLISECONDS = 10800000;

    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    ///constructor
    constructor(
        address _vrfCoordinator,
        address _linkToken,
        uint256 _linkFee,
        bytes32 _keyHash
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        keyHash = _keyHash;
        linkFee = _linkFee;
        VRFCoordinator = _vrfCoordinator;
        LinkToken = _linkToken;
    }

    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    ///Game functions
    function startNewGame(uint256 _ante, string memory _gameKey)
        public
        payable
    {
        (bool success, string memory message) = checkNewGameRequirements(
            msg.sender,
            msg.value,
            _gameKey,
            _ante
        );
        require(success, message);
        // uint256 timeStamp = block.timestamp;
        // //dealer pays a fee to start a game
        // //keep track of the dealer fees added to the contract
        // cryptoRouletteBank += msg.value;

        uint256 noMoney = 0;

        // DealerGame memory dealerGame = DealerGame(
        //     msg.sender,
        //     timeStamp,
        //     0,
        //     _gameKey,
        //     _ante,
        //     GameStatus.WAITING_FOR_PLAYERS,
        //     0,
        //     false,
        //     [
        //         NULL_ADDRESS,
        //         NULL_ADDRESS,
        //         NULL_ADDRESS,
        //         NULL_ADDRESS,
        //         NULL_ADDRESS,
        //         NULL_ADDRESS
        //     ],
        //     [noMoney, noMoney, noMoney, noMoney, noMoney, noMoney],
        //     0,
        //     0
        // );

        // //The gameKeyDealer mapping and gameKeys array will
        // //permanently store this data for future reference
        // gameKeyDealerGame[_gameKey] = dealerGame;
        // gameKeys.push(_gameKey);
        // //the currentGames array only holds gameKeys for games not ended
        // currentGames.push(_gameKey);
        // //need to have easy access to all gamekeys associated with a dealer
        // //so add it to the array in the mapping
        // dealerGameKeys[msg.sender].push(_gameKey);
        // emit newGameStarted(msg.sender, _gameKey, _gameKey, timeStamp, _ante);
        // emit gameStatusChanged(
        //     msg.sender,
        //     _gameKey,
        //     _gameKey,
        //     timeStamp,
        //     WAITING_FOR_PLAYERS_STRING
        // );
    }

    function setGameToInProgress(string memory _gameKey) public {
        (uint256 index, string memory gameKey2) = getDealerCurrentGame(
            msg.sender
        );
        require(!isSameString(gameKey2, ""), GAME_NOT_FOUND_STRING);
        require(
            isSameString(gameKey2, _gameKey),
            "Game key is not current game for dealer."
        );
        require(
            gameKeyDealerGame[_gameKey].gameStatus ==
                GameStatus.WAITING_FOR_PLAYERS,
            "Game already in progress or ended."
        );
        gameKeyDealerGame[_gameKey].gameStatus = GameStatus.IN_PROGRESS;
        gameKeyDealerGame[_gameKey].currentRound = 1;
        emit gameStatusChanged(
            msg.sender,
            _gameKey,
            _gameKey,
            block.timestamp,
            IN_PROGRESS_STRING
        );
    }

    function joinGame(string memory _gameKey) public payable {
        (bool success, string memory message) = checkJoinPlayerRequirements(
            _gameKey,
            msg.sender,
            msg.value
        );
        require(success, message);
        bool playerAdded = false;
        // can be up to 6 players per game
        for (uint256 i = 0; i < 6; i++) {
            if (gameKeyDealerGame[_gameKey].players[i] == NULL_ADDRESS) {
                //found an empty slot for the player
                gameKeyDealerGame[_gameKey].players[i] = msg.sender;
                gameKeyDealerGame[_gameKey].playerStacks[i] = msg.value;
                gameKeyDealerGame[_gameKey].playerCount += 1;
                playerAdded = true;
                break;
            }
        }
        require(playerAdded, "Game already has 6 players");

        emit playerJoined(msg.sender, _gameKey, _gameKey, block.timestamp);
    }

    function submitNumbers(
        string memory _gameKey,
        uint256 _highLow,
        uint256 _oddEven,
        uint256[] memory _numbers
    ) public {
        (
            bool player_can_submit,
            string memory message
        ) = checkPlayerSubmitRequirements(_gameKey, msg.sender);

        require(player_can_submit, message);

        //make sure only one player submits at a time
        //to avoid collision updating potAmount
        gameKeyDealerGame[_gameKey].locked = true;

        //the highLowPlayers, oddEvenPlayers and numberPickPlayers
        //are made to efficiently identify winners without a lot of looping.
        //But these mappings are not good for retrieving a specific
        //player's picks, so need to save off the player's picks
        // in an easy to access mapping playersPicks

        string memory playersPicksKey = concatenateStrings(
            _gameKey,
            "-",
            Strings.toString(gameKeyDealerGame[_gameKey].currentRound)
        );

        if (_highLow == HIGHLOW_HIGH) {
            highLowPlayers[_gameKey][HIGHLOW_HIGH].push(msg.sender);
            playersPicks[playersPicksKey][msg.sender][0] = HIGHLOW_HIGH;
        } else {
            highLowPlayers[_gameKey][HIGHLOW_LOW].push(msg.sender);
            playersPicks[playersPicksKey][msg.sender][0] = HIGHLOW_LOW;
        }
        if (_oddEven == ODDEVEN_ODD) {
            oddEvenPlayers[_gameKey][ODDEVEN_ODD].push(msg.sender);
            playersPicks[playersPicksKey][msg.sender][1] = ODDEVEN_ODD;
        } else {
            oddEvenPlayers[_gameKey][ODDEVEN_EVEN].push(msg.sender);
            playersPicks[playersPicksKey][msg.sender][1] = ODDEVEN_EVEN;
        }
        uint256 numbersCount = _numbers.length;
        //player gets up to 10 choices for individual numbers
        if (numbersCount > 10) {
            numbersCount = 10;
        }

        //in the event we will want to pass back only valid
        uint256[10] memory validNumbers;
        //players get to choose 10 numbers between 1 and 36
        //submitted numbers outside that range
        //result in a wasted pick.
        for (uint256 i = 0; i < numbersCount; i++) {
            //loop through the numbers and add the players address to the mapping
            //where the key is the chosen number
            numberPickPlayers[_gameKey][_numbers[i]].push(msg.sender);
            playersPicks[playersPicksKey][msg.sender][i + 2] = _numbers[i];
            validNumbers[i] = _numbers[i];
        }

        uint256 playersStack;
        //subtract the ante from the player's stack
        //and add it to the pot
        for (uint256 i = 0; i < gameKeyDealerGame[_gameKey].playerCount; i++) {
            if (gameKeyDealerGame[_gameKey].players[i] == msg.sender) {
                gameKeyDealerGame[_gameKey].playerStacks[
                    i
                ] -= gameKeyDealerGame[_gameKey].ante;
                gameKeyDealerGame[_gameKey].potAmount += gameKeyDealerGame[
                    _gameKey
                ].ante;
                //save the player's new stack for the event
                playersStack = gameKeyDealerGame[_gameKey].playerStacks[i];
                break;
            }
        }
        //we can now allow other players to submit their numbers
        gameKeyDealerGame[_gameKey].locked = false;

        uint256 ante = gameKeyDealerGame[_gameKey].ante;

        emit playerSubmittedNumbers(
            msg.sender,
            _gameKey,
            _gameKey,
            block.timestamp,
            _highLow,
            _oddEven,
            validNumbers,
            ante,
            playersStack
        );

        //if all players have submitted numbers then time to spin wheel
        if (
            (highLowPlayers[_gameKey][HIGHLOW_HIGH].length +
                highLowPlayers[_gameKey][HIGHLOW_LOW].length) ==
            gameKeyDealerGame[_gameKey].playerCount
        ) {
            spinWheel(_gameKey);
        }
    }

    function withdrawalStack(string memory _gameKey) public payable {
        (bool allowWithdrawal, string memory message) = checkAllowWithdrawal(
            _gameKey
        );
        require(allowWithdrawal, message);

        uint256 balanceOwed = 0;
        //find the player's stack in the game and set balanceOwed
        //if player not found in game then throw error
        for (uint256 i = 0; i < gameKeyDealerGame[_gameKey].playerCount; i++) {
            if (gameKeyDealerGame[_gameKey].players[i] == msg.sender) {
                balanceOwed = gameKeyDealerGame[_gameKey].playerStacks[i];
                //to avoid a re-entrancy attack
                //set the playerStack to 0 before transferring the funds
                gameKeyDealerGame[_gameKey].playerStacks[i] = 0;
                break;
            }
        }
        require(balanceOwed > 0, "You have no money in this game.");
        payable(msg.sender).transfer(balanceOwed);
    }

    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    ///Public helper functions
    function getDealerFee() public view returns (uint256) {
        return dealerFee;
    }

    function getPlayerFee(string memory _gameKey)
        public
        view
        returns (uint256)
    {
        //The players fee is the ante passed in by the dealer when they
        //started the game, times 10. One ante for each of the 10 rounds.
        return gameKeyDealerGame[_gameKey].ante * 10;
    }

    function getGames(bool _currentOnly) public view returns (string[] memory) {
        if (_currentOnly) {
            return currentGames;
        } else {
            return gameKeys;
        }
    }

    function getGameStatus(string memory _gameKey)
        public
        view
        returns (string memory)
    {
        if (isGameKeyInUse(_gameKey)) {
            if (
                gameKeyDealerGame[_gameKey].gameStatus ==
                GameStatus.WAITING_FOR_PLAYERS
            ) {
                return WAITING_FOR_PLAYERS_STRING;
            } else if (
                gameKeyDealerGame[_gameKey].gameStatus == GameStatus.IN_PROGRESS
            ) {
                return IN_PROGRESS_STRING;
            } else {
                return GAME_ENDED_STRING;
            }
        } else {
            return GAME_NOT_FOUND_STRING;
        }
    }

    function getGamePlayers(string memory _gameKey)
        public
        view
        returns (
            address[6] memory playerAddresses,
            uint256[6] memory playerStacks
        )
    {
        return (
            gameKeyDealerGame[_gameKey].players,
            gameKeyDealerGame[_gameKey].playerStacks
        );
    }

    function getDealerGameKeys(address _dealer)
        public
        view
        returns (string[] memory keys)
    {
        return dealerGameKeys[_dealer];
    }

    function getGameInfo(string memory _gameKey)
        public
        view
        returns (
            address dealer,
            uint256 ante,
            string memory gameStatus,
            uint256 potAmount,
            uint256 playerCount,
            uint256 currentRound
        )
    {
        string memory status;
        if (
            gameKeyDealerGame[_gameKey].gameStatus ==
            GameStatus.WAITING_FOR_PLAYERS
        ) {
            status = WAITING_FOR_PLAYERS_STRING;
        } else if (
            gameKeyDealerGame[_gameKey].gameStatus == GameStatus.IN_PROGRESS
        ) {
            status = IN_PROGRESS_STRING;
        } else {
            status = GAME_ENDED_STRING;
        }
        return (
            gameKeyDealerGame[_gameKey].dealer,
            gameKeyDealerGame[_gameKey].ante,
            status,
            gameKeyDealerGame[_gameKey].potAmount,
            gameKeyDealerGame[_gameKey].playerCount,
            gameKeyDealerGame[_gameKey].currentRound
        );
    }

    function getPlayerPicks(
        string memory _gameKey,
        uint256 round,
        address _player
    ) public view returns (uint256[12] memory) {
        string memory playersPicksKey = concatenateStrings(
            _gameKey,
            "-",
            Strings.toString(round)
        );
        return playersPicks[playersPicksKey][_player];
    }

    function getWinningNumber(string memory _gameKey, uint256 round)
        public
        view
        returns (uint256)
    {
        string memory winningNumberKey = concatenateStrings(
            _gameKey,
            "-",
            Strings.toString(round)
        );
        return winningNumbers[winningNumberKey];
    }

    function getWinnersAndAmounts()
        public
        view
        returns (
            address[] memory,
            string[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        return (winners, winType, winAmount, winRound, winnerStack);
    }

    //////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    ///Internal functions

    function spinWheel(string memory _gameKey) internal {
        emit rouletteWheelSpun(
            _gameKey,
            _gameKey,
            block.timestamp,
            gameKeyDealerGame[_gameKey].currentRound
        );
        //make sure spinWheel function is not called more than once by the dealer
        //this will be set back to false after the round is over
        gameKeyDealerGame[_gameKey].locked = true;

        bytes32 requestId = requestRandomness(keyHash, linkFee);
        requestIDGameKey[requestId] = _gameKey;
    }

    function checkAllowWithdrawal(string memory _gameKey)
        internal
        returns (bool allowWithdrawal, string memory message)
    {
        if (gameKeyDealerGame[_gameKey].gameStatus == GameStatus.ENDED) {
            return (true, "");
        }
        //There may be times when a dealer does not complete a game and
        //does not call endGame. If this happens there needs to be a way
        //for players of that game to retrieve their money.
        //Check to see if the game is over 3 hours old.
        //If so and a player wants to withdraw their money
        //end the game and allow the player to withdrawal.
        if (
            block.timestamp - gameKeyDealerGame[_gameKey].startTime >=
            THREE_HOURS_IN_MILLISECONDS
        ) {
            endGameAndDividePot(_gameKey);
            return (true, "");
        }
        return (false, "Cannot withdrawal at this time. Try again later.");
    }

    function payWinners(string memory _gameKey, uint256 _randomNumber)
        internal
    {
        string memory winningNumberKey = concatenateStrings(
            _gameKey,
            "-",
            Strings.toString(gameKeyDealerGame[_gameKey].currentRound)
        );

        //the winning number is between 1 and 36 inclusive
        uint256 winningNumber = (_randomNumber % 36) + 1;
        winningNumbers[winningNumberKey] = winningNumber;
        bool isOdd = (winningNumber % 2 != 0);
        bool isLow = (winningNumber < 18);
        //winners of odd/even and high/low get to split 25% of the pot each
        uint256 quarterPot = gameKeyDealerGame[_gameKey].potAmount / 4;
        //winners of the exact match get to split 50% of the pot
        uint256 halfPot = gameKeyDealerGame[_gameKey].potAmount / 2;

        payOddEvenWinners(_gameKey, isOdd, quarterPot);

        payHighLowWinners(_gameKey, isLow, quarterPot);

        payExactMatchWinners(_gameKey, halfPot, winningNumber);

        //check to see if this was the last round
        if (gameKeyDealerGame[_gameKey].currentRound == 10) {
            //the game is over when 10 rounds completed
            endGameAndDividePot(_gameKey);
        } else {
            //increment the round
            gameKeyDealerGame[_gameKey].currentRound += 1;
        }

        gameKeyDealerGame[_gameKey].locked = false;
    }

    function payOddEvenWinners(
        string memory _gameKey,
        bool _isOdd,
        uint256 _quarterPot
    ) internal {
        address[] memory oddEvenWinners;

        if (_isOdd) {
            oddEvenWinners = oddEvenPlayers[_gameKey][ODDEVEN_ODD];
        } else {
            oddEvenWinners = oddEvenPlayers[_gameKey][ODDEVEN_EVEN];
        }

        if (oddEvenWinners.length > 0) {
            uint256 oddEvenShare = _quarterPot / oddEvenWinners.length;

            //pay off each of the players in the array
            for (uint256 i = 0; i < oddEvenWinners.length; i++) {
                for (uint256 k = 0; k < 6; k++) {
                    if (
                        gameKeyDealerGame[_gameKey].players[k] ==
                        oddEvenWinners[i]
                    ) {
                        // add the share to the player's stack
                        gameKeyDealerGame[_gameKey].playerStacks[
                                k
                            ] += oddEvenShare;
                        // subtract the same amount from the pot
                        gameKeyDealerGame[_gameKey].potAmount -= oddEvenShare;
                        emit playerWon(
                            gameKeyDealerGame[_gameKey].players[k],
                            _gameKey,
                            _gameKey,
                            "Odds-Evens",
                            oddEvenShare,
                            gameKeyDealerGame[_gameKey].playerStacks[k],
                            gameKeyDealerGame[_gameKey].currentRound
                        );
                        //winners, winType, winAmount, winRound, winnerStack
                        winners.push(gameKeyDealerGame[_gameKey].players[k]);
                        winType.push("odd-even");
                        winAmount.push(oddEvenShare);
                        winRound.push(gameKeyDealerGame[_gameKey].currentRound);
                        winnerStack.push(
                            gameKeyDealerGame[_gameKey].playerStacks[k]
                        );
                        break; //move on to the next player in the array
                    }
                }
            }
        }
        //set the players array to empty
        address[] memory emptyAddressArray;
        oddEvenPlayers[_gameKey][ODDEVEN_ODD] = emptyAddressArray;
        oddEvenPlayers[_gameKey][ODDEVEN_EVEN] = emptyAddressArray;
    }

    function payHighLowWinners(
        string memory _gameKey,
        bool _isLow,
        uint256 _quarterPot
    ) internal {
        address[] memory highLowWinners;
        if (_isLow) {
            highLowWinners = highLowPlayers[_gameKey][HIGHLOW_LOW];
        } else {
            highLowWinners = highLowPlayers[_gameKey][HIGHLOW_HIGH];
        }
        if (highLowWinners.length > 0) {
            uint256 highLowShare = _quarterPot / highLowWinners.length;

            //pay off each of the players in the array
            for (uint256 i = 0; i < highLowWinners.length; i++) {
                for (uint256 k = 0; k < 6; k++) {
                    if (
                        gameKeyDealerGame[_gameKey].players[k] ==
                        highLowWinners[i]
                    ) {
                        // add the share to the player's stack
                        gameKeyDealerGame[_gameKey].playerStacks[
                                k
                            ] += highLowShare;
                        // subtract the same amount from the pot
                        gameKeyDealerGame[_gameKey].potAmount -= highLowShare;
                        emit playerWon(
                            gameKeyDealerGame[_gameKey].players[k],
                            _gameKey,
                            _gameKey,
                            "High-Low",
                            highLowShare,
                            gameKeyDealerGame[_gameKey].playerStacks[k],
                            gameKeyDealerGame[_gameKey].currentRound
                        );
                        //winners, winType, winAmount, winRound, winnerStack
                        winners.push(gameKeyDealerGame[_gameKey].players[k]);
                        winType.push("high-low");
                        winAmount.push(highLowShare);
                        winRound.push(gameKeyDealerGame[_gameKey].currentRound);
                        winnerStack.push(
                            gameKeyDealerGame[_gameKey].playerStacks[k]
                        );
                        break; //move on to the next player in the array
                    }
                }
            }
        }
        //set the players array to empty
        address[] memory emptyAddressArray;
        highLowPlayers[_gameKey][HIGHLOW_LOW] = emptyAddressArray;
        highLowPlayers[_gameKey][HIGHLOW_HIGH] = emptyAddressArray;
    }

    function payExactMatchWinners(
        string memory _gameKey,
        uint256 _halfPot,
        uint256 _winningNumber
    ) internal {
        address[] memory exactNumberPlayers = numberPickPlayers[_gameKey][
            _winningNumber
        ];
        if (exactNumberPlayers.length > 0) {
            uint256 exactNumbersShare = _halfPot / exactNumberPlayers.length;
            //pay off each of the players in the array
            for (uint256 i = 0; i < exactNumberPlayers.length; i++) {
                for (uint256 k = 0; k < 6; k++) {
                    if (
                        gameKeyDealerGame[_gameKey].players[k] ==
                        exactNumberPlayers[i]
                    ) {
                        // add the share to the player's stack
                        gameKeyDealerGame[_gameKey].playerStacks[
                                k
                            ] += exactNumbersShare;
                        // subtract the same amount from the pot
                        gameKeyDealerGame[_gameKey]
                            .potAmount -= exactNumbersShare;

                        emit playerWon(
                            gameKeyDealerGame[_gameKey].players[k],
                            _gameKey,
                            _gameKey,
                            "Exact Number",
                            exactNumbersShare,
                            gameKeyDealerGame[_gameKey].playerStacks[k],
                            gameKeyDealerGame[_gameKey].currentRound
                        );

                        //winners, winType, winAmount, winRound, winnerStack
                        winners.push(gameKeyDealerGame[_gameKey].players[k]);
                        winType.push("exact");
                        winAmount.push(exactNumbersShare);
                        winRound.push(gameKeyDealerGame[_gameKey].currentRound);
                        winnerStack.push(
                            gameKeyDealerGame[_gameKey].playerStacks[k]
                        );

                        break; //move on to the next player in the array
                    }
                }
            }
        }
        //set all exact numbers player arrays to empty
        address[] memory emptyAddressArray;
        for (uint256 i = 1; i < 37; i++) {
            numberPickPlayers[_gameKey][i] = emptyAddressArray;
        }
    }

    function endGameAndDividePot(string memory _gameKey) internal {
        uint256 index = 0;
        //find the index of the game in currentGames array
        for (uint256 i = 0; i < currentGames.length; i++) {
            if (isSameString(currentGames[i], _gameKey)) {
                index = i;
                break;
            }
        }
        //remove the game from the currentGames array
        removeItemFromCurrentGamesArray(index);
        //set the status = ENDED
        uint256 endTime = block.timestamp;
        gameKeyDealerGame[_gameKey].gameStatus = GameStatus.ENDED;
        gameKeyDealerGame[_gameKey].endTime = endTime;

        if (gameKeyDealerGame[_gameKey].potAmount > 0) {
            //if there is money still in the pot then
            //split it evenly between the players
            uint256 playerCut = gameKeyDealerGame[_gameKey].potAmount /
                gameKeyDealerGame[_gameKey].playerCount;

            for (
                uint256 i = 0;
                i < gameKeyDealerGame[_gameKey].playerCount;
                i++
            ) {
                gameKeyDealerGame[_gameKey].playerStacks[i] += playerCut;
            }
        }
        gameKeyDealerGame[_gameKey].potAmount = 0;

        emit gameStatusChanged(
            msg.sender,
            _gameKey,
            _gameKey,
            endTime,
            GAME_ENDED_STRING
        );
    }

    function getDealerCurrentGame(address _dealer)
        internal
        returns (uint256 index, string memory gameKey)
    {
        string[] memory keys = dealerGameKeys[_dealer]; //get the gameKeys for the dealer
        if (keys.length == 0) {
            //no games so no current game
            return (0, "");
        }
        string memory latestGameKey = keys[keys.length - 1];
        for (uint256 i = 0; i < currentGames.length; i++) {
            if (isSameString(currentGames[i], latestGameKey)) {
                return (i, latestGameKey); //return the index and the key
            }
        }
        //no current game found
        return (0, "");
    }

    function removeItemFromCurrentGamesArray(uint256 _index) internal {
        //the easiest way to remove an item from the array in Solidity
        //is to copy the last item in the array over the
        //item to be deleted, then popping the last item off
        require(_index < currentGames.length);
        currentGames[_index] = currentGames[currentGames.length - 1];
        currentGames.pop();
    }

    function isGameKeyInUse(string memory _gameKey)
        internal
        view
        returns (bool)
    {
        //gameKey is in use if it has a non-null address in the gameKeyDealer mapping
        return
            gameKeyDealerGame[_gameKey].dealer !=
            0x0000000000000000000000000000000000000000;
    }

    function checkNewGameRequirements(
        address _dealer,
        uint256 _dealerPayment,
        string memory _gameKey,
        uint256 _ante
    ) internal returns (bool success, string memory message) {
        //The owner can set the contract to not allow new games if needed
        if (!allowNewGames) {
            return (
                false,
                "New games not allowed at this time. Check back later."
            );
        }

        if (_dealerPayment < dealerFee) {
            return (false, "Not enough ETH!");
        }

        // The ante can be .001 eth, .01 eth or .1 eth
        if (
            _ante != ONE_ONETHOUSANDTH_ETH &&
            _ante != ONE_ONEHUNDREDTH_ETH &&
            _ante != ONE_TENTH_ETH
        ) {
            return (false, "Ante not a valid value.");
        }

        (uint256 index, string memory currentGameKey) = getDealerCurrentGame(
            _dealer
        );
        if (!isSameString(currentGameKey, "")) {
            return (false, "You already have a game in progress.");
        }

        if (isGameKeyInUse(_gameKey)) {
            return (false, "GameKey already in use.");
        }

        return (true, "All conditions satisfied.");
    }

    function checkJoinPlayerRequirements(
        string memory _gameKey,
        address _player,
        uint256 _fee
    ) internal returns (bool success, string memory message) {
        if (_fee < gameKeyDealerGame[_gameKey].ante * 10) {
            return (false, "Not enough ETH!");
        }
        string memory status = getGameStatus(_gameKey);
        if (isSameString(status, GAME_NOT_FOUND_STRING)) {
            return (false, status);
        }
        if (!isSameString(status, WAITING_FOR_PLAYERS_STRING)) {
            return (false, "Cannot join game at this time.");
        }
        if (playerIsInGame(_gameKey, _player)) {
            return (false, "Player already in game.");
        }
        return (true, "");
    }

    function checkPlayerSubmitRequirements(
        string memory _gameKey,
        address _player
    ) internal returns (bool success, string memory message) {
        if (!playerIsInGame(_gameKey, _player)) {
            return (false, "Player not in game.");
        }
        if (gameKeyDealerGame[_gameKey].gameStatus != GameStatus.IN_PROGRESS) {
            return (false, "Cannot submit numbers. Game is not in progress.");
        }
        if (hasPlayerSubmittedNumbers(_gameKey, _player)) {
            return (false, "Player already submitted numbers.");
        }
        if (gameKeyDealerGame[_gameKey].locked) {
            return (
                false,
                "Too many players submitting at one time. Please try again."
            );
        }
        return (true, "");
    }

    function playerIsInGame(string memory _gameKey, address _player)
        internal
        returns (bool)
    {
        for (uint256 i = 0; i < gameKeyDealerGame[_gameKey].playerCount; i++) {
            if (gameKeyDealerGame[_gameKey].players[i] == _player) {
                return true;
            }
        }
        return false;
    }

    function isSameString(string memory _string1, string memory _string2)
        internal
        returns (bool)
    {
        //Comparing strings in Solidity doesn't work normally
        //TypeError: Operator != not compatible with types string memory and literal_string ""
        //So need to jump some hoops.
        return (keccak256(abi.encodePacked(_string1)) ==
            keccak256(abi.encodePacked(_string2)));
    }

    function hasPlayerSubmittedNumbers(string memory _gameKey, address _player)
        internal
        returns (bool)
    {
        address[] memory playersHigh = highLowPlayers[_gameKey][HIGHLOW_HIGH];
        for (uint256 i = 1; i < playersHigh.length; i++) {
            if (playersHigh[i] == _player) {
                return true;
            }
        }
        address[] memory playersLow = highLowPlayers[_gameKey][HIGHLOW_LOW];
        for (uint256 i = 1; i < playersLow.length; i++) {
            if (playersLow[i] == _player) {
                return true;
            }
        }
        return false;
    }

    function clearGameNumbers(string memory _gameKey) internal {
        address[] memory emptyAddressArray;

        highLowPlayers[_gameKey][HIGHLOW_HIGH] = emptyAddressArray;
        highLowPlayers[_gameKey][HIGHLOW_LOW] = emptyAddressArray;

        oddEvenPlayers[_gameKey][ODDEVEN_EVEN] = emptyAddressArray;
        oddEvenPlayers[_gameKey][ODDEVEN_ODD] = emptyAddressArray;

        for (uint256 i = 1; i < 37; i++) {
            numberPickPlayers[_gameKey][i] = emptyAddressArray;
        }
    }

    function concatenateStrings(
        string memory a,
        string memory b,
        string memory c
    ) public pure returns (string memory) {
        return string(bytes.concat(bytes(a), bytes(b), bytes(c)));
    }

    ////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    // ///Administrative functions
    function getCryptoRouletteBalance()
        public
        view
        onlyOwner
        returns (uint256)
    {
        return address(this).balance;
    }

    //Dealer's pay a fee when starting a new game
    //the cryptoRouletteBank variable holds the amount
    //of dealer fees added since the last withdrawal
    function getDealerFeeBalance() public view onlyOwner returns (uint256) {
        return cryptoRouletteBank;
    }

    //This is used to withdraw dealer fees from the contract.
    //This should not withdraw any eth owned by players.
    function withdrawDealerFees() public payable onlyOwner {
        uint256 amountToWithdraw = cryptoRouletteBank;
        cryptoRouletteBank = 0; //zero out the amount before transfer
        payable(msg.sender).transfer(amountToWithdraw);
    }

    function setDealerFee(uint256 _newDealerFee) public onlyOwner {
        dealerFee = _newDealerFee;
    }

    function setAllowNewGames(bool _allowNewGames) public onlyOwner {
        allowNewGames = _allowNewGames;
    }

    function setLinkFee(uint256 _linkFee) public onlyOwner {
        linkFee = _linkFee;
    }

    ////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness)
        internal
        override
    {
        //need to use the request id to find the gameKey
        string memory gameKey = requestIDGameKey[_requestId];

        if (_randomness == 0) {
            //This should not happen, but if it does try again
            spinWheel(gameKey);
            return;
        }

        payWinners(gameKey, _randomness);
    }
}