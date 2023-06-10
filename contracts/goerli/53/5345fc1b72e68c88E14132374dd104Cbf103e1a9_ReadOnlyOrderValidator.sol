// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { OrderType } from "seaport-types/src/lib/ConsiderationEnums.sol";

import {
    Order,
    OrderComponents,
    OrderParameters,
    OrderStatus
} from "seaport-types/src/lib/ConsiderationStructs.sol";

import {
    _revertConsiderationLengthNotEqualToTotalOriginal,
    _revertMissingOriginalConsiderationItems
} from "seaport-types/src/lib/ConsiderationErrors.sol";

import {
    SignatureVerification
} from "seaport-core/src/lib/SignatureVerification.sol";

import {
    _revertOrderIsCancelled,
    _revertOrderPartiallyFilled,
    _revertOrderAlreadyFilled
} from "seaport-types/src/lib/ConsiderationErrors.sol";

import { SeaportInterface } from "seaport-sol/src/SeaportInterface.sol";

import {
    EIP_712_PREFIX,
    EIP712_DigestPayload_size,
    EIP712_DomainSeparator_offset,
    EIP712_OrderHash_offset,
    BulkOrderProof_keyShift,
    BulkOrderProof_keySize,
    BulkOrderProof_lengthAdjustmentBeforeMask,
    BulkOrderProof_lengthRangeAfterMask,
    BulkOrderProof_minSize,
    BulkOrderProof_rangeSize,
    ECDSA_MaxLength,
    OneWordShift,
    ThirtyOneBytes,
    OneWord,
    TwoWords,
    BulkOrder_Typehash_Height_One,
    BulkOrder_Typehash_Height_Two,
    BulkOrder_Typehash_Height_Three,
    BulkOrder_Typehash_Height_Four,
    BulkOrder_Typehash_Height_Five,
    BulkOrder_Typehash_Height_Six,
    BulkOrder_Typehash_Height_Seven,
    BulkOrder_Typehash_Height_Eight,
    BulkOrder_Typehash_Height_Nine,
    BulkOrder_Typehash_Height_Ten,
    BulkOrder_Typehash_Height_Eleven,
    BulkOrder_Typehash_Height_Twelve,
    BulkOrder_Typehash_Height_Thirteen,
    BulkOrder_Typehash_Height_Fourteen,
    BulkOrder_Typehash_Height_Fifteen,
    BulkOrder_Typehash_Height_Sixteen,
    BulkOrder_Typehash_Height_Seventeen,
    BulkOrder_Typehash_Height_Eighteen,
    BulkOrder_Typehash_Height_Nineteen,
    BulkOrder_Typehash_Height_Twenty,
    BulkOrder_Typehash_Height_TwentyOne,
    BulkOrder_Typehash_Height_TwentyTwo,
    BulkOrder_Typehash_Height_TwentyThree,
    BulkOrder_Typehash_Height_TwentyFour
} from "seaport-types/src/lib/ConsiderationConstants.sol";

