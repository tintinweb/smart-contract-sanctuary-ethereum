// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./../../common/interfaces/IThePixelsInc.sol";
import "./../../common/interfaces/IThePixelsMetadataProvider.sol";
import "./../../common/interfaces/IThePixelsIncExtensionStorage.sol";

contract ThePixelsIncMetadataURLProviderV3 is
    IThePixelsMetadataProvider,
    Ownable
{
    using Strings for uint256;

    struct BaseURL {
        bool useDNA;
        string url;
        string description;
    }

    string public initialBaseURL;
    BaseURL[] public baseURLs;

    address public immutable pixelsAddress;
    address public extensionStorageAddress;

    constructor(address _pixelsAddress, address _extensionStorageAddress) {
        pixelsAddress = _pixelsAddress;
        extensionStorageAddress = _extensionStorageAddress;
    }

    // OWNER CONTROLS

    function setInitialBaseURL(string calldata _initialBaseURL)
        external
        onlyOwner
    {
        initialBaseURL = _initialBaseURL;
    }

    function setExtensionStorageAddress(address _extensionStorageAddress)
        external
        onlyOwner
    {
        extensionStorageAddress = _extensionStorageAddress;
    }

    function addBaseURL(
        bool _useDNA,
        string memory _url,
        string memory _description
    ) external onlyOwner {
        baseURLs.push(BaseURL(_useDNA, _url, _description));
    }

    function setBaseURL(
        uint256 id,
        bool _useDNA,
        string memory _url,
        string memory _description
    ) external onlyOwner {
        baseURLs[id] = (BaseURL(_useDNA, _url, _description));
    }

    // PUBLIC

    function getMetadata(
        uint256 tokenId,
        uint256 dna,
        uint256 extensionV1
    ) public view override returns (string memory) {
        uint256 extensionV2 = IThePixelsIncExtensionStorage(
            extensionStorageAddress
        ).pixelExtensions(tokenId);

        string memory fullDNA = _fullDNA(dna, extensionV1, extensionV2);
        BaseURL memory currentBaseURL = baseURLs[baseURLs.length - 1];

        if (extensionV1 > 0 || extensionV2 > 0) {
            if (currentBaseURL.useDNA) {
                return
                    string(abi.encodePacked(currentBaseURL.url, "/", fullDNA));
            } else {
                return
                    string(
                        abi.encodePacked(
                            currentBaseURL.url,
                            "/",
                            tokenId.toString()
                        )
                    );
            }
        } else {
            return string(abi.encodePacked(initialBaseURL, "/", fullDNA));
        }
    }

    function fullDNAOfToken(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 dna = IThePixelsInc(pixelsAddress).pixelDNAs(tokenId);
        uint256 extensionV1 = IThePixelsInc(pixelsAddress).pixelDNAExtensions(
            tokenId
        );
        uint256 extensionV2 = IThePixelsIncExtensionStorage(
            extensionStorageAddress
        ).pixelExtensions(tokenId);

        return _fullDNA(dna, extensionV1, extensionV2);
    }

    function lastBaseURL() public view returns (string memory) {
        return baseURLs[baseURLs.length - 1].url;
    }

    // INTERNAL

    function _fullDNA(
        uint256 _dna,
        uint256 _extensionV1,
        uint256 _extensionV2
    ) internal pure returns (string memory) {
        string memory _extension = _fixedExtension(_extensionV1, _extensionV2);
        return string(abi.encodePacked(_dna.toString(), "_", _extension));
    }

    function _fixedExtension(uint256 _extensionV1, uint256 _extensionV2)
        internal
        pure
        returns (string memory)
    {
        if (_extensionV2 > 0) {
            return
                string(
                    abi.encodePacked(
                        _extensionV1.toString(),
                        _extensionV2.toString()
                    )
                );
        }

        return _extensionV1.toString();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

interface IThePixelsInc {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function updateDNAExtension(uint256 _tokenId) external;

    function pixelDNAs(uint256 _tokenId) external view returns (uint256);

    function pixelDNAExtensions(uint256 _tokenId)
        external
        view
        returns (uint256);
}

// pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

interface IThePixelsMetadataProvider {
    function getMetadata(
        uint256 tokenId,
        uint256 dna,
        uint256 dnaExtension
    ) external view returns (string memory);

    function fullDNAOfToken(uint256 tokenId)
        external
        view
        returns (string memory);
}

// pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

interface IThePixelsIncExtensionStorage {
    struct Variant {
        bool isFreeForCollection;
        bool isDisabled;
        bool isDisabledForSpecialPixels;
        uint16 contributerCut;
        uint128 cost;
        uint128 supply;
        uint128 count;
        address contributer;
        address collection;
    }

    struct VariantStatus {
        bool isAlreadyClaimed;
        uint128 finalCost;
    }

    function extend(
        uint256 extensionId,
        address owner,
        uint256 tokenId,
        uint256 variantId,
        uint128 cost,
        address contributer,
        uint16 contributerCut
    ) external;

    function extendMultiple(
        uint256 extensionId,
        address owner,
        uint256[] calldata tokenIds,
        uint256[] calldata variantIds,
        uint128[] calldata costs,
        address[] calldata contributers,
        uint16[] calldata contributerCuts
    ) external;

    function extendWithVariant(
        uint256 extensionId,
        uint256 tokenId,
        uint256 variantId,
        bool useCollectionTokenId,
        uint256 collectionTokenId
    ) external;

    function extendMultipleWithVariants(
        uint256 extensionId,
        uint256[] memory tokenIds,
        uint256[] memory variantIds,
        bool[] memory useCollectionTokenId,
        uint256[] memory collectionTokenIds
    ) external;

    function variantDetails(
        uint256 extensionId,
        address owner,
        uint256[] memory tokenIds,
        uint256[] memory variantIds,
        bool[] memory useCollectionTokenId,
        uint256[] memory collectionTokenIds
    ) external view returns (Variant[] memory, VariantStatus[] memory);

    function pixelExtensions(uint256 tokenId) external view returns (uint256);

    function pixelExtensionsString(uint256 tokenId)
        external
        view
        returns (string memory);
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