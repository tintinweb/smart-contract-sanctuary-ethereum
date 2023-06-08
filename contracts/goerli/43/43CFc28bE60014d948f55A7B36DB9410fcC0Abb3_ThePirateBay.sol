// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface CryptoPirates {
    function types(uint256) external view returns (uint256);
    function TYPE_COMMON() external view returns (uint256);
    function TYPE_RARE() external view returns (uint256);
    function TYPE_EPIC() external view returns (uint256);
    function TYPE_LEGENDARY() external view returns (uint256);
}

contract ThePirateBay is Ownable, IERC721Receiver, Pausable, ReentrancyGuard {
    // emergency rescue to allow unstaking without any checks
    bool public rescueEnabled = false;
    // address of the NFT contract
    IERC721 public nftAddress;
    // address of the ERC20 token
    IERC20 public tokenAddress;

    uint256 public amountPerNFT = 10_000_000 ether; // amount of tokens per NFT

    uint256 public totalStaked; // total amount of tokens staked
    uint256 public totalNFTsStaked; // total amount of NFTs staked
    uint256 public totalMultiplers; // total amount of multipliers

    uint256 public activeRewardId; // id of the active reward

    uint256 public constant COMMON_MULTIPLIER = 100; // 100%
    uint256 public constant RARE_MULTIPLIER = 125; // 200%
    uint256 public constant EPIC_MULTIPLIER = 200; // 300%
    uint256 public constant LEGENDARY_MULTIPLIER = 500; // 400%

    struct Reward {
        uint256 depositStartTime; // when the deposit starts
        uint256 lockStartTime; // when the lock starts
        uint256 totalLockTime; // how long the lock is
        uint256 totalReward; // total reward
        uint256 totalMultiplers; // total amount of multipliers
    }

    struct Stake {
        uint256 amount; // amount of tokens staked
        uint256[] nftIds; // array of NFTs staked
        uint256 lastRewardId; // id of the reward
        uint256 lastClaimedRewardId; // id of the last claimed reward
        uint256 earned; // amount of tokens earned
    }

    // tracks location of each nft
    mapping(uint256 => uint256) private nftIdsIndexes;

    Reward[] public rewards;
    mapping(address => Stake) public stakes;

    event RewardAdded(uint256 indexed rewardId, uint256 _depositStartTime, uint256 _lockStartTime, uint256 _totalLockTime, uint256 _totalReward);
    event Staked(address indexed user, uint256 amount, uint256[] nftIds, uint256 lastRewardId);
    event Unstaked(address indexed user, uint256 amount, uint256[] nftIds, uint256 lastRewardId);
    event Claimed(address indexed user, uint256 amount, uint256 lastRewardId); 

    constructor(address _nftAddress, address _tokenAddress) {
        nftAddress = IERC721(_nftAddress);
        tokenAddress = IERC20(_tokenAddress);
    }

    function addReward(
        uint256 _depositStartTime,
        uint256 _lockStartTime,
        uint256 _totalLockTime,
        uint256 _totalReward
    ) external onlyOwner {
        require(_depositStartTime > block.timestamp, "Cannot add reward with 0 deposit start time");
        require(_lockStartTime > block.timestamp, "Cannot add reward with 0 lock start time");
        require(_depositStartTime > rewards[activeRewardId].lockStartTime + rewards[activeRewardId].totalLockTime, "Cannot add reward with deposit start time before active reward finishes");
        require(_totalReward > 0, "Cannot add reward with 0 reward");
        require(_totalLockTime > 0, "Cannot add reward with 0 lock time");

        // transfer tokens to contract
        tokenAddress.transferFrom(msg.sender, address(this), _totalReward);
        // add reward
        uint256 rewardId = rewards.length;
        rewards.push(Reward({
            depositStartTime: block.timestamp,
            lockStartTime: _lockStartTime,
            totalLockTime: _totalLockTime,
            totalReward: _totalReward,
            totalMultiplers: 0
        }));

        emit RewardAdded(
            rewardId,
            _depositStartTime,
            _lockStartTime,
            _totalLockTime,
            _totalReward
        );
    }

    /// @dev allows user to stake tokens and NFTs
    /// @param _nftIds ids of the NFTs to stake
    function stake(uint256[] calldata _nftIds) external nonReentrant whenNotPaused {
        require(_nftIds.length > 0, "Cannot stake 0 NFTs");
        Reward memory reward = rewards[activeRewardId];
        require(reward.depositStartTime > 0, "Cannot stake before reward is added");
        require(reward.depositStartTime < block.timestamp, "Cannot stake before deposit start time");
        require(reward.lockStartTime > block.timestamp, "Cannot stake after lock started");
        
        uint256 totalAmount = amountPerNFT * _nftIds.length;

        // transfer tokens to contract
        require(tokenAddress.transferFrom(msg.sender, address(this), totalAmount), "Cannot transfer tokens to contract");

        Stake memory _stake = stakes[msg.sender];

        if (_stake.nftIds.length > 0 && _stake.lastRewardId < activeRewardId && _stake.lastClaimedRewardId < activeRewardId) { // staked before and not claimed
            uint256 _earned = earned(msg.sender);
            stakes[msg.sender].earned += _earned;
        }

        // transfer NFTs to contract
        for (uint256 i = 0; i < _nftIds.length; i++) {
            stakes[msg.sender].nftIds.push(_nftIds[i]);
            nftIdsIndexes[_nftIds[i]] = _stake.nftIds.length - 1;
            nftAddress.transferFrom(msg.sender, address(this), _nftIds[i]);
        }

        uint256 multiplier = totalMultiplier(msg.sender);
        rewards[activeRewardId].totalMultiplers += multiplier;

        // update stake
        stakes[msg.sender].amount += totalAmount;
        stakes[msg.sender].lastRewardId = activeRewardId;

        // update totals
        totalStaked += totalAmount;
        totalNFTsStaked += _nftIds.length;

        emit Staked(msg.sender, totalAmount, _nftIds, activeRewardId);
    }

    function _removeNFTFromStake(address account, uint256 nftId) internal {
        uint256 index = nftIdsIndexes[nftId];
        uint256 lastNFTId = stakes[account].nftIds[stakes[account].nftIds.length - 1];
        stakes[account].nftIds[index] = lastNFTId;
        stakes[account].nftIds.pop();
        nftIdsIndexes[lastNFTId] = index;
        nftIdsIndexes[nftId] = 0;
    }

    /// @dev allows user to claim tokens and NFTs
    /// @param _nftIds ids of the NFTs to claim
    function unstake(uint256[] calldata _nftIds) external nonReentrant whenNotPaused {
        Stake memory _stake = stakes[msg.sender];
        require(_stake.amount > 0, "Cannot claim before staking");
        require(rewards[activeRewardId].depositStartTime > block.timestamp, "Cannot claim after deposit start time");
        require(rewards[activeRewardId].lockStartTime + rewards[activeRewardId].totalLockTime < block.timestamp, "Cannot claim during lock time");
        require(_stake.nftIds.length >= _nftIds.length, "Cannot claim more NFTs than staked");

        uint256 totalNFTsLeft = _stake.nftIds.length - _nftIds.length;
        uint256 totalAmountLeft = amountPerNFT * totalNFTsLeft;
        uint256 amountToClaim = _stake.amount - totalAmountLeft;

        uint256 multiplier = totalMultiplier(msg.sender);

        if (_stake.nftIds.length > 0 && _stake.lastRewardId < activeRewardId && _stake.lastClaimedRewardId < activeRewardId) { // staked before and not claimed
            uint256 _earned = earned(msg.sender);
            stakes[msg.sender].earned += _earned;
        }

        // update stake
        stakes[msg.sender].lastRewardId = activeRewardId;
        stakes[msg.sender].amount -= amountToClaim;

        // update totals
        totalStaked -= amountToClaim;
        totalNFTsStaked -= _nftIds.length;

        // transfer NFTs to user
        for (uint256 i = 0; i < _nftIds.length; i++) {
            _removeNFTFromStake(msg.sender, _nftIds[i]);
            nftAddress.transferFrom(address(this), msg.sender, _nftIds[i]);
        }

        // transfer tokens to user
        require(IERC20(tokenAddress).transfer(msg.sender, amountToClaim), "Cannot transfer tokens to user");

        emit Unstaked(msg.sender, amountToClaim, _nftIds, activeRewardId);
    }

    /// @dev allows user to claim earned tokens
    function claim() external nonReentrant whenNotPaused {
        uint256 _earned = earned(msg.sender) + stakes[msg.sender].earned;
        stakes[msg.sender].lastRewardId = activeRewardId;
        stakes[msg.sender].lastClaimedRewardId = activeRewardId;
        stakes[msg.sender].earned = 0;
        // transfer tokens to user
        require(tokenAddress.transfer(msg.sender, _earned), "Cannot transfer tokens to user");

        emit Claimed(msg.sender, _earned, activeRewardId);
    }

    function earned(address account) public view returns (uint256 _earned) {
        Stake memory _stake = stakes[account];
        uint256 multiplier = totalMultiplier(account);
        for (uint256 i = _stake.lastRewardId; i <= activeRewardId; i++) {
            Reward memory reward = rewards[i];
            _earned += multiplier / reward.totalMultiplers * reward.totalReward;
        }
    }

    function totalMultiplier(address account) public view returns (uint256 multiplier) {
        Stake memory _stake = stakes[msg.sender];
        Reward memory reward = rewards[_stake.lastRewardId];
        for (uint256 i = 0; i < _stake.nftIds.length; i++) {
            CryptoPirates cryptoPirates = CryptoPirates(address(nftAddress));
            uint256 nftType = cryptoPirates.types(_stake.nftIds[i]);
            if (nftType == cryptoPirates.TYPE_COMMON()) {
                multiplier += COMMON_MULTIPLIER;
            } else if (nftType == cryptoPirates.TYPE_RARE()) {
                multiplier += RARE_MULTIPLIER;
            } else if (nftType == cryptoPirates.TYPE_EPIC()) {
                multiplier += EPIC_MULTIPLIER;
            } else if (nftType == cryptoPirates.TYPE_LEGENDARY()) {
                multiplier += LEGENDARY_MULTIPLIER;
            }
        }
        return multiplier;
    }

    /// @dev allows owner to set the active reward
    /// @param _activeRewardId id of the active reward
    function setActiveReward(uint256 _activeRewardId) external onlyOwner {
        require(_activeRewardId < rewards.length, "Cannot set active reward to non-existent reward");
        require(_activeRewardId > activeRewardId, "Cannot set active reward to lower id");
        activeRewardId = _activeRewardId;
    }

    /// @dev allows owner to enable "rescue mode"
    /// @param _enabled boolean
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    /// @dev enables owner to pause / unpause minting
    /// @param _paused boolean
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens directly to the bay");
      return IERC721Receiver.onERC721Received.selector;
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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