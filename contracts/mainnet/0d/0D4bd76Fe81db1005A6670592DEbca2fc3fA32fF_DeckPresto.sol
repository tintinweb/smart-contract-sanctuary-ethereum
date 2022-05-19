/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// File: @openzeppelin\contracts\utils\introspection\IERC165.sol

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

// File: @openzeppelin\contracts\token\ERC1155\IERC1155Receiver.sol

// SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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

// File: @openzeppelin\contracts\token\ERC721\IERC721Receiver.sol

// SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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

// File: @openzeppelin\contracts\token\ERC1155\IERC1155.sol

// SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

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

// File: contracts\model\IERC1155Views.sol

// SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @title IERC1155Views - An optional utility interface to improve the ERC-1155 Standard.
 * @dev This interface introduces some additional capabilities for ERC-1155 Tokens.
 */
interface IERC1155Views {

    /**
     * @dev Returns the total supply of the given token id
     * @param itemId the id of the token whose availability you want to know 
     */
    function totalSupply(uint256 itemId) external view returns (uint256);

    /**
     * @dev Returns the name of the given token id
     * @param itemId the id of the token whose name you want to know 
     */
    function name(uint256 itemId) external view returns (string memory);

    /**
     * @dev Returns the symbol of the given token id
     * @param itemId the id of the token whose symbol you want to know 
     */
    function symbol(uint256 itemId) external view returns (string memory);

    /**
     * @dev Returns the decimals of the given token id
     * @param itemId the id of the token whose decimals you want to know 
     */
    function decimals(uint256 itemId) external view returns (uint256);

    /**
     * @dev Returns the uri of the given token id
     * @param itemId the id of the token whose uri you want to know 
     */
    function uri(uint256 itemId) external view returns (string memory);
}

// File: contracts\model\Item.sol

//SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;
pragma abicoder v2;


struct Header {
    address host;
    string name;
    string symbol;
    string uri;
}

struct CreateItem {
    Header header;
    bytes32 collectionId;
    uint256 id;
    address[] accounts;
    uint256[] amounts;
}

interface Item is IERC1155, IERC1155Views {

    event CollectionItem(bytes32 indexed fromCollectionId, bytes32 indexed toCollectionId, uint256 indexed itemId);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint256);

    function burn(address account, uint256 itemId, uint256 amount) external;
    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts) external;

    function burn(address account, uint256 itemId, uint256 amount, bytes calldata data) external;
    function burnBatch(address account, uint256[] calldata itemIds, uint256[] calldata amounts, bytes calldata data) external;

    function mintItems(CreateItem[] calldata items) external returns(uint256[] memory itemIds);
    function setItemsCollection(uint256[] calldata itemIds, bytes32[] calldata collectionIds) external returns(bytes32[] memory oldCollectionIds);
    function setItemsMetadata(uint256[] calldata itemIds, Header[] calldata newValues) external returns(Header[] memory oldValues);

    function interoperableOf(uint256 itemId) external view returns(address);
}

// File: contracts\projection\deckPresto\IDeckPresto.sol

//SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;
interface IDeckPresto is IERC721Receiver, IERC1155Receiver {

    function data() external view returns(address prestoAddress, address erc721DeckWrapper, address erc1155DeckWrapper);

    function buyAndUnwrap(PrestoOperation calldata operation, bool isERC721, bytes[] calldata payload) external payable returns(uint256 outputAmount);

    function wrapAndSell721(address tokenAddress, uint256[] calldata tokenIds, bool[] calldata reserve, PrestoOperation[] calldata operations) external returns(uint256[] memory outputAmounts);
}

struct PrestoOperation {

    address inputTokenAddress;
    uint256 inputTokenAmount;

    address ammPlugin;
    address[] liquidityPoolAddresses;
    address[] swapPath;
    bool enterInETH;
    bool exitInETH;

    uint256[] tokenMins;

    address[] receivers;
    uint256[] receiversPercentages;
}

interface IPrestoUniV3 {

    function execute(PrestoOperation[] memory operations) external payable returns(uint256[] memory outputAmounts);
}

