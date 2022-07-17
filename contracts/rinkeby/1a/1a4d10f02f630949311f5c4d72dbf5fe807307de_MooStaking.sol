// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMilk.sol";

contract MooStaking is IERC721Receiver, Pausable, Ownable {
    struct Stake {
        address addr;
        uint64 startTimestamp;
    }

    uint256 public totalStaked;
    uint256 public reward = 1 ether;
    uint256 public interval = 1 days;

    uint256 private constant _BITPOS_START_TIMESTAMP = 160;
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    mapping(uint256 => uint256) private _packedOwnerships;
    mapping(address => uint256) private _balance;

    IERC721 private _collection;
    IMilk private _reward;

    constructor(address collection, address rewardToken) {
        _collection = IERC721(collection);
        _reward = IMilk(rewardToken);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setCollection(address collection) external onlyOwner {
        _collection = IERC721(collection);
    }

    function setRewardToken(address rewardToken) external onlyOwner {
        _reward = IMilk(rewardToken);
    }

    function setReward(uint256 newReward) external onlyOwner {
        reward = newReward;
    }

    function setInterval(uint256 newInterval) external onlyOwner {
        interval = newInterval;
    }

    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function _unpackedOwnership(uint256 packed) private pure returns (Stake memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
    }

    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        unchecked {
            uint256 packed = _packedOwnerships[tokenId];
            return packed;
        }
    }

    function _packOwnershipData(address owner) private view returns (uint256 result) {
        assembly {
            owner := and(owner, _BITMASK_ADDRESS)
            result := or(owner, shl(_BITPOS_START_TIMESTAMP, timestamp()))
        }
    }

    function stake(uint256 tokenId) external whenNotPaused {
        unchecked {
            _collection.safeTransferFrom(msg.sender, address(this), tokenId, "");
            _packedOwnerships[tokenId] = _packOwnershipData(msg.sender);
            _balance[msg.sender]++;
            totalStaked++;   
        }
    }

    function stakeMany(uint256[] calldata tokenIds) external whenNotPaused {
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                _collection.safeTransferFrom(msg.sender, address(this), tokenIds[i], "");
                _packedOwnerships[tokenIds[i]] = _packOwnershipData(msg.sender);
            }
            _balance[msg.sender] += tokenIds.length;
            totalStaked += tokenIds.length;
        }
    }

    function unstake(uint256 tokenId) external {
        unchecked {
            require(ownerOf(tokenId) == msg.sender, "Not the token owner");
            _collection.safeTransferFrom(address(this), msg.sender, tokenId, "");
            delete _packedOwnerships[tokenId];
            _balance[msg.sender]--;
            totalStaked--;
        }
    }

    function unstakeMany(uint256[] calldata tokenIds) external {
        unchecked {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                require(ownerOf(tokenIds[i]) == msg.sender, "Not the token owner");
                _collection.safeTransferFrom(address(this), msg.sender, tokenIds[i], "");
                delete _packedOwnerships[tokenIds[i]];
            }
            _balance[msg.sender] -= tokenIds.length;
            totalStaked -= tokenIds.length;
        }
    }

    function calculateRewards(address owner) external view returns (uint256) {
        unchecked {
            if (_balance[owner] == 0) return 0;
            uint256 rewards;
            Stake memory ownership;
            for (uint256 i = 0; i < totalStaked; i++) {
                ownership = _unpackedOwnership(_packedOwnerships[i]);
                if (ownership.addr == owner) {
                    rewards += reward * ((block.timestamp - ownership.startTimestamp) / interval);
                }
            }
            return rewards;
        }
    }

    function claim() external {
        unchecked {
            require(_balance[msg.sender] > 0, "No token staked to claim");
            uint256 rewards;
            Stake memory ownership;
            for (uint256 i = 0; i < totalStaked; i++) {
                ownership = _unpackedOwnership(_packedOwnerships[i]);
                if (ownership.addr == msg.sender) {
                    rewards += reward * ((block.timestamp - ownership.startTimestamp) / interval);
                    _packedOwnerships[i] = _packOwnershipData(msg.sender);
                }
            }
            _reward.mint(msg.sender, rewards);
        }
    }

    function claimAndUnstake() external {
        unchecked {
            require(_balance[msg.sender] > 0, "No token staked to claim");
            uint256 rewards;
            uint256 unstaked;
            Stake memory ownership;
            for (uint256 i = 0; i < totalStaked; i++) {
                ownership = _unpackedOwnership(_packedOwnerships[i]);
                if (ownership.addr == msg.sender) {
                    _collection.safeTransferFrom(address(this), msg.sender, i, "");
                    rewards += reward * ((block.timestamp - ownership.startTimestamp) / interval);
                    delete _packedOwnerships[i];
                    unstaked++;
                }
            }
            _balance[msg.sender] -= unstaked;
            totalStaked -= unstaked;
            _reward.mint(msg.sender, rewards);
        }
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            if (_balance[owner] == 0) return new uint256[](0);
            uint256 tokenIdsIdx;
            uint256[] memory tokenIds = new uint256[](_balance[owner]);
            Stake memory ownership;
            for (uint256 i = 0; i < totalStaked; i++) {
                ownership = _unpackedOwnership(_packedOwnerships[i]);
                if (ownership.addr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balance[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    function stakingInfo(uint256 tokenId) external view returns (uint256, uint256, address) {
        require(_collection.ownerOf(tokenId) == address(this), "Token isn't staked");
        Stake memory staked = _unpackedOwnership(_packedOwnerships[tokenId]);
        return (tokenId, staked.startTimestamp, staked.addr);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IMilk {
    function mint(address to, uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
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