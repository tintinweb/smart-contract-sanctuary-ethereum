// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { ArbitraryCall } from "../../../util/ArbitraryCall.sol";
import { IOpenSea } from "./IOpenSea.sol";
import { IMerkleValidator } from "./IMerkleValidator.sol";
import { OpenSeaBuy } from "./IOpenSea.sol";
import { Ownable } from "../../../util/Ownable.sol";
import { Recoverable } from "../../../util/Recoverable.sol";
import { RevertUtils } from "../../../util/RevertUtils.sol";
import { SendUtils } from "../../../util/SendUtils.sol";

enum OfferSchema {
    Generic,
    MatchERC721UsingCriteria,
    MatchERC1155UsingCriteria,
    ERC721TransferFrom

    // NOTE: We currently don't support ERC1155SafeTransferFrom in the contract.
    // It seems to have been phased out by OpenSea so it's not relevant to us,
    // which is fine because we only use 2 bits to encode the schema anyway.
    //ERC1155SafeTransferFrom
}

//---------------------------------------------------------------------------------//
// WARNING: Due to the extra power ArbitraryCall gives the owner of this contract, //
// the contract MUST NOT own any tokens or be trused by other contracts to         //
// perform sensitive operations without additional authorization.                  //
//---------------------------------------------------------------------------------//

