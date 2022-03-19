// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

// The NFT that can be staked here.
interface IPPASurrealestates {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// A listening contract can implement this function to get notified any time a user stakes or unstakes.
interface IStakingListener {
    function notifyChange(address account) external;
}

contract SurrealestateStaking is ERC721Holder, Ownable {
    constructor() public {}

    IPPASurrealestates surrealestates;
    address surrealestateContractAddress;

    // The period which people can lock their funds up for to get an xtra multiplier on rewards earned.
    uint256 stakingLockPeriod = 7776000; // 90 days in seconds.

    // (UserAddress => (TokenID => Owned?))
    mapping(address => mapping(uint256 => bool)) public ownerships;
    // Helper list for easy lookup of what Surrealestates an individual has ever staked.
    mapping(address => uint256[]) public tokensTouched;
    // How many Surrealestates an individual is currently staking.
    mapping(address => uint256) public numStakedByAddress;
    // How many Surrealestates are locked in staking by this invididual.
    mapping(address => uint256) public numLockedByAddress;
    // Whether a token is currently recorded as locked.
    mapping(uint256 => bool) public lockedTokens;
    // (TokenID => Timestamp))
    mapping(uint256 => uint256) public tokenLockedUntil;
    // Any time a user interacts with the contract, their rewards up to that point will be calculated and saved.
    mapping(address => uint256) private _tokensEarnedBeforeLastRefresh;
    // Each user has a particular staking refresh timestamp (i.e. last time their rewards were calculated and saved)/
    mapping(address => uint256) private _stakingRefreshTimestamp;
    // Addresses that are allowed to do things like deduct tokens from a user's account or award earning multipliers.
    mapping(address => bool) public approvedManagers;
    // A multiplier defaults to 1 but can be set by a manager in the future for a particular address. This increases
    // the overall rate of earning.
    mapping(address => StakingMultiplier) public stakingMultiplier;

    IStakingListener[] listeners;

    struct StakingMultiplier {
        uint256 numeratorMinus1; // Store as "minus 1" because we want this to default to 1, but uninitialized vars default to 0.
        uint256 denominatorMinus1;
    }

    // Number of seconds a surrealestate must be staked in order to earn 1 token.
    uint256 public earnPeriod = 60;

    modifier onlyApprovedManager() {
        require(
            owner() == msg.sender || approvedManagers[msg.sender],
            "Caller is not an approved manager"
        );
        _;
    }

    /**
     * To stake a Surrealestate, the user sends the ERC721 token to this contract address, which invokes
     * this function.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public virtual override returns (bytes4) {
        require(
            msg.sender == surrealestateContractAddress,
            "Can only receive Surrealestates NFTs"
        );
        refreshTokensEarned(from);

        ownerships[from][tokenId] = true;
        tokensTouched[from].push(tokenId);
        numStakedByAddress[from]++;
        _notifyAllListeners(from);

        return super.onERC721Received(operator, from, tokenId, data);
    }

    function _notifyAllListeners(address account) internal {
        for (uint256 i = 0; i < listeners.length; i++) {
            listeners[i].notifyChange(account);
        }
    }

    /**
     * User can lock their staking in for the stakingLockPeriod, which increases their multiplier.
     */
    function lockStaking(uint256 tokenId) public {
        require(
            ownerships[msg.sender][tokenId],
            "Caller does not own the token"
        );
        refreshTokensEarned(msg.sender);
        _lockStakingForSingleToken(tokenId);
    }

    /**
     * Lock up staking for all tokens the user has.
     */
    function lockStakingForAll() public {
        refreshTokensEarned(msg.sender);
        for (uint256 i = 0; i < tokensTouched[msg.sender].length; i++) {
            uint256 tokenId = tokensTouched[msg.sender][i];
            if (ownerships[msg.sender][tokenId]) {
                _lockStakingForSingleToken(tokenId);
            }
        }
    }

    function _lockStakingForSingleToken(uint256 tokenId) internal {
        if (tokenLockedUntil[tokenId] > block.timestamp) {
            // Token is already locked
            return;
        }
        if (!lockedTokens[tokenId]) {
            numLockedByAddress[msg.sender]++;
            lockedTokens[tokenId] = true;
        }
        tokenLockedUntil[tokenId] = block.timestamp + stakingLockPeriod;
    }

    function refreshTokensEarned(address addr) internal {
        uint256 totalTokensEarned = calculateTokensEarned(addr);
        _tokensEarnedBeforeLastRefresh[addr] = totalTokensEarned;
        _stakingRefreshTimestamp[addr] = block.timestamp;
    }

    function calculateTokensEarned(address addr) public view returns (uint256) {
        uint256 secondsStakedSinceLastRefresh = block.timestamp -
            _stakingRefreshTimestamp[addr];

        uint256 earnPeriodsSinceLastRefresh = secondsStakedSinceLastRefresh /
            earnPeriod;

        uint256 tokensEarnedAfterLastRefresh = (earnPeriodsSinceLastRefresh *
            (numStakedByAddress[addr] + numLockedByAddress[addr]) *
            (stakingMultiplier[addr].numeratorMinus1 + 1)) /
            (stakingMultiplier[addr].denominatorMinus1 + 1);
        return
            _tokensEarnedBeforeLastRefresh[addr] + tokensEarnedAfterLastRefresh;
    }

    /**
     * To unstake, the user calls this function with the tokenID they want to unstake.
     */
    function unstake(uint256 tokenId) public {
        require(
            ownerships[msg.sender][tokenId],
            "Caller is not currently staking the provided tokenId"
        );

        refreshTokensEarned(msg.sender);
        _unstakeSingle(tokenId);
        _notifyAllListeners(msg.sender);
    }

    /**
     * User can unstake all their NFTs at once.
     */
    function unstakeAll() public {
        refreshTokensEarned(msg.sender);
        for (uint256 i = 0; i < tokensTouched[msg.sender].length; i++) {
            uint256 tokenId = tokensTouched[msg.sender][i];
            if (ownerships[msg.sender][tokenId]) {
                _unstakeSingle(tokenId);
            }
        }
        _notifyAllListeners(msg.sender);
    }

    function _unstakeSingle(uint256 tokenId) internal {
        if (tokenLockedUntil[tokenId] > block.timestamp) {
            // Skip ones that are locked.
            return;
        }

        // If we are past the token locktime, then we need to update the the lockedTokens map as well.
        if (lockedTokens[tokenId]) {
            lockedTokens[tokenId] = false;
            numLockedByAddress[msg.sender]--;
        }

        surrealestates.transferFrom(address(this), msg.sender, tokenId);

        ownerships[msg.sender][tokenId] = false;
        numStakedByAddress[msg.sender]--;
    }

    function addApprovedManager(address managerAddr) public onlyOwner {
        approvedManagers[managerAddr] = true;
    }

    function removeApprovedManager(address managerAddr) public onlyOwner {
        approvedManagers[managerAddr] = false;
    }

    function setStakingLockPeriod(uint256 newPeriod)
        public
        onlyApprovedManager
    {
        stakingLockPeriod = newPeriod;
    }

    function setEarnPeriod(uint256 newSeconds) public onlyApprovedManager {
        earnPeriod = newSeconds;
    }

    function setEarningMultiplier(
        address addr,
        uint256 numerator,
        uint256 denominator
    ) public onlyApprovedManager {
        refreshTokensEarned(addr);
        stakingMultiplier[addr] = StakingMultiplier(
            numerator - 1,
            denominator - 1
        );
    }

    function setSurrealestateContract(address newAddress) public onlyOwner {
        surrealestateContractAddress = newAddress;
        surrealestates = IPPASurrealestates(newAddress);
    }

    function addStakingListener(address contractAddress) public onlyOwner {
        listeners.push(IStakingListener(contractAddress));
    }

    function resetStakingListeners() public onlyOwner {
        delete listeners;
    }

    // Only for use in emergency. Can be called by owner to unstake.
    function unstakeAllAsOwner(address addr) public onlyOwner {
        for (uint256 i = 0; i < tokensTouched[addr].length; i++) {
            uint256 tokenId = tokensTouched[addr][i];
            if (ownerships[addr][tokenId]) {
                surrealestates.transferFrom(address(this), addr, tokenId);
                ownerships[addr][tokenId] = false;
                numStakedByAddress[addr]--;
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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