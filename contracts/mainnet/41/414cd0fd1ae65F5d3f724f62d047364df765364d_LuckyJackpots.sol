// SPDX-License-Identifier: NONE

/**
 * LuckyToad v3 Jackpot Manager
 * Holds a list of winners to be dealt with
 */

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LuckyJackpots is Ownable {
    event WinPending(address indexed seller, uint256 ethWinnings, uint256 randomNumber);
    event JackpotWin(address indexed winner, uint256 winnings, uint256 randomSeedUsed);
    event ClaimManually(address indexed winner, uint256 winnings);
    struct WinToProcess {
        uint256 randomNumber;
        uint256 ethWinnings;
        address seller;
    }
    struct ManuallyClaimableWin {
        uint256 ethWinnings;
        address winner;
    }

    modifier onlyProcessingBot() {
        require(msg.sender == processingBot, "LuckyJackpot: Only the bot can execute this.");
        _;
    }
    modifier onlyHeadContract() {
        require(msg.sender == topContract, "LuckyJackpot: Only the bot can execute this.");
        _;
    }


    modifier reentrancyGuard() {
        require(!_reentrancySemaphore, "LuckyJackpot: Pls do not rentrancy us.");
        _reentrancySemaphore = true;
        _;
        _reentrancySemaphore = false;
    }
    address private processingBot;
    
    bool private _reentrancySemaphore = false;

    WinToProcess[] private pendingWins;

    ManuallyClaimableWin[] private failedSends;

    address private topContract;

    constructor(address bot) {
        topContract = msg.sender;
        processingBot = bot;
    }
    /// @notice Changes the processing bot address. Only settable by CA owner.
    /// @param newBot the new bot to set
    function changeProcessingBot(address newBot) public onlyOwner {
        processingBot = newBot;
    }
    function changeTopContract(address newContract) public onlyOwner {
        topContract = newContract;
    }

    /// @notice Generates a pseudo-random number - don't rely on for crypto
    function generateNumber() private view returns (uint256 result) {
        result = uint256(keccak256(abi.encode(blockhash(block.number-1))));
    }
    /// @notice Adds a pending win from a sell - only callable by contract and the value of ETH should be sent
    /// @param seller the seller, so we can exclude them

    function addPendingWin(address seller) external payable onlyHeadContract {
        uint256 rng = generateNumber();
        pendingWins.push(WinToProcess(rng, msg.value, seller));
        emit WinPending(seller, msg.value, rng);
    }

    /// @notice Get the lists of pending wins
    function getPendingWins() public view returns (uint256[] memory rngs, uint256[] memory winnings, address[] memory sellers) {
        rngs = new uint256[](pendingWins.length);
        winnings = new uint256[](pendingWins.length);
        sellers = new address[](pendingWins.length);
        for(uint i = 0; i < pendingWins.length; i++) {
            rngs[i] = pendingWins[i].randomNumber;
            winnings[i] = pendingWins[i].ethWinnings;
            sellers[i] = pendingWins[i].seller;
        }
    }


    function processPendingWin(uint256 index, address receipient, uint256 processingCost) public onlyProcessingBot reentrancyGuard {
        processWinInternal(index, receipient, processingCost);
        // Check if it's the very end of the list
        if(index != pendingWins.length-1) {
            // It's not, so move the end to the index we wish to erase
            pendingWins[index] = pendingWins[pendingWins.length-1];
        }
        // Pop the end - if our pending win is the end, it's okay, if not we made a copy of the end
        pendingWins.pop();
    }

    function processWinInternal(uint256 index, address winner, uint256 processingCost) private {
        uint256 winAmount = pendingWins[index].ethWinnings;
        (bool success,) = winner.call{gas: 50000, value: winAmount-processingCost}("");
        payable(msg.sender).transfer(processingCost);
        if(success) {
            emit JackpotWin(winner, winAmount-processingCost, pendingWins[index].randomNumber);
        } else {
            failedSends.push(ManuallyClaimableWin(winAmount-processingCost, winner));
            emit ClaimManually(winner, winAmount-processingCost);
        }
    }
    /// @notice Process a list of indexes and winners. Ensure the indexes are ascending. 
    function processPendingWins(uint256[] calldata indexes, address[] calldata recipients, uint256[] calldata processingCosts) external onlyProcessingBot reentrancyGuard {
        require(indexes.length == recipients.length && indexes.length == processingCosts.length, "LuckyJackpot: Length of arrays must match.");
        for(uint i = 0; i < indexes.length; i++) {
            processWinInternal(indexes[i], recipients[i], processingCosts[i]);
        }
        // Need to be a little more careful here, as we have multiple indexes to remove
        uint indexLen = indexes.length-1;
        for(uint i = 0; i < indexes.length; i++) {
            // i is, from the end, how many
            if(indexes[indexLen-i] != pendingWins.length) {
                // Copy the end to the current index, if necessary
                pendingWins[indexes[indexLen-i]] = pendingWins[pendingWins.length-1];
            }
            // Delete the end
            pendingWins.pop();
        }
    }

    /// @notice Claim the first win for this address
    function manualClaim(address winner) public reentrancyGuard {
        // Find the first win in failedSends
        for(uint i = 0; i < failedSends.length; i++) {
            if(failedSends[i].winner == winner) {
                (bool success,) = winner.call{value: failedSends[i].ethWinnings}("");
                require(success, "LuckyJackpot: Send failed.");
                // Delete the winner
                if(i != failedSends.length-1) {
                    failedSends[i] = failedSends[failedSends.length-1];
                }
                failedSends.pop();
                break;
            }
        }
    }

    function withdrawGas(uint256 amount) public onlyProcessingBot {
        // Withdraw the gas fee to be spent on running a sell
        payable(processingBot).transfer(amount);
    }

    function withdrawFees(uint256 amount) public onlyOwner {
        // Withdraw excess fees for owner
        payable(owner()).transfer(amount);
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