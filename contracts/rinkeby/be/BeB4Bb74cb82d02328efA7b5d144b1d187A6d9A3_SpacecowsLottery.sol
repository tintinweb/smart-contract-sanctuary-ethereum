// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SpacecowsLottery is ReentrancyGuard, Ownable {
    address public immutable BURN_ADDRESS;
    uint256 private lotteryId;

    uint256 public maxNumberTicketsPerRound;
    uint256 public ticketPriceInSpacemilk;

    IERC20 public smilkToken;

    enum Status {
        Open,
        Close,
        WinnerFound
    }

    struct Lottery {
        Status status;
        uint32 ticketId;
        uint32 playerId;
        uint32 finalNumber;
        uint32 winnerPlayerId;
        uint64 startTime;
        uint64 endTime;
        uint64 ticketPriceInSmilk;
        uint128 amountCollectedInSmilk;
        address winner;
        string reward;
        string rewardTransaction;
    }

    struct Player {
        uint32 ticketStart;
        uint32 ticketEnd;
        uint32 quantityTickets;
        address owner;
    }

    // Mapping are cheaper than arrays
    mapping(uint256 => Lottery) private _lotteries;
    mapping(uint256 => mapping(uint256 => Player)) private _tickets;

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /**
     * @notice Constructor
     * @dev RandomNumberGenerator must be deployed prior to this contract
     * @param _smilkTokenAddress: address of the SMILK token
     */
    constructor(address _smilkTokenAddress) {
        smilkToken = IERC20(_smilkTokenAddress);

        BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    }

    /**
     * @notice Buy tickets for the current lottery
     * @param _lotteryId: lotteryId
     * @param _numberOfTickets: amount of tickets to buy
     * @dev Callable by users
     */
    function buyTickets(uint256 _lotteryId, uint256 _numberOfTickets)
        external
        notContract
        nonReentrant
    {
        Lottery storage selectLottery = _lotteries[_lotteryId];

        require(_numberOfTickets != 0, "No ticket amount specified");
        require(_numberOfTickets < maxNumberTicketsPerRound + 1, "Too many tickets");

        require(selectLottery.status == Status.Open, "Lottery is not open");
        require(block.timestamp < selectLottery.endTime, "Lottery is over");

        unchecked {
            // Calculate number of SMILK to this contract
            uint256 amountSmilkToTransfer = selectLottery.ticketPriceInSmilk * _numberOfTickets;

            // Transfer smilk tokens to this contract
            smilkToken.transferFrom(address(msg.sender), address(this), amountSmilkToTransfer);

            uint256 endToken = selectLottery.ticketId;
            for (uint256 i = 1; i < _numberOfTickets; ++i) {
                ++endToken;
            }

            Player storage tmpPlayer = _tickets[_lotteryId][selectLottery.playerId];
            tmpPlayer.quantityTickets = uint32(_numberOfTickets);
            tmpPlayer.ticketStart = uint32(selectLottery.ticketId);
            tmpPlayer.ticketEnd = uint32(endToken);
            tmpPlayer.owner = msg.sender;

            selectLottery.playerId = uint32(selectLottery.playerId + 1);
            selectLottery.ticketId = uint32(endToken + 1);

            // Increment the total amount collected for the lottery round
            selectLottery.amountCollectedInSmilk = uint128(selectLottery.amountCollectedInSmilk + amountSmilkToTransfer);
        }
    }

    /**
     * @notice Close lottery
     * @param _lotteryId: lottery id
     * @dev Callable by owner
     */
    function closeLottery(uint256 _lotteryId) external onlyOwner nonReentrant {
        require(_lotteries[_lotteryId].status == Status.Open, "Lottery not open");
        require(block.timestamp > _lotteries[_lotteryId].endTime, "Lottery not over");

        _lotteries[_lotteryId].status = Status.Close;
    }

    /**
     * @notice Draw the final number, calculate reward in CAKE per group, and make lottery claimable
     * @param _lotteryId: lottery id
     * @param _tweetId: tweet id from the tweet about the lottery is closed
     * @dev Callable by operator
     */
    function drawFinalNumberAndMakeLotteryFinal(uint256 _lotteryId, uint256 _tweetId)
        external
        onlyOwner
        nonReentrant
    {
        Lottery storage selectLottery = _lotteries[_lotteryId];
        require(selectLottery.status == Status.Close, "Lottery not close");
        uint256 tmpTicketId = selectLottery.ticketId;

        // Calculate the finalNumber based on the tweet ID
        if (tmpTicketId != 0) {
            uint256 randomNumber = random(_tweetId);
            uint256 finalNumber = randomNumber % tmpTicketId;

            unchecked {
                for (uint256 i = 0; i < selectLottery.playerId; ++i) {
                    if (finalNumber <= _tickets[_lotteryId][i].ticketEnd && finalNumber >= _tickets[_lotteryId][i].ticketStart) {
                        selectLottery.winner = _tickets[_lotteryId][i].owner;
                        selectLottery.winnerPlayerId = uint32(i);
                        break;
                    }
                }
            }

            // Update internal statuses for lottery
            selectLottery.finalNumber = uint32(finalNumber);
        }

        selectLottery.status = Status.WinnerFound;
    }

    /**
     * @notice Start the lottery
     * @dev Callable by operator
     * @param _endTime: endTime of the lottery
     * @param _ticketPriceInSmilk: price of a ticket in CAKE
     * @param _reward: Description of the reward like Spacecows #7544
     */
    function startLottery(
        uint256 _endTime,
        uint256 _ticketPriceInSmilk,
        string memory _reward
    ) external onlyOwner {
        uint256 currentLotteryId = lotteryId;

        require(
            (currentLotteryId == 0) || (_lotteries[currentLotteryId].status == Status.WinnerFound),
            "Not time to start lottery"
        );

        unchecked {
            ++currentLotteryId;
        }
        
        Lottery storage tmpLottery = _lotteries[currentLotteryId];
        tmpLottery.status = Status.Open;
        tmpLottery.startTime = uint64(block.timestamp);
        tmpLottery.endTime = uint64(_endTime);
        tmpLottery.ticketPriceInSmilk = uint64(_ticketPriceInSmilk);
        tmpLottery.reward = _reward;

        lotteryId = currentLotteryId;
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(smilkToken), "Cannot be SMILK token");

        IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
    }

    /**
     * @notice Set SMILK ticket price
     * @dev Only callable by owner
     * @param _ticketPriceInSmilk: price of a ticket in SMILK
     */
    function setTicketPriceInSmilk(uint256 _ticketPriceInSmilk)
        external
        onlyOwner
    {
        require(_ticketPriceInSmilk != 0, "Must be > 0");

        ticketPriceInSpacemilk = _ticketPriceInSmilk;
    }

    /**
     * @notice Set max number of tickets
     * @dev Only callable by owner
     */
    function setMaxNumberTicketsPerRound(uint256 _maxNumberTicketsPerRound) external onlyOwner {
        require(_maxNumberTicketsPerRound != 0, "Must be > 0");
        maxNumberTicketsPerRound = _maxNumberTicketsPerRound;
    }

    /**
     * @notice Burn all SMILK token inside contract
     * @dev Only callable by owner
     */
    function burnSmilk() external onlyOwner nonReentrant {
        uint256 smilkBalance = smilkToken.balanceOf(address(this));
        smilkToken.transfer(address(BURN_ADDRESS), smilkBalance);
    }

    /**
     * @notice View current ticket id
     */
    function viewCurrentTicketId() external view returns (uint256) {
        return _lotteries[lotteryId].ticketId;
    }

    /**
     * @notice View current lottery id
     */
    function viewCurrentLotteryId() external view returns (uint256) {
        return lotteryId;
    }

    /**
     * @notice View lottery information
     * @param _lotteryId: lottery id
     */
    function viewLottery(uint256 _lotteryId) external view returns (Lottery memory) {
        return _lotteries[_lotteryId];
    }

    /**
     * @notice View ticket information
     * @param _lotteryId: lottery id
     * @param _playerId: player id
     */
    function viewTicket(uint256 _lotteryId, uint256 _playerId) external view returns (Player memory) {
        return _tickets[_lotteryId][_playerId];
    }

    /**
    * @param _tweetId: tweet id from the tweet about the lottery is closed
     */
    function random(uint256 _tweetId) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(_tweetId, lotteryId, _lotteries[lotteryId].ticketId)));
    }

    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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