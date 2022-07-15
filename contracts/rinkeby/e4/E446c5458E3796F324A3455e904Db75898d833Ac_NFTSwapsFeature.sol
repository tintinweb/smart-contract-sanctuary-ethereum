// SPDX-License-Identifier: Apache-2.0
/*

  CopyrightCopyright 2022 Element.Market Intl.

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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/INFTSwapsFeature.sol";
import "../../fixins/FixinEIP712.sol";
import "../../fixins/FixinTokenSpender.sol";
import "../../fixins/FixinERC721Spender.sol";
import "../../fixins/FixinERC1155Spender.sol";
import "../../storage/LibCommonNftOrdersStorage.sol";
import "../../storage/LibNFTSwapsStorage.sol";
import "../libs/LibSignature.sol";
import "../libs/LibNFTSwap.sol";

contract NFTSwapsFeature is INFTSwapsFeature, FixinEIP712, FixinTokenSpender, FixinERC721Spender, FixinERC1155Spender {

    /// @dev The implementation address of this feature.
    address internal immutable _implementation;

    constructor() {
        // Remember this feature's original address.
        _implementation = address(this);
    }

    function fillNFTSwapOrder(LibNFTSwap.NFTSwapOrder memory order, LibSignature.Signature memory signature, address taker) public override payable {
        uint256 ethBalanceBefore = address(this).balance - msg.value;

        _fillNFTSwapOrder(order, signature, taker == address(0) ? msg.sender : taker);

        if (address(this).balance != ethBalanceBefore) {
            // Refund
            _transferEth(payable(msg.sender), address(this).balance - ethBalanceBefore);
        }
    }

    function fillNFTSwapOrderEx(
        LibNFTSwap.NFTSwapOrder memory order,
        LibSignature.Signature memory signature,
        address taker,
        uint256[] calldata ids
    ) public override payable {
        uint256 ethBalanceBefore = address(this).balance - msg.value;

        _fillNFTSwapOrderEx(order, signature, taker == address(0) ? msg.sender : taker, ids);

        if (address(this).balance != ethBalanceBefore) {
            // Refund
            _transferEth(payable(msg.sender), address(this).balance - ethBalanceBefore);
        }
    }

    function batchFillNFTSwapOrders(
        LibNFTSwap.NFTSwapOrder[] memory orders,
        LibSignature.Signature[] memory signatures,
        address taker,
        bool revertIfIncomplete
    ) public override payable returns (bool[] memory successes) {
        // Array length must match.
        uint256 length = orders.length;
        require(length == signatures.length, "ARRAY_LENGTH_MISMATCH");

        if (taker == address(0)) {
            taker = msg.sender;
        }

        successes = new bool[](length);
        uint256 ethBalanceBefore = address(this).balance - msg.value;

        if (revertIfIncomplete) {
            for (uint256 i = 0; i < length; i++) {
                _fillNFTSwapOrder(orders[i], signatures[i], taker);
                successes[i] = true;
            }
        } else {
            for (uint256 i = 0; i < length; i++) {
                (successes[i], ) = _implementation.delegatecall(
                    abi.encodeWithSelector(this.fillNFTSwapOrderFromProxy.selector, orders[i], signatures[i], taker)
                );
            }
        }

        // Refund
        _transferEth(payable(msg.sender), address(this).balance - ethBalanceBefore);
    }

    function batchFillNFTSwapOrdersEx(
        LibNFTSwap.NFTSwapOrder[] memory orders,
        LibSignature.Signature[] memory signatures,
        address[] calldata takers,
        uint256[][] calldata ids,
        bool revertIfIncomplete
    ) public override payable returns (bool[] memory successes) {
        // All array length must match.
        uint256 length = orders.length;
        require(length == signatures.length && length == takers.length && length == ids.length, "ARRAY_LENGTH_MISMATCH");

        successes = new bool[](length);
        uint256 ethBalanceBefore = address(this).balance - msg.value;

        if (revertIfIncomplete) {
            for (uint256 i = 0; i < length; i++) {
                _fillNFTSwapOrderEx(orders[i], signatures[i], takers[i] == address(0) ? msg.sender : takers[i], ids[i]);
                successes[i] = true;
            }
        } else {
            for (uint256 i = 0; i < length; i++) {
                (successes[i], ) = _implementation.delegatecall(
                    abi.encodeWithSelector(
                        this.fillNFTSwapOrderExFromProxy.selector, orders[i], signatures[i], takers[i] == address(0) ? msg.sender : takers[i], ids[i]
                    )
                );
            }
        }

        // Refund
        _transferEth(payable(msg.sender), address(this).balance - ethBalanceBefore);
    }

    function fillNFTSwapOrderFromProxy(LibNFTSwap.NFTSwapOrder memory order, LibSignature.Signature memory signature, address taker) external payable {
        require(_implementation != address(this), "MUST_CALL_FROM_PROXY");
        _fillNFTSwapOrder(order, signature, taker);
    }

    function fillNFTSwapOrderExFromProxy(LibNFTSwap.NFTSwapOrder memory order, LibSignature.Signature memory signature, address taker, uint256[] calldata ids) external payable {
        require(_implementation != address(this), "MUST_CALL_FROM_PROXY");
        _fillNFTSwapOrderEx(order, signature, taker, ids);
    }

    function cancelNFTSwapOrder(uint256 orderNonce) public override {
        _updateOrderState(msg.sender, orderNonce);
        emit NFTSwapOrderCancelled(msg.sender, orderNonce);
    }

    function preSignNFTSwapOrder(LibNFTSwap.NFTSwapOrder memory order) public override {
        require(order.maker == msg.sender, "ONLY_MAKER");

        uint256 hashNonce = LibCommonNftOrdersStorage.getStorage().hashNonces[order.maker];
        bytes32 orderHash = getNFTSwapOrderHash(order);
        LibNFTSwapsStorage.getStorage().preSigned[orderHash] = (hashNonce + 1);

        emit NFTSwapOrderPreSigned(
            orderHash,
            order.maker,
            order.taker,
            order.extra,
            order.makerPayItems,
            order.takerPayItems
        );
    }

    function getNFTSwapOrderHash(LibNFTSwap.NFTSwapOrder memory order) public override view returns (bytes32) {
        return _getEIP712Hash(
            LibNFTSwap.getNFTSwapOrderStructHash(order, LibCommonNftOrdersStorage.getStorage().hashNonces[order.maker])
        );
    }

    function getNFTSwapOrderStatus(LibNFTSwap.NFTSwapOrder memory order) public override view returns (LibNFTSwap.OrderStatus) {
        // Check for listingTime.
        // Gas Optimize, listingTime only used in rare cases.
        if (order.extra & 0xffffffff00000000 > 0) {
            if ((order.extra >> 32) & 0xffffffff > block.timestamp) {
                return LibNFTSwap.OrderStatus.INVALID;
            }
        }

        // Check for extraTime.
        if (order.extra & 0xffffffff <= block.timestamp) {
            return LibNFTSwap.OrderStatus.EXPIRED;
        }

        // Check `orderStatusByMaker` state variable to see if the order
        // has been cancelled or previously filled.
        LibNFTSwapsStorage.Storage storage stor = LibNFTSwapsStorage.getStorage();

        // `orderStatusByMaker` is indexed by maker and nonce.
        uint256 nonce = (order.extra >> 64) & 0xffffffffffffffff;
        uint256 orderStatusBitVector = stor.orderStatusByMaker[order.maker][uint248(nonce >> 8)];

        // The bitvector is indexed by the lower 8 bits of the nonce.
        uint256 flag = 1 << (nonce & 255);

        // If the designated bit is set, the order has been cancelled or
        // previously filled, so it is now unfillable.
        if (orderStatusBitVector & flag != 0) {
            return LibNFTSwap.OrderStatus.UNFILLABLE;
        }

        // Otherwise, the order is fillable.
        return LibNFTSwap.OrderStatus.FILLABLE;
    }

    function validateNFTSwapOrderSignature(LibNFTSwap.NFTSwapOrder calldata order, LibSignature.Signature calldata signature) public override view {
        _validateOrderSignature(getNFTSwapOrderHash(order), signature, order.maker);
    }

    function _fillNFTSwapOrder(LibNFTSwap.NFTSwapOrder memory order, LibSignature.Signature memory signature, address taker) internal {
        // Validate order and update state.
        bytes32 orderHash = _validateOrderAndUpdateState(order, signature, taker);

        // Maker pay.
        _payItemsByMaker(order.maker, taker, order.makerPayItems);

        // Taker pay.
        _payItemsByTaker(taker, order.takerPayItems);

        // Emit an event signifying that the order has been filled.
        emit NFTSwapOrderFilled(
            orderHash,
            order.maker,
            taker,
            order.makerPayItems,
            order.takerPayItems
        );
    }

    function _fillNFTSwapOrderEx(LibNFTSwap.NFTSwapOrder memory order, LibSignature.Signature memory signature, address taker, uint256[] calldata ids) internal {
        // Validate order and update state.
        bytes32 orderHash = _validateOrderAndUpdateState(order, signature, taker);

        // Maker pay.
        _payItemsByMaker(order.maker, taker, order.makerPayItems);

        // Taker pay.
        _payItemsByTakerEx(taker, order.takerPayItems, ids);

        // Emit an event signifying that the order has been filled.
        emit NFTSwapOrderFilled(
            orderHash,
            order.maker,
            taker,
            order.makerPayItems,
            order.takerPayItems
        );
    }

    function _validateOrderAndUpdateState(LibNFTSwap.NFTSwapOrder memory order, LibSignature.Signature memory signature, address taker) internal returns (bytes32 orderHash) {
        // Taker must match the order taker, if one is specified.
        require(order.taker == address(0) || order.taker == taker, "_validateOrder/ONLY_TAKER");

        // Check that the order is valid and has not expired, been cancelled, or been filled.
        require(getNFTSwapOrderStatus(order) == LibNFTSwap.OrderStatus.FILLABLE, "_validateOrder/ORDER_NOT_FILL");

        // Check the signature.
        orderHash = getNFTSwapOrderHash(order);
        _validateOrderSignature(orderHash, signature, order.maker);

        // Update the order state.
        _updateOrderState(order.maker, (order.extra >> 64) & 0xffffffffffffffff);
    }

    function _validateOrderSignature(bytes32 orderHash, LibSignature.Signature memory signature, address maker) internal view {
        if (signature.signatureType == LibSignature.SignatureType.PRESIGNED) {
            require(LibNFTSwapsStorage.getStorage().preSigned[orderHash] == LibCommonNftOrdersStorage.getStorage().hashNonces[maker] + 1, "PRESIGNED_INVALID_SIGNER");
        } else {
            require(maker != address(0) && maker == ecrecover(orderHash, signature.v, signature.r, signature.s), "INVALID_SIGNER_ERROR");
        }
    }

    function _updateOrderState(address maker, uint256 nonce) internal {
        // The bitvector is indexed by the lower 8 bits of the nonce.
        uint256 flag = 1 << (nonce & 255);
        // Update order status bit vector to indicate that the given order
        // has been cancelled/filled by setting the designated bit to 1.
        LibNFTSwapsStorage.getStorage().orderStatusByMaker[maker][uint248(nonce >> 8)] |= flag;
    }

    function _payItemsByMaker(address maker, address taker, LibNFTSwap.MakerPayItem[] memory items) internal {
        uint256 length = items.length;
        for (uint256 i = 0; i < length; ++i) {
            LibNFTSwap.MakerPayItem memory item = items[i];
            if (item.itemType == LibNFTSwap.ItemType.ERC721) {
                // Transfer ERC721 token from maker to taker.
                require(item.amount == 1, "_payItemsByMaker/INVALID_ERC721_AMOUNT");
                _transferERC721AssetFrom(item.token, maker, taker, item.id);
            } else if (item.itemType == LibNFTSwap.ItemType.ERC20) {
                // Transfer ERC20 token from maker to taker.
                require(item.id == 0, "_payItemsByMaker/INVALID_ERC20_ID");
                require(item.amount > 0, "_payItemsByMaker/INVALID_ERC20_AMOUNT");
                _transferERC20TokensFrom(IERC20(item.token), maker, taker, item.amount);
            } else if (item.itemType == LibNFTSwap.ItemType.ERC1155) {
                // Transfer ERC1155 token from maker to taker.
                require(item.amount > 0, "_payItemsByMaker/INVALID_ERC1155_AMOUNT");
                _transferERC1155AssetFrom(item.token, maker, taker, item.id, item.amount);
            } else {
                revert("_payItemsByMaker/INVALID_ITEM_TYPE");
            }
        }
    }

    function _payItemsByTaker(address taker, LibNFTSwap.TakerPayItem[] memory items) internal {
        uint256 length = items.length;
        for (uint256 i = 0; i < length; ++i) {
            _payItemByTaker(taker, items[i]);
        }
    }

    function _payItemByTaker(address taker, LibNFTSwap.TakerPayItem memory item) internal {
        if (item.itemType == LibNFTSwap.ItemType.ERC721) {
            // Transfer ERC721 token from taker to recipient.
            require(item.amount == 1, "_payItemByTaker/INVALID_ERC721_AMOUNT");
            _transferERC721AssetFrom(item.token, taker, item.recipient, item.id);
        } else if (item.itemType == LibNFTSwap.ItemType.NATIVE) {
            // Transfer NATIVE token to recipient.
            require(item.token == address(0), "_payItemByTaker/INVALID_NATIVE_TOKEN");
            require(item.id == 0, "_payItemByTaker/INVALID_NATIVE_ID");
            require(item.amount > 0, "_payItemByTaker/INVALID_NATIVE_AMOUNT");
            _transferEth(item.recipient, item.amount);
        } else if (item.itemType == LibNFTSwap.ItemType.ERC20) {
            // Transfer ERC20 token from taker to recipient.
            require(item.id == 0, "_payItemByTaker/INVALID_ERC20_ID");
            require(item.amount > 0, "_payItemByTaker/INVALID_ERC20_AMOUNT");
            _transferERC20TokensFrom(IERC20(item.token), taker, item.recipient, item.amount);
        } else if (item.itemType == LibNFTSwap.ItemType.ERC1155) {
            // Transfer ERC1155 token from taker to recipient.
            require(item.amount > 0, "_payItemByTaker/INVALID_ERC1155_AMOUNT");
            _transferERC1155AssetFrom(item.token, taker, item.recipient, item.id, item.amount);
        } else {
            revert("_payItemByTaker/INVALID_ITEM_TYPE");
        }
    }

    function _payItemsByTakerEx(address taker, LibNFTSwap.TakerPayItem[] memory items, uint256[] calldata ids) internal {
        uint256 length = items.length;
        for (uint256 i = 0; i < length; ++i) {
            LibNFTSwap.TakerPayItem memory item = items[i];
            if (item.itemType == LibNFTSwap.ItemType.ERC721_WITH_COLLECTION_BASED) {
                // Transfer ERC721 token from taker to recipient.
                require(i < ids.length, "_payItemsByTaker/INVALID_IDS");
                require(item.id == 0, "_payItemsByTaker/INVALID_ERC721_ID");
                require(item.amount == 1, "_payItemsByTaker/INVALID_ERC721_AMOUNT");
                item.id = ids[i];
                _transferERC721AssetFrom(item.token, taker, item.recipient, item.id);
            } else if (item.itemType == LibNFTSwap.ItemType.ERC721_WITH_COLLECTION_BASED) {
                // Transfer ERC1155 token from taker to recipient.
                require(i < ids.length, "_payItemsByTaker/INVALID_IDS");
                require(item.id == 0, "_payItemsByTaker/INVALID_ERC1155_ID");
                require(item.amount > 0, "_payItemsByTaker/INVALID_ERC1155_AMOUNT");
                item.id = ids[i];
                _transferERC1155AssetFrom(item.token, taker, item.recipient, item.id, item.amount);
            } else {
                _payItemByTaker(taker, item);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: Apache-2.0
/*

  CopyrightCopyright 2022 Element.Market Intl.

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

import "../libs/LibSignature.sol";
import "../libs/LibNFTSwap.sol";

interface INFTSwapsFeature {

    event NFTSwapOrderFilled(
        bytes32 orderHash,
        address indexed maker,
        address taker,
        LibNFTSwap.MakerPayItem[] makerPayItems,
        LibNFTSwap.TakerPayItem[] takerPayItems
    );

    event NFTSwapOrderCancelled(address maker, uint256 nonce);

    event NFTSwapOrderPreSigned(
        bytes32 orderHash,
        address maker,
        address taker,
        uint256 extra,
        LibNFTSwap.MakerPayItem[] makerPayItems,
        LibNFTSwap.TakerPayItem[] takerPayItems
    );

    function fillNFTSwapOrder(
        LibNFTSwap.NFTSwapOrder calldata order,
        LibSignature.Signature calldata signature,
        address taker
    ) external payable;

    function fillNFTSwapOrderEx(
        LibNFTSwap.NFTSwapOrder calldata order,
        LibSignature.Signature calldata signature,
        address taker,
        uint256[] calldata ids
    ) external payable;

    function batchFillNFTSwapOrders(
        LibNFTSwap.NFTSwapOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures,
        address taker,
        bool revertIfIncomplete
    ) external payable returns (bool[] memory successes);

    function batchFillNFTSwapOrdersEx(
        LibNFTSwap.NFTSwapOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures,
        address[] calldata takers,
        uint256[][] calldata ids,
        bool revertIfIncomplete
    ) external payable returns (bool[] memory successes);

    function cancelNFTSwapOrder(uint256 orderNonce) external;

    function preSignNFTSwapOrder(LibNFTSwap.NFTSwapOrder calldata order) external;

    function getNFTSwapOrderHash(LibNFTSwap.NFTSwapOrder calldata order) external view returns (bytes32);

    function getNFTSwapOrderStatus(LibNFTSwap.NFTSwapOrder calldata order) external view returns (LibNFTSwap.OrderStatus);

    function validateNFTSwapOrderSignature(LibNFTSwap.NFTSwapOrder calldata order, LibSignature.Signature calldata signature) external view;
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


/// @dev EIP712 helpers for features.
abstract contract FixinEIP712 {

    bytes32 private constant DOMAIN = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant NAME = keccak256("ElementEx");
    bytes32 private constant VERSION = keccak256("1.0.0");
    uint256 private immutable CHAIN_ID;

    constructor() {
        uint256 chainId;
        assembly { chainId := chainid() }
        CHAIN_ID = chainId;
    }

    function _getEIP712Hash(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(hex"1901", keccak256(abi.encode(DOMAIN, NAME, VERSION, CHAIN_ID, address(this))), structHash));
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";


/// @dev Helpers for moving tokens around.
abstract contract FixinTokenSpender {

    // Mask of the lower 20 bytes of a bytes32.
    uint256 constant private ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    /// @dev Transfers ERC20 tokens from `owner` to `to`.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20TokensFrom(IERC20 token, address owner, address to, uint256 amount) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), amount)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success,                             // call itself succeeded
                or(
                    iszero(rdsize),                  // no return data, or
                    and(
                        iszero(lt(rdsize, 32)),      // at least 32 bytes
                        eq(mload(ptr), 1)            // starts with uint256(1)
                    )
                )
            )
        }
        require(success != 0, "_transferERC20/TRANSFER_FAILED");
    }

    /// @dev Transfers ERC20 tokens from ourselves to `to`.
    /// @param token The token to spend.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20Tokens(IERC20 token, address to, uint256 amount) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transfer(address,uint256)
            mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x24), amount)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x44, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success,                             // call itself succeeded
                or(
                    iszero(rdsize),                  // no return data, or
                    and(
                        iszero(lt(rdsize, 32)),      // at least 32 bytes
                        eq(mload(ptr), 1)            // starts with uint256(1)
                    )
                )
            )
        }
        require(success != 0, "_transferERC20/TRANSFER_FAILED");
    }


    /// @dev Transfers some amount of ETH to the given recipient and
    ///      reverts if the transfer fails.
    /// @param recipient The recipient of the ETH.
    /// @param amount The amount of ETH to transfer.
    function _transferEth(address payable recipient, uint256 amount) internal {
        if (amount > 0) {
            (bool success,) = recipient.call{value: amount}("");
            require(success, "_transferEth/TRANSFER_FAILED");
        }
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


/// @dev Helpers for moving ERC721 assets around.
abstract contract FixinERC721Spender {

    // Mask of the lower 20 bytes of a bytes32.
    uint256 constant private ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    /// @dev Transfers an ERC721 asset from `owner` to `to`.
    /// @param token The address of the ERC721 token contract.
    /// @param owner The owner of the asset.
    /// @param to The recipient of the asset.
    /// @param tokenId The token ID of the asset to transfer.
    function _transferERC721AssetFrom(address token, address owner, address to, uint256 tokenId) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), tokenId)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, 0, 0)
        }
        require(success != 0, "_transferERC721/TRANSFER_FAILED");
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


/// @dev Helpers for moving ERC1155 assets around.
abstract contract FixinERC1155Spender {

    // Mask of the lower 20 bytes of a bytes32.
    uint256 constant private ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    /// @dev Transfers an ERC1155 asset from `owner` to `to`.
    /// @param token The address of the ERC1155 token contract.
    /// @param owner The owner of the asset.
    /// @param to The recipient of the asset.
    /// @param tokenId The token ID of the asset to transfer.
    /// @param amount The amount of the asset to transfer.
    function _transferERC1155AssetFrom(
        address token,
        address owner,
        address to,
        uint256 tokenId,
        uint256 amount
    )
        internal
    {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for safeTransferFrom(address,address,uint256,uint256,bytes)
            mstore(ptr, 0xf242432a00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), tokenId)
            mstore(add(ptr, 0x64), amount)
            mstore(add(ptr, 0x84), 0xa0)
            mstore(add(ptr, 0xa4), 0)

            success := call(
                gas(),
                and(token, ADDRESS_MASK),
                0,
                ptr,
                0xc4,
                0,
                0
            )
        }
        require(success != 0, "_transferERC1155/TRANSFER_FAILED");
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


/// @dev Storage helpers for `LibNFTSwapStorage`.
library LibNFTSwapsStorage {

    /// @dev Storage bucket for this feature.
    struct Storage {
        // maker => nonce range => order status bit vector
        mapping(address => mapping(uint248 => uint256)) orderStatusByMaker;
        // order hash => hashNonce
        mapping(bytes32 => uint256) preSigned;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.STORAGE_ID_NFT_SWAPS;
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

/// @dev A library for validating signatures.
library LibSignature {

    /// @dev Allowed signature types.
    enum SignatureType {
        EIP712,
        PRESIGNED
    }

    /// @dev Encoded EC signature.
    struct Signature {
        // How to validate the signature.
        SignatureType signatureType;
        // EC Signature data.
        uint8 v;
        // EC Signature data.
        bytes32 r;
        // EC Signature data.
        bytes32 s;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  CopyrightCopyright 2022 Element.Market Intl.

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

library LibNFTSwap {

    enum OrderStatus {
        INVALID,
        FILLABLE,
        UNFILLABLE,
        EXPIRED
    }

    // prettier-ignore
    enum ItemType {
        // 0: ETH on mainnet, MATIC on polygon, etc.
        NATIVE,

        // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
        ERC20,

        // 2: ERC721 items
        ERC721,

        // 3: ERC1155 items
        ERC1155,

        // 4: ERC721 items where collection-based ids are supported
        ERC721_WITH_COLLECTION_BASED,

        // 5: ERC1155 items where collection-based ids are supported
        ERC1155_WITH_COLLECTION_BASED
    }

    struct MakerPayItem {
        ItemType itemType;
        address token;
        uint256 id;
        uint256 amount;
    }

    struct TakerPayItem {
        ItemType itemType;
        address token;
        uint256 id;
        uint256 amount;
        address payable recipient;
    }

    struct NFTSwapOrder {
        address maker;
        address taker;
        uint256 extra;
        MakerPayItem[] makerPayItems;
        TakerPayItem[] takerPayItems;
    }

    // keccak256("");
    bytes32 private constant _EMPTY_ARRAY_KECCAK256 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // The type hash for ERC1155 sell orders, which is:
    // keccak256(abi.encodePacked(
    //    "NFTSwapOrder(",
    //        "address maker,",
    //        "address taker,",
    //        "uint256 extra,",
    //        "MakerPayItem[] makerPayItems,",
    //        "TakerPayItem[] takerPayItems,",
    //        "uint256 hashNonce",
    //    ")",
    //    "MakerPayItem(",
    //        "uint8 itemType,",
    //        "address token,",
    //        "uint256 id,",
    //        "uint256 amount",
    //    ")",
    //    "TakerPayItem(",
    //        "uint8 itemType,",
    //        "address token,",
    //        "uint256 id,",
    //        "uint256 amount,",
    //        "address recipient",
    //    ")"
    // ));
    uint256 private constant _NFT_SWAP_ORDER_TYPE_HASH = 0xe685551aee8935202e142313b20416251ef716f35300ffcb09fe9e4ac34fe030;
    function getNFTSwapOrderStructHash(NFTSwapOrder memory order, uint256 hashNonce) internal pure returns (bytes32 structHash) {
        bytes32 makerPayItemsHash = _makerPayItemsHash(order.makerPayItems);
        bytes32 takerPayItemsHash = _takerPayItemsHash(order.takerPayItems);
        // Hash in place, equivalent to:
        // return keccak256(abi.encode(
        //         _NFT_SWAP_ORDER_TYPE_HASH,
        //         order.maker,
        //         order.taker,
        //         order.extra,
        //         makerPayItemsHash,
        //         takerPayItemsHash,
        //         hashNonce
        // ));
        assembly {
            if lt(order, 32) { invalid() } // Don't underflow memory.

            let typeHashPos := sub(order, 32) // order - 32
            let makerPayItemsHashPos := add(order, 96) // order + (32 * 3)
            let takerPayItemsHashPos := add(order, 128) // order + (32 * 4)
            let hashNoncePos := add(order, 160) // order + (32 * 5)

            let typeHashMemBefore := mload(typeHashPos)
            let makerPayItemsHashMemBefore := mload(makerPayItemsHashPos)
            let takerPayItemsHashMemBefore := mload(takerPayItemsHashPos)
            let hashNonceMemBefore := mload(hashNoncePos)

            mstore(typeHashPos, _NFT_SWAP_ORDER_TYPE_HASH)
            mstore(makerPayItemsHashPos, makerPayItemsHash)
            mstore(takerPayItemsHashPos, takerPayItemsHash)
            mstore(hashNoncePos, hashNonce)
            structHash := keccak256(typeHashPos, 224 /* 32 * 7 */ )

            mstore(typeHashPos, typeHashMemBefore)
            mstore(makerPayItemsHashPos, makerPayItemsHashMemBefore)
            mstore(takerPayItemsHashPos, takerPayItemsHashMemBefore)
            mstore(hashNoncePos, hashNonceMemBefore)
        }
        return structHash;
    }

    uint256 private constant ITEM_TYPE_MASK = 0xff; // (1 << 8) - 1;
    uint256 private constant ADDRESS_MASK = (1 << 160) - 1;

    // keccak256(abi.encodePacked(
    //    "MakerPayItem(",
    //        "uint8 itemType,",
    //        "address token,",
    //        "uint256 id,",
    //        "uint256 amount",
    //    ")"
    // ));
    uint256 private constant _MAKER_PAY_ITEM_TYPE_HASH = 0x0beb5c5a821d8df7ad0fadf8e52a266ca20712f53fe2cec12bd7e2ad970b0f8a;
    function _makerPayItemsHash(MakerPayItem[] memory items) internal pure returns (bytes32 hash) {
        uint256 length = items.length;
        if (length == 1) {
            // hash = keccak256(abi.encodePacked(keccak256(abi.encode(
            //        _MAKER_PAY_ITEM_TYPE_HASH,
            //        items[0].itemType,
            //        items[0].token,
            //        items[0].id,
            //        items[0].amount
            // ))));
            MakerPayItem memory item = items[0];
            assembly {
                // Load free memory pointer
                let mem := mload(64)
                mstore(mem, _MAKER_PAY_ITEM_TYPE_HASH)
                // item.itemType
                mstore(add(mem, 32), and(ITEM_TYPE_MASK, mload(item)))
                // item.token
                mstore(add(mem, 64), and(ADDRESS_MASK, mload(add(item, 32))))
                // item.id
                mstore(add(mem, 96), mload(add(item, 64)))
                // item.amount
                mstore(add(mem, 128), mload(add(item, 96)))
                // keccak256(item)
                mstore(mem, keccak256(mem, 160))
                // keccak256(abi.encodePacked(keccak256(item))
                hash := keccak256(mem, 32)
            }
        } else if (length != 0) {
            bytes32[] memory structHashArray = new bytes32[](length);
            for (uint256 i = 0; i < length; ++i) {
                MakerPayItem memory item = items[i];
                structHashArray[i] = keccak256(abi.encode(_MAKER_PAY_ITEM_TYPE_HASH, item.itemType, item.token, item.id, item.amount));
            }
            assembly {
                hash := keccak256(add(structHashArray, 32), mul(length, 32))
            }
        } else {
            hash = _EMPTY_ARRAY_KECCAK256;
        }
    }

    // keccak256(abi.encodePacked(
    //    "TakerPayItem(",
    //        "uint8 itemType,",
    //        "address token,",
    //        "uint256 id,",
    //        "uint256 amount,",
    //        "address recipient",
    //    ")"
    // ));
    uint256 private constant _TAKER_PAY_ITEM_TYPE_HASH = 0xb8f8c3036d85fdd53e2db9a64529ab45f657168bdb025c2563bede22fec26d33;
    function _takerPayItemsHash(TakerPayItem[] memory items) internal pure returns (bytes32 hash) {
        uint256 length = items.length;
        if (length == 1) {
            // hash = keccak256(abi.encodePacked(keccak256(abi.encode(
            //         _TAKER_PAY_ITEM_TYPE_HASH,
            //        items[0].itemType,
            //        items[0].token,
            //        items[0].id,
            //        items[0].amount,
            //        items[0].recipient
            // ))));
            TakerPayItem memory item = items[0];
            assembly {
                // Load free memory pointer
                let mem := mload(64)
                mstore(mem, _TAKER_PAY_ITEM_TYPE_HASH)
                // item.itemType
                mstore(add(mem, 32), and(ITEM_TYPE_MASK, mload(item)))
                // item.token
                mstore(add(mem, 64), and(ADDRESS_MASK, mload(add(item, 32))))
                // item.id
                mstore(add(mem, 96), mload(add(item, 64)))
                // item.amount
                mstore(add(mem, 128), mload(add(item, 96)))
                // item.recipient
                mstore(add(mem, 160), and(ADDRESS_MASK, mload(add(item, 128))))
                // keccak256(item)
                mstore(mem, keccak256(mem, 192))
                // keccak256(abi.encodePacked(keccak256(item))
                hash := keccak256(mem, 32)
            }
        } else if (length != 0) {
            bytes32[] memory structHashArray = new bytes32[](length);
            for (uint256 i = 0; i < length; ++i) {
                TakerPayItem memory item = items[i];
                structHashArray[i] = keccak256(abi.encode(_TAKER_PAY_ITEM_TYPE_HASH, item.itemType, item.token, item.id, item.amount, item.recipient));
            }
            assembly {
                hash := keccak256(add(structHashArray, 32), mul(length, 32))
            }
        } else {
            hash = _EMPTY_ARRAY_KECCAK256;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
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
    uint256 constant STORAGE_ID_NFT_SWAPS = 7 << 128;
}