// File: @openzeppelin\contracts\token\ERC721\IERC721.sol

// SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @ethereansos\swissknife\contracts\generic\model\ILazyInitCapableElement.sol

// SPDX_License_Identifier: MIT
pragma solidity >=0.7.0;

interface ILazyInitCapableElement is IERC165 {

    function lazyInit(bytes calldata lazyInitData) external returns(bytes memory initResponse);
    function initializer() external view returns(address);

    event Host(address indexed from, address indexed to);

    function host() external view returns(address);
    function setHost(address newValue) external returns(address oldValue);

    function subjectIsAuthorizedFor(address subject, address location, bytes4 selector, bytes calldata payload, uint256 value) external view returns(bool);
}

// File: contracts\projection\IItemProjection.sol

//SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;
//pragma abicoder v2;


interface IItemProjection is Item, ILazyInitCapableElement {

    function mainInterface() external view returns(address);

    function collectionId() external view returns(bytes32);
    function uri() external view returns(string memory);
    function plainUri() external view returns(string memory);
    function itemPlainUri(uint256 itemId) external view returns(string memory);
    function setHeader(Header calldata value) external returns(Header memory oldValue);

    function toInteroperableInterfaceAmount(uint256 amount, uint256 itemId, address account) external view returns(uint256);
    function toMainInterfaceAmount(uint256 amount, uint256 itemId) external view returns(uint256);
}

// File: contracts\projection\ERC721Deck\IERC721DeckWrapper.sol

//SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;
//pragma abicoder v2;

interface IERC721DeckWrapper is IItemProjection {

    function reserveTimeInBlocks() external view returns(uint256);

    function reserveData(address tokenAddress, uint256 tokenId) external view returns(address unwrapper, uint256 timeout);

    function unlockReserves(address[] calldata tokenAddresses, uint256[] calldata tokenIds) external;

    function mintItems(CreateItem[] calldata createItemsInput, bool[] calldata reserveArray) external returns(uint256[] memory itemIds);

    event Token(address indexed tokenAddress, uint256 indexed tokenId, uint256 indexed itemId);

    function itemIdOf(address tokenAddress) external view returns(uint256);

    function source(uint256 itemId) external view returns(address tokenAddress);
}

// File: contracts\projection\ERC1155Deck\IERC1155DeckWrapper.sol

//SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;
//pragma abicoder v2;

interface IERC1155DeckWrapper is IItemProjection {

    function reserveTimeInBlocks() external view returns(uint256);

    function reserveData(bytes32 reserveDataKey) external view returns(address unwrapper, uint256 timeout, uint256 amount);

    event ReserveData(address from, address indexed tokenAddress, uint256 indexed tokenId, uint256 amount, uint256 timeout, bytes32 indexed reserveDataKey);

    event ReserveDataUnlocked(address indexed from, bytes32 indexed reserveDataKey, address tokenAddress, uint256 tokenId, address unwrapper, uint256 amount, uint256 timeout);

