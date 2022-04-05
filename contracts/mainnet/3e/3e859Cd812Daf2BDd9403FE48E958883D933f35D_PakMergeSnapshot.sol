// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
                                                                                                                                                                                                                                      
import "./IMerge.sol";

contract PakMergeSnapshot {    
        
    IMerge immutable public _mergeContract;

    constructor() {
        _mergeContract = IMerge(0xc3f8a0F5841aBFf777d3eefA5047e8D413a1C9AB);
    }       

    function getOwners(uint256 tokenIdBegin, uint256 tokenIdEnd) public view returns (address[] memory) {
        require(tokenIdEnd >= tokenIdBegin, "Invalid arguments");
        uint256 numTokens = tokenIdEnd - tokenIdBegin + 1;
        address[] memory owners = new address[](numTokens);
        for(uint256 tokenId = tokenIdBegin; tokenId <= tokenIdEnd; tokenId++) {
            try _mergeContract.ownerOf(tokenId) returns (address owner) {
                owners[tokenId - tokenIdBegin] = owner;
            } catch Error(string memory /*reason*/) {                
                owners[tokenId - tokenIdBegin] = address(0);
            }
        }
        return owners;
    }

    function getMasses(uint256 tokenIdBegin, uint256 tokenIdEnd) public view returns (uint256[] memory) {
        require(tokenIdEnd >= tokenIdBegin, "Invalid arguments");
        uint256 numTokens = tokenIdEnd - tokenIdBegin + 1;
        uint256[] memory masses = new uint256[](numTokens);
        for(uint256 tokenId = tokenIdBegin; tokenId <= tokenIdEnd; tokenId++) {
            try _mergeContract.massOf(tokenId) returns (uint256 mass) {
                masses[tokenId - tokenIdBegin] = mass;
            } catch Error(string memory /*reason*/) {                
                masses[tokenId - tokenIdBegin] = 0;
            }
        }
        return masses;        
    }

    function getMergeCounts(uint256 tokenIdBegin, uint256 tokenIdEnd) public view returns (uint256[] memory) {
        require(tokenIdEnd >= tokenIdBegin, "Invalid arguments");
        uint256 numTokens = tokenIdEnd - tokenIdBegin + 1;
        uint256[] memory merges = new uint256[](numTokens);
        for(uint256 tokenId = tokenIdBegin; tokenId <= tokenIdEnd; tokenId++) {
            try _mergeContract.getMergeCount(tokenId) returns (uint256 mergeCount) {
                merges[tokenId - tokenIdBegin] = mergeCount;
            } catch Error(string memory /*reason*/) {                
                merges[tokenId - tokenIdBegin] = 0;
            }
        }
        return merges;
    }

    function getClasses(uint256 tokenIdBegin, uint256 tokenIdEnd) public view returns (uint256[] memory) {
        require(tokenIdEnd >= tokenIdBegin, "Invalid arguments");
        uint256 numTokens = tokenIdEnd - tokenIdBegin + 1;
        uint256[] memory classes = new uint256[](numTokens);
        for(uint256 tokenId = tokenIdBegin; tokenId <= tokenIdEnd; tokenId++) {
            try _mergeContract.getValueOf(tokenId) returns (uint256 value) {
                uint256 tensDigit = tokenId % 100 / 10;
                uint256 onesDigit = tokenId % 10;
                uint256 class = tensDigit * 10 + onesDigit;
                classes[tokenId - tokenIdBegin] = class;
            } catch Error(string memory /*reason*/) {                
                classes[tokenId - tokenIdBegin] = 0;
            }
        }
        return classes;
    }

    function getTiers(uint256 tokenIdBegin, uint256 tokenIdEnd) public view returns (uint256[] memory) {
        require(tokenIdEnd >= tokenIdBegin, "Invalid arguments");
        uint256 numTokens = tokenIdEnd - tokenIdBegin + 1;
        uint256[] memory tiers = new uint256[](numTokens);
        for(uint256 tokenId = tokenIdBegin; tokenId <= tokenIdEnd; tokenId++) {
            try _mergeContract.getValueOf(tokenId) returns (uint256 value) {
                tiers[tokenId - tokenIdBegin] = _mergeContract.decodeClass(value);
            } catch Error(string memory /*reason*/) {                
                tiers[tokenId - tokenIdBegin] = 0;
            }
        }
        return tiers;        
    }

    function getExists(uint256 tokenIdBegin, uint256 tokenIdEnd) public view returns (bool[] memory) {
        require(tokenIdEnd >= tokenIdBegin, "Invalid arguments");
        uint256 numTokens = tokenIdEnd - tokenIdBegin + 1;
        bool[] memory existence = new bool[](numTokens);
        for(uint256 tokenId = tokenIdBegin; tokenId <= tokenIdEnd; tokenId++) {
            try _mergeContract.exists(tokenId) returns (bool exists) {
                existence[tokenId - tokenIdBegin] = exists;
            } catch Error(string memory /*reason*/) {                
                existence[tokenId - tokenIdBegin] = false;
            }
        }
        return existence;        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@niftygateway/nifty-contracts/contracts/interfaces/IERC721.sol";
import "@niftygateway/nifty-contracts/contracts/interfaces/IERC721Metadata.sol";

interface IMerge is IERC721, IERC721Metadata {
    function getMergeCount(uint256 tokenId) external virtual view returns (uint256 mergeCount);    
    function totalSupply() external virtual view returns (uint256);    
    function massOf(uint256 tokenId) external virtual view returns (uint256);
    function getValueOf(uint256 tokenId) external view virtual returns (uint256 value);
    function exists(uint256 tokenId) external virtual view returns (bool);
    function decodeClassAndMass(uint256 value) external pure returns (uint256, uint256);
    function decodeClass(uint256 value) external pure returns (uint256 class);
    function decodeMass(uint256 value) external pure returns (uint256 mass);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC165.sol";

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

pragma solidity 0.8.9;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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