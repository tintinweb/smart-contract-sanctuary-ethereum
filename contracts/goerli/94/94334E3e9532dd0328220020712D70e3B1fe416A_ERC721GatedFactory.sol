// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721GatedImmutable.sol";

/**
 * ERC721Gated factory contract.
 */
contract ERC721GatedFactory {
    event ContractCreated(address contractAddress);

    /**
     * @notice Deploy and initialize contract.
     */
    function deploy(
        address productsModuleAddress_,
        uint256 slicerId_,
        IERC721 erc721_
    ) external returns (address contractAddress) {
        contractAddress = address(
            new ERC721GatedImmutable(productsModuleAddress_, slicerId_, erc721_)
        );

        emit ContractCreated(contractAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721Gated.sol";

/**
 * ERC721Gated purchase hook.
 */
contract ERC721GatedImmutable is ERC721Gated {
    /// ============ Constructor ============

    /**
     * @notice Initializes the contract.
     *
     * @param productsModuleAddress_ {ProductsModule} address
     * @param slicerId_ ID of the slicer linked to this contract
     * @param erc721_ Address of the ERC721 contract used for gating
     */
    constructor(
        address productsModuleAddress_,
        uint256 slicerId_,
        IERC721 erc721_
    ) {
        _productsModuleAddress = productsModuleAddress_;
        _slicerId = slicerId_;
        _erc721 = erc721_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../extensions/Purchasable/SlicerPurchasable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

/**
 * Purchase hook with single ERC20 Gate.
 */
abstract contract ERC721Gated is SlicerPurchasable {
    /// ============= Storage =============

    IERC721 internal _erc721;

    /// ============ Functions ============

    /**
     * @notice Overridable function containing the requirements for an account to be eligible for the purchase.
     *
     * Checks if `account` owns the required amount of ERC20 tokens.
     *
     * @dev Used on the Slice interface to check whether a user is able to buy a product. See {ISlicerPurchasable}.
     * @dev Max quantity purchasable per address and total mint amount is handled on Slicer product logic
     */
    function isPurchaseAllowed(
        uint256,
        uint256,
        address account,
        uint256,
        bytes memory,
        bytes memory
    ) public view virtual override returns (bool isAllowed) {
        uint256 accountBalance = _erc721.balanceOf(account);

        isAllowed = accountBalance != 0;
    }

    /**
     * @notice Overridable function to handle external calls on product purchases from slicers. See {ISlicerPurchasable}
     */
    function onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) public payable override onlyOnPurchaseFrom(slicerId) {
        // Check whether the account is allowed to buy a product.
        if (
            !isPurchaseAllowed(
                slicerId,
                productId,
                account,
                quantity,
                slicerCustomData,
                buyerCustomData
            )
        ) revert NotAllowed();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./interfaces/ISlicerPurchasable.sol";

/**
 * @title SlicerPurchasable
 * @author jjranalli
 *
 * @notice Extension enabling basic usage of external calls by slicers upon product purchase.
 */
abstract contract SlicerPurchasable is ISlicerPurchasable {
    /// ============ Errors ============

    /// @notice Thrown if not called from the correct slicer
    error WrongSlicer();
    /// @notice Thrown if not called during product purchase
    error NotPurchase();
    /// @notice Thrown when account is not allowed to buy product
    error NotAllowed();
    /// @notice Thrown when a critical request was not successful
    error NotSuccessful();

    /// ============ Storage ============

    /// ProductsModule contract address
    address internal _productsModuleAddress;
    /// Id of the slicer able to call the functions with the `OnlyOnPurchaseFrom` function
    uint256 internal _slicerId;

    /// ============ Modifiers ============

    /**
     * @notice Checks product purchases are accepted only from correct slicer (modifier)
     */
    modifier onlyOnPurchaseFrom(uint256 slicerId) {
        _onlyOnPurchaseFrom(slicerId);
        _;
    }

    /// ============ Functions ============

    /**
     * @notice Checks product purchases are accepted only from correct slicer (function)
     */
    function _onlyOnPurchaseFrom(uint256 slicerId) internal view virtual {
        if (_slicerId != slicerId) revert WrongSlicer();
        if (msg.sender != _productsModuleAddress) revert NotPurchase();
    }

    /**
     * @notice Overridable function containing the requirements for an account to be eligible for the purchase.
     *
     * @dev Used on the Slice interface to check whether a user is able to buy a product. See {ISlicerPurchasable}.
     */
    function isPurchaseAllowed(
        uint256,
        uint256,
        address,
        uint256,
        bytes memory,
        bytes memory
    ) public view virtual override returns (bool isAllowed) {
        // Add all requirements related to product purchase here
        // Return true if account is allowed to buy product
        return true;
    }

    /**
     * @notice Overridable function to handle external calls on product purchases from slicers. See {ISlicerPurchasable}
     *
     * @dev Can be inherited by child contracts to add custom logic on product purchases.
     */
    function onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) public payable virtual override onlyOnPurchaseFrom(slicerId) {
        // Check whether the account is allowed to buy a product.
        if (
            !isPurchaseAllowed(
                slicerId,
                productId,
                account,
                quantity,
                slicerCustomData,
                buyerCustomData
            )
        ) revert NotAllowed();

        // Add product purchase logic here
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

interface ISlicerPurchasable {
    /**
     * @notice Overridable function containing the requirements for an account to be eligible for the purchase.
     *
     * @param slicerId ID of the slicer calling the function
     * @param productId ID of the product being purchased
     * @param account Address of the account buying the product
     * @param quantity Amount of products being purchased
     * @param slicerCustomData Custom data sent by slicer during product purchase
     * @param buyerCustomData Custom data sent by buyer during product purchase
     *
     * @dev Used on the Slice interface to check whether a user is able to buy a product.
     */
    function isPurchaseAllowed(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) external view returns (bool);

    /**
     * @notice Overridable function to handle external calls on product purchases from slicers.
     *
     * @param slicerId ID of the slicer calling the function
     * @param productId ID of the product being purchased
     * @param account Address of the account buying the product
     * @param quantity Amount of products being purchased
     * @param slicerCustomData Custom data sent by slicer during product purchase
     * @param buyerCustomData Custom data sent by buyer during product purchase
     *
     * @dev Can be inherited by child contracts to add custom logic on product purchases.
     */
    function onProductPurchase(
        uint256 slicerId,
        uint256 productId,
        address account,
        uint256 quantity,
        bytes memory slicerCustomData,
        bytes memory buyerCustomData
    ) external payable;
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