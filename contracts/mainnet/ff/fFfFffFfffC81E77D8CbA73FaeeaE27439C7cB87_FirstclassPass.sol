// SPDX-License-Identifier: CC0
pragma solidity ^0.8.10;

/**
 * @dev Required interface of an ERC4907 compliant contract.
 */
interface IERC4907 {
    /**
     * @notice Emits when the `user` or the `expires` is changed
     */
    event UpdateUser(
        uint256 indexed tokenId,
        address indexed user,
        uint64 expires
    );

    /**
     * @notice Set the user and an expiration time of an NFT
     */
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external;

    /**
     * @notice Query the current user of an NFT
     * @dev The zero address indicates that there is no user
     */
    function userOf(uint256 tokenId) external view returns (address);

    /**
     * @notice Query the end time of the current rental period
     * @dev The zero value indicates that there is no user
     */
    function userExpires(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: CC0
pragma solidity ^0.8.10;

import "./IERC4907.sol";

/**
 * @dev Required interface of an ERC4907Rentable compliant contract.
 */
interface IERC4907Rentable is IERC4907 {
    /**
     * @dev This emits when the rental rate of an NFT changes.
     */
    event UpdateRate(uint256 indexed tokenId, uint256 rate);

    /**
     * @notice Rent an NFT for a period of time
     * @dev Emit the {UpdateUser} event. This function is called by the renter,
     *  while {setUser} is called by the owner or approved operators.
     * @param tokenId The identifier for an NFT
     * @param duration The duration of rental
     */
    function rent(uint256 tokenId, uint64 duration) external payable;

    /**
     * @notice Set the rental price per second for an NFT
     * @dev Emit the {UpdateRate} event.
     * @param tokenId The identifier for an NFT
     * @param rate The rental price per second
     */
    function setRate(uint256 tokenId, uint256 rate) external;

    /**
     * @notice Query the rental price for an NFT
     * @dev A zero rate indicates the NFT is not available for rent.
     * @param tokenId The identifier for an NFT
     * @return The rental price per second, or zero if not available for rent
     */
    function rateOf(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Optimized and flexible operator filterer to abide to OpenSea's
/// mandatory on-chain royalty enforcement in order for new collections to
/// receive royalties.
/// For more information, see:
/// See: https://github.com/ProjectOpenSea/operator-filter-registry
abstract contract OperatorFilterer {
    /// @dev The default OpenSea operator blocklist subscription.
    address internal constant _DEFAULT_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

    /// @dev The OpenSea operator filter registry.
    address internal constant _OPERATOR_FILTER_REGISTRY = 0x000000000000AAeB6D7670E522A718067333cd4E;

    /// @dev Registers the current contract to OpenSea's operator filter,
    /// and subscribe to the default OpenSea operator blocklist.
    /// Note: Will not revert nor update existing settings for repeated registration.
    function _registerForOperatorFiltering() internal virtual {
        _registerForOperatorFiltering(_DEFAULT_SUBSCRIPTION, true);
    }

    /// @dev Registers the current contract to OpenSea's operator filter.
    /// Note: Will not revert nor update existing settings for repeated registration.
    function _registerForOperatorFiltering(address subscriptionOrRegistrantToCopy, bool subscribe)
        internal
        virtual
    {
        /// @solidity memory-safe-assembly
        assembly {
            let functionSelector := 0x7d3e3dbe // `registerAndSubscribe(address,address)`.

            // Clean the upper 96 bits of `subscriptionOrRegistrantToCopy` in case they are dirty.
            subscriptionOrRegistrantToCopy := shr(96, shl(96, subscriptionOrRegistrantToCopy))
            // prettier-ignore
            for {} iszero(subscribe) {} {
                if iszero(subscriptionOrRegistrantToCopy) {
                    functionSelector := 0x4420e486 // `register(address)`.
                    break
                }
                functionSelector := 0xa0af2903 // `registerAndCopyEntries(address,address)`.
                break
            }
            // Store the function selector.
            mstore(0x00, shl(224, functionSelector))
            // Store the `address(this)`.
            mstore(0x04, address())
            // Store the `subscriptionOrRegistrantToCopy`.
            mstore(0x24, subscriptionOrRegistrantToCopy)
            // Register into the registry.
            pop(call(gas(), _OPERATOR_FILTER_REGISTRY, 0, 0x00, 0x44, 0x00, 0x00))
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, because of Solidity's memory size limits.
            mstore(0x24, 0)
        }
    }

    /// @dev Modifier to guard a function and revert if the caller is a blocked operator.
    modifier onlyAllowedOperator(address from) virtual {
        if (from != msg.sender) {
            if (!_isPriorityOperator(msg.sender)) {
                if (_operatorFilteringEnabled()) _revertIfBlocked(msg.sender);
            }
        }
        _;
    }

    /// @dev Modifier to guard a function from approving a blocked operator..
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        if (!_isPriorityOperator(operator)) {
            if (_operatorFilteringEnabled()) _revertIfBlocked(operator);
        }
        _;
    }

    /// @dev Helper function that reverts if the `operator` is blocked by the registry.
    function _revertIfBlocked(address operator) private view {
        /// @solidity memory-safe-assembly
        assembly {
            // Store the function selector of `isOperatorAllowed(address,address)`,
            // shifted left by 6 bytes, which is enough for 8tb of memory.
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0xc6171134001122334455)
            // Store the `address(this)`.
            mstore(0x1a, address())
            // Store the `operator`.
            mstore(0x3a, operator)

            // `isOperatorAllowed` always returns true if it does not revert.
            if iszero(staticcall(gas(), _OPERATOR_FILTER_REGISTRY, 0x16, 0x44, 0x00, 0x00)) {
                // Bubble up the revert if the staticcall reverts.
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }

            // We'll skip checking if `from` is inside the blacklist.
            // Even though that can block transferring out of wrapper contracts,
            // we don't want tokens to be stuck.

            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev For deriving contracts to override, so that operator filtering
    /// can be turned on / off.
    /// Returns true by default.
    function _operatorFilteringEnabled() internal view virtual returns (bool) {
        return true;
    }

    /// @dev For deriving contracts to override, so that preferred marketplaces can
    /// skip operator filtering, helping users save gas.
    /// Returns false for all inputs by default.
    function _isPriorityOperator(address) internal view virtual returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library to encode strings in Base64.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Base64.sol)
/// @author Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos - <[email protected]>.
library Base64 {
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    function encode(
        bytes memory data,
        bool fileSafe,
        bool noPadding
    ) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                // The magic constant 0x0230 will translate "-_" + "+/".
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, sub("ghijklmnopqrstuvwxyz0123456789-_", mul(iszero(fileSafe), 0x0230)))

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                // prettier-ignore
                for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))
                    
                    ptr := add(ptr, 4) // Advance 4 bytes.
                    // prettier-ignore
                    if iszero(lt(ptr, end)) { break }
                }