contract ReadOnlyOrderValidator is SignatureVerification {
    function canValidate(
        address seaport,
        Order[] memory orders
    ) external view returns (bool) {
        return _validate(orders, SeaportInterface(seaport));
    }

    /**
     * @dev Internal function to validate an arbitrary number of orders, thereby
     *      registering their signatures as valid and allowing the fulfiller to
     *      skip signature verification on fulfillment. Note that validated
     *      orders may still be unfulfillable due to invalid item amounts or
     *      other factors; callers should determine whether validated orders are
     *      fulfillable by simulating the fulfillment call prior to execution.
     *      Also note that anyone can validate a signed order, but only the
     *      offerer can validate an order without supplying a signature.
     *
     * @param orders The orders to validate.
     *
     * @return validated A boolean indicating whether the supplied orders were
     *                   successfully validated.
     */
    function _validate(
        Order[] memory orders,
        SeaportInterface seaport
    ) internal view returns (bool validated) {
        (, bytes32 domainSeparator, ) = seaport.information();

        // Declare variables outside of the loop.
        OrderStatus memory orderStatus;
        bytes32 orderHash;
        address offerer;

        // Skip overflow check as for loop is indexed starting at zero.
        unchecked {
            // Read length of the orders array from memory and place on stack.
            uint256 totalOrders = orders.length;

            // Iterate over each order.
            for (uint256 i = 0; i < totalOrders; ++i) {
                // Retrieve the order.
                Order memory order = orders[i];

                // Retrieve the order parameters.
                OrderParameters memory orderParameters = order.parameters;

                // Skip contract orders.
                if (orderParameters.orderType == OrderType.CONTRACT) {
                    continue;
                }

                // Move offerer from memory to the stack.
                offerer = orderParameters.offerer;

                // Get current counter & use it w/ params to derive order hash.
                orderHash = _assertConsiderationLengthAndGetOrderHash(
                    orderParameters,
                    seaport
                );

                {
                    // Retrieve the order status using the derived order hash.
                    (
                        bool isValidated,
                        bool isCancelled,
                        uint256 totalFilled,
                        uint256 totalSize
                    ) = seaport.getOrderStatus(orderHash);
                    orderStatus = OrderStatus(
                        isValidated,
                        isCancelled,
                        uint120(totalFilled),
                        uint120(totalSize)
                    );
                }

                // Ensure order is fillable and retrieve the filled amount.
                _verifyOrderStatus(
                    orderHash,
                    orderStatus,
                    false, // Signifies that partially filled orders are valid.
                    true // Signifies to revert if the order is invalid.
                );

                // If the order has not already been validated...
                if (!orderStatus.isValidated) {
                    // Ensure that consideration array length is equal to the
                    // total original consideration items value.
                    if (
                        orderParameters.consideration.length !=
                        orderParameters.totalOriginalConsiderationItems
                    ) {
                        _revertConsiderationLengthNotEqualToTotalOriginal();
                    }

                    // Verify the supplied signature.
                    _verifySignature(
                        offerer,
                        orderHash,
                        order.signature,
                        domainSeparator
                    );

                    // Update order status to mark the order as valid.
                    // orderStatus.isValidated = true;

                    // Emit an event signifying the order has been validated.
                    // emit OrderValidated(orderHash, orderParameters);
                }
            }
        }

        // Return a boolean indicating that orders were successfully validated.
        validated = true;
    }

    /**
     * @dev Internal view function to validate that a given order is fillable
     *      and not cancelled based on the order status.
     *
     * @param orderHash       The order hash.
     * @param orderStatus     The status of the order, including whether it has
     *                        been cancelled and the fraction filled.
     * @param onlyAllowUnused A boolean flag indicating whether partial fills
     *                        are supported by the calling function.
     * @param revertOnInvalid A boolean indicating whether to revert if the
     *                        order has been cancelled or filled beyond the
     *                        allowable amount.
     *
     * @return valid A boolean indicating whether the order is valid.
     */
    function _verifyOrderStatus(
        bytes32 orderHash,
        OrderStatus memory orderStatus,
        bool onlyAllowUnused,
        bool revertOnInvalid
    ) internal pure returns (bool valid) {
        // Ensure that the order has not been cancelled.
        if (orderStatus.isCancelled) {
            // Only revert if revertOnInvalid has been supplied as true.
            if (revertOnInvalid) {
                _revertOrderIsCancelled(orderHash);
            }

            // Return false as the order status is invalid.
            return false;
        }

        // Read order status numerator and place on stack.
        uint256 orderStatusNumerator = orderStatus.numerator;

        // If the order is not entirely unused...
        if (orderStatusNumerator != 0) {
            // ensure the order has not been partially filled when not allowed.
            if (onlyAllowUnused) {
                // Always revert on partial fills when onlyAllowUnused is true.
                _revertOrderPartiallyFilled(orderHash);
            }
            // Otherwise, ensure that order has not been entirely filled.
            else if (orderStatusNumerator >= orderStatus.denominator) {
                // Only revert if revertOnInvalid has been supplied as true.
                if (revertOnInvalid) {
                    _revertOrderAlreadyFilled(orderHash);
                }

                // Return false as the order status is invalid.
                return false;
            }
        }

        // Return true as the order status is valid.
        valid = true;
    }

    /**
     * @dev Internal view function to verify the signature of an order. An
     *      ERC-1271 fallback will be attempted if either the signature length
     *      is not 64 or 65 bytes or if the recovered signer does not match the
     *      supplied offerer. Note that in cases where a 64 or 65 byte signature
     *      is supplied, only standard ECDSA signatures that recover to a
     *      non-zero address are supported.
     *
     * @param offerer   The offerer for the order.
     * @param orderHash The order hash.
     * @param signature A signature from the offerer indicating that the order
     *                  has been approved.
     */
    function _verifySignature(
        address offerer,
        bytes32 orderHash,
        bytes memory signature,
        bytes32 domainSeparator
    ) internal view {
        // Determine whether the offerer is the caller.
        bool offererIsCaller;
        assembly {
            offererIsCaller := eq(offerer, caller())
        }

        // Skip signature verification if the offerer is the caller.
        if (offererIsCaller) {
            return;
        }

        // Derive original EIP-712 digest using domain separator and order hash.
        bytes32 originalDigest = _deriveEIP712Digest(
            domainSeparator,
            orderHash
        );

        // Read the length of the signature from memory and place on the stack.
        uint256 originalSignatureLength = signature.length;

        // Determine effective digest if signature has a valid bulk order size.
        bytes32 digest;
        if (_isValidBulkOrderSize(originalSignatureLength)) {
            // Rederive order hash and digest using bulk order proof.
            (orderHash) = _computeBulkOrderProof(signature, orderHash);
            digest = _deriveEIP712Digest(domainSeparator, orderHash);
        } else {
            // Supply the original digest as the effective digest.
            digest = originalDigest;
        }

        // Ensure that the signature for the digest is valid for the offerer.
        _assertValidSignature(
            offerer,
            digest,
            originalDigest,
            originalSignatureLength,
            signature
        );
    }

    /**
     * @dev Determines whether the specified bulk order size is valid.
     *
     * @param signatureLength The signature length of the bulk order to check.
     *
     * @return validLength True if bulk order size is valid, false otherwise.
     */
    function _isValidBulkOrderSize(
        uint256 signatureLength
    ) internal pure returns (bool validLength) {
        // Utilize assembly to validate the length; the equivalent logic is
        // (64 + x) + 3 + 32y where (0 <= x <= 1) and (1 <= y <= 24).
        assembly {
            validLength := and(
                lt(
                    sub(signatureLength, BulkOrderProof_minSize),
                    BulkOrderProof_rangeSize
                ),
                lt(
                    and(
                        add(
                            signatureLength,
                            BulkOrderProof_lengthAdjustmentBeforeMask
                        ),
                        ThirtyOneBytes
                    ),
                    BulkOrderProof_lengthRangeAfterMask
                )
            )
        }
    }

    /**
     * @dev Computes the bulk order hash for the specified proof and leaf. Note
     *      that if an index that exceeds the number of orders in the bulk order
     *      payload will instead "wrap around" and refer to an earlier index.
     *
     * @param proofAndSignature The proof and signature of the bulk order.
     * @param leaf              The leaf of the bulk order tree.
     *
     * @return bulkOrderHash The bulk order hash.
     */
    function _computeBulkOrderProof(
        bytes memory proofAndSignature,
        bytes32 leaf
    ) internal pure returns (bytes32 bulkOrderHash) {
        // Declare arguments for the root hash and the height of the proof.
        bytes32 root;
        uint256 height;

        // Utilize assembly to efficiently derive the root hash using the proof.
        assembly {
            // Retrieve the length of the proof, key, and signature combined.
            let fullLength := mload(proofAndSignature)

            // If proofAndSignature has odd length, it is a compact signature
            // with 64 bytes.
            let signatureLength := sub(ECDSA_MaxLength, and(fullLength, 1))

            // Derive height (or depth of tree) with signature and proof length.
            height := shr(OneWordShift, sub(fullLength, signatureLength))

            // Update the length in memory to only include the signature.
            mstore(proofAndSignature, signatureLength)

            // Derive the pointer for the key using the signature length.
            let keyPtr := add(proofAndSignature, add(OneWord, signatureLength))

            // Retrieve the three-byte key using the derived pointer.
            let key := shr(BulkOrderProof_keyShift, mload(keyPtr))

            /// Retrieve pointer to first proof element by applying a constant
            // for the key size to the derived key pointer.
            let proof := add(keyPtr, BulkOrderProof_keySize)

            // Compute level 1.
            let scratchPtr1 := shl(OneWordShift, and(key, 1))
            mstore(scratchPtr1, leaf)
            mstore(xor(scratchPtr1, OneWord), mload(proof))

            // Compute remaining proofs.
            for {
                let i := 1
            } lt(i, height) {
                i := add(i, 1)
            } {
                proof := add(proof, OneWord)
                let scratchPtr := shl(OneWordShift, and(shr(i, key), 1))
                mstore(scratchPtr, keccak256(0, TwoWords))
                mstore(xor(scratchPtr, OneWord), mload(proof))
            }

            // Compute root hash.
            root := keccak256(0, TwoWords)
        }

        // Retrieve appropriate typehash constant based on height.
        bytes32 rootTypeHash = _lookupBulkOrderTypehash(height);

        // Use the typehash and the root hash to derive final bulk order hash.
        assembly {
            mstore(0, rootTypeHash)
            mstore(OneWord, root)
            bulkOrderHash := keccak256(0, TwoWords)
        }
    }

    /**
     * @dev Internal pure function to look up one of twenty-four potential bulk
     *      order typehash constants based on the height of the bulk order tree.
     *      Note that values between one and twenty-four are supported, which is
     *      enforced by _isValidBulkOrderSize.
     *
     * @param _treeHeight The height of the bulk order tree. The value must be
     *                    between one and twenty-four.
     *
     * @return _typeHash The EIP-712 typehash for the bulk order type with the
     *                   given height.
     */
    function _lookupBulkOrderTypehash(
        uint256 _treeHeight
    ) internal pure returns (bytes32 _typeHash) {
        // Utilize assembly to efficiently retrieve correct bulk order typehash.
        assembly {
            // Use a Yul function to enable use of the `leave` keyword
            // to stop searching once the appropriate type hash is found.
            function lookupTypeHash(treeHeight) -> typeHash {
                // Handle tree heights one through eight.
                if lt(treeHeight, 9) {
                    // Handle tree heights one through four.
                    if lt(treeHeight, 5) {
                        // Handle tree heights one and two.
                        if lt(treeHeight, 3) {
                            // Utilize branchless logic to determine typehash.
                            typeHash := ternary(
                                eq(treeHeight, 1),
                                BulkOrder_Typehash_Height_One,
                                BulkOrder_Typehash_Height_Two
                            )

                            // Exit the function once typehash has been located.
                            leave
                        }

                        // Handle height three and four via branchless logic.
                        typeHash := ternary(
                            eq(treeHeight, 3),
                            BulkOrder_Typehash_Height_Three,
                            BulkOrder_Typehash_Height_Four
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle tree height five and six.
                    if lt(treeHeight, 7) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 5),
                            BulkOrder_Typehash_Height_Five,
                            BulkOrder_Typehash_Height_Six
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle height seven and eight via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 7),
                        BulkOrder_Typehash_Height_Seven,
                        BulkOrder_Typehash_Height_Eight
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height nine through sixteen.
                if lt(treeHeight, 17) {
                    // Handle tree height nine through twelve.
                    if lt(treeHeight, 13) {
                        // Handle tree height nine and ten.
                        if lt(treeHeight, 11) {
                            // Utilize branchless logic to determine typehash.
                            typeHash := ternary(
                                eq(treeHeight, 9),
                                BulkOrder_Typehash_Height_Nine,
                                BulkOrder_Typehash_Height_Ten
                            )

                            // Exit the function once typehash has been located.
                            leave
                        }

                        // Handle height eleven and twelve via branchless logic.
                        typeHash := ternary(
                            eq(treeHeight, 11),
                            BulkOrder_Typehash_Height_Eleven,
                            BulkOrder_Typehash_Height_Twelve
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle tree height thirteen and fourteen.
                    if lt(treeHeight, 15) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 13),
                            BulkOrder_Typehash_Height_Thirteen,
                            BulkOrder_Typehash_Height_Fourteen
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }
                    // Handle height fifteen and sixteen via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 15),
                        BulkOrder_Typehash_Height_Fifteen,
                        BulkOrder_Typehash_Height_Sixteen
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height seventeen through twenty.
                if lt(treeHeight, 21) {
                    // Handle tree height seventeen and eighteen.
                    if lt(treeHeight, 19) {
                        // Utilize branchless logic to determine typehash.
                        typeHash := ternary(
                            eq(treeHeight, 17),
                            BulkOrder_Typehash_Height_Seventeen,
                            BulkOrder_Typehash_Height_Eighteen
                        )

                        // Exit the function once typehash has been located.
                        leave
                    }

                    // Handle height nineteen and twenty via branchless logic.
                    typeHash := ternary(
                        eq(treeHeight, 19),
                        BulkOrder_Typehash_Height_Nineteen,
                        BulkOrder_Typehash_Height_Twenty
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle tree height twenty-one and twenty-two.
                if lt(treeHeight, 23) {
                    // Utilize branchless logic to determine typehash.
                    typeHash := ternary(
                        eq(treeHeight, 21),
                        BulkOrder_Typehash_Height_TwentyOne,
                        BulkOrder_Typehash_Height_TwentyTwo
                    )

                    // Exit the function once typehash has been located.
                    leave
                }

                // Handle height twenty-three & twenty-four w/ branchless logic.
                typeHash := ternary(
                    eq(treeHeight, 23),
                    BulkOrder_Typehash_Height_TwentyThree,
                    BulkOrder_Typehash_Height_TwentyFour
                )

                // Exit the function once typehash has been located.
                leave
            }

            // Implement ternary conditional using branchless logic.
            function ternary(cond, ifTrue, ifFalse) -> c {
                c := xor(ifFalse, mul(cond, xor(ifFalse, ifTrue)))
            }

            // Look up the typehash using the supplied tree height.
            _typeHash := lookupTypeHash(_treeHeight)
        }
    }

    /**
     * @dev Internal view function to ensure that the supplied consideration
     *      array length on a given set of order parameters is not less than the
     *      original consideration array length for that order and to retrieve
     *      the current counter for a given order's offerer and zone and use it
     *      to derive the order hash.
     *
     * @param orderParameters The parameters of the order to hash.
     *
     * @return The hash.
     */
    function _assertConsiderationLengthAndGetOrderHash(
        OrderParameters memory orderParameters,
        SeaportInterface seaport
    ) internal view returns (bytes32) {
        // Ensure supplied consideration array length is not less than original.
        _assertConsiderationLengthIsNotLessThanOriginalConsiderationLength(
            orderParameters.consideration.length,
            orderParameters.totalOriginalConsiderationItems
        );

        // Derive and return order hash using current counter for the offerer.
        return
            _deriveOrderHash(
                orderParameters,
                _getCounter(seaport, orderParameters.offerer),
                seaport
            );
    }

    function _getCounter(
        SeaportInterface seaport,
        address offerer
    ) internal view returns (uint256) {
        return seaport.getCounter(offerer);
    }

    function _deriveOrderHash(
        OrderParameters memory orderParameters,
        uint256 counter,
        SeaportInterface seaport
    ) internal view returns (bytes32 orderHash) {
        return
            seaport.getOrderHash(_toOrderComponents(orderParameters, counter));
    }

    /**
     * @dev Converts an OrderParameters struct into an OrderComponents struct.
     *
     * @param parameters the OrderParameters struct to convert
     * @param counter    the counter to use for the OrderComponents struct
     *
     * @return components the OrderComponents struct
     */
    function _toOrderComponents(
        OrderParameters memory parameters,
        uint256 counter
    ) internal pure returns (OrderComponents memory components) {
        components.offerer = parameters.offerer;
        components.zone = parameters.zone;
        components.offer = parameters.offer;
        components.consideration = parameters.consideration;
        components.orderType = parameters.orderType;
        components.startTime = parameters.startTime;
        components.endTime = parameters.endTime;
        components.zoneHash = parameters.zoneHash;
        components.salt = parameters.salt;
        components.conduitKey = parameters.conduitKey;
        components.counter = counter;
    }

    /**
     * @dev Internal pure function to efficiently derive an digest to sign for
     *      an order in accordance with EIP-712.
     *
     * @param domainSeparator The domain separator.
     * @param orderHash       The order hash.
     *
     * @return value The hash.
     */
    function _deriveEIP712Digest(
        bytes32 domainSeparator,
        bytes32 orderHash
    ) internal pure returns (bytes32 value) {
        // Leverage scratch space to perform an efficient hash.
        assembly {
            // Place the EIP-712 prefix at the start of scratch space.
            mstore(0, EIP_712_PREFIX)

            // Place the domain separator in the next region of scratch space.
            mstore(EIP712_DomainSeparator_offset, domainSeparator)

            // Place the order hash in scratch space, spilling into the first
            // two bytes of the free memory pointer — this should never be set
            // as memory cannot be expanded to that size, and will be zeroed out
            // after the hash is performed.
            mstore(EIP712_OrderHash_offset, orderHash)

            // Hash the relevant region (65 bytes).
            value := keccak256(0, EIP712_DigestPayload_size)

            // Clear out the dirtied bits in the memory pointer.
            mstore(EIP712_OrderHash_offset, 0)
        }
    }

    /**
     * @dev Internal pure function to ensure that the supplied consideration
     *      array length for an order to be fulfilled is not less than the
     *      original consideration array length for that order.
     *
     * @param suppliedConsiderationItemTotal The number of consideration items
     *                                       supplied when fulfilling the order.
     * @param originalConsiderationItemTotal The number of consideration items
     *                                       supplied on initial order creation.
     */
    function _assertConsiderationLengthIsNotLessThanOriginalConsiderationLength(
        uint256 suppliedConsiderationItemTotal,
        uint256 originalConsiderationItemTotal
    ) internal pure {
        // Ensure supplied consideration array length is not less than original.
        if (suppliedConsiderationItemTotal < originalConsiderationItemTotal) {
            _revertMissingOriginalConsiderationItems();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED,

    // 4: contract order type
    CONTRACT
}

enum BasicOrderType {
    // 0: no partial fills, anyone can execute
    ETH_TO_ERC721_FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    ETH_TO_ERC721_PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    ETH_TO_ERC721_FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC721_PARTIAL_RESTRICTED,

    // 4: no partial fills, anyone can execute
    ETH_TO_ERC1155_FULL_OPEN,

    // 5: partial fills supported, anyone can execute
    ETH_TO_ERC1155_PARTIAL_OPEN,

    // 6: no partial fills, only offerer or zone can execute
    ETH_TO_ERC1155_FULL_RESTRICTED,

    // 7: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC1155_PARTIAL_RESTRICTED,

    // 8: no partial fills, anyone can execute
    ERC20_TO_ERC721_FULL_OPEN,

    // 9: partial fills supported, anyone can execute
    ERC20_TO_ERC721_PARTIAL_OPEN,

    // 10: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC721_FULL_RESTRICTED,

    // 11: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC721_PARTIAL_RESTRICTED,

    // 12: no partial fills, anyone can execute
    ERC20_TO_ERC1155_FULL_OPEN,

    // 13: partial fills supported, anyone can execute
    ERC20_TO_ERC1155_PARTIAL_OPEN,

    // 14: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC1155_FULL_RESTRICTED,

    // 15: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

    // 16: no partial fills, anyone can execute
    ERC721_TO_ERC20_FULL_OPEN,

    // 17: partial fills supported, anyone can execute
    ERC721_TO_ERC20_PARTIAL_OPEN,

    // 18: no partial fills, only offerer or zone can execute
    ERC721_TO_ERC20_FULL_RESTRICTED,

    // 19: partial fills supported, only offerer or zone can execute
    ERC721_TO_ERC20_PARTIAL_RESTRICTED,

    // 20: no partial fills, anyone can execute
    ERC1155_TO_ERC20_FULL_OPEN,

    // 21: partial fills supported, anyone can execute
    ERC1155_TO_ERC20_PARTIAL_OPEN,

    // 22: no partial fills, only offerer or zone can execute
    ERC1155_TO_ERC20_FULL_RESTRICTED,

    // 23: partial fills supported, only offerer or zone can execute
    ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}

enum BasicOrderRouteType {
    // 0: provide Ether (or other native token) to receive offered ERC721 item.
    ETH_TO_ERC721,

    // 1: provide Ether (or other native token) to receive offered ERC1155 item.
    ETH_TO_ERC1155,

    // 2: provide ERC20 item to receive offered ERC721 item.
    ERC20_TO_ERC721,

    // 3: provide ERC20 item to receive offered ERC1155 item.
    ERC20_TO_ERC1155,

    // 4: provide ERC721 item to receive offered ERC20 item.
    ERC721_TO_ERC20,

    // 5: provide ERC1155 item to receive offered ERC20 item.
    ERC1155_TO_ERC20
}

enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}

enum Side {
    // 0: Items that can be spent
    OFFER,

    // 1: Items that must be received
    CONSIDERATION
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {
    BasicOrderType,
    ItemType,
    OrderType,
    Side
} from "./ConsiderationEnums.sol";

import {
    CalldataPointer,
    MemoryPointer
} from "../helpers/PointerLibraries.sol";

/**
 * @dev An order contains eleven components: an offerer, a zone (or account that
 *      can cancel the order or restrict who can fulfill the order depending on
 *      the type), the order type (specifying partial fill support as well as
 *      restricted order status), the start and end time, a hash that will be
 *      provided to the zone when validating restricted orders, a salt, a key
 *      corresponding to a given conduit, a counter, and an arbitrary number of
 *      offer items that can be spent along with consideration items that must
 *      be received by their respective recipient.
 */
struct OrderComponents {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 counter;
}

/**
 * @dev An offer item has five components: an item type (ETH or other native
 *      tokens, ERC20, ERC721, and ERC1155, as well as criteria-based ERC721 and
 *      ERC1155), a token address, a dual-purpose "identifierOrCriteria"
 *      component that will either represent a tokenId or a merkle root
 *      depending on the item type, and a start and end amount that support
 *      increasing or decreasing amounts over the duration of the respective
 *      order.
 */
struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

/**
 * @dev A consideration item has the same five components as an offer item and
 *      an additional sixth component designating the required recipient of the
 *      item.
 */
struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

/**
 * @dev A spent item is translated from a utilized offer item and has four
 *      components: an item type (ETH or other native tokens, ERC20, ERC721, and
 *      ERC1155), a token address, a tokenId, and an amount.
 */
struct SpentItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
}

/**
 * @dev A received item is translated from a utilized consideration item and has
 *      the same four components as a spent item, as well as an additional fifth
 *      component designating the required recipient of the item.
 */
struct ReceivedItem {
    ItemType itemType;
    address token;
    uint256 identifier;
    uint256 amount;
    address payable recipient;
}

/**
 * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
 *      matching, a group of six functions may be called that only requires a
 *      subset of the usual order arguments. Note the use of a "basicOrderType"
 *      enum; this represents both the usual order type as well as the "route"
 *      of the basic order (a simple derivation function for the basic order
 *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
 */
struct BasicOrderParameters {
    // calldata offset
    address considerationToken; // 0x24
    uint256 considerationIdentifier; // 0x44
    uint256 considerationAmount; // 0x64
    address payable offerer; // 0x84
    address zone; // 0xa4
    address offerToken; // 0xc4
    uint256 offerIdentifier; // 0xe4
    uint256 offerAmount; // 0x104
    BasicOrderType basicOrderType; // 0x124
    uint256 startTime; // 0x144
    uint256 endTime; // 0x164
    bytes32 zoneHash; // 0x184
    uint256 salt; // 0x1a4
    bytes32 offererConduitKey; // 0x1c4
    bytes32 fulfillerConduitKey; // 0x1e4
    uint256 totalOriginalAdditionalRecipients; // 0x204
    AdditionalRecipient[] additionalRecipients; // 0x224
    bytes signature; // 0x244
    // Total length, excluding dynamic array data: 0x264 (580)
}

/**
 * @dev Basic orders can supply any number of additional recipients, with the
 *      implied assumption that they are supplied from the offered ETH (or other
 *      native token) or ERC20 token for the order.
 */
struct AdditionalRecipient {
    uint256 amount;
    address payable recipient;
}

/**
 * @dev The full set of order components, with the exception of the counter,
 *      must be supplied when fulfilling more sophisticated orders or groups of
 *      orders. The total number of original consideration items must also be
 *      supplied, as the caller may specify additional consideration items.
 */
struct OrderParameters {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}

/**
 * @dev Orders require a signature in addition to the other order parameters.
 */
struct Order {
    OrderParameters parameters;
    bytes signature;
}

/**
 * @dev Advanced orders include a numerator (i.e. a fraction to attempt to fill)
 *      and a denominator (the total size of the order) in addition to the
 *      signature and other order parameters. It also supports an optional field
 *      for supplying extra data; this data will be provided to the zone if the
 *      order type is restricted and the zone is not the caller, or will be
 *      provided to the offerer as context for contract order types.
 */
struct AdvancedOrder {
    OrderParameters parameters;
    uint120 numerator;
    uint120 denominator;
    bytes signature;
    bytes extraData;
}

/**
 * @dev Orders can be validated (either explicitly via `validate`, or as a
 *      consequence of a full or partial fill), specifically cancelled (they can
 *      also be cancelled in bulk via incrementing a per-zone counter), and
 *      partially or fully filled (with the fraction filled represented by a
 *      numerator and denominator).
 */
struct OrderStatus {
    bool isValidated;
    bool isCancelled;
    uint120 numerator;
    uint120 denominator;
}

/**
 * @dev A criteria resolver specifies an order, side (offer vs. consideration),
 *      and item index. It then provides a chosen identifier (i.e. tokenId)
 *      alongside a merkle proof demonstrating the identifier meets the required
 *      criteria.
 */
struct CriteriaResolver {
    uint256 orderIndex;
    Side side;
    uint256 index;
    uint256 identifier;
    bytes32[] criteriaProof;
}

/**
 * @dev A fulfillment is applied to a group of orders. It decrements a series of
 *      offer and consideration items, then generates a single execution
 *      element. A given fulfillment can be applied to as many offer and
 *      consideration items as desired, but must contain at least one offer and
 *      at least one consideration that match. The fulfillment must also remain
 *      consistent on all key parameters across all offer items (same offerer,
 *      token, type, tokenId, and conduit preference) as well as across all
 *      consideration items (token, type, tokenId, and recipient).
 */
struct Fulfillment {
    FulfillmentComponent[] offerComponents;
    FulfillmentComponent[] considerationComponents;
}

/**
 * @dev Each fulfillment component contains one index referencing a specific
 *      order and another referencing a specific offer or consideration item.
 */
struct FulfillmentComponent {
    uint256 orderIndex;
    uint256 itemIndex;
}

/**
 * @dev An execution is triggered once all consideration items have been zeroed
 *      out. It sends the item in question from the offerer to the item's
 *      recipient, optionally sourcing approvals from either this contract
 *      directly or from the offerer's chosen conduit if one is specified. An
 *      execution is not provided as an argument, but rather is derived via
 *      orders, criteria resolvers, and fulfillments (where the total number of
 *      executions will be less than or equal to the total number of indicated
 *      fulfillments) and returned as part of `matchOrders`.
 */
struct Execution {
    ReceivedItem item;
    address offerer;
    bytes32 conduitKey;
}

/**
 * @dev Restricted orders are validated post-execution by calling validateOrder
 *      on the zone. This struct provides context about the order fulfillment
 *      and any supplied extraData, as well as all order hashes fulfilled in a
 *      call to a match or fulfillAvailable method.
 */
struct ZoneParameters {
    bytes32 orderHash;
    address fulfiller;
    address offerer;
    SpentItem[] offer;
    ReceivedItem[] consideration;
    bytes extraData;
    bytes32[] orderHashes;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
}

/**
 * @dev Zones and contract offerers can communicate which schemas they implement
 *      along with any associated metadata related to each schema.
 */
struct Schema {
    uint256 id;
    bytes metadata;
}

using StructPointers for OrderComponents global;
using StructPointers for OfferItem global;
using StructPointers for ConsiderationItem global;
using StructPointers for SpentItem global;
using StructPointers for ReceivedItem global;
using StructPointers for BasicOrderParameters global;
using StructPointers for AdditionalRecipient global;
using StructPointers for OrderParameters global;
using StructPointers for Order global;
using StructPointers for AdvancedOrder global;
using StructPointers for OrderStatus global;
using StructPointers for CriteriaResolver global;
using StructPointers for Fulfillment global;
using StructPointers for FulfillmentComponent global;
using StructPointers for Execution global;
using StructPointers for ZoneParameters global;

/**
 * @dev This library provides a set of functions for converting structs to
 *      pointers.
 */
library StructPointers {
    /**
     * @dev Get a MemoryPointer from OrderComponents.
     *
     * @param obj The OrderComponents object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        OrderComponents memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from OrderComponents.
     *
     * @param obj The OrderComponents object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        OrderComponents calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from OfferItem.
     *
     * @param obj The OfferItem object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        OfferItem memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from OfferItem.
     *
     * @param obj The OfferItem object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        OfferItem calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from ConsiderationItem.
     *
     * @param obj The ConsiderationItem object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        ConsiderationItem memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from ConsiderationItem.
     *
     * @param obj The ConsiderationItem object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        ConsiderationItem calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from SpentItem.
     *
     * @param obj The SpentItem object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        SpentItem memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from SpentItem.
     *
     * @param obj The SpentItem object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        SpentItem calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from ReceivedItem.
     *
     * @param obj The ReceivedItem object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        ReceivedItem memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from ReceivedItem.
     *
     * @param obj The ReceivedItem object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        ReceivedItem calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from BasicOrderParameters.
     *
     * @param obj The BasicOrderParameters object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        BasicOrderParameters memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from BasicOrderParameters.
     *
     * @param obj The BasicOrderParameters object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        BasicOrderParameters calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from AdditionalRecipient.
     *
     * @param obj The AdditionalRecipient object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        AdditionalRecipient memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from AdditionalRecipient.
     *
     * @param obj The AdditionalRecipient object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        AdditionalRecipient calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from OrderParameters.
     *
     * @param obj The OrderParameters object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        OrderParameters memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from OrderParameters.
     *
     * @param obj The OrderParameters object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        OrderParameters calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from Order.
     *
     * @param obj The Order object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        Order memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from Order.
     *
     * @param obj The Order object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        Order calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from AdvancedOrder.
     *
     * @param obj The AdvancedOrder object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        AdvancedOrder memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from AdvancedOrder.
     *
     * @param obj The AdvancedOrder object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        AdvancedOrder calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from OrderStatus.
     *
     * @param obj The OrderStatus object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        OrderStatus memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from OrderStatus.
     *
     * @param obj The OrderStatus object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        OrderStatus calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from CriteriaResolver.
     *
     * @param obj The CriteriaResolver object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        CriteriaResolver memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from CriteriaResolver.
     *
     * @param obj The CriteriaResolver object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        CriteriaResolver calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from Fulfillment.
     *
     * @param obj The Fulfillment object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        Fulfillment memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from Fulfillment.
     *
     * @param obj The Fulfillment object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        Fulfillment calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from FulfillmentComponent.
     *
     * @param obj The FulfillmentComponent object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        FulfillmentComponent memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from FulfillmentComponent.
     *
     * @param obj The FulfillmentComponent object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        FulfillmentComponent calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from Execution.
     *
     * @param obj The Execution object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        Execution memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from Execution.
     *
     * @param obj The Execution object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        Execution calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a MemoryPointer from ZoneParameters.
     *
     * @param obj The ZoneParameters object.
     *
     * @return ptr The MemoryPointer.
     */
    function toMemoryPointer(
        ZoneParameters memory obj
    ) internal pure returns (MemoryPointer ptr) {
        assembly {
            ptr := obj
        }
    }

    /**
     * @dev Get a CalldataPointer from ZoneParameters.
     *
     * @param obj The ZoneParameters object.
     *
     * @return ptr The CalldataPointer.
     */
    function toCalldataPointer(
        ZoneParameters calldata obj
    ) internal pure returns (CalldataPointer ptr) {
        assembly {
            ptr := obj
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Side } from "./ConsiderationEnums.sol";

import {
    BadFraction_error_length,
    BadFraction_error_selector,
    CannotCancelOrder_error_length,
    CannotCancelOrder_error_selector,
    ConsiderationLengthNotEqualToTotalOriginal_error_length,
    ConsiderationLengthNotEqualToTotalOriginal_error_selector,
    ConsiderationNotMet_error_considerationIndex_ptr,
    ConsiderationNotMet_error_length,
    ConsiderationNotMet_error_orderIndex_ptr,
    ConsiderationNotMet_error_selector,
    ConsiderationNotMet_error_shortfallAmount_ptr,
    CriteriaNotEnabledForItem_error_length,
    CriteriaNotEnabledForItem_error_selector,
    Error_selector_offset,
    InsufficientNativeTokensSupplied_error_length,
    InsufficientNativeTokensSupplied_error_selector,
    InvalidBasicOrderParameterEncoding_error_length,
    InvalidBasicOrderParameterEncoding_error_selector,
    InvalidCallToConduit_error_conduit_ptr,
    InvalidCallToConduit_error_length,
    InvalidCallToConduit_error_selector,
    InvalidConduit_error_conduit_ptr,
    InvalidConduit_error_conduitKey_ptr,
    InvalidConduit_error_length,
    InvalidConduit_error_selector,
    InvalidContractOrder_error_length,
    InvalidContractOrder_error_orderHash_ptr,
    InvalidContractOrder_error_selector,
    InvalidERC721TransferAmount_error_amount_ptr,
    InvalidERC721TransferAmount_error_length,
    InvalidERC721TransferAmount_error_selector,
    InvalidMsgValue_error_length,
    InvalidMsgValue_error_selector,
    InvalidMsgValue_error_value_ptr,
    InvalidNativeOfferItem_error_length,
    InvalidNativeOfferItem_error_selector,
    InvalidProof_error_length,
    InvalidProof_error_selector,
    InvalidTime_error_endTime_ptr,
    InvalidTime_error_length,
    InvalidTime_error_selector,
    InvalidTime_error_startTime_ptr,
    MismatchedOfferAndConsiderationComponents_error_idx_ptr,
    MismatchedOfferAndConsiderationComponents_error_length,
    MismatchedOfferAndConsiderationComponents_error_selector,
    MissingFulfillmentComponentOnAggregation_error_length,
    MissingFulfillmentComponentOnAggregation_error_selector,
    MissingFulfillmentComponentOnAggregation_error_side_ptr,
    MissingOriginalConsiderationItems_error_length,
    MissingOriginalConsiderationItems_error_selector,
    NoReentrantCalls_error_length,
    NoReentrantCalls_error_selector,
    NoSpecifiedOrdersAvailable_error_length,
    NoSpecifiedOrdersAvailable_error_selector,
    OfferAndConsiderationRequiredOnFulfillment_error_length,
    OfferAndConsiderationRequiredOnFulfillment_error_selector,
    OrderAlreadyFilled_error_length,
    OrderAlreadyFilled_error_orderHash_ptr,
    OrderAlreadyFilled_error_selector,
    OrderCriteriaResolverOutOfRange_error_length,
    OrderCriteriaResolverOutOfRange_error_selector,
    OrderCriteriaResolverOutOfRange_error_side_ptr,
    OrderIsCancelled_error_length,
    OrderIsCancelled_error_orderHash_ptr,
    OrderIsCancelled_error_selector,
    OrderPartiallyFilled_error_length,
    OrderPartiallyFilled_error_orderHash_ptr,
    OrderPartiallyFilled_error_selector,
    PartialFillsNotEnabledForOrder_error_length,
    PartialFillsNotEnabledForOrder_error_selector,
    UnresolvedConsiderationCriteria_error_considerationIdx_ptr,
    UnresolvedConsiderationCriteria_error_length,
    UnresolvedConsiderationCriteria_error_orderIndex_ptr,
    UnresolvedConsiderationCriteria_error_selector,
    UnresolvedOfferCriteria_error_length,
    UnresolvedOfferCriteria_error_offerIndex_ptr,
    UnresolvedOfferCriteria_error_orderIndex_ptr,
    UnresolvedOfferCriteria_error_selector,
    UnusedItemParameters_error_length,
    UnusedItemParameters_error_selector
} from "./ConsiderationErrorConstants.sol";

/**
 * @dev Reverts the current transaction with a "BadFraction" error message.
 */
function _revertBadFraction() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, BadFraction_error_selector)

        // revert(abi.encodeWithSignature("BadFraction()"))
        revert(Error_selector_offset, BadFraction_error_length)
    }
}

/**
 * @dev Reverts the current transaction with a "ConsiderationNotMet" error
 *      message, including the provided order index, consideration index, and
 *      shortfall amount.
 *
 * @param orderIndex         The index of the order that did not meet the
 *                           consideration criteria.
 * @param considerationIndex The index of the consideration item that did not
 *                           meet its criteria.
 * @param shortfallAmount    The amount by which the consideration criteria were
 *                           not met.
 */
function _revertConsiderationNotMet(
    uint256 orderIndex,
    uint256 considerationIndex,
    uint256 shortfallAmount
) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, ConsiderationNotMet_error_selector)

        // Store arguments.
        mstore(ConsiderationNotMet_error_orderIndex_ptr, orderIndex)
        mstore(
            ConsiderationNotMet_error_considerationIndex_ptr,
            considerationIndex
        )
        mstore(ConsiderationNotMet_error_shortfallAmount_ptr, shortfallAmount)

        // revert(abi.encodeWithSignature(
        //     "ConsiderationNotMet(uint256,uint256,uint256)",
        //     orderIndex,
        //     considerationIndex,
        //     shortfallAmount
        // ))
        revert(Error_selector_offset, ConsiderationNotMet_error_length)
    }
}

/**
 * @dev Reverts the current transaction with a "CriteriaNotEnabledForItem" error
 *      message.
 */
function _revertCriteriaNotEnabledForItem() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, CriteriaNotEnabledForItem_error_selector)

        // revert(abi.encodeWithSignature("CriteriaNotEnabledForItem()"))
        revert(Error_selector_offset, CriteriaNotEnabledForItem_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an
 *      "InsufficientNativeTokensSupplied" error message.
 */
function _revertInsufficientNativeTokensSupplied() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InsufficientNativeTokensSupplied_error_selector)

        // revert(abi.encodeWithSignature("InsufficientNativeTokensSupplied()"))
        revert(
            Error_selector_offset,
            InsufficientNativeTokensSupplied_error_length
        )
    }
}

/**
 * @dev Reverts the current transaction with an
 *      "InvalidBasicOrderParameterEncoding" error message.
 */
function _revertInvalidBasicOrderParameterEncoding() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidBasicOrderParameterEncoding_error_selector)

        // revert(abi.encodeWithSignature(
        //     "InvalidBasicOrderParameterEncoding()"
        // ))
        revert(
            Error_selector_offset,
            InvalidBasicOrderParameterEncoding_error_length
        )
    }
}

/**
 * @dev Reverts the current transaction with an "InvalidCallToConduit" error
 *      message, including the provided address of the conduit that was called
 *      improperly.
 *
 * @param conduit The address of the conduit that was called improperly.
 */
