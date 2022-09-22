// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// LooksRare order types, source: https://github.com/LooksRare/contracts-exchange-v1/blob/59ccb75c939c1dcafebda8cecedbda442131f0af/contracts/libraries/OrderTypes.sol
library OrderTypes {
    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
        uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // other params (e.g., tokenId)
    }
}

/// ============ Interfaces ============

// Wrapped Ether
interface IWETH {
    /// @notice Deposit ETH to WETH
    function deposit() external payable;

    /// @notice WETH balance
    function balanceOf(address holder) external returns (uint256);

    /// @notice ERC20 Spend approval
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice ERC20 transferFrom
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// ERC721
interface IERC721 {
    /// @notice Set transfer approval for operator
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Transfer NFT
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// LooksRare exchange, source: https://github.com/LooksRare/contracts-exchange-v1/blob/59ccb75c939c1dcafebda8cecedbda442131f0af/contracts/LooksRareExchange.sol
interface ILooksRareExchange {
    /// @notice Match a taker ask with maker bid
    function matchBidWithTakerAsk(
        OrderTypes.TakerOrder calldata takerAsk,
        OrderTypes.MakerOrder calldata makerBid
    ) external;

    /// @notice Match ask with ETH/WETH bid
    function matchAskWithTakerBidUsingETHAndWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable;
}

contract SellLooksrare is IERC721Receiver {
    /// @dev Wrapped Ether contract
    IWETH internal immutable WETH;
    /// @dev Contract owner
    address internal immutable OWNER;
    /// @dev LooksRare exchange contract
    ILooksRareExchange internal immutable LOOKSRARE;

    /// @notice Creates a new instant sell contract
    /// @param _WETH address of WETH
    /// @param _LOOKSRARE address of looksrare exchange
    constructor(
        address _WETH,
        address _LOOKSRARE
    ) {
        // Setup contract owner
        OWNER = msg.sender;
        // Setup Wrapped Ether contract
        WETH = IWETH(_WETH);
        // Setup LooksRare exchange contract (0x59728544B08AB483533076417FbBB2fD0B17CE3a)
        LOOKSRARE = ILooksRareExchange(_LOOKSRARE);
    }

   function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @notice Executes purchase NFT on looksrare
    function executeBuy(bytes memory data) external {
        // Decode variables passed in data
        OrderTypes.MakerOrder memory purchaseAsk = abi.decode(
            data,
            (OrderTypes.MakerOrder)
        );

        // Setup our taker bid to buy
        OrderTypes.TakerOrder memory purchaseBid = OrderTypes.TakerOrder({
            isOrderAsk: false,
            taker: address(this),
            price: purchaseAsk.price,
            tokenId: purchaseAsk.tokenId,
            minPercentageToAsk: purchaseAsk.minPercentageToAsk,
            params: ""
        });

        // Accept maker ask order and purchase the NFT
        LOOKSRARE.matchAskWithTakerBidUsingETHAndWETH{value:purchaseAsk.price}(purchaseBid, purchaseAsk);
    }

    /// @notice Executes instant sell on looksrare
    function executeSell(bytes memory data, uint256 _tokenId) external {
        // Decode variables passed in data
        OrderTypes.MakerOrder memory saleBid = abi.decode(
            data,
            (OrderTypes.MakerOrder)
        );

        // Setup our taker bid to sell
        OrderTypes.TakerOrder memory saleAsk = OrderTypes.TakerOrder({
            isOrderAsk: true,
            taker: address(this),
            price: saleBid.price,
            tokenId: _tokenId, // user's token id
            minPercentageToAsk: saleBid.minPercentageToAsk,
            params: ""
        });

        // Accept maker ask order and sell NFT
        LOOKSRARE.matchBidWithTakerAsk(saleAsk, saleBid);
    }

    /// @notice Withdraws contract ETH balance to owner address
    function withdrawBalance() external {
        (bool sent, ) = OWNER.call{value: address(this).balance}("");
        if (!sent) revert("Could not withdraw balance");
    }

    /// @notice Withdraws contract WETH balance to owner address
    function withdrawBalanceWETH() external {
        WETH.transferFrom(address(this), OWNER, WETH.balanceOf(address(this)));
    }

    /// @notice Allows receiving ETH
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
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