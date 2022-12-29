//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IXEN {
    struct MintInfo {
        address user;
        uint256 term;
        uint256 maturityTs;
        uint256 rank;
        uint256 amplifier;
        uint256 eaaRate;
    }

    function globalRank() external view returns (uint256);

    function SECONDS_IN_DAY() external view returns (uint256);

    function WITHDRAWAL_WINDOW_DAYS() external view returns (uint256);

    function MAX_PENALTY_PCT() external view returns (uint256);

    function getGrossReward(
        uint256 rankDelta,
        uint256 amplifier,
        uint256 term,
        uint256 eaa
    ) external pure returns (uint256);

    function userMints(address user) external view returns (MintInfo memory);

    function getCurrentAMP() external view returns (uint256);

    function getCurrentEAAR() external view returns (uint256);
}

contract XenBoxHelper {
    IXEN xen = IXEN(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8);

    /* ================ UTIL FUNCTIONS ================ */

    function _penalty(uint256 secsLate) internal view returns (uint256) {
        uint256 daysLate = secsLate / xen.SECONDS_IN_DAY();
        if (daysLate > xen.WITHDRAWAL_WINDOW_DAYS() - 1) return xen.MAX_PENALTY_PCT();
        uint256 penalty = (uint256(1) << (daysLate + 3)) / xen.WITHDRAWAL_WINDOW_DAYS() - 1;
        return _min(penalty, xen.MAX_PENALTY_PCT());
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) return b;
        return a;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) return a;
        return b;
    }

    /* ================ VIEW FUNCTIONS ================ */

    function getOwnedTokenIdList(
        address target,
        address owner,
        uint256 start,
        uint256 end
    ) external view returns (uint256[] memory tokenIdList) {
        require(start < end, "XenBoxHelper: end must over start");
        IERC721 erc721 = IERC721(target);
        uint256[] memory list = new uint256[](end - start);
        uint256 index;
        for (uint256 tokenId = start; tokenId < end; tokenId++) {
            if (erc721.ownerOf(tokenId) == owner) {
                list[index] = tokenId;
                index++;
            }
        }
        tokenIdList = new uint256[](index);
        for (uint256 i; i < index; i++) {
            tokenIdList[i] = list[i];
        }
    }

    function calculateMintReward(address user) external view returns (uint256) {
        IXEN.MintInfo memory info = xen.userMints(user);
        uint256 secsLate = block.timestamp > info.maturityTs ? block.timestamp - info.maturityTs : 0;
        uint256 penalty = _penalty(secsLate);
        uint256 rankDelta = _max(xen.globalRank() - info.rank, 2);
        uint256 EAA = (1_000 + info.eaaRate);
        uint256 reward = xen.getGrossReward(rankDelta, info.amplifier, info.term, EAA);
        return ((reward * (100 - penalty)) / 100) * 1 ether;
    }

    function calculateMintRewardNew(uint256 addRank, uint256 term) external view returns (uint256) {
        uint256 rankDelta = _max(addRank, 2);
        uint256 EAA = (1_000 + xen.getCurrentEAAR());
        uint256 reward = xen.getGrossReward(rankDelta, xen.getCurrentAMP(), term, EAA);
        return reward * 1 ether;
    }

    /* ================ TRAN FUNCTIONS ================ */

    /* ================ ADMIN FUNCTIONS ================ */
}

// SPDX-License-Identifier: MIT

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