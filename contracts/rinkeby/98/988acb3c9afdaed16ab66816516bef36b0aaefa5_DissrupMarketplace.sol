// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./sales/Auction.sol";
import "./sales/Proposal.sol";
import "./sales/DirectSale.sol";
import "./interfaces/IAsset.sol";

contract DissrupMarketplace is Initializable, ContextUpgradeable, Auction, Proposal, DirectSale, ERC165Upgradeable {
    using ERC165CheckerUpgradeable for address;

    enum SaleType {
        Auction,
        Proposal,
        DirectSale
    }

    enum ContractTokenType {
        ERC721,
        ERC1155,
        DISSRUP
    }

    struct Listings {
        address seller;
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
        ContractTokenType contractTokenType;
        SaleType saleType;
        bool isRevealed;
        bool initialized;
    }

    bytes4 private constant IID_IERC721 = type(IERC721Upgradeable).interfaceId;
    bytes4 private constant IID_IERC1155 = type(IERC1155Upgradeable).interfaceId;
    bytes4 private constant IID_IASSET = type(IAsset).interfaceId;

    address _tempDissrupAssetAddress;
    uint256 currentListingId;

    mapping(uint256 => Listings) public listings;

    //events:
    event List(uint256 listingId,address contractAddress,uint256 tokenId,uint256 amount,ContractTokenType contractTokenType,SaleType saleType,bool isRevealed);
    event ListRemoved(uint256 listingId);
    event TransferListingToBuyer(uint256 listingId,uint256 amount,address buyer);
    event RemoveActiveSale(uint256 listingId);
    event CancelListing(uint256 listingId);

function initialize(address _dissrupAssetAddress) public initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        currentListingId++;
        _tempDissrupAssetAddress = _dissrupAssetAddress;
    }

    function transferAsset(uint256 _listingId, address _from, address _to, uint256 _amount) private {
        Listings storage listing = listings[_listingId];

        if (listing.contractTokenType == ContractTokenType.ERC721) {
            IERC721Upgradeable erc721 = IERC721Upgradeable(listing.contractAddress);
            erc721.safeTransferFrom(_from, _to, listing.tokenId);
        } else {
            IERC1155Upgradeable erc1155 = IERC1155Upgradeable(listing.contractAddress);
            erc1155.safeTransferFrom(_from,_to, listing.tokenId, _amount,"");
        }
    }

    function removeActiveSale(uint256 _listingId) private {
        Listings storage listing = listings[_listingId];
        emit RemoveActiveSale(_listingId);
        if (listing.saleType == SaleType.DirectSale) {
            closeDirectSale(_listingId);
        } else if (listing.saleType == SaleType.Proposal) {
            removeProposalSale(_listingId);
        } else {
            removeAuctionSale(_listingId);
        }
    }

    function transferListingToBuyer(uint256 _listingId, uint256 _amount, address _buyer) private {
        transferAsset(_listingId, address(this), _buyer, _amount);
        Listings storage listing = listings[_listingId];
        listing.amount -= _amount;
        if (listing.amount == 0) {
            removeActiveSale(_listingId);
            delete listings[_listingId];
            emit ListRemoved(_listingId);
        }
        emit TransferListingToBuyer(_listingId,_amount,_buyer);
    }

    function verifyContractAndGetType(address _contractAddress, uint256 _tokenId, uint256 _amount) private returns (ContractTokenType) {
        ContractTokenType contractTokenType;
        if (_isERC721(_contractAddress)) {
            require(_amount == 1, "Amount must be one if ERC721");
            IERC721Upgradeable asset721 = IERC721Upgradeable(_contractAddress);
            require(asset721.ownerOf(_tokenId) == _msgSender(),  "must be owner of the asset to list");
            contractTokenType = ContractTokenType.ERC721;
        }
        else if (_isERC1155(_contractAddress)){
            IERC1155Upgradeable asset1155 = IERC1155Upgradeable(_contractAddress);
            require(asset1155.balanceOf(_msgSender(),_tokenId) >= _amount, "not enough token to list");
            if (_isDissrupAsset(_contractAddress)) {
                contractTokenType = ContractTokenType.DISSRUP;
            } else {
                contractTokenType = ContractTokenType.ERC1155;
            }
        } else {
            require(false, "Not valid contract");
        }
        return contractTokenType;
    }

    function initSale(uint256 _listingId, SaleType _saleType, uint256 _duration, uint256 _price) private {
        if (_saleType == SaleType.DirectSale) {
            initDirectSale(_listingId, _price);
            //  event InitDirectSale(uint256 _listingId,uint256  _price);
        } else if (_saleType == SaleType.Proposal) {
            initProposal(_listingId);
            // event InitProposal(uint256 listingId);
        } else {
            initAuction(_listingId, _duration, _price);
            // event InitAuction(uint256 listingId,uint256 duration,uint256 reservePrice);
        }
    }

    function list(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _amount,
        SaleType _saleType,
        bool _isRevealed,
        uint256 _duration,
        uint256 _price
    ) public returns (bool){
        require(!AddressUpgradeable.isContract(_msgSender()), "Contracts can't list items");
        require(_amount > 0,"amount is zero!");
        // and require to _saleType

        ContractTokenType contractTokenType = verifyContractAndGetType(_contractAddress, _tokenId, _amount);
        listings[currentListingId] = Listings({
            seller: _msgSender(),
            contractAddress: _contractAddress,
            tokenId: _tokenId,
            amount: _amount,
            contractTokenType: contractTokenType,
            saleType: _saleType,
            isRevealed: _isRevealed,
            initialized: true
        });

        transferAsset(currentListingId,  _msgSender(), address(this), _amount);
        emit List(currentListingId,_contractAddress,_tokenId,_amount,contractTokenType,_saleType,_isRevealed);
        initSale(currentListingId, _saleType, _duration, _price);
        //  emit init sales
        currentListingId++;
        return true;
    }

    function buyDirectSale(uint256 _listingId, uint256 _amount) public payable returns (bool) {
        Listings storage listing = listings[_listingId];
        require (listing.initialized, "listing doesnt exist");
        require (listing.saleType == SaleType.DirectSale, "Not listed as direct sale");
        require (listing.amount >= _amount, "amount is more than supply");
        require(_msgSender() != listing.seller, "seller can't buy his asset");
        uint256 salePrice = getDirectSalePrice(_listingId);
        uint256 total = _amount * salePrice;
        require(total >= msg.value, "not enough ether to buy");

        if (msg.value > total) {
            uint256 refund = msg.value - total;
            address buyer = _msgSender();
            payable(buyer).transfer(refund);
        }
        payable(listing.seller).transfer(msg.value); // should be splitter
        transferListingToBuyer(_listingId, _amount, _msgSender());
        return true;
    }

    function propose(uint256 _listingId, uint256 _amount) public payable returns (bool) {
        Listings memory listing = listings[_listingId];
        require (listing.initialized, "listing doesnt exist");
        require(_amount > 0,"must be at least one asset");
        require(msg.value >= 100, "Price must be at least 100");
        createOrUpdatePropose(_listingId, _amount);
        // event Propose(uint256 listingId,address buyer,uint256 amount,uint256 price);
        return true;
    }

    function acceptProposal(uint256 _listingId, address _buyer) public returns(bool) {
        Listings storage listing = listings[_listingId];
        require (listing.initialized, "listing doesnt exist");
        (uint256 amount, uint price) = closeProposal(_listingId, _buyer);
        //event CloseProposal(uint256 listingId,address buyer,uint256 amount,uint256  price);
        payable(listing.seller).transfer(price); // should be splitter
        transferListingToBuyer(_listingId, amount, _buyer);
        return true;
    }


    function settleAuction(uint256 _listingId) public returns(bool) {
        Listings storage listing = listings[_listingId];
        require (listing.initialized, "listing doesnt exist");
        (address bidder, uint256 price) = closeAuction(_listingId);
        // event CloseAuction(uint256 listingId,address bidder,uint256 price);
        payable(listing.seller).transfer(price); // should be splitter

        transferListingToBuyer(_listingId, listing.amount, bidder);

        return true;
    }

    function cancelListing(uint256 _listingId) public {
        Listings memory listing = listings[_listingId];
        require (listing.initialized, "listing doesnt exist");
        require(listing.seller == _msgSender(), "Must be seller to cancel");
        emit CancelListing(_listingId);
        transferAsset(_listingId, address(this), _msgSender(), listing.amount);
        removeActiveSale(_listingId);
        delete listings[_listingId];
    }

    function _isERC1155(address _contractAddress) private view returns (bool) {
        return _contractAddress.supportsInterface(IID_IERC1155);
    }
    function _isERC721(address _contractAddress) private view returns (bool) {
        return _contractAddress.supportsInterface(IID_IERC721);
    }
    function _isDissrupAsset(address _contractAddress) private view returns (bool){
        //return _contractAddress.supportsInterface(IID_IASSET);
        return _tempDissrupAssetAddress == _contractAddress;
    }

    function onERC721Received(address _operator, address, uint256, bytes calldata) external view returns (bytes4) {
            if (_operator == address(this)) {
                return this.onERC721Received.selector;
            }
            return 0x0;
        }
    function onERC1155Received(address _operator, address, uint256, uint256, bytes calldata) external view returns (bytes4) {
            if (_operator == address(this)) {
                return this.onERC1155Received.selector;
            }
            return 0x0;
        }
    function onERC1155BatchReceived(address _operator, address, uint256[] calldata, uint256[] calldata, bytes calldata) external view returns (bytes4) {
            if (_operator == address(this)) {
                return this.onERC1155BatchReceived.selector;
            }

            return 0x0;
        }

    function supportsInterface(bytes4 interfaceId) public view virtual override ( ERC165Upgradeable ) returns (bool){
            return super.supportsInterface(interfaceId);
        }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract Auction is ContextUpgradeable {

    uint256 private constant EXTENSION_DURATION = 15 minutes;



    struct Auction {
        uint256 duration;
        uint256 extensionDuration;
        uint256 endTime;
        address bidder;
        uint256 currentBid;
        uint256 reservePrice;
        bool initialized;
    }

    mapping(uint256 => Auction) public auctions;
    event InitAuction(uint256 listingId,uint256 duration,uint256 reservePrice);
    event CloseAuction(uint256 listingId,address bidder,uint256 price);

    function getMinBidAmountForReserveAuction(uint256 currentBidAmount) internal pure returns (uint256) {
        uint256 minIncrement = currentBidAmount / 10;

        if (minIncrement < (0.1 ether)) {
            // The next bid must be at least 0.1 ether greater than the current.
            return currentBidAmount + (0.1 ether);
        }

        return (currentBidAmount + minIncrement);
    }


    function closeAuction(uint256 _listingId) public returns (address bidder_, uint256 price_) {
        Auction storage auction = auctions[_listingId];
        require(auction.initialized, "auction doest exists");
        require(auction.endTime > 0, "Auction was already settled");
        require(auction.endTime < block.timestamp, "Auction still in progress");
        uint256 price = auction.currentBid;
        address bidder = auction.bidder;
        delete auctions[_listingId];
        emit CloseAuction(_listingId,bidder,price);
        return (bidder, price);
    }

    function getEndTimeForReserveAuction(uint256 _listingId) public view returns (uint256) {
        Auction memory auction = auctions[_listingId];
        require(auction.initialized, "Auction not found");
        return auction.endTime;
    }

    function isAuctionEnded(uint256 _listingId) public view returns (bool) {
        Auction memory auction = auctions[_listingId];

        require(auction.initialized, "Auction not found");

        return (auction.endTime > 0) && (auction.endTime < block.timestamp);
    }

    function getMinBidAmount(uint256 _listingId) public view returns (uint256) {
        Auction memory auction = auctions[_listingId];

        if (auction.endTime == 0) {
            return auction.currentBid;
        }

        return getMinBidAmountForReserveAuction(auction.currentBid);
    }

    function removeAuctionSale(uint256 _listingId) internal {
        Auction storage auction = auctions[_listingId];
        require(auction.initialized , "auction doest exists");
        if (auction.endTime > 0) {
            uint256 price = auction.currentBid;
            address bidder = auction.bidder;
            payable(bidder).transfer(price);
        }
        delete auctions[_listingId];
    }

    function bid(uint256 _listingId) payable public {
        Auction storage auction = auctions[_listingId];
        require(auction.initialized, "auction doest exists");
        if (auction.endTime == 0) {
            require(msg.value >= auction.reservePrice, "Bid must be at least the reserve price");
            auction.currentBid = msg.value;
            auction.bidder = _msgSender();
            // On the first bid, the endTime is now + duration
            auction.endTime = block.timestamp + auction.duration;
        } else {
            require(auction.endTime >= block.timestamp, "Auction is over");
            require(auction.bidder != _msgSender(), "You already have an outstanding bid");
            uint256 minAmount = getMinBidAmountForReserveAuction(auction.currentBid);
            require(msg.value >= minAmount, "Bid currentBid too low");

            uint256 oldBid = auction.currentBid;
            address oldBidder = auction.bidder;

            auction.currentBid = msg.value;
            auction.bidder = _msgSender();

            // When a bid outbids another, check to see if a time extension should apply.
            if (auction.endTime - block.timestamp < auction.extensionDuration) {
                auction.endTime = block.timestamp + auction.extensionDuration;
            }
            payable(oldBidder).transfer(oldBid);
        }
    }

    function initAuction(uint256 _listingId, uint256 _duration, uint256 _reservePrice) internal {

        // requires

        auctions[_listingId] = Auction({
        duration: _duration,
        extensionDuration: EXTENSION_DURATION,
        endTime: 0, // endTime is only known once the reserve price is met
        bidder: address(0),
        currentBid: 0, // bidder is only known once a bid has been placed
         reservePrice: _reservePrice,
        initialized: true
        });
        emit InitAuction(_listingId,_duration,  _reservePrice);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract Proposal is ContextUpgradeable {

    struct Proposal {
        uint256 price;
        uint256 amount;
        bool initialized;
    }


    mapping(uint256 => mapping(address => Proposal)) public proposals;
    event InitProposal(uint256 listingId);
    event RemoveProposalSale(uint256 listingId);
    event Propose(uint256 listingId,address buyer,uint256 amount,uint256 price);
    event CloseProposal(uint256 listingId,address buyer,uint256 amount,uint256  price);

    function initProposal(uint256 _listingId) internal {
        emit InitProposal( _listingId);
    }

    function removeProposalSale(uint256 _listingId) internal {
        emit RemoveProposalSale(_listingId);
    }

    function closeProposal(uint256 _listingId, address buyer) internal returns(uint256 amount, uint256 price) {
        Proposal storage proposal =  proposals[_listingId][buyer];
        require (proposal.initialized, "proposal doesnt exist");
        uint256 amount = proposal.amount;
        uint256 price = proposal.price;
        delete proposals[_listingId][buyer];
        emit CloseProposal(_listingId,buyer,amount,price);
        return (amount, price);
    }

    function cancelPropose(uint256 _listingId) public {
        Proposal storage proposal =  proposals[_listingId][_msgSender()];
        require (proposal.initialized, "proposal doesnt exist");
        payable(_msgSender()).transfer(proposal.price);
        delete proposals[_listingId][_msgSender()];
    }

    function createOrUpdatePropose(uint256 _listingId, uint256 _amount) internal {
        Proposal storage proposal =  proposals[_listingId][_msgSender()];
        require(proposal.initialized, "proposal doesnt exist");
        if (proposal.amount != 0) {
            payable(_msgSender()).transfer(proposal.price);
        }
        proposals[_listingId][_msgSender()] = Proposal({
            price: msg.value,
            amount: _amount,
            initialized: true
        });
        emit Propose(_listingId,_msgSender(),_amount,msg.value);
    }



}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract DirectSale {

    struct DirectSaleList {
        uint256 price;
        bool initialized;
    }

    mapping(uint256 => DirectSaleList) public directSales;
    event InitDirectSale(uint256 listingId,uint256  price);
    event CloseDirectSale(uint256 listingId,uint256 price);

    function initDirectSale (uint256 _listingId, uint256 _price) internal {
        directSales[_listingId] = DirectSaleList({
            price: _price,
            initialized: true
        });
        emit InitDirectSale(_listingId,_price);
    }

    function getDirectSalePrice(uint256 _listingId) internal returns(uint256) {
        DirectSaleList memory listing = directSales[_listingId];
        require(listing.initialized,"Not valid Sale");
        return listing.price;
    }

    function closeDirectSale(uint256 _listingId) internal {
        DirectSaleList memory listing = directSales[_listingId];
        uint256 price = listing.price;
        require(listing.initialized,"Not valid Sale");
        delete directSales[_listingId];
        emit CloseDirectSale(_listingId, price);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IAsset is IERC1155 {
    function creator(uint256 _assetId) external view returns (address);
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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