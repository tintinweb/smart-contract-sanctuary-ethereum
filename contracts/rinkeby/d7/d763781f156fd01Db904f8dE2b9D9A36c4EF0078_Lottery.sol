// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Lottery is Ownable, ReentrancyGuard {
    struct LotteryInfo {
        address payable[] players;
        address creator;
        address payable winner;
    }

    address public treasury;
    address public rewardDistributor;

    /// @dev current active lottery id
    uint256 public currentLotteryId;

    /// @dev lottery id => Lottry info
    mapping(uint256 => LotteryInfo) public lotteries;

    /// @dev lottery id => user index => status
    mapping(uint256 => mapping(uint256 => bool)) _winnerSelected;

    event LotteryCreated(
        address indexed creator,
        uint256 indexed lotteryId,
        uint256 timestamp
    );
    event LotteryEntered(
        address indexed participant,
        uint256 indexed lotteryId,
        uint256 amount,
        uint256 timestamp
    );
    event LotteryEnded(
        address indexed creator,
        uint256 indexed lotteryId,
        uint256 timestamp
    );

    /**
     * @dev Construct Lottery contract
     * @param _treasury address of treasury
     * @param _rewardDistributor address of rewardDistributor
     */
    constructor(address _treasury, address _rewardDistributor) {
        require(_treasury != address(0), "Error: treasury address is zero");
        require(
            _rewardDistributor != address(0),
            "Error: rewardDistributor address is zero"
        );

        treasury = _treasury;
        rewardDistributor = _rewardDistributor;

        currentLotteryId = 0;
    }

    /**
     * @dev Create lottry only from owner
     */
    function getLotteryInfo(uint256 _lotteryId)
        public
        view
        returns (LotteryInfo memory)
    {
        return lotteries[_lotteryId];
    }

    /**
     * @dev Create lottry only from owner
     */
    function createLottery() public onlyOwner {
        currentLotteryId += 1;
        lotteries[currentLotteryId].creator = msg.sender;

        emit LotteryCreated(msg.sender, currentLotteryId, block.timestamp);
    }

    /**
     * @dev Enter lottery
     * @param _lotteryId lottery id
     * @param _amount amount of pay token
     */
    function enterLottery(uint256 _lotteryId, uint256 _amount) public payable {
        require(_amount > 0, "Not enough payment!");
        require(
            msg.sender != lotteries[_lotteryId].creator,
            "Lottery creator can't participate"
        );

        lotteries[_lotteryId].players.push(payable(msg.sender));
        payable(msg.sender).transfer(_amount);
        emit LotteryEntered(msg.sender, _lotteryId, _amount, block.timestamp);
    }

    /**
     * @dev End lottery and choose winner by only owner
     * @param _lotteryId lottery id
     */
    function endLottery(uint256 _lotteryId) public onlyOwner nonReentrant {
        require(
            lotteries[_lotteryId].players.length > 1,
            "Error: less than 2 participants"
        );

        // choose winner
        _drawWinner(_lotteryId);

        emit LotteryEnded(msg.sender, _lotteryId, block.timestamp);
    }

    /**
     * @notice Change treasury address
     * @param _treasury  address of treasury
     */
    function changeTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Error: treasury address is zero");
        treasury = _treasury;
    }

    /**
     * @notice Change rewardDistributor address
     * @param _rewardDistributor  address of rewardDistributor
     */
    function changeRewardDistributor(address _rewardDistributor)
        external
        onlyOwner
    {
        require(
            _rewardDistributor != address(0),
            "Error: rewardDistributor address is zero"
        );
        rewardDistributor = _rewardDistributor;
    }

    /**
     * @notice Draw 3 winners
     * @param _lotteryId lottery id
     */
    function _drawWinner(uint256 _lotteryId) internal {
        address payable[] memory lotteryPlayers = lotteries[_lotteryId].players;
        uint256 indexOfWinner;
        // get random number
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty, // can actually be manipulated by the miners!
                    block.timestamp, // timestamp is predictable
                    lotteryPlayers // lottery players
                )
            )
        );

        indexOfWinner = randomNumber % lotteryPlayers.length;

        if (!_winnerSelected[_lotteryId][indexOfWinner]) {
            _winnerSelected[_lotteryId][indexOfWinner] = true;
        }
        lotteries[_lotteryId].winner = lotteryPlayers[indexOfWinner];
        payable(lotteries[_lotteryId].winner).transfer(address(this).balance);
    }
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