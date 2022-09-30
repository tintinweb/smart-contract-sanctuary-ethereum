//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBattleship.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

/**
 * @dev Battleship contract
 */
contract Battleship is IBattleship, Ownable {
    struct Guess {
        uint8 x;
        uint8 y;
    }

    /**
     * @dev Game information.
     * @dev The joiner is the challenger.
     * @dev The game creater always plays first
     *
     * @dev You may add more fields here for internal use, but do not change or remove any.
     */
    struct Game {
        GameStatus status;
        bytes32 localShipRoot;
        bytes32 challengerShipRoot;
        IBattleship challenger;
        Guess[] Localguesses;
        Guess pendingChallengerGuess;
        bool turn;
        address winner;
        address gameOwner;
        bool lastAttackHit;
        bool lastAttackSunk;
    }

    struct Ship {
        uint256 lives;
        uint256 hits;
        bool sunk;
    }

    Game public game;
    bool public firstAttack;

    Ship carrier = Ship(5, 0, false);
    Ship battleship = Ship(4, 0, false);
    Ship cruiser = Ship(3, 0, false);
    Ship submarine = Ship(3, 0, false);
    Ship destroyer = Ship(2, 0, false);

    mapping(bytes1 => Ship) Ships;

    //
    // Modifiers
    //
    modifier onlyContract() {
        uint32 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size > 0, "not calling from a contract");
        _;
    }

    // Add more

    //
    // External functions
    //

    /*
     * @dev Creates a new game. The sender becomes the owner of the game. Ensure a game isn't already started.
     * @param _shipsMerkleRoot The ships of the game creator. This is a merkle root of the ships.
     */
    function createGame(bytes32 _shipsMerkleRoot)
        external
        override
        returns (bool success)
    {
        require(game.status == GameStatus.FINISHED, "A gaem has been started.");
        game.status = GameStatus.WAITING;
        game.localShipRoot = _shipsMerkleRoot;
        game.turn = true;
        firstAttack = true;
        createShips();
        emit GameCreated();
        success = true;
    }

    /*
     * @dev Joins an existing game. The game must be in the WAITING state.
     * @param otherContract the contract address to join.
     * @param _shipsMerkleRoot the ships you want to place. This is a merkle root of the ships.
     */
    function joinGame(address otherContract, bytes32 _shipsMerkleRoot)
        external
        override
        returns (bool success)
    {
        require(
            IBattleship(otherContract).getGameStatus() == GameStatus.WAITING,
            "A gaem has been started or not created yet."
        );
        game.gameOwner = otherContract;
        game.challenger = IBattleship(otherContract);
        IBattleship(otherContract).setGameChallenger(
            IBattleship(address(this))
        );
        success = IBattleship(otherContract).handleJoin(_shipsMerkleRoot);
        createShips();
        emit GameJoined(otherContract);
    }

    /**
     * @dev Function that is called by the opposing contract, to join the game.
     * @dev This must handle the local setup of the game.
     * @dev param _challengerMerkleRoot the merkle root of the challenger's ships.
     */
    function handleJoin(bytes32 _challengerMerkleRoot)
        external
        override
        onlyContract
        returns (bool success)
    {
        game.status = GameStatus.STARTED;
        IBattleship(game.challenger).setGameStatus(GameStatus.STARTED);
        game.challengerShipRoot = _challengerMerkleRoot;
        emit GameStarted(address(game.challenger));
        success = true;
    }

    /*
     * @dev Attacks a target. Check if it is your turn.
     * @dev Check the challenger last guess hit. If it is, check if the ship is sunk.
     * @param x The x index of the target.
     * @param y The y index of the target.
     * @param merkleProofs the 6 merkle hashes to prove the attack
     * @param leaf raw data of the ship placement, used with merkle proofs
     * @return True if the attack was a hit, false otherwise.
     */
    function fire(
        uint8 x,
        uint8 y,
        bytes32[] memory merkleProofs,
        string memory leaf
    ) external override onlyOwner returns (bool hit) {
        require(game.turn, "its not your turn dear...");
        if (firstAttack) {
            IBattleship(game.challenger).recieveFire(x, y);
            firstAttack = false;
        } else {
            bytes32 Bleaf;
            assembly {
                Bleaf := mload(add(leaf, 32))
            }
            require(
                MerkleProof.verify(
                    merkleProofs,
                    game.challengerShipRoot,
                    Bleaf
                ),
                "you are cheating ..."
            );
            if (hitCheck(Bleaf)) {
                game.lastAttackHit = true;
                hit = true;
                if (sinkCheck(Bleaf)) {
                    game.lastAttackSunk = true;
                    emit Sunk(
                        address(game.challenger),
                        msg.sender,
                        uint8(Ships[Bleaf[3]].lives)
                    );
                }
            }
        }
    }

    /*
     * @dev Function that is called by the opposing contract, to check for a hit.
     * @param index The index of the target.
     * Emit necessary events
     * Ensure this is only called by the opposing contract, and it's their turn.
     * @return True for hit the attack was a hit, false otherwise. Also returns bool for sunk.
     */
    function recieveFire(uint8 x, uint8 y)
        external
        override
        onlyContract
        returns (bool hit, bool sunk)
    {
        require(
            msg.sender != address(this) && game.turn == false,
            "only opposing contract must call this function"
        );
        game.pendingChallengerGuess.x = x;
        game.pendingChallengerGuess.y = y;
        game.Localguesses.push(game.pendingChallengerGuess);
        emit Attack(msg.sender, address(this), x, y, game.lastAttackHit);
        return (game.lastAttackHit, game.lastAttackSunk);
    }

    /**
     * @dev Cancel/leave the current game.
     * Let the other contract know as well (handleWin), use modifiers
     */
    function cancelGame() external override returns (bool success) {
        if (msg.sender == address(this)) {
            success = game.challenger.handleWin();
        } else {
            success = IBattleship(game.gameOwner).handleWin();
        }
    }

    /**
     * @dev Function that is called by the opposing contract, when you have won. (all ships sunk)
     * @dev This should set game state, and winner.
     */
    function handleWin() external override onlyContract returns (bool) {
        game.status = GameStatus.FINISHED;
        game.winner = address(this);
        emit GameFinished(address(this), msg.sender);
        return true;
    }

    function createShips() internal returns (bool) {
        Ships["1"] = carrier;
        Ships["2"] = battleship;
        Ships["3"] = cruiser;
        Ships["4"] = submarine;
        Ships["5"] = destroyer;
        return true;
    }

    function hitCheck(bytes32 leaf) internal returns (bool success) {
        require(
            Ships[leaf[3]].hits != Ships[leaf[3]].lives,
            "you are a hitting a sunk ship ..."
        );
        if (leaf[2] == "1") {
            Ships[leaf[3]].hits++;
            success = true;
        }
    }

    function sinkCheck(bytes32 leaf) internal returns (bool success) {
        if (Ships[leaf[3]].hits == Ships[leaf[3]].lives) {
            Ships[leaf[3]].sunk = true;
            success = true;
        }
    }

    //
    // Getters and setters
    //

    /*
     * @dev Returns the current state of the game.
     * @return The current state of the game.
     */
    function getGameStatus()
        external
        view
        override
        returns (GameStatus status)
    {
        status = game.status;
    }

    function getShipsMerkleRoot()
        external
        view
        override
        returns (bytes32 shipsMerkleRoot)
    {
        shipsMerkleRoot = game.localShipRoot;
    }

    function setGameStatus(GameStatus newStatus)
        external
        override
        returns (bool)
    {
        game.status = newStatus;
        return true;
    }

    function setGameChallenger(IBattleship newChallenger)
        external
        override
        returns (bool)
    {
        game.challenger = newChallenger;
        return true;
    }

    // Add any internal functions as necessary
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Battleship contract.
 */
