// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/Ownable.sol)
/// @dev While the ownable portion follows [EIP-173](https://eips.ethereum.org/EIPS/eip-173)
/// for compatibility, the nomenclature for the 2-step ownership handover
/// may be unique to this codebase.
abstract contract Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The `newOwner` cannot be the zero address.
    error NewOwnerIsZeroAddress();

    /// @dev The `pendingOwner` does not have a valid handover request.
    error NoHandoverRequest();

    /// @dev `bytes4(keccak256(bytes("Unauthorized()")))`.
    uint256 private constant _UNAUTHORIZED_ERROR_SELECTOR = 0x82b42900;

    /// @dev `bytes4(keccak256(bytes("NewOwnerIsZeroAddress()")))`.
    uint256 private constant _NEW_OWNER_IS_ZERO_ADDRESS_ERROR_SELECTOR = 0x7448fbae;

    /// @dev `bytes4(keccak256(bytes("NoHandoverRequest()")))`.
    uint256 private constant _NO_HANDOVER_REQUEST_ERROR_SELECTOR = 0x6f5e8818;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
    /// This event is intentionally kept the same as OpenZeppelin's Ownable to be
    /// compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173),
    /// despite it not being as lightweight as a single argument event.
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @dev An ownership handover to `pendingOwner` has been requested.
    event OwnershipHandoverRequested(address indexed pendingOwner);

    /// @dev The ownership handover to `pendingOwner` has been canceled.
    event OwnershipHandoverCanceled(address indexed pendingOwner);

    /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    /// @dev `keccak256(bytes("OwnershipHandoverRequested(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE =
        0xdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d;

    /// @dev `keccak256(bytes("OwnershipHandoverCanceled(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE =
        0xfa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c92;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The owner slot is given by: `not(_OWNER_SLOT_NOT)`.
    /// It is intentionally choosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    uint256 private constant _OWNER_SLOT_NOT = 0x8b78c6d8;

    /// The ownership handover slot of `newOwner` is given by:
    /// ```
    ///     mstore(0x00, or(shl(96, user), _HANDOVER_SLOT_SEED))
    ///     let handoverSlot := keccak256(0x00, 0x20)
    /// ```
    /// It stores the expiry timestamp of the two-step ownership handover.
    uint256 private constant _HANDOVER_SLOT_SEED = 0x389a75e1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the owner directly without authorization guard.
    /// This function must be called upon initialization,
    /// regardless of whether the contract is upgradeable or not.
    /// This is to enable generalization to both regular and upgradeable contracts,
    /// and to save gas in case the initial owner is not the caller.
    /// For performance reasons, this function will not check if there
    /// is an existing owner.
    function _initializeOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Store the new value.
            sstore(not(_OWNER_SLOT_NOT), newOwner)
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
        }
    }

    /// @dev Sets the owner directly without authorization guard.
    function _setOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let ownerSlot := not(_OWNER_SLOT_NOT)
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
            // Store the new value.
            sstore(ownerSlot, newOwner)
        }
    }

    /// @dev Throws if the sender is not the owner.
    function _checkOwner() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner, revert.
            if iszero(eq(caller(), sload(not(_OWNER_SLOT_NOT)))) {
                mstore(0x00, _UNAUTHORIZED_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        if (newOwner == address(0)) revert NewOwnerIsZeroAddress();
        _setOwner(newOwner);
    }

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() public payable virtual onlyOwner {
        _setOwner(address(0));
    }

    /// @dev Request a two-step ownership handover to the caller.
    /// The request will be automatically expire in 48 hours (172800 seconds) by default.
    function requestOwnershipHandover() public payable virtual {
        unchecked {
            uint256 expires = block.timestamp + ownershipHandoverValidFor();
            /// @solidity memory-safe-assembly
            assembly {
                // Compute and set the handover slot to `expires`.
                mstore(0x0c, _HANDOVER_SLOT_SEED)
                mstore(0x00, caller())
                sstore(keccak256(0x0c, 0x20), expires)
                // Emit the {OwnershipHandoverRequested} event.
                log2(0, 0, _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE, caller())
            }
        }
    }

    /// @dev Cancels the two-step ownership handover to the caller, if any.
    function cancelOwnershipHandover() public payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x20), 0)
            // Emit the {OwnershipHandoverCanceled} event.
            log2(0, 0, _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE, caller())
        }
    }

    /// @dev Allows the owner to complete the two-step ownership handover to `pendingOwner`.
    /// Reverts if there is no existing ownership handover requested by `pendingOwner`.
    function completeOwnershipHandover(address pendingOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            let handoverSlot := keccak256(0x0c, 0x20)
            // If the handover does not exist, or has expired.
            if gt(timestamp(), sload(handoverSlot)) {
                mstore(0x00, _NO_HANDOVER_REQUEST_ERROR_SELECTOR)
                revert(0x1c, 0x04)
            }
            // Set the handover slot to 0.
            sstore(handoverSlot, 0)
        }
        _setOwner(pendingOwner);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the owner of the contract.
    function owner() public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(not(_OWNER_SLOT_NOT))
        }
    }

    /// @dev Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.
    function ownershipHandoverExpiresAt(address pendingOwner)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the handover slot.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            // Load the handover slot.
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Returns how long a two-step ownership handover is valid for in seconds.
    function ownershipHandoverValidFor() public view virtual returns (uint64) {
        return 48 * 3600;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by the owner.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // We don't check and revert upon failure here, just in case
                // `SELFDESTRUCT`'s behavior is changed some day in the future.
                // (If that ever happens, we will riot, and port the code to use WETH).
                pop(create(amount, 0x0b, 0x16))
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overriden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // We don't check and revert upon failure here, just in case
                // `SELFDESTRUCT`'s behavior is changed some day in the future.
                // (If that ever happens, we will riot, and port the code to use WETH).
                pop(create(amount, 0x0b, 0x16))
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x23b872dd)
            mstore(0x20, from) // Append the "from" argument.
            mstore(0x40, to) // Append the "to" argument.
            mstore(0x60, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x64 because that's the total length of our calldata (0x04 + 0x20 * 3)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0xa9059cbb)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x095ea7b3)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
// REMILIA COLLECTIVE
// ETYMOLOGY: Zora Auction House -> Noun Auction House -> Bonkler Auction

pragma solidity ^0.8.4;

import "solady/src/utils/SafeTransferLib.sol";
import "solady/src/auth/Ownable.sol";

contract BonklerAuction is Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event AuctionCreated(uint256 indexed bonklerId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 indexed bonklerId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 indexed bonklerId, uint256 endTime);

    event AuctionSettled(uint256 indexed bonklerId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionBidIncrementUpdated(uint256 bidIncrement);

    event AuctionDurationUpdated(uint256 duration);

    event AuctionReservePercentageUpdated(uint256 reservePercentage);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev A struct containing the auction data and configuration.
     * We bundle as much as possible into a single struct so that we can
     * use a single view function to fetch all the relevant data,
     * helping us reduce RPC calls.
     *
     * Notes: 
     *
     * - `uint96` is enough to represent 79,228,162,514 ETH.
     *   Currently, there is only 120,523,060 ETH in existence.
     *
     * - `uint40` is enough to represent timestamps up to year 36811 A.D.
     */
    struct AuctionData {
        // The address of the current highest bid.
        address bidder;
        // The current highest bid amount.
        uint96 amount;
        // The amount of ETH that can be withdrawn.
        uint96 withdrawable;
        // The start time of the auction.
        uint40 startTime;
        // The end time of the auction.
        uint40 endTime;
        // ID for the Bonkler (ERC721 token ID). Starts from 0.
        uint24 bonklerId;
        // The number of generation hashes preloaded into the contract.
        uint24 generationHashesLength;
        // Whether or not the auction has been settled.
        bool settled;
        // The percent (0 .. 100) of the bidded amount to store in the Bonkler.
        uint8 reservePercentage;
        // The Bonklers ERC721 token contract.
        address bonklers;
        // The minimum price accepted in an auction.
        uint96 reservePrice;
        // The purchase price for a bonkler.
        uint96 purchasePrice;
        // The minimum bid increment.
        uint96 bidIncrement;
        // The duration of a single auction.
        uint32 duration;
        // The minimum amount of time left in an auction after a new bid is created.
        uint32 timeBuffer;
    }

    /**
     * @dev The auction data.
     */
    AuctionData internal _auctionData;

    /**
     * @dev Custom mapping of `bonklerId` to the keccak256 of its `generationHash`.
     *
     * In order to allow users to auto-settle and auto-create auctions
     * as they bid, we preload the generation hashes into the contract.
     *
     * Functionally similar to a `mapping(uint256 => uint256)`,
     * but offers the advantage of lower gas usage and easier upgrades.
     *
     * The storage slot of a value is computed via:
     * ```
     *     mstore(0x0c, _GENERATION_HASH_HASHES_SLOT_SEED)
     *     mstore(0x00, bonklerId)
     *     storageSlot := keccak256(0x0c, 0x20)
     * ```
     */
    uint256 internal constant _GENERATION_HASH_HASHES_SLOT_SEED = 0x4f6d0b0a;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        INITIALIZER                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Initialize the auction house and base contracts,
     * populate configuration values, and pause the contract.
     */
    function initialize(
        address bonklers,
        uint96 reservePrice,
        uint96 bidIncrement,
        uint32 duration,
        uint32 timeBuffer,
        uint8 reservePercentage
    ) external payable {
        require(bonklers != address(0), "Bonklers must not be the zero address.");
        require(_auctionData.bonklers == address(0), "Already initialized.");

        _checkReservePercentage(reservePercentage);
        _checkReservePrice(reservePrice);
        _checkBidIncrement(bidIncrement);
        _checkDuration(duration);

        _auctionData.bonklers = bonklers;

        _auctionData.reservePrice = reservePrice;
        _auctionData.bidIncrement = bidIncrement;

        _auctionData.duration = duration;
        _auctionData.timeBuffer = timeBuffer;

        _auctionData.reservePercentage = reservePercentage;

        _initializeOwner(msg.sender);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              PUBLIC / EXTERNAL VIEW FUNCTIONS              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Returns all the public data on the auction.
     */
    function auctionData() external view returns (AuctionData memory) {
        return _auctionData;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              PUBLIC / EXTERNAL WRITE FUNCTIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Create a bid for a Bonkler, with a given amount.
     * This contract only accepts payment in ETH.
     */
    function createBid(uint256 generationHash) external payable {
        // To prevent gas under-estimation.
        require(gasleft() > 150000);

        // Logic for auto-settlement and auto-creation of auctions.
        bool creationFailed;
        if (_auctionData.startTime == 0) { 
            // If the first auction has not been created,
            // try to create a new auction.
            creationFailed = !_createAuction(generationHash);
        } else if (block.timestamp >= _auctionData.endTime) { 
            // Otherwise, if the current auction has ended...
            if (_auctionData.settled) {
                // ... and if the auction is settled, try to create a new auction.
                creationFailed = !_createAuction(generationHash);
            } else {
                // Otherwise... the auction has not yet been settled, 
                // and we have to settle it.
                _settleAuction();
                // After settling the auction, try to create a new auction.
                if (!_createAuction(generationHash)) {
                    // If the creation fails,, it means
                    // we have ran out of generation hashes. 
                    // In this case, we must refund all the ETH sent in this transaction,
                    // because we are not creating any bids.
                    SafeTransferLib.forceSafeTransferETH(msg.sender, msg.value);
                    return;
                }
            }
        }
        // If the auction creation fails, we must revert to prevent any bids.
        require(!creationFailed, "Cannot create auction.");

        // Bidding logic.
        unchecked {
            address lastBidder = _auctionData.bidder;
            uint256 amount = _auctionData.amount;
            uint256 endTime = _auctionData.endTime;
            uint256 bonklerId = _auctionData.bonklerId;

            if (amount == 0) {
                require(msg.value >= _auctionData.reservePrice, "Bid below reserve price.");
            } else {
                require(msg.value >= amount + _auctionData.bidIncrement, "Bid too low.");
            }

            _auctionData.bidder = msg.sender;
            _auctionData.amount = uint96(msg.value);

            // Extend the auction if the bid was received within `timeBuffer` of the auction end time.
            uint256 extendedTime = block.timestamp + _auctionData.timeBuffer;
            // Because we have previously settled and re-created the auction if
            // `timestamp >= endTime`, the only way for `extended` to be true
            // is for `int(endTime) - int(timeBuffer) < int(block.timestamp)`.
            bool extended = endTime < extendedTime;
            emit AuctionBid(bonklerId, msg.sender, msg.value, extended);

            if (extended) {
                _auctionData.endTime = uint40(extendedTime);
                emit AuctionExtended(bonklerId, extendedTime);
            }
            
            if (amount != 0) {
                // Refund the last bidder.
                SafeTransferLib.forceSafeTransferETH(lastBidder, amount);
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   ADMIN WRITE FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Appends an array of generation hashes.
     */
    function addGenerationHashHashes(uint256[] calldata values) external onlyOwner {
        unchecked {
            uint256 n = values.length;
            uint256 o = _auctionData.generationHashesLength;
            for (uint256 i; i != n; ++i) {
                _setGenerationHashHash(o++, values[i]);
            }
            _auctionData.generationHashesLength = uint24(o);
        }
    }

    /**
     * @dev Update the generation hashes.
     * Each index in `indices` must be less than `generationHashesLength`.
     */
    function setGenerationHashHashes(uint256[] calldata indices, uint256[] calldata values)
        external
       
        onlyOwner
    {
        unchecked {
            uint256 n = values.length;
            require(indices.length == n, "Array lengths mismatch.");
            uint256 o = _auctionData.generationHashesLength;
            for (uint256 i; i != n; ++i) {
                uint256 j = indices[i];
                require(j < o, "Array out of bounds access.");
                _setGenerationHashHash(j, values[i]);
            }
        }
    }

    /**
     * @dev Settles the auction.
     */
    function settleAuction() external onlyOwner {
        require(block.timestamp >= _auctionData.endTime, "Auction still ongoing.");
        require(_auctionData.startTime != 0, "No auction.");
        require(_auctionData.bidder != address(0), "No bids.");
        _settleAuction();
    }

    /**
     * @dev Set the auction reserve price.
     */
    function setReservePrice(uint96 reservePrice) external onlyOwner {
        _checkReservePrice(reservePrice);
        _auctionData.reservePrice = reservePrice;
        emit AuctionReservePriceUpdated(reservePrice);
    }

    /**
     * @dev Set the auction bid increment.
     */
    function setBidIncrement(uint96 bidIncrement) external onlyOwner {
        _checkBidIncrement(bidIncrement);
        _auctionData.bidIncrement = bidIncrement;
        emit AuctionBidIncrementUpdated(bidIncrement);
    }

    /**
     * @dev Set the auction time duration.
     */
    function setDuration(uint32 duration) external onlyOwner {
        _checkDuration(duration);
        _auctionData.duration = duration;
        emit AuctionDurationUpdated(duration);
    }

    /**
     * @dev Set the auction time buffer.
     */
    function setTimeBuffer(uint32 timeBuffer) external onlyOwner {
        _auctionData.timeBuffer = timeBuffer;
        emit AuctionTimeBufferUpdated(timeBuffer);
    }

    /**
     * @dev Set the reserve percentage
     * (the percentage of the max bid that is stored in the Bonkler).
     */
    function setReservePercentage(uint8 reservePercentage) external onlyOwner {
        _checkReservePercentage(reservePercentage);
        _auctionData.reservePercentage = reservePercentage;
        emit AuctionReservePriceUpdated(reservePercentage);
    }

    /**
     * @dev Withdraws all the ETH in the contract.
     */
    function withdrawETH() external onlyOwner {
        uint256 amount = _auctionData.withdrawable;
        _auctionData.withdrawable = 0;
        SafeTransferLib.forceSafeTransferETH(msg.sender, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 INTERNAL / PRIVATE HELPERS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Create an auction.
     * Stores the auction details in the `auction` state variable
     * and emits an `AuctionCreated` event.
     * Returns whether the auction has been created successfully.
     */
    function _createAuction(uint256 generationHash) internal returns (bool) {
        unchecked {
            // This is the index into the `generationHashHashes`.
            // If there is no auction, its value is 0.
            // Otherwise, its value is the next `bonklerId`.
            uint256 hashIndex = _auctionData.startTime == 0 ? 0 : _auctionData.bonklerId + 1;
            // If we have used up all the `generationHashHashes`,
            // we cannot create a new auction.
            if (hashIndex >= _auctionData.generationHashesLength) return false;

            address bonklers = _auctionData.bonklers;
            uint256 bonklerId;
            bool generationHashValid;

            assembly {
                mstore(0x0c, _GENERATION_HASH_HASHES_SLOT_SEED)
                mstore(0x00, hashIndex)
                let generationHashHashSlot := keccak256(0x0c, 0x20)

                // The following assembly is equivalent to checking:
                // `keccak256(abi.encode(generationHash)) == generationHashHashes[hashIndex]`.
                mstore(0x00, generationHash)
                generationHashValid := eq(keccak256(0x00, 0x20), sload(generationHashHashSlot))

                // To get some gas refund, since the value will only be used once.
                // Equivalent to: `generationHashHashes[hashIndex] = 0`.
                sstore(generationHashHashSlot, 0)
            }
            require(generationHashValid, "Generation hash is invalid.");

            // The following assembly is equivalent to calling `mint(generationHash)`
            // on the `bonklers` contract.
            assembly {
                // Store the function signature: `bytes4(keccak256("mint(uint256)"))`.
                mstore(0x00, 0xa0712d68)
                mstore(0x20, generationHash)
                // Make a call to `mint` and revert if it is somehow not successful.
                if iszero(
                    and(
                        eq(0x20, returndatasize()),
                        call(
                            gas(), // Remaining gas.
                            bonklers, // The bonklers contract.
                            0, // Zero ETH to send.
                            0x1c, // Start of calldata.
                            0x24, // Length of calldata.
                            0x00, // Start of returndata.
                            0x20 // Length of returndata.
                        )    
                    )
                ) { revert(0, 0) }
                // Load the minted bonklerId from the returndata in memory.
                bonklerId := mload(0x00)
            }

            uint256 endTime = block.timestamp + _auctionData.duration;

            _auctionData.bidder = address(1);
            _auctionData.amount = 0;
            _auctionData.startTime = uint40(block.timestamp);
            _auctionData.endTime = uint40(endTime);
            _auctionData.bonklerId = uint24(bonklerId);
            _auctionData.settled = false;

            emit AuctionCreated(bonklerId, block.timestamp, endTime);

            return true;
        }
    }

    /**
     * @dev Settle an auction, finalizing the bid.
     */
    function _settleAuction() internal {
        address bidder = _auctionData.bidder;
        uint256 amount = _auctionData.amount;
        uint256 withdrawable = _auctionData.withdrawable;
        uint256 bonklerId = _auctionData.bonklerId;
        uint256 reservePercentage = _auctionData.reservePercentage;
        address bonklers = _auctionData.bonklers;

        // The following assembly is equivalent to calling
        // `transferPurchasedBonkler(bonklerId, to)`
        // on the `bonklers` contract.
        assembly {
            let bonklerShares := div(mul(amount, reservePercentage), 100)
            withdrawable := add(withdrawable, sub(amount, bonklerShares))

            // Store the function signature:
            // `bytes4(keccak256("transferPurchasedBonkler(uint256,address)"))`,
            // shifted left by 6 bytes, which is enough for 8tb of memory.
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0x9229407d000000000000)
            mstore(0x1a, bonklerId)
            mstore(0x3a, bidder)
            if iszero(
                call(
                    gas(), // Remaining gas.
                    bonklers, // The bonklers contract.
                    bonklerShares, // ETH to send.
                    0x16, // Start of calldata.
                    0x44, // Length of calldata.
                    0x00, // Start of returndata.
                    0x00 // Length of returndata.
                )
            ) { revert(0, 0) }

            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }

        _auctionData.settled = true;
        _auctionData.withdrawable = uint96(withdrawable);

        emit AuctionSettled(bonklerId, bidder, amount);
    }

    /**
     * @dev Sets the `generationHashHash` for `bonklerId`.
     */
    function _setGenerationHashHash(uint256 bonklerId, uint256 generationHashHash) internal {
        assembly {
            mstore(0x0c, _GENERATION_HASH_HASHES_SLOT_SEED)
            mstore(0x00, bonklerId)
            sstore(keccak256(0x0c, 0x20), generationHashHash)
        }
    }

    /**
     * @dev Returns the `generationHashHash` for `bonklerId`.
     */
    function _getGenerationHashHash(uint256 bonklerId) internal view returns (uint256 generationHashHash) {
        assembly {
            mstore(0x0c, _GENERATION_HASH_HASHES_SLOT_SEED)
            mstore(0x00, bonklerId)
            generationHashHash := sload(keccak256(0x0c, 0x20))
        }
    }

    /**
     * @dev Checks whether `reservePercentage` is within 1..100 (inclusive).
     */
    function _checkReservePercentage(uint8 reservePercentage) internal pure {
        require(reservePercentage < 101, "Reserve percentage exceeds 100.");
    }

    /**
     * @dev Checks whether `reservePrice` is greater than 0.
     */
    function _checkReservePrice(uint96 reservePrice) internal pure {
        require(reservePrice != 0, "Reserve price must be greater than 0.");
    }

    /**
     * @dev Checks whether `bidIncrement` is greater than 0.
     */
    function _checkBidIncrement(uint96 bidIncrement) internal pure {
        require(bidIncrement != 0, "Bid increment must be greater than 0.");
    }

    /**
     * @dev Checks whether `bidIncrement` is greater than 0.
     */
    function _checkDuration(uint32 duration) internal pure {
        require(duration != 0, "Duration must be greater than 0.");
    }

}