    function unlockReserves(address[] calldata owners, address[] calldata tokenAddresses, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    function mintItems(CreateItem[] calldata createItemsInput, bool[] calldata reserveArray) external returns(uint256[] memory itemIds);

    event Token(address indexed tokenAddress, uint256 indexed tokenId, uint256 indexed itemId);

    function itemIdOf(address tokenAddress, uint256 tokenId) external view returns(uint256);

    function source(uint256 itemId) external view returns(address tokenAddress, bytes32 tokenKey);
}

// File: contracts\projection\deckPresto\DeckPresto.sol

//SPDX_License_Identifier: MIT

pragma solidity >=0.7.0;






contract DeckPresto is IDeckPresto {

    address private immutable _prestoAddress;
    address private immutable _erc721DeckWrapper;
    address private immutable _erc1155DeckWrapper;

    constructor(address prestoAddress, address erc721DeckWrapper, address erc1155DeckWrapper) {
        _prestoAddress = prestoAddress;
        _erc721DeckWrapper = erc721DeckWrapper;
        _erc1155DeckWrapper = erc1155DeckWrapper;
    }

    function supportsInterface(bytes4) external override pure returns (bool) {
        return true;
    }

    function data() external override view returns(address prestoAddress, address erc721DeckWrapper, address erc1155DeckWrapper) {
        prestoAddress = _prestoAddress;
        erc721DeckWrapper = _erc721DeckWrapper;
        erc1155DeckWrapper = _erc1155DeckWrapper;
    }

    function buyAndUnwrap(PrestoOperation calldata operation, bool isERC721, bytes[] calldata payload) external override payable returns(uint256 outputAmount) {
        uint256 itemId = uint160(operation.swapPath[operation.swapPath.length - 1]);
        require(operation.ammPlugin != address(0), "amm");
        require(operation.liquidityPoolAddresses.length > 0, "amm");

        PrestoOperation[] memory operations = new PrestoOperation[](1);
        operations[0] = PrestoOperation({
            inputTokenAddress : address(0),
            inputTokenAmount : msg.value,
            ammPlugin : operation.ammPlugin,
            liquidityPoolAddresses : operation.liquidityPoolAddresses,
            swapPath : operation.swapPath,
            enterInETH : true,
            exitInETH : false,
            tokenMins : operation.tokenMins,
            receivers : _asSingleArray(address(this)),
            receiversPercentages : new uint256[](0)
        });
        outputAmount = IPrestoUniV3(_prestoAddress).execute{value : msg.value}(operations)[0];
        require(operations[0].tokenMins.length == 0 || outputAmount >= operations[0].tokenMins[0], "slippage");

        uint256[] memory itemIds = new uint256[](payload.length);
        uint256[] memory outputAmounts = new uint256[](payload.length);

        for(uint256 i = 0; i < itemIds.length; i++) {
            itemIds[i] = itemId;
            outputAmounts[i] = outputAmount >= 1e18 ? 1e18 : outputAmount;
        }

        Item(isERC721 ? _erc721DeckWrapper : _erc1155DeckWrapper).burnBatch(address(this), itemIds, outputAmounts, abi.encode(payload));

        uint256 balance = address(this).balance;
        if(balance > 0) {
            payable(msg.sender).transfer(balance);
        }
        IERC20 token = IERC20(address(uint160(itemId)));
        balance = token.balanceOf(address(this));
        if(balance > 0) {
            token.transfer(msg.sender, balance);
        }
    }

    function wrapAndSell721(address tokenAddress, uint256[] calldata tokenIds, bool[] memory reserve, PrestoOperation[] calldata operations) external override returns(uint256[] memory outputAmounts) {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(tokenAddress).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }
        return _wrapAndSell721(msg.sender, tokenAddress, tokenIds, reserve, operations, false);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata payload
    ) external override returns (bytes4) {
        if(operator == address(this)) {
            return this.onERC721Received.selector;
        }
        (bool[] memory reserve, PrestoOperation[] memory operations, bool simulation) = abi.decode(payload, (bool[], PrestoOperation[], bool));
        _wrapAndSell721(from, msg.sender, _asSingleArray(tokenId), reserve, operations, simulation);
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata payload
    ) external override returns (bytes4) {
        _wrapAndSell1155(from, msg.sender, _asSingleArray(id), _asSingleArray(value), payload);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata payload
    ) external override returns (bytes4) {
        _wrapAndSell1155(from, msg.sender, ids, values, payload);
        return this.onERC1155BatchReceived.selector;
    }

    function _wrapAndSell721(address from, address tokenAddress, uint256[] memory tokenIds, bool[] memory reserve, PrestoOperation[] memory operations, bool simulation) private returns(uint256[] memory outputAmounts) {
        IERC721(tokenAddress).setApprovalForAll(_erc721DeckWrapper, true);
        CreateItem[] memory createItems;
        uint256 itemId = IERC721DeckWrapper(_erc721DeckWrapper).itemIdOf(tokenAddress);
        (operations, createItems) = _prepareWrapAndSell(tokenAddress, tokenIds, operations, itemId);
        IERC721DeckWrapper(_erc721DeckWrapper).mintItems(createItems, reserve);
        outputAmounts = _sellAfterWrap(from, itemId, operations, simulation);
    }

