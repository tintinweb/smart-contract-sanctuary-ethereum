// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC721 {
    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;

    function setApprovalForAll(address operator, bool approved) external;

    function approve(address to, uint256 tokenId) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function balanceOf(address _owner) external view returns (uint256);
}

pragma solidity 0.8.17;

import "../../interfaces/tokens/IERC721.sol";
import "../../interfaces/tokens/IERC1155.sol";


// keccak256("MakerOrder(bool isOrderAsk,address signer,address collection,uint256 price,uint256 tokenId,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params)")
// bytes32 constant MAKER_ORDER_HASH = 0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;

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

struct TradeDataLooksrare {
    uint256 value;
    uint256 collectionType;
    TakerOrder takerOrder;
    MakerOrder makerOrder;
}


interface ILooksRareExchange {
    function matchAskWithTakerBidUsingETHAndWETH(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external payable;

    function matchAskWithTakerBid(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk
    ) external;

    function matchBidWithTakerAsk(
        TakerOrder calldata takerAsk,
        MakerOrder calldata makerBid
    ) external;
}

library LooksrareMarket {

    address public constant LooksrareExange = 0xD112466471b5438C1ca2D218694200e49d81D047;
    bytes32 internal constant MAKER_ORDER_HASH = 0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;
    event Log(string message);
    event LogBytes(bytes data);

    function execute(bytes memory tradeData) public {
        uint256 SUCCESS = 0;

        TradeDataLooksrare memory tradeDataLooksrare = abi.decode(tradeData, (TradeDataLooksrare));


        // address taker_address = tradeDataLooksrare.takerOrder.taker;
        tradeDataLooksrare.takerOrder.taker = address(this);

        try ILooksRareExchange(LooksrareExange).matchAskWithTakerBidUsingETHAndWETH{value: tradeDataLooksrare.value}(
            tradeDataLooksrare.takerOrder,
            tradeDataLooksrare.makerOrder
        ) {
            emit Log("Transaction succeeded");
            SUCCESS = 1;
        } catch Error(string memory reason){
            // catch failing revert() and require()
            emit Log(reason);
        } catch (bytes memory reason) {
            // catch failing assert()
            emit LogBytes(reason);
        }

        if (SUCCESS == 1){
            if (tradeDataLooksrare.collectionType == 1) {
                IERC721(tradeDataLooksrare.makerOrder.collection).transferFrom(address(this), msg.sender, tradeDataLooksrare.takerOrder.tokenId);

            } else {
                // uint256 amount = 1;
                IERC1155(tradeDataLooksrare.makerOrder.collection).safeTransferFrom(address(this), msg.sender, tradeDataLooksrare.takerOrder.tokenId, tradeDataLooksrare.makerOrder.amount, "");
            }

        }
    }
}


// library LooksrareMarket {

//     address public constant LooksrareExange = 0xD112466471b5438C1ca2D218694200e49d81D047;
//     bytes32 internal constant MAKER_ORDER_HASH = 0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;
//     uint256 internal constant SUCCESS = 1;

//     function execute(bytes memory tradeData) public {
//         TradeDataLooksrare memory tradeDataLooksrare = abi.decode(tradeData, (TradeDataLooksrare));

//         try ILooksRareExchange(LooksrareExange).matchAskWithTakerBidUsingETHAndWETH{value: tradeDataLooksrare.value}(
//             tradeDataLooksrare.takerOrder,
//             tradeDataLooksrare.makerOrder
//         ) returns (){

//         } catch {

//         }


//         if (tradeDataLooksrare.collectionType == 1) {
//             IERC721(tradeDataLooksrare.makerOrder.collection).transferFrom(address(this), msg.sender, tradeDataLooksrare.takerOrder.tokenId);

//         } else {
//             // uint256 amount = 1;
//             IERC1155(tradeDataLooksrare.makerOrder.collection).safeTransferFrom(address(this), msg.sender, tradeDataLooksrare.takerOrder.tokenId, tradeDataLooksrare.makerOrder.amount, "");
//         }


//     }
// }