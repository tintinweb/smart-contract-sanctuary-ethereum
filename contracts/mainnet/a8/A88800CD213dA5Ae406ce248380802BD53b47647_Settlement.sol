// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
pragma abicoder v1;

/**
 * @title Interface for interactor which acts after `taker -> maker` transfers.
 * @notice The order filling steps are `preInteraction` =>` Transfer "maker -> taker"` => **`Interaction`** => `Transfer "taker -> maker"` => `postInteraction`
 */
interface IInteractionNotificationReceiver {
    /**
     * @notice Callback method that gets called after all funds transfers
     * @param taker Taker address (tx sender)
     * @param makingAmount Actual making amount
     * @param takingAmount Actual taking amount
     * @param interactionData Interaction calldata
     * @return offeredTakingAmount Suggested amount. Order is filled with this amount if maker or taker getter functions are not defined.
     */
    function fillOrderInteraction(
        address taker,
        uint256 makingAmount,
        uint256 takingAmount,
        bytes memory interactionData
    ) external returns(uint256 offeredTakingAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../OrderLib.sol";

interface IOrderMixin {
    /**
     * @notice Returns unfilled amount for order. Throws if order does not exist
     * @param orderHash Order's hash. Can be obtained by the `hashOrder` function
     * @return amount Unfilled amount
     */
    function remaining(bytes32 orderHash) external view returns(uint256 amount);

    /**
     * @notice Returns unfilled amount for order
     * @param orderHash Order's hash. Can be obtained by the `hashOrder` function
     * @return rawAmount Unfilled amount of order plus one if order exists. Otherwise 0
     */
    function remainingRaw(bytes32 orderHash) external view returns(uint256 rawAmount);

    /**
     * @notice Same as `remainingRaw` but for multiple orders
     * @param orderHashes Array of hashes
     * @return rawAmounts Array of amounts for each order plus one if order exists or 0 otherwise
     */
    function remainingsRaw(bytes32[] memory orderHashes) external view returns(uint256[] memory rawAmounts);

    /**
     * @notice Checks order predicate
     * @param order Order to check predicate for
     * @return result Predicate evaluation result. True if predicate allows to fill the order, false otherwise
     */
    function checkPredicate(OrderLib.Order calldata order) external view returns(bool result);

    /**
     * @notice Returns order hash according to EIP712 standard
     * @param order Order to get hash for
     * @return orderHash Hash of the order
     */
    function hashOrder(OrderLib.Order calldata order) external view returns(bytes32 orderHash);

    /**
     * @notice Delegates execution to custom implementation. Could be used to validate if `transferFrom` works properly
     * @dev The function always reverts and returns the simulation results in revert data.
     * @param target Addresses that will be delegated
     * @param data Data that will be passed to delegatee
     */
    function simulate(address target, bytes calldata data) external;

    /**
     * @notice Cancels order.
     * @dev Order is cancelled by setting remaining amount to _ORDER_FILLED value
     * @param order Order quote to cancel
     * @return orderRemaining Unfilled amount of order before cancellation
     * @return orderHash Hash of the filled order
     */
    function cancelOrder(OrderLib.Order calldata order) external returns(uint256 orderRemaining, bytes32 orderHash);

    /**
     * @notice Fills an order. If one doesn't exist (first fill) it will be created using order.makerAssetData
     * @param order Order quote to fill
     * @param signature Signature to confirm quote ownership
     * @param interaction A call data for InteractiveNotificationReceiver. Taker may execute interaction after getting maker assets and before sending taker assets.
     * @param makingAmount Making amount
     * @param takingAmount Taking amount
     * @param skipPermitAndThresholdAmount Specifies maximum allowed takingAmount when takingAmount is zero, otherwise specifies minimum allowed makingAmount. Top-most bit specifies whether taker wants to skip maker's permit.
     * @return actualMakingAmount Actual amount transferred from maker to taker
     * @return actualTakingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     */
    function fillOrder(
        OrderLib.Order calldata order,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 skipPermitAndThresholdAmount
    ) external payable returns(uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash);

    /**
     * @notice Same as `fillOrderTo` but calls permit first,
     * allowing to approve token spending and make a swap in one transaction.
     * Also allows to specify funds destination instead of `msg.sender`
     * @dev See tests for examples
     * @param order Order quote to fill
     * @param signature Signature to confirm quote ownership
     * @param interaction A call data for InteractiveNotificationReceiver. Taker may execute interaction after getting maker assets and before sending taker assets.
     * @param makingAmount Making amount
     * @param takingAmount Taking amount
     * @param skipPermitAndThresholdAmount Specifies maximum allowed takingAmount when takingAmount is zero, otherwise specifies minimum allowed makingAmount. Top-most bit specifies whether taker wants to skip maker's permit.
     * @param target Address that will receive swap funds
     * @param permit Should consist of abiencoded token address and encoded `IERC20Permit.permit` call.
     * @return actualMakingAmount Actual amount transferred from maker to taker
     * @return actualTakingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     */
    function fillOrderToWithPermit(
        OrderLib.Order calldata order,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 skipPermitAndThresholdAmount,
        address target,
        bytes calldata permit
    ) external returns(uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash);

    /**
     * @notice Same as `fillOrder` but allows to specify funds destination instead of `msg.sender`
     * @param order_ Order quote to fill
     * @param signature Signature to confirm quote ownership
     * @param interaction A call data for InteractiveNotificationReceiver. Taker may execute interaction after getting maker assets and before sending taker assets.
     * @param makingAmount Making amount
     * @param takingAmount Taking amount
     * @param skipPermitAndThresholdAmount Specifies maximum allowed takingAmount when takingAmount is zero, otherwise specifies minimum allowed makingAmount. Top-most bit specifies whether taker wants to skip maker's permit.
     * @param target Address that will receive swap funds
     * @return actualMakingAmount Actual amount transferred from maker to taker
     * @return actualTakingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     */
    function fillOrderTo(
        OrderLib.Order calldata order_,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 skipPermitAndThresholdAmount,
        address target
    ) external payable returns(uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@1inch/solidity-utils/contracts/libraries/ECDSA.sol";

library OrderLib {
    struct Order {
        uint256 salt;
        address makerAsset;
        address takerAsset;
        address maker;
        address receiver;
        address allowedSender;  // equals to Zero address on public orders
        uint256 makingAmount;
        uint256 takingAmount;
        uint256 offsets;
        // bytes makerAssetData;
        // bytes takerAssetData;
        // bytes getMakingAmount; // this.staticcall(abi.encodePacked(bytes, swapTakerAmount)) => (swapMakerAmount)
        // bytes getTakingAmount; // this.staticcall(abi.encodePacked(bytes, swapMakerAmount)) => (swapTakerAmount)
        // bytes predicate;       // this.staticcall(bytes) => (bool)
        // bytes permit;          // On first fill: permit.1.call(abi.encodePacked(permit.selector, permit.2))
        // bytes preInteraction;
        // bytes postInteraction;
        bytes interactions; // concat(makerAssetData, takerAssetData, getMakingAmount, getTakingAmount, predicate, permit, preIntercation, postInteraction)
    }

    bytes32 constant internal _LIMIT_ORDER_TYPEHASH = keccak256(
        "Order("
            "uint256 salt,"
            "address makerAsset,"
            "address takerAsset,"
            "address maker,"
            "address receiver,"
            "address allowedSender,"
            "uint256 makingAmount,"
            "uint256 takingAmount,"
            "uint256 offsets,"
            "bytes interactions"
        ")"
    );

    enum DynamicField {
        MakerAssetData,
        TakerAssetData,
        GetMakingAmount,
        GetTakingAmount,
        Predicate,
        Permit,
        PreInteraction,
        PostInteraction
    }

    function getterIsFrozen(bytes calldata getter) internal pure returns(bool) {
        return getter.length == 1 && getter[0] == "x";
    }

    function _get(Order calldata order, DynamicField field) private pure returns(bytes calldata) {
        uint256 bitShift = uint256(field) << 5; // field * 32
        return order.interactions[
            uint32((order.offsets << 32) >> bitShift):
            uint32(order.offsets >> bitShift)
        ];
    }

    function makerAssetData(Order calldata order) internal pure returns(bytes calldata) {
        return _get(order, DynamicField.MakerAssetData);
    }

    function takerAssetData(Order calldata order) internal pure returns(bytes calldata) {
        return _get(order, DynamicField.TakerAssetData);
    }

    function getMakingAmount(Order calldata order) internal pure returns(bytes calldata) {
        return _get(order, DynamicField.GetMakingAmount);
    }

    function getTakingAmount(Order calldata order) internal pure returns(bytes calldata) {
        return _get(order, DynamicField.GetTakingAmount);
    }

    function predicate(Order calldata order) internal pure returns(bytes calldata) {
        return _get(order, DynamicField.Predicate);
    }

    function permit(Order calldata order) internal pure returns(bytes calldata) {
        return _get(order, DynamicField.Permit);
    }

    function preInteraction(Order calldata order) internal pure returns(bytes calldata) {
        return _get(order, DynamicField.PreInteraction);
    }

    function postInteraction(Order calldata order) internal pure returns(bytes calldata) {
        return _get(order, DynamicField.PostInteraction);
    }

    function hash(Order calldata order, bytes32 domainSeparator) internal pure returns(bytes32 result) {
        bytes calldata interactions = order.interactions;
        bytes32 typehash = _LIMIT_ORDER_TYPEHASH;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)

            // keccak256(abi.encode(_LIMIT_ORDER_TYPEHASH, orderWithoutInteractions, keccak256(order.interactions)));
            calldatacopy(ptr, interactions.offset, interactions.length)
            mstore(add(ptr, 0x140), keccak256(ptr, interactions.length))
            calldatacopy(add(ptr, 0x20), order, 0x120)
            mstore(ptr, typehash)
            result := keccak256(ptr, 0x160)
        }
        result = ECDSA.toTypedDataHash(domainSeparator, result);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

interface IDaiLikePermit {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

import "@openzeppelin/contracts/interfaces/IERC1271.sol";

library ECDSA {
    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    uint256 private constant _S_BOUNDARY = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0 + 1;
    uint256 private constant _COMPACT_S_MASK = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant _COMPACT_V_SHIFT = 255;

    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address signer) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            if lt(s, _S_BOUNDARY) {
                let ptr := mload(0x40)

                mstore(ptr, hash)
                mstore(add(ptr, 0x20), v)
                mstore(add(ptr, 0x40), r)
                mstore(add(ptr, 0x60), s)
                mstore(0, 0)
                pop(staticcall(gas(), 0x1, ptr, 0x80, 0, 0x20))
                signer := mload(0)
            }
        }
    }

    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal view returns (address signer) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let s := and(vs, _COMPACT_S_MASK)
            if lt(s, _S_BOUNDARY) {
                let ptr := mload(0x40)

                mstore(ptr, hash)
                mstore(add(ptr, 0x20), add(27, shr(_COMPACT_V_SHIFT, vs)))
                mstore(add(ptr, 0x40), r)
                mstore(add(ptr, 0x60), s)
                mstore(0, 0)
                pop(staticcall(gas(), 0x1, ptr, 0x80, 0, 0x20))
                signer := mload(0)
            }
        }
    }

