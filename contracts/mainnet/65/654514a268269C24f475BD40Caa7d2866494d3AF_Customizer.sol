// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/GotTokenInterface.sol";
import "../interfaces/OGColorInterface.sol";

library Customizer {
    
    function safeOwnerOf(IERC721 callingContract, uint256 tokenId) public view returns (address) {
        
        address ownerOfToken = address(0);
                
        try callingContract.ownerOf(tokenId) returns (address a) {
            ownerOfToken = a;
        }
        catch { }

        return ownerOfToken;
    }

    function getColors(IERC721 callingContract, address ogColorContractAddress, uint256 tokenId) external view returns (string memory back, string memory frame, string memory digit, string memory slug) {

        address ownerOfToken = safeOwnerOf(callingContract, tokenId);
        if (ownerOfToken != address(0)) {
            if (ogColorContractAddress != address(0)) {
                OGColorInterface ogColorContract = OGColorInterface(ogColorContractAddress);
                try ogColorContract.getColors(ownerOfToken, tokenId) returns (string memory extBack, string memory extFrame, string memory extDigit, string memory extSlug) {
                    return (extBack, extFrame, extDigit, extSlug);
                }
                catch { }
            }
        }
        
        return ("<linearGradient id='back'><stop stop-color='#ffffff'/></linearGradient>",
                "<linearGradient id='frame'><stop stop-color='#000000'/></linearGradient>",
                "<linearGradient id='digit'><stop stop-color='#000000'/></linearGradient>",
                "<linearGradient id='slug'><stop stop-color='#ffffff'/></linearGradient>");
    }

    function getColorAttributes(IERC721 callingContract, address ogColorContractAddress, uint256 tokenId) external view returns (string memory) {

        address ownerOfToken = safeOwnerOf(callingContract, tokenId);
        if (ownerOfToken != address(0)) {
            if (ogColorContractAddress != address(0)) {
                OGColorInterface ogColorContract = OGColorInterface(ogColorContractAddress);
                try ogColorContract.getOgAttributes(ownerOfToken, tokenId) returns (string memory extAttributes) {
                    return extAttributes;
                }
                catch { }
            }
        }
        
        return "";
    }
    
    function getOwnedSupportedCollection(IERC721 callingContract, address gotTokenContractAddress, address[] memory supportedCollections, uint256 tokenId) external view returns (address) {
        
        if (gotTokenContractAddress == address(0))
            return address(0);
        
        address ownerOfToken = safeOwnerOf(callingContract, tokenId);
        if (ownerOfToken == address(0))
            return address(0);
    
        bool[] memory ownsTokens;
        
        GotTokenInterface gotTokenContract = GotTokenInterface(gotTokenContractAddress);        
        try gotTokenContract.ownsTokenOfContracts(ownerOfToken, supportedCollections, tokenId) returns (bool[] memory returnValue) {
            ownsTokens = returnValue;
        }
        catch { return address(0); }

        // find the first contract which is owned
        for (uint256 i = 0; i < ownsTokens.length; i++) {
            if (ownsTokens[i])
                return supportedCollections[i];
        }

        return address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title The interface to access the OGColor contract to get the colors to render OG svgs
 * @author nfttank.eth
 */
interface OGColorInterface {
    function getColors(address forAddress, uint256 tokenId) external view returns (string memory back, string memory frame, string memory digit, string memory slug);
    function getOgAttributes(address forAddress, uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title The interface to access the GotToken contract to check if an address owns a given token of a given contract
 * @author nfttank.eth
 */
interface GotTokenInterface {
    function ownsTokenOfContract(address possibleOwner, address contractAddress, uint256 tokenId) external view returns (bool);
    function ownsTokenOfContracts(address possibleOwner, address[] calldata upToTenContractAddresses, uint256 tokenId) external view returns (bool[] memory);
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