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
import "../interfaces/IBasicERC721OrdersFeature.sol";


/// @dev Feature for interacting with ERC721 orders.
contract BasicERC721OrdersFeature is IBasicERC721OrdersFeature {

    uint256 internal constant MASK_160 = (1 << 160) - 1;
    uint256 internal constant MASK_64 = (1 << 64) - 1;
    uint256 internal constant MASK_32 = (1 << 32) - 1;
    address internal constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // Storage ID.
    uint256 constant STORAGE_ID_COMMON_NFT_ORDERS = 4 << 128;
    uint256 constant STORAGE_ID_ERC721_ORDERS = 5 << 128;

    // Topic for ERC721SellOrderFilled.
    bytes32 internal constant _TOPIC_SELL_ORDER_FILLED = 0x9c248aa1a265aa616f707b979d57f4529bb63a4fc34dc7fc61fdddc18410f74e;

    // keccak256(""));
    bytes32 internal constant _EMPTY_ARRAY_KECCAK256 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    bytes32 internal constant _NFT_SELL_ORDER_TYPE_HASH = 0xed676c7f3e8232a311454799b1cf26e75b4abc90c9bf06c9f7e8e79fcc7fe14d;
    bytes32 internal constant _FEE_TYPE_HASH = 0xe68c29f1b4e8cce0bbcac76eb1334bdc1dc1f293a517c90e9e532340e1e94115;

    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 internal constant DOMAIN = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    // keccak256("ElementEx")
    bytes32 internal constant NAME = 0x27b14c20196091d9cd90ca9c473d3ad1523b00ddf487a9b7452a8a119a16b98c;
    // keccak256("1.0.0")
    bytes32 internal constant VERSION = 0x06c015bd22b4c69690933c1058878ebdfef31f9aaae40bbe86d8a09fe1b2972c;

    /// @dev The implementation address of this feature.
    address internal immutable _IMPL;

    constructor() {
        _IMPL = address(this);
    }

    function fillBasicERC721Order(BasicOrderParameter calldata parameter) external override payable {
        uint256 ethBalanceBefore;
        address maker;
        address taker;
        assembly {
            ethBalanceBefore := sub(selfbalance(), callvalue())

            // data1 [96 bits(ethAmount) + 160 bits(maker)]
            // maker = data1 & MASK_160
            maker := and(calldataload(0x4), MASK_160)

            // data2 [32 bits(listingTime) + 32 bits(expiryTime) + 32 bits(unused) + 160 bits(taker)]
            // taker = data2 & MASK_160
            taker := and(calldataload(0x24), MASK_160)
            if iszero(taker) {
                taker := caller()
            }
        }

        // Check order and update order status.
        _checkOrderAndUpdateOrderStatus(maker, parameter.data2, parameter.data3);

        // Validate order signature.
        bytes32 orderHash = _validateOrderSignature(maker, parameter);

        // Transfer the NFT asset to taker.
        _transferERC721AssetFrom(parameter.data3, maker, taker, parameter.nftId);

        // Transfer ETH to the maker.
        _transferEth(parameter.data1);

        // The taker pays fees.
        if (parameter.fee1 > 0) {
            _transferEth(parameter.fee1);
            if (parameter.fee2 > 0) {
                _transferEth(parameter.fee2);
            }
        }

        // Emit event.
        _emitEventSellOrderFilled(taker, orderHash);

        // Refund ETH.
        assembly {
            if eq(selfbalance(), ethBalanceBefore) {
                return(0, 0)
            }
            if gt(selfbalance(), ethBalanceBefore) {
                let success := call(gas(), caller(), sub(selfbalance(), ethBalanceBefore), 0, 0, 0, 0)
                return(0, 0)
            }
            // revert("Failed to refund ETH.")
            mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
            mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
            mstore(0x40, 0x000000154661696c656420746f20726566756e64204554482e00000000000000)
            mstore(0x60, 0)
            revert(0, 0x64)
        }
    }

    function fillBasicERC721Orders(BasicOrderParameter[] calldata parameters) external override payable {
        address _impl = _IMPL;
        assembly {
            let ethBalanceBefore := sub(selfbalance(), callvalue())
            let anySuccess

            // selector for delegateCallFillBasicERC721Order(BasicOrderParameter)
            mstore(0, 0xcb750fd800000000000000000000000000000000000000000000000000000000)

            for { let offset := parameters.offset } lt(offset, calldatasize()) { offset := add(offset, 0x100 /* 8 * 32 */) } {
                // copy parameters[i] to memory
                calldatacopy(0x4, offset, 0x100 /* 8 * 32 */)

                // 0x104 = 0x4 bytes(selector) + 0x100 bytes(parameters[i])
                switch delegatecall(gas(), _impl, 0, 0x104, 0, 0)
                case 0 {
                    // Failed.
                    // data3 [64 bits(nonce) + 8 bits(v) + 8 bits(revertIfFailed) + 16 bits(unused) + 160 bits(nftAddress)]
                    // revertIfFailed = byte(9, data3)
                    // if (revertIfFailed != 0) revert()
                    if gt(byte(9, calldataload(add(offset, 0x40))), 0) {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }
                default {
                    // Success.
                    anySuccess := 1
                }

                if lt(selfbalance(), ethBalanceBefore) {
                    // revert("Eth balance error.")
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(0x40, 0x000000124574682062616c616e6365206572726f722e00000000000000000000)
                    mstore(0x60, 0)
                    revert(0, 0x64)
                }
            }

            if iszero(anySuccess) {
                if gt(parameters.length, 0) {
                    // revert("No order filled.")
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(0x40, 0x000000104e6f206f726465722066696c6c65642e000000000000000000000000)
                    mstore(0x60, 0)
                    revert(0, 0x64)
                }
            }

            // Refund ETH.
            if eq(selfbalance(), ethBalanceBefore) {
                return(0, 0)
            }
            if gt(selfbalance(), ethBalanceBefore) {
                let success := call(gas(), caller(), sub(selfbalance(), ethBalanceBefore), 0, 0, 0, 0)
                return(0, 0)
            }
            // revert("Failed to refund ETH.")
            mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
            mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
            mstore(0x40, 0x000000154661696c656420746f20726566756e64204554482e00000000000000)
            mstore(0x60, 0)
            revert(0, 0x64)
        }
    }

    // @Note `delegateCallFillBasicERC721Order` is a external function, but must delegatecall from an external exchange,
    //        and should not be registered in the external exchange.
    function delegateCallFillBasicERC721Order(BasicOrderParameter calldata parameter) external payable {
        require(_IMPL != address(this), "Must delegatecall from an external exchange.");

        address maker;
        address taker;
        assembly {
            // data1 [96 bits(ethAmount) + 160 bits(maker)]
            // maker = data1 & MASK_160
            maker := and(calldataload(0x4), MASK_160)

            // data2 [32 bits(listingTime) + 32 bits(expiryTime) + 32 bits(unused) + 160 bits(taker)]
            // taker = data2 & MASK_160
            taker := and(calldataload(0x24), MASK_160)
            if iszero(taker) {
                taker := caller()
            }
        }

        // Check order and update order status.
        _checkOrderAndUpdateOrderStatus(maker, parameter.data2, parameter.data3);

        // Validate order signature.
        bytes32 orderHash = _validateOrderSignature(maker, parameter);

        // Transfer the NFT asset to taker.
        _transferERC721AssetFrom(parameter.data3, maker, taker, parameter.nftId);

        // Transfer ETH to the maker.
        _transferEth(parameter.data1);

        // The taker pays fees.
        if (parameter.fee1 > 0) {
            _transferEth(parameter.fee1);
            if (parameter.fee2 > 0) {
                _transferEth(parameter.fee2);
            }
        }

        // Emit event.
        _emitEventSellOrderFilled(taker, orderHash);
    }

    function _emitEventSellOrderFilled(address taker, bytes32 orderHash) internal {
        //struct Fee {
        //    address recipient;
        //    uint256 amount;
        //}
        //event ERC721SellOrderFilled(
        //    bytes32 orderHash,
        //    address maker,
        //    address taker,
        //    uint256 nonce,
        //    address erc20Token,
        //    uint256 erc20TokenAmount,
        //    Fee[] fees,
        //    address erc721Token,
        //    uint256 erc721TokenId
        //)
        assembly {
            let data1 := calldataload(0x4)
            let data3 := calldataload(0x44)

            // orderHash
            mstore(0, orderHash)

            // data1 [96 bits(ethAmount) + 160 bits(maker)]
            // maker = data1 & MASK_160
            mstore(0x20, and(data1, MASK_160))

            // taker
            mstore(0x40, taker)

            // data3 [64 bits(nonce) + 8 bits(v) + 8 bits(revertIfFailed) + 16 bits(unused) + 160 bits(nftAddress)]
            // nonce = data3 >> 192
            mstore(0x60, shr(192, data3))

            // erc20Token = NATIVE_TOKEN_ADDRESS
            mstore(0x80, NATIVE_TOKEN_ADDRESS)

            // fees.offset
            mstore(0xc0, 0x120 /* 9 * 32 */)

            // data3 [64 bits(nonce) + 8 bits(v) + 8 bits(revertIfFailed) + 16 bits(unused) + 160 bits(nftAddress)]
            // erc721Token = data3 & MASK_160
            mstore(0xe0, and(data3, MASK_160))

            // erc721TokenId = parameter.nftId
            // parameter.nftId.offset = 0x64
            calldatacopy(0x100, 0x64, 0x20)

            // data1 [96 bits(ethAmount) + 160 bits(maker)]
            // erc20TokenAmount = data1 >> 160
            let erc20TokenAmount := shr(160, data1)

            let fee1 := calldataload(0x84)
            switch fee1
            case 0 {
                // No fees.
                // Store erc20TokenAmount to memory.
                mstore(0xa0, erc20TokenAmount)
                // fees.length = 0
                mstore(0x120, 0)
                // emit event
                log1(0, 0x140, _TOPIC_SELL_ORDER_FILLED)
            }
            default {
                // fee1.recipient = fee1 & MASK_160
                mstore(0x140, and(fee1, MASK_160))
                // fee1.amount = fee1 >> 160
                mstore(0x160, shr(160, fee1))
                // erc20TokenAmount += fee1.amount
                erc20TokenAmount := add(erc20TokenAmount, mload(0x160))

                let fee2 := calldataload(0xa4)
                switch fee2
                case 0 {
                    // Only fee1.
                    // Store erc20TokenAmount to memory.
                    mstore(0xa0, erc20TokenAmount)
                    // fees.length = 1
                    mstore(0x120, 1)
                    // emit event
                    log1(0, 0x180, _TOPIC_SELL_ORDER_FILLED)
                }
                default {
                    // Pay fee1 and fee2.
                    // fee2.recipient = fee2 & MASK_160
                    mstore(0x180, and(fee2, MASK_160))
                    // fee2.amount = fee2 >> 160
                    mstore(0x1a0, shr(160, fee2))
                    // erc20TokenAmount += fee2.amount
                    mstore(0xa0, add(erc20TokenAmount, mload(0x1a0)))
                    // fees.length = 2
                    mstore(0x120, 2)
                    // emit event
                    log1(0, 0x1c0, _TOPIC_SELL_ORDER_FILLED)
                }
            }
        }
    }

    /// @param data2 [32 bits(listingTime) + 32 bits(expiryTime) + 32 bits(unused) + 160 bits(taker)]
    /// @param data3 [64 bits(nonce) + 8 bits(v) + 8 bits(revertIfFailed) + 16 bits(unused) + 160 bits(nftAddress)]
    function _checkOrderAndUpdateOrderStatus(address maker, uint256 data2, uint256 data3) internal {
        assembly {
            // Check for listingTime.
            // require((data2 >> 224) <= block.timestamp, "Failed to check for listingTime.")
            if gt(shr(224, data2), timestamp()) {
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x000000204661696c656420746f20636865636b20666f72206c697374696e6754)
                mstore(0x60, 0x696d652e00000000000000000000000000000000000000000000000000000000)
                revert(0, 0x64)
            }

            // Check for expiryTime.
            // require((data2 >> 192) & MASK_32 > block.timestamp, "Failed to check for expiryTime.")
            if iszero(gt(and(shr(192, data2), MASK_32), timestamp())) {
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000001f4661696c656420746f20636865636b20666f72206578706972795469)
                mstore(0x60, 0x6d652e0000000000000000000000000000000000000000000000000000000000)
                revert(0, 0x64)
            }

            // `orderStatusBitVector` is the order status bit vector for the maker and nonce range.
            // orderStatusBitVector = LibERC721OrdersStorage.getStorage().orderStatusByMaker[maker][nonceRange]
            // orderStatusBitVector.slot = keccak256(abi.encode(nonceRange, keccak256(abi.encode(maker, STORAGE_ID_ERC721_ORDERS)))
            mstore(0, maker)
            mstore(0x20, STORAGE_ID_ERC721_ORDERS)

            // Store nonceRange to memory 0x40
            // nonceRange = (higher 56-bits of nonce) = (higher 56-bits of data3) = data3 >> 200
            mstore(0x40, shr(200, data3))
            // Store keccak256(abi.encode(maker, STORAGE_ID_ERC721_ORDERS)) to memory 0x60
            mstore(0x60, keccak256(0, 0x40))
            // Get orderStatusBitVector.slot
            let orderStatusBitVectorSlot := keccak256(0x40, 0x40)

            // Load orderStatusBitVector from storage.
            let orderStatusBitVector := sload(orderStatusBitVectorSlot)

            // The bitvector is indexed by the lower 8 bits of the nonce.
            // data3 [64 bits(nonce) + 8 bits(v) + 8 bits(revertIfFailed) + 16 bits(unused) + 160 bits(nftAddress)]
            // flag = 1 << (lower 8-bits of nonce) = 1 << byte(7, data3)
            let flag := shl(byte(7, data3), 1)

            // Check `orderStatusByMaker` state variable to see if the order has been cancelled or previously filled.
            // require(orderStatusBitVector & flag == 0, "Failed to check order status.")
            if gt(and(orderStatusBitVector, flag), 0) {
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000001d4661696c656420746f20636865636b206f7264657220737461747573)
                mstore(0x60, 0x2e00000000000000000000000000000000000000000000000000000000000000)
                revert(0, 0x64)
            }

            // Update order status bit vector to indicate that the given order has been cancelled/filled by setting the designated bit to 1.
            // LibERC721OrdersStorage.getStorage().orderStatusByMaker[maker][nonceRange] = orderStatusBitVector | flag
            sstore(orderStatusBitVectorSlot, or(orderStatusBitVector, flag))
        }
    }

    function _validateOrderSignature(address maker, BasicOrderParameter calldata parameter) internal view returns(bytes32 orderHash) {
        // hashNonce = LibCommonNftOrdersStorage.getStorage().hashNonces[maker]
        // hashNonce.slot = keccak256(abi.encode(maker, STORAGE_ID_COMMON_NFT_ORDERS))
        uint256 hashNonce;
        assembly {
            mstore(0, maker)
            mstore(0x20, STORAGE_ID_COMMON_NFT_ORDERS)
            hashNonce := sload(keccak256(0, 0x40))
        }

        // Get order hash.
        orderHash = _getEIP712Hash(
            _getStructHash(
                _getFeesHash(
                    parameter.fee1,
                    parameter.fee2
                ),
                hashNonce
            )
        );

        // Must reset memory status before the require() sentence.
        assembly {
            mstore(0x40, 0x80)
            mstore(0x60, 0)
        }

        // Check for the order maker.
        require(maker != address(0), "Invalid maker: order.maker should not be address(0).");

        // Validate order signature.
        // data3 [64 bits(nonce) + 8 bits(v) + 8 bits(revertIfFailed) + 16 bits(unused) + 160 bits(nftAddress)]
        // v = uint8(parameter.data3 >> 184)
        require(maker == ecrecover(orderHash, uint8(parameter.data3 >> 184), parameter.r, parameter.s), "Failed to validate signature.");
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

    function _getStructHash(bytes32 feesHash, uint256 hashNonce) internal pure returns (bytes32 structHash) {
        // Hash in place, equivalent to:
        // structHash = keccak256(abi.encode(
        //     _NFT_SELL_ORDER_TYPE_HASH,
        //     order.maker,
        //     order.taker,
        //     order.expiry,
        //     order.nonce,
        //     order.erc20Token,
        //     order.erc20TokenAmount,
        //     feesHash,
        //     order.nft,
        //     order.nftId,
        //     hashNonce
        // ));
        assembly {
            let data1 := calldataload(0x4)
            let data3 := calldataload(0x44)

            // _NFT_SELL_ORDER_TYPE_HASH
            mstore(0, _NFT_SELL_ORDER_TYPE_HASH)

            // data1 [96 bits(ethAmount) + 160 bits(maker)]
            // order.maker = (data1 & MASK_160)
            mstore(0x20, and(data1, MASK_160))

            // order.taker = address(0)
            mstore(0x40, 0)

            // data2 [32 bits(listingTime) + 32 bits(expiryTime) + 32 bits(unused) + 160 bits(taker)]
            // order.expiry = [32 bits(listingTime) + 32 bits(expiryTime)] = data2 >> 192
            mstore(0x60, shr(192, calldataload(0x24)))

            // data3 [64 bits(nonce) + 8 bits(v) + 8 bits(revertIfFailed) + 16 bits(unused) + 160 bits(nftAddress)]
            // order.nonce = data3 >> 192
            mstore(0x80, shr(192, data3))

            // order.erc20Token = NATIVE_TOKEN_ADDRESS
            mstore(0xa0, NATIVE_TOKEN_ADDRESS)

            // data1 [96 bits(ethAmount) + 160 bits(maker)]
            // order.erc20TokenAmount = data1 >> 160
            mstore(0xc0, shr(160, data1))

            // feesHash
            mstore(0xe0, feesHash)

            // data3 [64 bits(nonce) + 8 bits(v) + 8 bits(revertIfFailed) + 16 bits(unused) + 160 bits(nftAddress)]
            // order.nft = data3 & MASK_160
            mstore(0x100, and(data3, MASK_160))

            // order.nftId = parameter.nftId
            // parameter.nftId.offset = 0x64
            calldatacopy(0x120, 0x64, 0x20)

            // hashNonce
            mstore(0x140, hashNonce)

            // Get structHash
            structHash := keccak256(0, 0x160 /* 11 * 32 */ )
        }
    }

    function _getFeesHash(uint256 fee1, uint256 fee2) internal pure returns (bytes32 feesHash) {
        assembly {
            switch fee1
            case 0 {
                // No fees.
                feesHash := _EMPTY_ARRAY_KECCAK256
            }
            default {
                mstore(0, _FEE_TYPE_HASH)
                // fee1.recipient
                mstore(0x20, and(MASK_160, fee1))
                // fee1.amount
                mstore(0x40, shr(160, fee1))
                // fee1.feeData
                mstore(0x60, _EMPTY_ARRAY_KECCAK256)
                // store feeStructHash1 into memory 0x80
                mstore(0x80, keccak256(0, 0x80))

                switch fee2
                case 0 {
                    // Only fee1.
                    // feesHash = keccak256(feeStructHash1)
                    feesHash := keccak256(0x80, 0x20)
                }
                default {
                    // Pay fee1 and fee2.
                    // fee2.recipient
                    mstore(0x20, and(MASK_160, fee2))
                    // fee2.amount
                    mstore(0x40, shr(160, fee2))
                    // store feeStructHash2 into memory 0xa0
                    mstore(0xa0, keccak256(0, 0x80))
                    // feesHash = keccak256(feeStructHash1 + feeStructHash2)
                    feesHash := keccak256(0x80, 0x40)
                }
            }
        }
    }

    function _transferERC721AssetFrom(uint256 nftAddress, address from, address to, uint256 nftId) internal {
        assembly {
            // selector for transferFrom(address,address,uint256)
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(0x04, from)
            mstore(0x24, to)
            mstore(0x44, nftId)
            if iszero(call(gas(), and(nftAddress, MASK_160), 0, 0, 0x64, 0, 0)) {
                // revert("Failed to transfer ERC721.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x0000001a4661696c656420746f207472616e73666572204552433732312e0000)
                mstore(0x60, 0)
                revert(0, 0x64)
            }
        }
    }

    /// @param data [96 bits(ethAmount) + 160 bits(recipient)]
    function _transferEth(uint256 data) internal {
        assembly {
            let ethAmount := shr(160, data)
            if gt(ethAmount, 0) {
                if iszero(call(gas(), and(data, MASK_160), ethAmount, 0, 0, 0, 0)) {
                    // revert("Failed to transfer ETH.")
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(0x40, 0x000000174661696c656420746f207472616e73666572204554482e0000000000)
                    mstore(0x60, 0)
                    revert(0, 0x64)
                }
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


interface IBasicERC721OrdersFeature {

    /// @param data1 [96 bits(ethAmount) + 160 bits(maker)]
    /// @param data2 [32 bits(listingTime) + 32 bits(expiryTime) + 32 bits(unused) + 160 bits(taker)]
    /// @param data3 [64 bits(nonce) + 8 bits(v) + 8 bits(revertIfFailed) + 16 bits(unused) + 160 bits(nftAddress)]
    /// @param fee1 [96 bits(ethAmount) + 160 bits(recipient)]
    /// @param fee2 [96 bits(ethAmount) + 160 bits(recipient)]
    struct BasicOrderParameter {
        uint256 data1;
        uint256 data2;
        uint256 data3;
        uint256 nftId;
        uint256 fee1;
        uint256 fee2;
        bytes32 r;
        bytes32 s;
    }

    function fillBasicERC721Order(BasicOrderParameter calldata parameter) external payable;

    function fillBasicERC721Orders(BasicOrderParameter[] calldata parameters) external payable;
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
}