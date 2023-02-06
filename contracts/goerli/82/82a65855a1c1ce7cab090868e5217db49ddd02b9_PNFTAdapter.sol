/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: tests/pnft/adapter.sol


pragma solidity ^0.8.0;



    enum Side { Buy, Sell }
    enum SignatureVersion { Single, Bulk }
    enum AssetType { ERC721, ERC1155 }

    struct Fee {
        uint16 rate;
        address payable recipient;
    }

    struct Order {
        address trader;
        Side side;
        address matchingPolicy;
        address collection; // token address
        uint256 tokenId; // identifier
        uint256 amount;
        address paymentToken;
        uint256 price;
        uint256 listingTime;
        /* Order expiration timestamp - 0 for oracle cancellations. */
        uint256 expirationTime;
        Fee[] fees;
        uint256 salt;
        bytes extraParams;
    }

    struct Input {
        Order order;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes extraSignature;
        SignatureVersion signatureVersion;
        uint256 blockNumber;
    }

    struct Execution {
        Input sell;
        Input buy;
    }

    struct OpenseaTrades {
        uint256 value;
        bytes tradeData;
    }

    struct ERC20Details {
        address[] tokenAddrs;
        uint256[] amounts;
    }

    struct ERC1155Details {
        address tokenAddr;
        uint256[] ids;
        uint256[] amounts;
    }

    struct ConverstionDetails {
        bytes conversionData;
    }

    struct AffiliateDetails {
        address affiliate;
        bool isActive;
    }

    struct SponsoredMarket {
        uint256 marketId;
        bool isActive;
    }

    struct TradeDetails {
        uint256 marketId;
        uint256 value;
        bytes tradeData;
    }

    struct Market {
        address proxy;
        bool isLib;
        bool isActive;
    }

    struct TokenInfo {
        AssetType tokenType;
        address collection;
        uint256 identifier;
        uint256 amount;
    }

interface IERC721 {
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
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155 {
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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

interface IMatchingPolicy {
    function canMatchMakerAsk(Order calldata makerAsk, Order calldata takerBid)
    external
    view
    returns (
        bool,
        uint256,
        uint256,
        uint256,
        AssetType
    );

    function canMatchMakerBid(Order calldata makerBid, Order calldata takerAsk)
    external
    view
    returns (
        bool,
        uint256,
        uint256,
        uint256,
        AssetType
    );
}

interface IBlur {
    function batchBuyWithETH(
        TradeDetails[] memory tradeDetails
    ) payable external;

    function batchBuyWithERC20s(
        ERC20Details memory erc20Details,
        TradeDetails[] memory tradeDetails,
        ConverstionDetails[] memory converstionDetails,
        address[] memory dustTokens
    ) payable external;

    function execute(Input calldata sell, Input calldata buy) external payable;

    function bulkExecute(Execution[] calldata executions) external payable;
}

contract PNFTAdapter {

    enum PNFTMarket {
        pNFT,
        OpenSea
    }

    IBlur constant public blur1 = IBlur(0x87E5Ffa37503487691c75359401080B1e2FBdE5E);
    address constant public opensea = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

    function execute(Input calldata sell, Input calldata buy, address recipient) external payable returns(address, uint) {
        blur1.execute{value: msg.value}(sell, buy);
        _processExecute(sell.order, buy.order, recipient);

        return (address(0x4cB607c24Ac252A0cE4b2e987eC4413dA0F1e3Ae), 0);
    }

    function bulkExecute(Execution[] calldata executions, address recipient) external payable returns(address, uint) {
        blur1.bulkExecute{value: msg.value}(executions);
        for (uint i = 0; i < executions.length; i++) {
            Execution memory temp = executions[i];
            _processExecute(temp.sell.order, temp.buy.order, recipient);
        }

        return (address(0x4cB607c24Ac252A0cE4b2e987eC4413dA0F1e3Ae), 0);
    }

    function buyBatchETH(PNFTMarket[] calldata _markets, bytes[] calldata messages) external payable returns(address, uint) {
        require(_markets.length == messages.length, "Adapter: invalid input data");
        address callee;
        for (uint i = 0; i < _markets.length; i++) {
            if (_markets[i] == PNFTMarket.OpenSea) {
                callee = opensea;
            } else {
                callee = address(this);
            }
            (bool success, ) = callee.call{value: address(this).balance}(messages[i]);
            require(success, "Adapter: request to market failed");
        }
        require(address(this).balance == 0, "Adapter: balance after execute must be zero");

        return (address(0x4cB607c24Ac252A0cE4b2e987eC4413dA0F1e3Ae), 0);
    }

    function _processExecute(Order memory sell, Order memory buy, address recipient) internal {
        (uint256 tokenId, uint256 amount, AssetType assetType) = _getAssetType(sell, buy);
        _transferNFT(assetType, recipient, sell.collection, tokenId, amount);
    }

    function _transferNFT(AssetType assetType, address to, address token, uint256 identifier, uint256 amount) internal {
        if (assetType == AssetType.ERC721) {
            IERC721(token).transferFrom(address(this), to, identifier);
        } else if (assetType == AssetType.ERC1155) {
            IERC1155(token).safeTransferFrom(address(this), to, identifier, amount, bytes(""));
        } else {
            revert("PB: the item type not supported");
        }
    }

    function _getAssetType(Order memory sell, Order memory buy)
    internal
    view
    returns (uint256 tokenId, uint256 amount, AssetType assetType)
    {
        if (sell.listingTime <= buy.listingTime) {
            /* Seller is maker. */
            (,, tokenId, amount, assetType) = IMatchingPolicy(sell.matchingPolicy).canMatchMakerAsk(sell, buy);
        } else {
            /* Buyer is maker. */
            (,, tokenId, amount, assetType) = IMatchingPolicy(buy.matchingPolicy).canMatchMakerBid(buy, sell);
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Payable receive function to receive Ether from oldVault when migrating
     */
    receive() external payable {}
}