    /// @dev WARNING!!!
    /// There is a known signature malleability issue with two representations of signatures!
    /// Even though this function is able to verify both standard 65-byte and compact 64-byte EIP-2098 signatures
    /// one should never use raw signatures for any kind of invalidation logic in their code.
    /// As the standard and compact representations are interchangeable any invalidation logic that relies on
    /// signature uniqueness will get rekt.
    /// More info: https://github.com/OpenZeppelin/openzeppelin-contracts/security/advisories/GHSA-4h98-2769-gh6h
    function recover(bytes32 hash, bytes calldata signature) internal view returns (address signer) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)

            // memory[ptr:ptr+0x80] = (hash, v, r, s)
            switch signature.length
            case 65 {
                // memory[ptr+0x20:ptr+0x80] = (v, r, s)
                mstore(add(ptr, 0x20), byte(0, calldataload(add(signature.offset, 0x40))))
                calldatacopy(add(ptr, 0x40), signature.offset, 0x40)
            }
            case 64 {
                // memory[ptr+0x20:ptr+0x80] = (v, r, s)
                let vs := calldataload(add(signature.offset, 0x20))
                mstore(add(ptr, 0x20), add(27, shr(_COMPACT_V_SHIFT, vs)))
                calldatacopy(add(ptr, 0x40), signature.offset, 0x20)
                mstore(add(ptr, 0x60), and(vs, _COMPACT_S_MASK))
            }
            default {
                ptr := 0
            }

            if ptr {
                if lt(mload(add(ptr, 0x60)), _S_BOUNDARY) {
                    // memory[ptr:ptr+0x20] = (hash)
                    mstore(ptr, hash)

                    mstore(0, 0)
                    pop(staticcall(gas(), 0x1, ptr, 0x80, 0, 0x20))
                    signer := mload(0)
                }
            }
        }
    }

    function recoverOrIsValidSignature(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) internal view returns (bool success) {
        if (signer == address(0)) return false;
        if ((signature.length == 64 || signature.length == 65) && recover(hash, signature) == signer) {
            return true;
        }
        return isValidSignature(signer, hash, signature);
    }

    function recoverOrIsValidSignature(
        address signer,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool success) {
        if (signer == address(0)) return false;
        if (recover(hash, v, r, s) == signer) {
            return true;
        }
        return isValidSignature(signer, hash, v, r, s);
    }

    function recoverOrIsValidSignature(
        address signer,
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal view returns (bool success) {
        if (signer == address(0)) return false;
        if (recover(hash, r, vs) == signer) {
            return true;
        }
        return isValidSignature(signer, hash, r, vs);
    }

    function recoverOrIsValidSignature65(
        address signer,
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal view returns (bool success) {
        if (signer == address(0)) return false;
        if (recover(hash, r, vs) == signer) {
            return true;
        }
        return isValidSignature65(signer, hash, r, vs);
    }

    function isValidSignature(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) internal view returns (bool success) {
        // (bool success, bytes memory data) = signer.staticcall(abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature));
        // return success && data.length >= 4 && abi.decode(data, (bytes4)) == IERC1271.isValidSignature.selector;
        bytes4 selector = IERC1271.isValidSignature.selector;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)

            mstore(ptr, selector)
            mstore(add(ptr, 0x04), hash)
            mstore(add(ptr, 0x24), 0x40)
            mstore(add(ptr, 0x44), signature.length)
            calldatacopy(add(ptr, 0x64), signature.offset, signature.length)
            if staticcall(gas(), signer, ptr, add(0x64, signature.length), 0, 0x20) {
                success := and(eq(selector, mload(0)), eq(returndatasize(), 0x20))
            }
        }
    }

    function isValidSignature(
        address signer,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool success) {
        bytes4 selector = IERC1271.isValidSignature.selector;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)

            mstore(ptr, selector)
            mstore(add(ptr, 0x04), hash)
            mstore(add(ptr, 0x24), 0x40)
            mstore(add(ptr, 0x44), 65)
            mstore(add(ptr, 0x64), r)
            mstore(add(ptr, 0x84), s)
            mstore8(add(ptr, 0xa4), v)
            if staticcall(gas(), signer, ptr, 0xa5, 0, 0x20) {
                success := and(eq(selector, mload(0)), eq(returndatasize(), 0x20))
            }
        }
    }

    function isValidSignature(
        address signer,
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal view returns (bool success) {
        // (bool success, bytes memory data) = signer.staticcall(abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, abi.encodePacked(r, vs)));
        // return success && data.length >= 4 && abi.decode(data, (bytes4)) == IERC1271.isValidSignature.selector;
        bytes4 selector = IERC1271.isValidSignature.selector;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)

            mstore(ptr, selector)
            mstore(add(ptr, 0x04), hash)
            mstore(add(ptr, 0x24), 0x40)
            mstore(add(ptr, 0x44), 64)
            mstore(add(ptr, 0x64), r)
            mstore(add(ptr, 0x84), vs)
            if staticcall(gas(), signer, ptr, 0xa4, 0, 0x20) {
                success := and(eq(selector, mload(0)), eq(returndatasize(), 0x20))
            }
        }
    }

    function isValidSignature65(
        address signer,
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal view returns (bool success) {
        // (bool success, bytes memory data) = signer.staticcall(abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, abi.encodePacked(r, vs & ~uint256(1 << 255), uint8(vs >> 255))));
        // return success && data.length >= 4 && abi.decode(data, (bytes4)) == IERC1271.isValidSignature.selector;
        bytes4 selector = IERC1271.isValidSignature.selector;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)

            mstore(ptr, selector)
            mstore(add(ptr, 0x04), hash)
            mstore(add(ptr, 0x24), 0x40)
            mstore(add(ptr, 0x44), 65)
            mstore(add(ptr, 0x64), r)
            mstore(add(ptr, 0x84), and(vs, _COMPACT_S_MASK))
            mstore8(add(ptr, 0xa4), add(27, shr(_COMPACT_V_SHIFT, vs)))
            if staticcall(gas(), signer, ptr, 0xa5, 0, 0x20) {
                success := and(eq(selector, mload(0)), eq(returndatasize(), 0x20))
            }
        }
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 res) {
        // 32 is the length in bytes of hash, enforced by the type signature above
        // return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            mstore(0, 0x19457468657265756d205369676e6564204d6573736167653a0a333200000000) // "\x19Ethereum Signed Message:\n32"
            mstore(28, hash)
            res := keccak256(0, 60)
        }
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 res) {
        // return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            mstore(ptr, 0x1901000000000000000000000000000000000000000000000000000000000000) // "\x19\x01"
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            res := keccak256(ptr, 66)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

/// @title Revert reason forwarder.
library RevertReasonForwarder {
    /// @dev Forwards latest externall call revert.
    function reRevert() internal pure {
        // bubble up revert reason from latest external call
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            revert(ptr, returndatasize())
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "../interfaces/IDaiLikePermit.sol";
import "../libraries/RevertReasonForwarder.sol";

/// @title Implements efficient safe methods for ERC20 interface.
library SafeERC20 {
    error SafeTransferFailed();
    error SafeTransferFromFailed();
    error ForceApproveFailed();
    error SafeIncreaseAllowanceFailed();
    error SafeDecreaseAllowanceFailed();
    error SafePermitBadLength();

    /// @dev Ensures method do not revert or return boolean `true`, admits call to non-smart-contract.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bytes4 selector = token.transferFrom.selector;
        bool success;
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            success := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
        if (!success) revert SafeTransferFromFailed();
    }

    /// @dev Ensures method do not revert or return boolean `true`, admits call to non-smart-contract.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.transfer.selector, to, value)) {
            revert SafeTransferFailed();
        }
    }

    /// @dev If `approve(from, to, amount)` fails, try to `approve(from, to, 0)` before retry.
    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        if (!_makeCall(token, token.approve.selector, spender, value)) {
            if (
                !_makeCall(token, token.approve.selector, spender, 0) ||
                !_makeCall(token, token.approve.selector, spender, value)
            ) {
                revert ForceApproveFailed();
            }
        }
    }

    /// @dev Allowance increase with safe math check.
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > type(uint256).max - allowance) revert SafeIncreaseAllowanceFailed();
        forceApprove(token, spender, allowance + value);
    }

    /// @dev Allowance decrease with safe math check.
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (value > allowance) revert SafeDecreaseAllowanceFailed();
        forceApprove(token, spender, allowance - value);
    }

    /// @dev Calls either ERC20 or Dai `permit` for `token`, if unsuccessful forwards revert from external call.
    function safePermit(IERC20 token, bytes calldata permit) internal {
        if (!tryPermit(token, permit)) RevertReasonForwarder.reRevert();
    }

    function tryPermit(IERC20 token, bytes calldata permit) internal returns(bool) {
        if (permit.length == 32 * 7) {
            return _makeCalldataCall(token, IERC20Permit.permit.selector, permit);
        }
        if (permit.length == 32 * 8) {
            return _makeCalldataCall(token, IDaiLikePermit.permit.selector, permit);
        }
        revert SafePermitBadLength();
    }

    function _makeCall(
        IERC20 token,
        bytes4 selector,
        address to,
        uint256 amount
    ) private returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), to)
            mstore(add(data, 0x24), amount)
            success := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }

    function _makeCalldataCall(
        IERC20 token,
        bytes4 selector,
        bytes calldata args
    ) private returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly { // solhint-disable-line no-inline-assembly
            let len := add(4, args.length)
            let data := mload(0x40)

            mstore(data, selector)
            calldatacopy(add(data, 0x04), args.offset, args.length)
            success := call(gas(), token, 0, data, len, 0x0, 0x20)
            if success {
                switch returndatasize()
                case 0 {
                    success := gt(extcodesize(token), 0)
                }
                default {
                    success := and(gt(returndatasize(), 31), eq(mload(0), 1))
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFeeBankCharger.sol";
import "./interfaces/IFeeBank.sol";

/// @title Contract with fee mechanism for solvers to pay for using the system
contract FeeBank is IFeeBank, Ownable {
    using SafeERC20 for IERC20;

    IERC20 private immutable _token;
    IFeeBankCharger private immutable _charger;

    mapping(address => uint256) private _accountDeposits;

    constructor(IFeeBankCharger charger, IERC20 inch, address owner) {
        _charger = charger;
        _token = inch;
        transferOwnership(owner);
    }

    function availableCredit(address account) external view returns (uint256) {
        return _charger.availableCredit(account);
    }

    /**
     * @notice Increment sender's availableCredit in Settlement contract.
     * @param amount The amount of 1INCH sender pay for incresing.
     * @return totalAvailableCredit The total sender's availableCredit after deposit.
     */
    function deposit(uint256 amount) external returns (uint256 totalAvailableCredit) {
        return _depositFor(msg.sender, amount);
    }

    /**
     * @notice Increases account's availableCredit in Settlement contract.
     * @param account The account whose availableCredit is increased by the sender.
     * @param amount The amount of 1INCH sender pay for incresing.
     * @return totalAvailableCredit The total account's availableCredit after deposit.
     */
    function depositFor(address account, uint256 amount) external returns (uint256 totalAvailableCredit) {
        return _depositFor(account, amount);
    }

    /**
     * @notice See {deposit}. This method uses permit for deposit without prior approves.
     * @param amount The amount of 1INCH sender pay for incresing.
     * @param permit The data with sender's permission via token.
     * @return totalAvailableCredit The total sender's availableCredit after deposit.
     */
    function depositWithPermit(uint256 amount, bytes calldata permit) external returns (uint256 totalAvailableCredit) {
        return depositForWithPermit(msg.sender, amount, permit);
    }

    /**
     * @notice See {depositFor} and {depositWithPermit}.
     */
    function depositForWithPermit(
        address account,
        uint256 amount,
        bytes calldata permit
    ) public returns (uint256 totalAvailableCredit) {
        _token.safePermit(permit);
        return _depositFor(account, amount);
    }

    /**
     * @notice Returns unspent availableCredit.
     * @param amount The amount of 1INCH sender returns.
     * @return totalAvailableCredit The total sender's availableCredit after withdrawal.
     */
    function withdraw(uint256 amount) external returns (uint256 totalAvailableCredit) {
        return _withdrawTo(msg.sender, amount);
    }

    /**
     * @notice Returns unspent availableCredit to specific account.
     * @param account The account which get withdrawaled tokens.
     * @param amount The amount of withdrawaled tokens.
     * @return totalAvailableCredit The total sender's availableCredit after withdrawal.
     */
    function withdrawTo(address account, uint256 amount) external returns (uint256 totalAvailableCredit) {
        return _withdrawTo(account, amount);
    }

    /**
     * @notice Admin method returns commissions spent by users.
     * @param accounts Accounts whose commissions are being withdrawn.
     * @return totalAccountFees The total amount of accounts commissions.
     */
    function gatherFees(address[] memory accounts) external onlyOwner returns (uint256 totalAccountFees) {
        uint256 accountsLength = accounts.length;
        for (uint256 i = 0; i < accountsLength; ++i) {
            address account = accounts[i];
            uint256 accountDeposit = _accountDeposits[account];
            uint256 availableCredit_ = _charger.availableCredit(account);
            _accountDeposits[account] = availableCredit_;
            totalAccountFees += accountDeposit - availableCredit_;
        }
        _token.safeTransfer(msg.sender, totalAccountFees);
    }

    function _depositFor(address account, uint256 amount) internal returns (uint256 totalAvailableCredit) {
        _token.safeTransferFrom(msg.sender, address(this), amount);
        _accountDeposits[account] += amount;
        totalAvailableCredit = _charger.increaseAvailableCredit(account, amount);
    }

    function _withdrawTo(address account, uint256 amount) internal returns (uint256 totalAvailableCredit) {
        totalAvailableCredit = _charger.decreaseAvailableCredit(msg.sender, amount);
        _accountDeposits[msg.sender] -= amount;
        _token.safeTransfer(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFeeBankCharger.sol";
import "./FeeBank.sol";

contract FeeBankCharger is IFeeBankCharger {
    error OnlyFeeBankAccess();
    error NotEnoughCredit();

    IFeeBank public immutable feeBank;
    mapping(address => uint256) private _creditAllowance;

    modifier onlyFeeBank() {
        if (msg.sender != address(feeBank)) revert OnlyFeeBankAccess();
        _;
    }

    constructor(IERC20 token) {
        feeBank = new FeeBank(this, token, msg.sender);
    }

    function availableCredit(address account) external view returns (uint256) {
        return _creditAllowance[account];
    }

    function increaseAvailableCredit(address account, uint256 amount) external onlyFeeBank returns (uint256 allowance) {
        allowance = _creditAllowance[account];
        allowance += amount;
        _creditAllowance[account] = allowance;
    }

    function decreaseAvailableCredit(address account, uint256 amount) external onlyFeeBank returns (uint256 allowance) {
        allowance = _creditAllowance[account];
        allowance -= amount;
        _creditAllowance[account] = allowance;
    }

    function _chargeFee(address account, uint256 fee) internal {
        if (fee > 0) {
            uint256 currentAllowance = _creditAllowance[account];
            if (currentAllowance < fee) revert NotEnoughCredit();
            unchecked {
                _creditAllowance[account] = currentAllowance - fee;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IFeeBank {
    function deposit(uint256 amount) external returns (uint256 totalAvailableCredit);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IFeeBankCharger {
    function availableCredit(address account) external view returns (uint256);
    function increaseAvailableCredit(address account, uint256 amount) external returns (uint256 allowance);
    function decreaseAvailableCredit(address account, uint256 amount) external returns (uint256 allowance);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../libraries/DynamicSuffix.sol";

interface IResolver {
    function resolveOrders(address resolver, bytes calldata tokensAndAmounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@1inch/limit-order-protocol-contract/contracts/interfaces/IInteractionNotificationReceiver.sol";
import "./IFeeBankCharger.sol";

interface ISettlement is IInteractionNotificationReceiver, IFeeBankCharger {
    function settleOrders(bytes calldata order) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

type Address is uint256;

library AddressLib {
    function get(Address a) internal pure returns (address) {
        return address(uint160(Address.unwrap(a)));
    }

    function getFlag(Address a, uint256 flag) internal pure returns (bool) {
        return Address.unwrap(a) & flag != 0;
    }

    function getUint32(Address a, uint256 offset) internal pure returns (uint32) {
        return uint32(Address.unwrap(a) >> offset);
    }

    function getUint64(Address a, uint256 offset) internal pure returns (uint64) {
        return uint64(Address.unwrap(a) >> offset);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Address.sol";
import "./TakingFee.sol";

// layout of dynamic suffix is as follows:
// 0x00 - 0x19: totalFee
// 0x20 - 0x39: resolver
// 0x40 - 0x59: token
// 0x60 - 0x79: rateBump
// 0x80 - 0x99: takingFee
// 0xa0 - 0x..: tokensAndAmounts bytes
// 0x.. - 0x..: tokensAndAmounts length in bytes
library DynamicSuffix {
    struct Data {
        uint256 totalFee;
        Address resolver;
        Address token;
        uint256 rateBump;
        TakingFee.Data takingFee;
    }

    uint256 internal constant _STATIC_DATA_SIZE = 0xa0;

    function decodeSuffix(bytes calldata cd) internal pure returns(Data calldata suffix, bytes calldata tokensAndAmounts, bytes calldata interaction) {
        assembly {
            let lengthOffset := sub(add(cd.offset, cd.length), 0x20)
            tokensAndAmounts.length := calldataload(lengthOffset)
            tokensAndAmounts.offset := sub(lengthOffset, tokensAndAmounts.length)
            suffix := sub(tokensAndAmounts.offset, _STATIC_DATA_SIZE)
            interaction.offset := add(cd.offset, 1)
            interaction.length := sub(suffix, interaction.offset)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Library for parsing parameters from salt.
library OrderSaltParser {
    uint256 private constant _TIME_START_MASK        = 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000; // prettier-ignore
    uint256 private constant _DURATION_MASK          = 0x00000000FFFFFF00000000000000000000000000000000000000000000000000; // prettier-ignore
    uint256 private constant _INITIAL_RATE_BUMP_MASK = 0x00000000000000FFFFFF00000000000000000000000000000000000000000000; // prettier-ignore
    uint256 private constant _FEE_MASK               = 0x00000000000000000000FFFFFFFF000000000000000000000000000000000000; // prettier-ignore
    uint256 private constant _SALT_MASK              = 0x0000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    uint256 private constant _TIME_START_SHIFT = 224; // orderTimeMask 224-255
    uint256 private constant _DURATION_SHIFT = 200; // durationMask 200-223
    uint256 private constant _INITIAL_RATE_BUMP_SHIFT = 176; // initialRateMask 176-200
    uint256 private constant _FEE_SHIFT = 144; // orderFee 144-175

    function getStartTime(uint256 salt) internal pure returns (uint256) {
        return (salt & _TIME_START_MASK) >> _TIME_START_SHIFT;
    }

    function getDuration(uint256 salt) internal pure returns (uint256) {
        return (salt & _DURATION_MASK) >> _DURATION_SHIFT;
    }

    function getInitialRateBump(uint256 salt) internal pure returns (uint256) {
        return (salt & _INITIAL_RATE_BUMP_MASK) >> _INITIAL_RATE_BUMP_SHIFT;
    }

    function getFee(uint256 salt) internal pure returns (uint256) {
        return (salt & _FEE_MASK) >> _FEE_SHIFT;
    }

    function getSalt(uint256 salt) internal pure returns (uint256) {
        return salt & _SALT_MASK;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@1inch/limit-order-protocol-contract/contracts/OrderLib.sol";
import "./OrderSaltParser.sol";
import "./TakingFee.sol";

// Placed in the end of the order interactions data
// Last byte contains flags and lengths, can have up to 15 resolvers and 7 points
library OrderSuffix {
    using OrderSaltParser for uint256;

    // `Order.interactions` suffix structure:
    // M*(1 + 3 bytes)  - auction points coefficients with seconds delays
    // N*(4 + 20 bytes) - resolver with corresponding time limit
    // 4 bytes          - public time limit
    // 32 bytes         - taking fee (optional if flags has _HAS_TAKING_FEE_FLAG)
    // 1 bytes          - flags

    uint256 private constant _HAS_TAKING_FEE_FLAG = 0x80;
    uint256 private constant _RESOLVERS_LENGTH_MASK = 0x78;
    uint256 private constant _RESOLVERS_LENGTH_BIT_SHIFT = 3;
    uint256 private constant _POINTS_LENGTH_MASK = 0x07;
    uint256 private constant _POINTS_LENGTH_BIT_SHIFT = 0;

    uint256 private constant _TAKING_FEE_BYTES_SIZE = 32;

    uint256 private constant _PUBLIC_TIME_LIMIT_BYTES_SIZE = 4;
    uint256 private constant _PUBLIC_TIME_LIMIT_BIT_SHIFT = 224; // 256 - _PUBLIC_TIME_LIMIT_BYTES_SIZE * 8

    uint256 private constant _AUCTION_POINT_DELAY_BYTES_SIZE = 2;
    uint256 private constant _AUCTION_POINT_BUMP_BYTES_SIZE = 3;
    uint256 private constant _AUCTION_POINT_BYTES_SIZE = 5; // _AUCTION_POINT_DELAY_BYTES_SIZE + _AUCTION_POINT_BUMP_BYTES_SIZE;
    uint256 private constant _AUCTION_POINT_DELAY_BIT_SHIFT = 240; // 256 - _AUCTION_POINT_DELAY_BYTES_SIZE * 8;
    uint256 private constant _AUCTION_POINT_BUMP_BIT_SHIFT = 232; // 256 - _AUCTION_POINT_BUMP_BYTES_SIZE * 8;

    uint256 private constant _RESOLVER_TIME_LIMIT_BYTES_SIZE = 4;
    uint256 private constant _RESOLVER_ADDRESS_BYTES_SIZE = 20;
    uint256 private constant _RESOLVER_BYTES_SIZE = 24; // _RESOLVER_TIME_LIMIT_BYTES_SIZE + _RESOLVER_ADDRESS_BYTES_SIZE;
    uint256 private constant _RESOLVER_TIME_LIMIT_BIT_SHIFT = 224; // 256 - _RESOLVER_TIME_LIMIT_BYTES_SIZE * 8;
    uint256 private constant _RESOLVER_ADDRESS_BIT_SHIFT = 96; // 256 - _RESOLVER_ADDRESS_BYTES_SIZE * 8;

    function takingFee(OrderLib.Order calldata order) internal pure returns (TakingFee.Data ret) {
        bytes calldata interactions = order.interactions;
        assembly {
            let ptr := sub(add(interactions.offset, interactions.length), 1)
            if and(_HAS_TAKING_FEE_FLAG, byte(0, calldataload(ptr))) {
                ret := calldataload(sub(ptr, _TAKING_FEE_BYTES_SIZE))
            }
        }
    }

    function checkResolver(OrderLib.Order calldata order, address resolver) internal view returns (bool valid) {
        bytes calldata interactions = order.interactions;
        assembly {
            let ptr := sub(add(interactions.offset, interactions.length), 1)
            let flags := byte(0, calldataload(ptr))
            ptr := sub(ptr, _PUBLIC_TIME_LIMIT_BYTES_SIZE)
            if and(flags, _HAS_TAKING_FEE_FLAG) {
                ptr := sub(ptr, _TAKING_FEE_BYTES_SIZE)
            }

            let resolversCount := shr(_RESOLVERS_LENGTH_BIT_SHIFT, and(flags, _RESOLVERS_LENGTH_MASK))

            // Check public time limit
            let publicLimit := shr(_PUBLIC_TIME_LIMIT_BIT_SHIFT, calldataload(ptr))
            valid := gt(timestamp(), publicLimit)

            // Check resolvers and corresponding time limits
            if not(valid) {
                for { let end := sub(ptr, mul(_RESOLVER_BYTES_SIZE, resolversCount)) } gt(ptr, end) { } {
                    ptr := sub(ptr, _RESOLVER_ADDRESS_BYTES_SIZE)
                    let account := shr(_RESOLVER_ADDRESS_BIT_SHIFT, calldataload(ptr))
                    ptr := sub(ptr, _RESOLVER_TIME_LIMIT_BYTES_SIZE)
                    let limit := shr(_RESOLVER_TIME_LIMIT_BIT_SHIFT, calldataload(ptr))
                    if eq(account, resolver) {
                        valid := iszero(lt(timestamp(), limit))
                        break
                    }
                }
            }
        }
    }

    function rateBump(OrderLib.Order calldata order) internal view returns (uint256 bump) {
        uint256 startBump = order.salt.getInitialRateBump();
        uint256 cumulativeTime = order.salt.getStartTime();
        uint256 lastTime = cumulativeTime + order.salt.getDuration();
        if (block.timestamp <= cumulativeTime) {
            return startBump;
        } else if (block.timestamp >= lastTime) {
            return 0;
        }

        bytes calldata interactions = order.interactions;
        assembly {
            function linearInterpolation(t1, t2, v1, v2, t) -> v {
                v := div(
                    add(mul(sub(t, t1), v2), mul(sub(t2, t), v1)),
                    sub(t2, t1)
                )
            }

            let ptr := sub(add(interactions.offset, interactions.length), 1)

            // move ptr to the last point
            let pointsCount
            {  // stack too deep
                let flags := byte(0, calldataload(ptr))
                let resolversCount := shr(_RESOLVERS_LENGTH_BIT_SHIFT, and(flags, _RESOLVERS_LENGTH_MASK))
                pointsCount := and(flags, _POINTS_LENGTH_MASK)
                if and(flags, _HAS_TAKING_FEE_FLAG) {
                    ptr := sub(ptr, _TAKING_FEE_BYTES_SIZE)
                }
                ptr := sub(ptr, add(mul(_RESOLVER_BYTES_SIZE, resolversCount), _PUBLIC_TIME_LIMIT_BYTES_SIZE)) // 24 byte for each wl entry + 4 bytes for public time limit
            }

            // Check points sequentially
            let prevCoefficient := startBump
            let prevCumulativeTime := cumulativeTime
            for { let end := sub(ptr, mul(_AUCTION_POINT_BYTES_SIZE, pointsCount)) } gt(ptr, end) { } {
                ptr := sub(ptr, _AUCTION_POINT_BUMP_BYTES_SIZE)
                let coefficient := shr(_AUCTION_POINT_BUMP_BIT_SHIFT, calldataload(ptr))
                ptr := sub(ptr, _AUCTION_POINT_DELAY_BYTES_SIZE)
                let delay := shr(_AUCTION_POINT_DELAY_BIT_SHIFT, calldataload(ptr))
                cumulativeTime := add(cumulativeTime, delay)
                if gt(cumulativeTime, timestamp()) {
                    // prevCumulativeTime <passed> time <elapsed> cumulativeTime
                    // prevCoefficient    <passed>  X   <elapsed> coefficient
                    bump := linearInterpolation(
                        prevCumulativeTime,
                        cumulativeTime,
                        prevCoefficient,
                        coefficient,
                        timestamp()
                    )
                    break
                }
                prevCumulativeTime := cumulativeTime
                prevCoefficient := coefficient
            }

            if iszero(bump) {
                bump := linearInterpolation(
                    prevCumulativeTime,
                    lastTime,
                    prevCoefficient,
                    0,
                    timestamp()
                )
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library TakingFee {
    type Data is uint256;

    uint256 internal constant _TAKING_FEE_BASE = 1e9;
    uint256 private constant _TAKING_FEE_RATIO_OFFSET = 160;

    function init(address receiver_, uint256 ratio_) internal pure returns (Data) {
        if (ratio_ == 0) {
            return Data.wrap(uint160(receiver_));
        }
        return Data.wrap(uint160(receiver_) | (ratio_ << _TAKING_FEE_RATIO_OFFSET));
    }

    function enabled(Data self) internal pure returns (bool) {
        return ratio(self) != 0;
    }

    function ratio(Data self) internal pure returns (uint256) {
        return uint32(Data.unwrap(self) >> _TAKING_FEE_RATIO_OFFSET);
    }

    function receiver(Data self) internal pure returns (address) {
        return address(uint160(Data.unwrap(self)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@1inch/limit-order-protocol-contract/contracts/interfaces/IOrderMixin.sol";
import "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import "./interfaces/ISettlement.sol";
import "./interfaces/IResolver.sol";
import "./libraries/DynamicSuffix.sol";
import "./libraries/OrderSaltParser.sol";
import "./libraries/OrderSuffix.sol";
import "./FeeBankCharger.sol";

contract Settlement is ISettlement, FeeBankCharger {
    using SafeERC20 for IERC20;
    using OrderSaltParser for uint256;
    using DynamicSuffix for bytes;
    using AddressLib for Address;
    using OrderSuffix for OrderLib.Order;
    using TakingFee for TakingFee.Data;

    error AccessDenied();
    error IncorrectCalldataParams();
    error FailedExternalCall();
    error ResolverIsNotWhitelisted();
    error WrongInteractionTarget();

    bytes1 private constant _FINALIZE_INTERACTION = 0x01;
    uint256 private constant _ORDER_FEE_BASE_POINTS = 1e15;
    uint256 private constant _BASE_POINTS = 10_000_000; // 100%

    IOrderMixin private immutable _limitOrderProtocol;

    modifier onlyThis(address account) {
        if (account != address(this)) revert AccessDenied();
        _;
    }

    modifier onlyLimitOrderProtocol {
        if (msg.sender != address(_limitOrderProtocol)) revert AccessDenied();
        _;
    }

    constructor(IOrderMixin limitOrderProtocol, IERC20 token)
        FeeBankCharger(token)
    {
        _limitOrderProtocol = limitOrderProtocol;
    }

    function settleOrders(bytes calldata data) external {
        _settleOrder(data, msg.sender, 0, new bytes(0));
    }

    function fillOrderInteraction(
        address taker,
        uint256, /* makingAmount */
        uint256 takingAmount,
        bytes calldata interactiveData
    ) external onlyThis(taker) onlyLimitOrderProtocol returns (uint256 result) {
        (DynamicSuffix.Data calldata suffix, bytes calldata tokensAndAmounts, bytes calldata interaction) = interactiveData.decodeSuffix();
        IERC20 token = IERC20(suffix.token.get());
        result = takingAmount * (_BASE_POINTS + suffix.rateBump) / _BASE_POINTS;
        uint256 takingFee = result * suffix.takingFee.ratio() / TakingFee._TAKING_FEE_BASE;

        bytes memory allTokensAndAmounts = new bytes(tokensAndAmounts.length + 0x40);
        assembly {
            let ptr := add(allTokensAndAmounts, 0x20)
            calldatacopy(ptr, tokensAndAmounts.offset, tokensAndAmounts.length)
            ptr := add(ptr, tokensAndAmounts.length)
            mstore(ptr, token)
            mstore(add(ptr, 0x20), add(result, takingFee))
        }

        if (interactiveData[0] == _FINALIZE_INTERACTION) {
            _chargeFee(suffix.resolver.get(), suffix.totalFee);
            address target = address(bytes20(interaction));
            bytes calldata data = interaction[20:];
            IResolver(target).resolveOrders(suffix.resolver.get(), allTokensAndAmounts, data);
        } else {
            _settleOrder(
                interaction,
                suffix.resolver.get(),
                suffix.totalFee,
                allTokensAndAmounts
            );
        }

        if (takingFee > 0) {
            token.safeTransfer(suffix.takingFee.receiver(), takingFee);
        }
        token.forceApprove(address(_limitOrderProtocol), result);
    }

    bytes4 private constant _FILL_ORDER_TO_SELECTOR = 0xe5d7bde6; // IOrderMixin.fillOrderTo.selector
    bytes4 private constant _WRONG_INTERACTION_TARGET_SELECTOR = 0x5b34bf89; // WrongInteractionTarget.selector

    function _settleOrder(bytes calldata data, address resolver, uint256 totalFee, bytes memory tokensAndAmounts) private {
        OrderLib.Order calldata order;
        assembly {
            order := add(data.offset, calldataload(data.offset))
        }
        if (!order.checkResolver(resolver)) revert ResolverIsNotWhitelisted();
        TakingFee.Data takingFeeData = order.takingFee();
        totalFee += order.salt.getFee() * _ORDER_FEE_BASE_POINTS;

        uint256 rateBump = order.rateBump();
        uint256 suffixLength = DynamicSuffix._STATIC_DATA_SIZE + tokensAndAmounts.length + 0x20;
        IOrderMixin limitOrderProtocol = _limitOrderProtocol;

        assembly {
            function memcpy(dst, src, len) {
                pop(staticcall(gas(), 0x4, src, len, dst, len))
            }

            let interactionLengthOffset := calldataload(add(data.offset, 0x40))
            let interactionOffset := add(interactionLengthOffset, 0x20)
            let interactionLength := calldataload(add(data.offset, interactionLengthOffset))

            { // stack too deep
                let target := shr(96, calldataload(add(data.offset, interactionOffset)))
                if or(lt(interactionLength, 20), iszero(eq(target, address()))) {
                    mstore(0, _WRONG_INTERACTION_TARGET_SELECTOR)
                    revert(0, 4)
                }
            }

            // Copy calldata and patch interaction.length
            let ptr := mload(0x40)
            mstore(ptr, _FILL_ORDER_TO_SELECTOR)
            calldatacopy(add(ptr, 4), data.offset, data.length)
            mstore(add(add(ptr, interactionLengthOffset), 4), add(interactionLength, suffixLength))

            {  // stack too deep
                // Append suffix fields
                let offset := add(add(ptr, interactionOffset), interactionLength)
                mstore(add(offset, 0x04), totalFee)
                mstore(add(offset, 0x24), resolver)
                mstore(add(offset, 0x44), calldataload(add(order, 0x40)))  // takerAsset
                mstore(add(offset, 0x64), rateBump)
                mstore(add(offset, 0x84), takingFeeData)
                let tokensAndAmountsLength := mload(tokensAndAmounts)
                memcpy(add(offset, 0xa4), add(tokensAndAmounts, 0x20), tokensAndAmountsLength)
                mstore(add(offset, add(0xa4, tokensAndAmountsLength)), tokensAndAmountsLength)
            }

            // Call fillOrderTo
            if iszero(call(gas(), limitOrderProtocol, 0, ptr, add(add(4, suffixLength), data.length), ptr, 0)) {
                returndatacopy(ptr, 0, returndatasize())
                revert(ptr, returndatasize())
            }
        }
    }
}