contract OptimizedOpenSeaMarket is Recoverable, ArbitraryCall {
    address constant OPEN_SEA_WALLET = 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;
    address constant MERKLE_VALIDATOR_ADDRESS = 0xBAf2127B49fC93CbcA6269FAdE0F7F31dF4c88a7;

    IOpenSea immutable _openSea;

    constructor(address owner, IOpenSea openSea) Ownable(owner) {
        _openSea = openSea;
    }

    receive() external payable {}

    function optimizedBuyAssetsForEth(bytes calldata optimizedBuys) public payable {
        uint8 buyCount = uint8(optimizedBuys[0]);
        bool revertIfTrxFails = (optimizedBuys[1] > 0);

        OpenSeaBuy memory openSeaBuy;
        initOpenSeaBuyTemplate(openSeaBuy);

        uint offset = 2;
        for (uint256 i = 0; i < buyCount;) {
            uint decodedDataSize = decodeBuyIntoTemplate(optimizedBuys[offset:], openSeaBuy);
            offset += decodedDataSize;

            _buyAssetForEth(openSeaBuy, revertIfTrxFails);
            unchecked { ++i; }
        }
        SendUtils._returnAllEth();
    }

    function _buyAssetForEth(OpenSeaBuy memory openSeaBuy, bool revertIfTrxFails) internal {
        try _openSea.atomicMatch_{value: openSeaBuy.uints[4]}(
            openSeaBuy.addrs,
            openSeaBuy.uints,
            openSeaBuy.feeMethodsSidesKindsHowToCalls,
            openSeaBuy.calldataBuy,
            openSeaBuy.calldataSell,
            openSeaBuy.replacementPatternBuy,
            openSeaBuy.replacementPatternSell,
            openSeaBuy.staticExtradataBuy,
            openSeaBuy.staticExtradataSell,
            openSeaBuy.vs,
            openSeaBuy.rssMetadata
        ) {
            return;
        } catch (bytes memory lowLevelData) {
            if (revertIfTrxFails)
                RevertUtils.rawRevert(lowLevelData);
        }
    }

    function decodeCalldataERC721TF(
        address maker,
        uint tokenId,
        address taker
    )
        public
        pure
        returns (bytes memory, bytes memory, bytes memory, bytes memory)
    {
        return (
            // calldata_
            bytes.concat(
                IERC721.transferFrom.selector,
                bytes32(uint(uint160(maker))),
                bytes32(0),
                bytes32(tokenId)
            ),
            // replacementPattern
            bytes.concat(
                bytes4(0),
                bytes32(0),
                bytes32(type(uint).max),
                bytes32(0)
            ),
            // calldataFromBackend
            bytes.concat(
                IERC721.transferFrom.selector,
                bytes32(uint(uint160(maker))),
                bytes32(uint(uint160(taker))),
                bytes32(tokenId)
            ),
            // replacementPatternFromBackend
            bytes.concat(
                bytes4(0),
                bytes32(0),
                bytes32(0),
                bytes32(0)
            )
        );
    }

    function decodeCalldataMERC721UC(
        address maker,
        uint tokenId,
        address taker,
        address tokenContract
    )
        public
        pure
        returns (bytes memory, bytes memory, bytes memory, bytes memory)
    {
        return (
            // calldata_
            bytes.concat(
                IMerkleValidator.matchERC721UsingCriteria.selector,
                bytes32(uint(uint160(maker))),
                bytes32(0),
                bytes32(uint(uint160(tokenContract))),
                bytes32(tokenId),
                bytes32(0),            // root
                bytes32(uint(6 * 32)), // proof.offset
                bytes32(0)             // proof.length
            ),
            // replacementPattern
            bytes.concat(
                bytes4(0),
                bytes32(0),
                bytes32(type(uint).max),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0)
            ),
            // calldataFromBackend
            bytes.concat(
                IMerkleValidator.matchERC721UsingCriteria.selector,
                bytes32(uint(uint160(maker))),
                bytes32(uint(uint160(taker))),
                bytes32(uint(uint160(tokenContract))),
                bytes32(tokenId),
                bytes32(0),            // root
                bytes32(uint(6 * 32)), // proof.offset
                bytes32(0)             // proof.length
            ),
            // replacementPatternFromBackend
            bytes.concat(
                bytes4(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0)
            )
        );
    }

    function decodeCalldataMERC1155UC(
        address maker,
        uint tokenId,
        address taker,
        address tokenContract,
        uint tokenAmount
    )
        public
        pure
        returns (bytes memory, bytes memory, bytes memory, bytes memory)
    {
        return (
            // calldata_
            bytes.concat(
                IMerkleValidator.matchERC1155UsingCriteria.selector,
                bytes32(uint(uint160(maker))),
                bytes32(0),
                bytes32(uint(uint160(tokenContract))),
                bytes32(tokenId),
                bytes32(tokenAmount),
                bytes32(0),            // root
                bytes32(uint(7 * 32)), // proof.offset
                bytes32(0)             // proof.length
            ),
            // replacementPattern
            bytes.concat(
                bytes4(0),
                bytes32(0),
                bytes32(type(uint).max),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0)
            ),
            // calldataFromBackend
            bytes.concat(
                IMerkleValidator.matchERC1155UsingCriteria.selector,
                bytes32(uint(uint160(maker))),
                bytes32(uint(uint160(taker))),
                bytes32(uint(uint160(tokenContract))),
                bytes32(tokenId),
                bytes32(tokenAmount),
                bytes32(0),            // root
                bytes32(uint(7 * 32)), // proof.offset
                bytes32(0)             // proof.length
            ),
            // replacementPatternFromBackend
            bytes.concat(
                bytes4(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0),
                bytes32(0)
            )
        );
    }

    function decodeBuy(bytes calldata optimizedBuy) public view returns (OpenSeaBuy memory openSeaBuy, uint offset) {
        initOpenSeaBuyTemplate(openSeaBuy);
        offset = decodeBuyIntoTemplate(optimizedBuy, openSeaBuy);
        return (openSeaBuy, offset);
    }

    /// Initializes the part of OpenSeaBuy that stays the same for all offers.
    function initOpenSeaBuyTemplate(OpenSeaBuy memory openSeaBuyToFill) internal view {
        openSeaBuyToFill.uints[0] = 0;                  // buy.uints.makerRelayerFee
        openSeaBuyToFill.uints[1] = 0;                  // buy.uints.takerRelayerFee
        openSeaBuyToFill.uints[2] = 0;                  // buy.uints.makerProtocolFee
        openSeaBuyToFill.uints[3] = 0;                  // buy.uints.takerProtocolFee
        //openSeaBuyToFill.uints[4]                     // buy.uints.basePrice
        openSeaBuyToFill.uints[5] = 0;                  // buy.uints.extra
        openSeaBuyToFill.uints[6] = 0;                  // buy.uints.listingTime
        openSeaBuyToFill.uints[7] = 0;                  // buy.uints.expirationTime

        // NOTE: Salt only matters for published orders. It is used by Wyvern Exchange to ensure that
        // two otherwise identical orders hash to different values because order hash is used as a unique
        // identifier. The hash is what gets signed (see `Exchange.hashToSign()`) and is required for order
        // cancellation to work properly.
        // Since we're the taker side for an already published order, `ExchangeCore.atomicMatch()` will
        // never even try to generate this hash (note that v, r and s are zero so there's no signature
        // for it) and we can safely set salt to zero.
        openSeaBuyToFill.uints[8] = 0;                           // buy.uints.salt

        //openSeaBuyToFill.uints[9]                              // sell.uints.makerRelayerFee
        openSeaBuyToFill.uints[10] = 0;                          // sell.uints.takerRelayerFee
        openSeaBuyToFill.uints[11] = 0;                          // sell.uints.makerProtocolFee
        openSeaBuyToFill.uints[12] = 0;                          // sell.uints.takerProtocolFee
        //openSeaBuyToFill.uints[13]                             // sell.uints.basePrice
        openSeaBuyToFill.uints[14] = 0;                          // sell.uints.extra
        //openSeaBuyToFill.uints[15]                             // sell.uints.listingTime
        //openSeaBuyToFill.uints[16]                             // sell.uints.expirationTime
        //openSeaBuyToFill.uints[17]                             // sell.uints.salt

        openSeaBuyToFill.vs[0] = 0;                              // buy.v
        //openSeaBuyToFill.vs[1]                                 // sell.v
        openSeaBuyToFill.rssMetadata[0] = 0;                     // buy.r
        openSeaBuyToFill.rssMetadata[1] = 0;                     // buy.s
        //openSeaBuyToFill.rssMetadata[2]                        // sell.r
        //openSeaBuyToFill.rssMetadata[3]                        // sell.s
        openSeaBuyToFill.rssMetadata[4] = 0;                     // metadata

        openSeaBuyToFill.addrs[0] = address(_openSea);           // buy.addrs.exchange
        openSeaBuyToFill.addrs[1] = address(this);               // buy.addrs.maker
        openSeaBuyToFill.addrs[2] = address(0);                  // buy.addrs.taker
        openSeaBuyToFill.addrs[3] = address(0);                  // buy.addrs.feeRecipient
        //openSeaBuyToFill.addrs[4]                              // buy.addrs.target
        openSeaBuyToFill.addrs[5] = address(0);                  // buy.addrs.staticTarget
        openSeaBuyToFill.addrs[6] = address(0);                  // buy.addrs.paymentToken
        openSeaBuyToFill.addrs[7] = address(_openSea);           // sell.addrs.exchange
        //openSeaBuyToFill.addrs[8]                              // sell.addrs.maker
        openSeaBuyToFill.addrs[9] = address(0);                  // sell.addrs.taker
        openSeaBuyToFill.addrs[10] = OPEN_SEA_WALLET;            // sell.addrs.feeRecipient
        //openSeaBuyToFill.addrs[11]                             // sell.addrs.target
        openSeaBuyToFill.addrs[12] = address(0);                 // sell.addrs.staticTarget
        openSeaBuyToFill.addrs[13] = address(0);                 // sell.addrs.paymentToken

        openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[0] = 1;  // buy.kinds.feeMethod
        openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[1] = 0;  // buy.kinds.side
        openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[2] = 0;  // buy.kinds.saleKind
        //openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[3]     // buy.kinds.howToCall
        openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[4] = 1;  // sell.kinds.feeMethod
        openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[5] = 1;  // sell.kinds.side
        openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[6] = 0;  // sell.kinds.saleKind
        //openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[7]     // sell.kinds.howToCall

        openSeaBuyToFill.staticExtradataBuy = '';                // buy.staticExtradata
        openSeaBuyToFill.staticExtradataSell = '';               // sell.staticExtradata
    }

    /// Decodes an optimized buy encoded as bytes into the specified OpenSeaBuy struct.
    ///
    /// @dev This function assumes that openSeaBuyToFill has already been initialized with initOpenSeaBuyTemplate()
    /// so that only the fields that may very between orders need to be initialized.
    function decodeBuyIntoTemplate(bytes calldata optimizedBuy, OpenSeaBuy memory openSeaBuyToFill) internal pure returns (uint) {
        OfferSchema offerSchema = OfferSchema(uint8(optimizedBuy[0]) >> 6);

        uint offset = 0;

        {
            uint makerRelayerFee;
            uint basePrice;
            uint listingTime;
            uint expirationTime;
            uint salt;

            assembly {
                makerRelayerFee := and(0x3fff, shr(240, calldataload(add(optimizedBuy.offset, offset))))
                offset := add(offset, 2)
                basePrice := calldataload(add(optimizedBuy.offset, offset))
                offset := add(offset, 32)

                listingTime := shr(224, calldataload(add(optimizedBuy.offset, offset)))
                offset := add(offset, 4)
                expirationTime := shr(224, calldataload(add(optimizedBuy.offset, offset)))
                offset := add(offset, 4)
                salt := calldataload(add(optimizedBuy.offset, offset))
                offset := add(offset, 32)
            }

            // ASSUMPTION: Commented-out fields were already initialized by initOpenSeaBuyTemplate()
            //openSeaBuyToFill.uints[0] = 0;                // buy.uints.makerRelayerFee
            //openSeaBuyToFill.uints[1] = 0;                // buy.uints.takerRelayerFee
            //openSeaBuyToFill.uints[2] = 0;                // buy.uints.makerProtocolFee
            //openSeaBuyToFill.uints[3] = 0;                // buy.uints.takerProtocolFee
            openSeaBuyToFill.uints[4] = basePrice;          // buy.uints.basePrice
            //openSeaBuyToFill.uints[5] = 0;                // buy.uints.extra
            //openSeaBuyToFill.uints[6] = 0;                // buy.uints.listingTime
            //openSeaBuyToFill.uints[7] = 0;                // buy.uints.expirationTime
            //openSeaBuyToFill.uints[8] = 0;                // buy.uints.salt
            openSeaBuyToFill.uints[9]  = makerRelayerFee;   // sell.uints.makerRelayerFee
            //openSeaBuyToFill.uints[10] = 0;               // sell.uints.takerRelayerFee
            //openSeaBuyToFill.uints[11] = 0;               // sell.uints.makerProtocolFee
            //openSeaBuyToFill.uints[12] = 0;               // sell.uints.takerProtocolFee
            openSeaBuyToFill.uints[13] = basePrice;         // sell.uints.basePrice
            //openSeaBuyToFill.uints[14] = 0;               // sell.uints.extra
            openSeaBuyToFill.uints[15] = listingTime;       // sell.uints.listingTime
            openSeaBuyToFill.uints[16] = expirationTime;    // sell.uints.expirationTime
            openSeaBuyToFill.uints[17] = salt;              // sell.uints.salt
        }
        {
            bytes32 r;                                      // sell.r
            bytes32 s;                                      // sell.s
            uint8 v;                                        // sell.v

            assembly {
                r := calldataload(add(optimizedBuy.offset, offset))
                offset := add(offset, 32)
                let vs := calldataload(add(optimizedBuy.offset, offset))
                offset := add(offset, 32)

                v := add(shr(255, vs), 27)
                s := and(vs, not(shl(255, 1)))
            }

            // ASSUMPTION: Commented-out fields were already initialized by initOpenSeaBuyTemplate()
            //openSeaBuyToFill.vs[0] = 0;                   // buy.v
            openSeaBuyToFill.vs[1] = v;                     // sell.v
            //openSeaBuyToFill.rssMetadata[0] = 0;          // buy.r
            //openSeaBuyToFill.rssMetadata[1] = 0;          // buy.s
            openSeaBuyToFill.rssMetadata[2] = r;            // sell.r
            openSeaBuyToFill.rssMetadata[3] = s;            // sell.s
            //openSeaBuyToFill.rssMetadata[4] = 0;          // metadata
        }
        address maker;
        {
            assembly {
                maker := shr(96, calldataload(add(optimizedBuy.offset, offset)))
                offset := add(offset, 20)
            }

            address target;
            uint8 howToCall;
            if (offerSchema == OfferSchema.MatchERC721UsingCriteria || offerSchema == OfferSchema.MatchERC1155UsingCriteria) {
                target = MERKLE_VALIDATOR_ADDRESS;
                howToCall = 1;
            }
            else
                assembly {
                    target := shr(96, calldataload(add(optimizedBuy.offset, offset)))
                    offset := add(offset, 20)
                    howToCall := shr(248, calldataload(add(optimizedBuy.offset, offset)))
                    offset := add(offset, 1)
                }

            // ASSUMPTION: Commented-out fields were already initialized by initOpenSeaBuyTemplate()
            //openSeaBuyToFill.addrs[0] = address(_openSea);                 // buy.addrs.exchange
            //openSeaBuyToFill.addrs[1] = address(this);                     // buy.addrs.maker
            //openSeaBuyToFill.addrs[2] = address(0);                        // buy.addrs.taker
            //openSeaBuyToFill.addrs[3] = address(0);                        // buy.addrs.feeRecipient
            openSeaBuyToFill.addrs[4] = target;                              // buy.addrs.target
            //openSeaBuyToFill.addrs[5] = address(0);                        // buy.addrs.staticTarget
            //openSeaBuyToFill.addrs[6] = address(0);                        // buy.addrs.paymentToken
            //openSeaBuyToFill.addrs[7] = address(_openSea);                 // sell.addrs.exchange
            openSeaBuyToFill.addrs[8] = maker;                               // sell.addrs.maker
            //openSeaBuyToFill.addrs[9] = address(0);                        // sell.addrs.taker
            //openSeaBuyToFill.addrs[10] = OPEN_SEA_WALLET;                  // sell.addrs.feeRecipient
            openSeaBuyToFill.addrs[11] = target;                             // sell.addrs.target
            //openSeaBuyToFill.addrs[12] = address(0);                       // sell.addrs.staticTarget
            //openSeaBuyToFill.addrs[13] = address(0);                       // sell.addrs.paymentToken

            //openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[0] = 1;        // buy.kinds.feeMethod
            //openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[1] = 0;        // buy.kinds.side
            //openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[2] = 0;        // buy.kinds.saleKind
            openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[3] = howToCall;  // buy.kinds.howToCall
            //openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[4] = 1;        // sell.kinds.feeMethod
            //openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[5] = 1;        // sell.kinds.side
            //openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[6] = 0;        // sell.kinds.saleKind
            openSeaBuyToFill.feeMethodsSidesKindsHowToCalls[7] = howToCall;  // sell.kinds.howToCall
        }
        if (offerSchema == OfferSchema.Generic) {
            {
                uint dataSize;
                assembly {
                    dataSize := shr(240, calldataload(add(optimizedBuy.offset, offset)))
                    offset := add(offset, 2)
                }

                bytes memory dataPtr;
                if (openSeaBuyToFill.calldataSell.length < dataSize)
                    dataPtr = new bytes(dataSize);
                else {
                    dataPtr = openSeaBuyToFill.calldataSell;
                    assembly {
                        mstore(dataPtr, dataSize)
                    }
                }

                assembly {
                    calldatacopy(add(dataPtr, 32), add(optimizedBuy.offset, offset), dataSize)
                    offset := add(offset, dataSize)
                }
                openSeaBuyToFill.calldataSell = dataPtr;              // sell.calldata
            }
            {
                uint dataSize;
                assembly {
                    dataSize := shr(240, calldataload(add(optimizedBuy.offset, offset)))
                    offset := add(offset, 2)
                }

                bytes memory dataPtr;
                if (openSeaBuyToFill.replacementPatternSell.length < dataSize)
                    dataPtr = new bytes(dataSize);
                else {
                    dataPtr = openSeaBuyToFill.replacementPatternSell;
                    assembly {
                        mstore(dataPtr, dataSize)
                    }
                }

                assembly {
                    calldatacopy(add(dataPtr, 32), add(optimizedBuy.offset, offset), dataSize)
                    offset := add(offset, dataSize)
                }
                openSeaBuyToFill.replacementPatternSell = dataPtr;    // sell.replacementPattern
            }
            {
                uint dataSize;
                assembly {
                    dataSize := shr(240, calldataload(add(optimizedBuy.offset, offset)))
                    offset := add(offset, 2)
                }

                bytes memory dataPtr;
                if (openSeaBuyToFill.calldataBuy.length < dataSize)
                    dataPtr = new bytes(dataSize);
                else {
                    dataPtr = openSeaBuyToFill.calldataBuy;
                    assembly {
                        mstore(dataPtr, dataSize)
                    }
                }

                assembly {
                    calldatacopy(add(dataPtr, 32), add(optimizedBuy.offset, offset), dataSize)
                    offset := add(offset, dataSize)
                }
                openSeaBuyToFill.calldataBuy = dataPtr;               // buy.calldata
            }
            {
                uint dataSize;
                assembly {
                    dataSize := shr(240, calldataload(add(optimizedBuy.offset, offset)))
                    offset := add(offset, 2)
                }

                bytes memory dataPtr;
                if (openSeaBuyToFill.replacementPatternBuy.length < dataSize)
                    dataPtr = new bytes(dataSize);
                else {
                    dataPtr = openSeaBuyToFill.replacementPatternBuy;
                    assembly {
                        mstore(dataPtr, dataSize)
                    }
                }

                assembly {
                    calldatacopy(add(dataPtr, 32), add(optimizedBuy.offset, offset), dataSize)
                    offset := add(offset, dataSize)
                }
                openSeaBuyToFill.replacementPatternBuy = dataPtr;     // buy.replacementPattern
            }
        }
        else {
            uint tokenId;
            address taker;

            assembly {
                tokenId := calldataload(add(optimizedBuy.offset, offset))
                offset := add(offset, 32)
                taker := shr(96, calldataload(add(optimizedBuy.offset, offset)))
                offset := add(offset, 20)
            }

            if (offerSchema == OfferSchema.ERC721TransferFrom)
                (
                    openSeaBuyToFill.calldataSell,            // sell.calldata
                    openSeaBuyToFill.replacementPatternSell,  // sell.replacementPattern
                    openSeaBuyToFill.calldataBuy,             // buy.calldata
                    openSeaBuyToFill.replacementPatternBuy    // buy.replacementPattern
                ) = decodeCalldataERC721TF(maker, tokenId, taker);
            else {
                address tokenContract;

                assembly {
                    tokenContract := shr(96, calldataload(add(optimizedBuy.offset, offset)))
                    offset := add(offset, 20)
                }

                if (offerSchema == OfferSchema.MatchERC721UsingCriteria)
                    (
                        openSeaBuyToFill.calldataSell,            // sell.calldata
                        openSeaBuyToFill.replacementPatternSell,  // sell.replacementPattern
                        openSeaBuyToFill.calldataBuy,             // buy.calldata
                        openSeaBuyToFill.replacementPatternBuy    // buy.replacementPattern
                    ) = decodeCalldataMERC721UC(maker, tokenId, taker, tokenContract);
                else {
                    uint tokenAmount;

                    assembly {
                        tokenAmount := calldataload(add(optimizedBuy.offset, offset))
                        offset := add(offset, 32)
                    }

                    assert(offerSchema == OfferSchema.MatchERC1155UsingCriteria);
                    (
                        openSeaBuyToFill.calldataSell,            // sell.calldata
                        openSeaBuyToFill.replacementPatternSell,  // sell.replacementPattern
                        openSeaBuyToFill.calldataBuy,             // buy.calldata
                        openSeaBuyToFill.replacementPatternBuy    // buy.replacementPattern
                    ) = decodeCalldataMERC1155UC(maker, tokenId, taker, tokenContract, tokenAmount);
                }
            }
        }

        // ASSUMPTION: These fields were already initialized by initOpenSeaBuyTemplate()
        //openSeaBuyToFill.staticExtradataBuy = '';  // buy.staticExtradata
        //openSeaBuyToFill.staticExtradataSell = ''; // sell.staticExtradata

        return offset;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import { Ownable } from "./Ownable.sol";
import { RevertUtils } from "./RevertUtils.sol";
import { SendUtils } from "./SendUtils.sol";

abstract contract ArbitraryCall is Ownable {
    event ArbitraryCallReturn(bytes returndata);

    /// Performs an external call to the specified address with the specified arguments.
    /// This function is meant to allow the owner of the contract to reap benefits of being
    /// a frequent customer of OpenSea. For example, to collect an airdrop.
    ///
    /// @dev This function would be a big security liability in a contract holding significant amounts
    /// of funds or being whilelisted to perform privileged actions in other contracts. Currently
    /// this is not the case and it's very important to ensure that it stays that way.
    /// This function gives the owner the ability to freely impersonate the contract. If the owner contract
    /// gets compromised, the attacker will have the same power.
    function arbitraryCall(address targetContract, bytes calldata encodedArguments) public payable onlyOwner returns (bytes memory) {
        // NOTE: If the contract has no receive() function and the target contract tries to send ether
        // back to msg.sender, the transaction will fail.
        (bool success, bytes memory returndata) = targetContract.call{value: msg.value}(encodedArguments);
        if (!success)
            RevertUtils.forwardRevert();

        SendUtils._returnAllEth();
        emit ArbitraryCallReturn(returndata);
        return returndata;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

struct OpenSeaBuy {
    address[14] addrs;
    uint[18] uints;
    uint8[8] feeMethodsSidesKindsHowToCalls;
    bytes calldataBuy;
    bytes calldataSell;
    bytes replacementPatternBuy;
    bytes replacementPatternSell;
    bytes staticExtradataBuy;
    bytes staticExtradataSell;
    uint8[2] vs;
    bytes32[5] rssMetadata;
}

interface IOpenSea {
    /**
     * @dev Call atomicMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function atomicMatch_(
        address[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata
    ) external payable;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IMerkleValidator {
    // Function declarations based on https://etherscan.io/address/0xbaf2127b49fc93cbca6269fade0f7f31df4c88a7#code

    /// @dev Match an ERC721 order, ensuring that the supplied proof demonstrates inclusion of the tokenId in the associated merkle root.
    /// @param from The account to transfer the ERC721 token from — this token must first be approved on the seller's AuthenticatedProxy contract.
    /// @param to The account to transfer the ERC721 token to.
    /// @param token The ERC721 token to transfer.
    /// @param tokenId The ERC721 tokenId to transfer.
    /// @param root A merkle root derived from each valid tokenId — set to 0 to indicate a collection-level or tokenId-specific order.
    /// @param proof A proof that the supplied tokenId is contained within the associated merkle root. Must be length 0 if root is not set.
    /// @return A boolean indicating a successful match and transfer.
    function matchERC721UsingCriteria(
        address from,
        address to,
        IERC721 token,
        uint256 tokenId,
        bytes32 root,
        bytes32[] calldata proof
    ) external returns (bool);

    /// @dev Match an ERC1155 order, ensuring that the supplied proof demonstrates inclusion of the tokenId in the associated merkle root.
    /// @param from The account to transfer the ERC1155 token from — this token must first be approved on the seller's AuthenticatedProxy contract.
    /// @param to The account to transfer the ERC1155 token to.
    /// @param token The ERC1155 token to transfer.
    /// @param tokenId The ERC1155 tokenId to transfer.
    /// @param amount The amount of ERC1155 tokens with the given tokenId to transfer.
    /// @param root A merkle root derived from each valid tokenId — set to 0 to indicate a collection-level or tokenId-specific order.
    /// @param proof A proof that the supplied tokenId is contained within the associated merkle root. Must be length 0 if root is not set.
    /// @return A boolean indicating a successful match and transfer.
    function matchERC1155UsingCriteria(
        address from,
        address to,
        IERC1155 token,
        uint256 tokenId,
        uint256 amount,
        bytes32 root,
        bytes32[] calldata proof
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

abstract contract Ownable {
    error AccessDenied();

    address immutable public owner;

    constructor(address newOwner) {
        owner = newOwner;
    }

    modifier onlyOwner() {
        if (address(msg.sender) != owner)
            revert AccessDenied();
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1

import { Ownable } from "./Ownable.sol";
import { SendUtils } from "./SendUtils.sol";

pragma solidity ^0.8.4;

abstract contract Recoverable is Ownable {
    function recoverEther() external onlyOwner {
        SendUtils._returnAllEth();
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

library RevertUtils {
    /// Reverts, forwarding the return data from the last external call.
    /// If there was no preceding external call, reverts with empty returndata.
    /// It's up to the caller to ensure that the preceding call actually reverted - if it did not,
    /// the return data will come from a successfull call.
    ///
    /// @dev This function writes to arbitrary memory locations, violating any assumptions the compiler
    /// might have about memory use. This may prevent it from doing some kinds of memory optimizations
    /// planned in future versions or make them unsafe. It's recommended to obtain the revert data using 
    /// the try/catch statement and rethrow it with `rawRevert()` instead.
    function forwardRevert() internal pure {
        assembly {
            returndatacopy(0, 0, returndatasize())
            revert(0, returndatasize())
        }
    }

    /// Reverts, directly setting the return data from the provided `bytes` object.
    /// Unlike the high-level `revert` statement, this allows forwarding the revert data obtained from
    /// a failed external call (high-level `revert` would wrap it in an `Error`).
    ///
    /// @dev This function is recommended over `forwardRevert()` because it does not interfere with
    /// the memory allocation mechanism used by the compiler.
    function rawRevert(bytes memory revertData) internal pure {
        assembly {
            // NOTE: `bytes` arrays in memory start with a 32-byte size slot, which is followed by data.
            let revertDataStart := add(revertData, 32)
            let revertDataEnd := add(revertDataStart, mload(revertData))
            revert(revertDataStart, revertDataEnd)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

library SendUtils {
    error EtherTransferFailed();

    function _sendEthViaCall(address payable receiver, uint amount) internal {
        if (amount > 0) {
            (bool success, ) = receiver.call{value: amount}("");
            if (!success)
                revert EtherTransferFailed();
        }
    }

    function _returnAllEth() internal {
        // NOTE: This works on the assumption that the whole balance of the contract consists of
        // the ether sent by the caller.
        // (1) This is never 100% true because anyone can send ether to it with selfdestruct or by using
        // its address as the coinbase when mining a block. Anyone doing that is doing it to their own
        // disavantage though so we're going to disregard these possibilities.
        // (2) For this to be safe we must ensure that no ether is stored in the contract long-term.
        // It's best if it has no receive function and all payable functions should ensure that they
        // use the whole balance or send back the remainder.
        _sendEthViaCall(payable(msg.sender), address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

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