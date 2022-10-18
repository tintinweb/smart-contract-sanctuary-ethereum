// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./NftCheck.sol";
import "../interfaces/ICryptoPunks.sol";

library AelinNftGating {
    address constant CRYPTO_PUNKS = address(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);

    // collectionAddress should be unique, otherwise will override
    struct NftCollectionRules {
        // if 0, then unlimited purchase
        uint256 purchaseAmount;
        address collectionAddress;
        // if true, then `purchaseAmount` is per token
        // else `purchaseAmount` is per account regardless of the NFTs held
        bool purchaseAmountPerToken;
        // both variables below are only applicable for 1155
        uint256[] tokenIds;
        // min number of tokens required for participating
        uint256[] minTokensEligible;
    }

    struct NftGatingData {
        mapping(address => NftCollectionRules) nftCollectionDetails;
        mapping(address => mapping(address => bool)) nftWalletUsedForPurchase;
        mapping(address => mapping(uint256 => bool)) nftId;
        bool hasNftList;
    }

    struct NftPurchaseList {
        address collectionAddress;
        uint256[] tokenIds;
    }

    /**
     * @dev check if deal is nft gated, sets hasNftList
     * if yes, move collection rule array input to mapping in the data storage
     * @param _nftCollectionRules array of all nft collection rule data
     * @param _data contract storage data passed by reference
     */
    function initialize(NftCollectionRules[] calldata _nftCollectionRules, NftGatingData storage _data) external {
        if (_nftCollectionRules.length > 0) {
            // if the first address supports punks or 721, the entire pool only supports 721 or punks
            if (
                _nftCollectionRules[0].collectionAddress == CRYPTO_PUNKS ||
                NftCheck.supports721(_nftCollectionRules[0].collectionAddress)
            ) {
                for (uint256 i; i < _nftCollectionRules.length; ++i) {
                    require(
                        _nftCollectionRules[i].collectionAddress == CRYPTO_PUNKS ||
                            NftCheck.supports721(_nftCollectionRules[i].collectionAddress),
                        "can only contain 721"
                    );
                    _data.nftCollectionDetails[_nftCollectionRules[i].collectionAddress] = _nftCollectionRules[i];
                    emit PoolWith721(
                        _nftCollectionRules[i].collectionAddress,
                        _nftCollectionRules[i].purchaseAmount,
                        _nftCollectionRules[i].purchaseAmountPerToken
                    );
                }
                _data.hasNftList = true;
            }
            // if the first address supports 1155, the entire pool only supports 1155
            else if (NftCheck.supports1155(_nftCollectionRules[0].collectionAddress)) {
                for (uint256 i; i < _nftCollectionRules.length; ++i) {
                    require(NftCheck.supports1155(_nftCollectionRules[i].collectionAddress), "can only contain 1155");
                    _data.nftCollectionDetails[_nftCollectionRules[i].collectionAddress] = _nftCollectionRules[i];

                    for (uint256 j; j < _nftCollectionRules[i].tokenIds.length; ++j) {
                        _data.nftId[_nftCollectionRules[i].collectionAddress][_nftCollectionRules[i].tokenIds[j]] = true;
                    }
                    emit PoolWith1155(
                        _nftCollectionRules[i].collectionAddress,
                        _nftCollectionRules[i].purchaseAmount,
                        _nftCollectionRules[i].purchaseAmountPerToken,
                        _nftCollectionRules[i].tokenIds,
                        _nftCollectionRules[i].minTokensEligible
                    );
                }
                _data.hasNftList = true;
            } else {
                require(false, "collection is not compatible");
            }
        } else {
            _data.hasNftList = false;
        }
    }

    /**
     * @dev allows anyone to become a purchaser with a qualified erc721
     * nft in the pool depending on the scenarios
     *
     * Scenarios:
     * 1. each wallet holding a qualified NFT to deposit an unlimited amount of purchase tokens
     * 2. certain amount of purchase tokens per wallet regardless of the number of qualified NFTs held
     * 3. certain amount of Investment tokens per qualified NFT held
     * @param _nftPurchaseList nft collection address and token ids to use for purchase
     * @param _data contract storage data for nft gating passed by reference
     * @param _purchaseTokenAmount amount to purchase with, must not exceed max allowable from collection rules
     * @return uint256 max purchase token amount allowable
     */
    function purchaseDealTokensWithNft(
        NftPurchaseList[] calldata _nftPurchaseList,
        NftGatingData storage _data,
        uint256 _purchaseTokenAmount
    ) external returns (uint256) {
        require(_data.hasNftList, "pool does not have an NFT list");
        require(_nftPurchaseList.length > 0, "must provide purchase list");

        uint256 maxPurchaseTokenAmount;

        for (uint256 i; i < _nftPurchaseList.length; ++i) {
            NftPurchaseList memory nftPurchaseList = _nftPurchaseList[i];
            address _collectionAddress = nftPurchaseList.collectionAddress;
            uint256[] memory _tokenIds = nftPurchaseList.tokenIds;

            NftCollectionRules memory nftCollectionRules = _data.nftCollectionDetails[_collectionAddress];
            require(nftCollectionRules.collectionAddress == _collectionAddress, "collection not in the pool");

            if (nftCollectionRules.purchaseAmountPerToken && nftCollectionRules.purchaseAmount > 0) {
                if (NftCheck.supports1155(_collectionAddress)) {
                    for (uint256 j; j < _tokenIds.length; ++j) {
                        unchecked {
                            uint256 collectionAllowance = nftCollectionRules.purchaseAmount *
                                IERC1155(_collectionAddress).balanceOf(msg.sender, _tokenIds[j]);
                            // if there is an overflow of the pervious calculation, allow the max purchase token amount
                            if (
                                collectionAllowance / nftCollectionRules.purchaseAmount !=
                                IERC1155(_collectionAddress).balanceOf(msg.sender, _tokenIds[j])
                            ) {
                                maxPurchaseTokenAmount = type(uint256).max;
                            } else {
                                maxPurchaseTokenAmount += collectionAllowance;
                                if (maxPurchaseTokenAmount < collectionAllowance) {
                                    maxPurchaseTokenAmount = type(uint256).max;
                                }
                            }
                        }
                    }
                } else {
                    unchecked {
                        uint256 collectionAllowance = nftCollectionRules.purchaseAmount * _tokenIds.length;
                        // if there is an overflow of the pervious calculation, allow the max purchase token amount
                        if (collectionAllowance / nftCollectionRules.purchaseAmount != _tokenIds.length) {
                            maxPurchaseTokenAmount = type(uint256).max;
                        } else {
                            maxPurchaseTokenAmount += collectionAllowance;
                            if (maxPurchaseTokenAmount < collectionAllowance) {
                                maxPurchaseTokenAmount = type(uint256).max;
                            }
                        }
                    }
                }
            }

            if (!nftCollectionRules.purchaseAmountPerToken && nftCollectionRules.purchaseAmount > 0) {
                require(!_data.nftWalletUsedForPurchase[_collectionAddress][msg.sender], "wallet already used for nft set");
                _data.nftWalletUsedForPurchase[_collectionAddress][msg.sender] = true;
                unchecked {
                    maxPurchaseTokenAmount += nftCollectionRules.purchaseAmount;
                    // if addition causes overflow the max allowance is max value of uint256
                    if (maxPurchaseTokenAmount < nftCollectionRules.purchaseAmount) {
                        maxPurchaseTokenAmount = type(uint256).max;
                    }
                }
            }

            if (nftCollectionRules.purchaseAmount == 0) {
                maxPurchaseTokenAmount = type(uint256).max;
            }

            if (NftCheck.supports721(_collectionAddress)) {
                for (uint256 j; j < _tokenIds.length; ++j) {
                    require(IERC721(_collectionAddress).ownerOf(_tokenIds[j]) == msg.sender, "has to be the token owner");
                    require(!_data.nftId[_collectionAddress][_tokenIds[j]], "tokenId already used");
                    _data.nftId[_collectionAddress][_tokenIds[j]] = true;
                    emit BlacklistNFT(_collectionAddress, _tokenIds[j]);
                }
            }
            if (NftCheck.supports1155(_collectionAddress)) {
                for (uint256 j; j < _tokenIds.length; ++j) {
                    require(_data.nftId[_collectionAddress][_tokenIds[j]], "tokenId not in the pool");
                    require(
                        IERC1155(_collectionAddress).balanceOf(msg.sender, _tokenIds[j]) >=
                            nftCollectionRules.minTokensEligible[j],
                        "erc1155 balance too low"
                    );
                }
            }
            if (_collectionAddress == CRYPTO_PUNKS) {
                for (uint256 j; j < _tokenIds.length; ++j) {
                    require(
                        ICryptoPunks(_collectionAddress).punkIndexToAddress(_tokenIds[j]) == msg.sender,
                        "not the owner"
                    );
                    require(!_data.nftId[_collectionAddress][_tokenIds[j]], "tokenId already used");
                    _data.nftId[_collectionAddress][_tokenIds[j]] = true;
                    emit BlacklistNFT(_collectionAddress, _tokenIds[j]);
                }
            }
        }

        require(_purchaseTokenAmount <= maxPurchaseTokenAmount, "purchase amount greater than max allocation");

        return (maxPurchaseTokenAmount);
    }

    event PoolWith721(address indexed collectionAddress, uint256 purchaseAmount, bool purchaseAmountPerToken);

    event PoolWith1155(
        address indexed collectionAddress,
        uint256 purchaseAmount,
        bool purchaseAmountPerToken,
        uint256[] tokenIds,
        uint256[] minTokensEligible
    );
    event BlacklistNFT(address indexed collection, uint256 nftID);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library NftCheck {
    bytes4 public constant IERC165_ID = type(IERC165).interfaceId;
    bytes4 public constant IERC1155_ID = type(IERC1155).interfaceId;
    bytes4 public constant IERC721_ID = type(IERC721).interfaceId;

    function supports721(address collectionAddress) internal view returns (bool) {
        return _supportsInterface(collectionAddress, IERC721_ID);
    }

    function supports1155(address collectionAddress) internal view returns (bool) {
        return _supportsInterface(collectionAddress, IERC1155_ID);
    }

    function _supportsInterface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

interface ICryptoPunks {
    function balanceOf(address) external view returns (uint256);

    function punkIndexToAddress(uint256) external view returns (address);
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