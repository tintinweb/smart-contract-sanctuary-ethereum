// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./interface/IRentContract.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


error __NotOwner();

contract RentContract{
        
    enum status {
        Started,
        Ended
    }
    struct RentalAgreement{
        status contractStatus;
        uint256 period;
        uint256 costPerPeriod;
        uint256 numberOfPeriods;
        uint256 bufferTime;
    }


    mapping(address=>mapping(uint256=>RentalAgreement)) public rentalAgreements;

    bool public contractStatus;
    function startAgreement(address nftAddress,uint256 tokenId,uint256 _period,uint256 _costPerPeriod,uint256 _numberOfPeriods,uint256 _bufferTime) public{
        rentalAgreements[nftAddress][tokenId]=RentalAgreement(status.Started,_period,_costPerPeriod,_numberOfPeriods,_bufferTime);

    }
    function endAgreement(address nftAddress,uint256 tokenId) public{
        delete(rentalAgreements[nftAddress][tokenId]);
    }
    function getAgreementStatus(address nftAddress,uint256 tokenId) public view returns(RentalAgreement memory){
        return rentalAgreements[nftAddress][tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRentContract{
    function nftOwner() external view returns(address);
    function nftTenant() external view returns(address);
    function nftTokenId() external view returns(uint256);
    function contractStarted() external view returns(bool isContractStarted);
    function contractEnded() external view returns(bool isContractEnded);
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
    event Rented(address indexed owner,address indexed rentedTo,uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event ApprovalToSell(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalToRent(address indexed owner, address indexed approved, uint256 indexed tokenId);

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
    function tenantOf(uint256 tokenId) external view returns (address tenant);
    function contractOf(uint256 tokenId) external view returns (address tenant);

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

    function setTenant(
        address owener,
        address rentedTo,
        address rentContractAddress,
        uint256 tokenId
    ) external;

    function removeTenant(
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
    function approveToSell(address to, uint256 tokenId) external;
    function approveToRent(address to, uint256 tokenId) external;

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
    function setApprovalToSellForAll(address operator, bool _approved) external;

    function setApprovalToRentForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApprovedToSell(uint256 tokenId) external view returns (address operator);

    function getApprovedToRent(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedToSellForAll(address owner, address operator) external view returns (bool);
    function isApprovedToRentForAll(address owner, address operator) external view returns (bool);
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