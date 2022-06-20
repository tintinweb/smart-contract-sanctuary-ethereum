// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./ThePixelsDigitsUtility.sol";
import "./../../common/interfaces/IINT.sol";
import "./../../common/interfaces/IThePixelsIncExtensionStorageV2.sol";
import "./../../common/interfaces/ICoreRewarder.sol";

contract ThePixelsIncExtensionStorageV2 is
    Ownable,
    IThePixelsIncExtensionStorageV2,
    ThePixelsDigitsUtility
{
    struct Extension {
        bool isEnabled;
        bool isSticky;
        uint8 beginIndex;
        uint8 endIndex;
        address operator;
    }

    bool public isLive;

    address public immutable INTAddress;
    address public DAOAddress;
    address public rewarderAddress;

    uint256 public extensionCount;

    mapping(uint256 => uint256) public override pixelExtensions;
    mapping(uint256 => Extension) public extensions;
    mapping(uint256 => mapping(uint256 => Variant)) public variants;
    mapping(uint256 => mapping(uint256 => Category)) public categories;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool)))
        public claimedPixelVariants;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool)))
        public usedCollectionTokens;

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

    function setDAOAddress(address _DAOAddress) external onlyOwner {
        DAOAddress = _DAOAddress;
    }

    function setRewarderAddress(address _rewarderAddress) external onlyOwner {
        rewarderAddress = _rewarderAddress;
    }

    function setExtension(uint256 extensionId, Extension memory extension)
        public
        onlyOwner
    {
        require(
            extension.endIndex > extension.beginIndex,
            "Indexes are invalid"
        );
        extensions[extensionId] = extension;
        emitExtensionChangeEvent(extensionId, extension);
    }

    function setExtensions(
        uint256[] memory extensionIds,
        Extension[] memory _extensions
    ) public onlyOwner {
        for (uint256 i = 0; i < extensionIds.length; i++) {
            setExtension(extensionIds[i], _extensions[i]);
        }
    }

    function enableExtension(uint256 extensionId, bool isEnabled)
        external
        onlyOwner
    {
        extensions[extensionId].isEnabled = isEnabled;
        emitExtensionChangeEvent(extensionId, extensions[extensionId]);
    }

    function setVariant(
        uint256 extensionId,
        uint256 variantId,
        Variant memory variant
    ) public onlyOwner {
        variants[extensionId][variantId] = variant;
        emitVariantChangeEvent(extensionId, variantId, variant);
    }

    function setVariants(
        uint256 extensionId,
        uint256[] memory variantIds,
        Variant[] memory _variants
    ) public onlyOwner {
        for (uint256 i; i < variantIds.length; i++) {
            setVariant(extensionId, variantIds[i], _variants[i]);
        }
    }

    function enableVariant(
        uint256 extensionId,
        uint256 variantId,
        bool isEnabled
    ) external onlyOwner {
        variants[extensionId][variantId].isEnabled = isEnabled;
        emitVariantChangeEvent(
            extensionId,
            variantId,
            variants[extensionId][variantId]
        );
    }

    function setCategory(
        uint256 extensionId,
        uint256 categoryId,
        Category memory category
    ) public onlyOwner {
        categories[extensionId][categoryId] = category;
        emitCategoryChangeEvent(extensionId, categoryId, category);
    }

    function setCategories(
        uint256 extensionId,
        uint256[] memory categoryIds,
        Category[] memory _categories
    ) public onlyOwner {
        for (uint256 i; i < categoryIds.length; i++) {
            setCategory(extensionId, categoryIds[i], _categories[i]);
        }
    }

    // Used for migration
    function setClaimedPixelVariants(
        uint256[] memory extensionIds,
        uint256[] memory tokenIds,
        uint256[] memory variantIds,
        bool[] memory isClaimeds
    ) public onlyOwner {
        for (uint256 i; i < extensionIds.length; i++) {
            claimedPixelVariants[extensionIds[i]][tokenIds[i]][
                variantIds[i]
            ] = isClaimeds[i];
        }
    }

    // Used for migration
    function setPixelExtensions(
        uint256[] memory tokenIds,
        uint256[] memory _pixelExtensions
    ) public onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            pixelExtensions[tokenIds[i]] = _pixelExtensions[i];
        }
    }

    // PUBILC CONTROLS

    function extendWithVariant(
        address owner,
        uint256 extensionId,
        uint256 tokenId,
        uint256 variantId,
        bool useCollectionTokenId,
        uint256 collectionTokenId
    ) public override {
        require(isLive, "Extension storage is not live");
        Extension memory extension = extensions[extensionId];
        require(extension.isEnabled, "This extension is disabled");

        _extendWithVariant(
            owner,
            extension,
            extensionId,
            tokenId,
            variantId,
            useCollectionTokenId,
            collectionTokenId
        );
    }

    function extendMultipleWithVariants(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds,
        uint256[] memory variantIds,
        bool[] memory useCollectionTokenIds,
        uint256[] memory collectionTokenIds
    ) public override {
        require(isLive, "Extension storage is not live");
        Extension memory extension = extensions[extensionId];
        require(extension.isEnabled, "This extension is disabled");

        for (uint256 i; i < tokenIds.length; i++) {
            _extendWithVariant(
                owner,
                extension,
                extensionId,
                tokenIds[i],
                variantIds[i],
                useCollectionTokenIds[i],
                collectionTokenIds[i]
            );
        }
    }

    function detachVariant(
        address owner,
        uint256 extensionId,
        uint256 tokenId
    ) public override {
        require(isLive, "Extension storage is not live");
        Extension memory extension = extensions[extensionId];
        require(extension.isEnabled, "This extension is disabled");

        _detachExtensionVariant(owner, extension, extensionId, tokenId);
    }

    function detachVariants(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds
    ) public override {
        require(isLive, "Extension storage is not live");
        Extension memory extension = extensions[extensionId];
        require(extension.isEnabled, "This extension is disabled");

        for (uint256 i; i < tokenIds.length; i++) {
            _detachExtensionVariant(owner, extension, extensionId, tokenIds[i]);
        }
    }

    function transferExtensionVariant(
        address owner,
        uint256 extensionId,
        uint256 variantId,
        uint256 fromTokenId,
        uint256 toTokenId
    ) public override {
        require(isLive, "Extension storage is not live");
        Extension memory extension = extensions[extensionId];
        require(extension.isEnabled, "This extension is disabled");
        require(!extension.isSticky, "This extension is sticky");

        Variant memory _variant = variants[extensionId][variantId];
        require(_variant.isEnabled, "This variant is disabled");

        require(
            extension.operator == msg.sender || owner == msg.sender,
            "Not authorised - Invalid owner or operator"
        );

        require(
            ICoreRewarder(rewarderAddress).isOwner(owner, fromTokenId),
            "Not authorised - Invalid owner"
        );

        bool ownershipOfSender = claimedPixelVariants[extensionId][fromTokenId][
            variantId
        ];
        require(ownershipOfSender, "Sender doesn't own this variant");
        uint256 currentVariantId = currentVariantIdOf(extensionId, fromTokenId);
        if (currentVariantId == variantId) {
            _detach(
                msg.sender,
                extensionId,
                extension.beginIndex,
                extension.endIndex,
                fromTokenId
            );
        }

        bool ownershipOfRecipent = claimedPixelVariants[extensionId][toTokenId][
            variantId
        ];
        require(!ownershipOfRecipent, "Recipent already has this variant");

        claimedPixelVariants[extensionId][fromTokenId][variantId] = false;
        claimedPixelVariants[extensionId][toTokenId][variantId] = true;

        emit VariantTransferred(extensionId, variantId, fromTokenId, toTokenId);
    }

    // UTILITY

    function variantDetail(
        address owner,
        uint256 extensionId,
        uint256 tokenId,
        uint256 variantId,
        bool useCollectionTokenId,
        uint256 collectionTokenId
    ) public view override returns (Variant memory, VariantStatus memory) {
        Variant memory variant = variants[extensionId][variantId];
        VariantStatus memory status;

        (uint128 _cost, uint128 _supply) = _costAndSupplyOfVariant(
            extensionId,
            variant
        );

        status.cost = _cost;
        status.supply = _supply;

        bool isFreeForCollection = _shouldConsumeCollectionToken(
            owner,
            extensionId,
            variantId,
            useCollectionTokenId,
            collectionTokenId,
            variant
        );

        if (isFreeForCollection) {
            status.cost = 0;
        }

        if (claimedPixelVariants[extensionId][tokenId][variantId]) {
            status.isAlreadyClaimed = true;
            status.cost = 0;
        }

        return (variant, status);
    }

    function variantDetails(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds,
        uint256[] memory variantIds,
        bool[] memory useCollectionTokenIds,
        uint256[] memory collectionTokenIds
    ) public view override returns (Variant[] memory, VariantStatus[] memory) {
        VariantStatus[] memory statuses = new VariantStatus[](
            variantIds.length
        );
        Variant[] memory _variants = new Variant[](variantIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            (
                Variant memory _variant,
                VariantStatus memory _status
            ) = variantDetail(
                    owner,
                    extensionId,
                    tokenIds[i],
                    variantIds[i],
                    useCollectionTokenIds[i],
                    collectionTokenIds[i]
                );
            _variants[i] = _variant;
            statuses[i] = _status;
        }

        return (_variants, statuses);
    }

    function variantsOfExtension(
        uint256 extensionId,
        uint256[] memory variantIds
    ) public view override returns (Variant[] memory) {
        Variant[] memory _variants = new Variant[](variantIds.length);

        for (uint256 i; i < variantIds.length; i++) {
            _variants[i] = variants[extensionId][variantIds[i]];
        }

        return _variants;
    }

    function balanceOfToken(
        uint256 extensionId,
        uint256 tokenId,
        uint256[] memory variantIds
    ) public view override returns (uint256) {
        uint256 balance;
        for (uint256 i; i < variantIds.length; i++) {
            uint256 variantId = variantIds[i];
            if (claimedPixelVariants[extensionId][tokenId][variantId]) {
                balance++;
            }
        }
        return balance;
    }

    function currentVariantIdOf(uint256 extensionId, uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        Extension memory extension = extensions[extensionId];
        uint256 value = pixelExtensions[tokenId];
        return _digitsAt(value, extension.beginIndex, extension.endIndex);
    }

    function currentVariantIdsOf(uint256 extensionId, uint256[] memory tokenIds)
        public
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory _variants = new uint256[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; i++) {
            _variants[i] = currentVariantIdOf(extensionId, tokenIds[i]);
        }
        return _variants;
    }

    // INTERNAL

    function _extendWithVariant(
        address _owner,
        Extension memory _extension,
        uint256 _extensionId,
        uint256 _tokenId,
        uint256 _variantId,
        bool _useCollectionTokenId,
        uint256 _collectionTokenId
    ) internal {
        Variant memory _variant = variants[_extensionId][_variantId];
        require(_variant.isEnabled, "This variant is disabled");

        if (_variant.isOperatorExecution) {
            require(
                _extension.operator == msg.sender,
                "Not authroised - Invalid operator"
            );
        } else {
            require(_owner == msg.sender, "Not authroised - Invalid owner");
        }

        require(
            ICoreRewarder(rewarderAddress).isOwner(_owner, _tokenId),
            "Not authorised - Invalid owner"
        );

        if (_variant.isDisabledForSpecialPixels) {
            require(
                !_isSpecialPixel(_tokenId),
                "This variant is not for special pixels"
            );
        }

        _extend(
            _owner,
            _extensionId,
            _extension.beginIndex,
            _extension.endIndex,
            _tokenId,
            _variantId
        );

        if (!claimedPixelVariants[_extensionId][_tokenId][_variantId]) {
            (uint128 _cost, uint128 _supply) = _costAndSupplyOfVariant(
                _extensionId,
                _variant
            );

            bool shouldConsumeCollectionToken = _shouldConsumeCollectionToken(
                _owner,
                _extensionId,
                _variantId,
                _useCollectionTokenId,
                _collectionTokenId,
                _variant
            );

            if (shouldConsumeCollectionToken) {
                _cost = 0;
                usedCollectionTokens[_extensionId][_variantId][
                    _collectionTokenId
                ] = true;
            }

            if (_supply != 0) {
                require(_variant.count < _supply, "Sorry, sold out");
                variants[_extensionId][_variantId].count++;
            }

            claimedPixelVariants[_extensionId][_tokenId][_variantId] = true;

            if (_cost > 0) {
                _spendINT(
                    _owner,
                    _cost,
                    _variant.contributer,
                    _variant.contributerCut
                );
            }
        }
    }

    function _detachExtensionVariant(
        address _owner,
        Extension memory _extension,
        uint256 _extensionId,
        uint256 _tokenId
    ) internal {
        require(!_extension.isSticky, "This extension is sticky");
        require(
            _extension.operator == msg.sender || _owner == msg.sender,
            "Not authorised - Invalid owner or operator"
        );

        require(
            ICoreRewarder(rewarderAddress).isOwner(_owner, _tokenId),
            "Not authorised - Invalid owner"
        );

        _detach(
            _owner,
            _extensionId,
            _extension.beginIndex,
            _extension.endIndex,
            _tokenId
        );
    }

    function _extend(
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
            _beginIndex,
            _endIndex,
            _value
        );
        pixelExtensions[_tokenId] = newValue;
        emit Extended(_owner, _tokenId, _extensionId, value, newValue);
    }

    function _detach(
        address _owner,
        uint256 _extensionId,
        uint8 _beginIndex,
        uint8 _endIndex,
        uint256 _tokenId
    ) internal {
        uint256 value = pixelExtensions[_tokenId];
        uint256 newValue = _clearDigits(value, _beginIndex, _endIndex);
        pixelExtensions[_tokenId] = newValue;
        emit Detached(_owner, _tokenId, _extensionId, value, newValue);
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

        emit INTSpent(_owner, _contributer, contributerAmount, daoAmount);
    }

    function _costAndSupplyOfVariant(
        uint256 _extensionId,
        Variant memory _variant
    ) internal view returns (uint128, uint128) {
        uint128 _cost = _variant.cost;
        uint128 _supply = _variant.supply;

        if (_variant.categoryId > 0) {
            Category memory _category = categories[_extensionId][
                _variant.categoryId
            ];
            _cost = _category.cost;
            _supply = _category.supply;
        }

        return (_cost, _supply);
    }

    function _shouldConsumeCollectionToken(
        address _owner,
        uint256 _extensionId,
        uint256 _variantId,
        bool _useCollectionTokenId,
        uint256 _collectionTokenId,
        Variant memory _variant
    ) internal view returns (bool) {
        if (_variant.isFreeForCollection && _useCollectionTokenId) {
            if (
                !usedCollectionTokens[_extensionId][_variantId][
                    _collectionTokenId
                ] &&
                IERC721(_variant.collection).ownerOf(_collectionTokenId) ==
                _owner
            ) {
                return true;
            }
        }
        return false;
    }

    function _isSpecialPixel(uint256 tokenId) internal pure returns (bool) {
        if (
            tokenId == 5061 ||
            tokenId == 5060 ||
            tokenId == 5059 ||
            tokenId == 5058 ||
            tokenId == 5057
        ) {
            return true;
        }
        return false;
    }

    // EVENTS

    function emitExtensionChangeEvent(
        uint256 extensionId,
        Extension memory extension
    ) internal {
        emit ExtensionChanged(
            extensionId,
            extension.operator,
            extension.isEnabled,
            extension.isSticky,
            extension.beginIndex,
            extension.endIndex
        );
    }

    function emitVariantChangeEvent(
        uint256 extensionId,
        uint256 variantId,
        Variant memory variant
    ) internal {
        emit VariantChanged(
            extensionId,
            variantId,
            variant.isOperatorExecution,
            variant.isFreeForCollection,
            variant.isEnabled,
            variant.isDisabledForSpecialPixels,
            variant.contributerCut,
            variant.cost,
            variant.supply,
            variant.count,
            variant.contributer,
            variant.collection
        );
    }

    function emitCategoryChangeEvent(
        uint256 extensionId,
        uint256 categoryId,
        Category memory category
    ) internal {
        emit CategoryChanged(
            extensionId,
            categoryId,
            category.cost,
            category.supply
        );
    }

    event Extended(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 extensionId,
        uint256 previousExtension,
        uint256 newExtension
    );

    event Detached(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 extensionId,
        uint256 previousExtension,
        uint256 newExtension
    );

    event ExtensionChanged(
        uint256 indexed extensionId,
        address operator,
        bool isEnabled,
        bool isSticky,
        uint8 beginIndex,
        uint8 endIndex
    );

    event VariantChanged(
        uint256 indexed extensionId,
        uint256 indexed variantId,
        bool isOperatorExecution,
        bool isFreeForCollection,
        bool isEnabled,
        bool isDisabledForSpecialPixels,
        uint16 contributerCut,
        uint128 cost,
        uint128 supply,
        uint128 count,
        address contributer,
        address collection
    );

    event CategoryChanged(
        uint256 indexed extensionId,
        uint256 indexed categoryId,
        uint128 cost,
        uint128 supply
    );

    event VariantTransferred(
        uint256 indexed extensionId,
        uint256 indexed variantId,
        uint256 fromTokenId,
        uint256 toTokenId
    );

    event INTSpent(
        address indexed owner,
        address contributer,
        uint256 contributerAmount,
        uint256 daoAmount
    );
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

    function _clearDigits(
        uint256 value,
        uint256 beginIndex,
        uint256 endIndex
    ) internal pure returns (uint256) {
        require(endIndex > beginIndex, "Indexes are invalid");
        uint256 _replaceValue = uint256(10**(endIndex - beginIndex - 1));
        return _replacedDigits(
            value, 
            beginIndex, 
            endIndex, 
            _replaceValue
        );
    }

    function _replacedDigits(
        uint256 value,
        uint256 beginIndex,
        uint256 endIndex,
        uint256 replaceValue
    ) internal pure returns (uint256) {
        require(endIndex > beginIndex, "Indexes are invalid");

        unchecked {
            uint256 length = _digitOf(value);
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

            if (value == 0) {
                value = 1;
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

    function _digitsAt(
        uint256 value,
        uint256 beginIndex,
        uint256 endIndex
    ) internal pure returns (uint256) {
        require(endIndex > beginIndex, "Indexes are invalid");

        unchecked {
            uint256 length = _digitOf(value);
            if (beginIndex < length && endIndex <= length) {
                uint256 left = (value / (10**(length - beginIndex))) *
                    (10**(length - beginIndex));
                uint256 valueWithoutLeft = value - left;
                return valueWithoutLeft / (10**(length - endIndex));
            } else if (beginIndex >= length && endIndex >= length) {
                return 0;
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

interface IThePixelsIncExtensionStorageV2 {
    struct Variant {
        bool isOperatorExecution;
        bool isFreeForCollection;
        bool isEnabled;
        bool isDisabledForSpecialPixels;
        uint16 contributerCut;
        uint128 cost;
        uint128 supply;
        uint128 count;
        uint128 categoryId;
        address contributer;
        address collection;
    }

    struct Category {
        uint128 cost;
        uint128 supply;
    }

    struct VariantStatus {
        bool isAlreadyClaimed;
        uint128 cost;
        uint128 supply;
    }

    function extendWithVariant(
        address owner,
        uint256 extensionId,
        uint256 tokenId,
        uint256 variantId,
        bool useCollectionTokenId,
        uint256 collectionTokenId
    ) external;

    function extendMultipleWithVariants(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds,
        uint256[] memory variantIds,
        bool[] memory useCollectionTokenId,
        uint256[] memory collectionTokenIds
    ) external;

    function detachVariant(
        address owner,
        uint256 extensionId,
        uint256 tokenId
    ) external;

    function detachVariants(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds
    ) external;

    function variantDetail(
        address owner,
        uint256 extensionId,
        uint256 tokenId,
        uint256 variantId,
        bool useCollectionTokenId,
        uint256 collectionTokenId
    ) external view returns (Variant memory, VariantStatus memory);

    function variantDetails(
        address owner,
        uint256 extensionId,
        uint256[] memory tokenIds,
        uint256[] memory variantIds,
        bool[] memory useCollectionTokenIds,
        uint256[] memory collectionTokenIds
    ) external view returns (Variant[] memory, VariantStatus[] memory);

    function variantsOfExtension(
        uint256 extensionId,
        uint256[] memory variantIds
    ) external view returns (Variant[] memory);

    function transferExtensionVariant(
        address owner,
        uint256 extensionId,
        uint256 variantId,
        uint256 fromTokenId,
        uint256 toTokenId
    ) external;

    function pixelExtensions(uint256 tokenId) external view returns (uint256);

    function balanceOfToken(
        uint256 extensionId,
        uint256 tokenId,
        uint256[] memory variantIds
    ) external view returns (uint256);

    function currentVariantIdOf(uint256 extensionId, uint256 tokenId)
        external
        view
        returns (uint256);

    function currentVariantIdsOf(uint256 extensionId, uint256[] memory tokenIds)
        external
        view
        returns (uint256[] memory);
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