function _revertInvalidCallToConduit(address conduit) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidCallToConduit_error_selector)

        // Store argument.
        mstore(InvalidCallToConduit_error_conduit_ptr, conduit)

        // revert(abi.encodeWithSignature(
        //     "InvalidCallToConduit(address)",
        //     conduit
        // ))
        revert(Error_selector_offset, InvalidCallToConduit_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an "CannotCancelOrder" error
 *      message.
 */
function _revertCannotCancelOrder() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, CannotCancelOrder_error_selector)

        // revert(abi.encodeWithSignature("CannotCancelOrder()"))
        revert(Error_selector_offset, CannotCancelOrder_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an "InvalidConduit" error message,
 *      including the provided key and address of the invalid conduit.
 *
 * @param conduitKey    The key of the invalid conduit.
 * @param conduit       The address of the invalid conduit.
 */
function _revertInvalidConduit(bytes32 conduitKey, address conduit) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidConduit_error_selector)

        // Store arguments.
        mstore(InvalidConduit_error_conduitKey_ptr, conduitKey)
        mstore(InvalidConduit_error_conduit_ptr, conduit)

        // revert(abi.encodeWithSignature(
        //     "InvalidConduit(bytes32,address)",
        //     conduitKey,
        //     conduit
        // ))
        revert(Error_selector_offset, InvalidConduit_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an "InvalidERC721TransferAmount"
 *      error message.
 *
 * @param amount The invalid amount.
 */
function _revertInvalidERC721TransferAmount(uint256 amount) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidERC721TransferAmount_error_selector)

        // Store argument.
        mstore(InvalidERC721TransferAmount_error_amount_ptr, amount)

        // revert(abi.encodeWithSignature(
        //     "InvalidERC721TransferAmount(uint256)",
        //     amount
        // ))
        revert(Error_selector_offset, InvalidERC721TransferAmount_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an "InvalidMsgValue" error message,
 *      including the invalid value that was sent in the transaction's
 *      `msg.value` field.
 *
 * @param value The invalid value that was sent in the transaction's `msg.value`
 *              field.
 */
function _revertInvalidMsgValue(uint256 value) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidMsgValue_error_selector)

        // Store argument.
        mstore(InvalidMsgValue_error_value_ptr, value)

        // revert(abi.encodeWithSignature("InvalidMsgValue(uint256)", value))
        revert(Error_selector_offset, InvalidMsgValue_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an "InvalidNativeOfferItem" error
 *      message.
 */
function _revertInvalidNativeOfferItem() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidNativeOfferItem_error_selector)

        // revert(abi.encodeWithSignature("InvalidNativeOfferItem()"))
        revert(Error_selector_offset, InvalidNativeOfferItem_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an "InvalidProof" error message.
 */
function _revertInvalidProof() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidProof_error_selector)

        // revert(abi.encodeWithSignature("InvalidProof()"))
        revert(Error_selector_offset, InvalidProof_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an "InvalidContractOrder" error
 *      message.
 *
 * @param orderHash The hash of the contract order that caused the error.
 */
function _revertInvalidContractOrder(bytes32 orderHash) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidContractOrder_error_selector)

        // Store arguments.
        mstore(InvalidContractOrder_error_orderHash_ptr, orderHash)

        // revert(abi.encodeWithSignature(
        //     "InvalidContractOrder(bytes32)",
        //     orderHash
        // ))
        revert(Error_selector_offset, InvalidContractOrder_error_length)
    }
}

/**
 * @dev Reverts the current transaction with an "InvalidTime" error message.
 *
 * @param startTime       The time at which the order becomes active.
 * @param endTime         The time at which the order becomes inactive.
 */
function _revertInvalidTime(uint256 startTime, uint256 endTime) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, InvalidTime_error_selector)

        // Store arguments.
        mstore(InvalidTime_error_startTime_ptr, startTime)
        mstore(InvalidTime_error_endTime_ptr, endTime)

        // revert(abi.encodeWithSignature(
        //     "InvalidTime(uint256,uint256)",
        //     startTime,
        //     endTime
        // ))
        revert(Error_selector_offset, InvalidTime_error_length)
    }
}

/**
 * @dev Reverts execution with a
 *      "MismatchedFulfillmentOfferAndConsiderationComponents" error message.
 *
 * @param fulfillmentIndex         The index of the fulfillment that caused the
 *                                 error.
 */
function _revertMismatchedFulfillmentOfferAndConsiderationComponents(
    uint256 fulfillmentIndex
) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, MismatchedOfferAndConsiderationComponents_error_selector)

        // Store fulfillment index argument.
        mstore(
            MismatchedOfferAndConsiderationComponents_error_idx_ptr,
            fulfillmentIndex
        )

        // revert(abi.encodeWithSignature(
        //     "MismatchedFulfillmentOfferAndConsiderationComponents(uint256)",
        //     fulfillmentIndex
        // ))
        revert(
            Error_selector_offset,
            MismatchedOfferAndConsiderationComponents_error_length
        )
    }
}

/**
 * @dev Reverts execution with a "MissingFulfillmentComponentOnAggregation"
 *       error message.
 *
 * @param side The side of the fulfillment component that is missing (0 for
 *             offer, 1 for consideration).
 *
 */
function _revertMissingFulfillmentComponentOnAggregation(Side side) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, MissingFulfillmentComponentOnAggregation_error_selector)

        // Store argument.
        mstore(MissingFulfillmentComponentOnAggregation_error_side_ptr, side)

        // revert(abi.encodeWithSignature(
        //     "MissingFulfillmentComponentOnAggregation(uint8)",
        //     side
        // ))
        revert(
            Error_selector_offset,
            MissingFulfillmentComponentOnAggregation_error_length
        )
    }
}

/**
 * @dev Reverts execution with a "MissingOriginalConsiderationItems" error
 *      message.
 */
function _revertMissingOriginalConsiderationItems() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, MissingOriginalConsiderationItems_error_selector)

        // revert(abi.encodeWithSignature(
        //     "MissingOriginalConsiderationItems()"
        // ))
        revert(
            Error_selector_offset,
            MissingOriginalConsiderationItems_error_length
        )
    }
}

/**
 * @dev Reverts execution with a "NoReentrantCalls" error message.
 */
function _revertNoReentrantCalls() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, NoReentrantCalls_error_selector)

        // revert(abi.encodeWithSignature("NoReentrantCalls()"))
        revert(Error_selector_offset, NoReentrantCalls_error_length)
    }
}

/**
 * @dev Reverts execution with a "NoSpecifiedOrdersAvailable" error message.
 */
function _revertNoSpecifiedOrdersAvailable() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, NoSpecifiedOrdersAvailable_error_selector)

        // revert(abi.encodeWithSignature("NoSpecifiedOrdersAvailable()"))
        revert(Error_selector_offset, NoSpecifiedOrdersAvailable_error_length)
    }
}

/**
 * @dev Reverts execution with a "OfferAndConsiderationRequiredOnFulfillment"
 *      error message.
 */
function _revertOfferAndConsiderationRequiredOnFulfillment() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, OfferAndConsiderationRequiredOnFulfillment_error_selector)

        // revert(abi.encodeWithSignature(
        //     "OfferAndConsiderationRequiredOnFulfillment()"
        // ))
        revert(
            Error_selector_offset,
            OfferAndConsiderationRequiredOnFulfillment_error_length
        )
    }
}

/**
 * @dev Reverts execution with an "OrderAlreadyFilled" error message.
 *
 * @param orderHash The hash of the order that has already been filled.
 */
function _revertOrderAlreadyFilled(bytes32 orderHash) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, OrderAlreadyFilled_error_selector)

        // Store argument.
        mstore(OrderAlreadyFilled_error_orderHash_ptr, orderHash)

        // revert(abi.encodeWithSignature(
        //     "OrderAlreadyFilled(bytes32)",
        //     orderHash
        // ))
        revert(Error_selector_offset, OrderAlreadyFilled_error_length)
    }
}

/**
 * @dev Reverts execution with an "OrderCriteriaResolverOutOfRange" error
 *      message.
 *
 * @param side The side of the criteria that is missing (0 for offer, 1 for
 *             consideration).
 *
 */
function _revertOrderCriteriaResolverOutOfRange(Side side) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, OrderCriteriaResolverOutOfRange_error_selector)

        // Store argument.
        mstore(OrderCriteriaResolverOutOfRange_error_side_ptr, side)

        // revert(abi.encodeWithSignature(
        //     "OrderCriteriaResolverOutOfRange(uint8)",
        //     side
        // ))
        revert(
            Error_selector_offset,
            OrderCriteriaResolverOutOfRange_error_length
        )
    }
}

/**
 * @dev Reverts execution with an "OrderIsCancelled" error message.
 *
 * @param orderHash The hash of the order that has already been cancelled.
 */
function _revertOrderIsCancelled(bytes32 orderHash) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, OrderIsCancelled_error_selector)

        // Store argument.
        mstore(OrderIsCancelled_error_orderHash_ptr, orderHash)

        // revert(abi.encodeWithSignature(
        //     "OrderIsCancelled(bytes32)",
        //     orderHash
        // ))
        revert(Error_selector_offset, OrderIsCancelled_error_length)
    }
}

/**
 * @dev Reverts execution with an "OrderPartiallyFilled" error message.
 *
 * @param orderHash The hash of the order that has already been partially
 *                  filled.
 */
function _revertOrderPartiallyFilled(bytes32 orderHash) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, OrderPartiallyFilled_error_selector)

        // Store argument.
        mstore(OrderPartiallyFilled_error_orderHash_ptr, orderHash)

        // revert(abi.encodeWithSignature(
        //     "OrderPartiallyFilled(bytes32)",
        //     orderHash
        // ))
        revert(Error_selector_offset, OrderPartiallyFilled_error_length)
    }
}

/**
 * @dev Reverts execution with a "PartialFillsNotEnabledForOrder" error message.
 */
function _revertPartialFillsNotEnabledForOrder() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, PartialFillsNotEnabledForOrder_error_selector)

        // revert(abi.encodeWithSignature("PartialFillsNotEnabledForOrder()"))
        revert(
            Error_selector_offset,
            PartialFillsNotEnabledForOrder_error_length
        )
    }
}

/**
 * @dev Reverts execution with an "UnresolvedConsiderationCriteria" error
 *      message.
 */
function _revertUnresolvedConsiderationCriteria(
    uint256 orderIndex,
    uint256 considerationIndex
) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, UnresolvedConsiderationCriteria_error_selector)

        // Store orderIndex and considerationIndex arguments.
        mstore(UnresolvedConsiderationCriteria_error_orderIndex_ptr, orderIndex)
        mstore(
            UnresolvedConsiderationCriteria_error_considerationIdx_ptr,
            considerationIndex
        )

        // revert(abi.encodeWithSignature(
        //     "UnresolvedConsiderationCriteria(uint256, uint256)",
        //     orderIndex,
        //     considerationIndex
        // ))
        revert(
            Error_selector_offset,
            UnresolvedConsiderationCriteria_error_length
        )
    }
}

/**
 * @dev Reverts execution with an "UnresolvedOfferCriteria" error message.
 */
function _revertUnresolvedOfferCriteria(
    uint256 orderIndex,
    uint256 offerIndex
) pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, UnresolvedOfferCriteria_error_selector)

        // Store arguments.
        mstore(UnresolvedOfferCriteria_error_orderIndex_ptr, orderIndex)
        mstore(UnresolvedOfferCriteria_error_offerIndex_ptr, offerIndex)

        // revert(abi.encodeWithSignature(
        //     "UnresolvedOfferCriteria(uint256, uint256)",
        //     orderIndex,
        //     offerIndex
        // ))
        revert(Error_selector_offset, UnresolvedOfferCriteria_error_length)
    }
}

/**
 * @dev Reverts execution with an "UnusedItemParameters" error message.
 */
function _revertUnusedItemParameters() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, UnusedItemParameters_error_selector)

        // revert(abi.encodeWithSignature("UnusedItemParameters()"))
        revert(Error_selector_offset, UnusedItemParameters_error_length)
    }
}

/**
 * @dev Reverts execution with a "ConsiderationLengthNotEqualToTotalOriginal"
 *      error message.
 */
