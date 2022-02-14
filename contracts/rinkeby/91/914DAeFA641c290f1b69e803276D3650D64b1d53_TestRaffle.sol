// SPDX-License-Identifier: MIT

pragma solidity =0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burn is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}

contract TestRaffle is Ownable {
    struct Entry {
        uint32 raffle;
        uint32 ticketPosition;
        uint32 tickets;
    }

    mapping(address => Entry) private _entries;

    struct Raffle {
        uint32 entryDeadline;
        uint32 totalEntries;
        uint32 totalTickets; 
        
        uint16 numberOfWinners;
        uint16 maximumTicketsPerEntry;

        uint48 rewardTicketPrice;
        uint48 tokenTicketPrice;

        uint32 numberOfRedraws;
        bytes32 randomSeed;
    }
    mapping(uint256 => Raffle) private _raffles;

    uint48 private _rewardTicketPrice;
    uint48 private _tokenTicketPrice;

    uint32 public currentRaffle;
    uint32 public entryDeadline;
    uint32 public totalEntries;
    uint32 public totalTickets; 
       
    uint16 public numberOfWinners;
    uint16 public maximumTicketsPerEntry;

    // TODO change to mainnet addresses
    address private constant REWARD_ADDRESS = address(0xC740ae100C554a90E5622d52e54d617Cd088711C);
    address private constant TOKEN_ADDRESS = address(0x049937d06Dce7A30B10914AA3bC21678dC612687);
    //address private constant REWARD_ADDRESS = address(0xc08f2f8946593a8da611F70747B4360006b5B2c5);
    //address private constant TOKEN_ADDRESS = address(0x831dAA3B72576867cD66319259bf022AFB1D9211);

    /// @dev Emitted when `account` enters `raffle` at `ticketPosition` with number of `tickets`.
    event EnterRaffle(uint256 indexed raffle, address indexed account, uint256 ticketPosition, uint256 tickets);


    function rewardTicketPrice() external view returns (uint256) {
        return _rewardTicketPrice * 10**9;
    }

    function tokenTicketPrice() external view returns (uint256) {
        return _tokenTicketPrice * 10**9;
    }

    function ticketPositionOf(address account) external view returns (uint256) {
        Entry storage entry = _entries[account];
        require(entry.raffle == currentRaffle, "Account has not entered current raffle");
        return entry.ticketPosition;
    }

    function ticketsOf(address account) external view returns (uint256) {
        Entry storage entry = _entries[account];
        require(entry.raffle == currentRaffle, "Account has not entered current raffle");
        return entry.tickets;
    }


    function newRaffle(uint16 _numberOfWinners, uint16 _maximumTicketsPerEntry, uint32 _entryDeadline, uint48 rewardTicketPrice, uint48 tokenTicketPrice) external onlyOwner() {
        require(_entryDeadline > block.timestamp, "Deadline for entry must be in the future");
        require(_numberOfWinners > 0, "Number of winners cannot be zero");
        require(_maximumTicketsPerEntry > 0, "Maximum tickets cannot be zero");
        require(entryDeadline == 0, "Previous raffle has not ended");

        currentRaffle++;
        entryDeadline = _entryDeadline;

        totalEntries = 0;
        totalTickets = 0;
        numberOfWinners = _numberOfWinners;
        maximumTicketsPerEntry = _maximumTicketsPerEntry;

        _rewardTicketPrice = rewardTicketPrice;
        _tokenTicketPrice = tokenTicketPrice;
    }

    

    function endRaffle(bytes32 randomSeed, uint32 redrawsNeeded) external onlyOwner() {
        require(entryDeadline != 0, "No raffle is running");
        require(block.timestamp >= entryDeadline, "Raffle entry deadline has not passed");
        entryDeadline = 0;

        Raffle storage raffle = _raffles[currentRaffle];
        raffle.entryDeadline = entryDeadline;
        raffle.totalEntries = totalEntries;
        raffle.totalTickets = totalTickets;
        raffle.numberOfWinners = numberOfWinners;
        raffle.maximumTicketsPerEntry = maximumTicketsPerEntry;
        raffle.randomSeed = randomSeed;
        raffle.numberOfRedraws = redrawsNeeded;
    }



    // TODO this function is for testing only, remove in final version
    function updateRaffle(uint16 _numberOfWinners, uint16 _maximumTicketsPerEntry, uint32 _entryDeadline, uint48 rewardTicketPrice, uint48 tokenTicketPrice) external onlyOwner() {
        require(entryDeadline != 0, "No raffle is running");
        require(_entryDeadline > block.timestamp, "Deadline for entry must be in the future");
        require(_numberOfWinners > 0, "Number of winners cannot be zero");
        require(_maximumTicketsPerEntry > 0, "Maximum tickets cannot be zero");

        entryDeadline = _entryDeadline;

        numberOfWinners = _numberOfWinners;
        maximumTicketsPerEntry = _maximumTicketsPerEntry;

        _rewardTicketPrice = rewardTicketPrice;
        _tokenTicketPrice = tokenTicketPrice;
    }

    function getRaffle(uint256 raffle) external view returns (Raffle memory) {
        return _raffles[raffle];
    }

    function getRandomValue(bytes32 randomSeed, uint256 index) external pure returns (uint256 randomValue) {
        randomValue = uint256(keccak256(abi.encode(randomSeed, index)));
    }

    function getRandomUniformValue(bytes32 randomSeed, uint256 index, uint256 upperBound) external pure returns (uint256) {
        uint256 randomValue = uint256(keccak256(abi.encode(randomSeed, index)));
        return _randomUniform(randomValue, upperBound);
    }


    function _randomUniform(uint256 randomValue, uint256 upperBound) private pure returns (uint256) {
        unchecked {
            uint256 min = uint256(-int256(upperBound)) % upperBound;
            while (randomValue < min) {
                randomValue = uint256(keccak256(abi.encodePacked(randomValue)));
            }
            return randomValue % upperBound;
        }
    }
    

    function isWinner(address account) external view returns (uint256) {
        Entry storage entry = _entries[account];
        Raffle storage raffle = _raffles[entry.raffle];
        uint256 ticketCount = raffle.totalTickets;
        require(ticketCount > 0, "Invalid raffle");

        uint256 min = entry.ticketPosition;
        uint256 max = min + entry.tickets;
        bytes32 randomSeed = raffle.randomSeed;
        uint256 drawCount = raffle.numberOfWinners;
        if (drawCount > ticketCount) {
            drawCount = ticketCount;
        }
        drawCount += raffle.numberOfRedraws;
        for (uint256 winnerIndex=0; winnerIndex<drawCount; winnerIndex++) {
            uint256 randomValue = uint256(keccak256(abi.encode(randomSeed, winnerIndex)));
            uint256 winningIndex = _randomUniform(randomValue, ticketCount);
            if (winningIndex >= min && winningIndex < max) {
                return winnerIndex;
            }
        }

        revert("Not a winner");
    }

    function claimPrize(uint256 winnerIndex) external {
        Entry storage entry = _entries[_msgSender()];
        Raffle storage raffle = _raffles[entry.raffle];
        uint256 ticketCount = raffle.totalTickets;
        require(ticketCount > 0, "Invalid raffle");

        unchecked {
            uint256 min = entry.ticketPosition;
            uint256 max = min + entry.tickets;
            bytes32 randomSeed = raffle.randomSeed;
            uint256 drawCount = raffle.numberOfWinners;
            if (drawCount > ticketCount) {
                drawCount = ticketCount;
            }
            drawCount += raffle.numberOfRedraws;
            require(winnerIndex < drawCount, "Invalid winnerIndex");
            uint256 randomValue = uint256(keccak256(abi.encode(randomSeed, winnerIndex)));
            uint256 winningIndex = _randomUniform(randomValue, ticketCount);
            require(winningIndex >= min && winningIndex < max, "You did not win");
        }
        entry.tickets = 0;

        // TODO add minting of prize
    }

   

    function enterRaffle(uint16 tickets) external {
        require(block.timestamp < entryDeadline, "Deadline for entering has passed");
        require(tickets > 0, "Cannot enter without tickets");
        require(tickets <= maximumTicketsPerEntry, "Tickets exceed maximum per entry");
        require(_rewardTicketPrice > 0, "Entering raffle with rewards not enabled");
        address account = _msgSender();
        unchecked {
            IERC20Burn(REWARD_ADDRESS).burnFrom(account, tickets * _rewardTicketPrice * 10**9);
        }

        uint32 entryTicketPosition = totalTickets;

        Entry storage entry = _entries[account];
        require(entry.raffle != currentRaffle, "You already entered this raffle");            
        entry.raffle = currentRaffle;
        entry.ticketPosition = entryTicketPosition;
        entry.tickets = tickets;

        totalTickets = entryTicketPosition + tickets;
        totalEntries++;

        emit EnterRaffle(currentRaffle, account, entryTicketPosition, tickets);
    }

    function enterRaffleUsingTokens(uint16 tickets) external {
        require(block.timestamp < entryDeadline, "Deadline for entering has passed");
        require(tickets > 0, "Cannot enter without tickets");
        require(tickets <= maximumTicketsPerEntry, "Tickets exceed maximum per entry");
        require(_tokenTicketPrice > 0, "Entering raffle with tokens not enabled");
        address account = _msgSender();
        unchecked {
            IERC20Burn(TOKEN_ADDRESS).burnFrom(account, tickets * _tokenTicketPrice * 10**9);
        }

        uint32 entryTicketPosition = totalTickets;

        Entry storage entry = _entries[account];
        require(entry.raffle != currentRaffle, "You already entered this raffle");            
        entry.raffle = currentRaffle;
        entry.ticketPosition = entryTicketPosition;
        entry.tickets = tickets;

        totalTickets = entryTicketPosition + tickets;
        totalEntries++;

        emit EnterRaffle(currentRaffle, account, entryTicketPosition, tickets);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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