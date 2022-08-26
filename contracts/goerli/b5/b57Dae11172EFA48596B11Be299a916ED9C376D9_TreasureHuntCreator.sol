// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.12 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract TreasureHuntCreator is Ownable {
    event ChapterCompleted(
        uint indexed completedChapter,
        address indexed player
    );

    uint constant PAGE_SIZE = 32;

    mapping(uint96 => address[]) public _chapterToPlayers;
    mapping(address => uint96) public _playerToCurrentChapter;
    address[] public _solutions;
    address[] public _players;
    address[] public _gameMasters;
    bytes32[] public _quests;

    constructor(address[] memory solutions, bytes32[] memory quests) {
        _solutions = solutions;
        _quests = quests;
    }

    modifier onlyGameMaster() {
        require(isGameMaster(), "Only game masters can use this function.");
        _;
    }

    modifier onlyPlayer() {
        require(
            _playerToCurrentChapter[msg.sender] >= 1,
            "Player did not join yet. Call 'join' first"
        );
        _;
    }

    function isGameMaster() internal view returns (bool) {
        for (uint i; i < _gameMasters.length; i++) {
            if (_gameMasters[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function addChapter(address solution, bytes32 nextQuest)
        public
        onlyGameMaster
    {
        _solutions.push(solution);
        _quests.push(nextQuest);
    }

    function addGameMaster(address gameMaster) public onlyOwner {
        for (uint i = 0; i < _gameMasters.length; i++) {
            require(
                _gameMasters[i] != gameMaster,
                "This game master has already been added"
            );
        }

        _gameMasters.push(gameMaster);
    }

    function totalChapters() public view returns (uint) {
        return _quests.length;
    }

    function currentChapter() public view returns (uint96) {
        return _playerToCurrentChapter[msg.sender];
    }

    function currentQuest() public view returns (bytes32) {
        uint currentChapterIndex = _playerToCurrentChapter[msg.sender];
        return _quests[currentChapterIndex];
    }

    function submit(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        uint96 playerChapter = _playerToCurrentChapter[msg.sender];
        address playerChapterSolution = _solutions[playerChapter];
        bytes32 addressHash = getAddressHash(msg.sender);

        require(
            ecrecover(addressHash, v, r, s) == playerChapterSolution,
            "Wrong solution."
        );

        if (_playerToCurrentChapter[msg.sender] == 0) {
            _players.push(msg.sender);
        }
        _playerToCurrentChapter[msg.sender]++;
        _chapterToPlayers[playerChapter].push(msg.sender);
        emit ChapterCompleted(playerChapter, msg.sender);
    }

    function getAddressHash(address a) public pure returns (bytes32) {
        return
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n20", a));
    }

    function getLeaderboard(uint page)
        public
        view
        returns (uint256[PAGE_SIZE] memory leaderboard)
    {
        uint offset = page * PAGE_SIZE;
        for (uint i = 0; i < PAGE_SIZE && i + offset < _players.length; i++) {
            address player = _players[i + offset];

            leaderboard[i] =
                (uint256(uint160(player)) << 96) |
                uint256(_playerToCurrentChapter[player]);
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