// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {IERC721} from "src/interfaces/IERC721.sol";

/// @title NftChecker
/// @author bruno <https://github.com/brunobar79>
/// @author asnared <https://github.com/abigger87>
/// @notice Checks if one of many NFTs are ownerd by any of the given addresses
contract NftChecker {
    /// @notice Returns if one of the given addresses is a token owner.
    function areOwners(address[] memory targets, address[] memory potentialOwners) public view returns (bool) {
        uint256 targetsLength = targets.length;
        uint256 potentialOwnersLength = potentialOwners.length;
        uint256 i;
        uint256 j;
        // for every contract in the targets array
        for (i = 0; i < targetsLength;) {
            // for every address in the potential owners array
            for (j = 0; j < potentialOwnersLength;) {
                // if the potential owner is an actual owner, return true
                if (IERC721(targets[i]).balanceOf(potentialOwners[j]) > 0) {
                    return true;
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {IERC165} from "./IERC165.sol";

/// @title ERC721 Interface
/// @author Modified from openzeppelin-contracts <https://github.com/OpenZeppelin/openzeppelin-contracts>
interface IERC721 is IERC165 {
    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @notice Returns the number of tokens in ``owner``'s account.
    function balanceOf(address owner) external view returns (uint256 balance);

    /// @notice Returns the owner of the `tokenId` token.
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /// @notice Safely transfers `tokenId` token from `from` to `to`.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /// @notice Safely transfers `tokenId` token from `from` to `to`.
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /// @notice Transfers `tokenId` token from `from` to `to`.
    function transferFrom(address from, address to, uint256 tokenId) external;

    /// @notice Gives permission to `to` to transfer `tokenId` token to another account.
    function approve(address to, uint256 tokenId) external;

    /// @notice Approve or remove `operator` as an operator for the caller.
    function setApprovalForAll(address operator, bool _approved) external;

    /// @notice Returns the account approved for `tokenId` token.
    function getApproved(uint256 tokenId) external view returns (address operator);

    /// @notice Returns if the `operator` is allowed to manage all of the assets of `owner`.
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/// @title ERC165 Interface
/// @notice Interface of the ERC165 standard <https://eips.ethereum.org/EIPS/eip-165[EIP]>
/// @author Modified from openzeppelin-contracts <https://github.com/OpenZeppelin/openzeppelin-contracts>
interface IERC165 {
    /// @notice Returns true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}