    function _wrapAndSell1155(address from, address tokenAddress, uint256[] memory tokenIds, uint256[] memory values, bytes memory payload) private returns(uint256[] memory outputAmounts) {
        (bool[] memory reserve, PrestoOperation[] memory operations, bool simulation) = abi.decode(payload, (bool[], PrestoOperation[], bool));
        uint256 itemId = IERC1155DeckWrapper(_erc1155DeckWrapper).itemIdOf(tokenAddress, tokenIds[0]);
        (operations,) = _prepareWrapAndSell(tokenAddress, tokenIds, operations, itemId);
        bytes[] memory arr = new bytes[](tokenIds.length);
        for(uint256 i = 0; i < arr.length; i++) {
            arr[i] = abi.encode(_asSingleArray(values[i]), new address[](0), i < reserve.length ? reserve[i] : false);
        }
        IERC1155(tokenAddress).safeBatchTransferFrom(address(this), _erc1155DeckWrapper, tokenIds, values, abi.encode(arr));
        outputAmounts = _sellAfterWrap(from, itemId, operations, simulation);
    }

    function _prepareWrapAndSell(address tokenAddress, uint256[] memory tokenIds, PrestoOperation[] memory operations, uint256 itemId) private view returns(PrestoOperation[] memory elaboratedOperations, CreateItem[] memory createItems) {
        require(tokenAddress != address(0) && tokenIds.length > 0 && operations.length == tokenIds.length && itemId != 0, "invalid input");
        elaboratedOperations = new PrestoOperation[](1);
        elaboratedOperations[0] = operations[0];
        createItems = new CreateItem[](tokenIds.length);
        uint256 totalAmount = 0;
        uint256 tokenMins = 0;
        address[] memory receiver = _asSingleArray(address(this));
        require(elaboratedOperations[0].ammPlugin != address(0), "amm");
        require(elaboratedOperations[0].liquidityPoolAddresses.length > 0, "amm");
        elaboratedOperations[0].inputTokenAddress = address(uint160(itemId));
        elaboratedOperations[0].swapPath[elaboratedOperations[0].swapPath.length - 1] = address(0);
        elaboratedOperations[0].enterInETH = false;
        elaboratedOperations[0].exitInETH = true;
        for(uint256 i = 0; i < tokenIds.length; i++) {
            require(operations[i].inputTokenAmount > 0, "amount");
            totalAmount += operations[i].inputTokenAmount;
            tokenMins += operations[i].tokenMins[0];
            createItems[i] = CreateItem(Header(address(0), "", "", ""), bytes32(uint256(uint160(tokenAddress))), tokenIds[i], receiver, _asSingleArray(operations[i].inputTokenAmount));
        }
        require(totalAmount > 0, "amount");
        elaboratedOperations[0].inputTokenAmount = totalAmount;
        elaboratedOperations[0].tokenMins = _asSingleArray(tokenMins);
    }

    function _sellAfterWrap(address from, uint256 itemId, PrestoOperation[] memory operations, bool simulation) private returns(uint256[] memory outputAmounts) {
        IERC20 token = IERC20(address(uint160(itemId)));
        token.approve(_prestoAddress, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        outputAmounts = IPrestoUniV3(_prestoAddress).execute(operations);
        for(uint256 i = 0; i < outputAmounts.length; i++) {
            require(operations[i].tokenMins.length == 0 || outputAmounts[i] >= operations[i].tokenMins[0], "slippage");
        }
        uint256 postBalance = token.balanceOf(address(this));
        if(postBalance > 0) {
            token.transfer(from, postBalance);
        }
        if(simulation) {
            revert(string(abi.encode(outputAmounts)));
        }
    }

    function _asSingleArray(address addr) private pure returns(address[] memory arr) {
        arr = new address[](1);
        arr[0] = addr;
    }

    function _asSingleArray(uint256 num) private pure returns(uint256[] memory arr) {
        arr = new uint256[](1);
        arr[0] = num;
    }
}