//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract StakeShiboshi {
    uint256 public constant STAKE_MIN = 1;
    uint256 public constant STAKE_MAX = 10;
    uint256 public constant DAYS_MIN = 1;
    uint256 public constant DAYS_MAX = 100;

    IERC721 public immutable SHIBOSHI;

    struct Stake {
        uint256[] ids;
        uint256 startTime;
        uint256 duration;
    }

    mapping(address => Stake) private _stakeOf;

    constructor(address _shiboshi) {
        SHIBOSHI = IERC721(_shiboshi);
    }

    function stakeOf(address user)
        public
        view
        returns (
            uint256[] memory ids,
            uint256 startTime,
            uint256 duration
        )
    {
        return (
            _stakeOf[user].ids,
            _stakeOf[user].startTime,
            _stakeOf[user].duration
        );
    }

    function weightOf(address user) public view returns (uint256) {
        return _stakeOf[user].ids.length * _stakeOf[user].duration;
    }

    function extraStakeNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256)
    {
        uint256 currentWeight = weightOf(user);

        if (currentWeight >= targetWeight) {
            return 0;
        }

        return (targetWeight - currentWeight) / _stakeOf[user].duration;
    }

    function extraDurationNeeded(address user, uint256 targetWeight)
        external
        view
        returns (uint256)
    {
        uint256 currentWeight = weightOf(user);

        if (currentWeight >= targetWeight) {
            return 0;
        }

        return (targetWeight - currentWeight) / _stakeOf[user].ids.length;
    }

    function stake(uint256[] memory ids, uint256 numDaysToAdd) external {
        Stake storage s = _stakeOf[msg.sender];

        uint256 length = ids.length;
        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            SHIBOSHI.transferFrom(msg.sender, address(this), ids[i]);
            s.ids.push(ids[i]);
        }

        length = s.ids.length;
        require(
            STAKE_MIN <= length && length <= STAKE_MAX,
            "SHIBOSHI count outside of limits"
        );

        if (s.duration == 0) {
            // no existing lock
            s.startTime = block.timestamp;
        }

        if (numDaysToAdd > 0) {
            s.duration += numDaysToAdd * 1 days;
        }

        uint256 duration = s.duration / 1 days;

        require(
            DAYS_MIN <= duration && duration <= DAYS_MAX,
            "Duration outside of limits"
        );
    }

    function unstake() external {
        Stake storage s = _stakeOf[msg.sender];

        uint256 length = s.ids.length;
        uint256 startTime = s.startTime;
        uint256 duration = s.duration;

        require(length > 0, "No SHIBOSHI staked");
        require(startTime + duration <= block.timestamp, "Not unlocked yet");

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            SHIBOSHI.transferFrom(address(this), msg.sender, s.ids[i]);
        }

        delete _stakeOf[msg.sender];
    }

    function _uncheckedInc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
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