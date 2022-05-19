//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

    Planktoons market contract
      https://planktoons.io

*/

import {MerkleMarket, Order} from "./MerkleMarket.sol";
import {MerkleAirdrop} from "./MerkleAirdrop.sol";
import {NFTStaking} from "./NFTStaking.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

contract PlanktoonsMarket is MerkleMarket {
    // ---
    // Errors
    // ---

    /// @notice A purchase was attempted by an account that does not own or have
    /// any staked Planktoons NFTs
    error NotAHolder();

    // ---
    // Storage
    // ---

    string public constant name = "PlanktoonsMarket";

    /// @notice The Planktoons nft contract
    IERC721 public immutable nft;

    /// @notice The Planktoons staking contract.
    NFTStaking public immutable staking;

    /// @notice The Planktoons airdrop contract.
    MerkleAirdrop public immutable airdrop;

    constructor(
        IERC721 nft_,
        NFTStaking staking_,
        MerkleAirdrop airdrop_
    ) {
        nft = nft_;
        staking = staking_;
        airdrop = airdrop_;
    }

    // ---
    // End user functionality
    // ---

    /// @notice Purchase items from the marketplace
    function purchase(Order[] calldata orders) public virtual override {
        _assertHasNfts();
        return MerkleMarket.purchase(orders);
    }

    /// @notice Convenience function to claim from airdrop and staking contracts
    /// before purchasing from the market to save holders a few transactions.
    function claimAllAndPurchase(
        Order[] calldata orders,
        uint256 airdropMaxClaimable,
        bytes32[] calldata airdropProof
    ) external {
        _assertHasNfts();

        // if nothing staked, nop is safe
        staking.claimFor(msg.sender);

        // only attempt airdrop claim if > 0, allows skipping by setting max
        // claimable to 0 and passing in an empty array as proof
        if (airdropMaxClaimable > 0) {
            airdrop.claimFor(msg.sender, airdropMaxClaimable, airdropProof);
        }

        purchase(orders);
    }

    function _assertHasNfts() internal view {
        uint256 owned = nft.balanceOf(msg.sender) +
            staking.getStakedBalance(msg.sender);
        if (owned == 0) {
            revert NotAHolder();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

struct Order {
    string itemId;
    IERC20 token;
    uint256 unitPrice;
    uint256 maxAmount;
    bytes32[] proof;
    uint256 amount;
}

/// @notice Simple vending machine (eg, for community prizes) that stores
/// inventory off chain and requires a proof to be submitted when purchasing
contract MerkleMarket is Ownable {
    // ---
    // Events
    // ---

    /// @notice An item was purchased from the market
    event ItemPurchased(
        string itemId,
        IERC20 token,
        uint256 unitPrice,
        uint256 amount
    );

    // ---
    // Errors
    // ---

    /// @notice A purchase was attempted for an item that is out of stock.
    error NoRemainingSupply();

    /// @notice A purchase was attempted with an invalid inventory proof.
    error InvalidItem();

    // ---
    // Storage
    // ---

    /// @notice The merkle root of the inventory tree.
    bytes32 public inventoryRoot;

    // item ID -> total purchased so far
    mapping(string => uint256) private _purchased;

    // ---
    // Admin functionality
    // ---

    /// @notice Set the merkle root of the inventory tree.
    function setInventoryRoot(bytes32 root) public onlyOwner {
        inventoryRoot = root;
    }

    /// @notice Withdraw tokens from the marketplace.
    function withdraw(IERC20 token) external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    // ---
    // Main functionality
    // ---

    /// @notice Purchase items from the marketplace
    function purchase(Order[] calldata orders) public virtual {
        for (uint256 i = 0; i < orders.length; i++) {
            bool isValid = MerkleProof.verify(
                orders[i].proof,
                inventoryRoot,
                keccak256(
                    abi.encodePacked(
                        orders[i].itemId,
                        orders[i].token,
                        orders[i].unitPrice,
                        orders[i].maxAmount
                    )
                )
            );

            if (!isValid) revert InvalidItem();

            // make sure there is remaining supply and update the total purchase
            // count for this item
            uint256 nextCount = _purchased[orders[i].itemId] + orders[i].amount;
            if (nextCount > orders[i].maxAmount) revert NoRemainingSupply();
            _purchased[orders[i].itemId] = nextCount;

            // execute the token transfer
            orders[i].token.transferFrom(
                msg.sender,
                address(this),
                orders[i].unitPrice * orders[i].amount
            );

            emit ItemPurchased(
                orders[i].itemId,
                orders[i].token,
                orders[i].unitPrice,
                orders[i].amount
            );
        }
    }

    // ---
    // Views
    // ---

    /// @notice Get the total purchased count for as specific item.
    function getTotalPurchased(string calldata itemId)
        external
        view
        returns (uint256)
    {
        return _purchased[itemId];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @notice Simple merkle airdrop contract. Claimed tokens come from reserves
/// held by the contract
contract MerkleAirdrop is Ownable {
    // ---
    // Events
    // ---

    /// @notice Tokens were claimed for a recipient
    event TokensClaimed(address recipient, uint256 amount);

    // ---
    // Errors
    // ---

    /// @notice The contract has already been set up
    error AlreadySetup();

    /// @notice A claim was attempted with an invalid claim list proof.
    error InvalidClaim();

    /// @notice A claim on behalf of another address came from an account with no allowance.
    error NotApproved();

    // ---
    // Storage
    // ---

    /// @notice The merkle root of the claim list tree.
    bytes32 public claimListRoot;

    /// @notice The airdropped token
    IERC20 public token;

    // tokens claimed so far
    mapping(address => uint256) private _claimed;

    // ---
    // Admin
    // ---

    /// @notice Set the airdropped token, merkle root, and do an initial
    /// deposit. Only callable by owner, only callable once.
    function setup(
        IERC20 token_,
        uint256 deposit,
        bytes32 root
    ) external onlyOwner {
        if (token != IERC20(address(0))) revert AlreadySetup();

        token = token_;
        claimListRoot = root;

        // reverts if contract not approved to spend msg.sender tokens
        // reverts if insufficient balance in msg.sender
        // reverts if invalid token reference
        // reverts if deposit = 0
        token_.transferFrom(msg.sender, address(this), deposit);
    }

    /// @notice Set the merkle root of the claim tree. Only callable by owner.
    function setClaimListRoot(bytes32 root) external onlyOwner {
        claimListRoot = root;
    }

    // ---
    // End users
    // ---

    /// @notice Claim msg.sender's airdropped tokens.
    function claim(uint256 maxClaimable, bytes32[] calldata proof)
        external
        returns (uint256)
    {
        return _claimFor(msg.sender, maxClaimable, proof);
    }

    /// @notice Permissionlessly claim tokens on behalf of another account.
    function claimFor(
        address recipient,
        uint256 maxClaimable,
        bytes32[] calldata proof
    ) external returns (uint256) {
        return _claimFor(recipient, maxClaimable, proof);
    }

    function _claimFor(
        address recipient,
        uint256 maxClaimable,
        bytes32[] calldata proof
    ) internal returns (uint256) {
        bool isValid = MerkleProof.verify(
            proof,
            claimListRoot,
            keccak256(abi.encodePacked(recipient, maxClaimable))
        );

        if (!isValid) revert InvalidClaim();

        uint256 claimed = _claimed[recipient];
        uint256 toClaim = claimed < maxClaimable ? maxClaimable - claimed : 0;

        // allow silent / non-reverting nop
        if (toClaim == 0) return 0;

        _claimed[recipient] = maxClaimable;
        emit TokensClaimed(recipient, toClaim);

        // reverts if insufficient reserve balance
        token.transfer(recipient, toClaim);

        return toClaim;
    }

    // ---
    // Views
    // ---

    /// @notice Returns the total amount of tokens claimed for an account
    function totalClaimed(address account) external view returns (uint256) {
        return _claimed[account];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

struct AccountStake {
    // buffered rewards... tokens earned by an account but not yet distributed.
    // 96 bit int -> 79 billion max earned token accumulator
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
    function depositRewards(uint256 amount, uint256 cutoff) external onlyOwner {
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
        _stakes[msg.sender].stakedCount -= uint32(tokenIds.length); // reverts on overflow

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
        _stakes[msg.sender].stakedCount -= uint32(tokenIds.length); // reverts on overflow

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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