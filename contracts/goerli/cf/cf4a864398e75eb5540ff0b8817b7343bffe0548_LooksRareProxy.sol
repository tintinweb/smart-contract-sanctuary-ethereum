// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC721.sol";
import {IERC1155} from "@looksrare/contracts-libs/contracts/interfaces/generic/IERC1155.sol";
import {CollectionType} from "./libraries/OrderEnums.sol";

/**
 * @title TokenTransferrer
 * @notice This contract contains a function to transfer NFTs from a proxy to the recipient
 * @author LooksRare protocol team (👀,💎)
 */
abstract contract TokenTransferrer {
    function _transferTokenToRecipient(
        CollectionType collectionType,
        address collection,
        address recipient,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (collectionType == CollectionType.ERC721) {
            IERC721(collection).transferFrom(address(this), recipient, tokenId);
        } else if (collectionType == CollectionType.ERC1155) {
            IERC1155(collection).safeTransferFrom(address(this), recipient, tokenId, amount, "");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BasicOrder} from "../libraries/OrderStructs.sol";

interface IProxy {
    error InvalidCaller();

    /**
     * @notice Execute NFT sweeps in a single transaction
     * @param orders Orders to be executed
     * @param ordersExtraData Extra data for each order
     * @param extraData Extra data for the whole transaction
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing)
     *                 or partial trades
     */
    function execute(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata extraData,
        address recipient,
        bool isAtomic
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum CollectionType { ERC721, ERC1155 }

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {CollectionType} from "./OrderEnums.sol";

/**
 * @param signer The order's maker
 * @param collection The address of the ERC721/ERC1155 token to be purchased
 * @param collectionType 0 for ERC721, 1 for ERC1155
 * @param tokenIds The IDs of the tokens to be purchased
 * @param amounts Always 1 when ERC721, can be > 1 if ERC1155
 * @param price The *taker bid* price to pay for the order
 * @param currency The order's currency, address(0) for ETH
 * @param startTime The timestamp when the order starts becoming valid
 * @param endTime The timestamp when the order stops becoming valid
 * @param signature split to v,r,s for LooksRare
 */
struct BasicOrder {
    address signer;
    address collection;
    CollectionType collectionType;
    uint256[] tokenIds;
    uint256[] amounts;
    uint256 price;
    address currency;
    uint256 startTime;
    uint256 endTime;
    bytes signature;
}

/**
 * @param amount ERC20 transfer amount
 * @param currency ERC20 transfer currency
 */
struct TokenTransfer {
    uint256 amount;
    address currency;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error InvalidOrderLength();
error TradeExecutionFailed();
error ZeroAddress();

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SignatureChecker} from "@looksrare/contracts-libs/contracts/SignatureChecker.sol";
import {ILooksRareExchange} from "@looksrare/contracts-exchange-v1/contracts/interfaces/ILooksRareExchange.sol";
import {OrderTypes} from "@looksrare/contracts-exchange-v1/contracts/libraries/OrderTypes.sol";

import {CollectionType} from "../libraries/OrderEnums.sol";
import {BasicOrder} from "../libraries/OrderStructs.sol";
import {IProxy} from "../interfaces/IProxy.sol";
import {TokenTransferrer} from "../TokenTransferrer.sol";
import {InvalidOrderLength} from "../libraries/SharedErrors.sol";

/**
 * @title LooksRareProxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from LooksRare
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract LooksRareProxy is IProxy, TokenTransferrer, SignatureChecker {
    /**
     * @param makerAskPrice Maker ask price, which is not necessarily equal to the
     *                      taker bid price
     * @param minPercentageToAsk The maker's minimum % to receive from the sale
     * @param nonce The maker's nonce
     * @param strategy LooksRare execution strategy
     */
    struct OrderExtraData {
        uint256 makerAskPrice;
        uint256 minPercentageToAsk;
        uint256 nonce;
        address strategy;
    }

    ILooksRareExchange public immutable marketplace;
    address public immutable aggregator;

    /**
     * @param _marketplace LooksRareExchange's address
     * @param _aggregator LooksRareAggregator's address
     */
    constructor(address _marketplace, address _aggregator) {
        marketplace = ILooksRareExchange(_marketplace);
        aggregator = _aggregator;
    }

    /**
     * @notice Execute LooksRare NFT sweeps in a single transaction
     * @dev extraData is not used
     * @param orders Orders to be executed by LooksRare
     * @param ordersExtraData Extra data for each order
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
     */
    function execute(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes memory, /* extraData */
        address recipient,
        bool isAtomic
    ) external payable override {
        if (address(this) != aggregator) revert InvalidCaller();

        uint256 ordersLength = orders.length;
        if (ordersLength == 0 || ordersLength != ordersExtraData.length) revert InvalidOrderLength();

        for (uint256 i; i < ordersLength; ) {
            BasicOrder calldata order = orders[i];

            OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));

            OrderTypes.MakerOrder memory makerAsk;
            {
                makerAsk.isOrderAsk = true;
                makerAsk.signer = order.signer;
                makerAsk.collection = order.collection;
                makerAsk.tokenId = order.tokenIds[0];
                makerAsk.price = orderExtraData.makerAskPrice;
                makerAsk.amount = order.amounts[0];
                makerAsk.strategy = orderExtraData.strategy;
                makerAsk.nonce = orderExtraData.nonce;
                makerAsk.minPercentageToAsk = orderExtraData.minPercentageToAsk;
                makerAsk.currency = order.currency;
                makerAsk.startTime = order.startTime;
                makerAsk.endTime = order.endTime;

                (bytes32 r, bytes32 s, uint8 v) = _splitSignature(order.signature);
                makerAsk.v = v;
                makerAsk.r = r;
                makerAsk.s = s;
            }

            OrderTypes.TakerOrder memory takerBid;
            {
                // No need to set isOrderAsk as its default value is false
                takerBid.taker = address(this);
                takerBid.price = order.price;
                takerBid.tokenId = makerAsk.tokenId;
                takerBid.minPercentageToAsk = makerAsk.minPercentageToAsk;
            }

            _executeSingleOrder(takerBid, makerAsk, recipient, order.collectionType, isAtomic);

            unchecked {
                ++i;
            }
        }
    }

    function _executeSingleOrder(
        OrderTypes.TakerOrder memory takerBid,
        OrderTypes.MakerOrder memory makerAsk,
        address recipient,
        CollectionType collectionType,
        bool isAtomic
    ) private {
        if (isAtomic) {
            marketplace.matchAskWithTakerBidUsingETHAndWETH{value: takerBid.price}(takerBid, makerAsk);
            _transferTokenToRecipient(
                collectionType,
                makerAsk.collection,
                recipient,
                makerAsk.tokenId,
                makerAsk.amount
            );
        } else {
            try marketplace.matchAskWithTakerBidUsingETHAndWETH{value: takerBid.price}(takerBid, makerAsk) {
                _transferTokenToRecipient(
                    collectionType,
                    makerAsk.collection,
                    recipient,
                    makerAsk.tokenId,
                    makerAsk.amount
                );
            } catch {}
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "../libraries/OrderTypes.sol";

interface ILooksRareExchange {
    function matchAskWithTakerBidUsingETHAndWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable;

    function matchAskWithTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external;

    function matchBidWithTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OrderTypes
 * @notice This library contains order types for the LooksRare exchange.
 */
library OrderTypes {
    // keccak256("MakerOrder(bool isOrderAsk,address signer,address collection,uint256 price,uint256 tokenId,uint256 amount,address strategy,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params)")
    bytes32 internal constant MAKER_ORDER_HASH = 0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;

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

    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.isOrderAsk,
                    makerOrder.signer,
                    makerOrder.collection,
                    makerOrder.price,
                    makerOrder.tokenId,
                    makerOrder.amount,
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk,
                    keccak256(makerOrder.params)
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {IERC1271} from "./interfaces/generic/IERC1271.sol";
import {ISignatureChecker} from "./interfaces/ISignatureChecker.sol";

/**
 * @title SignatureChecker
 * @notice This contract is used to verify signatures for EOAs (with length of both 65 and 64 bytes) and contracts (ERC-1271).
 */
abstract contract SignatureChecker is ISignatureChecker {
    /**
     * @notice Split a signature into r,s,v outputs
     * @param signature A 64 or 65 bytes signature
     * @return r The r output of the signature
     * @return s The s output of the signature
     * @return v The recovery identifier, must be 27 or 28
     */
    function _splitSignature(bytes memory signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        if (signature.length == 64) {
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else if (signature.length == 65) {
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else {
            revert WrongSignatureLength(signature.length);
        }

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) revert BadSignatureS();

        if (v != 27 && v != 28) revert BadSignatureV(v);
    }

    /**
     * @notice Recover the signer of a signature (for EOA)
     * @param hash Hash of the signed message
     * @param signature Bytes containing the signature (64 or 65 bytes)
     */
    function _recoverEOASigner(bytes32 hash, bytes memory signature) internal pure returns (address signer) {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);

        // If the signature is valid (and not malleable), return the signer address
        signer = ecrecover(hash, v, r, s);

        if (signer == address(0)) revert NullSignerAddress();
    }

    /**
     * @notice Checks whether the signer is valid
     * @param hash Data hash
     * @param signer Signer address (to confirm message validity)
     * @param signature Signature parameters encoded (v, r, s)
     * @dev For EIP-712 signatures, the hash must be the digest (computed with signature hash and domain separator)
     */
    function _verify(
        bytes32 hash,
        address signer,
        bytes memory signature
    ) internal view {
        if (signer.code.length == 0) {
            if (_recoverEOASigner(hash, signature) != signer) revert InvalidSignatureEOA();
        } else {
            if (IERC1271(signer).isValidSignature(hash, signature) != 0x1626ba7e) revert InvalidSignatureERC1271();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ISignatureChecker
 */
interface ISignatureChecker {
    // Custom errors
    error BadSignatureS();
    error BadSignatureV(uint8 v);
    error InvalidSignatureERC1271();
    error InvalidSignatureEOA();
    error NullSignerAddress();
    error WrongSignatureLength(uint256 length);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1271 {
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}