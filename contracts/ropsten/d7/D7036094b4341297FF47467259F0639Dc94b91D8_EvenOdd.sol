// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICashManager.sol";
import "./interfaces/ITicketManager.sol";

contract EvenOdd is Ownable, ReentrancyGuard {

    event Betted(address _userAddress, uint256 _gameId, uint256 _amount);
    event Played(uint256 _gameId, bool _isOdd);
    event Received(address from, uint256 _amount);

    struct Player {
        uint256 ticketId;
        bool isOdd;
        uint256 bet;
    }

    struct Match {
        uint256 roll1;
        uint256 roll2;
        bool isOdd;
    }
    IERC20 private _cash;
    ICashManager private _cashManager;
    ITicketManager private _ticketManager;

    uint256 public latestMatchId;
    mapping(uint256 => Player[]) public playerList; // each match has multiple players, find by match id
    mapping(uint256 => Match) public matchList;

    constructor(address _cashAddress, address _cashManagerAddress, address _ticketManagerAddress) {
        _cash = IERC20(_cashAddress);
        _cashManager = ICashManager(_cashManagerAddress);
        _ticketManager = ITicketManager(_ticketManagerAddress);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * This function is used to supply token to contract
     */
    function supplyToken() external payable onlyOwner {
        _cashManager.buy{ value: msg.value }();
    }

    /**
     * This function is used to bet in a game
     * @param _isOdd - (true/false) the result that user betted
     * @param _amount - The amount of token that user betteds
     */
    function bet(bool _isOdd, uint256 _amount) external nonReentrant {
        _checkTicket();
        _checkAlreadyBet();
        _checkCashBalance(_amount);
        _cash.transferFrom(msg.sender, address(this), _amount);
        _ticketManager.subtractTimes(_msgSender());
        Player memory newPlayer = Player({
            ticketId: _ticketManager.getTicketId(msg.sender),
            isOdd: _isOdd,
            bet: _amount
        });

        playerList[latestMatchId].push(newPlayer);

        emit Betted(msg.sender, latestMatchId, _amount);
    }

    /**
     * Play a new game
     * Only owner can play
     */
    function play() external onlyOwner {
        _roll();
        _endGame();
        _nextGame();

        emit Played(latestMatchId - 1, matchList[latestMatchId - 1].isOdd);
    }

    /** 
     * Checking a ticket is available
     */
    function _checkTicket() private view {
        uint256 ticketId = _ticketManager.getTicketId(_msgSender());
        require(
            ticketId != 0,
            "This user does not have ticket. Please buy a one to play"
        );

        bool isExpired = _ticketManager.isExpired(_msgSender());
        require(
            isExpired != true,
            "This user's ticket is expired. Please buy a new one to play"
        );
    }

    /**
     * Checking that user has already betted before
     */
    function _checkAlreadyBet() private view {
        uint256 ticketId = _ticketManager.getTicketId(_msgSender());
        Player[] memory players = playerList[latestMatchId];

        for (uint256 i = 0; i < players.length; i++) {
            require(
                players[i].ticketId != ticketId,
                "This user has betted before!"
            );
        }
    }

    /**
     * Checking that balance is enough to bet or the balance of contract is enought to reward
     * @param _amount - The amount of token that user betted
     */
    function _checkCashBalance(uint256 _amount) private view {
        require(
            _cash.balanceOf(_msgSender()) >= _amount,
            "User's balance is not enough to bet"
        );

        Player[] memory players = playerList[latestMatchId];
        uint256 totalCashBetted = 0;
        for (uint256 i = 0; i < players.length; i++) {
            totalCashBetted = totalCashBetted + players[i].bet;
        }

        uint256 totalCashReward = (totalCashBetted + _amount) * 2;
        require(
            totalCashReward <= (_cash.balanceOf(address(this)) + _amount),
            "Contract is not enough cash to reward if user win"
        );
    }

    /**
     * Rolling 2 result of the game
     */
    function _roll() private {
        uint256 roll1 = ((block.timestamp % 15) + block.difficulty * 2) -
            block.number /
            3;
        uint256 roll2 = (((block.timestamp / block.chainid + 5) % 23) +
            block.number *
            2 +
            block.difficulty) / 4;

        matchList[latestMatchId].roll1 = uint256(roll1 % 6) + 1;
        matchList[latestMatchId].roll2 = uint256(roll2 % 6) + 1;
    }

    /**
     * Calculate the result of game and reward token to users
     */
    function _endGame() private {
        Player[] memory players = playerList[latestMatchId];
        Match memory currentMatch = matchList[latestMatchId];
        bool isOdd = (currentMatch.roll1 + currentMatch.roll2) % 2 == 1;
        matchList[latestMatchId].isOdd = isOdd;

        for (uint i = 0; i < players.length; i++) {
            if(players[i].isOdd == isOdd) {
                _cash.transfer(_ticketManager.ownerOf(players[i].ticketId), players[i].bet * 2);
            }
        }
    }

    function _nextGame() private {
        ++latestMatchId;
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
pragma solidity 0.8.9;

interface ICashManager {
    function buy() external payable; 

    function withdraw(uint256 amount) external;

    function setRateConversion(uint256 rate) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ITicketManager {
    function buy() external payable;

    function subtractTimes(address _account) external;

    function extendTicket() external payable;

    function isExpired(address _account) external view returns (bool);

    function getTicketId(address _account) external view returns (uint256);

    function getTicketTimes(address _account) external view returns (uint256);

    function ownerOf(uint256 _ticketId) external view returns (address);
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