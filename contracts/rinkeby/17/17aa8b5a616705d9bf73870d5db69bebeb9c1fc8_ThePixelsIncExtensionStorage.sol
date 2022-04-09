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
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ThePixelsDigitsUtility.sol";
import "./../../common/interfaces/IINT.sol";
import "./../../common/interfaces/IThePixelsIncExtensionStorage.sol";
import "./../../common/interfaces/ICoreRewarder.sol";

contract ThePixelsIncExtensionStorage is
    Ownable,
    IThePixelsIncExtensionStorage,
    ThePixelsDigitsUtility
{
    using Strings for uint256;

    struct Extension {
        bool isDisabled;
        uint8 beginIndex;
        uint8 endIndex;
        address operator;
    }

    struct Variant {
        bool isFreeForCollection;
        uint16 contributerCut;
        uint128 cost;
        uint128 availableSupply;
        address contributer;
        address collection;
    }

    bool public isLive;

    address public immutable INTAddress;
    address public immutable DAOAddress;
    address public immutable rewarderAddress;

    uint256 public extensionCount;

    mapping(uint256 => uint256) public override pixelExtensions;
    mapping(uint256 => Extension) public extensions;
    mapping(uint256 => mapping(uint256 => Variant)) public variants;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool)))
        public claimedTokenVariants;

    constructor(
        address _INTAddress,
        address _DAOAddress,
        address _rewarderAddress
    ) {
        INTAddress = _INTAddress;
        DAOAddress = _DAOAddress;
        rewarderAddress = _rewarderAddress;
    }

    // OWNER CONTROLS

    function setIsLive(bool _isLive) external onlyOwner {
        isLive = _isLive;
    }

    function addExtension(
        address operator,
        uint8 beginIndex,
        uint8 endIndex
    ) external onlyOwner {
        require(endIndex > beginIndex, "Indexes are invalid");
        extensions[extensionCount].operator = operator;
        extensions[extensionCount].beginIndex = beginIndex;
        extensions[extensionCount].endIndex = endIndex;
        emit ExtensionAdded(extensionCount, operator, beginIndex, endIndex);
        extensionCount++;
    }

    function updateExtension(
        uint256 id,
        address operator,
        uint8 beginIndex,
        uint8 endIndex
    ) external onlyOwner {
        require(endIndex > beginIndex, "Indexes are invalid");
        require(id < extensionCount, "Invalid id");
        extensions[id].operator = operator;
        extensions[id].beginIndex = beginIndex;
        extensions[id].endIndex = endIndex;
        emit ExtensionUpdated(id, operator, beginIndex, endIndex);
    }

    function disableExtension(uint256 extensionId) external onlyOwner {
        extensions[extensionId].isDisabled = true;
    }

    function enableExtension(uint256 extensionId) external onlyOwner {
        extensions[extensionId].isDisabled = false;
    }

    function setVariant(
        uint256 extensionId,
        uint256 id,
        address contributer,
        address collection,
        bool isFreeForCollection,
        uint16 contributerCut,
        uint128 cost,
        uint128 availableSupply
    ) public onlyOwner {
        variants[extensionId][id] = Variant(
            isFreeForCollection,
            contributerCut,
            cost,
            availableSupply,
            contributer,
            collection
        );
        emit VariantUpdated(
            id,
            isFreeForCollection,
            contributerCut,
            cost,
            availableSupply,
            contributer,
            collection
        );
    }

    function setVariants(
        uint256[] memory extensionIds,
        uint256[] memory ids,
        address[] memory contributers,
        address[] memory collections,
        bool[] memory isFreeForCollection,
        uint16[] memory contributerCuts,
        uint128[] memory costs,
        uint128[] memory availableSupplies
    ) public onlyOwner {
        for (uint256 i; i < ids.length; i++) {
            setVariant(
                extensionIds[i],
                ids[i],
                contributers[i],
                collections[i],
                isFreeForCollection[i],
                contributerCuts[i],
                costs[i],
                availableSupplies[i]
            );
        }
    }

    // PUBILC CONTROLS

    function extend(
        uint256 extensionId,
        address owner,
        uint256 tokenId,
        uint256 variantId,
        uint128 cost,
        address contributer,
        uint16 contributerCut
    ) public override {
        require(isLive, "Extension storage is not live");
        Extension memory extension = extensions[extensionId];
        require(!extension.isDisabled, "This extension is disabled");
        require(extension.operator == msg.sender, "Not authorised");

        _extend(
            extension,
            extensionId,
            owner,
            tokenId,
            variantId,
            cost,
            contributer,
            contributerCut
        );
    }

    function extendMultiple(
        uint256 extensionId,
        address owner,
        uint256[] calldata tokenIds,
        uint256[] calldata variantIds,
        uint128[] calldata costs,
        address[] calldata contributers,
        uint16[] calldata contributerCuts
    ) public override {
        require(isLive, "Extension storage is not live");
        Extension memory extension = extensions[extensionId];
        require(!extension.isDisabled, "This extension is disabled");
        require(extension.operator == msg.sender, "Not authorised");

        for (uint256 i; i < tokenIds.length; i++) {
            _extend(
                extension,
                extensionId,
                owner,
                tokenIds[i],
                variantIds[i],
                costs[i],
                contributers[i],
                contributerCuts[i]
            );
        }
    }

    function extendWithVariant(
        uint256 extensionId,
        uint256 tokenId,
        uint256 variantId
    ) public override {
        require(isLive, "Extension storage is not live");
        Extension memory extension = extensions[extensionId];
        require(!extension.isDisabled, "This extension is disabled");

        if (extension.operator != msg.sender) {
            require(
                ICoreRewarder(rewarderAddress).isOwner(msg.sender, tokenId),
                "Not authorised"
            );
        }

        _extendWithVariant(
            extension,
            extensionId,
            msg.sender,
            tokenId,
            variantId
        );
    }

    function extendMultipleWithVariants(
        uint256 extensionId,
        uint256[] memory tokenIds,
        uint256[] memory variantIds
    ) public override {
        require(isLive, "Extension storage is not live");
        Extension memory extension = extensions[extensionId];
        require(!extension.isDisabled, "This extension is disabled");

        for (uint256 i; i < tokenIds.length; i++) {
            if (extension.operator != msg.sender) {
                require(
                    ICoreRewarder(rewarderAddress).isOwner(
                        msg.sender,
                        tokenIds[i]
                    ),
                    "Not authorised"
                );
            }

            _extendWithVariant(
                extension,
                extensionId,
                msg.sender,
                tokenIds[i],
                variantIds[i]
            );
        }
    }

    // UTILITY

    function variantDetails(
        uint256 extensionId,
        address owner,
        uint256[] memory tokenIds,
        uint256[] memory variantIds
    ) public view override returns (VariantSatus[] memory) {
        VariantSatus[] memory statusses = new VariantSatus[](tokenIds.length);

        for (uint256 i; i < variantIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 variantId = variantIds[i];
            Variant memory variant = variants[extensionId][variantId];

            statusses[i].cost = _getCostOfVariant(variant, owner);
            statusses[i].finalCost = statusses[i].cost;

            if (claimedTokenVariants[extensionId][tokenId][variantId]) {
                statusses[i].isAlreadyClaimed = true;
                statusses[i].finalCost = 0;
            }

            if (variant.isFreeForCollection) {
                if (IERC721(variant.collection).balanceOf(owner) > 0) {
                    statusses[i].isFreeForCollection = true;
                }
            }
        }

        return statusses;
    }

    function pixelExtensionsString(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        return pixelExtensions[tokenId].toString();
    }

    // INTERNAL

    function _extend(
        Extension memory _extension,
        uint256 _extensionId,
        address _owner,
        uint256 _tokenId,
        uint256 _variantId,
        uint128 _cost,
        address _contributer,
        uint16 _contributerCut
    ) internal {
        Variant memory _variant = variants[_extensionId][_variantId];
        require(_variant.contributer != address(0), "Invalid variant");
        require(_variant.availableSupply > 0, "Sorry, sold out");
        _variant.availableSupply--;
        variants[_extensionId][_variantId] = _variant;

        _storeVariant(
            _owner,
            _extensionId,
            _extension.beginIndex,
            _extension.endIndex,
            _tokenId,
            _variantId
        );

        if (!claimedTokenVariants[_extensionId][_tokenId][_variantId]) {
            claimedTokenVariants[_extensionId][_tokenId][_variantId] = true;
            _spendINT(_owner, _cost, _contributer, _contributerCut);
        }
    }

    function _extendWithVariant(
        Extension memory _extension,
        uint256 _extensionId,
        address _owner,
        uint256 _tokenId,
        uint256 _variantId
    ) internal {
        Variant memory _variant = variants[_extensionId][_variantId];
        require(_variant.contributer != address(0), "Invalid variant");
        require(_variant.availableSupply > 0, "Sorry, sold out");
        variants[_extensionId][_variantId].availableSupply--;

        if (!claimedTokenVariants[_extensionId][_tokenId][_variantId]) {
            claimedTokenVariants[_extensionId][_tokenId][_variantId] = true;
            uint128 _cost = _getCostOfVariant(_variant, _owner);

            _storeVariant(
                _owner,
                _extensionId,
                _extension.beginIndex,
                _extension.endIndex,
                _tokenId,
                _variantId
            );

            if (_cost > 0) {
                _spendINT(
                    _owner,
                    _cost,
                    _variant.contributer,
                    _variant.contributerCut
                );
            }

            return;
        }

        _storeVariant(
            _owner,
            _extensionId,
            _extension.beginIndex,
            _extension.endIndex,
            _tokenId,
            _variantId
        );
    }

    function _getCostOfVariant(Variant memory _variant, address _owner)
        internal
        view
        returns (uint128)
    {
        if (_variant.isFreeForCollection) {
            if (IERC721(_variant.collection).balanceOf(_owner) > 0) {
                return 0;
            }
        }
        return _variant.cost;
    }

    function _storeVariant(
        address _owner,
        uint256 _extensionId,
        uint8 _beginIndex,
        uint8 _endIndex,
        uint256 _tokenId,
        uint256 _value
    ) internal {
        uint256 value = pixelExtensions[_tokenId];
        uint256 newValue = _replacedDigits(
            value,
            _digitOf(value),
            _beginIndex,
            _endIndex,
            _value
        );
        pixelExtensions[_tokenId] = newValue;
        emit Extended(_owner, _tokenId, _extensionId, value, newValue);
    }

    function _spendINT(
        address _owner,
        uint128 _amount,
        address _contributer,
        uint16 _contributerCut
    ) internal {
        if (_amount == 0) {
            return;
        }

        uint128 contributerAmount;
        uint128 daoAmount;
        unchecked {
            if (_contributerCut > 0) {
                contributerAmount = _amount / _contributerCut;
                daoAmount = _amount - contributerAmount;
            } else {
                daoAmount = _amount;
            }

            if (daoAmount > 0) {
                IINT(INTAddress).transferFrom(_owner, DAOAddress, daoAmount);
            }

            if (contributerAmount > 0) {
                IINT(INTAddress).transferFrom(
                    _owner,
                    _contributer,
                    contributerAmount
                );
            }
        }
    }

    // EVENTS

    event Extended(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 extensionId,
        uint256 previousExtension,
        uint256 newExtension
    );

    event ExtensionAdded(
        uint256 indexed id,
        address operator,
        uint8 beginIndex,
        uint8 endIndex
    );

    event ExtensionUpdated(
        uint256 indexed id,
        address operator,
        uint8 beginIndex,
        uint8 endIndex
    );

    event VariantUpdated(
        uint256 indexed id,
        bool isFreeForCollection,
        uint16 contributerCut,
        uint128 cost,
        uint128 availableSupply,
        address contributer,
        address collection
    );
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

// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract ThePixelsDigitsUtility {
    using Strings for uint256;

    function _replacedDigits(
        uint256 value,
        uint256 length,
        uint256 beginIndex,
        uint256 endIndex,
        uint256 replaceValue
    ) internal pure returns (uint256) {
        require(endIndex > beginIndex, "Indexes are invalid");

        unchecked {
            uint256 maxReplaceValue = uint256(10**(endIndex - beginIndex) - 1);
            require(
                replaceValue <= maxReplaceValue,
                "Replace value is too big"
            );

            uint256 minReplaceValue = uint256(10**(endIndex - beginIndex - 1));
            require(
                replaceValue >= minReplaceValue,
                "Replace value is too small"
            );

            if (length == 0) {
                length = 1;
            }

            if (beginIndex < length && endIndex < length) {
                uint256 left = (value / (10**(length - beginIndex))) *
                    (10**(length - beginIndex));
                uint256 middle = replaceValue * (10**(length - endIndex));
                uint256 leftFromEndIndex = uint256(
                    (value / (10**(length - endIndex))) *
                        (10**(length - endIndex))
                );
                uint256 right = value - leftFromEndIndex;
                return left + middle + right;
            } else if (beginIndex >= length && endIndex >= length) {
                uint256 left = value * (10**(endIndex - length));
                return left + replaceValue;
            } else if (beginIndex < length && endIndex >= length) {
                uint256 left = (value / (10**(length - beginIndex))) *
                    (10**(endIndex - beginIndex));
                return left + replaceValue;
            }
        }

        return value;
    }

    function _digitOf(uint256 value) internal pure returns (uint256) {
        return bytes(value.toString()).length;
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

interface IINT {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
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
    struct VariantSatus {
        bool isFreeForCollection;
        bool isAlreadyClaimed;
        uint128 cost;
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
        uint256 variantId
    ) external;

    function extendMultipleWithVariants(
        uint256 extensionId,
        uint256[] memory tokenIds,
        uint256[] memory variantIds
    ) external;

    function variantDetails(
        uint256 extensionId,
        address owner,
        uint256[] memory tokenIds,
        uint256[] memory variantIds
    ) external view returns (VariantSatus[] memory);

    function pixelExtensions(uint256 tokenId) external view returns (uint256);

    function pixelExtensionsString(uint256 tokenId)
        external
        view
        returns (string memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

interface ICoreRewarder {
    function stake(
        uint256[] calldata tokenIds
    ) external;

    function withdraw(
        uint256[] calldata tokenIds
    ) external;

    function claim(uint256[] calldata tokenIds) external;

    function earned(uint256[] memory tokenIds)
        external
        view
        returns (uint256);

    function lastClaimTimesOfTokens(uint256[] memory tokenIds)
        external
        view
        returns (uint256[] memory);

    function isOwner(address owner, uint256 tokenId)
        external
        view
        returns (bool);

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);

    function stakedTokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory);
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