interface IBattleship {
    enum GameStatus {
        WAITING,
        STARTED,
        FINISHED
    }

    //
    // Events
    //

    event GameCreated();

    event GameJoined(address indexed challenger);

    event GameStarted(address indexed challenger);

    // @dev NOTE this is dispatched when a guess is revealed (the contract getting attacked)
    event Attack(
        address indexed attacker,
        address indexed defender,
        uint8 x,
        uint8 y,
        bool hit
    );

    event Sunk(
        address indexed attacker,
        address indexed defender,
        uint8 shipLength
    );

    event GameFinished(address indexed winner, address indexed opponent);

    //
    // External functions
    //

    /*
     * @dev Creates a new game. The sender becomes the owner of the game. Ensure a game isn't already started.
     * @param _shipsMerkleRoot The ships of the game creator. This is a merkle root of the ships.
     */
    function createGame(bytes32 _shipsMerkleRoot)
        external
        returns (bool success);

    /*
     * @dev Joins an existing game. The game must be in the OPEN state.
     * @param otherContract the contract address to join.
     * @param _shipsMerkleRoot the ships you want to place. This is a merkle root of the ships.
     */
    function joinGame(address otherContract, bytes32 _shipsMerkleRoot)
        external
        returns (bool success);

    /**
     * @dev Function that is called by the opposing contract, to join the game.
     * @dev This must handle the local setup of the game.
     * @dev param _challengerMerkleRoot the merkle root of the challenger's ships.
     */
    function handleJoin(bytes32 _challengerMerkleRoot)
        external
        returns (bool success);

    /*
     * @dev Attacks a target. Check if it is your turn.
     * @param x The x index of the target.
     * @param y The y index of the target.
     * @param merkleProofs the 6 merkle hashes to prove the attack
     * @param leaf raw data of the ship placement, used with merkle proofs
     * @return True if the attack was a hit, false otherwise.
     */
    function fire(
        uint8 x,
        uint8 y,
        bytes32[] calldata merkleProofs,
        string memory leaf
    ) external returns (bool hit);

    /*
     * @dev Function that is called by the opposing contract, to check for a hit.
     * @param index The index of the target.
     * Emit necessary events
     * Ensure this is only called by the opposing contract, and it's their turn.
     * @return True for hit the attack was a hit, false otherwise. Also returns bool for sunk.
     */
    function recieveFire(uint8 x, uint8 y)
        external
        returns (bool hit, bool sunk);

    /**
     * @dev Cancel/leave the current game.
     * Let the other contract know as well (handleWin), use modifiers
     */
    function cancelGame() external returns (bool success);

    /**
     * @dev Function that is called by the opposing contract, when you have won. (all ships sunk)
     * @dev This should set the game state and winner.
     */
    function handleWin() external returns (bool);

    //
    // Getters
    //

    /*
     * @dev Returns the current state of the game.
     * @return The current state of the game.
     */
    function getGameStatus() external view returns (GameStatus status);

    /*
     * @dev Returns the local ship root.
     * @return The local merkle root.
     */
    function getShipsMerkleRoot()
        external
        view
        returns (bytes32 shipsMerkleRoot);

    function setGameStatus(GameStatus newStatus) external returns (bool);

    function setGameChallenger(IBattleship newChallenger)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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