                let r := mod(dataLength, 3)

                switch noPadding
                case 0 {
                    // Offset `ptr` and pad with '='. We can simply write over the end.
                    mstore8(sub(ptr, iszero(iszero(r))), 0x3d) // Pad at `ptr - 1` if `r > 0`.
                    mstore8(sub(ptr, shl(1, eq(r, 1))), 0x3d) // Pad at `ptr - 2` if `r == 1`.
                    // Write the length of the string.
                    mstore(result, encodedLength)
                }
                default {
                    // Write the length of the string.
                    mstore(result, sub(encodedLength, add(iszero(iszero(r)), eq(r, 1))))
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))
            }
        }
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, false, false)`.
    function encode(bytes memory data) internal pure returns (string memory result) {
        result = encode(data, false, false);
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, fileSafe, false)`.
    function encode(bytes memory data, bool fileSafe) internal pure returns (string memory result) {
        result = encode(data, fileSafe, false);
    }

    /// @dev Encodes base64 encoded `data`.
    ///
    /// Supports:
    /// - RFC 4648 (both standard and file-safe mode).
    /// - RFC 3501 (63: ',').
    ///
    /// Does not support:
    /// - Line breaks.
    ///
    /// Note: For performance reasons,
    /// this function will NOT revert on invalid `data` inputs.
    /// Outputs for invalid inputs will simply be undefined behaviour.
    /// It is the user's responsibility to ensure that the `data`
    /// is a valid base64 encoded string.
    function decode(string memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                let end := add(data, dataLength)
                let decodedLength := mul(shr(2, dataLength), 3)

                switch and(dataLength, 3)
                case 0 {
                    // If padded.
                    decodedLength := sub(
                        decodedLength,
                        add(eq(and(mload(end), 0xFF), 0x3d), eq(and(mload(end), 0xFFFF), 0x3d3d))
                    )
                }
                default {
                    // If non-padded.
                    decodedLength := add(decodedLength, sub(and(dataLength, 3), 1))
                }

                result := mload(0x40)

                // Write the length of the string.
                mstore(result, decodedLength)

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)

                // Load the table into the scratch space.
                // Constants are optimized for smaller bytecode with zero gas overhead.
                // `m` also doubles as the mask of the upper 6 bits.
                let m := 0xfc000000fc00686c7074787c8084888c9094989ca0a4a8acb0b4b8bcc0c4c8cc
                mstore(0x5b, m)
                mstore(0x3b, 0x04080c1014181c2024282c3034383c4044484c5054585c6064)
                mstore(0x1a, 0xf8fcf800fcd0d4d8dce0e4e8ecf0f4)

                // prettier-ignore
                for {} 1 {} {
                    // Read 4 bytes.
                    data := add(data, 4)
                    let input := mload(data)

                    // Write 3 bytes.
                    mstore(ptr, or(
                        and(m, mload(byte(28, input))),
                        shr(6, or(
                            and(m, mload(byte(29, input))),
                            shr(6, or(
                                and(m, mload(byte(30, input))),
                                shr(6, mload(byte(31, input)))
                            ))
                        ))
                    ))

                    ptr := add(ptr, 3)
                    
                    // prettier-ignore
                    if iszero(lt(data, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 32 + 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(add(result, decodedLength), 63), not(31)))

                // Restore the zero slot.
                mstore(0x60, 0)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized ECDSA wrapper.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ECDSA.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ECDSA.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol)
