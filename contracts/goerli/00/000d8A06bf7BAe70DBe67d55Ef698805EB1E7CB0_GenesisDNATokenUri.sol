// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "contracts/interfaces/ITokenUri.sol";
import "contracts/interfaces/IGenesisDNAVault.sol";
import "contracts/interfaces/IGenesisCollection.sol";

contract GenesisDNATokenUri is ITokenUri, Ownable {
    using Strings for uint256;

    uint256 constant POSITION_SIZE = 1000000;
    uint256 constant MAX_TRAITS = 20;
    uint256 constant INITIAL_TRAITS_AMOUNT = 5;
    uint256 constant MAX_INVENTORY = 20;

    IGenesisDNAVault public immutable genesisVault;

    string public preRevealUri;

    constructor(address _genesisVault) {
        genesisVault = IGenesisDNAVault(_genesisVault);
    }

    function setPreRevealUri(string memory _preRevealUri) public onlyOwner {
        preRevealUri = _preRevealUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            IGenesisCollection(genesisVault.contractsArray(0)).generalSalt() > 0
                ? onChainTokenURI(tokenId)
                : preRevealUri;
    }

    function onChainTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"Regen #',
                            tokenId.toString(),
                            '","description":"This is a test",',
                            '"image": "',
                            genesisVault.previewImageUri(),
                            '","animation_url": "',
                            tokenImage(tokenId),
                            '" ,"attributes":',
                            genesisVault.hasMintedTraits(tokenId)
                                ? mintedAttributes(tokenId)
                                : notMintedAttributes(tokenId),
                            "}"
                        )
                    )
                )
            );
    }

    function mintedAttributes(uint256 tokenId)
        internal
        view
        returns (string memory attributes)
    {
        uint256 i;
        bool passedFirst;
        Trait[20] memory traits = genesisVault.getTraits(tokenId);
        attributes = string(
            abi.encodePacked(
                '[{"trait_type":"DNA", "value": "GenesisDNA", "contract":"',
                Strings.toHexString(uint256(uint160(address(genesisVault)))),
                '"},'
            )
        );
        for (i = 0; i < MAX_TRAITS; i++) {
            Trait memory trait = traits[i];
            if (uint160(trait.traitId) == 0) continue;
            attributes = string(
                abi.encodePacked(
                    attributes,
                    passedFirst
                        ? ',{"trait_type":"Position '
                        : '{"trait_type":"Position ',
                    i.toString(),
                    '","value": "',
                    ITraitCollection(genesisVault.contractsArray(trait.layer1))
                        .traitName(trait.traitId),
                    '","metadata":"',
                    IERC721Metadata(genesisVault.contractsArray(trait.layer1))
                        .tokenURI(trait.traitId),
                    '","contract":"',
                    Strings.toHexString(
                        uint256(
                            uint160(genesisVault.contractsArray(trait.layer1))
                        )
                    ),
                    '","tokenId":"',
                    (trait.traitId).toString(),
                    '"}'
                )
            );
            passedFirst = true;
        }
        attributes = string(abi.encodePacked(attributes, "]"));
    }

    function notMintedAttributes(uint256 tokenId)
        internal
        view
        returns (string memory attributes)
    {
        uint256 i;
        attributes = string(
            abi.encodePacked(
                '[{"trait_type":"DNA", "value": "GenesisDNA", "contract":"',
                Strings.toHexString(uint256(uint160(address(genesisVault)))),
                '"},'
            )
        );
        for (i = 0; i < INITIAL_TRAITS_AMOUNT; i++) {
            attributes = string(
                abi.encodePacked(
                    attributes,
                    '{"trait_type":"Position ',
                    (2 * i).toString(),
                    '","value":"',
                    ITraitCollection(genesisVault.contractsArray(0)).traitName(
                        tokenId + POSITION_SIZE * 2 * i
                    ),
                    '","metadata": "Equipped traits not minted yet."',
                    ',"contract":"',
                    Strings.toHexString(
                        uint256(uint160(genesisVault.contractsArray(0)))
                    ),
                    '","tokenId":"'
                    '"},'
                )
            );
        }
        attributes = string(
            abi.encodePacked(
                attributes,
                '{"trait_type":"Position 10","value":"',
                ITraitCollection(genesisVault.contractsArray(0)).traitName(
                    tokenId + POSITION_SIZE * 2 * 5
                ),
                '","metadata":"',
                "Equipped traits not minted yet.",
                '","contract":"',
                Strings.toHexString(
                    uint256(uint160(genesisVault.contractsArray(0)))
                ),
                '","tokenId":"'
                '"}]'
            )
        );
    }

    function tokenImage(uint256 tokenId)
        public
        view
        returns (string memory _tokenImage)
    {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 3000 3000" width="508.333" height="508.333">',
                                    genesisVault.hasMintedTraits(tokenId)
                                        ? mintedAttributesImage(tokenId)
                                        : notMintedAttributesImage(tokenId),
                                    "</svg>"
                                )
                            )
                        )
                    )
                )
            );
    }

    function mintedAttributesImage(uint256 tokenId)
        internal
        view
        returns (string memory imageUri)
    {
        uint256 i;
        imageUri = "";
        Trait[20] memory traits = genesisVault.getTraits(tokenId);
        bool passedFirst;
        for (i = 0; i < MAX_TRAITS; i++) {
            Trait memory trait = traits[i];
            if (i == 3) {
                if (passedFirst) {
                    imageUri = string(
                        abi.encodePacked(
                            imageUri,
                            ',<image href= "',
                            genesisVault.DNAImageUri(),
                            '"/>'
                        )
                    );
                } else {
                    passedFirst = true;
                    imageUri = string(
                        abi.encodePacked(
                            imageUri,
                            '<image href= "',
                            genesisVault.DNAImageUri(),
                            '"/>'
                        )
                    );
                }
            }
            if (uint160(trait.traitId) == 0) continue;
            if (passedFirst) {
                imageUri = string(
                    abi.encodePacked(
                        imageUri,
                        ',<image href= "',
                        ITraitCollection(
                            genesisVault.contractsArray(trait.layer1)
                        ).tokenImage(trait.traitId),
                        '"/>'
                    )
                );
            } else {
                passedFirst = true;
                imageUri = string(
                    abi.encodePacked(
                        imageUri,
                        '<image href= "',
                        ITraitCollection(
                            genesisVault.contractsArray(trait.layer1)
                        ).tokenImage(trait.traitId),
                        '"/>'
                    )
                );
            }
        }
    }

    function notMintedAttributesImage(uint256 tokenId)
        internal
        view
        returns (string memory imageUri)
    {
        uint256 i;
        imageUri = "";
        bool passedFirst;
        for (i = 0; i <= INITIAL_TRAITS_AMOUNT; i++) {
            if (i == 2) {
                imageUri = string(
                    abi.encodePacked(
                        imageUri,
                        ',<image href= "',
                        genesisVault.DNAImageUri(),
                        '"/>'
                    )
                );
            }
            if (passedFirst) {
                imageUri = string(
                    abi.encodePacked(
                        imageUri,
                        ',<image href= "',
                        ITraitCollection(genesisVault.contractsArray(0))
                            .tokenImage(tokenId + POSITION_SIZE * 2 * i),
                        '"/>'
                    )
                );
            } else {
                passedFirst = true;
                imageUri = string(
                    abi.encodePacked(
                        imageUri,
                        '<image href= "',
                        ITraitCollection(genesisVault.contractsArray(0))
                            .tokenImage(tokenId + POSITION_SIZE * 2 * i),
                        '"/>'
                    )
                );
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
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

pragma solidity ^0.8.2;

interface ITokenUri {
    function tokenURI(uint256 tokenId) external view returns (string memory uri);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "contracts/interfaces/IDNAVault.sol";

interface IGenesisDNAVault is IDNAVault {
    function getTraits(uint256 tokenId)
        external
        view
        returns (Trait[20] memory traits);

    function hasMintedTraits(uint256 tokenId) external view returns (bool);

    function contractsArray(uint256) external view returns (address);

    function DNAImageUri() external view returns (string memory);

    function previewImageUri() external view returns (string memory);

    function getTokenIdSalt(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "contracts/interfaces/ITraitCollection.sol";

interface IGenesisCollection is ITraitCollection {
    function mintTraits(uint256 tokenId) external;
    function generalSalt() external view returns(uint256);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

struct Trait {
    uint256 layer1;
    uint256 traitId;
}

interface IDNAVault {
    function tokenURI(uint256) external view returns (string memory);

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface ITraitCollection {
    function transferSpecial(uint256 tokenId, address _address) external;
    function tokenImage(uint256 tokenId) external view returns(string memory);
    function collectionName() external view returns(string memory);
    function traitName(uint256 tokenId) external view returns(string memory);
}