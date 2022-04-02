//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILockShiboshi.sol";
import "./interfaces/ILandAuction.sol";

contract LockShiboshi is ILockShiboshi, Ownable {
    uint256 public immutable AMOUNT_MIN;
    uint256 public immutable AMOUNT_MAX;
    uint256 public immutable DAYS_MIN;
    uint256 public immutable DAYS_MAX;

    IERC721 public immutable SHIBOSHI;

    ILandAuction public landAuction;

    struct Lock {
        uint256[] ids;
        uint256 startTime;
        uint256 numDays;
        address ogUser;
    }

    mapping(address => Lock) private _lockOf;

    constructor(
        address _shiboshi,
        uint256 amountMin,
        uint256 amountMax,
        uint256 daysMin,
        uint256 daysMax
    ) {
        SHIBOSHI = IERC721(_shiboshi);
        AMOUNT_MIN = amountMin;
        AMOUNT_MAX = amountMax;
        DAYS_MIN = daysMin;
        DAYS_MAX = daysMax;
    }

    function lockInfoOf(address user)
        public
        view
        returns (
            uint256[] memory ids,
            uint256 startTime,
            uint256 numDays,
            address ogUser
        )
    {
        return (
            _lockOf[user].ids,
            _lockOf[user].startTime,
            _lockOf[user].numDays,
            _lockOf[user].ogUser
        );
    }

    function weightOf(address user) public view returns (uint256) {
        return _lockOf[user].ids.length * _lockOf[user].numDays;
    }

    function extraShiboshiNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256)
    {
        uint256 currentWeight = weightOf(user);

        if (currentWeight >= targetWeight) {
            return 0;
        }

        return (targetWeight - currentWeight) / _lockOf[user].numDays;
    }

    function extraDaysNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256)
    {
        uint256 currentWeight = weightOf(user);

        if (currentWeight >= targetWeight) {
            return 0;
        }

        return (targetWeight - currentWeight) / _lockOf[user].ids.length;
    }

    function isWinner(address user) public view returns (bool) {
        return landAuction.winningsBidsOf(user) > 0;
    }

    function unlockAt(address user) public view returns (uint256) {
        Lock memory s = _lockOf[user];

        if (isWinner(user)) {
            return s.startTime + s.numDays * 1 days;
        }

        return s.startTime + 15 days + (s.numDays * 1 days) / 3;
    }

    function setLandAuction(address sale) external onlyOwner {
        landAuction = ILandAuction(sale);
    }

    function lock(uint256[] memory ids, uint256 numDaysToAdd) external {
        Lock storage s = _lockOf[msg.sender];

        uint256 length = ids.length;
        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            SHIBOSHI.transferFrom(msg.sender, address(this), ids[i]);
            s.ids.push(ids[i]);
        }

        length = s.ids.length;
        require(
            AMOUNT_MIN <= length && length <= AMOUNT_MAX,
            "SHIBOSHI count outside of limits"
        );

        if (s.numDays == 0) {
            // no existing lock
            s.startTime = block.timestamp;
            s.ogUser = msg.sender;
        }

        if (numDaysToAdd > 0) {
            s.numDays += numDaysToAdd;
        }

        uint256 numDays = s.numDays;

        require(
            DAYS_MIN <= numDays && numDays <= DAYS_MAX,
            "Days outside of limits"
        );
    }

    function unlock() external {
        Lock storage s = _lockOf[msg.sender];

        uint256 length = s.ids.length;

        require(length > 0, "No SHIBOSHI locked");
        require(unlockAt(msg.sender) <= block.timestamp, "Not unlocked yet");

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            // NOT using safeTransferFrom intentionally
            SHIBOSHI.transferFrom(address(this), msg.sender, s.ids[i]);
        }

        delete _lockOf[msg.sender];
    }

    function _uncheckedInc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    function transferLock(address newOwner) external {
        require(_lockOf[msg.sender].numDays != 0, "Lock does not exist");
        require(_lockOf[newOwner].numDays == 0, "New owner already has a lock");
        _lockOf[newOwner] = _lockOf[msg.sender];
        delete _lockOf[msg.sender];
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILockShiboshi {
    function lockInfoOf(address user)
        external
        view
        returns (
            uint256[] memory ids,
            uint256 startTime,
            uint256 numDays,
            address ogUser
        );

    function weightOf(address user) external view returns (uint256);

    function extraShiboshiNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256);

    function extraDaysNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256);

    function isWinner(address user) external view returns (bool);

    function unlockAt(address user) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILandAuction {
    function winningsBidsOf(address user) external view returns (uint256);
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