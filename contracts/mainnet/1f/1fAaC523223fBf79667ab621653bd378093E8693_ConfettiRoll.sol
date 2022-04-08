// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./RpSeeder.sol";

/// @title A Death Roll-inspired game for Raid Party
/// @author xanewok.eth
/// @notice The games uses $CFTI, the native Raid Party token
contract ConfettiRoll is AccessControlEnumerable, Ownable, Pausable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    IERC20 public immutable confetti;
    RpSeeder public immutable seeder;
    address public immutable treasury;
    uint256 public tipAmount;
    uint256 public treasuryAmount;

    uint128 public minBet = 1e17; // 0.1 $CFTI
    uint128 public maxBet = 150e18; // 150 $CFTI
    uint128 public defaultBet = 30e18; // 30 $CFTI

    uint16 public treasuryFee = 500; // 5%
    uint16 public betTip = 50; // 0.5%
    uint16 constant FEE_PRECISION = 1e4;

    uint16 public minStartingRoll = 2;
    uint16 public maxStartingRoll = 1000;
    uint16 public defaultStartingRoll = 100;

    uint16 public defaultMaxParticipants = 10;

    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    struct Game {
        address[] participants;
        uint128 poolBet;
        uint32 roundNum;
        uint16 startingRoll;
        uint16 maxParticipants;
    }

    struct GameResult {
        // In theory this should always be equal to `getSeed(game.roundNum)`;
        // however, since we depend on an external seeder, let's always remember
        // the seed for a given finalized game to make the results verifiable
        // and deterministic
        uint256 finalizedSeed;
        // The amount that every participant (except for the loser) is due,
        // after the game finishes
        uint256 prizeShare;
        address loser;
    }

    event PlayerLost(bytes32 indexed gameId, address indexed player);
    event GameCreated(bytes32 indexed gameId);
    event PlayerJoined(bytes32 indexed gameId, address indexed player);

    mapping(bytes32 => GameResult) gameResults;
    mapping(bytes32 => Game) games;

    mapping(address => EnumerableSet.Bytes32Set) pendingGames;

    constructor(
        IERC20 confetti_,
        address seeder_,
        address treasury_
    ) {
        _setupRole(TREASURY_ROLE, treasury_);

        seeder = RpSeeder(seeder_);
        treasury = treasury_;
        confetti = confetti_;
        tipAmount = 0;
        treasuryAmount = 0;
    }

    function setTreasuryFee(uint16 treasuryFee_)
        public
        onlyRole(TREASURY_ROLE)
    {
        require(treasuryFee_ <= 3000, "Let the gamblers gamble in peace");
        treasuryFee = treasuryFee_;
    }

    function withdrawTax() public onlyRole(TREASURY_ROLE) {
        require(treasuryAmount > 0, "Nothing to withdraw");
        confetti.transfer(treasury, treasuryAmount);
        treasuryAmount = 0;
    }

    function withdrawTip() public onlyOwner {
        require(tipAmount > 0, "Nothing to withdraw");
        confetti.transfer(owner(), tipAmount);
        tipAmount = 0;
    }

    function setBetTip(uint16 betTip_) public onlyOwner {
        betTip = betTip_;
    }

    function setBets(
        uint128 min,
        uint128 max,
        uint128 default_
    ) public onlyOwner {
        minBet = min;
        maxBet = max;
        defaultBet = default_;
    }

    function setStartingRolls(
        uint16 min,
        uint16 max,
        uint16 default_
    ) public onlyOwner {
        minStartingRoll = min;
        maxStartingRoll = max;
        defaultStartingRoll = default_;
    }

    function setDefaultMaxParticipants(uint16 value) public onlyOwner {
        defaultMaxParticipants = value;
    }

    /// @dev We piggyback on the RaidParty batch seeder for our game round abstraction
    function currentRound() public view returns (uint32) {
        return uint32(seeder.getBatch());
    }

    /// @notice Return generated random words for a given game round
    function getSeed(uint32 roundNum) public view returns (uint256) {
        bytes32 reqId = seeder.getReqByBatch(roundNum);
        return seeder.getRandomness(reqId);
    }

    function getGame(bytes32 gameId) public view returns (Game memory) {
        return games[gameId];
    }

    function getGameResults(bytes32 gameId)
        public
        view
        returns (GameResult memory)
    {
        return gameResults[gameId];
    }

    function isGameFinished(bytes32 gameId) public view returns (bool) {
        return gameResults[gameId].loser != address(0x0);
    }

    /// @notice Returns the order in which the players roll for a given game
    function getRollingPlayers(bytes32 gameId)
        public
        view
        returns (address[] memory)
    {
        Game memory game = games[gameId];
        uint256 seed = getSeed(game.roundNum);
        require(seed > 0, "Game not seeded yet");
        require(game.participants.length >= 2, "Need at least 2 players");

        return shuffledPlayers(game.participants, seed);
    }

    /// @notice Returns player rolls for a given game. They correspond to player order returned by `getRollingPlayers`
    function getRolls(bytes32 gameId) public view returns (uint256[] memory) {
        Game memory game = games[gameId];
        uint256 seed = getSeed(game.roundNum);
        require(seed > 0, "Game not seeded yet");
        require(game.participants.length >= 2, "Need at least 2 players");
        // NOTE: The part below is the same as `simulateGame` only with
        // remembering the roll values (which are originally not to save gas).

        // The upper bound for the number of rolls is the starting roll value
        uint256[] memory rolls = new uint256[](game.startingRoll);

        uint256 roll = game.startingRoll;
        uint256 rollCount = 0;
        while (roll > 0) {
            // NOTE: `roll` is always in the [1, game.startingRoll - 1] range
            // here, as we start if it's positive and we always use modulo,
            // starting from the `game.startingRoll`
            roll = uint256(keccak256(abi.encodePacked(rollCount, seed))) % roll;
            rolls[rollCount] = roll + 1;
            rollCount++;
        }
        // NOTE: This is meant to be executed in a read-only fashion - to get rid
        // of the extra zeroes, we just copy over the actual rolls to a new array
        uint256[] memory returnedRolls = new uint256[](rollCount);
        for (uint256 i = 0; i < returnedRolls.length; i++) {
            returnedRolls[i] = rolls[i];
        }
        return returnedRolls;
    }

    /// @notice Returns a list of outstanding games for the player
    function getPendingGames(address player)
        public
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory pendingGames_ = new bytes32[](
            pendingGames[player].length()
        );
        for (uint256 i = 0; i < pendingGames[player].length(); i++) {
            pendingGames_[i] = pendingGames[player].at(i);
        }
        return pendingGames_;
    }

    /// @notice Returns whether the player is eligible to collect a prize for a given game
    function canCollectReward(address player, bytes32 gameId)
        public
        view
        returns (bool)
    {
        return (isGameFinished(gameId) && gameResults[gameId].loser != player);
    }

    /// @notice Returns a total amount of claimable rewards by the player
    function getPendingRewards(address player) public view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < pendingGames[player].length(); i++) {
            bytes32 gameId = pendingGames[player].at(i);
            if (canCollectReward(player, gameId)) {
                sum += gameResults[gameId].prizeShare;
            }
        }
        return sum;
    }

    /// @notice Process and clear every outstanding game, collecting the rewards
    function withdrawRewards() public whenNotPaused returns (uint256) {
        address player = msg.sender;
        uint256 rewards = 0;

        for (uint256 i = 0; i < pendingGames[player].length(); ) {
            bytes32 gameId = pendingGames[player].at(i);
            if (canCollectReward(player, gameId)) {
                rewards += gameResults[gameId].prizeShare;
            }
            // NOTE: This is the main function that is responsible for clearing
            // up pending games (e.g. for UI reasons), so make sure to clear up
            // pending *lost* games as well, even if we didn't collect a prize
            if (isGameFinished(gameId)) {
                pendingGames[player].remove(gameId);
                // Deleting an element might've shifted the order of the elements
                // and since we're deleting while iterating (a Bad Idea^TM),
                // simply start iterating from the start to be safe
                i = 0;
            } else {
                i++;
            }
        }

        confetti.transfer(msg.sender, rewards);
        return rewards;
    }

    /// @notice Calculates the game identifier for a given game initializer and roundNum
    /// The game initializer can be either the address of the contract if we're
    /// creating a "global" game or the address of the callee
    function calcGameId(address initializer, uint256 roundNum)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(initializer, roundNum));
    }

    /// @notice Returns a game identifier for the currently running, global game
    function currentGlobalGameId() public view returns (bytes32) {
        return calcGameId(address(this), currentRound());
    }

    // Anyone can join the game for the current round where either they are the
    // initializer and they can set a custom bet or they can create a global
    // game per round with a default bet amount
    /// @notice Create a new game
    /// @param initializer needs to be an address of the contract or the sender
    /// @param poolBet The amount of money that the player enters with. Use 18 decimals, just like for $CFTI
    /// @param maxParticipants The maximum number of players that can join the game
    /// @param startingRoll The upper roll that the game begins with
    /// @param roundNum The round when the game will be played. Must be bigger than the current round
    function createGame(
        address initializer,
        uint128 poolBet,
        uint16 startingRoll,
        uint16 maxParticipants,
        uint32 roundNum
    ) public whenNotPaused returns (bytes32) {
        if (startingRoll == 0) {
            startingRoll = defaultStartingRoll;
        }
        if (poolBet == 0) {
            poolBet = defaultBet;
        }
        if (maxParticipants < 2) {
            maxParticipants = defaultMaxParticipants;
        }
        uint256 seed = getSeed(roundNum);
        require(seed == 0, "Game already seeded");
        require(
            roundNum >= currentRound(),
            "Can't create games in the past"
        );
        require(
            poolBet >= minBet && poolBet <= maxBet,
            "Bet outside legal range"
        );
        require(
            startingRoll >= minStartingRoll && startingRoll <= maxStartingRoll,
            "Start roll outside legal range"
        );
        // Allow for creating a custom game with the sender as initializer or
        // a "global" (per round) one that needs to have default values set
        require(
            initializer == msg.sender ||
                (initializer == address(this) &&
                    poolBet == defaultBet &&
                    startingRoll == defaultStartingRoll &&
                    maxParticipants == defaultMaxParticipants)
        );
        bytes32 gameId = calcGameId(initializer, roundNum);
        require(!isGameFinished(gameId), "Game already finished");

        games[gameId].poolBet = poolBet;
        games[gameId].roundNum = roundNum;
        games[gameId].startingRoll = startingRoll;
        games[gameId].maxParticipants = maxParticipants;

        emit GameCreated(gameId);
        return gameId;
    }

    /// @notice Join the given game. Needs $CFTI approval as the player needs to deposit the pool bet in order to play.
    function joinGame(bytes32 gameId) public whenNotPaused {
        Game memory game = games[gameId];
        require(game.startingRoll > 0, "Game doesn't exist yet");
        require(!isGameFinished(gameId), "Game already finished");
        // Mitigate possible front-running - close the game sign-ups about a minute
        // before the seeder can request randomness. The RP seeder is pre-configured
        // to require 3 block confirmations, so 60 seconds makes sense (< 3 * 14s)
        uint256 seed = getSeed(game.roundNum);
        require(seed == 0, "Game already seeded");
        require(
            seeder.getNextAvailableBatch() > (block.timestamp + 60),
            "Seed imminent; sign-up is closed"
        );
        require(!pendingGames[msg.sender].contains(gameId), "Already joined");
        require(
            games[gameId].participants.length < game.maxParticipants &&
                games[gameId].participants.length <= (FEE_PRECISION / betTip),
            "Too many players"
        );

        uint256 tip = (game.poolBet * betTip) / FEE_PRECISION;
        tipAmount += tip;
        confetti.transferFrom(msg.sender, address(this), game.poolBet);

        games[gameId].participants.push(msg.sender);
        pendingGames[msg.sender].add(gameId);
        emit PlayerJoined(gameId, msg.sender);
    }

    /// @notice A convenient method to join the currently running global game
    function joinGlobalGame() public whenNotPaused returns (bytes32) {
        bytes32 globalGameId = currentGlobalGameId();
        // Lazily create a global game if there isn't one already
        if (games[globalGameId].startingRoll == 0) {
            createGame(
                address(this),
                defaultBet,
                defaultStartingRoll,
                defaultMaxParticipants,
                currentRound()
            );
        }
        joinGame(globalGameId);
        return globalGameId;
    }

    /// @return Shuffled randomly players from the given ones, using supplied seed
    function shuffledPlayers(address[] memory players, uint256 seed)
        public
        pure
        returns (address[] memory)
    {
        address[] memory shuffled = players;

        address temp;
        uint256 pick;
        for (uint256 i = 0; i < players.length; i++) {
            // Randomly pick a value from i (incl.) till the end of the array
            // To further increase randomness entropy, add the current player address
            pick =
                uint256(keccak256(abi.encodePacked(players[i], seed))) %
                (players.length - i);
            temp = shuffled[i];
            // Save the randomly picked number as the i-th address in the sequence
            shuffled[i] = shuffled[i + pick];
            // Return the original value to the pool that we pick from
            shuffled[i + pick] = temp;
        }

        return shuffled;
    }

    /// @dev Given an unitialized yet game, simulate the game and commit the results to the storage
    function simulateGame(bytes32 gameId)
        internal
        whenNotPaused
        returns (GameResult storage)
    {
        require(!isGameFinished(gameId), "Game already finished");
        Game memory game = games[gameId];

        uint256 seed = getSeed(game.roundNum);
        require(seed > 0, "Game not seeded yet");
        require(game.participants.length >= 2, "Need at least 2 players");
        // To remove any bias from the order that players registered with, make
        // sure to shuffle them before starting the actual game
        // NOTE: This is the same as `getRollingPlayers`
        address[] memory players = shuffledPlayers(game.participants, seed);

        // NOTE: This is the same as `getRolls`, however we don't use that as
        // we'd spend too much gas on remembering the rolls - we're interested
        // only in the outcome itself, which is the losing player
        uint256 roll = game.startingRoll;
        uint256 rollCount = 0;
        while (roll > 0) {
            // NOTE: `roll` is always in the [1, game.startingRoll - 1] range
            // here, as we start if it's positive and we always use modulo,
            // starting from the `game.startingRoll`
            unchecked {
                roll =
                    uint256(keccak256(abi.encodePacked(rollCount, seed))) %
                    roll;
                rollCount++;
            }
        }

        // The last to roll is the one who lost
        address loser = players[(rollCount - 1) % players.length];
        gameResults[gameId].loser = loser;
        // Saved for bookkeeping
        gameResults[gameId].finalizedSeed = seed;

        return gameResults[gameId];
    }

    /// @notice Simulates a given game, assuming it's been seeded since its creation
    function commenceGame(bytes32 gameId) public whenNotPaused {
        Game memory game = games[gameId];

        require(game.participants.length > 0, "No players in the game");
        if (game.participants.length == 1) {
            // Not much of a game if we have a single participant, return the bet
            confetti.transfer(game.participants[0], game.poolBet);
            pendingGames[game.participants[0]].remove(gameId);
            return;
        }

        GameResult storage results = simulateGame(gameId);
        require(isGameFinished(gameId), "Game not finished after simul.");
        require(results.loser != address(0), "Finished game has no loser");

        emit PlayerLost(gameId, results.loser);

        // Tax the prize money for the treasury
        uint256 collectedBetTip = (game.poolBet * betTip) / FEE_PRECISION;
        uint256 payableBet = game.poolBet - collectedBetTip;
        uint256 treasuryShare = (payableBet * treasuryFee) / FEE_PRECISION;
        treasuryAmount += treasuryShare;

        // Split the remaining prize pool among the winners; they need to collect
        // them themselves to amortize gas cost of the game simulation
        results.prizeShare =
            // Original bet
            payableBet +
            // Taxed prize pool that's split among everyone
            (payableBet - treasuryShare) /
            (game.participants.length - 1);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ISeederV2.sol';
import './ISeedStorage.sol';

/// @title Access to the batch seeder used by the Raid Party game
contract RpSeeder is ISeederV2, ISeedStorage {
    ISeederV2 private immutable seederV2;
    ISeedStorage private immutable seedStorage;

    constructor(address seederV2_, address seedStorage_) {
        seederV2 = ISeederV2(seederV2_);
        seedStorage = ISeedStorage(seedStorage_);
    }

    function getBatch() external override view returns (uint256) {
        return seederV2.getBatch();
    }

    function getReqByBatch(uint256 batch) external override view returns (bytes32) {
        return seederV2.getReqByBatch(batch);
    }

    function getNextAvailableBatch() external override view returns (uint256) {
        return ISeederV2(seederV2).getNextAvailableBatch();
    }

    function getRandomness(bytes32 key) external override view returns (uint256) {
        return seedStorage.getRandomness(key);
    }

    function executeRequestMulti() external {
        return seederV2.executeRequestMulti();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Originally deployed at https://etherscan.io/address/0x2Ed251752DA7F24F33CFbd38438748BB8eeb44e1
interface ISeederV2 {
    function getBatch() external view returns (uint256);
    function getReqByBatch(uint256 batch) external view returns (bytes32);
    function getNextAvailableBatch() external view returns (uint256);

    function executeRequestMulti() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Originally deployed at https://etherscan.io/address/0xFc8f72Ac252d5409ba427629F0F1bab113a7492F
interface ISeedStorage {
    function getRandomness(bytes32 key) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}