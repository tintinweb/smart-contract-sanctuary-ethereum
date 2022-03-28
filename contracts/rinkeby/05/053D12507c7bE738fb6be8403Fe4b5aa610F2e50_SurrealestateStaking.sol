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

    function ownerOf(uint256 tokenId) external view returns (address);
}

// A listening contract can implement this function to get notified any time a user stakes or unstakes.
interface IStakingListener {
    function notifyChange(address account) external;
}

contract SurrealestateStaking is ERC721Holder, Ownable {
    IPPASurrealestates surrealestates;
    address surrealestateContractAddress;

    constructor() public {
        surrealestateContractAddress = _getSurrealestatesContractAddress();
        surrealestates = IPPASurrealestates(surrealestateContractAddress);
    }

    function _getSurrealestatesContractAddress()
        internal
        view
        returns (address)
    {
        address addr;
        assembly {
            switch chainid()
            case 1 {
                // mainnet
                addr := 0x6f3185b51a42e03a4f0eaaf37604ddd499ef9b12
            }
            case 4 {
                // rinkeby
                addr := 0x6551111b5d3C7e4B5436409C2e70A8Fbe1757407
            }
        }
        return addr;
    }

    // The period which people can lock their funds up for to get an extra multiplier on rewards earned.
    uint256 stakingLockPeriod = 7776000; // 90 days in seconds.

    struct StakingMultiplier {
        uint256 numeratorMinus1; // Store as "minus 1" because we want this to default to 1, but uninitialized vars default to 0.
        uint256 denominatorMinus1;
    }

    struct AccountInfo {
        uint256 numStaked;
        uint256 pointsStaked;
        uint256 lastRefreshTimestamp;
        uint256 tokensEarnedBeforeLastRefresh;
        // A multiplier defaults to 1 but can be set by a manager in the future for a particular address. This increases
        // the overall rate of earning.
        StakingMultiplier stakingMultiplier;
    }
    mapping(address => AccountInfo) public accounts;

    struct TokenInfo {
        bool isLocked;
        uint256 lockedUntil;
        address owner;
    }
    mapping(uint256 => TokenInfo) public tokens;

    // Addresses that are allowed to do things like deduct tokens from a user's account or award earning multipliers.
    mapping(address => bool) public approvedManagers;

    IStakingListener[] listeners;

    // Earning period for a surrealestate. Default to 10 hours.
    uint256 public earnPeriodSeconds = 36000;

    modifier onlyApprovedManager() {
        require(
            owner() == msg.sender || approvedManagers[msg.sender],
            "Caller is not an approved manager"
        );
        _;
    }

    function _notifyAllListeners(address account) internal {
        for (uint256 i = 0; i < listeners.length; i++) {
            listeners[i].notifyChange(account);
        }
    }

    /** User must setApprovalForAll on the contract before staking. */
    function stake(uint256[] calldata tokenIds, bool lock) public {
        refreshTokensEarned(msg.sender);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                surrealestates.ownerOf(tokenIds[i]) == msg.sender,
                "Not your token"
            );

            surrealestates.transferFrom(msg.sender, address(this), tokenIds[i]);
            tokens[tokenIds[i]].owner = msg.sender;
            accounts[msg.sender].pointsStaked += pointsByTokenId(tokenIds[i]);
        }
        accounts[msg.sender].numStaked += tokenIds.length;

        if (lock) {
            uint256 lockUntil = block.timestamp + stakingLockPeriod;
            for (uint256 i = 0; i < tokenIds.length; i++) {
                tokens[tokenIds[i]].lockedUntil = lockUntil;
                tokens[tokenIds[i]].isLocked = true;
                accounts[msg.sender].pointsStaked += pointsByTokenId(
                    tokenIds[i]
                );
            }
        }

        _notifyAllListeners(msg.sender);
    }

    /**
     * User can lock their staking in for the stakingLockPeriod, which increases their multiplier.
     */
    function lockStaking(uint256[] calldata tokenIds) public {
        refreshTokensEarned(msg.sender);
        uint256 lockUntil = block.timestamp + stakingLockPeriod;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokens[tokenIds[i]].owner == msg.sender,
                "Token is not currently staked"
            );
            require(
                tokens[tokenIds[i]].lockedUntil < block.timestamp,
                "Token is already locked"
            );
            if (!tokens[tokenIds[i]].isLocked) {
                tokens[tokenIds[i]].isLocked = true;
                accounts[msg.sender].pointsStaked += pointsByTokenId(
                    tokenIds[i]
                );
            }
            tokens[tokenIds[i]].lockedUntil = lockUntil;
        }
        _notifyAllListeners(msg.sender);
    }

    function refreshTokensEarned(address addr) internal {
        if (block.timestamp == accounts[addr].lastRefreshTimestamp) {
            // No need to refresh anything if we're up to date.
            return;
        }
        if (accounts[addr].lastRefreshTimestamp == 0) {
            // If this is the first refresh ever done, then just set the timestamp and return.
            accounts[addr].lastRefreshTimestamp = block.timestamp;
            return;
        }

        uint256 totalTokensEarned = calculateTokensEarned(addr);
        accounts[addr].tokensEarnedBeforeLastRefresh = totalTokensEarned;
        accounts[addr].lastRefreshTimestamp = block.timestamp;
    }

    function calculateTokensEarned(address addr) public view returns (uint256) {
        uint256 secondsStakedSinceLastRefresh = block.timestamp -
            accounts[addr].lastRefreshTimestamp;

        uint256 tokensEarnedSinceLastRefresh = (secondsStakedSinceLastRefresh *
            (accounts[addr].pointsStaked) *
            (accounts[addr].stakingMultiplier.numeratorMinus1 + 1)) /
            (accounts[addr].stakingMultiplier.denominatorMinus1 + 1) /
            earnPeriodSeconds;
        return
            accounts[addr].tokensEarnedBeforeLastRefresh +
            tokensEarnedSinceLastRefresh;
    }

    /**
     * To unstake, the user calls this function with the tokenIds they want to unstake.
     */
    function unstake(uint256[] calldata tokenIds) public {
        refreshTokensEarned(msg.sender);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokens[tokenIds[i]].owner == msg.sender,
                "Caller is not currently staking the provided tokenId"
            );
            _unstakeSingle(tokenIds[i]);
        }
        accounts[msg.sender].numStaked -= tokenIds.length;
        _notifyAllListeners(msg.sender);
    }

    // Caller is responsible for deducted accounts[addr].numStaked
    function _unstakeSingle(uint256 tokenId) internal {
        require(
            tokens[tokenId].lockedUntil < block.timestamp,
            "Token is still locked"
        );
        accounts[tokens[tokenId].owner].pointsStaked -= pointsByTokenId(
            tokenId
        );

        // If we are past the token locktime, then we need to update the the lockedTokens map as well.
        if (tokens[tokenId].isLocked) {
            tokens[tokenId].isLocked = false;
            // Deduct again because it was locked, so it was earning double.
            accounts[tokens[tokenId].owner].pointsStaked -= pointsByTokenId(
                tokenId
            );
        }

        surrealestates.transferFrom(address(this), msg.sender, tokenId);

        tokens[tokenId].owner = address(0);
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
        earnPeriodSeconds = newSeconds;
    }

    function setEarningMultiplier(
        address addr,
        uint256 numerator,
        uint256 denominator
    ) public onlyApprovedManager {
        refreshTokensEarned(addr);
        accounts[addr].stakingMultiplier = StakingMultiplier(
            numerator - 1,
            denominator - 1
        );
    }

    function addStakingListener(address contractAddress) public onlyOwner {
        listeners.push(IStakingListener(contractAddress));
    }

    function resetStakingListeners() public onlyOwner {
        delete listeners;
    }

    // Do not use in actual transaction due to massive gas cost.
    function stakedTokensOfOwner(
        address addr,
        uint256 start,
        uint256 stop
    ) public view returns (uint256[] memory) {
        if (accounts[addr].numStaked == 0) {
            return new uint256[](0);
        }

        uint256 index = 0;
        uint256[] memory ownedTokens = new uint256[](accounts[addr].numStaked);

        for (uint256 tokenId = start; tokenId <= stop; tokenId++) {
            if (tokens[tokenId].owner == addr) {
                ownedTokens[index] = tokenId;
                index++;
                if (index == accounts[addr].numStaked) {
                    break;
                }
            }
        }

        return ownedTokens;
    }

    // Only for use in emergency. Can be called by owner to unstake. Does not update the rest of the contract state.
    function unstakeAsOwner(address addr, uint256[] calldata tokenIds)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            surrealestates.transferFrom(address(this), addr, tokenIds[i]);
        }
    }

    function pointsByTokenId(uint256 tokenId) public view returns (uint256) {
        return 1000 + uint256(uint8(rawPointsByTokenId[tokenId]));
    }

    function setRawPoints(bytes memory newRawPoints) public onlyOwner {
        rawPointsByTokenId = newRawPoints;
    }

    bytes rawPointsByTokenId;
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