library ECDSA {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The number which `s` must not exceed in order for
    /// the signature to be non-malleable.
    bytes32 private constant _MALLEABILITY_THRESHOLD =
        0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    RECOVERY OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the `signature`.
    ///
    /// This function does NOT accept EIP-2098 short form signatures.
    /// Use `recover(bytes32 hash, bytes32 r, bytes32 vs)` for EIP-2098
    /// short form signatures instead.
    ///
    /// WARNING!
    /// The `result` will be the zero address upon recovery failure.
    /// As such, it is extremely important to ensure that the address which
    /// the `result` is compared against is never zero.
    function recover(bytes32 hash, bytes calldata signature) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            if eq(signature.length, 65) {
                // Copy the free memory pointer so that we can restore it later.
                let m := mload(0x40)
                // Directly copy `r` and `s` from the calldata.
                calldatacopy(0x40, signature.offset, 0x40)

                // If `s` in lower half order, such that the signature is not malleable.
                if iszero(gt(mload(0x60), _MALLEABILITY_THRESHOLD)) {
                    mstore(0x00, hash)
                    // Compute `v` and store it in the scratch space.
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40))))
                    pop(
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            0x01, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x40, // Start of output.
                            0x20 // Size of output.
                        )
                    )
                    // Restore the zero slot.
                    mstore(0x60, 0)
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    result := mload(sub(0x60, returndatasize()))
                }
                // Restore the free memory pointer.
                mstore(0x40, m)
            }
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the EIP-2098 short form signature defined by `r` and `vs`.
    ///
    /// This function only accepts EIP-2098 short form signatures.
    /// See: https://eips.ethereum.org/EIPS/eip-2098
    ///
    /// To be honest, I do not recommend using EIP-2098 signatures
    /// for simplicity, performance, and security reasons. Most if not
    /// all clients support traditional non EIP-2098 signatures by default.
    /// As such, this method is intentionally not fully inlined.
    /// It is merely included for completeness.
    ///
    /// WARNING!
    /// The `result` will be the zero address upon recovery failure.
    /// As such, it is extremely important to ensure that the address which
    /// the `result` is compared against is never zero.
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal view returns (address result) {
        uint8 v;
        bytes32 s;
        /// @solidity memory-safe-assembly
        assembly {
            s := shr(1, shl(1, vs))
            v := add(shr(255, vs), 27)
        }
        result = recover(hash, v, r, s);
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the signature defined by `v`, `r`, `s`.
    ///
    /// WARNING!
    /// The `result` will be the zero address upon recovery failure.
    /// As such, it is extremely important to ensure that the address which
    /// the `result` is compared against is never zero.
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Copy the free memory pointer so that we can restore it later.
            let m := mload(0x40)

            // If `s` in lower half order, such that the signature is not malleable.
            if iszero(gt(s, _MALLEABILITY_THRESHOLD)) {
                mstore(0x00, hash)
                mstore(0x20, v)
                mstore(0x40, r)
                mstore(0x60, s)
                pop(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        0x01, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x40, // Start of output.
                        0x20 // Size of output.
                    )
                )
                // Restore the zero slot.
                mstore(0x60, 0)
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                result := mload(sub(0x60, returndatasize()))
            }
            // Restore the free memory pointer.
            mstore(0x40, m)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an Ethereum Signed Message, created from a `hash`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Store into scratch space for keccak256.
            mstore(0x20, hash)
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32")
            // 0x40 - 0x04 = 0x3c
            result := keccak256(0x04, 0x3c)
        }
    }

    /// @dev Returns an Ethereum Signed Message, created from `s`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32 result) {
        assembly {
            // We need at most 128 bytes for Ethereum signed message header.
            // The max length of the ASCII reprenstation of a uint256 is 78 bytes.
            // The length of "\x19Ethereum Signed Message:\n" is 26 bytes (i.e. 0x1a).
            // The next multiple of 32 above 78 + 26 is 128 (i.e. 0x80).

            // Instead of allocating, we temporarily copy the 128 bytes before the
            // start of `s` data to some variables.
            let m3 := mload(sub(s, 0x60))
            let m2 := mload(sub(s, 0x40))
            let m1 := mload(sub(s, 0x20))
            // The length of `s` is in bytes.
            let sLength := mload(s)

            let ptr := add(s, 0x20)

            // `end` marks the end of the memory which we will compute the keccak256 of.
            let end := add(ptr, sLength)

            // Convert the length of the bytes to ASCII decimal representation
            // and store it into the memory.
            // prettier-ignore
            for { let temp := sLength } 1 {} {
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            // Copy the header over to the memory.
            mstore(sub(ptr, 0x20), "\x00\x00\x00\x00\x00\x00\x19Ethereum Signed Message:\n")
            // Compute the keccak256 of the memory.
            result := keccak256(sub(ptr, 0x1a), sub(end, sub(ptr, 0x1a)))

            // Restore the previous memory.
            mstore(s, sLength)
            mstore(sub(s, 0x20), m1)
            mstore(sub(s, 0x40), m2)
            mstore(sub(s, 0x60), m3)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(uint256 value) internal pure returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/// @author: Firstclass Labs
/// @notice: "If you don’t get it, you don’t get it."

//////////////////////////////////////////////////////////////////////////////////
//      _______           __       __                   __          __          //
//     / ____(_)_________/ /______/ /___ ___________   / /   ____ _/ /_  _____  //
//    / /_  / / ___/ ___/ __/ ___/ / __ `/ ___/ ___/  / /   / __ `/ __ \/ ___/  //
//   / __/ / / /  (__  ) /_/ /__/ / /_/ (__  |__  )  / /___/ /_/ / /_/ (__  )   //
//  /_/   /_/_/  /____/\__/\___/_/\__,_/____/____/  /_____/\__,_/_.___/____/    //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////

import "@firstclasslabs/erc4907/IERC4907Rentable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "closedsea/src/OperatorFilterer.sol";
import "solady/src/utils/Base64.sol";
import "solady/src/utils/ECDSA.sol";
import "solmate/src/auth/Owned.sol";
import "solmate/src/tokens/ERC721.sol";
import "solmate/src/utils/LibString.sol";
import "solmate/src/utils/ReentrancyGuard.sol";

error F_BadInput();
error F_ExceededMaxSupply();
error F_ExceededPermitted();
error F_Forbidden();
error F_PaymentError();
error F_SignatureExpired();
error F_SignatureInvalid();
error F_SignatureUsed();
error F_TokenNotAvailable();
error F_TokenInUse();
error F_Underpaid();

contract FirstclassPass is
    ERC721,
    ERC2981,
    IERC4907Rentable,
    OperatorFilterer,
    Owned,
    ReentrancyGuard
{
    using LibString for uint256;

    // Maximum number of tokens that will be ever created
    uint256 public immutable maxSupply;

    // The number of tokens that currently exists
    uint256 private totalSupply_;

    // Mint price per token
    uint256 public immutable price;

    // Used to verify ECDSA signatures
    address private signer;

    // Keep track of used signatures
    mapping(bytes32 => bool) private signatures;

    /**
     * @notice Container for ERC4907Rentable data
     * @dev We're bullish on Ethereum but we'll likely be dead before `expires`
     * causes a problem in 2106. Also note that the `rate` is uint64 here as
     * opposed to uint256 defined in the interface. A non-zero `rate` means
     * the token is rentable.
     */
    struct Rentable {
        address user;
        uint32 expires;
        uint64 rate;
    }

    /**
     * @notice Mapping from token ID to packed {Rentable} data
     * @dev Bits layout: [255..192][191..160][159..0]
     *                       `rate` `expires`  `user`
     */
    mapping(uint256 => uint256) private rentables;

    // The mask of the lower 160 bits for `user`
    uint256 private constant BITMASK_USER = (1 << 160) - 1;

    // The mask of the lower 32 bits for `expires`
    uint256 private constant BITMASK_EXPIRES = (1 << 32) - 1;

    // The bit position of `expires`
    uint256 private constant BITPOS_EXPIRES = 160;

    // The bit position of `rate`
    uint256 private constant BITPOS_RATE = 192;

    // Minimum duration per rental
    uint256 private constant MIN_RENTAL_DURATION = 24 hours;

    // Maximum duration per rental
    uint256 private constant MAX_RENTAL_DURATION = 14 days;

    // Minimum rent per second
    uint256 private constant MIN_RENTAL_RATE = 100 gwei;

    // Where the funds should go to
    address private treasury;

    // See {ERC721Metadata}
    string private baseURI;

    // 💎 + 🖖
    uint256 private immutable initiation;

    // Keep track of the last transferred timestamps
    mapping(uint256 => uint256) private lastTransferred;

    // ERC2981 default royalty in bps
    uint96 private constant DEFAULT_ROYALTY_BPS = 1000;

    // See {_operatorFilteringEnabled}
    bool private operatorFiltering = true;

    /**
     * @notice Constructooooooor
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _price,
        address _signer,
        address _treasury,
        uint256 _initiation,
        string memory _baseURI
    ) ERC721(_name, _symbol) Owned(msg.sender) {
        signer = _signer;
        treasury = _treasury;
        maxSupply = _maxSupply;
        price = _price;
        initiation = _initiation;
        baseURI = _baseURI;

        _setDefaultRoyalty(_treasury, DEFAULT_ROYALTY_BPS);
        _registerForOperatorFiltering();
    }

    /**
     * @notice Reverts if the queried token does not exist
     */
    modifier exists(uint256 _tokenId) {
        if (_ownerOf[_tokenId] == address(0)) revert F_BadInput();

        _;
    }

    /**
     * @notice Set the ECDSA signer address
     */
    function setSigner(address _signer) external onlyOwner {
        if (_signer == address(0)) revert F_BadInput();

        signer = _signer;
    }

    /**
     * @notice Set the treasury address
     */
    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert F_BadInput();

        treasury = _treasury;
        _setDefaultRoyalty(_treasury, DEFAULT_ROYALTY_BPS);
    }

    /**
     * @notice See {ERC2981}
     */
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    /**
     * @notice See {_operatorFilteringEnabled}
     */
    function setOperatorFiltering(bool _operatorFiltering) external onlyOwner {
        operatorFiltering = _operatorFiltering;
    }

    /**
     * @notice Mint tokens with ECDSA signatures
     */
    function mint(
        uint256 _quantity,
        uint256 _permitted,
        uint256 _deadline,
        bytes calldata _signature
    ) external payable {
        if (_quantity > _permitted) revert F_ExceededPermitted();
        if (totalSupply_ + _quantity > maxSupply) revert F_ExceededMaxSupply();
        if (msg.value < price * _quantity) revert F_Underpaid();
        if (block.timestamp > _deadline) revert F_SignatureExpired();
        if (!_signatureValid(_permitted, _deadline, _signature)) revert F_SignatureInvalid();

        bytes32 signatureHash = keccak256(_signature);
        if (_signatureUsed(signatureHash)) revert F_SignatureUsed();
        signatures[signatureHash] = true;

        (bool sent, ) = treasury.call{value: msg.value}("");
        if (!sent) revert F_PaymentError();

        unchecked {
            for (uint256 i = 0; i < _quantity; i++) {
                uint256 tokenId = ++totalSupply_;
                _safeMint(msg.sender, tokenId);
                lastTransferred[tokenId] = block.timestamp;
            }
        }
    }

    /**
     * @notice See {ERC4907}
     */
    function setUser(
        uint256 _tokenId,
        address _user,
        uint64 _expires
    ) external exists(_tokenId) {
        if (_expires > 2**32 - 1) revert F_BadInput();

        address owner = _ownerOf[_tokenId];
        if (msg.sender != owner)
            if (!isApprovedForAll[owner][msg.sender])
                if (getApproved[_tokenId] != msg.sender) revert F_Forbidden();

        Rentable memory rentable = _unpackedRentable(rentables[_tokenId]);
        if (rentable.expires > block.timestamp) revert F_TokenInUse();

        rentables[_tokenId] = _packRentable(_user, uint32(_expires), rentable.rate);

        emit UpdateUser(_tokenId, _user, _expires);
    }

    /**
     * @notice See {ERC4907}
     */
    function userOf(uint256 _tokenId) external view exists(_tokenId) returns (address) {
        Rentable memory rentable = _unpackedRentable(rentables[_tokenId]);
        return rentable.expires < block.timestamp ? address(0) : rentable.user;
    }

    /**
     * @notice See {ERC4907}
     */
    function userExpires(uint256 _tokenId) external view exists(_tokenId) returns (uint256) {
        Rentable memory rentable = _unpackedRentable(rentables[_tokenId]);
        return rentable.expires < block.timestamp ? 0 : rentable.expires;
    }

    /**
     * @notice See {ERC4907Rentable}
     */
    function rateOf(uint256 _tokenId) external view exists(_tokenId) returns (uint256) {
        return _unpackedRentable(rentables[_tokenId]).rate;
    }

    /**
     * @notice See {ERC4907Rentable}
     */
    function rent(uint256 _tokenId, uint64 _duration)
        external
        payable
        exists(_tokenId)
        nonReentrant
    {
        if (_duration < MIN_RENTAL_DURATION) revert F_BadInput();
        if (_duration > MAX_RENTAL_DURATION) revert F_BadInput();

        Rentable memory rentable = _unpackedRentable(rentables[_tokenId]);
        if (rentable.rate == 0) revert F_TokenNotAvailable();
        if (rentable.expires > block.timestamp) revert F_TokenInUse();

        uint256 rent_ = rentable.rate * _duration;
        if (msg.value < rent_) revert F_Underpaid();

        uint256 expires = block.timestamp + _duration;
        if (expires > 2**32 - 1) revert F_BadInput();

        // Rent distribution also conforms to the ERC2981 standard
        (address receiver, uint256 amount) = royaltyInfo(_tokenId, msg.value);
        (bool sent, ) = receiver.call{value: amount}("");
        if (!sent) revert F_PaymentError();

        address owner = _ownerOf[_tokenId];
        (sent, ) = owner.call{value: msg.value - amount}("");
        if (!sent) revert F_PaymentError();

        rentables[_tokenId] = _packRentable(msg.sender, uint32(expires), rentable.rate);

        emit UpdateUser(_tokenId, msg.sender, uint64(expires));
    }

    /**
     * @notice See {ERC4907Rentable}
     */
    function setRate(uint256 _tokenId, uint256 _rate) external exists(_tokenId) {
        if (_rate > 2**64 - 1) revert F_BadInput();
        if (_rate < MIN_RENTAL_RATE) revert F_BadInput();

        address owner = _ownerOf[_tokenId];
        if (msg.sender != owner)
            if (!isApprovedForAll[owner][msg.sender])
                if (getApproved[_tokenId] != msg.sender) revert F_Forbidden();

        Rentable memory rentable = _unpackedRentable(rentables[_tokenId]);
        if (rentable.expires > block.timestamp) revert F_TokenInUse();

        rentables[_tokenId] = _packRentable(rentable.user, rentable.expires, uint64(_rate));

        emit UpdateRate(_tokenId, _rate);
    }

    /**
     * @notice See {ERC721Metadata}
     */
    function setBaseURI(string calldata _uri) external onlyOwner {
        if (bytes(_uri).length == 0) revert F_BadInput();

        baseURI = _uri;
    }

    /**
     * @notice See {ERC721Metadata}
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        exists(_tokenId)
        returns (string memory)
    {
        if (bytes(baseURI).length == 0) return "";

        string memory id = _tokenId.toString();
        uint256 since = lastTransferred[_tokenId];
        string memory level = (block.timestamp - since) < initiation ? "Silver" : "Black";
        Rentable memory rentable = _unpackedRentable(rentables[_tokenId]);

        /* prettier-ignore */
        string memory encoded = Base64.encode(bytes(string(abi.encodePacked(
            /* solhint-disable */
            '{"name":"', name, ' #', id, '","image":"', baseURI, level, '.png",'
            '"animation_url":"', baseURI, level, '.mp4",'
            '"attributes":[{"trait_type":"Level","value":"', level, '"},',
            rentable.rate > 0 && rentable.expires < block.timestamp ? '{"value":"Rentable"},' : '',
            '{"display_type":"date","trait_type":"Member Since","value":', since.toString(), '}]}'
            /* solhint-enable */
        ))));

        return string(abi.encodePacked("data:application/json;base64,", encoded));
    }

    /**
     * @notice Query when did the membership start
     */
    function memberSince(uint256 _tokenId) public view exists(_tokenId) returns (uint256) {
        return lastTransferred[_tokenId];
    }

    /**
     * @notice See {ERC721Enumerable}
     */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @notice See {ERC721}
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override onlyAllowedOperator(_from) {
        ERC721.transferFrom(_from, _to, _tokenId);
        lastTransferred[_tokenId] = block.timestamp;
    }

    /**
     * @notice See {ERC165}
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            ERC721.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId) ||
            _interfaceId == type(IERC4907).interfaceId ||
            _interfaceId == type(IERC4907Rentable).interfaceId;
    }

    /**
     * @notice Read packed {Rentable} data from uint256
     */
    function _unpackedRentable(uint256 _packed) internal pure returns (Rentable memory rentable) {
        rentable.user = address(uint160(_packed));
        rentable.expires = uint32(_packed >> BITPOS_EXPIRES);
        rentable.rate = uint64(_packed >> BITPOS_RATE);
    }

    /**
     * @notice Pack {Rentable} data into uint256
     */
    function _packRentable(
        address _user,
        uint32 _expires,
        uint64 _rate
    ) internal pure returns (uint256 result) {
        assembly {
            // In case the upper bits somehow aren't clean
            _user := and(_user, BITMASK_USER)
            _expires := and(_expires, BITMASK_EXPIRES)
            // `_user` | (`_expires` << BITPOS_EXPIRES) | (`_rate` << BITPOS_RATE)
            result := or(_user, or(shl(BITPOS_EXPIRES, _expires), shl(BITPOS_RATE, _rate)))
        }
    }

    /**
     * @notice Validate ECDSA signatures
     */
    function _signatureValid(
        uint256 _permitted,
        uint256 _deadline,
        bytes calldata _signature
    ) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _permitted, _deadline));
        address signer_ = ECDSA.recover(hash, _signature);
        return signer_ == signer ? true : false;
    }

    /**
     * @notice Check if an ECDSA signature has been used
     */
    function _signatureUsed(bytes32 _signatureHash) internal view returns (bool) {
        return signatures[_signatureHash];
    }

    /**
     * @dev For context, OpenSea has turned off royalties (yet they still
     * collect their 2.5% platform fees) on new collections that don't block
     * optional royalty marketplaces. As creators we unfortunately have to
     * follow the rule set by OpenSea since they still dominate the market at
     * the moment.
     *
     * This overhead adds ~3k gas to each {transferFrom} call 🖕
     */
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFiltering;
    }
}