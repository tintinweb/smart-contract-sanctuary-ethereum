// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum AttributeType {
    Unknown,
    String ,
    Bytes32,
    Uint256,
    Uint8,
    Uint256Array,
    Uint8Array
}

struct Attribute {
    string key;
    AttributeType attributeType;
    string value;
}

// attribute storage
struct AttributeContract {
    mapping(uint256 => bool)  burnedIds;
    mapping(uint256 => mapping(string => Attribute))  attributes;
    mapping(uint256 => string[]) attributeKeys;
    mapping(uint256 =>  mapping(string => uint256)) attributeKeysIndexes;
}


/// @notice a pool of tokens that users can deposit into and withdraw from
interface IAttribute {
    /// @notice get an attribute for a tokenid keyed by string
    function getAttribute(
        uint256 id,
        string memory key
    ) external view returns (Attribute calldata _attrib);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

import "../interfaces/IAttribute.sol";

struct AttributeStorage {
    AttributeContract attributes;
}

library AttributeLib {
    event AttributeSet(address indexed tokenAddress, uint256 tokenId, Attribute attribute);
    event AttributeRemoved(address indexed tokenAddress, uint256 tokenId, string attributeKey);

    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.nextblock.bitgem.app.AttributeStorage.storage");

    function attributeStorage() internal pure returns (AttributeStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice set an attribute for a tokenid keyed by string
    function _getAttribute(
        AttributeContract storage self,
        uint256 tokenId,
        string memory key
    ) internal view returns (Attribute memory) {
        require(self.burnedIds[tokenId] == false, "Token has been burned");
        return self.attributes[tokenId][key];
    }

    /// @notice get a list of keys of attributes assigned to this tokenid
    function _getAttributeValues(
        uint256 id
    ) internal view returns (string[] memory) {
        AttributeContract storage ct = AttributeLib.attributeStorage().attributes;
        string[] memory keys = ct.attributeKeys[id];
        string[] memory values = new string[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            values[i] = ct.attributes[id][keys[i]].value;
        }
        return values;
    }
    
    /// @notice set an attribute to a tokenid keyed by string
    function _setAttribute(
        AttributeContract storage self,
        uint256 tokenId,
        Attribute memory attribute
    ) internal {
        require(self.burnedIds[tokenId] == false, "Token has been burned");
        if (self.attributeKeysIndexes[tokenId][attribute.key] == 0 
            && bytes(self.attributes[tokenId][attribute.key].value).length == 0) {
            self.attributeKeys[tokenId].push(attribute.key);
            self.attributeKeysIndexes[tokenId][attribute.key] = self.attributeKeys[tokenId].length - 1;
        }
        self.attributes[tokenId][attribute.key] = attribute;
    }
    
    /// @notice set multiple  attributes for the token
    function _setAttributes(
        AttributeContract storage self,
        uint256 tokenId, 
        Attribute[] memory _attributes)
        internal
    {
        require(self.burnedIds[tokenId] == false, "Token has been burned");
        for (uint256 i = 0; i < _attributes.length; i++) {
            _setAttribute(self, tokenId, _attributes[i]);
        }
    }

    /// @notice get a list of keys of attributes assigned to this tokenid
    function _getAttributeKeys(
        AttributeContract storage self,
        uint256 tokenId
    ) internal view returns (string[] memory) {
        require(self.burnedIds[tokenId] == false, "Token has been burned");
        return self.attributeKeys[tokenId];
    }

    /// @notice remove the attribute for a tokenid keyed by string
    function _removeAttribute(
        AttributeContract storage self,
        uint256 tokenId,
        string memory key
    ) internal {
        require(self.burnedIds[tokenId] == false, "Token has been burned");
        delete self.attributes[tokenId][key];
        uint256 ndx = self.attributeKeysIndexes[tokenId][key];
        for (uint256 i = ndx; i < self.attributeKeys[tokenId].length - 1; i++) {
            self.attributeKeys[tokenId][i] = self.attributeKeys[tokenId][i + 1];
            self.attributeKeysIndexes[tokenId][self.attributeKeys[tokenId][i]] = i;
        }
        delete self.attributeKeys[tokenId][self.attributeKeys[tokenId].length - 1];
        emit AttributeRemoved(address(this), tokenId, key);
    }

    // @notice set multiple attributes for the token
    function _burn(
        AttributeContract storage self,
        uint256 tokenId)
        internal
    {
        self.burnedIds[tokenId] = true;
    }
}