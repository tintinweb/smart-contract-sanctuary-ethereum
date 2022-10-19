// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Replacement {
    string matchString;
    string replaceString;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../interfaces/IAttribute.sol";

import "../libraries/AttributeLib.sol";
import "../libraries/StringsLib.sol";

enum TokenType {
    ERC721,
    ERC1155
}

struct AttributeMutationPoolContract {
    TokenType tokenType;
    address tokenAddress;
    string _attributeKey;
    uint256 _attributeValuePerPeriod;
    uint256 _attributeBlocksPerPeriod;
    uint256 _totalValueThreshold;
    mapping(address => mapping(uint256 => uint256)) _tokenConvertedHeight;
    mapping(address => mapping(uint256 => uint256)) _tokenDepositHeight;
}

// attribute mutatiom pool storage
struct AttributeMutationPoolStorage {
    AttributeMutationPoolContract attributeMutationPool;
}

library AttributeMutationPoolLib {
    using AttributeLib for AttributeContract;

    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256(
            "diamond.nextblock.bitgem.app.AttributeMutationPoolStorage.storage"
        );

    /// @notice get the attribute mutation pool storage
    /// @return ds the attribute mutation pool storage
    function attributeMutationPoolStorage()
        internal
        pure
        returns (AttributeMutationPoolStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice set the attribute mutation pool settings
    /// @param attributeKey the attribute key
    /// @param updateValuePerPeriod the attribute value per period
    /// @param blocksPerPeriod the attribute blocks per period
    /// @param totalValueThreshold the total value threshold
    function _setAttributeMutationSettings(
        AttributeMutationPoolContract storage attributeMutationPool,
        string memory attributeKey,
        uint256 updateValuePerPeriod,
        uint256 blocksPerPeriod,
        uint256 totalValueThreshold
    ) internal {
        require(bytes(attributeKey).length > 0, "noempty");
        require(updateValuePerPeriod > 0, "zerovalue");
        attributeMutationPool._attributeKey = attributeKey;
        attributeMutationPool._attributeValuePerPeriod = updateValuePerPeriod;
        attributeMutationPool._attributeBlocksPerPeriod = blocksPerPeriod;
        attributeMutationPool._totalValueThreshold = totalValueThreshold;
    }

    /// @notice get the accrued value for a token
    /// @param attributeMutationPool the attribute mutation pool storage
    /// @param attributes attributes storage
    /// @param tokenId the token id
    /// @return _currentAccruedValue the accrued value
    function _getAccruedValue(
        AttributeMutationPoolContract storage attributeMutationPool,
        AttributeContract storage attributes,
        uint256 tokenId
    ) internal view returns (uint256 _currentAccruedValue) {
        // get the current accrued value for the token
        uint256 currentAccruedValue = StringsLib.parseInt(
            attributes
                ._getAttribute(tokenId, attributeMutationPool._attributeKey)
                .value
        );

        // get the block deposit height for the token
        uint256 depositBlockHeight = attributeMutationPool._tokenDepositHeight[msg.sender][
            tokenId
        ];
        require(
            depositBlockHeight > 0 && depositBlockHeight <= block.number,
            "notdeposited"
        );

        // calculate the current accrued value for the token
        uint256 blocksDeposited = block.number - depositBlockHeight;
        uint256 accruedValue = (blocksDeposited *
            attributeMutationPool._attributeValuePerPeriod) /
            attributeMutationPool._attributeBlocksPerPeriod;

        // add the accrued value to the current accrued value
        _currentAccruedValue = accruedValue + currentAccruedValue;
    }

    /// @notice require that the token owns the token id
    /// @param tokenType the token type
    /// @param tokenAddress the token address
    /// @param tokenId the token id
    function _requireCallerOwnsTokenId(
        address caller,
        TokenType tokenType,
        address tokenAddress,
        uint256 tokenId
    ) internal view {
        if (tokenType == TokenType.ERC721) {
            // require that the user have a quantity of the tokenId they specify
            require(
                IERC721(tokenAddress).ownerOf(tokenId) == caller,
                "needtoken"
            );
        } else if (tokenType == TokenType.ERC1155) {
            // require that the user have a quantity of the tokenId they specify
            require(
                IERC1155(tokenAddress).balanceOf(caller, tokenId) >= 1,
                "nofunds"
            );
        }
    }

    /// @notice transfer token being staked to contract
    /// @param tokenType the token type
    /// @param tokenAddress the token address
    /// @param tokenId the token id
    /// @param sender the sender
    function _transferStakedTokenToContract(
        TokenType tokenType,
        address tokenAddress,
        uint256 tokenId,
        address sender
    ) internal {
        if (tokenType == TokenType.ERC721) {
            // transfer the token to this contract
            IERC721(tokenAddress).transferFrom(sender, address(this), tokenId);
        } else if (tokenType == TokenType.ERC1155) {
            // transfer the token to this contract
            IERC1155(tokenAddress).safeTransferFrom(
                sender,
                address(this),
                tokenId,
                1,
                ""
            );
        }
    }

    /// @notice transfer token being staked to staker
    /// @param tokenType the token type
    /// @param tokenAddress the token address
    /// @param tokenId the token id
    /// @param staker the sender
    function _transferStakedTokenBackToStaker(
        TokenType tokenType,
        address tokenAddress,
        uint256 tokenId,
        address staker
    ) internal {
        if (tokenType == TokenType.ERC721) {
            // transfer the token to this contract
            IERC721(tokenAddress).transferFrom(address(this), staker, tokenId);
        } else if (tokenType == TokenType.ERC1155) {
            // transfer the token to this contract
            IERC1155(tokenAddress).safeTransferFrom(
                address(this),
                staker,
                tokenId,
                1,
                ""
            );
        }
    }

    /// @notice stake a token
    /// @param attributeMutationPool the attribute mutation pool storage
    /// @param attributeContract attributes storage
    /// @param tokenId the token id
    function _stake(
        AttributeMutationPoolContract storage attributeMutationPool,
        AttributeContract storage attributeContract,
        uint256 tokenId
    ) internal {
        uint256 currentAccruedValue = StringsLib.parseInt(
            attributeContract
                ._getAttribute(tokenId, attributeMutationPool._attributeKey)
                .value
        );

        // require that this be a valid token with the correct attribute set to at least 1
        require(currentAccruedValue > 0, "needvalue");

        // require that this token not be already deposited
        uint256 tdHeight = attributeMutationPool._tokenDepositHeight[
            msg.sender
        ][tokenId];
        require(tdHeight == 0, "alreadydeposited");

        _requireCallerOwnsTokenId(
            msg.sender,
            attributeMutationPool.tokenType,
            attributeMutationPool.tokenAddress,
            tokenId
        );

        _transferStakedTokenToContract(
            attributeMutationPool.tokenType,
            attributeMutationPool.tokenAddress,
            tokenId,
            msg.sender
        );

        // record the deposit in the variables to track it
        attributeMutationPool._tokenDepositHeight[msg.sender][tokenId] = block
            .number;
    }

    /// @notice unstake a token
    /// @param attributeMutationPool the attribute mutation pool storage
    /// @param attributeContract attributes storage
    /// @param tokenId the token id
    function _unstake(
        AttributeMutationPoolContract storage attributeMutationPool,
        AttributeContract storage attributeContract,
        uint256 tokenId
    ) public {
        // require that this token be owned by the caller
        _requireCallerOwnsTokenId(
            msg.sender,
            attributeMutationPool.tokenType,
            attributeMutationPool.tokenAddress,
            tokenId
        );

        // get the accrued valie of the token
        uint256 currentAccruedValue = AttributeMutationPoolLib._getAccruedValue(
            attributeMutationPool,
            attributeContract,
            tokenId
        );

        attributeMutationPool._tokenDepositHeight[msg.sender][tokenId] = 0;

        // set the attribute to the value, or the total value if value > total value
        uint256 val = currentAccruedValue >
            attributeMutationPool._totalValueThreshold
            ? attributeMutationPool._totalValueThreshold
            : currentAccruedValue;

        // set the attribute value to the accrued value
        attributeContract._setAttribute(
            tokenId,
            Attribute({
                key: attributeMutationPool._attributeKey,
                attributeType: AttributeType.String,
                value: Strings.toString(val)
            })
        );

        // send the token back to the user
        _transferStakedTokenBackToStaker(
            attributeMutationPool.tokenType,
            attributeMutationPool.tokenAddress,
            tokenId,
            msg.sender
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IStrings.sol";

library StringsLib {

    function parseInt(string memory s) internal pure returns (uint256 res) {

        for (uint256 i = 0; i < bytes(s).length; i++) {
            if ((uint8(bytes(s)[i]) - 48) < 0 || (uint8(bytes(s)[i]) - 48) > 9) {
                return 0;
            }
            res += (uint8(bytes(s)[i]) - 48) * 10**(bytes(s).length - i - 1);
        }
        return res;

    }

    function startsWith(string memory haystack, string memory needle)
        internal
        pure
        returns (bool)
    {
        bytes memory haystackBytes = bytes(haystack);
        bytes memory needleBytes = bytes(needle);
        uint256 haystackLength = haystackBytes.length;
        uint256 needleLength = needleBytes.length;
        if (needleLength > haystackLength) {
            return false;
        }
        for (uint256 i = 0; i < needleLength; i++) {
            if (haystackBytes[i] != needleBytes[i]) {
                return false;
            }
        }
        return true;
    }

    function endsWith(string memory haystack, string memory needle)
        internal
        pure
        returns (bool)
    {
        bytes memory haystackBytes = bytes(haystack);
        bytes memory needleBytes = bytes(needle);
        uint256 haystackLength = haystackBytes.length;
        uint256 needleLength = needleBytes.length;
        if (needleLength > haystackLength) {
            return false;
        }
        for (uint256 i = 0; i < needleLength; i++) {
            if (
                haystackBytes[haystackLength - i - 1] !=
                needleBytes[needleLength - i - 1]
            ) {
                return false;
            }
        }
        return true;
    }

    function substring(string memory haystack, uint256 startpos)
        internal
        pure
        returns (string memory)
    {
        bytes memory haystackBytes = bytes(haystack);
        uint256 length = haystackBytes.length;
        uint256 endpos = length - startpos;
        bytes memory substringBytes = new bytes(endpos);
        for (uint256 i = 0; i < endpos; i++) {
            substringBytes[i] = haystackBytes[startpos + i];
        }
        return string(substringBytes);
    }

    function substring(string memory haystack, uint256 startpos, uint256 endpos)
        internal
        pure
        returns (string memory)
    {
        bytes memory haystackBytes = bytes(haystack);
        uint256 substringLength = endpos - startpos;
        bytes memory substringBytes = new bytes(substringLength);
        for (uint256 i = 0; i < substringLength; i++) {
            substringBytes[i] = haystackBytes[startpos + i];
        }
        return string(substringBytes);
    }

    function concat(string[] memory _strings)
        internal
        pure
        returns (string memory _concat)
    {
        _concat = "";
        for (uint256 i = 0; i < _strings.length; i++) {
            _concat = string(abi.encodePacked(_concat, _strings[i]));
        }
        return _concat;
    }

    function split(string memory _string, string memory _delimiter) internal pure returns (string[] memory _split) {
        _split = new string[](0);
        uint256 _delimiterLength = bytes(_delimiter).length;
        uint256 _stringLength = bytes(_string).length;
        uint256 _splitLength = 0;
        uint256 _splitIndex = 0;
        uint256 _startpos = 0;
        uint256 _endpos = 0;
        for (uint256 i = 0; i < _stringLength; i++) {
            if (bytes(_string)[i] == bytes(_delimiter)[0]) {
                _endpos = i;
                if (_endpos - _startpos > 0) {
                    _split[_splitIndex] = substring(_string, _startpos);
                    _splitIndex++;
                    _splitLength++;
                }
                _startpos = i + _delimiterLength;
            }
        }
        if (_startpos < _stringLength) {
            _split[_splitIndex] = substring(_string, _startpos);
            _splitIndex++;
            _splitLength++;
        }
        return _split;
    }

    function join(string[] memory _strings, string memory _delimiter) internal pure returns (string memory _joined) {
        for (uint256 i = 0; i < _strings.length; i++) {
            _joined = string(abi.encodePacked(_joined, _strings[i]));
            if (i < _strings.length - 1) {
                _joined = string(abi.encodePacked(_joined, _delimiter));
            }
        }
        return _joined;
    }

    function replace(string memory _string, string memory _search, string memory _replace) internal pure returns (string memory _replaced) {
        _replaced = _string;
        uint256 _searchLength = bytes(_search).length;
        uint256 _stringLength = bytes(_string).length;
        uint256 _replacedLength = _stringLength;
        uint256 _startpos = 0;
        uint256 _endpos = 0;
        for (uint256 i = 0; i < _stringLength; i++) {
            if (bytes(_string)[i] == bytes(_search)[0]) {
                _endpos = i;
                if (_endpos - _startpos > 0) {
                    _replaced = substring(_replaced, _startpos);
                    _replacedLength -= _endpos - _startpos;
                }
                _replaced = string(abi.encodePacked(_replaced, _replace));
                _replacedLength += bytes(_replace).length;
                _startpos = i + _searchLength;
            }
        }
        if (_startpos < _stringLength) {
            _replaced = substring(_replaced, _startpos);
            _replacedLength -= _stringLength - _startpos;
        }
        return _replaced;
    }

    function trim(string memory _string) internal pure returns (string memory _trimmed) {
        _trimmed = _string;
        uint256 _stringLength = bytes(_string).length;
        uint256 _startpos = 0;
        uint256 _endpos = 0;
        for (uint256 i = 0; i < _stringLength; i++) {
            if (bytes(_string)[i] != 0x20) {
                _startpos = i;
                break;
            }
        }
        for (uint256 i = _stringLength - 1; i >= 0; i--) {
            if (bytes(_string)[i] != 0x20) {
                _endpos = i;
                break;
            }
        }
        if (_startpos < _endpos) {
            _trimmed = substring(_trimmed, _startpos);
            _trimmed = substring(_trimmed, 0, _endpos - _startpos + 1);
        }
        return _trimmed;
    }

    function toUint16(string memory s) internal pure returns (uint16 res_) {
        uint256 res = 0;
        for (uint256 i = 0; i < bytes(s).length; i++) {
            if ((uint8(bytes(s)[i]) - 48) < 0 || (uint8(bytes(s)[i]) - 48) > 9) {
                return 0;
            }
            res += (uint8(bytes(s)[i]) - 48) * 10**(bytes(s).length - i - 1);
        }
        res_ = uint16(res);
    }


    function replace(string[] memory input, string memory matchTag, string[] memory repl) internal pure returns (string memory) {
        string memory svgBody;
        for(uint256 i = 0; i < input.length; i++) {
            string memory svgString = input[i];
            string memory outValue;
            if(StringsLib.startsWith(svgString, matchTag)) {
                string memory restOfLine = StringsLib.substring(svgString, bytes(matchTag).length);
                uint256 replIndex = StringsLib.parseInt(restOfLine);
                outValue = repl[replIndex];
            } else {
                outValue = svgString;
            }
            svgBody = string(abi.encodePacked(svgBody, outValue));
        }
        return svgBody;
    }

    function replace(bytes[] memory sourceBytes, Replacement[] memory replacements_) public pure returns (string memory) {
        //bytes[] memory sourceBytes = _getSourceBytes();
        string memory outputFile = "";
        for (uint256 i = 0; i < sourceBytes.length; i++) {
            bytes memory sourceByte = sourceBytes[i];
            string memory outputLine  = string(sourceBytes[i]);
            for (uint256 j = 0; j < replacements_.length; j++) {
                Replacement memory replacement = replacements_[j];
                if (keccak256(sourceByte) == keccak256(bytes(replacement.matchString))) {
                    outputLine = replacement.replaceString;
                }
            }
            outputFile = string(abi.encodePacked(outputFile, outputLine));
        }
        return outputFile;
    }    
}