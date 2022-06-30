// SPDX-License-Identifier: MIT
//
//  ********  **     **    ******   **        **  *******  
// /**/////  /**    /**   **////** /**       /** /**////** 
// /**       /**    /**  **    //  /**       /** /**    /**
// /*******  /**    /** /**        /**       /** /**    /**
// /**////   /**    /** /**        /**       /** /**    /**
// /**       /**    /** //**    ** /**       /** /**    ** 
// /******** //*******   //******  /******** /** /*******  
// ////////   ///////     //////   ////////  //  ///////   
//
// by collect-code 2022
// https://collect-code.com/
//
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IParent is IERC721, IERC721Enumerable, IERC721Metadata {
}

struct WhitelistStorage {
	IParent parent;
	uint8 mintsPerSource;
	uint8 mintsPerBuilt;
	mapping(uint256 => uint8) mintsByTokenId;
}

library Whitelist {

	function setupContract(WhitelistStorage storage self, address contractAddress, uint8 newMintsPerSource, uint8 newMintsPerBuilt) public {
		self.parent = IParent(contractAddress);
		self.mintsPerSource = newMintsPerSource;
		self.mintsPerBuilt = newMintsPerBuilt;
	}

	function isTokenBuilt(WhitelistStorage storage self, uint256 tokenId) public view returns (bool) {
		bytes memory uri = bytes(self.parent.tokenURI(tokenId));
		return (uri[uri.length-1] != '=');
	}

	function calcAllowedMintsPerTokenId(WhitelistStorage storage self, uint256 tokenId) public view returns (uint8) {
		try self.parent.ownerOf(tokenId) returns (address /*owner*/) {
		} catch {
			return 0; // token does not exist
		}
		if(self.mintsPerBuilt > 0 && isTokenBuilt(self, tokenId)) {
			return self.mintsPerBuilt;
		}
		return self.mintsPerSource;
	}

	function calcAvailableMintsPerTokenId(WhitelistStorage storage self, uint256 tokenId) public view returns (uint8) {
		uint8 allowedMints = calcAllowedMintsPerTokenId(self, tokenId);
		if (self.mintsByTokenId[tokenId] >= allowedMints) { // avoid negative result
			return 0; // none available
		}
		return (allowedMints - self.mintsByTokenId[tokenId]);
	}

	function getAvailableMintsForUser(WhitelistStorage storage self, address to) public view returns (uint256[] memory, uint8[] memory) {
		uint256 balance = self.parent.balanceOf(to);
		uint256[] memory tokenIds = new uint256[](balance);
		uint8[] memory available = new uint8[](balance);
		for(uint256 i = 0 ; i < balance ; i++) {
			tokenIds[i] = self.parent.tokenOfOwnerByIndex(to, i);
			available[i] = calcAvailableMintsPerTokenId(self, tokenIds[i]);
		}
		return (tokenIds, available);
	}

	function claimTokenIds(WhitelistStorage storage self, uint256[] memory tokenIds) public returns (uint8 quantity) {
		for(uint256 i = 0 ; i < tokenIds.length ; i++) {
			require(self.parent.ownerOf(tokenIds[i]) == msg.sender, "Whitelist: Not Owner");
			uint8 available = calcAvailableMintsPerTokenId(self, tokenIds[i]);
			if(available > 0) {
				self.mintsByTokenId[tokenIds[i]] += available;
				quantity += available;
			}
		}
		require(quantity > 0, "Whitelist: None available");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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