function _revertConsiderationLengthNotEqualToTotalOriginal() pure {
    assembly {
        // Store left-padded selector with push4 (reduces bytecode),
        // mem[28:32] = selector
        mstore(0, ConsiderationLengthNotEqualToTotalOriginal_error_selector)

        // revert(abi.encodeWithSignature(
        //     "ConsiderationLengthNotEqualToTotalOriginal()"
        // ))
        revert(
            Error_selector_offset,
            ConsiderationLengthNotEqualToTotalOriginal_error_length
        )
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SignatureVerificationErrors} from "seaport-types/src/interfaces/SignatureVerificationErrors.sol";

import {LowLevelHelpers} from "./LowLevelHelpers.sol";

import {
    ECDSA_MaxLength,
    ECDSA_signature_s_offset,
    ECDSA_signature_v_offset,
    ECDSA_twentySeventhAndTwentyEighthBytesSet,
    Ecrecover_args_size,
    Ecrecover_precompile,
    EIP1271_isValidSignature_calldata_baseLength,
    EIP1271_isValidSignature_digest_negativeOffset,
    EIP1271_isValidSignature_selector_negativeOffset,
    EIP1271_isValidSignature_selector,
    EIP1271_isValidSignature_signature_head_offset,
    EIP2098_allButHighestBitMask,
    MaxUint8,
    OneWord,
    Signature_lower_v
} from "seaport-types/src/lib/ConsiderationConstants.sol";

import {
    BadContractSignature_error_length,
    BadContractSignature_error_selector,
    BadSignatureV_error_length,
    BadSignatureV_error_selector,
    BadSignatureV_error_v_ptr,
    Error_selector_offset,
    InvalidSignature_error_length,
    InvalidSignature_error_selector,
    InvalidSigner_error_length,
    InvalidSigner_error_selector
} from "seaport-types/src/lib/ConsiderationErrorConstants.sol";

/**
 * @title SignatureVerification
 * @author 0age
 * @notice SignatureVerification contains logic for verifying signatures.
 */
contract SignatureVerification is SignatureVerificationErrors, LowLevelHelpers {
    /**
     * @dev Internal view function to verify the signature of an order. An
     *      ERC-1271 fallback will be attempted if either the signature length
     *      is not 64 or 65 bytes or if the recovered signer does not match the
     *      supplied signer.
     *
     * @param signer                  The signer for the order.
     * @param digest                  The digest to verify signature against.
     * @param originalDigest          The original digest to verify signature
     *                                against.
     * @param originalSignatureLength The original signature length.
     * @param signature               A signature from the signer indicating
     *                                that the order has been approved.
     */
    function _assertValidSignature(
        address signer,
        bytes32 digest,
        bytes32 originalDigest,
        uint256 originalSignatureLength,
        bytes memory signature
    ) internal view {
        // Declare value for ecrecover equality or 1271 call success status.
        bool success;

        // Utilize assembly to perform optimized signature verification check.
        assembly {
            // Ensure that first word of scratch space is empty.
            mstore(0, 0)

            // Get the length of the signature.
            let signatureLength := mload(signature)

            // Get the pointer to the value preceding the signature length.
            // This will be used for temporary memory overrides - either the
            // signature head for isValidSignature or the digest for ecrecover.
            let wordBeforeSignaturePtr := sub(signature, OneWord)

            // Cache the current value behind the signature to restore it later.
            let cachedWordBeforeSignature := mload(wordBeforeSignaturePtr)

            // Declare lenDiff + recoveredSigner scope to manage stack pressure.
            {
                // Take the difference between the max ECDSA signature length
                // and the actual signature length. Overflow desired for any
                // values > 65. If the diff is not 0 or 1, it is not a valid
                // ECDSA signature - move on to EIP1271 check.
                let lenDiff := sub(ECDSA_MaxLength, signatureLength)

                // Declare variable for recovered signer.
                let recoveredSigner

                // If diff is 0 or 1, it may be an ECDSA signature.
                // Try to recover signer.
                if iszero(gt(lenDiff, 1)) {
                    // Read the signature `s` value.
                    let originalSignatureS := mload(add(signature, ECDSA_signature_s_offset))

                    // Read the first byte of the word after `s`. If the
                    // signature is 65 bytes, this will be the real `v` value.
                    // If not, it will need to be modified - doing it this way
                    // saves an extra condition.
                    let v := byte(0, mload(add(signature, ECDSA_signature_v_offset)))

                    // If lenDiff is 1, parse 64-byte signature as ECDSA.
                    if lenDiff {
                        // Extract yParity from highest bit of vs and add 27 to
                        // get v.
                        v := add(shr(MaxUint8, originalSignatureS), Signature_lower_v)

                        // Extract canonical s from vs, all but the highest bit.
                        // Temporarily overwrite the original `s` value in the
                        // signature.
                        mstore(
                            add(signature, ECDSA_signature_s_offset),
                            and(originalSignatureS, EIP2098_allButHighestBitMask)
                        )
                    }
                    // Temporarily overwrite the signature length with `v` to
                    // conform to the expected input for ecrecover.
                    mstore(signature, v)

                    // Temporarily overwrite the word before the length with
                    // `digest` to conform to the expected input for ecrecover.
                    mstore(wordBeforeSignaturePtr, digest)

                    // Attempt to recover the signer for the given signature. Do
                    // not check the call status as ecrecover will return a null
                    // address if the signature is invalid.
                    pop(
                        staticcall(
                            gas(),
                            Ecrecover_precompile, // Call ecrecover precompile.
                            wordBeforeSignaturePtr, // Use data memory location.
                            Ecrecover_args_size, // Size of digest, v, r, and s.
                            0, // Write result to scratch space.
                            OneWord // Provide size of returned result.
                        )
                    )

                    // Restore cached word before signature.
                    mstore(wordBeforeSignaturePtr, cachedWordBeforeSignature)

                    // Restore cached signature length.
                    mstore(signature, signatureLength)

                    // Restore cached signature `s` value.
                    mstore(add(signature, ECDSA_signature_s_offset), originalSignatureS)

                    // Read the recovered signer from the buffer given as return
                    // space for ecrecover.
                    recoveredSigner := mload(0)
                }

                // Set success to true if the signature provided was a valid
                // ECDSA signature and the signer is not the null address. Use
                // gt instead of direct as success is used outside of assembly.
                success := and(eq(signer, recoveredSigner), gt(signer, 0))
            }

            // If the signature was not verified with ecrecover, try EIP1271.
            if iszero(success) {
                // Reset the original signature length.
                mstore(signature, originalSignatureLength)

                // Temporarily overwrite the word before the signature length
                // and use it as the head of the signature input to
                // `isValidSignature`, which has a value of 64.
                mstore(wordBeforeSignaturePtr, EIP1271_isValidSignature_signature_head_offset)

                // Get pointer to use for the selector of `isValidSignature`.
                let selectorPtr := sub(signature, EIP1271_isValidSignature_selector_negativeOffset)

                // Cache the value currently stored at the selector pointer.
                let cachedWordOverwrittenBySelector := mload(selectorPtr)

                // Cache the value currently stored at the digest pointer.
                let cachedWordOverwrittenByDigest :=
                    mload(sub(signature, EIP1271_isValidSignature_digest_negativeOffset))

                // Write the selector first, since it overlaps the digest.
                mstore(selectorPtr, EIP1271_isValidSignature_selector)

                // Next, write the original digest.
                mstore(sub(signature, EIP1271_isValidSignature_digest_negativeOffset), originalDigest)

                // Call signer with `isValidSignature` to validate signature.
                success :=
                    staticcall(
                        gas(),
                        signer,
                        selectorPtr,
                        add(originalSignatureLength, EIP1271_isValidSignature_calldata_baseLength),
                        0,
                        OneWord
                    )

                // Determine if the signature is valid on successful calls.
                if success {
                    // If first word of scratch space does not contain EIP-1271
                    // signature selector, revert.
                    if iszero(eq(mload(0), EIP1271_isValidSignature_selector)) {
                        // Revert with bad 1271 signature if signer has code.
                        if extcodesize(signer) {
                            // Bad contract signature.
                            // Store left-padded selector with push4, mem[28:32]
                            mstore(0, BadContractSignature_error_selector)

                            // revert(abi.encodeWithSignature(
                            //     "BadContractSignature()"
                            // ))
                            revert(Error_selector_offset, BadContractSignature_error_length)
                        }

                        // Check if signature length was invalid.
                        if gt(sub(ECDSA_MaxLength, signatureLength), 1) {
                            // Revert with generic invalid signature error.
                            // Store left-padded selector with push4, mem[28:32]
                            mstore(0, InvalidSignature_error_selector)

                            // revert(abi.encodeWithSignature(
                            //     "InvalidSignature()"
                            // ))
                            revert(Error_selector_offset, InvalidSignature_error_length)
                        }

                        // Check if v was invalid.
                        if and(
                            eq(signatureLength, ECDSA_MaxLength),
                            iszero(
                                byte(
                                    byte(0, mload(add(signature, ECDSA_signature_v_offset))),
                                    ECDSA_twentySeventhAndTwentyEighthBytesSet
                                )
                            )
                        ) {
                            // Revert with invalid v value.
                            // Store left-padded selector with push4, mem[28:32]
                            mstore(0, BadSignatureV_error_selector)
                            mstore(BadSignatureV_error_v_ptr, byte(0, mload(add(signature, ECDSA_signature_v_offset))))

                            // revert(abi.encodeWithSignature(
                            //     "BadSignatureV(uint8)", v
                            // ))
                            revert(Error_selector_offset, BadSignatureV_error_length)
                        }

                        // Revert with generic invalid signer error message.
                        // Store left-padded selector with push4, mem[28:32]
                        mstore(0, InvalidSigner_error_selector)

                        // revert(abi.encodeWithSignature("InvalidSigner()"))
                        revert(Error_selector_offset, InvalidSigner_error_length)
                    }
                }

                // Restore the cached values overwritten by selector, digest and
                // signature head.
                mstore(wordBeforeSignaturePtr, cachedWordBeforeSignature)
                mstore(selectorPtr, cachedWordOverwrittenBySelector)
                mstore(sub(signature, EIP1271_isValidSignature_digest_negativeOffset), cachedWordOverwrittenByDigest)
            }
        }

        // If the call failed...
        if (!success) {
            // Revert and pass reason along if one was returned.
            _revertWithReasonIfOneIsReturned();

            // Otherwise, revert with error indicating bad contract signature.
            assembly {
                // Store left-padded selector with push4, mem[28:32] = selector
                mstore(0, BadContractSignature_error_selector)
                // revert(abi.encodeWithSignature("BadContractSignature()"))
                revert(Error_selector_offset, BadContractSignature_error_length)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ConsiderationInterface as SeaportInterface} from "seaport-types/src/interfaces/ConsiderationInterface.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*
 * -------------------------- Disambiguation & Other Notes ---------------------
 *    - The term "head" is used as it is in the documentation for ABI encoding,
 *      but only in reference to dynamic types, i.e. it always refers to the
 *      offset or pointer to the body of a dynamic type. In calldata, the head
 *      is always an offset (relative to the parent object), while in memory,
 *      the head is always the pointer to the body. More information found here:
 *      https://docs.soliditylang.org/en/v0.8.17/abi-spec.html#argument-encoding
 *        - Note that the length of an array is separate from and precedes the
 *          head of the array.
 *
 *    - The term "body" is used in place of the term "head" used in the ABI
 *      documentation. It refers to the start of the data for a dynamic type,
 *      e.g. the first word of a struct or the first word of the first element
 *      in an array.
 *
 *    - The term "pointer" is used to describe the absolute position of a value
 *      and never an offset relative to another value.
 *        - The suffix "_ptr" refers to a memory pointer.
 *        - The suffix "_cdPtr" refers to a calldata pointer.
 *
 *    - The term "offset" is used to describe the position of a value relative
 *      to some parent value. For example, OrderParameters_conduit_offset is the
 *      offset to the "conduit" value in the OrderParameters struct relative to
 *      the start of the body.
 *        - Note: Offsets are used to derive pointers.
 *
 *    - Some structs have pointers defined for all of their fields in this file.
 *      Lines which are commented out are fields that are not used in the
 *      codebase but have been left in for readability.
 */

// Declare constants for name, version, and reentrancy sentinel values.

// Name is right padded, so it touches the length which is left padded. This
// enables writing both values at once. Length goes at byte 95 in memory, and
// name fills bytes 96-109, so both values can be written left-padded to 77.
uint256 constant NameLengthPtr = 0x4D;
uint256 constant NameWithLength = 0x0d436F6E73696465726174696F6E;

uint256 constant information_version_offset = 0;
uint256 constant information_version_cd_offset = 0x60;
uint256 constant information_domainSeparator_offset = 0x20;
uint256 constant information_conduitController_offset = 0x40;
uint256 constant information_versionLengthPtr = 0x63;
uint256 constant information_versionWithLength = 0x03312e35; // 1.5
uint256 constant information_length = 0xa0;

uint256 constant _NOT_ENTERED = 1;
uint256 constant _ENTERED = 2;
uint256 constant _ENTERED_AND_ACCEPTING_NATIVE_TOKENS = 3;

uint256 constant Offset_fulfillAdvancedOrder_criteriaResolvers = 0x20;
uint256 constant Offset_fulfillAvailableOrders_offerFulfillments = 0x20;
uint256 constant Offset_fulfillAvailableOrders_considerationFulfillments = 0x40;
uint256 constant Offset_fulfillAvailableAdvancedOrders_criteriaResolvers = 0x20;
uint256 constant Offset_fulfillAvailableAdvancedOrders_offerFulfillments = 0x40;
uint256 constant Offset_fulfillAvailableAdvancedOrders_cnsdrationFlflmnts = (
    0x60
);

uint256 constant Offset_matchOrders_fulfillments = 0x20;

uint256 constant Offset_matchAdvancedOrders_criteriaResolvers = 0x20;
uint256 constant Offset_matchAdvancedOrders_fulfillments = 0x40;

// Common Offsets
// Offsets for identically positioned fields shared by:
// OfferItem, ConsiderationItem, SpentItem, ReceivedItem

uint256 constant Selector_length = 0x4;

uint256 constant Common_token_offset = 0x20;
uint256 constant Common_identifier_offset = 0x40;
uint256 constant Common_amount_offset = 0x60;
uint256 constant Common_endAmount_offset = 0x80;

uint256 constant SpentItem_size = 0x80;
uint256 constant SpentItem_size_shift = 0x7;

uint256 constant OfferItem_size = 0xa0;
uint256 constant OfferItem_size_with_length = 0xc0;

uint256 constant ReceivedItem_size_excluding_recipient = 0x80;
uint256 constant ReceivedItem_size = 0xa0;
uint256 constant ReceivedItem_amount_offset = 0x60;
uint256 constant ReceivedItem_recipient_offset = 0x80;

uint256 constant ReceivedItem_CommonParams_size = 0x60;

uint256 constant ConsiderationItem_size = 0xc0;
uint256 constant ConsiderationItem_size_with_length = 0xe0;

uint256 constant ConsiderationItem_recipient_offset = 0xa0;
// Store the same constant in an abbreviated format for a line length fix.
uint256 constant ConsiderItem_recipient_offset = 0xa0;

uint256 constant Execution_offerer_offset = 0x20;
uint256 constant Execution_conduit_offset = 0x40;

// uint256 constant OrderParameters_offerer_offset = 0x00;
uint256 constant OrderParameters_zone_offset = 0x20;
uint256 constant OrderParameters_offer_head_offset = 0x40;
uint256 constant OrderParameters_consideration_head_offset = 0x60;
// uint256 constant OrderParameters_orderType_offset = 0x80;
uint256 constant OrderParameters_startTime_offset = 0xa0;
uint256 constant OrderParameters_endTime_offset = 0xc0;
uint256 constant OrderParameters_zoneHash_offset = 0xe0;
// uint256 constant OrderParameters_salt_offset = 0x100;
uint256 constant OrderParameters_conduit_offset = 0x120;
uint256 constant OrderParameters_counter_offset = 0x140;

uint256 constant Fulfillment_itemIndex_offset = 0x20;

uint256 constant AdvancedOrder_head_size = 0xa0;
uint256 constant AdvancedOrder_numerator_offset = 0x20;
uint256 constant AdvancedOrder_denominator_offset = 0x40;
uint256 constant AdvancedOrder_signature_offset = 0x60;
uint256 constant AdvancedOrder_extraData_offset = 0x80;

uint256 constant OrderStatus_ValidatedAndNotCancelled = 1;
uint256 constant OrderStatus_filledNumerator_offset = 0x10;
uint256 constant OrderStatus_filledDenominator_offset = 0x88;

uint256 constant ThirtyOneBytes = 0x1f;
uint256 constant OneWord = 0x20;
uint256 constant TwoWords = 0x40;
uint256 constant ThreeWords = 0x60;
uint256 constant FourWords = 0x80;
uint256 constant FiveWords = 0xa0;

uint256 constant OneWordShift = 0x5;
uint256 constant TwoWordsShift = 0x6;

uint256 constant SixtyThreeBytes = 0x3f;
uint256 constant OnlyFullWordMask = 0xffffffe0;

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant ZeroSlot = 0x60;
uint256 constant DefaultFreeMemoryPointer = 0x80;

uint256 constant Slot0x80 = 0x80;
uint256 constant Slot0xA0 = 0xa0;

// uint256 constant BasicOrder_endAmount_cdPtr = 0x104;
uint256 constant BasicOrder_common_params_size = 0xa0;
uint256 constant BasicOrder_considerationHashesArray_ptr = 0x160;
uint256 constant BasicOrder_receivedItemByteMap = (
    0x0000010102030000000000000000000000000000000000000000000000000000
);
uint256 constant BasicOrder_offeredItemByteMap = (
    0x0203020301010000000000000000000000000000000000000000000000000000
);

bytes32 constant OrdersMatchedTopic0 = (
    0x4b9f2d36e1b4c93de62cc077b00b1a91d84b6c31b4a14e012718dcca230689e7
);

uint256 constant EIP712_Order_size = 0x180;
uint256 constant EIP712_OfferItem_size = 0xc0;
uint256 constant EIP712_ConsiderationItem_size = 0xe0;
uint256 constant AdditionalRecipient_size = 0x40;
uint256 constant AdditionalRecipient_size_shift = 0x6;

uint256 constant EIP712_DomainSeparator_offset = 0x02;
uint256 constant EIP712_OrderHash_offset = 0x22;
uint256 constant EIP712_DigestPayload_size = 0x42;

uint256 constant EIP712_domainData_nameHash_offset = 0x20;
uint256 constant EIP712_domainData_versionHash_offset = 0x40;
uint256 constant EIP712_domainData_chainId_offset = 0x60;
uint256 constant EIP712_domainData_verifyingContract_offset = 0x80;
uint256 constant EIP712_domainData_size = 0xa0;

// Minimum BulkOrder proof size: 64 bytes for signature + 3 for key + 32 for 1
// sibling. Maximum BulkOrder proof size: 65 bytes for signature + 3 for key +
// 768 for 24 siblings.

uint256 constant BulkOrderProof_minSize = 0x63;
uint256 constant BulkOrderProof_rangeSize = 0x2e2;
uint256 constant BulkOrderProof_lengthAdjustmentBeforeMask = 0x1d;
uint256 constant BulkOrderProof_lengthRangeAfterMask = 0x2;
uint256 constant BulkOrderProof_keyShift = 0xe8;
uint256 constant BulkOrderProof_keySize = 0x3;

uint256 constant BulkOrder_Typehash_Height_One = (
    0x3ca2711d29384747a8f61d60aad3c450405f7aaff5613541dee28df2d6986d32
);
uint256 constant BulkOrder_Typehash_Height_Two = (
    0xbf8e29b89f29ed9b529c154a63038ffca562f8d7cd1e2545dda53a1b582dde30
);
uint256 constant BulkOrder_Typehash_Height_Three = (
    0x53c6f6856e13104584dd0797ca2b2779202dc2597c6066a42e0d8fe990b0024d
);
uint256 constant BulkOrder_Typehash_Height_Four = (
    0xa02eb7ff164c884e5e2c336dc85f81c6a93329d8e9adf214b32729b894de2af1
);
uint256 constant BulkOrder_Typehash_Height_Five = (
    0x39c9d33c18e050dda0aeb9a8086fb16fc12d5d64536780e1da7405a800b0b9f6
);
uint256 constant BulkOrder_Typehash_Height_Six = (
    0x1c19f71958cdd8f081b4c31f7caf5c010b29d12950be2fa1c95070dc47e30b55
);
uint256 constant BulkOrder_Typehash_Height_Seven = (
    0xca74fab2fece9a1d58234a274220ad05ca096a92ef6a1ca1750b9d90c948955c
);
uint256 constant BulkOrder_Typehash_Height_Eight = (
    0x7ff98d9d4e55d876c5cfac10b43c04039522f3ddfb0ea9bfe70c68cfb5c7cc14
);
uint256 constant BulkOrder_Typehash_Height_Nine = (
    0xbed7be92d41c56f9e59ac7a6272185299b815ddfabc3f25deb51fe55fe2f9e8a
);
uint256 constant BulkOrder_Typehash_Height_Ten = (
    0xd1d97d1ef5eaa37a4ee5fbf234e6f6d64eb511eb562221cd7edfbdde0848da05
);
uint256 constant BulkOrder_Typehash_Height_Eleven = (
    0x896c3f349c4da741c19b37fec49ed2e44d738e775a21d9c9860a69d67a3dae53
);
uint256 constant BulkOrder_Typehash_Height_Twelve = (
    0xbb98d87cc12922b83759626c5f07d72266da9702d19ffad6a514c73a89002f5f
);
uint256 constant BulkOrder_Typehash_Height_Thirteen = (
    0xe6ae19322608dd1f8a8d56aab48ed9c28be489b689f4b6c91268563efc85f20e
);
uint256 constant BulkOrder_Typehash_Height_Fourteen = (
    0x6b5b04cbae4fcb1a9d78e7b2dfc51a36933d023cf6e347e03d517b472a852590
);
uint256 constant BulkOrder_Typehash_Height_Fifteen = (
    0xd1eb68309202b7106b891e109739dbbd334a1817fe5d6202c939e75cf5e35ca9
);
uint256 constant BulkOrder_Typehash_Height_Sixteen = (
    0x1da3eed3ecef6ebaa6e5023c057ec2c75150693fd0dac5c90f4a142f9879fde8
);
uint256 constant BulkOrder_Typehash_Height_Seventeen = (
    0xeee9a1392aa395c7002308119a58f2582777a75e54e0c1d5d5437bd2e8bf6222
);
uint256 constant BulkOrder_Typehash_Height_Eighteen = (
    0xc3939feff011e53ab8c35ca3370aad54c5df1fc2938cd62543174fa6e7d85877
);
uint256 constant BulkOrder_Typehash_Height_Nineteen = (
    0x0efca7572ac20f5ae84db0e2940674f7eca0a4726fa1060ffc2d18cef54b203d
);
uint256 constant BulkOrder_Typehash_Height_Twenty = (
    0x5a4f867d3d458dabecad65f6201ceeaba0096df2d0c491cc32e6ea4e64350017
);
uint256 constant BulkOrder_Typehash_Height_TwentyOne = (
    0x80987079d291feebf21c2230e69add0f283cee0b8be492ca8050b4185a2ff719
);
uint256 constant BulkOrder_Typehash_Height_TwentyTwo = (
    0x3bd8cff538aba49a9c374c806d277181e9651624b3e31111bc0624574f8bca1d
);
uint256 constant BulkOrder_Typehash_Height_TwentyThree = (
    0x5d6a3f098a0bc373f808c619b1bb4028208721b3c4f8d6bc8a874d659814eb76
);
uint256 constant BulkOrder_Typehash_Height_TwentyFour = (
    0x1d51df90cba8de7637ca3e8fe1e3511d1dc2f23487d05dbdecb781860c21ac1c
);

uint256 constant receivedItemsHash_ptr = 0x60;

/*
 *  Memory layout in _prepareBasicFulfillmentFromCalldata of
 *  data for OrderFulfilled
 *
 *   event OrderFulfilled(
 *     bytes32 orderHash,
 *     address indexed offerer,
 *     address indexed zone,
 *     address fulfiller,
 *     SpentItem[] offer,
 *       > (itemType, token, id, amount)
 *     ReceivedItem[] consideration
 *       > (itemType, token, id, amount, recipient)
 *   )
 *
 *  - 0x00: orderHash
 *  - 0x20: fulfiller
 *  - 0x40: offer offset (0x80)
 *  - 0x60: consideration offset (0x120)
 *  - 0x80: offer.length (1)
 *  - 0xa0: offerItemType
 *  - 0xc0: offerToken
 *  - 0xe0: offerIdentifier
 *  - 0x100: offerAmount
 *  - 0x120: consideration.length (1 + additionalRecipients.length)
 *  - 0x140: considerationItemType
 *  - 0x160: considerationToken
 *  - 0x180: considerationIdentifier
 *  - 0x1a0: considerationAmount
 *  - 0x1c0: considerationRecipient
 *  - ...
 */

// Minimum length of the OrderFulfilled event data.
// Must be added to the size of the ReceivedItem array for additionalRecipients
// (0xa0 * additionalRecipients.length) to calculate full size of the buffer.
uint256 constant OrderFulfilled_baseSize = 0x1e0;
uint256 constant OrderFulfilled_selector = (
    0x9d9af8e38d66c62e2c12f0225249fd9d721c54b83f48d9352c97c6cacdcb6f31
);

// Minimum offset in memory to OrderFulfilled event data.
// Must be added to the size of the EIP712 hash array for additionalRecipients
// (32 * additionalRecipients.length) to calculate the pointer to event data.
uint256 constant OrderFulfilled_baseOffset = 0x180;
uint256 constant OrderFulfilled_consideration_length_baseOffset = 0x2a0;
uint256 constant OrderFulfilled_offer_length_baseOffset = 0x200;

// Related constants used for restricted order checks on basic orders.
uint256 constant OrderFulfilled_baseDataSize = 0x160;
// uint256 constant ValidateOrder_offerDataOffset = 0x184;
// uint256 constant RatifyOrder_offerDataOffset = 0xc4;

// uint256 constant OrderFulfilled_orderHash_offset = 0x00;
uint256 constant OrderFulfilled_fulfiller_offset = 0x20;
uint256 constant OrderFulfilled_offer_head_offset = 0x40;
uint256 constant OrderFulfilled_offer_body_offset = 0x80;
uint256 constant OrderFulfilled_consideration_head_offset = 0x60;
uint256 constant OrderFulfilled_consideration_body_offset = 0x120;

// BasicOrderParameters
uint256 constant BasicOrder_parameters_cdPtr = 0x04;
uint256 constant BasicOrder_considerationToken_cdPtr = 0x24;
uint256 constant BasicOrder_considerationIdentifier_cdPtr = 0x44;
uint256 constant BasicOrder_considerationAmount_cdPtr = 0x64;
uint256 constant BasicOrder_offerer_cdPtr = 0x84;
uint256 constant BasicOrder_zone_cdPtr = 0xa4;
uint256 constant BasicOrder_offerToken_cdPtr = 0xc4;
uint256 constant BasicOrder_offerIdentifier_cdPtr = 0xe4;
uint256 constant BasicOrder_offerAmount_cdPtr = 0x104;
uint256 constant BasicOrder_basicOrderType_cdPtr = 0x124;
uint256 constant BasicOrder_startTime_cdPtr = 0x144;
uint256 constant BasicOrder_endTime_cdPtr = 0x164;
// uint256 constant BasicOrder_zoneHash_cdPtr = 0x184;
// uint256 constant BasicOrder_salt_cdPtr = 0x1a4;
uint256 constant BasicOrder_offererConduit_cdPtr = 0x1c4;
uint256 constant BasicOrder_fulfillerConduit_cdPtr = 0x1e4;
uint256 constant BasicOrder_totalOriginalAdditionalRecipients_cdPtr = 0x204;
uint256 constant BasicOrder_additionalRecipients_head_cdPtr = 0x224;
uint256 constant BasicOrder_signature_cdPtr = 0x244;
uint256 constant BasicOrder_additionalRecipients_length_cdPtr = 0x264;
uint256 constant BasicOrder_additionalRecipients_data_cdPtr = 0x284;
uint256 constant BasicOrder_parameters_ptr = 0x20;
uint256 constant BasicOrder_basicOrderType_range = 0x18; // 24 values

/*
 *  Memory layout in _prepareBasicFulfillmentFromCalldata of
 *  EIP712 data for ConsiderationItem
 *   - 0x80: ConsiderationItem EIP-712 typehash (constant)
 *   - 0xa0: itemType
 *   - 0xc0: token
 *   - 0xe0: identifier
 *   - 0x100: startAmount
 *   - 0x120: endAmount
 *   - 0x140: recipient
 */
uint256 constant BasicOrder_considerationItem_typeHash_ptr = 0x80; // memoryPtr
uint256 constant BasicOrder_considerationItem_itemType_ptr = 0xa0;
uint256 constant BasicOrder_considerationItem_token_ptr = 0xc0;
uint256 constant BasicOrder_considerationItem_identifier_ptr = 0xe0;
uint256 constant BasicOrder_considerationItem_startAmount_ptr = 0x100;
uint256 constant BasicOrder_considerationItem_endAmount_ptr = 0x120;
// uint256 constant BasicOrder_considerationItem_recipient_ptr = 0x140;

/*
 *  Memory layout in _prepareBasicFulfillmentFromCalldata of
 *  EIP712 data for OfferItem
 *   - 0x80:  OfferItem EIP-712 typehash (constant)
 *   - 0xa0:  itemType
 *   - 0xc0:  token
 *   - 0xe0:  identifier (reused for offeredItemsHash)
 *   - 0x100: startAmount
 *   - 0x120: endAmount
 */
uint256 constant BasicOrder_offerItem_typeHash_ptr = 0x80;
uint256 constant BasicOrder_offerItem_itemType_ptr = 0xa0;
uint256 constant BasicOrder_offerItem_token_ptr = 0xc0;
// uint256 constant BasicOrder_offerItem_identifier_ptr = 0xe0;
// uint256 constant BasicOrder_offerItem_startAmount_ptr = 0x100;
uint256 constant BasicOrder_offerItem_endAmount_ptr = 0x120;

/*
 *  Memory layout in _prepareBasicFulfillmentFromCalldata of
 *  EIP712 data for Order
 *   - 0x80:   Order EIP-712 typehash (constant)
 *   - 0xa0:   orderParameters.offerer
 *   - 0xc0:   orderParameters.zone
 *   - 0xe0:   keccak256(abi.encodePacked(offerHashes))
 *   - 0x100:  keccak256(abi.encodePacked(considerationHashes))
 *   - 0x120:  orderType
 *   - 0x140:  startTime
 *   - 0x160:  endTime
 *   - 0x180:  zoneHash
 *   - 0x1a0:  salt
 *   - 0x1c0:  conduit
 *   - 0x1e0:  _counters[orderParameters.offerer] (from storage)
 */
uint256 constant BasicOrder_order_typeHash_ptr = 0x80;
uint256 constant BasicOrder_order_offerer_ptr = 0xa0;
// uint256 constant BasicOrder_order_zone_ptr = 0xc0;
uint256 constant BasicOrder_order_offerHashes_ptr = 0xe0;
uint256 constant BasicOrder_order_considerationHashes_ptr = 0x100;
uint256 constant BasicOrder_order_orderType_ptr = 0x120;
uint256 constant BasicOrder_order_startTime_ptr = 0x140;
// uint256 constant BasicOrder_order_endTime_ptr = 0x160;
// uint256 constant BasicOrder_order_zoneHash_ptr = 0x180;
// uint256 constant BasicOrder_order_salt_ptr = 0x1a0;
// uint256 constant BasicOrder_order_conduitKey_ptr = 0x1c0;
uint256 constant BasicOrder_order_counter_ptr = 0x1e0;
uint256 constant BasicOrder_additionalRecipients_head_ptr = 0x240;
uint256 constant BasicOrder_signature_ptr = 0x260;
uint256 constant BasicOrder_startTimeThroughZoneHash_size = 0x60;

uint256 constant ContractOrder_orderHash_offerer_shift = 0x60;

uint256 constant Counter_blockhash_shift = 0x80;

// Signature-related
bytes32 constant EIP2098_allButHighestBitMask = (
    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
);
bytes32 constant ECDSA_twentySeventhAndTwentyEighthBytesSet = (
    0x0000000000000000000000000000000000000000000000000000000101000000
);
uint256 constant ECDSA_MaxLength = 65;
uint256 constant ECDSA_signature_s_offset = 0x40;
uint256 constant ECDSA_signature_v_offset = 0x60;

bytes32 constant EIP1271_isValidSignature_selector = (
    0x1626ba7e00000000000000000000000000000000000000000000000000000000
);
uint256 constant EIP1271_isValidSignature_digest_negativeOffset = 0x40;
uint256 constant EIP1271_isValidSignature_selector_negativeOffset = 0x44;
uint256 constant EIP1271_isValidSignature_calldata_baseLength = 0x64;
uint256 constant EIP1271_isValidSignature_signature_head_offset = 0x40;

uint256 constant EIP_712_PREFIX = (
    0x1901000000000000000000000000000000000000000000000000000000000000
);

uint256 constant ExtraGasBuffer = 0x20;
uint256 constant CostPerWord = 0x3;
uint256 constant MemoryExpansionCoefficientShift = 0x9;

uint256 constant Create2AddressDerivation_ptr = 0x0b;
uint256 constant Create2AddressDerivation_length = 0x55;

uint256 constant MaskOverByteTwelve = (
    0x0000000000000000000000ff0000000000000000000000000000000000000000
);
uint256 constant MaskOverLastTwentyBytes = (
    0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
);
uint256 constant AddressDirtyUpperBitThreshold = (
    0x0000000000000000000000010000000000000000000000000000000000000000
);
uint256 constant MaskOverFirstFourBytes = (
    0xffffffff00000000000000000000000000000000000000000000000000000000
);

uint256 constant Conduit_execute_signature = (
    0x4ce34aa200000000000000000000000000000000000000000000000000000000
);

uint256 constant MaxUint8 = 0xff;
uint256 constant MaxUint120 = 0xffffffffffffffffffffffffffffff;

uint256 constant Conduit_execute_ConduitTransfer_ptr = 0x20;
uint256 constant Conduit_execute_ConduitTransfer_length = 0x01;
uint256 constant Conduit_execute_ConduitTransfer_offset_ptr = 0x04;
uint256 constant Conduit_execute_ConduitTransfer_length_ptr = 0x24;
uint256 constant Conduit_execute_transferItemType_ptr = 0x44;
uint256 constant Conduit_execute_transferToken_ptr = 0x64;
uint256 constant Conduit_execute_transferFrom_ptr = 0x84;
uint256 constant Conduit_execute_transferTo_ptr = 0xa4;
uint256 constant Conduit_execute_transferIdentifier_ptr = 0xc4;
uint256 constant Conduit_execute_transferAmount_ptr = 0xe4;

uint256 constant OneConduitExecute_size = 0x104;

// Sentinel value to indicate that the conduit accumulator is not armed.
uint256 constant AccumulatorDisarmed = 0x20;
uint256 constant AccumulatorArmed = 0x40;
uint256 constant Accumulator_conduitKey_ptr = 0x20;
uint256 constant Accumulator_selector_ptr = 0x40;
uint256 constant Accumulator_array_offset_ptr = 0x44;
uint256 constant Accumulator_array_length_ptr = 0x64;
uint256 constant Accumulator_itemSizeOffsetDifference = 0x3c;
uint256 constant Accumulator_array_offset = 0x20;

uint256 constant Conduit_transferItem_size = 0xc0;
uint256 constant Conduit_transferItem_token_ptr = 0x20;
uint256 constant Conduit_transferItem_from_ptr = 0x40;
uint256 constant Conduit_transferItem_to_ptr = 0x60;
uint256 constant Conduit_transferItem_identifier_ptr = 0x80;
uint256 constant Conduit_transferItem_amount_ptr = 0xa0;

uint256 constant Ecrecover_precompile = 0x1;
uint256 constant Ecrecover_args_size = 0x80;
uint256 constant Signature_lower_v = 27;

// Bitmask that only gives a non-zero value if masked with a non-match selector.
uint256 constant NonMatchSelector_MagicMask = (
    0x4000000000000000000000000000000000000000000000000000000000
);

// First bit indicates that a NATIVE offer items has been used and the 231st bit
// indicates that a non match selector has been called.
uint256 constant NonMatchSelector_InvalidErrorValue = (
    0x4000000000000000000000000000000000000000000000000000000001
);

/**
 * @dev Selector and offsets for generateOrder
 *
 * function generateOrder(
 *   address fulfiller,
 *   SpentItem[] calldata minimumReceived,
 *   SpentItem[] calldata maximumSpent,
 *   bytes calldata context
 * )
 */
uint256 constant generateOrder_selector = 0x98919765;
uint256 constant generateOrder_selector_offset = 0x1c;
uint256 constant generateOrder_head_offset = 0x04;
uint256 constant generateOrder_minimumReceived_head_offset = 0x20;
uint256 constant generateOrder_maximumSpent_head_offset = 0x40;
uint256 constant generateOrder_context_head_offset = 0x60;
uint256 constant generateOrder_base_tail_offset = 0x80;
uint256 constant generateOrder_maximum_returndatasize = 0xffff;

uint256 constant ratifyOrder_selector = 0xf4dd92ce;
uint256 constant ratifyOrder_selector_offset = 0x1c;
uint256 constant ratifyOrder_head_offset = 0x04;
// uint256 constant ratifyOrder_offer_head_offset = 0x00;
uint256 constant ratifyOrder_consideration_head_offset = 0x20;
uint256 constant ratifyOrder_context_head_offset = 0x40;
uint256 constant ratifyOrder_orderHashes_head_offset = 0x60;
uint256 constant ratifyOrder_contractNonce_offset = 0x80;
uint256 constant ratifyOrder_base_tail_offset = 0xa0;

uint256 constant validateOrder_selector = 0x17b1f942;
uint256 constant validateOrder_selector_offset = 0x1c;
uint256 constant validateOrder_head_offset = 0x04;
uint256 constant validateOrder_zoneParameters_offset = 0x20;

// uint256 constant ZoneParameters_orderHash_offset = 0x00;
uint256 constant ZoneParameters_fulfiller_offset = 0x20;
uint256 constant ZoneParameters_offerer_offset = 0x40;
uint256 constant ZoneParameters_offer_head_offset = 0x60;
uint256 constant ZoneParameters_consideration_head_offset = 0x80;
uint256 constant ZoneParameters_extraData_head_offset = 0xa0;
uint256 constant ZoneParameters_orderHashes_head_offset = 0xc0;
uint256 constant ZoneParameters_startTime_offset = 0xe0;
uint256 constant ZoneParameters_endTime_offset = 0x100;
uint256 constant ZoneParameters_zoneHash_offset = 0x120;
uint256 constant ZoneParameters_base_tail_offset = 0x140;
uint256 constant ZoneParameters_selectorAndPointer_length = 0x24;
uint256 constant ZoneParameters_basicOrderFixedElements_length = 0x64;

// ConsiderationDecoder Constants
uint256 constant OrderParameters_head_size = 0x0160;
uint256 constant OrderParameters_totalOriginalConsiderationItems_offset = (
    0x0140
);
uint256 constant AdvancedOrderPlusOrderParameters_head_size = 0x0200;

uint256 constant Order_signature_offset = 0x20;
uint256 constant Order_head_size = 0x40;

uint256 constant AdvancedOrder_fixed_segment_0 = 0x40;

uint256 constant CriteriaResolver_head_size = 0xa0;
uint256 constant CriteriaResolver_fixed_segment_0 = 0x80;
uint256 constant CriteriaResolver_criteriaProof_offset = 0x80;

uint256 constant FulfillmentComponent_mem_tail_size = 0x40;
uint256 constant FulfillmentComponent_mem_tail_size_shift = 0x6;
uint256 constant Fulfillment_head_size = 0x40;
uint256 constant Fulfillment_considerationComponents_offset = 0x20;

uint256 constant OrderComponents_OrderParameters_common_head_size = 0x0140;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

type CalldataPointer is uint256;

type ReturndataPointer is uint256;

type MemoryPointer is uint256;

using CalldataPointerLib for CalldataPointer global;
using MemoryPointerLib for MemoryPointer global;
using ReturndataPointerLib for ReturndataPointer global;

using CalldataReaders for CalldataPointer global;
using ReturndataReaders for ReturndataPointer global;
using MemoryReaders for MemoryPointer global;
using MemoryWriters for MemoryPointer global;

CalldataPointer constant CalldataStart = CalldataPointer.wrap(0x04);
MemoryPointer constant FreeMemoryPPtr = MemoryPointer.wrap(0x40);
uint256 constant IdentityPrecompileAddress = 0x4;
uint256 constant OffsetOrLengthMask = 0xffffffff;
uint256 constant _OneWord = 0x20;
uint256 constant _FreeMemoryPointerSlot = 0x40;

/// @dev Allocates `size` bytes in memory by increasing the free memory pointer
///    and returns the memory pointer to the first byte of the allocated region.
// (Free functions cannot have visibility.)
// solhint-disable-next-line func-visibility
function malloc(uint256 size) pure returns (MemoryPointer mPtr) {
    assembly {
        mPtr := mload(_FreeMemoryPointerSlot)
        mstore(_FreeMemoryPointerSlot, add(mPtr, size))
    }
}

// (Free functions cannot have visibility.)
// solhint-disable-next-line func-visibility
function getFreeMemoryPointer() pure returns (MemoryPointer mPtr) {
    mPtr = FreeMemoryPPtr.readMemoryPointer();
}

// (Free functions cannot have visibility.)
// solhint-disable-next-line func-visibility
function setFreeMemoryPointer(MemoryPointer mPtr) pure {
    FreeMemoryPPtr.write(mPtr);
}

library CalldataPointerLib {
    function lt(
        CalldataPointer a,
        CalldataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := lt(a, b)
        }
    }

    function gt(
        CalldataPointer a,
        CalldataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := gt(a, b)
        }
    }

    function eq(
        CalldataPointer a,
        CalldataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := eq(a, b)
        }
    }

    function isNull(CalldataPointer a) internal pure returns (bool b) {
        assembly {
            b := iszero(a)
        }
    }

    /// @dev Resolves an offset stored at `cdPtr + headOffset` to a calldata.
    ///      pointer `cdPtr` must point to some parent object with a dynamic
    ///      type's head stored at `cdPtr + headOffset`.
    function pptr(
        CalldataPointer cdPtr,
        uint256 headOffset
    ) internal pure returns (CalldataPointer cdPtrChild) {
        cdPtrChild = cdPtr.offset(
            cdPtr.offset(headOffset).readUint256() & OffsetOrLengthMask
        );
    }

    /// @dev Resolves an offset stored at `cdPtr` to a calldata pointer.
    ///      `cdPtr` must point to some parent object with a dynamic type as its
    ///      first member, e.g. `struct { bytes data; }`
    function pptr(
        CalldataPointer cdPtr
    ) internal pure returns (CalldataPointer cdPtrChild) {
        cdPtrChild = cdPtr.offset(cdPtr.readUint256() & OffsetOrLengthMask);
    }

    /// @dev Returns the calldata pointer one word after `cdPtr`.
    function next(
        CalldataPointer cdPtr
    ) internal pure returns (CalldataPointer cdPtrNext) {
        assembly {
            cdPtrNext := add(cdPtr, _OneWord)
        }
    }

    /// @dev Returns the calldata pointer `_offset` bytes after `cdPtr`.
    function offset(
        CalldataPointer cdPtr,
        uint256 _offset
    ) internal pure returns (CalldataPointer cdPtrNext) {
        assembly {
            cdPtrNext := add(cdPtr, _offset)
        }
    }

    /// @dev Copies `size` bytes from calldata starting at `src` to memory at
    ///      `dst`.
    function copy(
        CalldataPointer src,
        MemoryPointer dst,
        uint256 size
    ) internal pure {
        assembly {
            calldatacopy(dst, src, size)
        }
    }
}

library ReturndataPointerLib {
    function lt(
        ReturndataPointer a,
        ReturndataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := lt(a, b)
        }
    }

    function gt(
        ReturndataPointer a,
        ReturndataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := gt(a, b)
        }
    }

    function eq(
        ReturndataPointer a,
        ReturndataPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := eq(a, b)
        }
    }

    function isNull(ReturndataPointer a) internal pure returns (bool b) {
        assembly {
            b := iszero(a)
        }
    }

    /// @dev Resolves an offset stored at `rdPtr + headOffset` to a returndata
    ///      pointer. `rdPtr` must point to some parent object with a dynamic
    ///      type's head stored at `rdPtr + headOffset`.
    function pptr(
        ReturndataPointer rdPtr,
        uint256 headOffset
    ) internal pure returns (ReturndataPointer rdPtrChild) {
        rdPtrChild = rdPtr.offset(
            rdPtr.offset(headOffset).readUint256() & OffsetOrLengthMask
        );
    }

    /// @dev Resolves an offset stored at `rdPtr` to a returndata pointer.
    ///    `rdPtr` must point to some parent object with a dynamic type as its
    ///    first member, e.g. `struct { bytes data; }`
    function pptr(
        ReturndataPointer rdPtr
    ) internal pure returns (ReturndataPointer rdPtrChild) {
        rdPtrChild = rdPtr.offset(rdPtr.readUint256() & OffsetOrLengthMask);
    }

    /// @dev Returns the returndata pointer one word after `cdPtr`.
    function next(
        ReturndataPointer rdPtr
    ) internal pure returns (ReturndataPointer rdPtrNext) {
        assembly {
            rdPtrNext := add(rdPtr, _OneWord)
        }
    }

    /// @dev Returns the returndata pointer `_offset` bytes after `cdPtr`.
    function offset(
        ReturndataPointer rdPtr,
        uint256 _offset
    ) internal pure returns (ReturndataPointer rdPtrNext) {
        assembly {
            rdPtrNext := add(rdPtr, _offset)
        }
    }

    /// @dev Copies `size` bytes from returndata starting at `src` to memory at
    /// `dst`.
    function copy(
        ReturndataPointer src,
        MemoryPointer dst,
        uint256 size
    ) internal pure {
        assembly {
            returndatacopy(dst, src, size)
        }
    }
}

