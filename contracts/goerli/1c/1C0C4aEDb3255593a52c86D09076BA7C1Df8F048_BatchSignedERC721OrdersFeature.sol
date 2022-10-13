// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.15;

import "../../storage/LibCommonNftOrdersStorage.sol";
import "../../storage/LibERC721OrdersStorage.sol";
import "../interfaces/IBatchSignedERC721OrdersFeature.sol";


contract BatchSignedERC721OrdersFeature is IBatchSignedERC721OrdersFeature {

    uint256 internal constant MASK_192 = (1 << 192) - 1;
    uint256 internal constant MASK_160 = (1 << 160) - 1;
    uint256 internal constant MASK_64 = (1 << 64) - 1;
    uint256 internal constant MASK_32 = (1 << 32) - 1;
    uint256 internal constant MASK_16 = (1 << 16) - 1;

    uint256 internal constant MASK_INDEX_LIST_PART1 = ((1 << 96) - 1) << 160;
    uint256 internal constant MASK_INDEX_LIST_PART2 = ((1 << 32) - 1) << 128;

    uint256 internal constant NONCE_RANGE_LIMIT = 1 << 248;
    uint256 internal constant MAX_ERC20_AMOUNT = (1 << 224) - 1;

    // Storage ID.
    uint256 constant STORAGE_ID_COMMON_NFT_ORDERS = 4 << 128;
    uint256 constant STORAGE_ID_ERC721_ORDERS = 5 << 128;

    // Topic for ERC721SellOrderFilled.
    bytes32 internal constant _TOPIC_SELL_ORDER_FILLED = 0x9c248aa1a265aa616f707b979d57f4529bb63a4fc34dc7fc61fdddc18410f74e;

    // keccak256("")
    bytes32 internal constant _EMPTY_ARRAY_KECCAK256 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // keccak256(abi.encodePacked(
    //    "BatchSignedERC721Orders(address maker,uint256 listingTime,uint256 expiryTime,uint256 startNonce,address erc20Token,address platformFeeRecipient,BasicCollection[] basicCollections,Collection[] collections,uint256 hashNonce)",
    //    "BasicCollection(address nftAddress,bytes32 fee,bytes32[] items)",
    //    "Collection(address nftAddress,bytes32 fee,OrderItem[] items)",
    //    "OrderItem(uint256 erc20TokenAmount,uint256 nftId)"
    // ))
    bytes32 internal constant _BATCH_SIGNED_ERC721_ORDERS_TYPE_HASH = 0x2d8cbbbc696e7292c3b5beb38e1363d34ff11beb8c3456c14cb938854597b9ed;
    // keccak256("BasicCollection(address nftAddress,bytes32 fee,bytes32[] items)")
    bytes32 internal constant _BASIC_COLLECTION_TYPE_HASH = 0x12ad29288fd70022f26997a9958d9eceb6e840ceaa79b72ea5945ba87e4d33b0;
    // keccak256(abi.encodePacked(
    //    "Collection(address nftAddress,bytes32 fee,OrderItem[] items)",
    //    "OrderItem(uint256 erc20TokenAmount,uint256 nftId)"
    // ))
    bytes32 internal constant _COLLECTION_TYPE_HASH = 0xb9f488d48cec782be9ecdb74330c9c6a33c236a8022d8a91a4e4df4e81b51620;
    // keccak256("OrderItem(uint256 erc20TokenAmount,uint256 nftId)")
    bytes32 internal constant _ORDER_ITEM_TYPE_HASH = 0x5f93394997caa49a9382d44a75e3ce6a460f32b39870464866ac994f8be97afe;

    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 internal constant DOMAIN = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    // keccak256("ElementEx")
    bytes32 internal constant NAME = 0x27b14c20196091d9cd90ca9c473d3ad1523b00ddf487a9b7452a8a119a16b98c;
    // keccak256("1.0.0")
    bytes32 internal constant VERSION = 0x06c015bd22b4c69690933c1058878ebdfef31f9aaae40bbe86d8a09fe1b2972c;

    /// @dev The implementation address of this feature.
    address internal immutable _IMPL;
    /// @dev The WETH token contract.
    address internal immutable _WETH;

    constructor(address weth) {
        require(address(weth) != address(0), "INVALID_WETH_ADDRESS");
        _WETH = weth;
        _IMPL = address(this);
    }

    function fillBatchSignedERC721Order(BatchSignedERC721OrderParameter calldata /* parameter */, bytes calldata collections) external override payable {
        uint256 ethBalanceBefore;
        uint256 offsetCollectionsBytes;
        assembly {
            ethBalanceBefore := sub(selfbalance(), callvalue())
            offsetCollectionsBytes := collections.offset
        }

        // Validate order.
        bytes32 orderHash = _validateOrder(offsetCollectionsBytes);

        assembly {
            // memory[0x0 - 0x20] orderHash
            mstore(0, orderHash)

            /////////////////////////// memory[0x380 - 0x420] for delegateCall  ///////////
            // memory[0x380 - 0x3a0] erc20TokenFromDelegateCall
            // memory[0x3a0 - 0x3c0] platformFeeRecipientFromDelegateCall
            // memory[0x3c0 - 0x3e0] royaltyFeeRecipientFromDelegateCall
            mstore(0x380, 0)
            mstore(0x3a0, 0)
            mstore(0x3c0, 0)
        }

        // Fill order.
        _fillBatchSignedERC721Order(offsetCollectionsBytes);

        // Refund ETH.
        assembly {
            if eq(selfbalance(), ethBalanceBefore) {
                return(0, 0)
            }
            if gt(selfbalance(), ethBalanceBefore) {
                if iszero(call(gas(), caller(), sub(selfbalance(), ethBalanceBefore), 0, 0, 0, 0)) {
                    _revertRefundETHFailed()
                }
                return(0, 0)
            }
            _revertRefundETHFailed()

            function _revertRefundETHFailed() {
                // revert("fillBatchSignedERC721Order: failed to refund ETH.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000003166696c6c42617463685369676e65644552433732314f726465723a20)
                mstore(0x60, 0x6661696c656420746f20726566756e64204554482e0000000000000000000000)
                mstore(0x80, 0)
                revert(0, 0x84)
            }
        }
    }

    /// @param additional1 [96 bits(withdrawETHAmount) + 160 bits(erc20Token)]
    /// @param additional2 [8 bits(revertIfIncomplete) + 88 bits(unused) + 160 bits(royaltyFeeRecipient)]
    function fillBatchSignedERC721Orders(
        BatchSignedERC721OrderParameters[] calldata parameters,
        uint256 additional1,
        uint256 additional2
    ) external override payable {
        require(parameters.length > 0, "fillBatchSignedERC721Orders: invalid parameters.");

        uint256 platformFeeRecipient = parameters[0].data3 & MASK_160;
        address impl = _IMPL;
        address weth = _WETH;
        assembly {
            let ethBalanceBefore := sub(selfbalance(), callvalue())

            let withdrawETHAmount := shr(160, additional1)
            let erc20Token := and(additional1, MASK_160)
            let royaltyFeeRecipient := and(additional2, MASK_160)
            let platformFeeGlobalAccum
            let royaltyFeeGlobalAccum
            let someSuccess

            // Withdraw ETH if needed.
            if withdrawETHAmount {
                // Step1: transfer WETH from msg.sender to address(this).
                _transferERC20(weth, address(), withdrawETHAmount)

                // Step2: withdraw ETH.
                // selector for `withdraw(uint256)`.
                mstore(0, 0x2e1a7d4d)
                mstore(0x20, withdrawETHAmount)
                if iszero(call(gas(), weth, 0, 0x1c, 0x24, 0, 0)) {
                    _revertWithdrawETHFailed()
                }
            }

            /////////////////////////// memory[0 - 0x40] for delegatecall output  /////////////
            // memory[0 - 0x20] output [platformFeeGlobal]
            // memory[0x20 - 0x40] output [royaltyFeeGlobal]

            /////////////////////////// memory[0x40 - ] for delegatecall input /////////////
            // memory[0x40 - 0x60] selector for `delegateCallFillBatchSignedERC721Order(BatchSignedERC721OrderParameter,address,address,address,bytes)`
            mstore(0x40, 0xdc055ecc)
            // memory[0x60 - 0x100] parameter
            // memory[0x100 - 0x120] erc20Token
            mstore(0x100, erc20Token)
            // memory[0x120 - 0x140] platformFeeRecipient
            mstore(0x120, platformFeeRecipient)
            // memory[0x140 - 0x160] royaltyFeeRecipient
            mstore(0x140, royaltyFeeRecipient)
            // memory[0x160 - 0x180] collections.offset
            mstore(0x160, 0x120)
            // memory[0x180 - 0x1a0] collections.length
            // memory[0x1a0 - ] collections.data

            let endPtr := add(parameters.offset, mul(parameters.length, 0x20))
            for { let ptr := parameters.offset } lt(ptr, endPtr) { ptr := add(ptr, 0x20) } {
                let ptrData := add(parameters.offset, calldataload(ptr))

                // memory[0x40 - 0x60] selector for `delegateCallFillBatchSignedERC721Order`
                // memory[0x60 - 0x100] parameter
                calldatacopy(0x60, ptrData, 0xa0 /* 5 * 32*/)
                // memory[0x100 - 0x120] erc20Token
                // memory[0x120 - 0x140] platformFeeRecipient
                // memory[0x140 - 0x160] royaltyFeeRecipient
                // memory[0x160 - 0x180] collections.offset
                // memory[0x180 - 0x1a0] collections.length
                let collectionsLength := calldataload(add(ptrData, 0xc0))
                if mod(collectionsLength, 0x20) {
                    _revertInvalidCollectionsBytes()
                }
                mstore(0x180, collectionsLength)

                // memory[0x1a0 - ] collections.data
                calldatacopy(0x1a0, add(ptrData, 0xe0), collectionsLength)

                // 0x144 = 0x4(selector) + 0xa0(parameter) + 0x20(erc20Token) + 0x20(platformFeeRecipient) + 0x20(royaltyFeeRecipient) + 0x20(collections.offset) + 0x20(collections.length)
                switch delegatecall(gas(), impl, 0x5c, add(0x144, collectionsLength), 0, 0x40)
                case 0 {
                    // Check revertIfIncomplete flag if failed.
                    if byte(0, additional2) {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }
                default {
                    // Success.
                    someSuccess := 1

                    // memory[0 - 0x20] output [platformFeeGlobal]
                    // memory[0x20 - 0x40] output [royaltyFeeGlobal]
                    platformFeeGlobalAccum := add(platformFeeGlobalAccum, mload(0))
                    royaltyFeeGlobalAccum := add(royaltyFeeGlobalAccum, mload(0x20))
                }
            } // end for

            if platformFeeGlobalAccum {
                _transferERC20(erc20Token, platformFeeRecipient, platformFeeGlobalAccum)
            }

            if royaltyFeeGlobalAccum {
                _transferERC20(erc20Token, royaltyFeeRecipient, royaltyFeeGlobalAccum)
            }

            if iszero(someSuccess) {
                _revertNoOrderFilled()
            }

            // Refund ETH.
            if eq(selfbalance(), ethBalanceBefore) {
                return(0, 0)
            }
            if gt(selfbalance(), ethBalanceBefore) {
                if iszero(call(gas(), caller(), sub(selfbalance(), ethBalanceBefore), 0, 0, 0, 0)) {
                    _revertRefundETHFailed()
                }
                return(0, 0)
            }
            _revertRefundETHFailed()

            ///////////////////////////////// functions  /////////////////////////////////
            function _transferERC20(_erc20Token, _to, _amount) {
                switch _erc20Token
                case 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE {
                    if iszero(call(gas(), _to, _amount, 0, 0, 0, 0)) {
                        _revertTransferERC20Failed()
                    }
                }

                default {
                    // selector for `transferFrom(address,address,uint256)`
                    mstore(0, 0x23b872dd)
                    mstore(0x20, caller())
                    mstore(0x40, _to)
                    mstore(0x60, _amount)

                    if iszero(call(gas(), _erc20Token, 0, 0x1c, 0x64, 0, 0x20)) {
                        _revertTransferERC20Failed()
                    }

                    // Check for ERC20 success. ERC20 tokens should return a boolean, but some don't.
                    // We accept 0-length return data as success, or at least 32 bytes that starts with
                    // a 32-byte boolean true.
                    if returndatasize() {
                        if lt(returndatasize(), 0x20) {
                            _revertTransferERC20Failed()
                        }
                        if iszero(eq(mload(0), 1)) {
                            _revertTransferERC20Failed()
                        }
                    }
                }
            }

            function _revertTransferERC20Failed() {
                // revert("fillBatchSignedERC721Orders: failed to transfer ERC20.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000003666696c6c42617463685369676e65644552433732314f72646572733a)
                mstore(0x60, 0x206661696c656420746f207472616e736665722045524332302e000000000000)
                mstore(0x80, 0)
                revert(0, 0x84)
            }

            function _revertWithdrawETHFailed() {
                // revert("fillBatchSignedERC721Orders: failed to withdraw ETH.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000003466696c6c42617463685369676e65644552433732314f72646572733a)
                mstore(0x60, 0x206661696c656420746f207769746864726177204554482e0000000000000000)
                mstore(0x80, 0)
                revert(0, 0x84)
            }

            function _revertInvalidCollectionsBytes() {
                // revert("fillBatchSignedERC721Orders: invalid collectionsBytes.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000003666696c6c42617463685369676e65644552433732314f72646572733a)
                mstore(0x60, 0x20696e76616c696420636f6c6c656374696f6e7342797465732e000000000000)
                mstore(0x80, 0)
                revert(0, 0x84)
            }

            function _revertNoOrderFilled() {
                // revert("fillBatchSignedERC721Orders: no order filled.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000002d66696c6c42617463685369676e65644552433732314f72646572733a)
                mstore(0x60, 0x206e6f206f726465722066696c6c65642e000000000000000000000000000000)
                mstore(0x80, 0)
                revert(0, 0x84)
            }

            function _revertRefundETHFailed() {
                // revert("fillBatchSignedERC721Orders: failed to refund ETH.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000003266696c6c42617463685369676e65644552433732314f72646572733a)
                mstore(0x60, 0x206661696c656420746f20726566756e64204554482e00000000000000000000)
                mstore(0x80, 0)
                revert(0, 0x84)
            }
        }
    }

    // @Note `delegateCallFillBatchSignedERC721Order` is a external function, but must delegatecall from an external exchange,
    //        and should not be registered in the external exchange.
    function delegateCallFillBatchSignedERC721Order(
        BatchSignedERC721OrderParameter calldata /* parameter */,
        address erc20TokenFromDelegateCall,
        address platformFeeRecipientFromDelegateCall,
        address royaltyFeeRecipientFromDelegateCall,
        bytes calldata collections
    ) external payable {
        address impl = _IMPL;
        uint256 offsetCollectionsBytes;
        assembly {
            if eq(impl, address()) {
                // revert("delegateCallFillBatchSignedERC721Order: must delegateCall from an external exchange.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000005464656c656761746543616c6c46696c6c42617463685369676e656445)
                mstore(0x60, 0x52433732314f726465723a206d7573742064656c656761746543616c6c206672)
                mstore(0x80, 0x6f6d20616e2065787465726e616c2065786368616e67652e0000000000000000)
                mstore(0xa0, 0)
                revert(0, 0xa4)
            }

            offsetCollectionsBytes := collections.offset
        }

        // Validate order.
        bytes32 orderHash = _validateOrder(offsetCollectionsBytes);

        assembly {
            // memory[0x0 - 0x20] orderHash
            mstore(0, orderHash)

            /////////////////////////// memory[0x380 - 0x420] for delegateCall  ///////////
            // memory[0x380 - 0x3a0] erc20TokenFromDelegateCall
            // memory[0x3a0 - 0x3c0] platformFeeRecipientFromDelegateCall
            // memory[0x3c0 - 0x3e0] royaltyFeeRecipientFromDelegateCall
            mstore(0x380, erc20TokenFromDelegateCall)
            mstore(0x3a0, platformFeeRecipientFromDelegateCall)
            mstore(0x3c0, royaltyFeeRecipientFromDelegateCall)
        }

        // Fill order.
        _fillBatchSignedERC721Order(offsetCollectionsBytes);

        assembly {
            // Return platformFeeGlobal and royaltyFeeGlobal.
            // memory[0x3e0 - 0x400] platformFeeGlobal
            // memory[0x400 - 0x420] royaltyFeeGlobal
            return(0x3e0, 0x40)
        }
    }

    /// data1 [56 bits(startNonce) + 8 bits(v) + 32 bits(listingTime) + 160 bits(maker)]
    /// data2 [64 bits(taker part1) + 32 bits(expiryTime) + 160 bits(erc20Token)]
    /// data3 [96 bits(taker part2) + 160 bits(platformFeeRecipient)]
    function _fillBatchSignedERC721Order(uint256 offsetCollectionsBytes) internal {
        assembly {
            /////////////////////////// memory[0x0 - 0x1c0] for emitEvent data ////////////////////////
            // memory[0x0 - 0x20] orderHash
            // memory[0x20 - 0x40] maker
            mstore(0x20, and(calldataload(0x4), MASK_160)) // maker = data1 & MASK_160
            // memory[0x40 - 0x60] taker
            mstore(0x40, or(shl(96, shr(192, calldataload(0x24))), shr(160, calldataload(0x44)))) // taker = ((data2 >> 192) << 96) | (data3 >> 160)
            if iszero(mload(0x40)) {
                mstore(0x40, caller())
            }

            // memory[0x60 - 0x80] nonce
            // memory[0x80 - 0xa0] erc20Token
            mstore(0x80, and(calldataload(0x24), MASK_160)) // erc20Token = data2 & MASK_160
            // memory[0xa0 - 0xc0] erc20TokenAmount
            // memory[0xc0 - 0xe0] fees.offset
            mstore(0xc0, 0x120 /* 9 * 32 */)
            // memory[0xe0 - 0x100] nftAddress
            // memory[0x100 - 0x120] nftId
            // memory[0x120 - 0x140] fees.length
            // memory[0x140 - 0x1c0] fees.data

            /////////////////////////// memory[0x1c0 - 0x240] for transferERC721 //////////
            // memory[0x1c0 - 0x1e0] selector for `transferFrom(address,address,uint256)`
            mstore(0x1c0, 0x23b872dd)
            // memory[0x1e0 - 0x200] maker
            mstore(0x1e0, mload(0x20))
            // memory[0x200 - 0x220] taker
            mstore(0x200, mload(0x40))
            // memory[0x220 - 0x240] nftId

            /////////////////////////// memory[0x240 - 0x300] for nonceVector /////////////
            // Note: nonceRange = nonce >> 8
            // Note: nonceVector = LibERC721OrdersStorage.orderStatusByMaker[maker][nonceRange]
            // Note: nonceVector.slot = keccak256(nonceRange, keccak256(maker, LibERC721OrdersStorage.storageId))

            // memory[0x240 - 0x260] shouldStoreNonceVectorToStorage flag
            mstore(0x240, 0)
            // memory[0x260 - 0x280] nonceMask
            // memory[0x280 - 0x2a0] nonceVector.slot
            // memory[0x2a0 - 0x2c0] nonceVector
            // memory[0x2c0 - 0x2e0] nonceRange
            mstore(0x2c0, NONCE_RANGE_LIMIT)
            // memory[0x2e0 - 0x300] keccak256(maker, LibERC721OrdersStorage.storageId)
            mstore(0x2e0, mload(0x20))
            mstore(0x300, STORAGE_ID_ERC721_ORDERS)
            mstore(0x2e0, keccak256(0x2e0, 0x40))

            /////////////////////////// memory[0x300 - 0x380] for collection //////////////
            // memory[0x300 - 0x320] collection.head2
            // memory[0x320 - 0x340] collection.platformFeePercentage
            // memory[0x340 - 0x360] collection.royaltyFeePercentage
            // memory[0x360 - 0x380] someSuccess flag
            mstore(0x360, 0)

            /////////////////////////// memory[0x380 - 0x420] for delegateCall  ///////////
            // memory[0x380 - 0x3a0] erc20TokenFromDelegateCall
            // memory[0x3a0 - 0x3c0] platformFeeRecipientFromDelegateCall
            // memory[0x3c0 - 0x3e0] royaltyFeeRecipientFromDelegateCall
            // memory[0x3e0 - 0x400] platformFeeGlobal
            mstore(0x3e0, 0)
            // memory[0x400 - 0x420] royaltyFeeGlobal
            mstore(0x400, 0)

            /////////////////////////// memory[0x420 - 0x4a0] for transferERC20 ///////////
            // memory[0x420 - 0x440] selector for `transferFrom(address,address,uint256)`
            mstore(0x420, 0x23b872dd)
            // memory[0x440 - 0x460] msg.sender
            mstore(0x440, caller())
            // memory[0x460 - 0x480] to
            // memory[0x480 - 0x4a0] amount

            /////////////////////////// global variables /////////////////////////////////
            let nonceVectorForCheckingNonReentrant

            // collectionStartNonce = data1 >> 200
            let collectionStartNonce := shr(200, calldataload(0x4))

            // platformFeeRecipient = data3 & MASK_160
            let platformFeeRecipient := and(calldataload(0x44), MASK_160)

            // Total erc20 amount.
            let totalERC20AmountToPlatform
            let totalERC20AmountToMaker

            for { let offsetCollection := offsetCollectionsBytes } lt(offsetCollection, calldatasize()) {} {
                // memory[0xe0 - 0x100] nftAddress
                // head1 [96 bits(filledIndexList part1) + 160 bits(nftAddress)]
                mstore(0xe0, and(calldataload(offsetCollection), MASK_160)) // nftAddress = head1 & MASK_160

                // memory[0x300 - 0x320] collection.head2
                // collectionType: 0 - basicCollection, 1 - collection
                // head2 [8 bits(collectionType) + 8 bits(itemsCount) + 8 bits(filledCount) + 8 bits(unused) + 32 bits(filledIndexList part2)
                //        + 16 bits(platformFeePercentage) + 16 bits(royaltyFeePercentage) + 160 bits(royaltyFeeRecipient)]
                mstore(0x300, calldataload(add(offsetCollection, 0x20)))

                // filledIndexList [96 bits(filledIndexList part1) + 32 bits(filledIndexList part2) + 128 bits(unused)]
                // filledIndexList = (head1 & MASK_INDEX_LIST_PART1) | ((head2 >> 64) & MASK_INDEX_LIST_PART2)
                let filledIndexList := or(and(calldataload(offsetCollection), MASK_INDEX_LIST_PART1), and(shr(64, mload(0x300)), MASK_INDEX_LIST_PART2))
                let filledCount := byte(2, mload(0x300))
                let itemsCount := byte(1, mload(0x300))

                // memory[0x140 - 0x160] platformFeeRecipient
                mstore(0x140, platformFeeRecipient)
                // memory[0x320 - 0x340] collection.platformFeePercentage
                switch platformFeeRecipient
                // if (platformFeeRecipient == address(0) platformFeePercentage = 0
                case 0 { mstore(0x320, 0) }
                // else platformFeePercentage = collection.platformFeePercentage
                default { mstore(0x320, and(shr(176, mload(0x300)), MASK_16)) }

                // memory[0x180 - 0x1a0] royaltyFeeRecipient
                mstore(0x180, and(mload(0x300), MASK_160))
                // memory[0x340 - 0x360] collection.royaltyFeePercentage
                switch mload(0x180)
                // if (royaltyFeeRecipient == address(0) royaltyFeePercentage = 0
                case 0 { mstore(0x340, 0) }
                // else royaltyFeePercentage = collection.royaltyFeePercentage
                default { mstore(0x340, and(shr(160, mload(0x300)), MASK_16)) }

                // Check fees.
                if gt(add(mload(0x320), mload(0x340)), 10000) {
                    revertFeesPercentageExceedsLimit()
                }

                let totalERC20AmountToRoyalty

                // switch collectionType
                switch byte(0, mload(0x300))

                // basicCollection
                case 0 {
                    for { } filledCount { } {
                        filledCount := sub(filledCount, 1)

                        let filledIndex := byte(filledCount, filledIndexList)
                        if iszero(lt(filledIndex, itemsCount)) {
                            _revertInvalidFilledIndex()
                        }

                        // memory[0x60 - 0x80] nonce
                        // memory[0x240 - 0x260] shouldStoreNonceVectorToStorage flag
                        // memory[0x260 - 0x280] nonceMask
                        // memory[0x280 - 0x2a0] nonceVector.slot
                        // memory[0x2a0 - 0x2c0] nonceVector
                        // memory[0x2c0 - 0x2e0] nonceRange
                        // memory[0x2e0 - 0x300] keccak256(maker, LibERC721OrdersStorage.storageId)

                        // nonce = add(collectionStartNonce, filledIndex)
                        mstore(0x60, add(collectionStartNonce, filledIndex))

                        // if (nonceRange != newNonceRange)
                        if iszero(eq(mload(0x2c0), shr(8, mload(0x60)))) {
                            // Store nonce to storage if needed.
                            if mload(0x240) {
                                // Revert if reentrant.
                                if iszero(eq(nonceVectorForCheckingNonReentrant, sload(mload(0x280)))) {
                                    _revertReentrantCall()
                                }

                                // Store nonce to storage at one time.
                                sstore(mload(0x280), mload(0x2a0))
                                // Clear store nonceVector flag.
                                mstore(0x240, 0)
                            }

                            // nonceRange = nonce >> 8
                            mstore(0x2c0, shr(8, mload(0x60)))
                            // Calculate nonceVector.slot and store to memory.
                            mstore(0x280, keccak256(0x2c0, 0x40))
                            // Load nonceVector from storage.
                            nonceVectorForCheckingNonReentrant := sload(mload(0x280))
                            // Store nonceVector to memory.
                            mstore(0x2a0, nonceVectorForCheckingNonReentrant)
                        }

                        // memory[0x260 - 0x280] nonceMask
                        // nonceMask = 1 << (nonce & 0xff)
                        mstore(0x260, shl(and(mload(0x60), 0xff), 1))

                        // if order is not filled.
                        // if (nonceVector & nonceMask == 0)
                        if iszero(and(mload(0x2a0), mload(0x260))) {
                            // orderItem [96 bits(erc20TokenAmount) + 160 bits(nftId)]
                            let orderItem := calldataload(add(add(offsetCollection, 0x40), mul(filledIndex, 0x20)))

                            // memory[0xe0 - 0x100] nftAddress
                            // memory[0x1c0 - 0x1e0] selector for `transferFrom(address,address,uint256)`
                            // memory[0x1e0 - 0x200] maker
                            // memory[0x200 - 0x220] taker
                            // memory[0x220 - 0x240] nftId
                            mstore(0x220, and(orderItem, MASK_160))

                            // transferERC721
                            // 0x1dc = 0x1c0 + 28
                            if call(gas(), mload(0xe0), 0, 0x1dc, 0x64, 0, 0) {
                                // Set store nonceVector flag.
                                mstore(0x240, 1)

                                // Update nonceVector.
                                // nonceVector |= nonceMask
                                mstore(0x2a0, or(mload(0x2a0), mload(0x260)))

                                // Calculate fees.
                                // memory[0xa0 - 0xc0] erc20TokenAmount
                                mstore(0xa0, shr(160, orderItem)) // erc20TokenAmount = orderItem >> 160

                                // memory[0x140 - 0x1c0] fees.data
                                // memory[0x140 - 0x160] platformFeeRecipient
                                // memory[0x160 - 0x180] platformFeeAmount
                                // memory[0x180 - 0x1a0] royaltyFeeRecipient
                                // memory[0x1a0 - 0x1c0] royaltyFeeAmount

                                // memory[0x320 - 0x340] platformFeePercentage
                                // platformFeeAmount = erc20TokenAmount * platformFeePercentage / 10000
                                mstore(0x160, div(mul(mload(0xa0), mload(0x320)), 10000))

                                // memory[0x340 - 0x360] royaltyFeePercentage
                                // royaltyFeeAmount = erc20TokenAmount * royaltyFeePercentage / 10000
                                mstore(0x1a0, div(mul(mload(0xa0), mload(0x340)), 10000))

                                // Update total erc20 amount.
                                // totalERC20AmountToMaker += erc20TokenAmount - (platformFeeAmount + royaltyFeeAmount)
                                totalERC20AmountToMaker := add(totalERC20AmountToMaker, sub(mload(0xa0), add(mload(0x160), mload(0x1a0))))
                                // totalERC20AmountToPlatform += platformFeeAmount
                                totalERC20AmountToPlatform := add(totalERC20AmountToPlatform, mload(0x160))
                                // totalERC20AmountToRoyalty += royaltyFeeAmount
                                totalERC20AmountToRoyalty := add(totalERC20AmountToRoyalty, mload(0x1a0))

                                // Emit event
                                // memory[0 - 0x20] orderHash
                                // memory[0x20 - 0x40] maker
                                // memory[0x40 - 0x60] taker
                                // memory[0x60 - 0x80] nonce
                                // memory[0x80 - 0xa0] erc20Token
                                // memory[0xa0 - 0xc0] erc20TokenAmount
                                // memory[0xc0 - 0xe0] fees.offset
                                // memory[0xe0 - 0x100] nftAddress
                                // memory[0x100 - 0x120] nftId
                                mstore(0x100, mload(0x220))

                                // fees
                                switch platformFeeRecipient
                                case 0 {
                                    // memory[0x180 - 0x1a0] royaltyFeeRecipient
                                    switch mload(0x180)
                                    case 0 {
                                        // memory[0x120 - 0x140] fees.length
                                        mstore(0x120, 0)
                                        // emit event
                                        log1(0, 320 /* 10 * 32 */, _TOPIC_SELL_ORDER_FILLED)
                                    }
                                    default {
                                        // memory[0x120 - 0x140] fees.length
                                        mstore(0x120, 1)
                                        // Copy royaltyFeeRecipient to memory[0x140 - 0x160]
                                        mstore(0x140, mload(0x180))
                                        // Copy royaltyFeeAmount to memory[0x160 - 0x180]
                                        mstore(0x160, mload(0x1a0))
                                        // emit event
                                        log1(0, 384 /* 12 * 32 */, _TOPIC_SELL_ORDER_FILLED)
                                    }
                                }
                                default {
                                    // memory[0x180 - 0x1a0] royaltyFeeRecipient
                                    switch mload(0x180)
                                    case 0 {
                                        // memory[0x120 - 0x140] fees.length
                                        mstore(0x120, 1)
                                        // emit event
                                        log1(0, 384 /* 12 * 32 */, _TOPIC_SELL_ORDER_FILLED)
                                    }
                                    default {
                                        // memory[0x120 - 0x140] fees.length
                                        mstore(0x120, 2)
                                        // emit event
                                        log1(0, 448 /* 14 * 32 */, _TOPIC_SELL_ORDER_FILLED)
                                    }
                                }

                                // Set someSuccess flag.
                                mstore(0x360, 1)
                            }
                        }
                    } // end for
                    // Update offsetCollection.
                    offsetCollection := add(add(offsetCollection, 0x40), mul(itemsCount, 0x20))
                } // end basicCollection

                // collection
                default {
                    for { } filledCount { } {
                        filledCount := sub(filledCount, 1)

                        let filledIndex := byte(filledCount, filledIndexList)
                        if iszero(lt(filledIndex, itemsCount)) {
                            _revertInvalidFilledIndex()
                        }

                        // memory[0x60 - 0x80] nonce
                        // memory[0x240 - 0x260] shouldStoreNonceVectorToStorage flag
                        // memory[0x260 - 0x280] nonceMask
                        // memory[0x280 - 0x2a0] nonceVector.slot
                        // memory[0x2a0 - 0x2c0] nonceVector
                        // memory[0x2c0 - 0x2e0] nonceRange
                        // memory[0x2e0 - 0x300] keccak256(maker, LibERC721OrdersStorage.storageId)

                        // nonce = add(collectionStartNonce, filledIndex)
                        mstore(0x60, add(collectionStartNonce, filledIndex))

                        // if (nonceRange != newNonceRange)
                        if iszero(eq(mload(0x2c0), shr(8, mload(0x60)))) {
                            // Store nonce to storage if needed.
                            if mload(0x240) {
                                // Revert if reentrant.
                                if iszero(eq(nonceVectorForCheckingNonReentrant, sload(mload(0x280)))) {
                                    _revertReentrantCall()
                                }

                                // Store nonce to storage at one time.
                                sstore(mload(0x280), mload(0x2a0))
                                // Clear store nonceVector flag.
                                mstore(0x240, 0)
                            }

                            // nonceRange = nonce >> 8
                            mstore(0x2c0, shr(8, mload(0x60)))
                            // Calculate nonceVector.slot and store to memory.
                            mstore(0x280, keccak256(0x2c0, 0x40))
                            // Load nonceVector from storage.
                            nonceVectorForCheckingNonReentrant := sload(mload(0x280))
                            // Store nonceVector to memory.
                            mstore(0x2a0, nonceVectorForCheckingNonReentrant)
                        }

                        // memory[0x260 - 0x280] nonceMask
                        // nonceMask = 1 << (nonce & 0xff)
                        mstore(0x260, shl(and(mload(0x60), 0xff), 1))

                        // if order is not filled.
                        // if (nonceVector & nonceMask == 0)
                        if iszero(and(mload(0x2a0), mload(0x260))) {
                            // struct OrderItem {
                            //     uint256 erc20TokenAmount;
                            //     uint256 nftId;
                            // }
                            let offsetOrderItem := add(add(offsetCollection, 0x40), mul(filledIndex, 0x40))
                            if gt(calldataload(offsetOrderItem), MAX_ERC20_AMOUNT) {
                                _revertERC20AmountExceedsLimit()
                            }

                            // memory[0xe0 - 0x100] nftAddress
                            // memory[0x1c0 - 0x1e0] selector for `transferFrom(address,address,uint256)`
                            // memory[0x1e0 - 0x200] maker
                            // memory[0x200 - 0x220] taker
                            // memory[0x220 - 0x240] nftId
                            mstore(0x220, calldataload(add(offsetOrderItem, 0x20)))

                            // transferERC721
                            // 0x1dc = 0x1c0 + 28
                            if call(gas(), mload(0xe0), 0, 0x1dc, 0x64, 0, 0) {
                                // Set store nonceVector flag.
                                mstore(0x240, 1)

                                // Update nonceVector.
                                // nonceVector |= nonceMask
                                mstore(0x2a0, or(mload(0x2a0), mload(0x260)))

                                // Calculate fees.
                                // memory[0xa0 - 0xc0] erc20TokenAmount
                                mstore(0xa0, calldataload(offsetOrderItem))

                                // memory[0x140 - 0x1c0] fees.data
                                // memory[0x140 - 0x160] platformFeeRecipient
                                // memory[0x160 - 0x180] platformFeeAmount
                                // memory[0x180 - 0x1a0] royaltyFeeRecipient
                                // memory[0x1a0 - 0x1c0] royaltyFeeAmount

                                // memory[0x320 - 0x340] platformFeePercentage
                                // platformFeeAmount = erc20TokenAmount * platformFeePercentage / 10000
                                mstore(0x160, div(mul(mload(0xa0), mload(0x320)), 10000))

                                // memory[0x340 - 0x360] royaltyFeePercentage
                                // royaltyFeeAmount = erc20TokenAmount * royaltyFeePercentage / 10000
                                mstore(0x1a0, div(mul(mload(0xa0), mload(0x340)), 10000))

                                // Update total erc20 amount.
                                // totalERC20AmountToMaker += erc20TokenAmount - (platformFeeAmount + royaltyFeeAmount)
                                totalERC20AmountToMaker := add(totalERC20AmountToMaker, sub(mload(0xa0), add(mload(0x160), mload(0x1a0))))
                                // totalERC20AmountToPlatform += platformFeeAmount
                                totalERC20AmountToPlatform := add(totalERC20AmountToPlatform, mload(0x160))
                                // totalERC20AmountToRoyalty += royaltyFeeAmount
                                totalERC20AmountToRoyalty := add(totalERC20AmountToRoyalty, mload(0x1a0))

                                // Emit event
                                // memory[0 - 0x20] orderHash
                                // memory[0x20 - 0x40] maker
                                // memory[0x40 - 0x60] taker
                                // memory[0x60 - 0x80] nonce
                                // memory[0x80 - 0xa0] erc20Token
                                // memory[0xa0 - 0xc0] erc20TokenAmount
                                // memory[0xc0 - 0xe0] fees.offset
                                // memory[0xe0 - 0x100] nftAddress
                                // memory[0x100 - 0x120] nftId
                                mstore(0x100, mload(0x220))

                                // fees
                                switch platformFeeRecipient
                                case 0 {
                                    // memory[0x180 - 0x1a0] royaltyFeeRecipient
                                    switch mload(0x180)
                                    case 0 {
                                        // memory[0x120 - 0x140] fees.length
                                        mstore(0x120, 0)
                                        // emit event
                                        log1(0, 320 /* 10 * 32 */, _TOPIC_SELL_ORDER_FILLED)
                                    }
                                    default {
                                        // memory[0x120 - 0x140] fees.length
                                        mstore(0x120, 1)
                                        // Copy royaltyFeeRecipient to memory[0x140 - 0x160]
                                        mstore(0x140, mload(0x180))
                                        // Copy royaltyFeeAmount to memory[0x160 - 0x180]
                                        mstore(0x160, mload(0x1a0))
                                        // emit event
                                        log1(0, 384 /* 12 * 32 */, _TOPIC_SELL_ORDER_FILLED)
                                    }
                                }
                                default {
                                    // memory[0x180 - 0x1a0] royaltyFeeRecipient
                                    switch mload(0x180)
                                    case 0 {
                                        // memory[0x120 - 0x140] fees.length
                                        mstore(0x120, 1)
                                        // emit event
                                        log1(0, 384 /* 12 * 32 */, _TOPIC_SELL_ORDER_FILLED)
                                    }
                                    default {
                                        // memory[0x120 - 0x140] fees.length
                                        mstore(0x120, 2)
                                        // emit event
                                        log1(0, 448 /* 14 * 32 */, _TOPIC_SELL_ORDER_FILLED)
                                    }
                                }

                                // Set someSuccess flag.
                                mstore(0x360, 1)
                            }
                        }
                    } // end for
                    // Update offsetCollection.
                    offsetCollection := add(add(offsetCollection, 0x40), mul(itemsCount, 0x40))
                } // end collection

                // Update collectionStartNonce.
                // collectionStartNonce += itemsCount
                // memory[0x300 - 0x320] collection.head2
                collectionStartNonce := add(collectionStartNonce, itemsCount)

                // Pay royaltyFee together.
                if totalERC20AmountToRoyalty {
                    // memory[0x80 - 0xa0] erc20Token
                    // memory[0x180 - 0x1a0] royaltyFeeRecipient
                    // memory[0x380 - 0x3a0] erc20TokenFromDelegateCall
                    // memory[0x3c0 - 0x3e0] royaltyFeeRecipientFromDelegateCall
                    switch and(eq(mload(0x80), mload(0x380)), eq(mload(0x180), mload(0x3c0)))
                    case 1 {
                        // memory[0x400 - 0x420] royaltyFeeGlobal
                        mstore(0x400, add(mload(0x400), totalERC20AmountToRoyalty))
                    }
                    default {
                        _transferERC20(mload(0x180), totalERC20AmountToRoyalty)
                    }
                }
            } // end for

            // Store nonce to storage if needed.
            if mload(0x240) {
                // Revert if reentrant.
                if iszero(eq(nonceVectorForCheckingNonReentrant, sload(mload(0x280)))) {
                    _revertReentrantCall()
                }

                // Store nonce to storage at one time.
                // memory[0x280 - 0x2a0] nonceVector.slot
                // memory[0x2a0 - 0x2c0] nonceVector
                sstore(mload(0x280), mload(0x2a0))
            }

            // Pay to maker at one time.
            if totalERC20AmountToMaker {
                // memory[0x20 - 0x40] maker
                _transferERC20(mload(0x20), totalERC20AmountToMaker)
            }

            // Pay to platform at one time.
            if totalERC20AmountToPlatform {
                // memory[0x80 - 0xa0] erc20Token
                // memory[0x380 - 0x3a0] erc20TokenFromDelegateCall
                // memory[0x3a0 - 0x3c0] platformFeeRecipientFromDelegateCall
                switch and(eq(mload(0x80), mload(0x380)), eq(platformFeeRecipient, mload(0x3a0)))
                case 1 {
                    // memory[0x3e0 - 0x400] platformFeeGlobal
                    mstore(0x3e0, add(mload(0x3e0), totalERC20AmountToPlatform))
                }
                default {
                    _transferERC20(platformFeeRecipient, totalERC20AmountToPlatform)
                }
            }

            // Revert if none of the orders is filled.
            // memory[0x360 - 0x380] someSuccess flag
            if iszero(mload(0x360)) {
                _revertNoOrderFilled()
            }

            ///////////////////////////////// functions  /////////////////////////////////
            function _transferERC20(_to, _amount) {
                // memory[0x80 - 0xa0] erc20Token
                switch mload(0x80)
                case 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE {
                    if iszero(call(gas(), _to, _amount, 0, 0, 0, 0)) {
                        _revertTransferERC20Failed()
                    }
                }
                default {
                    // memory[0x420 - 0x440] selector for `transferFrom(address,address,uint256)`
                    // memory[0x440 - 0x460] msg.sender
                    // memory[0x460 - 0x480] to
                    mstore(0x460, _to)
                    // memory[0x480 - 0x4a0] amount
                    mstore(0x480, _amount)

                    // memory[0x80 - 0xa0] erc20Token
                    // 0x43c = 0x420 + 28
                    if iszero(call(gas(), mload(0x80), 0, 0x43c, 0x64, 0x480, 0x20)) {
                        _revertTransferERC20Failed()
                    }

                    // Check for ERC20 success. ERC20 tokens should return a boolean, but some don't.
                    // We accept 0-length return data as success, or at least 32 bytes that starts with
                    // a 32-byte boolean true.
                    if returndatasize() {
                        if lt(returndatasize(), 0x20) {
                            _revertTransferERC20Failed()
                        }
                        if iszero(eq(mload(0x480), 1)) {
                            _revertTransferERC20Failed()
                        }
                    }
                }
            }

            function revertFeesPercentageExceedsLimit() {
                // revert("fillBatchSignedERC721Order: total fees percentage exceeds the limit.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000004466696c6c42617463685369676e65644552433732314f726465723a20)
                mstore(0x60, 0x746f74616c20666565732070657263656e746167652065786365656473207468)
                mstore(0x80, 0x65206c696d69742e000000000000000000000000000000000000000000000000)
                mstore(0xa0, 0)
                revert(0, 0xa4)
            }

            function _revertInvalidFilledIndex() {
                // revert("fillBatchSignedERC721Order: invalid filledIndex.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000003066696c6c42617463685369676e65644552433732314f726465723a20)
                mstore(0x60, 0x696e76616c69642066696c6c6564496e6465782e000000000000000000000000)
                mstore(0x80, 0)
                revert(0, 0x84)
            }

            function _revertReentrantCall() {
                // revert("fillBatchSignedERC721Order: reentrant call.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000002b66696c6c42617463685369676e65644552433732314f726465723a20)
                mstore(0x60, 0x7265656e7472616e742063616c6c2e0000000000000000000000000000000000)
                mstore(0x80, 0)
                revert(0, 0x84)
            }

            function _revertERC20AmountExceedsLimit() {
                // revert("fillBatchSignedERC721Order: erc20TokenAmount exceeds limit.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000003b66696c6c42617463685369676e65644552433732314f726465723a20)
                mstore(0x60, 0x6572633230546f6b656e416d6f756e742065786365656473206c696d69742e00)
                mstore(0x80, 0)
                revert(0, 0x84)
            }

            function _revertNoOrderFilled() {
                // revert("fillBatchSignedERC721Order: no order filled.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000002c66696c6c42617463685369676e65644552433732314f726465723a20)
                mstore(0x60, 0x6e6f206f726465722066696c6c65642e00000000000000000000000000000000)
                mstore(0x80, 0)
                revert(0, 0x84)
            }

            function _revertTransferERC20Failed() {
                // revert("fillBatchSignedERC721Order: failed to transfer ERC20.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000003566696c6c42617463685369676e65644552433732314f726465723a20)
                mstore(0x60, 0x6661696c656420746f207472616e736665722045524332302e00000000000000)
                mstore(0x80, 0)
                revert(0, 0x84)
            }
        }
    }

    /// data1 [56 bits(startNonce) + 8 bits(v) + 32 bits(listingTime) + 160 bits(maker)]
    /// data2 [64 bits(taker part1) + 32 bits(expiryTime) + 160 bits(erc20Token)]
    function _validateOrder(uint256 offsetCollectionsBytes) internal view returns (bytes32 orderHash) {
        address maker;
        uint8 v;
        assembly {
            let data1 := calldataload(0x4)
            let data2 := calldataload(0x24)
            v := byte(7, data1)

            // Check for listingTime.
            // if ((data1 >> 160) & MASK_32 > block.timestamp)
            if gt(and(shr(160, data1), MASK_32), timestamp()) {
                // revert("fillBatchSignedERC721Order: failed to check for listingTime.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000003c66696c6c42617463685369676e65644552433732314f726465723a20)
                mstore(0x60, 0x6661696c656420746f20636865636b20666f72206c697374696e6754696d652e)
                mstore(0x80, 0)
                revert(0, 0x84)
            }

            // Check for expiryTime.
            // if ((data2 >> 160) & MASK_32 <= block.timestamp)
            if iszero(gt(and(shr(160, data2), MASK_32), timestamp())) {
                // revert("fillBatchSignedERC721Order: failed to check for expiryTime.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000003b66696c6c42617463685369676e65644552433732314f726465723a20)
                mstore(0x60, 0x6661696c656420746f20636865636b20666f722065787069727954696d652e00)
                mstore(0x80, 0)
                revert(0, 0x84)
            }

            // Check for erc20Token.
            if iszero(and(data2, MASK_160)) {
                // revert("fillBatchSignedERC721Order: invalid erc20Token.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000002f66696c6c42617463685369676e65644552433732314f726465723a20)
                mstore(0x60, 0x696e76616c6964206572633230546f6b656e2e00000000000000000000000000)
                mstore(0x80, 0)
                revert(0, 0x84)
            }

            // Check maker.
            maker := and(data1, MASK_160)
            if iszero(maker) {
                // revert("fillBatchSignedERC721Order: invalid maker.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000002a66696c6c42617463685369676e65644552433732314f726465723a20)
                mstore(0x60, 0x696e76616c6964206d616b65722e000000000000000000000000000000000000)
                mstore(0x80, 0)
                revert(0, 0x84)
            }
        }

        // Get order hash.
        orderHash = _getEIP712Hash(_getStructHash(offsetCollectionsBytes));

        bytes32 r;
        bytes32 s;
        assembly {
            // Must reset memory status before the `require` sentence.
            mstore(0x40, 0x80)
            mstore(0x60, 0)

            // Get r and v.
            r := calldataload(0x64)
            s := calldataload(0x84)
        }
        require(maker == ecrecover(orderHash, v, r, s), "fillBatchSignedERC721Order: failed to validate signature.");
    }

    function _getEIP712Hash(bytes32 structHash) internal view returns (bytes32 eip712Hash) {
        assembly {
            // EIP712_DOMAIN_SEPARATOR = keccak256(abi.encode(
            //     DOMAIN,
            //     NAME,
            //     VERSION,
            //     block.chainid,
            //     address(this)
            // ));
            mstore(0, DOMAIN)
            mstore(0x20, NAME)
            mstore(0x40, VERSION)
            mstore(0x60, chainid())
            mstore(0x80, address())

            // eip712Hash = keccak256(abi.encodePacked(
            //     hex"1901",
            //     EIP712_DOMAIN_SEPARATOR,
            //     structHash
            // ));
            mstore(0xa0, 0x1901000000000000000000000000000000000000000000000000000000000000)
            mstore(0xa2, keccak256(0, 0xa0))
            mstore(0xc2, structHash)
            eip712Hash := keccak256(0xa0, 0x42)
        }
    }

    /// data1 [56 bits(startNonce) + 8 bits(v) + 32 bits(listingTime) + 160 bits(maker)]
    /// data2 [64 bits(taker part1) + 32 bits(expiryTime) + 160 bits(erc20Token)]
    /// data3 [96 bits(taker part2) + 160 bits(platformFeeRecipient)]
    function _getStructHash(uint256 offsetCollectionsBytes) internal view returns (bytes32 structHash) {
        // structHash = keccak256(abi.encode(
        //     _BATCH_SIGNED_ERC721_ORDERS_TYPE_HASH, // offset: 0x0
        //     maker,       // offset: 0x20
        //     listingTime, // offset: 0x40
        //     expiryTime,  // offset: 0x60
        //     startNonce,  // offset: 0x80
        //     erc20Token,  // offset: 0xa0
        //     platformFeeRecipient,    // offset: 0xc0
        //     basicCollectionsHash,    // offset: 0xe0
        //     collectionsHash,         // offset: 0x100
        //     hashNonce    // offset: 0x120
        // ));

        // Store basicCollectionsHash to memory[0xe0] and store collectionsHash to memory[0x100].
        _storeCollectionsHashToMemory(offsetCollectionsBytes);

        assembly {
            let data1 := calldataload(0x4)
            let data2 := calldataload(0x24)
            let data3 := calldataload(0x44)
            let maker := and(data1, MASK_160)

            // _BATCH_SIGNED_ERC721_ORDERS_TYPE_HASH
            mstore(0, _BATCH_SIGNED_ERC721_ORDERS_TYPE_HASH)

            // maker
            mstore(0x20, maker)

            // listingTime = (data1 >> 160) & MASK_32
            mstore(0x40, and(shr(160, data1), MASK_32))

            // expiryTime = (data2 >> 160) & MASK_32
            mstore(0x60, and(shr(160, data2), MASK_32))

            // startNonce = data1 >> 200
            mstore(0x80, shr(200, data1))

            // erc20Token = data2 & MASK_160
            mstore(0xa0, and(data2, MASK_160))

            // platformFeeRecipient = data3 & MASK_160
            mstore(0xc0, and(data3, MASK_160))

            // 0xe0 basicCollectionsHash
            // 0x100 collectionsHash

            // 0x120 hashNonce
            // hashNonce.slot = keccak256(abi.encode(maker, STORAGE_ID_COMMON_NFT_ORDERS))
            // hashNonce = sload(hashNonce.slot)
            mstore(0x120, maker)
            mstore(0x140, STORAGE_ID_COMMON_NFT_ORDERS)
            mstore(0x120, sload(keccak256(0x120, 0x40)))

            structHash := keccak256(0, 0x140 /* 10 * 32 */)
        }
    }

    function _storeCollectionsHashToMemory(uint256 offsetCollectionsBytes) internal pure {
        assembly {
            let isBasicCollectionsEnded
            let basicCollectionsHash
            let ptrCollectionHash

            let offsetCollection := offsetCollectionsBytes
            for {} lt(offsetCollection, calldatasize()) {} {
                // head1 [96 bits(filledIndexList part1) + 160 bits(nftAddress)]
                // nftAddress = head1 & MASK_160
                let nftAddress := and(calldataload(offsetCollection), MASK_160)
                if iszero(nftAddress) {
                    _revertInvalidNftAddress()
                }

                // collectionType: 0 - basicCollection, 1 - collection
                // head2 [8 bits(collectionType) + 8 bits(itemsCount) + 8 bits(filledCount) + 8 bits(unused) + 32 bits(filledIndexList part2)
                //        + 16 bits(platformFeePercentage) + 16 bits(royaltyFeePercentage) + 160 bits(royaltyFeeRecipient)]
                let head2 := calldataload(add(offsetCollection, 0x20))

                let itemsCount := byte(1, head2)
                if iszero(itemsCount) {
                    _revertInvalidItemCount()
                }

                let filledCount := byte(2, head2)
                if or(gt(filledCount, itemsCount), gt(filledCount, 16)) {
                    _revertInvalidFilledCount()
                }

                // basicCollection
                if iszero(byte(0, head2)) {
                    if isBasicCollectionsEnded {
                        _revertInvalidCollectionsBytes()
                    }

                    // typeHash = _BASIC_COLLECTION_TYPE_HASH
                    mstore(ptrCollectionHash, _BASIC_COLLECTION_TYPE_HASH)

                    // nftAddress
                    mstore(add(ptrCollectionHash, 0x20), nftAddress)

                    // fee = head2 & MASK_192
                    mstore(add(ptrCollectionHash, 0x40), and(head2, MASK_192))

                    // itemsHash
                    let ptrItemsHash := add(ptrCollectionHash, 0x60)
                    let itemsBytesLength := mul(itemsCount, 0x20)

                    // offset: 0x0 - head1
                    //         0x20 - head2
                    //         0x40 - items.data
                    let offsetItems := add(offsetCollection, 0x40)
                    calldatacopy(ptrItemsHash, offsetItems, itemsBytesLength)

                    // Calculate and store itemsHash.
                    mstore(ptrItemsHash, keccak256(ptrItemsHash, itemsBytesLength))

                    // keccak256(abi.encode(_BASIC_COLLECTION_TYPE_HASH, nftAddress, fee, itemsHash))
                    mstore(ptrCollectionHash, keccak256(ptrCollectionHash, 0x80))

                    // Update offset.
                    ptrCollectionHash := add(ptrCollectionHash, 0x20)
                    offsetCollection := add(offsetItems, itemsBytesLength)
                    continue
                }

                // Get basicCollectionsHash.
                if iszero(isBasicCollectionsEnded) {
                    // Set flag.
                    isBasicCollectionsEnded := 1

                    switch ptrCollectionHash
                    case 0 {
                        // basicCollections is empty.
                        basicCollectionsHash := _EMPTY_ARRAY_KECCAK256
                    }
                    default {
                        // Calculate basicCollectionsHash.
                        basicCollectionsHash := keccak256(0, ptrCollectionHash)
                        ptrCollectionHash := 0
                    }
                }

                // collection
                // typeHash = _COLLECTION_TYPE_HASH
                mstore(ptrCollectionHash, _COLLECTION_TYPE_HASH)

                // nftAddress
                mstore(add(ptrCollectionHash, 0x20), nftAddress)

                // fee = head2 & MASK_192
                mstore(add(ptrCollectionHash, 0x40), and(head2, MASK_192))

                // itemsHash
                let ptrItemsHash := add(ptrCollectionHash, 0x60)
                let itemsBytesLength := mul(itemsCount, 0x40)

                // offset: 0x0 - head1
                //         0x20 - head2
                //         0x40 - items.data
                let offsetItems := add(offsetCollection, 0x40)

                // Copy items to memory [ptrItemsHash + 0x20].
                // Reserve a slot(0x20) to store _ORDER_ITEM_TYPE_HASH.
                calldatacopy(add(ptrItemsHash, 0x20), offsetItems, itemsBytesLength)

                let ptrItemHashData := ptrItemsHash
                let ptrItemEnd := add(ptrItemsHash, mul(itemsCount, 0x20))
                for { let ptrItem := ptrItemsHash } lt(ptrItem, ptrItemEnd) {} {
                    mstore(ptrItemHashData, _ORDER_ITEM_TYPE_HASH)
                    mstore(ptrItem, keccak256(ptrItemHashData, 0x60))

                    ptrItem := add(ptrItem, 0x20)
                    ptrItemHashData := add(ptrItemHashData, 0x40)
                }

                // Calculate and store itemsHash.
                mstore(ptrItemsHash, keccak256(ptrItemsHash, mul(itemsCount, 0x20)))

                // keccak256(abi.encode(_COLLECTION_TYPE_HASH, nftAddress, fee, itemsHash))
                mstore(ptrCollectionHash, keccak256(ptrCollectionHash, 0x80))

                // Update offset.
                ptrCollectionHash := add(ptrCollectionHash, 0x20)
                offsetCollection := add(offsetItems, itemsBytesLength)
            }

            // if (offsetCollection != calldatasize()) revert()
            if iszero(eq(offsetCollection, calldatasize())) {
                _revertInvalidCollectionsBytes()
            }

            switch isBasicCollectionsEnded
            // Order.collections is empty.
            case 0 {
                // Order.basicCollections is empty.
                if iszero(ptrCollectionHash) {
                    _revertInvalidCollectionsBytes()
                }

                // Store basicCollectionsHash to memory[0xe0].
                mstore(0xe0, keccak256(0, ptrCollectionHash))

                // Store collectionsHash to memory[0x100].
                mstore(0x100, _EMPTY_ARRAY_KECCAK256)
            }
            // Order.collections is not empty.
            default {
                // Store basicCollectionsHash to memory[0xe0].
                mstore(0xe0, basicCollectionsHash)

                // Store collectionsHash to memory[0x100].
                mstore(0x100, keccak256(0, ptrCollectionHash))
            }

            ///////////////////////////////// functions  /////////////////////////////////
            function _revertInvalidNftAddress() {
                // revert("fillBatchSignedERC721Order: invalid nftAddress.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000002f66696c6c42617463685369676e65644552433732314f726465723a20)
                mstore(0x60, 0x696e76616c6964206e6674416464726573732e00000000000000000000000000)
                mstore(0x80, 0)
                revert(0, 0x84)
            }

            function _revertInvalidItemCount() {
                // revert("fillBatchSignedERC721Order: invalid itemCount.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000002e66696c6c42617463685369676e65644552433732314f726465723a20)
                mstore(0x60, 0x696e76616c6964206974656d436f756e742e0000000000000000000000000000)
                mstore(0x80, 0)
                revert(0, 0x84)
            }

            function _revertInvalidFilledCount() {
                // revert("fillBatchSignedERC721Order: invalid filledCount.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000003066696c6c42617463685369676e65644552433732314f726465723a20)
                mstore(0x60, 0x696e76616c69642066696c6c6564436f756e742e000000000000000000000000)
                mstore(0x80, 0)
                revert(0, 0x84)
            }

            function _revertInvalidCollectionsBytes() {
                // revert("fillBatchSignedERC721Order: invalid collectionsBytes.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000003566696c6c42617463685369676e65644552433732314f726465723a20)
                mstore(0x60, 0x696e76616c696420636f6c6c656374696f6e7342797465732e00000000000000)
                mstore(0x80, 0)
                revert(0, 0x84)
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import "./LibStorage.sol";


library LibCommonNftOrdersStorage {

    /// @dev Storage bucket for this feature.
    struct Storage {
        /* Track per-maker nonces that can be incremented by the maker to cancel orders in bulk. */
        // The current nonce for the maker represents the only valid nonce that can be signed by the maker
        // If a signature was signed with a nonce that's different from the one stored in nonces, it
        // will fail validation.
        mapping(address => uint256) hashNonces;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.STORAGE_ID_COMMON_NFT_ORDERS;
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor.slot := storageSlot }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;

import "./LibStorage.sol";


/// @dev Storage helpers for `ERC721OrdersFeature`.
library LibERC721OrdersStorage {

    /// @dev Storage bucket for this feature.
    struct Storage {
        // maker => nonce range => order status bit vector
        mapping(address => mapping(uint248 => uint256)) orderStatusByMaker;
        // order hash => hashNonce
        mapping(bytes32 => uint256) preSigned;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.STORAGE_ID_ERC721_ORDERS;
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor.slot := storageSlot }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/


pragma solidity ^0.8.15;


interface IBatchSignedERC721OrdersFeature {

    /// @param fee [16 bits(platformFeePercentage) + 16 bits(royaltyFeePercentage) + 160 bits(royaltyFeeRecipient)].
    /// @param items [96 bits(erc20TokenAmount) + 160 bits(nftId)].
    struct BasicCollection {
        address nftAddress;
        bytes32 fee;
        bytes32[] items;
    }

    struct OrderItem {
        uint256 erc20TokenAmount;
        uint256 nftId;
    }

    /// @param fee [16 bits(platformFeePercentage) + 16 bits(royaltyFeePercentage) + 160 bits(royaltyFeeRecipient)].
    struct Collection {
        address nftAddress;
        bytes32 fee;
        OrderItem[] items;
    }

    struct BatchSignedERC721Orders {
        address maker;
        uint256 listingTime;
        uint256 expiryTime;
        uint256 startNonce;
        address erc20Token;
        address platformFeeRecipient;
        BasicCollection[] basicCollections;
        Collection[] collections;
        uint256 hashNonce;
    }

    /// @param data1 [56 bits(startNonce) + 8 bits(v) + 32 bits(listingTime) + 160 bits(maker)]
    /// @param data2 [64 bits(taker part1) + 32 bits(expiryTime) + 160 bits(erc20Token)]
    /// @param data3 [96 bits(taker part2) + 160 bits(platformFeeRecipient)]
    struct BatchSignedERC721OrderParameter {
        uint256 data1;
        uint256 data2;
        uint256 data3;
        bytes32 r;
        bytes32 s;
    }

    function fillBatchSignedERC721Order(BatchSignedERC721OrderParameter calldata parameter, bytes calldata collections) external payable;

    /// @param data1 [56 bits(startNonce) + 8 bits(v) + 32 bits(listingTime) + 160 bits(maker)]
    /// @param data2 [64 bits(taker part1) + 32 bits(expiryTime) + 160 bits(erc20Token)]
    /// @param data3 [96 bits(taker part2) + 160 bits(platformFeeRecipient)]
    struct BatchSignedERC721OrderParameters {
        uint256 data1;
        uint256 data2;
        uint256 data3;
        bytes32 r;
        bytes32 s;
        bytes collections;
    }

    /// @param additional1 [96 bits(withdrawETHAmount) + 160 bits(erc20Token)]
    /// @param additional2 [8 bits(revertIfIncomplete) + 88 bits(unused) + 160 bits(royaltyFeeRecipient)]
    function fillBatchSignedERC721Orders(
        BatchSignedERC721OrderParameters[] calldata parameters,
        uint256 additional1,
        uint256 additional2
    ) external payable;
}

// SPDX-License-Identifier: Apache-2.0
/*

  Modifications Copyright 2022 Element.Market
  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.13;


/// @dev Common storage helpers
library LibStorage {

    /// @dev What to bit-shift a storage ID by to get its slot.
    ///      This gives us a maximum of 2**128 inline fields in each bucket.
    uint256 constant STORAGE_ID_PROXY = 1 << 128;
    uint256 constant STORAGE_ID_SIMPLE_FUNCTION_REGISTRY = 2 << 128;
    uint256 constant STORAGE_ID_OWNABLE = 3 << 128;
    uint256 constant STORAGE_ID_COMMON_NFT_ORDERS = 4 << 128;
    uint256 constant STORAGE_ID_ERC721_ORDERS = 5 << 128;
    uint256 constant STORAGE_ID_ERC1155_ORDERS = 6 << 128;
    uint256 constant STORAGE_ID_REENTRANCY_GUARD = 7 << 128;
}