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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "solmate/src/utils/ReentrancyGuard.sol";

contract TradeCoinCompositionSales is ReentrancyGuard {
    struct SaleQueue {
        address seller;
        address newOwner;
        uint256 priceInWei;
        bool payInFiat;
        bool isPayed;
    }

    struct Documents {
        bytes32[] docHashes;
        bytes32[] docTypes;
        bytes32 rootHash;
    }

    address public immutable tradeCoinComposition;

    uint256 public tradeCoinTokenBalance;
    uint256 public weiBalance;

    event InitiateCommercialTxEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        address indexed buyer,
        bool payInFiat,
        uint256 priceInWei,
        bool isPayed,
        bytes32[] docHashes,
        bytes32[] docTypes,
        bytes32 rootHash
    );

    event FinishCommercialTxEvent(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed functionCaller,
        bytes32[] dochashes,
        bytes32[] docTypes,
        bytes32 rootHash
    );

    event CompleteSaleEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32[] dochashes,
        bytes32[] docTypes,
        bytes32 rootHash
    );

    event ReverseSaleEvent(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32[] dochashes,
        bytes32[] docTypes,
        bytes32 rootHash
    );

    event ServicePaymentEvent(
        uint256 indexed tokenId,
        address indexed receiver,
        address indexed sender,
        bytes32 indexedDocHashes,
        bytes32[] docHashes,
        bytes32[] docTypes,
        bytes32 rootHash,
        uint256 paymentInWei,
        bool payInFiat
    );

    constructor(address _tradeCoinComposition) {
        tradeCoinComposition = _tradeCoinComposition;
    }

    mapping(uint256 => SaleQueue) public pendingSales;

    function initiateCommercialTx(
        uint256 _tradeCoinCompositionTokenID,
        uint256 _priceInWei,
        address _newOwner,
        Documents memory _documents,
        bool _payInFiat
    ) external {
        IERC721(tradeCoinComposition).transferFrom(
            msg.sender,
            address(this),
            _tradeCoinCompositionTokenID
        );
        pendingSales[_tradeCoinCompositionTokenID] = SaleQueue(
            msg.sender,
            _newOwner,
            _priceInWei,
            _payInFiat,
            _priceInWei == 0
        );
        tradeCoinTokenBalance += 1;
        emit InitiateCommercialTxEvent(
            _tradeCoinCompositionTokenID,
            msg.sender,
            _newOwner,
            _payInFiat,
            _priceInWei,
            _priceInWei == 0,
            _documents.docHashes,
            _documents.docTypes,
            _documents.rootHash
        );
    }

    function finishCommercialTx(
        uint256 _tradeCoinCompositionTokenID,
        Documents memory _documents
    ) external payable {
        if (!pendingSales[_tradeCoinCompositionTokenID].payInFiat) {
            require(
                pendingSales[_tradeCoinCompositionTokenID].priceInWei ==
                    msg.value,
                "Not the right price"
            );
        }
        address legalOwner = pendingSales[_tradeCoinCompositionTokenID].seller;

        pendingSales[_tradeCoinCompositionTokenID].isPayed = true;
        weiBalance += msg.value;
        emit FinishCommercialTxEvent(
            _tradeCoinCompositionTokenID,
            legalOwner,
            msg.sender,
            _documents.docHashes,
            _documents.docTypes,
            _documents.rootHash
        );
        completeSale(_tradeCoinCompositionTokenID, _documents);
    }

    function completeSale(
        uint256 _tradeCoinCompositionTokenID,
        Documents memory _documents
    ) internal nonReentrant {
        require(
            pendingSales[_tradeCoinCompositionTokenID].isPayed,
            "Not payed"
        );
        weiBalance -= pendingSales[_tradeCoinCompositionTokenID].priceInWei;
        tradeCoinTokenBalance -= 1;
        IERC721(tradeCoinComposition).transferFrom(
            address(this),
            pendingSales[_tradeCoinCompositionTokenID].newOwner,
            _tradeCoinCompositionTokenID
        );
        payable(pendingSales[_tradeCoinCompositionTokenID].seller).transfer(
            pendingSales[_tradeCoinCompositionTokenID].priceInWei
        );
        delete pendingSales[_tradeCoinCompositionTokenID];
        emit CompleteSaleEvent(
            _tradeCoinCompositionTokenID,
            msg.sender,
            _documents.docHashes,
            _documents.docTypes,
            _documents.rootHash
        );
    }

    function reverseSale(
        uint256 _tradeCoinCompositionTokenID,
        Documents memory _documents
    ) external nonReentrant {
        require(
            pendingSales[_tradeCoinCompositionTokenID].seller == msg.sender ||
                pendingSales[_tradeCoinCompositionTokenID].newOwner ==
                msg.sender,
            "Not the seller or new owner"
        );
        tradeCoinTokenBalance -= 1;
        IERC721(tradeCoinComposition).transferFrom(
            address(this),
            pendingSales[_tradeCoinCompositionTokenID].seller,
            _tradeCoinCompositionTokenID
        );
        if (
            pendingSales[_tradeCoinCompositionTokenID].isPayed &&
            pendingSales[_tradeCoinCompositionTokenID].priceInWei != 0
        ) {
            weiBalance -= pendingSales[_tradeCoinCompositionTokenID].priceInWei;
            payable(pendingSales[_tradeCoinCompositionTokenID].seller).transfer(
                    pendingSales[_tradeCoinCompositionTokenID].priceInWei
                );
        }
        delete pendingSales[_tradeCoinCompositionTokenID];
        emit ReverseSaleEvent(
            _tradeCoinCompositionTokenID,
            msg.sender,
            _documents.docHashes,
            _documents.docTypes,
            _documents.rootHash
        );
    }

    function servicePayment(
        uint256 _tradeCoinCompositionTokenID,
        address _receiver,
        uint256 _paymentInWei,
        bool _payInFiat,
        Documents memory _documents
    ) external payable nonReentrant {
        require(
            _documents.docHashes.length == _documents.docTypes.length &&
                (_documents.docHashes.length <= 2 ||
                    _documents.docTypes.length <= 2),
            "Invalid length"
        );

        // When not paying in Fiat pay but in Eth
        if (!_payInFiat) {
            require(
                _paymentInWei >= msg.value && _paymentInWei > 0,
                "Promised to pay in Fiat"
            );
            payable(_receiver).transfer(msg.value);
        }

        emit ServicePaymentEvent(
            _tradeCoinCompositionTokenID,
            _receiver,
            msg.sender,
            _documents.docHashes[0],
            _documents.docHashes,
            _documents.docTypes,
            _documents.rootHash,
            _paymentInWei,
            _payInFiat
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}