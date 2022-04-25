//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {NFTStaking} from "./NFTStaking.sol";

contract PlanktoonsStaking is NFTStaking {
  string constant public name = "PlanktoonsStaking";
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

struct AccountStake {
    // buffered rewards... tokens earned by an account but not yet distributed
    uint96 earned;
    // the last time a claim occured
    uint96 lastClaimTime;
    // the total count of NFTs staked
    uint32 stakedCount;
    // token ID -> isStaked flag
    mapping(uint256 => bool) stakedTokens;
}

/// @notice A simple NFT staking contract to emit deposited reserves to stakers
/// as claimable tokens.
contract NFTStaking is Ownable {
    /// @notice The amount of tokens that are emitted per day per NFT.
    uint256 public constant DAILY_RATE = 1 * 10**18;

    // ---
    // Storage
    // ---

    /// @notice The NFT that can be staked in this contract.
    IERC721 public nft;

    /// @notice The token that is rewarded for staking.
    IERC20 public token;

    //// @notice Generate rewards up until this timestamp
    uint256 public rewardUntilTimestamp = block.timestamp + 365 days;

    // all staking data by owner address
    mapping(address => AccountStake) private _stakes;

    // ---
    // Events
    // ---

    /// @notice An NFT was staked into the contract.
    event NFTStaked(address owner, uint256 tokenId);

    /// @notice An NFT was unstaked from the contract.
    event NFTUnstaked(address owner, uint256 tokenId);

    /// @notice Tokens were claimed.
    event TokensClaimed(address owner, uint256 amount);

    // ---
    // Errors
    // ---

    /// @notice Setup was attempted more than once.
    error AlreadySetup();

    /// @notice A token was attempted to be staked that wasn't owned by the staker.
    error NotTokenOwner();

    /// @notice An invalid NFT was attempted to be unstaked (eg, not owned or staked)
    error InvalidUnstake();

    /// @notice Reward end timestamp was set to an earlier date
    error InvalidRewardUntilTimestamp();

    // ---
    // Admin functionality
    // ---

    /// @notice Set the NFT and token contracts.
    function setup(
        IERC721 nft_,
        IERC20 token_,
        uint256 deposit_
    ) external onlyOwner {
        if (nft != IERC721(address(0))) revert AlreadySetup();

        nft = nft_;
        token = token_;

        // reverts if contract not approved to spend msg.sender tokens
        // reverts if insufficient balance in msg.sender
        // reverts if invalid token reference
        // reverts if deposit = 0
        token_.transferFrom(msg.sender, address(this), deposit_);
    }

    /// @notice Deposit more reward tokens (if amount > 0) and update the
    /// rewards cutoff date (if cutoff > 0))
    function depositRewards(uint256 amount, uint256 cutoff) external {
        if (amount > 0) {
            // reverts if contract not approved to spend msg.sender tokens
            // reverts if insufficient balance in msg.sender
            // reverts if staking not set up
            token.transferFrom(msg.sender, address(this), amount);
        }

        if (cutoff > 0) {
            if (cutoff < rewardUntilTimestamp)
                revert InvalidRewardUntilTimestamp();
            rewardUntilTimestamp = cutoff;
        }
    }

    // ---
    // Holder functionality
    // ---

    /// @notice Stake multiple NFTs
    function stakeNFTs(uint256[] memory tokenIds) external {
        // flush rewards to accumulator, basically buffers the current claim
        // since we are about the change the "rate" of rewards when we stake
        // more NFTs
        _stakes[msg.sender].earned = uint96(getClaimable(msg.sender));
        _stakes[msg.sender].lastClaimTime = uint96(block.timestamp);
        _stakes[msg.sender].stakedCount += uint32(tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            // reverts if nft isnt owned by caller
            // reverts if already staked (eg, a duplicate token ID)
            if (nft.ownerOf(tokenId) != msg.sender) revert NotTokenOwner();

            _stakes[msg.sender].stakedTokens[tokenId] = true;
            emit NFTStaked(msg.sender, tokenId);

            // reverts if contract not approved to move nft tokens
            // reverts if contract is not set up
            nft.transferFrom(msg.sender, address(this), tokenId);
        }
    }

    /// @notice Claim all earned tokens for msg.sender
    function claim() external {
        _claimFor(msg.sender);
    }

    /// @notice Permissionlessly claim tokens on behalf of another account.
    function claimFor(address account) external {
        _claimFor(account);
    }

    /// @notice Claim all unearned tokens and unstake a subset of staked NFTs
    function claimAndUnstakeNFTs(uint256[] memory tokenIds) external {
        _claimFor(msg.sender);
        _stakes[msg.sender].stakedCount -= uint32(tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(msg.sender, tokenIds[i]);
        }
    }

    /// @notice Unstake without claiming -- do not call unless NFTs are stuck
    /// due to insufficient rewards reserve balance.
    function emergencyUnstake(uint256[] memory tokenIds) external {
        // flush rewards to accumulator
        _stakes[msg.sender].earned = uint96(getClaimable(msg.sender));
        _stakes[msg.sender].lastClaimTime = uint96(block.timestamp);
        _stakes[msg.sender].stakedCount -= uint32(tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(msg.sender, tokenIds[i]);
        }
    }

    function _unstake(address account, uint256 tokenId) internal {
        if (!_stakes[account].stakedTokens[tokenId]) revert InvalidUnstake();
        delete _stakes[account].stakedTokens[tokenId];
        emit NFTUnstaked(account, tokenId);

        nft.transferFrom(address(this), account, tokenId);
    }

    function _claimFor(address account) internal {
        uint256 claimable = getClaimable(account);
        if (claimable == 0) return; // allow silent nop
        _stakes[account].earned = 0;
        _stakes[account].lastClaimTime = uint96(block.timestamp);
        emit TokensClaimed(account, claimable);

        // reverts if insufficient rewards reserves
        token.transfer(account, claimable);
    }

    // ---
    // Views
    // ---

    /// @notice Returns the total claimable tokens for a given account.
    function getClaimable(address account) public view returns (uint256) {
        // either claim up until now, or the rewards cutoff time if we've
        // already passed that date
        uint256 claimUntil = block.timestamp < rewardUntilTimestamp
            ? block.timestamp
            : rewardUntilTimestamp;

        uint256 delta = claimUntil - _stakes[account].lastClaimTime;
        uint256 emitted = (_stakes[account].stakedCount * DAILY_RATE * delta) /
            1 days;

        return emitted + _stakes[account].earned;
    }

    /// @notice Returns the total NFTs that have been staked by an account
    function getStakedBalance(address account) public view returns (uint256) {
        return _stakes[account].stakedCount;
    }

    /// @notice Returns true of a specific token ID has been staked by a specific address
    function isStakedForAccount(address account, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return _stakes[account].stakedTokens[tokenId];
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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