library MemoryPointerLib {
    function copy(
        MemoryPointer src,
        MemoryPointer dst,
        uint256 size
    ) internal view {
        assembly {
            let success := staticcall(
                gas(),
                IdentityPrecompileAddress,
                src,
                size,
                dst,
                size
            )
            if or(iszero(returndatasize()), iszero(success)) {
                revert(0, 0)
            }
        }
    }

    function lt(
        MemoryPointer a,
        MemoryPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := lt(a, b)
        }
    }

    function gt(
        MemoryPointer a,
        MemoryPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := gt(a, b)
        }
    }

    function eq(
        MemoryPointer a,
        MemoryPointer b
    ) internal pure returns (bool c) {
        assembly {
            c := eq(a, b)
        }
    }

    function isNull(MemoryPointer a) internal pure returns (bool b) {
        assembly {
            b := iszero(a)
        }
    }

    function hash(
        MemoryPointer ptr,
        uint256 length
    ) internal pure returns (bytes32 _hash) {
        assembly {
            _hash := keccak256(ptr, length)
        }
    }

    /// @dev Returns the memory pointer one word after `mPtr`.
    function next(
        MemoryPointer mPtr
    ) internal pure returns (MemoryPointer mPtrNext) {
        assembly {
            mPtrNext := add(mPtr, _OneWord)
        }
    }

    /// @dev Returns the memory pointer `_offset` bytes after `mPtr`.
    function offset(
        MemoryPointer mPtr,
        uint256 _offset
    ) internal pure returns (MemoryPointer mPtrNext) {
        assembly {
            mPtrNext := add(mPtr, _offset)
        }
    }

    /// @dev Resolves a pointer at `mPtr + headOffset` to a memory
    ///    pointer. `mPtr` must point to some parent object with a dynamic
    ///    type's pointer stored at `mPtr + headOffset`.
    function pptr(
        MemoryPointer mPtr,
        uint256 headOffset
    ) internal pure returns (MemoryPointer mPtrChild) {
        mPtrChild = mPtr.offset(headOffset).readMemoryPointer();
    }

    /// @dev Resolves a pointer stored at `mPtr` to a memory pointer.
    ///    `mPtr` must point to some parent object with a dynamic type as its
    ///    first member, e.g. `struct { bytes data; }`
    function pptr(
        MemoryPointer mPtr
    ) internal pure returns (MemoryPointer mPtrChild) {
        mPtrChild = mPtr.readMemoryPointer();
    }
}

library CalldataReaders {
    /// @dev Reads the value at `cdPtr` and applies a mask to return only the
    ///    last 4 bytes.
    function readMaskedUint256(
        CalldataPointer cdPtr
    ) internal pure returns (uint256 value) {
        value = cdPtr.readUint256() & OffsetOrLengthMask;
    }

    /// @dev Reads the bool at `cdPtr` in calldata.
    function readBool(
        CalldataPointer cdPtr
    ) internal pure returns (bool value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the address at `cdPtr` in calldata.
    function readAddress(
        CalldataPointer cdPtr
    ) internal pure returns (address value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes1 at `cdPtr` in calldata.
    function readBytes1(
        CalldataPointer cdPtr
    ) internal pure returns (bytes1 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes2 at `cdPtr` in calldata.
    function readBytes2(
        CalldataPointer cdPtr
    ) internal pure returns (bytes2 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes3 at `cdPtr` in calldata.
    function readBytes3(
        CalldataPointer cdPtr
    ) internal pure returns (bytes3 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes4 at `cdPtr` in calldata.
    function readBytes4(
        CalldataPointer cdPtr
    ) internal pure returns (bytes4 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes5 at `cdPtr` in calldata.
    function readBytes5(
        CalldataPointer cdPtr
    ) internal pure returns (bytes5 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes6 at `cdPtr` in calldata.
    function readBytes6(
        CalldataPointer cdPtr
    ) internal pure returns (bytes6 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes7 at `cdPtr` in calldata.
    function readBytes7(
        CalldataPointer cdPtr
    ) internal pure returns (bytes7 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes8 at `cdPtr` in calldata.
    function readBytes8(
        CalldataPointer cdPtr
    ) internal pure returns (bytes8 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes9 at `cdPtr` in calldata.
    function readBytes9(
        CalldataPointer cdPtr
    ) internal pure returns (bytes9 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes10 at `cdPtr` in calldata.
    function readBytes10(
        CalldataPointer cdPtr
    ) internal pure returns (bytes10 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes11 at `cdPtr` in calldata.
    function readBytes11(
        CalldataPointer cdPtr
    ) internal pure returns (bytes11 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes12 at `cdPtr` in calldata.
    function readBytes12(
        CalldataPointer cdPtr
    ) internal pure returns (bytes12 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes13 at `cdPtr` in calldata.
    function readBytes13(
        CalldataPointer cdPtr
    ) internal pure returns (bytes13 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes14 at `cdPtr` in calldata.
    function readBytes14(
        CalldataPointer cdPtr
    ) internal pure returns (bytes14 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes15 at `cdPtr` in calldata.
    function readBytes15(
        CalldataPointer cdPtr
    ) internal pure returns (bytes15 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes16 at `cdPtr` in calldata.
    function readBytes16(
        CalldataPointer cdPtr
    ) internal pure returns (bytes16 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes17 at `cdPtr` in calldata.
    function readBytes17(
        CalldataPointer cdPtr
    ) internal pure returns (bytes17 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes18 at `cdPtr` in calldata.
    function readBytes18(
        CalldataPointer cdPtr
    ) internal pure returns (bytes18 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes19 at `cdPtr` in calldata.
    function readBytes19(
        CalldataPointer cdPtr
    ) internal pure returns (bytes19 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes20 at `cdPtr` in calldata.
    function readBytes20(
        CalldataPointer cdPtr
    ) internal pure returns (bytes20 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes21 at `cdPtr` in calldata.
    function readBytes21(
        CalldataPointer cdPtr
    ) internal pure returns (bytes21 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes22 at `cdPtr` in calldata.
    function readBytes22(
        CalldataPointer cdPtr
    ) internal pure returns (bytes22 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes23 at `cdPtr` in calldata.
    function readBytes23(
        CalldataPointer cdPtr
    ) internal pure returns (bytes23 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes24 at `cdPtr` in calldata.
    function readBytes24(
        CalldataPointer cdPtr
    ) internal pure returns (bytes24 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes25 at `cdPtr` in calldata.
    function readBytes25(
        CalldataPointer cdPtr
    ) internal pure returns (bytes25 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes26 at `cdPtr` in calldata.
    function readBytes26(
        CalldataPointer cdPtr
    ) internal pure returns (bytes26 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes27 at `cdPtr` in calldata.
    function readBytes27(
        CalldataPointer cdPtr
    ) internal pure returns (bytes27 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes28 at `cdPtr` in calldata.
    function readBytes28(
        CalldataPointer cdPtr
    ) internal pure returns (bytes28 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes29 at `cdPtr` in calldata.
    function readBytes29(
        CalldataPointer cdPtr
    ) internal pure returns (bytes29 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes30 at `cdPtr` in calldata.
    function readBytes30(
        CalldataPointer cdPtr
    ) internal pure returns (bytes30 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes31 at `cdPtr` in calldata.
    function readBytes31(
        CalldataPointer cdPtr
    ) internal pure returns (bytes31 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the bytes32 at `cdPtr` in calldata.
    function readBytes32(
        CalldataPointer cdPtr
    ) internal pure returns (bytes32 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint8 at `cdPtr` in calldata.
    function readUint8(
        CalldataPointer cdPtr
    ) internal pure returns (uint8 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint16 at `cdPtr` in calldata.
    function readUint16(
        CalldataPointer cdPtr
    ) internal pure returns (uint16 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint24 at `cdPtr` in calldata.
    function readUint24(
        CalldataPointer cdPtr
    ) internal pure returns (uint24 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint32 at `cdPtr` in calldata.
    function readUint32(
        CalldataPointer cdPtr
    ) internal pure returns (uint32 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint40 at `cdPtr` in calldata.
    function readUint40(
        CalldataPointer cdPtr
    ) internal pure returns (uint40 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint48 at `cdPtr` in calldata.
    function readUint48(
        CalldataPointer cdPtr
    ) internal pure returns (uint48 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint56 at `cdPtr` in calldata.
    function readUint56(
        CalldataPointer cdPtr
    ) internal pure returns (uint56 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint64 at `cdPtr` in calldata.
    function readUint64(
        CalldataPointer cdPtr
    ) internal pure returns (uint64 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint72 at `cdPtr` in calldata.
    function readUint72(
        CalldataPointer cdPtr
    ) internal pure returns (uint72 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint80 at `cdPtr` in calldata.
    function readUint80(
        CalldataPointer cdPtr
    ) internal pure returns (uint80 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint88 at `cdPtr` in calldata.
    function readUint88(
        CalldataPointer cdPtr
    ) internal pure returns (uint88 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint96 at `cdPtr` in calldata.
    function readUint96(
        CalldataPointer cdPtr
    ) internal pure returns (uint96 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint104 at `cdPtr` in calldata.
    function readUint104(
        CalldataPointer cdPtr
    ) internal pure returns (uint104 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint112 at `cdPtr` in calldata.
    function readUint112(
        CalldataPointer cdPtr
    ) internal pure returns (uint112 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint120 at `cdPtr` in calldata.
    function readUint120(
        CalldataPointer cdPtr
    ) internal pure returns (uint120 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint128 at `cdPtr` in calldata.
    function readUint128(
        CalldataPointer cdPtr
    ) internal pure returns (uint128 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint136 at `cdPtr` in calldata.
    function readUint136(
        CalldataPointer cdPtr
    ) internal pure returns (uint136 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint144 at `cdPtr` in calldata.
    function readUint144(
        CalldataPointer cdPtr
    ) internal pure returns (uint144 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint152 at `cdPtr` in calldata.
    function readUint152(
        CalldataPointer cdPtr
    ) internal pure returns (uint152 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint160 at `cdPtr` in calldata.
    function readUint160(
        CalldataPointer cdPtr
    ) internal pure returns (uint160 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint168 at `cdPtr` in calldata.
    function readUint168(
        CalldataPointer cdPtr
    ) internal pure returns (uint168 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint176 at `cdPtr` in calldata.
    function readUint176(
        CalldataPointer cdPtr
    ) internal pure returns (uint176 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint184 at `cdPtr` in calldata.
    function readUint184(
        CalldataPointer cdPtr
    ) internal pure returns (uint184 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint192 at `cdPtr` in calldata.
    function readUint192(
        CalldataPointer cdPtr
    ) internal pure returns (uint192 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint200 at `cdPtr` in calldata.
    function readUint200(
        CalldataPointer cdPtr
    ) internal pure returns (uint200 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint208 at `cdPtr` in calldata.
    function readUint208(
        CalldataPointer cdPtr
    ) internal pure returns (uint208 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint216 at `cdPtr` in calldata.
    function readUint216(
        CalldataPointer cdPtr
    ) internal pure returns (uint216 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint224 at `cdPtr` in calldata.
    function readUint224(
        CalldataPointer cdPtr
    ) internal pure returns (uint224 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint232 at `cdPtr` in calldata.
    function readUint232(
        CalldataPointer cdPtr
    ) internal pure returns (uint232 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint240 at `cdPtr` in calldata.
    function readUint240(
        CalldataPointer cdPtr
    ) internal pure returns (uint240 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint248 at `cdPtr` in calldata.
    function readUint248(
        CalldataPointer cdPtr
    ) internal pure returns (uint248 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the uint256 at `cdPtr` in calldata.
    function readUint256(
        CalldataPointer cdPtr
    ) internal pure returns (uint256 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int8 at `cdPtr` in calldata.
    function readInt8(
        CalldataPointer cdPtr
    ) internal pure returns (int8 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int16 at `cdPtr` in calldata.
    function readInt16(
        CalldataPointer cdPtr
    ) internal pure returns (int16 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int24 at `cdPtr` in calldata.
    function readInt24(
        CalldataPointer cdPtr
    ) internal pure returns (int24 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int32 at `cdPtr` in calldata.
    function readInt32(
        CalldataPointer cdPtr
    ) internal pure returns (int32 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int40 at `cdPtr` in calldata.
    function readInt40(
        CalldataPointer cdPtr
    ) internal pure returns (int40 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int48 at `cdPtr` in calldata.
    function readInt48(
        CalldataPointer cdPtr
    ) internal pure returns (int48 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int56 at `cdPtr` in calldata.
    function readInt56(
        CalldataPointer cdPtr
    ) internal pure returns (int56 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int64 at `cdPtr` in calldata.
    function readInt64(
        CalldataPointer cdPtr
    ) internal pure returns (int64 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int72 at `cdPtr` in calldata.
    function readInt72(
        CalldataPointer cdPtr
    ) internal pure returns (int72 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int80 at `cdPtr` in calldata.
    function readInt80(
        CalldataPointer cdPtr
    ) internal pure returns (int80 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int88 at `cdPtr` in calldata.
    function readInt88(
        CalldataPointer cdPtr
    ) internal pure returns (int88 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int96 at `cdPtr` in calldata.
    function readInt96(
        CalldataPointer cdPtr
    ) internal pure returns (int96 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int104 at `cdPtr` in calldata.
    function readInt104(
        CalldataPointer cdPtr
    ) internal pure returns (int104 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int112 at `cdPtr` in calldata.
    function readInt112(
        CalldataPointer cdPtr
    ) internal pure returns (int112 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int120 at `cdPtr` in calldata.
    function readInt120(
        CalldataPointer cdPtr
    ) internal pure returns (int120 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int128 at `cdPtr` in calldata.
    function readInt128(
        CalldataPointer cdPtr
    ) internal pure returns (int128 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int136 at `cdPtr` in calldata.
    function readInt136(
        CalldataPointer cdPtr
    ) internal pure returns (int136 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int144 at `cdPtr` in calldata.
    function readInt144(
        CalldataPointer cdPtr
    ) internal pure returns (int144 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int152 at `cdPtr` in calldata.
    function readInt152(
        CalldataPointer cdPtr
    ) internal pure returns (int152 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int160 at `cdPtr` in calldata.
    function readInt160(
        CalldataPointer cdPtr
    ) internal pure returns (int160 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int168 at `cdPtr` in calldata.
    function readInt168(
        CalldataPointer cdPtr
    ) internal pure returns (int168 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int176 at `cdPtr` in calldata.
    function readInt176(
        CalldataPointer cdPtr
    ) internal pure returns (int176 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int184 at `cdPtr` in calldata.
    function readInt184(
        CalldataPointer cdPtr
    ) internal pure returns (int184 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int192 at `cdPtr` in calldata.
    function readInt192(
        CalldataPointer cdPtr
    ) internal pure returns (int192 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int200 at `cdPtr` in calldata.
    function readInt200(
        CalldataPointer cdPtr
    ) internal pure returns (int200 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int208 at `cdPtr` in calldata.
    function readInt208(
        CalldataPointer cdPtr
    ) internal pure returns (int208 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int216 at `cdPtr` in calldata.
    function readInt216(
        CalldataPointer cdPtr
    ) internal pure returns (int216 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int224 at `cdPtr` in calldata.
    function readInt224(
        CalldataPointer cdPtr
    ) internal pure returns (int224 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int232 at `cdPtr` in calldata.
    function readInt232(
        CalldataPointer cdPtr
    ) internal pure returns (int232 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int240 at `cdPtr` in calldata.
    function readInt240(
        CalldataPointer cdPtr
    ) internal pure returns (int240 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int248 at `cdPtr` in calldata.
    function readInt248(
        CalldataPointer cdPtr
    ) internal pure returns (int248 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }

    /// @dev Reads the int256 at `cdPtr` in calldata.
    function readInt256(
        CalldataPointer cdPtr
    ) internal pure returns (int256 value) {
        assembly {
            value := calldataload(cdPtr)
        }
    }
}

library ReturndataReaders {
    /// @dev Reads value at `rdPtr` & applies a mask to return only last 4 bytes
    function readMaskedUint256(
        ReturndataPointer rdPtr
    ) internal pure returns (uint256 value) {
        value = rdPtr.readUint256() & OffsetOrLengthMask;
    }

    /// @dev Reads the bool at `rdPtr` in returndata.
    function readBool(
        ReturndataPointer rdPtr
    ) internal pure returns (bool value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the address at `rdPtr` in returndata.
    function readAddress(
        ReturndataPointer rdPtr
    ) internal pure returns (address value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes1 at `rdPtr` in returndata.
    function readBytes1(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes1 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes2 at `rdPtr` in returndata.
    function readBytes2(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes2 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes3 at `rdPtr` in returndata.
    function readBytes3(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes3 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes4 at `rdPtr` in returndata.
    function readBytes4(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes4 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes5 at `rdPtr` in returndata.
    function readBytes5(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes5 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes6 at `rdPtr` in returndata.
    function readBytes6(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes6 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes7 at `rdPtr` in returndata.
    function readBytes7(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes7 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes8 at `rdPtr` in returndata.
    function readBytes8(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes8 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes9 at `rdPtr` in returndata.
    function readBytes9(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes9 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes10 at `rdPtr` in returndata.
    function readBytes10(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes10 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes11 at `rdPtr` in returndata.
    function readBytes11(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes11 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes12 at `rdPtr` in returndata.
    function readBytes12(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes12 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes13 at `rdPtr` in returndata.
    function readBytes13(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes13 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes14 at `rdPtr` in returndata.
    function readBytes14(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes14 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes15 at `rdPtr` in returndata.
    function readBytes15(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes15 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes16 at `rdPtr` in returndata.
    function readBytes16(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes16 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes17 at `rdPtr` in returndata.
    function readBytes17(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes17 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes18 at `rdPtr` in returndata.
    function readBytes18(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes18 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes19 at `rdPtr` in returndata.
    function readBytes19(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes19 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes20 at `rdPtr` in returndata.
    function readBytes20(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes20 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes21 at `rdPtr` in returndata.
    function readBytes21(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes21 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes22 at `rdPtr` in returndata.
    function readBytes22(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes22 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes23 at `rdPtr` in returndata.
    function readBytes23(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes23 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes24 at `rdPtr` in returndata.
    function readBytes24(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes24 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes25 at `rdPtr` in returndata.
    function readBytes25(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes25 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes26 at `rdPtr` in returndata.
    function readBytes26(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes26 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes27 at `rdPtr` in returndata.
    function readBytes27(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes27 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes28 at `rdPtr` in returndata.
    function readBytes28(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes28 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes29 at `rdPtr` in returndata.
    function readBytes29(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes29 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes30 at `rdPtr` in returndata.
    function readBytes30(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes30 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes31 at `rdPtr` in returndata.
    function readBytes31(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes31 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the bytes32 at `rdPtr` in returndata.
    function readBytes32(
        ReturndataPointer rdPtr
    ) internal pure returns (bytes32 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint8 at `rdPtr` in returndata.
    function readUint8(
        ReturndataPointer rdPtr
    ) internal pure returns (uint8 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint16 at `rdPtr` in returndata.
    function readUint16(
        ReturndataPointer rdPtr
    ) internal pure returns (uint16 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint24 at `rdPtr` in returndata.
    function readUint24(
        ReturndataPointer rdPtr
    ) internal pure returns (uint24 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint32 at `rdPtr` in returndata.
    function readUint32(
        ReturndataPointer rdPtr
    ) internal pure returns (uint32 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint40 at `rdPtr` in returndata.
    function readUint40(
        ReturndataPointer rdPtr
    ) internal pure returns (uint40 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint48 at `rdPtr` in returndata.
    function readUint48(
        ReturndataPointer rdPtr
    ) internal pure returns (uint48 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint56 at `rdPtr` in returndata.
    function readUint56(
        ReturndataPointer rdPtr
    ) internal pure returns (uint56 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint64 at `rdPtr` in returndata.
    function readUint64(
        ReturndataPointer rdPtr
    ) internal pure returns (uint64 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint72 at `rdPtr` in returndata.
    function readUint72(
        ReturndataPointer rdPtr
    ) internal pure returns (uint72 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint80 at `rdPtr` in returndata.
    function readUint80(
        ReturndataPointer rdPtr
    ) internal pure returns (uint80 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint88 at `rdPtr` in returndata.
    function readUint88(
        ReturndataPointer rdPtr
    ) internal pure returns (uint88 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint96 at `rdPtr` in returndata.
    function readUint96(
        ReturndataPointer rdPtr
    ) internal pure returns (uint96 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint104 at `rdPtr` in returndata.
    function readUint104(
        ReturndataPointer rdPtr
    ) internal pure returns (uint104 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint112 at `rdPtr` in returndata.
    function readUint112(
        ReturndataPointer rdPtr
    ) internal pure returns (uint112 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint120 at `rdPtr` in returndata.
    function readUint120(
        ReturndataPointer rdPtr
    ) internal pure returns (uint120 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint128 at `rdPtr` in returndata.
    function readUint128(
        ReturndataPointer rdPtr
    ) internal pure returns (uint128 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint136 at `rdPtr` in returndata.
    function readUint136(
        ReturndataPointer rdPtr
    ) internal pure returns (uint136 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint144 at `rdPtr` in returndata.
    function readUint144(
        ReturndataPointer rdPtr
    ) internal pure returns (uint144 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint152 at `rdPtr` in returndata.
    function readUint152(
        ReturndataPointer rdPtr
    ) internal pure returns (uint152 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint160 at `rdPtr` in returndata.
    function readUint160(
        ReturndataPointer rdPtr
    ) internal pure returns (uint160 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint168 at `rdPtr` in returndata.
    function readUint168(
        ReturndataPointer rdPtr
    ) internal pure returns (uint168 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint176 at `rdPtr` in returndata.
    function readUint176(
        ReturndataPointer rdPtr
    ) internal pure returns (uint176 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint184 at `rdPtr` in returndata.
    function readUint184(
        ReturndataPointer rdPtr
    ) internal pure returns (uint184 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint192 at `rdPtr` in returndata.
    function readUint192(
        ReturndataPointer rdPtr
    ) internal pure returns (uint192 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint200 at `rdPtr` in returndata.
    function readUint200(
        ReturndataPointer rdPtr
    ) internal pure returns (uint200 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint208 at `rdPtr` in returndata.
    function readUint208(
        ReturndataPointer rdPtr
    ) internal pure returns (uint208 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint216 at `rdPtr` in returndata.
    function readUint216(
        ReturndataPointer rdPtr
    ) internal pure returns (uint216 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint224 at `rdPtr` in returndata.
    function readUint224(
        ReturndataPointer rdPtr
    ) internal pure returns (uint224 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint232 at `rdPtr` in returndata.
    function readUint232(
        ReturndataPointer rdPtr
    ) internal pure returns (uint232 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint240 at `rdPtr` in returndata.
    function readUint240(
        ReturndataPointer rdPtr
    ) internal pure returns (uint240 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint248 at `rdPtr` in returndata.
    function readUint248(
        ReturndataPointer rdPtr
    ) internal pure returns (uint248 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the uint256 at `rdPtr` in returndata.
    function readUint256(
        ReturndataPointer rdPtr
    ) internal pure returns (uint256 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int8 at `rdPtr` in returndata.
    function readInt8(
        ReturndataPointer rdPtr
    ) internal pure returns (int8 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int16 at `rdPtr` in returndata.
    function readInt16(
        ReturndataPointer rdPtr
    ) internal pure returns (int16 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int24 at `rdPtr` in returndata.
    function readInt24(
        ReturndataPointer rdPtr
    ) internal pure returns (int24 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int32 at `rdPtr` in returndata.
    function readInt32(
        ReturndataPointer rdPtr
    ) internal pure returns (int32 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int40 at `rdPtr` in returndata.
    function readInt40(
        ReturndataPointer rdPtr
    ) internal pure returns (int40 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int48 at `rdPtr` in returndata.
    function readInt48(
        ReturndataPointer rdPtr
    ) internal pure returns (int48 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int56 at `rdPtr` in returndata.
    function readInt56(
        ReturndataPointer rdPtr
    ) internal pure returns (int56 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int64 at `rdPtr` in returndata.
    function readInt64(
        ReturndataPointer rdPtr
    ) internal pure returns (int64 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int72 at `rdPtr` in returndata.
    function readInt72(
        ReturndataPointer rdPtr
    ) internal pure returns (int72 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int80 at `rdPtr` in returndata.
    function readInt80(
        ReturndataPointer rdPtr
    ) internal pure returns (int80 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int88 at `rdPtr` in returndata.
    function readInt88(
        ReturndataPointer rdPtr
    ) internal pure returns (int88 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int96 at `rdPtr` in returndata.
    function readInt96(
        ReturndataPointer rdPtr
    ) internal pure returns (int96 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int104 at `rdPtr` in returndata.
    function readInt104(
        ReturndataPointer rdPtr
    ) internal pure returns (int104 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int112 at `rdPtr` in returndata.
    function readInt112(
        ReturndataPointer rdPtr
    ) internal pure returns (int112 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int120 at `rdPtr` in returndata.
    function readInt120(
        ReturndataPointer rdPtr
    ) internal pure returns (int120 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int128 at `rdPtr` in returndata.
    function readInt128(
        ReturndataPointer rdPtr
    ) internal pure returns (int128 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int136 at `rdPtr` in returndata.
    function readInt136(
        ReturndataPointer rdPtr
    ) internal pure returns (int136 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int144 at `rdPtr` in returndata.
    function readInt144(
        ReturndataPointer rdPtr
    ) internal pure returns (int144 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int152 at `rdPtr` in returndata.
    function readInt152(
        ReturndataPointer rdPtr
    ) internal pure returns (int152 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int160 at `rdPtr` in returndata.
    function readInt160(
        ReturndataPointer rdPtr
    ) internal pure returns (int160 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int168 at `rdPtr` in returndata.
    function readInt168(
        ReturndataPointer rdPtr
    ) internal pure returns (int168 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int176 at `rdPtr` in returndata.
    function readInt176(
        ReturndataPointer rdPtr
    ) internal pure returns (int176 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int184 at `rdPtr` in returndata.
    function readInt184(
        ReturndataPointer rdPtr
    ) internal pure returns (int184 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int192 at `rdPtr` in returndata.
    function readInt192(
        ReturndataPointer rdPtr
    ) internal pure returns (int192 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int200 at `rdPtr` in returndata.
    function readInt200(
        ReturndataPointer rdPtr
    ) internal pure returns (int200 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int208 at `rdPtr` in returndata.
    function readInt208(
        ReturndataPointer rdPtr
    ) internal pure returns (int208 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int216 at `rdPtr` in returndata.
    function readInt216(
        ReturndataPointer rdPtr
    ) internal pure returns (int216 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int224 at `rdPtr` in returndata.
    function readInt224(
        ReturndataPointer rdPtr
    ) internal pure returns (int224 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int232 at `rdPtr` in returndata.
    function readInt232(
        ReturndataPointer rdPtr
    ) internal pure returns (int232 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int240 at `rdPtr` in returndata.
    function readInt240(
        ReturndataPointer rdPtr
    ) internal pure returns (int240 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int248 at `rdPtr` in returndata.
    function readInt248(
        ReturndataPointer rdPtr
    ) internal pure returns (int248 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }

    /// @dev Reads the int256 at `rdPtr` in returndata.
    function readInt256(
        ReturndataPointer rdPtr
    ) internal pure returns (int256 value) {
        assembly {
            returndatacopy(0, rdPtr, _OneWord)
            value := mload(0)
        }
    }
}

library MemoryReaders {
    /// @dev Reads the memory pointer at `mPtr` in memory.
    function readMemoryPointer(
        MemoryPointer mPtr
    ) internal pure returns (MemoryPointer value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads value at `mPtr` & applies a mask to return only last 4 bytes
    function readMaskedUint256(
        MemoryPointer mPtr
    ) internal pure returns (uint256 value) {
        value = mPtr.readUint256() & OffsetOrLengthMask;
    }

    /// @dev Reads the bool at `mPtr` in memory.
    function readBool(MemoryPointer mPtr) internal pure returns (bool value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the address at `mPtr` in memory.
    function readAddress(
        MemoryPointer mPtr
    ) internal pure returns (address value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes1 at `mPtr` in memory.
    function readBytes1(
        MemoryPointer mPtr
    ) internal pure returns (bytes1 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes2 at `mPtr` in memory.
    function readBytes2(
        MemoryPointer mPtr
    ) internal pure returns (bytes2 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes3 at `mPtr` in memory.
    function readBytes3(
        MemoryPointer mPtr
    ) internal pure returns (bytes3 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes4 at `mPtr` in memory.
    function readBytes4(
        MemoryPointer mPtr
    ) internal pure returns (bytes4 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes5 at `mPtr` in memory.
    function readBytes5(
        MemoryPointer mPtr
    ) internal pure returns (bytes5 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes6 at `mPtr` in memory.
    function readBytes6(
        MemoryPointer mPtr
    ) internal pure returns (bytes6 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes7 at `mPtr` in memory.
    function readBytes7(
        MemoryPointer mPtr
    ) internal pure returns (bytes7 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes8 at `mPtr` in memory.
    function readBytes8(
        MemoryPointer mPtr
    ) internal pure returns (bytes8 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes9 at `mPtr` in memory.
    function readBytes9(
        MemoryPointer mPtr
    ) internal pure returns (bytes9 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes10 at `mPtr` in memory.
    function readBytes10(
        MemoryPointer mPtr
    ) internal pure returns (bytes10 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes11 at `mPtr` in memory.
    function readBytes11(
        MemoryPointer mPtr
    ) internal pure returns (bytes11 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes12 at `mPtr` in memory.
    function readBytes12(
        MemoryPointer mPtr
    ) internal pure returns (bytes12 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes13 at `mPtr` in memory.
    function readBytes13(
        MemoryPointer mPtr
    ) internal pure returns (bytes13 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes14 at `mPtr` in memory.
    function readBytes14(
        MemoryPointer mPtr
    ) internal pure returns (bytes14 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes15 at `mPtr` in memory.
    function readBytes15(
        MemoryPointer mPtr
    ) internal pure returns (bytes15 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes16 at `mPtr` in memory.
    function readBytes16(
        MemoryPointer mPtr
    ) internal pure returns (bytes16 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes17 at `mPtr` in memory.
    function readBytes17(
        MemoryPointer mPtr
    ) internal pure returns (bytes17 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes18 at `mPtr` in memory.
    function readBytes18(
        MemoryPointer mPtr
    ) internal pure returns (bytes18 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes19 at `mPtr` in memory.
    function readBytes19(
        MemoryPointer mPtr
    ) internal pure returns (bytes19 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes20 at `mPtr` in memory.
    function readBytes20(
        MemoryPointer mPtr
    ) internal pure returns (bytes20 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes21 at `mPtr` in memory.
    function readBytes21(
        MemoryPointer mPtr
    ) internal pure returns (bytes21 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes22 at `mPtr` in memory.
    function readBytes22(
        MemoryPointer mPtr
    ) internal pure returns (bytes22 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes23 at `mPtr` in memory.
    function readBytes23(
        MemoryPointer mPtr
    ) internal pure returns (bytes23 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes24 at `mPtr` in memory.
    function readBytes24(
        MemoryPointer mPtr
    ) internal pure returns (bytes24 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes25 at `mPtr` in memory.
    function readBytes25(
        MemoryPointer mPtr
    ) internal pure returns (bytes25 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes26 at `mPtr` in memory.
    function readBytes26(
        MemoryPointer mPtr
    ) internal pure returns (bytes26 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes27 at `mPtr` in memory.
    function readBytes27(
        MemoryPointer mPtr
    ) internal pure returns (bytes27 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes28 at `mPtr` in memory.
    function readBytes28(
        MemoryPointer mPtr
    ) internal pure returns (bytes28 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes29 at `mPtr` in memory.
    function readBytes29(
        MemoryPointer mPtr
    ) internal pure returns (bytes29 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes30 at `mPtr` in memory.
    function readBytes30(
        MemoryPointer mPtr
    ) internal pure returns (bytes30 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes31 at `mPtr` in memory.
    function readBytes31(
        MemoryPointer mPtr
    ) internal pure returns (bytes31 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the bytes32 at `mPtr` in memory.
    function readBytes32(
        MemoryPointer mPtr
    ) internal pure returns (bytes32 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint8 at `mPtr` in memory.
    function readUint8(MemoryPointer mPtr) internal pure returns (uint8 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint16 at `mPtr` in memory.
    function readUint16(
        MemoryPointer mPtr
    ) internal pure returns (uint16 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint24 at `mPtr` in memory.
    function readUint24(
        MemoryPointer mPtr
    ) internal pure returns (uint24 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint32 at `mPtr` in memory.
    function readUint32(
        MemoryPointer mPtr
    ) internal pure returns (uint32 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint40 at `mPtr` in memory.
    function readUint40(
        MemoryPointer mPtr
    ) internal pure returns (uint40 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint48 at `mPtr` in memory.
    function readUint48(
        MemoryPointer mPtr
    ) internal pure returns (uint48 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint56 at `mPtr` in memory.
    function readUint56(
        MemoryPointer mPtr
    ) internal pure returns (uint56 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint64 at `mPtr` in memory.
    function readUint64(
        MemoryPointer mPtr
    ) internal pure returns (uint64 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint72 at `mPtr` in memory.
    function readUint72(
        MemoryPointer mPtr
    ) internal pure returns (uint72 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint80 at `mPtr` in memory.
    function readUint80(
        MemoryPointer mPtr
    ) internal pure returns (uint80 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint88 at `mPtr` in memory.
    function readUint88(
        MemoryPointer mPtr
    ) internal pure returns (uint88 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint96 at `mPtr` in memory.
    function readUint96(
        MemoryPointer mPtr
    ) internal pure returns (uint96 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint104 at `mPtr` in memory.
    function readUint104(
        MemoryPointer mPtr
    ) internal pure returns (uint104 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint112 at `mPtr` in memory.
    function readUint112(
        MemoryPointer mPtr
    ) internal pure returns (uint112 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint120 at `mPtr` in memory.
    function readUint120(
        MemoryPointer mPtr
    ) internal pure returns (uint120 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint128 at `mPtr` in memory.
    function readUint128(
        MemoryPointer mPtr
    ) internal pure returns (uint128 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint136 at `mPtr` in memory.
    function readUint136(
        MemoryPointer mPtr
    ) internal pure returns (uint136 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint144 at `mPtr` in memory.
    function readUint144(
        MemoryPointer mPtr
    ) internal pure returns (uint144 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint152 at `mPtr` in memory.
    function readUint152(
        MemoryPointer mPtr
    ) internal pure returns (uint152 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint160 at `mPtr` in memory.
    function readUint160(
        MemoryPointer mPtr
    ) internal pure returns (uint160 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint168 at `mPtr` in memory.
    function readUint168(
        MemoryPointer mPtr
    ) internal pure returns (uint168 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint176 at `mPtr` in memory.
    function readUint176(
        MemoryPointer mPtr
    ) internal pure returns (uint176 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint184 at `mPtr` in memory.
    function readUint184(
        MemoryPointer mPtr
    ) internal pure returns (uint184 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint192 at `mPtr` in memory.
    function readUint192(
        MemoryPointer mPtr
    ) internal pure returns (uint192 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint200 at `mPtr` in memory.
    function readUint200(
        MemoryPointer mPtr
    ) internal pure returns (uint200 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint208 at `mPtr` in memory.
    function readUint208(
        MemoryPointer mPtr
    ) internal pure returns (uint208 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint216 at `mPtr` in memory.
    function readUint216(
        MemoryPointer mPtr
    ) internal pure returns (uint216 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint224 at `mPtr` in memory.
    function readUint224(
        MemoryPointer mPtr
    ) internal pure returns (uint224 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint232 at `mPtr` in memory.
    function readUint232(
        MemoryPointer mPtr
    ) internal pure returns (uint232 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint240 at `mPtr` in memory.
    function readUint240(
        MemoryPointer mPtr
    ) internal pure returns (uint240 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint248 at `mPtr` in memory.
    function readUint248(
        MemoryPointer mPtr
    ) internal pure returns (uint248 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the uint256 at `mPtr` in memory.
    function readUint256(
        MemoryPointer mPtr
    ) internal pure returns (uint256 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int8 at `mPtr` in memory.
    function readInt8(MemoryPointer mPtr) internal pure returns (int8 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int16 at `mPtr` in memory.
    function readInt16(MemoryPointer mPtr) internal pure returns (int16 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int24 at `mPtr` in memory.
    function readInt24(MemoryPointer mPtr) internal pure returns (int24 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int32 at `mPtr` in memory.
    function readInt32(MemoryPointer mPtr) internal pure returns (int32 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int40 at `mPtr` in memory.
    function readInt40(MemoryPointer mPtr) internal pure returns (int40 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int48 at `mPtr` in memory.
    function readInt48(MemoryPointer mPtr) internal pure returns (int48 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int56 at `mPtr` in memory.
    function readInt56(MemoryPointer mPtr) internal pure returns (int56 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int64 at `mPtr` in memory.
    function readInt64(MemoryPointer mPtr) internal pure returns (int64 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int72 at `mPtr` in memory.
    function readInt72(MemoryPointer mPtr) internal pure returns (int72 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int80 at `mPtr` in memory.
    function readInt80(MemoryPointer mPtr) internal pure returns (int80 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int88 at `mPtr` in memory.
    function readInt88(MemoryPointer mPtr) internal pure returns (int88 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int96 at `mPtr` in memory.
    function readInt96(MemoryPointer mPtr) internal pure returns (int96 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int104 at `mPtr` in memory.
    function readInt104(
        MemoryPointer mPtr
    ) internal pure returns (int104 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int112 at `mPtr` in memory.
    function readInt112(
        MemoryPointer mPtr
    ) internal pure returns (int112 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int120 at `mPtr` in memory.
    function readInt120(
        MemoryPointer mPtr
    ) internal pure returns (int120 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int128 at `mPtr` in memory.
    function readInt128(
        MemoryPointer mPtr
    ) internal pure returns (int128 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int136 at `mPtr` in memory.
    function readInt136(
        MemoryPointer mPtr
    ) internal pure returns (int136 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int144 at `mPtr` in memory.
    function readInt144(
        MemoryPointer mPtr
    ) internal pure returns (int144 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int152 at `mPtr` in memory.
    function readInt152(
        MemoryPointer mPtr
    ) internal pure returns (int152 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int160 at `mPtr` in memory.
    function readInt160(
        MemoryPointer mPtr
    ) internal pure returns (int160 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int168 at `mPtr` in memory.
    function readInt168(
        MemoryPointer mPtr
    ) internal pure returns (int168 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int176 at `mPtr` in memory.
    function readInt176(
        MemoryPointer mPtr
    ) internal pure returns (int176 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int184 at `mPtr` in memory.
    function readInt184(
        MemoryPointer mPtr
    ) internal pure returns (int184 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int192 at `mPtr` in memory.
    function readInt192(
        MemoryPointer mPtr
    ) internal pure returns (int192 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int200 at `mPtr` in memory.
    function readInt200(
        MemoryPointer mPtr
    ) internal pure returns (int200 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int208 at `mPtr` in memory.
    function readInt208(
        MemoryPointer mPtr
    ) internal pure returns (int208 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int216 at `mPtr` in memory.
    function readInt216(
        MemoryPointer mPtr
    ) internal pure returns (int216 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int224 at `mPtr` in memory.
    function readInt224(
        MemoryPointer mPtr
    ) internal pure returns (int224 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int232 at `mPtr` in memory.
    function readInt232(
        MemoryPointer mPtr
    ) internal pure returns (int232 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int240 at `mPtr` in memory.
    function readInt240(
        MemoryPointer mPtr
    ) internal pure returns (int240 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int248 at `mPtr` in memory.
    function readInt248(
        MemoryPointer mPtr
    ) internal pure returns (int248 value) {
        assembly {
            value := mload(mPtr)
        }
    }

    /// @dev Reads the int256 at `mPtr` in memory.
    function readInt256(
        MemoryPointer mPtr
    ) internal pure returns (int256 value) {
        assembly {
            value := mload(mPtr)
        }
    }
}

library MemoryWriters {
    /// @dev Writes `valuePtr` to memory at `mPtr`.
    function write(MemoryPointer mPtr, MemoryPointer valuePtr) internal pure {
        assembly {
            mstore(mPtr, valuePtr)
        }
    }

    /// @dev Writes a boolean `value` to `mPtr` in memory.
    function write(MemoryPointer mPtr, bool value) internal pure {
        assembly {
            mstore(mPtr, value)
        }
    }

    /// @dev Writes an address `value` to `mPtr` in memory.
    function write(MemoryPointer mPtr, address value) internal pure {
        assembly {
            mstore(mPtr, value)
        }
    }

    /// @dev Writes a bytes32 `value` to `mPtr` in memory.
    /// Separate name to disambiguate literal write parameters.
    function writeBytes32(MemoryPointer mPtr, bytes32 value) internal pure {
        assembly {
            mstore(mPtr, value)
        }
    }

    /// @dev Writes a uint256 `value` to `mPtr` in memory.
    function write(MemoryPointer mPtr, uint256 value) internal pure {
        assembly {
            mstore(mPtr, value)
        }
    }

    /// @dev Writes an int256 `value` to `mPtr` in memory.
    /// Separate name to disambiguate literal write parameters.
    function writeInt(MemoryPointer mPtr, int256 value) internal pure {
        assembly {
            mstore(mPtr, value)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

uint256 constant Error_selector_offset = 0x1c;

/*
 *  error MissingFulfillmentComponentOnAggregation(uint8 side)
 *    - Defined in FulfillmentApplicationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: side
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant MissingFulfillmentComponentOnAggregation_error_selector = (
    0x375c24c1
);
uint256 constant MissingFulfillmentComponentOnAggregation_error_side_ptr = 0x20;
uint256 constant MissingFulfillmentComponentOnAggregation_error_length = 0x24;

/*
 *  error OfferAndConsiderationRequiredOnFulfillment()
 *    - Defined in FulfillmentApplicationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant OfferAndConsiderationRequiredOnFulfillment_error_selector = (
    0x98e9db6e
);
uint256 constant OfferAndConsiderationRequiredOnFulfillment_error_length = 0x04;

/*
 *  error MismatchedFulfillmentOfferAndConsiderationComponents(
 *      uint256 fulfillmentIndex
 *  )
 *    - Defined in FulfillmentApplicationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: fulfillmentIndex
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant MismatchedOfferAndConsiderationComponents_error_selector = (
    0xbced929d
);
uint256 constant MismatchedOfferAndConsiderationComponents_error_idx_ptr = 0x20;
uint256 constant MismatchedOfferAndConsiderationComponents_error_length = 0x24;

/*
 *  error InvalidFulfillmentComponentData()
 *    - Defined in FulfillmentApplicationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InvalidFulfillmentComponentData_error_selector = 0x7fda7279;
uint256 constant InvalidFulfillmentComponentData_error_length = 0x04;

/*
 *  error InexactFraction()
 *    - Defined in AmountDerivationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InexactFraction_error_selector = 0xc63cf089;
uint256 constant InexactFraction_error_length = 0x04;

/*
 *  error OrderCriteriaResolverOutOfRange(uint8 side)
 *    - Defined in CriteriaResolutionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: side
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant OrderCriteriaResolverOutOfRange_error_selector = 0x133c37c6;
uint256 constant OrderCriteriaResolverOutOfRange_error_side_ptr = 0x20;
uint256 constant OrderCriteriaResolverOutOfRange_error_length = 0x24;

/*
 *  error UnresolvedOfferCriteria(uint256 orderIndex, uint256 offerIndex)
 *    - Defined in CriteriaResolutionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderIndex
 *    - 0x40: offerIndex
 * Revert buffer is memory[0x1c:0x60]
 */
uint256 constant UnresolvedOfferCriteria_error_selector = 0xd6929332;
uint256 constant UnresolvedOfferCriteria_error_orderIndex_ptr = 0x20;
uint256 constant UnresolvedOfferCriteria_error_offerIndex_ptr = 0x40;
uint256 constant UnresolvedOfferCriteria_error_length = 0x44;

/*
 *  error UnresolvedConsiderationCriteria(
 *      uint256 orderIndex,
 *      uint256 considerationIndex
 *  )
 *    - Defined in CriteriaResolutionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderIndex
 *    - 0x40: considerationIndex
 * Revert buffer is memory[0x1c:0x60]
 */
uint256 constant UnresolvedConsiderationCriteria_error_selector = 0xa8930e9a;
uint256 constant UnresolvedConsiderationCriteria_error_orderIndex_ptr = 0x20;
uint256 constant UnresolvedConsiderationCriteria_error_considerationIdx_ptr = (
    0x40
);
uint256 constant UnresolvedConsiderationCriteria_error_length = 0x44;

/*
 *  error OfferCriteriaResolverOutOfRange()
 *    - Defined in CriteriaResolutionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant OfferCriteriaResolverOutOfRange_error_selector = 0xbfb3f8ce;
// uint256 constant OfferCriteriaResolverOutOfRange_error_length = 0x04;

/*
 *  error ConsiderationCriteriaResolverOutOfRange()
 *    - Defined in CriteriaResolutionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant ConsiderationCriteriaResolverOutOfRange_error_selector = (
    0x6088d7de
);
uint256 constant ConsiderationCriteriaResolverOutOfRange_err_selector = (
    0x6088d7de
);
// uint256 constant ConsiderationCriteriaResolverOutOfRange_error_length = 0x04;

/*
 *  error CriteriaNotEnabledForItem()
 *    - Defined in CriteriaResolutionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant CriteriaNotEnabledForItem_error_selector = 0x94eb6af6;
uint256 constant CriteriaNotEnabledForItem_error_length = 0x04;

/*
 *  error InvalidProof()
 *    - Defined in CriteriaResolutionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InvalidProof_error_selector = 0x09bde339;
uint256 constant InvalidProof_error_length = 0x04;

/*
 *  error InvalidRestrictedOrder(bytes32 orderHash)
 *    - Defined in ZoneInteractionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderHash
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant InvalidRestrictedOrder_error_selector = 0xfb5014fc;
uint256 constant InvalidRestrictedOrder_error_orderHash_ptr = 0x20;
uint256 constant InvalidRestrictedOrder_error_length = 0x24;

/*
 *  error InvalidContractOrder(bytes32 orderHash)
 *    - Defined in ZoneInteractionErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderHash
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant InvalidContractOrder_error_selector = 0x93979285;
uint256 constant InvalidContractOrder_error_orderHash_ptr = 0x20;
uint256 constant InvalidContractOrder_error_length = 0x24;

/*
 *  error BadSignatureV(uint8 v)
 *    - Defined in SignatureVerificationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: v
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant BadSignatureV_error_selector = 0x1f003d0a;
uint256 constant BadSignatureV_error_v_ptr = 0x20;
uint256 constant BadSignatureV_error_length = 0x24;

/*
 *  error InvalidSigner()
 *    - Defined in SignatureVerificationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InvalidSigner_error_selector = 0x815e1d64;
uint256 constant InvalidSigner_error_length = 0x04;

/*
 *  error InvalidSignature()
 *    - Defined in SignatureVerificationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InvalidSignature_error_selector = 0x8baa579f;
uint256 constant InvalidSignature_error_length = 0x04;

/*
 *  error BadContractSignature()
 *    - Defined in SignatureVerificationErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant BadContractSignature_error_selector = 0x4f7fb80d;
uint256 constant BadContractSignature_error_length = 0x04;

/*
 *  error InvalidERC721TransferAmount(uint256 amount)
 *    - Defined in TokenTransferrerErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: amount
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant InvalidERC721TransferAmount_error_selector = 0x69f95827;
uint256 constant InvalidERC721TransferAmount_error_amount_ptr = 0x20;
uint256 constant InvalidERC721TransferAmount_error_length = 0x24;

/*
 *  error MissingItemAmount()
 *    - Defined in TokenTransferrerErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant MissingItemAmount_error_selector = 0x91b3e514;
uint256 constant MissingItemAmount_error_length = 0x04;

/*
 *  error UnusedItemParameters()
 *    - Defined in TokenTransferrerErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant UnusedItemParameters_error_selector = 0x6ab37ce7;
uint256 constant UnusedItemParameters_error_length = 0x04;

/*
 *  error NoReentrantCalls()
 *    - Defined in ReentrancyErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant NoReentrantCalls_error_selector = 0x7fa8a987;
uint256 constant NoReentrantCalls_error_length = 0x04;

/*
 *  error OrderAlreadyFilled(bytes32 orderHash)
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderHash
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant OrderAlreadyFilled_error_selector = 0x10fda3e1;
uint256 constant OrderAlreadyFilled_error_orderHash_ptr = 0x20;
uint256 constant OrderAlreadyFilled_error_length = 0x24;

/*
 *  error InvalidTime(uint256 startTime, uint256 endTime)
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: startTime
 *    - 0x40: endTime
 * Revert buffer is memory[0x1c:0x60]
 */
uint256 constant InvalidTime_error_selector = 0x21ccfeb7;
uint256 constant InvalidTime_error_startTime_ptr = 0x20;
uint256 constant InvalidTime_error_endTime_ptr = 0x40;
uint256 constant InvalidTime_error_length = 0x44;

/*
 *  error InvalidConduit(bytes32 conduitKey, address conduit)
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: conduitKey
 *    - 0x40: conduit
 * Revert buffer is memory[0x1c:0x60]
 */
uint256 constant InvalidConduit_error_selector = 0x1cf99b26;
uint256 constant InvalidConduit_error_conduitKey_ptr = 0x20;
uint256 constant InvalidConduit_error_conduit_ptr = 0x40;
uint256 constant InvalidConduit_error_length = 0x44;

/*
 *  error MissingOriginalConsiderationItems()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant MissingOriginalConsiderationItems_error_selector = 0x466aa616;
uint256 constant MissingOriginalConsiderationItems_error_length = 0x04;

/*
 *  error InvalidCallToConduit(address conduit)
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: conduit
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant InvalidCallToConduit_error_selector = 0xd13d53d4;
uint256 constant InvalidCallToConduit_error_conduit_ptr = 0x20;
uint256 constant InvalidCallToConduit_error_length = 0x24;

/*
 *  error ConsiderationNotMet(
 *      uint256 orderIndex,
 *      uint256 considerationIndex,
 *      uint256 shortfallAmount
 *  )
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderIndex
 *    - 0x40: considerationIndex
 *    - 0x60: shortfallAmount
 * Revert buffer is memory[0x1c:0x80]
 */
uint256 constant ConsiderationNotMet_error_selector = 0xa5f54208;
uint256 constant ConsiderationNotMet_error_orderIndex_ptr = 0x20;
uint256 constant ConsiderationNotMet_error_considerationIndex_ptr = 0x40;
uint256 constant ConsiderationNotMet_error_shortfallAmount_ptr = 0x60;
uint256 constant ConsiderationNotMet_error_length = 0x64;

/*
 *  error InsufficientNativeTokensSupplied()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InsufficientNativeTokensSupplied_error_selector = 0x8ffff980;
uint256 constant InsufficientNativeTokensSupplied_error_length = 0x04;

/*
 *  error NativeTokenTransferGenericFailure(address account, uint256 amount)
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: account
 *    - 0x40: amount
 * Revert buffer is memory[0x1c:0x60]
 */
uint256 constant NativeTokenTransferGenericFailure_error_selector = 0xbc806b96;
uint256 constant NativeTokenTransferGenericFailure_error_account_ptr = 0x20;
uint256 constant NativeTokenTransferGenericFailure_error_amount_ptr = 0x40;
uint256 constant NativeTokenTransferGenericFailure_error_length = 0x44;

/*
 *  error PartialFillsNotEnabledForOrder()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant PartialFillsNotEnabledForOrder_error_selector = 0xa11b63ff;
uint256 constant PartialFillsNotEnabledForOrder_error_length = 0x04;

/*
 *  error OrderIsCancelled(bytes32 orderHash)
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderHash
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant OrderIsCancelled_error_selector = 0x1a515574;
uint256 constant OrderIsCancelled_error_orderHash_ptr = 0x20;
uint256 constant OrderIsCancelled_error_length = 0x24;

/*
 *  error OrderPartiallyFilled(bytes32 orderHash)
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: orderHash
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant OrderPartiallyFilled_error_selector = 0xee9e0e63;
uint256 constant OrderPartiallyFilled_error_orderHash_ptr = 0x20;
uint256 constant OrderPartiallyFilled_error_length = 0x24;

/*
 *  error CannotCancelOrder()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant CannotCancelOrder_error_selector = 0xfed398fc;
uint256 constant CannotCancelOrder_error_length = 0x04;

/*
 *  error BadFraction()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant BadFraction_error_selector = 0x5a052b32;
uint256 constant BadFraction_error_length = 0x04;

/*
 *  error InvalidMsgValue(uint256 value)
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: value
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant InvalidMsgValue_error_selector = 0xa61be9f0;
uint256 constant InvalidMsgValue_error_value_ptr = 0x20;
uint256 constant InvalidMsgValue_error_length = 0x24;

/*
 *  error InvalidBasicOrderParameterEncoding()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InvalidBasicOrderParameterEncoding_error_selector = 0x39f3e3fd;
uint256 constant InvalidBasicOrderParameterEncoding_error_length = 0x04;

/*
 *  error NoSpecifiedOrdersAvailable()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant NoSpecifiedOrdersAvailable_error_selector = 0xd5da9a1b;
uint256 constant NoSpecifiedOrdersAvailable_error_length = 0x04;

/*
 *  error InvalidNativeOfferItem()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant InvalidNativeOfferItem_error_selector = 0x12d3f5a3;
uint256 constant InvalidNativeOfferItem_error_length = 0x04;

/*
 *  error ConsiderationLengthNotEqualToTotalOriginal()
 *    - Defined in ConsiderationEventsAndErrors.sol
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 * Revert buffer is memory[0x1c:0x20]
 */
uint256 constant ConsiderationLengthNotEqualToTotalOriginal_error_selector = (
    0x2165628a
);
uint256 constant ConsiderationLengthNotEqualToTotalOriginal_error_length = 0x04;

/*
 *  error Panic(uint256 code)
 *    - Built-in Solidity error
 *  Memory layout:
 *    - 0x00: Left-padded selector (data begins at 0x1c)
 *    - 0x20: code
 * Revert buffer is memory[0x1c:0x40]
 */
uint256 constant Panic_error_selector = 0x4e487b71;
uint256 constant Panic_error_code_ptr = 0x20;
uint256 constant Panic_error_length = 0x24;

uint256 constant Panic_arithmetic = 0x11;
// uint256 constant Panic_resource = 0x41;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title SignatureVerificationErrors
 * @author 0age
 * @notice SignatureVerificationErrors contains all errors related to signature
 *         verification.
 */
interface SignatureVerificationErrors {
    /**
     * @dev Revert with an error when a signature that does not contain a v
     *      value of 27 or 28 has been supplied.
     *
     * @param v The invalid v value.
     */
    error BadSignatureV(uint8 v);

    /**
     * @dev Revert with an error when the signer recovered by the supplied
     *      signature does not match the offerer or an allowed EIP-1271 signer
     *      as specified by the offerer in the event they are a contract.
     */
    error InvalidSigner();

    /**
     * @dev Revert with an error when a signer cannot be recovered from the
     *      supplied signature.
     */
    error InvalidSignature();

    /**
     * @dev Revert with an error when an EIP-1271 call to an account fails.
     */
    error BadContractSignature();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    CostPerWord,
    ExtraGasBuffer,
    FreeMemoryPointerSlot,
    MemoryExpansionCoefficientShift,
    OneWord,
    OneWordShift,
    ThirtyOneBytes
} from "seaport-types/src/lib/ConsiderationConstants.sol";

/**
 * @title LowLevelHelpers
 * @author 0age
 * @notice LowLevelHelpers contains logic for performing various low-level
 *         operations.
 */
contract LowLevelHelpers {
    /**
     * @dev Internal view function to revert and pass along the revert reason if
     *      data was returned by the last call and that the size of that data
     *      does not exceed the currently allocated memory size.
     */
    function _revertWithReasonIfOneIsReturned() internal view {
        assembly {
            // If it returned a message, bubble it up as long as sufficient gas
            // remains to do so:
            if returndatasize() {
                // Ensure that sufficient gas is available to copy returndata
                // while expanding memory where necessary. Start by computing
                // the word size of returndata and allocated memory.
                let returnDataWords := shr(OneWordShift, add(returndatasize(), ThirtyOneBytes))

                // Note: use the free memory pointer in place of msize() to work
                // around a Yul warning that prevents accessing msize directly
                // when the IR pipeline is activated.
                let msizeWords := shr(OneWordShift, mload(FreeMemoryPointerSlot))

                // Next, compute the cost of the returndatacopy.
                let cost := mul(CostPerWord, returnDataWords)

                // Then, compute cost of new memory allocation.
                if gt(returnDataWords, msizeWords) {
                    cost :=
                        add(
                            cost,
                            add(
                                mul(sub(returnDataWords, msizeWords), CostPerWord),
                                shr(
                                    MemoryExpansionCoefficientShift,
                                    sub(mul(returnDataWords, returnDataWords), mul(msizeWords, msizeWords))
                                )
                            )
                        )
                }

                // Finally, add a small constant and compare to gas remaining;
                // bubble up the revert data if enough gas is still available.
                if lt(add(cost, ExtraGasBuffer), gas()) {
                    // Copy returndata to memory; overwrite existing memory.
                    returndatacopy(0, 0, returndatasize())

                    // Revert, specifying memory region with copied returndata.
                    revert(0, returndatasize())
                }
            }
        }
    }

    /**
     * @dev Internal view function to branchlessly select either the caller (if
     *      a supplied recipient is equal to zero) or the supplied recipient (if
     *      that recipient is a nonzero value).
     *
     * @param recipient The supplied recipient.
     *
     * @return updatedRecipient The updated recipient.
     */
    function _substituteCallerForEmptyRecipient(address recipient) internal view returns (address updatedRecipient) {
        // Utilize assembly to perform a branchless operation on the recipient.
        assembly {
            // Add caller to recipient if recipient equals 0; otherwise add 0.
            updatedRecipient := add(recipient, mul(iszero(recipient), caller()))
        }
    }

    /**
     * @dev Internal pure function to cast a `bool` value to a `uint256` value.
     *
     * @param b The `bool` value to cast.
     *
     * @return u The `uint256` value.
     */
    function _cast(bool b) internal pure returns (uint256 u) {
        assembly {
            u := b
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {
    AdvancedOrder,
    BasicOrderParameters,
    CriteriaResolver,
    Execution,
    Fulfillment,
    FulfillmentComponent,
    Order,
    OrderComponents
} from "../lib/ConsiderationStructs.sol";

/**
 * @title ConsiderationInterface
 * @author 0age
 * @custom:version 1.5
 * @notice Consideration is a generalized native token/ERC20/ERC721/ERC1155
 *         marketplace. It minimizes external calls to the greatest extent
 *         possible and provides lightweight methods for common routes as well
 *         as more flexible methods for composing advanced orders.
 *
 * @dev ConsiderationInterface contains all external function interfaces for
 *      Consideration.
 */
interface ConsiderationInterface {
    /**
     * @notice Fulfill an order offering an ERC721 token by supplying Ether (or
     *         the native token for the given chain) as consideration for the
     *         order. An arbitrary number of "additional recipients" may also be
     *         supplied which will each receive native tokens from the fulfiller
     *         as consideration.
     *
     * @param parameters Additional information on the fulfilled order. Note
     *                   that the offerer must first approve this contract (or
     *                   their preferred conduit if indicated by the order) for
     *                   their offered ERC721 token to be transferred.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillBasicOrder(
        BasicOrderParameters calldata parameters
    ) external payable returns (bool fulfilled);

    /**
     * @notice Fulfill an order with an arbitrary number of items for offer and
     *         consideration. Note that this function does not support
     *         criteria-based orders or partial filling of orders (though
     *         filling the remainder of a partially-filled order is supported).
     *
     * @param order               The order to fulfill. Note that both the
     *                            offerer and the fulfiller must first approve
     *                            this contract (or the corresponding conduit if
     *                            indicated) to transfer any relevant tokens on
     *                            their behalf and that contracts must implement
     *                            `onERC1155Received` to receive ERC1155 tokens
     *                            as consideration.
     * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
     *                            any, to source the fulfiller's token approvals
     *                            from. The zero hash signifies that no conduit
     *                            should be used, with direct approvals set on
     *                            Consideration.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillOrder(
        Order calldata order,
        bytes32 fulfillerConduitKey
    ) external payable returns (bool fulfilled);

    /**
     * @notice Fill an order, fully or partially, with an arbitrary number of
     *         items for offer and consideration alongside criteria resolvers
     *         containing specific token identifiers and associated proofs.
     *
     * @param advancedOrder       The order to fulfill along with the fraction
     *                            of the order to attempt to fill. Note that
     *                            both the offerer and the fulfiller must first
     *                            approve this contract (or their preferred
     *                            conduit if indicated by the order) to transfer
     *                            any relevant tokens on their behalf and that
     *                            contracts must implement `onERC1155Received`
     *                            to receive ERC1155 tokens as consideration.
     *                            Also note that all offer and consideration
     *                            components must have no remainder after
     *                            multiplication of the respective amount with
     *                            the supplied fraction for the partial fill to
     *                            be considered valid.
     * @param criteriaResolvers   An array where each element contains a
     *                            reference to a specific offer or
     *                            consideration, a token identifier, and a proof
     *                            that the supplied token identifier is
     *                            contained in the merkle root held by the item
     *                            in question's criteria element. Note that an
     *                            empty criteria indicates that any
     *                            (transferable) token identifier on the token
     *                            in question is valid and that no associated
     *                            proof needs to be supplied.
     * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
     *                            any, to source the fulfiller's token approvals
     *                            from. The zero hash signifies that no conduit
     *                            should be used, with direct approvals set on
     *                            Consideration.
     * @param recipient           The intended recipient for all received items,
     *                            with `address(0)` indicating that the caller
     *                            should receive the items.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);

    /**
     * @notice Attempt to fill a group of orders, each with an arbitrary number
     *         of items for offer and consideration. Any order that is not
     *         currently active, has already been fully filled, or has been
     *         cancelled will be omitted. Remaining offer and consideration
     *         items will then be aggregated where possible as indicated by the
     *         supplied offer and consideration component arrays and aggregated
     *         items will be transferred to the fulfiller or to each intended
     *         recipient, respectively. Note that a failing item transfer or an
     *         issue with order formatting will cause the entire batch to fail.
     *         Note that this function does not support criteria-based orders or
     *         partial filling of orders (though filling the remainder of a
     *         partially-filled order is supported).
     *
     * @param orders                    The orders to fulfill. Note that both
     *                                  the offerer and the fulfiller must first
     *                                  approve this contract (or the
     *                                  corresponding conduit if indicated) to
     *                                  transfer any relevant tokens on their
     *                                  behalf and that contracts must implement
     *                                  `onERC1155Received` to receive ERC1155
     *                                  tokens as consideration.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     * @param fulfillerConduitKey       A bytes32 value indicating what conduit,
     *                                  if any, to source the fulfiller's token
     *                                  approvals from. The zero hash signifies
     *                                  that no conduit should be used, with
     *                                  direct approvals set on this contract.
     * @param maximumFulfilled          The maximum number of orders to fulfill.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     * @return executions      An array of elements indicating the sequence of
     *                         transfers performed as part of matching the given
     *                         orders. Note that unspent offer item amounts or
     *                         native tokens will not be reflected as part of
     *                         this array.
     */
    function fulfillAvailableOrders(
        Order[] calldata orders,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        uint256 maximumFulfilled
    )
        external
        payable
        returns (bool[] memory availableOrders, Execution[] memory executions);

    /**
     * @notice Attempt to fill a group of orders, fully or partially, with an
     *         arbitrary number of items for offer and consideration per order
     *         alongside criteria resolvers containing specific token
     *         identifiers and associated proofs. Any order that is not
     *         currently active, has already been fully filled, or has been
     *         cancelled will be omitted. Remaining offer and consideration
     *         items will then be aggregated where possible as indicated by the
     *         supplied offer and consideration component arrays and aggregated
     *         items will be transferred to the fulfiller or to each intended
     *         recipient, respectively. Note that a failing item transfer or an
     *         issue with order formatting will cause the entire batch to fail.
     *
     * @param advancedOrders            The orders to fulfill along with the
     *                                  fraction of those orders to attempt to
     *                                  fill. Note that both the offerer and the
     *                                  fulfiller must first approve this
     *                                  contract (or their preferred conduit if
     *                                  indicated by the order) to transfer any
     *                                  relevant tokens on their behalf and that
     *                                  contracts must implement
     *                                  `onERC1155Received` to enable receipt of
     *                                  ERC1155 tokens as consideration. Also
     *                                  note that all offer and consideration
     *                                  components must have no remainder after
     *                                  multiplication of the respective amount
     *                                  with the supplied fraction for an
     *                                  order's partial fill amount to be
     *                                  considered valid.
     * @param criteriaResolvers         An array where each element contains a
     *                                  reference to a specific offer or
     *                                  consideration, a token identifier, and a
     *                                  proof that the supplied token identifier
     *                                  is contained in the merkle root held by
     *                                  the item in question's criteria element.
     *                                  Note that an empty criteria indicates
     *                                  that any (transferable) token
     *                                  identifier on the token in question is
     *                                  valid and that no associated proof needs
     *                                  to be supplied.
     * @param offerFulfillments         An array of FulfillmentComponent arrays
     *                                  indicating which offer items to attempt
     *                                  to aggregate when preparing executions.
     * @param considerationFulfillments An array of FulfillmentComponent arrays
     *                                  indicating which consideration items to
     *                                  attempt to aggregate when preparing
     *                                  executions.
     * @param fulfillerConduitKey       A bytes32 value indicating what conduit,
     *                                  if any, to source the fulfiller's token
     *                                  approvals from. The zero hash signifies
     *                                  that no conduit should be used, with
     *                                  direct approvals set on this contract.
     * @param recipient                 The intended recipient for all received
     *                                  items, with `address(0)` indicating that
     *                                  the caller should receive the items.
     * @param maximumFulfilled          The maximum number of orders to fulfill.
     *
     * @return availableOrders An array of booleans indicating if each order
     *                         with an index corresponding to the index of the
     *                         returned boolean was fulfillable or not.
     * @return executions      An array of elements indicating the sequence of
     *                         transfers performed as part of matching the given
     *                         orders. Note that unspent offer item amounts or
     *                         native tokens will not be reflected as part of
     *                         this array.
     */
    function fulfillAvailableAdvancedOrders(
        AdvancedOrder[] calldata advancedOrders,
        CriteriaResolver[] calldata criteriaResolvers,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 maximumFulfilled
    )
        external
        payable
        returns (bool[] memory availableOrders, Execution[] memory executions);

    /**
     * @notice Match an arbitrary number of orders, each with an arbitrary
     *         number of items for offer and consideration along with a set of
     *         fulfillments allocating offer components to consideration
     *         components. Note that this function does not support
     *         criteria-based or partial filling of orders (though filling the
     *         remainder of a partially-filled order is supported). Any unspent
     *         offer item amounts or native tokens will be transferred to the
     *         caller.
     *
     * @param orders       The orders to match. Note that both the offerer and
     *                     fulfiller on each order must first approve this
     *                     contract (or their conduit if indicated by the order)
     *                     to transfer any relevant tokens on their behalf and
     *                     each consideration recipient must implement
     *                     `onERC1155Received` to enable ERC1155 token receipt.
     * @param fulfillments An array of elements allocating offer components to
     *                     consideration components. Note that each
     *                     consideration component must be fully met for the
     *                     match operation to be valid.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders. Note that unspent offer item amounts or
     *                    native tokens will not be reflected as part of this
     *                    array.
     */
    function matchOrders(
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    /**
     * @notice Match an arbitrary number of full or partial orders, each with an
     *         arbitrary number of items for offer and consideration, supplying
     *         criteria resolvers containing specific token identifiers and
     *         associated proofs as well as fulfillments allocating offer
     *         components to consideration components. Any unspent offer item
     *         amounts will be transferred to the designated recipient (with the
     *         null address signifying to use the caller) and any unspent native
     *         tokens will be returned to the caller.
     *
     * @param orders            The advanced orders to match. Note that both the
     *                          offerer and fulfiller on each order must first
     *                          approve this contract (or a preferred conduit if
     *                          indicated by the order) to transfer any relevant
     *                          tokens on their behalf and each consideration
     *                          recipient must implement `onERC1155Received` in
     *                          order to receive ERC1155 tokens. Also note that
     *                          the offer and consideration components for each
     *                          order must have no remainder after multiplying
     *                          the respective amount with the supplied fraction
     *                          in order for the group of partial fills to be
     *                          considered valid.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific order as well as that order's
     *                          offer or consideration, a token identifier, and
     *                          a proof that the supplied token identifier is
     *                          contained in the order's merkle root. Note that
     *                          an empty root indicates that any (transferable)
     *                          token identifier is valid and that no associated
     *                          proof needs to be supplied.
     * @param fulfillments      An array of elements allocating offer components
     *                          to consideration components. Note that each
     *                          consideration component must be fully met in
     *                          order for the match operation to be valid.
     * @param recipient         The intended recipient for all unspent offer
     *                          item amounts, or the caller if the null address
     *                          is supplied.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders. Note that unspent offer item amounts or native
     *                    tokens will not be reflected as part of this array.
     */
    function matchAdvancedOrders(
        AdvancedOrder[] calldata orders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments,
        address recipient
    ) external payable returns (Execution[] memory executions);

    /**
     * @notice Cancel an arbitrary number of orders. Note that only the offerer
     *         or the zone of a given order may cancel it. Callers should ensure
     *         that the intended order was cancelled by calling `getOrderStatus`
     *         and confirming that `isCancelled` returns `true`.
     *
     * @param orders The orders to cancel.
     *
     * @return cancelled A boolean indicating whether the supplied orders have
     *                   been successfully cancelled.
     */
    function cancel(
        OrderComponents[] calldata orders
    ) external returns (bool cancelled);

    /**
     * @notice Validate an arbitrary number of orders, thereby registering their
     *         signatures as valid and allowing the fulfiller to skip signature
     *         verification on fulfillment. Note that validated orders may still
     *         be unfulfillable due to invalid item amounts or other factors;
     *         callers should determine whether validated orders are fulfillable
     *         by simulating the fulfillment call prior to execution. Also note
     *         that anyone can validate a signed order, but only the offerer can
     *         validate an order without supplying a signature.
     *
     * @param orders The orders to validate.
     *
     * @return validated A boolean indicating whether the supplied orders have
     *                   been successfully validated.
     */
    function validate(
        Order[] calldata orders
    ) external returns (bool validated);

    /**
     * @notice Cancel all orders from a given offerer with a given zone in bulk
     *         by incrementing a counter. Note that only the offerer may
     *         increment the counter.
     *
     * @return newCounter The new counter.
     */
    function incrementCounter() external returns (uint256 newCounter);

    /**
     * @notice Fulfill an order offering an ERC721 token by supplying Ether (or
     *         the native token for the given chain) as consideration for the
     *         order. An arbitrary number of "additional recipients" may also be
     *         supplied which will each receive native tokens from the fulfiller
     *         as consideration. Note that this function costs less gas than
     *         `fulfillBasicOrder` due to the zero bytes in the function
     *         selector (0x00000000) which also results in earlier function
     *         dispatch.
     *
     * @param parameters Additional information on the fulfilled order. Note
     *                   that the offerer must first approve this contract (or
     *                   their preferred conduit if indicated by the order) for
     *                   their offered ERC721 token to be transferred.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillBasicOrder_efficient_6GL6yc(
        BasicOrderParameters calldata parameters
    ) external payable returns (bool fulfilled);

    /**
     * @notice Retrieve the order hash for a given order.
     *
     * @param order The components of the order.
     *
     * @return orderHash The order hash.
     */
    function getOrderHash(
        OrderComponents calldata order
    ) external view returns (bytes32 orderHash);

    /**
     * @notice Retrieve the status of a given order by hash, including whether
     *         the order has been cancelled or validated and the fraction of the
     *         order that has been filled.
     *
     * @param orderHash The order hash in question.
     *
     * @return isValidated A boolean indicating whether the order in question
     *                     has been validated (i.e. previously approved or
     *                     partially filled).
     * @return isCancelled A boolean indicating whether the order in question
     *                     has been cancelled.
     * @return totalFilled The total portion of the order that has been filled
     *                     (i.e. the "numerator").
     * @return totalSize   The total size of the order that is either filled or
     *                     unfilled (i.e. the "denominator").
     */
    function getOrderStatus(
        bytes32 orderHash
    )
        external
        view
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        );

    /**
     * @notice Retrieve the current counter for a given offerer.
     *
     * @param offerer The offerer in question.
     *
     * @return counter The current counter.
     */
    function getCounter(
        address offerer
    ) external view returns (uint256 counter);

    /**
     * @notice Retrieve configuration information for this contract.
     *
     * @return version           The contract version.
     * @return domainSeparator   The domain separator for this contract.
     * @return conduitController The conduit Controller set for this contract.
     */
    function information()
        external
        view
        returns (
            string memory version,
            bytes32 domainSeparator,
            address conduitController
        );

    function getContractOffererNonce(
        address contractOfferer
    ) external view returns (uint256 nonce);

    /**
     * @notice Retrieve the name of this contract.
     *
     * @return contractName The name of this contract.
     */
    function name() external view returns (string memory contractName);
}