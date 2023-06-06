// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../libraries/BytesLib.sol";

import {IWormhole} from "../interfaces/IWormhole.sol";

import "./CircleRelayerGovernance.sol";
import "./CircleRelayerMessages.sol";

/**
 * @title Circle Bridge Asset Relayer
 * @notice This contract composes on Wormhole's Circle Integration contracts to faciliate
 * one-click transfers of Circle Bridge supported assets cross chain.
 */
contract CircleRelayer is CircleRelayerMessages, CircleRelayerGovernance, ReentrancyGuard {
    using BytesLib for bytes;

    /**
     * @notice Emitted when a swap is executed with an off-chain relayer
     * @param recipient Address of the recipient of the native assets
     * @param relayer Address of the relayer that performed the swap
     * @param token Address of the token being swapped
     * @param tokenAmount Amount of token being swapped
     * @param nativeAmount Amount of native assets swapped for tokens
     */
    event SwapExecuted(
        address indexed recipient,
        address indexed relayer,
        address indexed token,
        uint256 tokenAmount,
        uint256 nativeAmount
    );

    constructor(
        address circleIntegration_,
        uint8 nativeTokenDecimals_
    ) {
        require(circleIntegration_ != address(0), "invalid circle integration address");
        require(nativeTokenDecimals_ > 0, "invalid native decimals");

        // configure state
        setOwner(msg.sender);
        setCircleIntegration(circleIntegration_);
        setNativeTokenDecimals(nativeTokenDecimals_);

        // set wormhole and chainId by querying the integration contract state
        ICircleIntegration integration = circleIntegration();
        setChainId(integration.chainId());
        setWormhole(address(integration.wormhole()));

        // set initial swap rate precision to 1e8
        setNativeSwapRatePrecision(1e8);
    }

    /**
     * @notice Calls Wormhole's Circle Integration contract to burn user specified tokens.
     * It emits a Wormhole message with instructions for how to handle relayer payments
     * on the target contract and the quantity of tokens to convert into native assets
     * for the user.
     * @param token Address of the Circle Bridge asset to be transferred.
     * @param amount Quantity of tokens to be transferred.
     * @param toNativeTokenAmount Amount of tokens to swap into native assets on
     * the target chain.
     * @param targetChain Wormhole chain ID of the target blockchain.
     * @param targetRecipientWallet User's wallet address on the target blockchain.
     * @return messageSequence Wormhole sequence for emitted TransferTokensWithRelay message.
     */
    function transferTokensWithRelay(
        IERC20Metadata token,
        uint256 amount,
        uint256 toNativeTokenAmount,
        uint16 targetChain,
        bytes32 targetRecipientWallet
    ) public payable nonReentrant notPaused returns (uint64 messageSequence) {
        // sanity check input values
        require(amount > 0, "amount must be > 0");
        require(targetRecipientWallet != bytes32(0), "invalid target recipient");
        require(address(token) != address(0), "token cannot equal address(0)");

        // cache the target contract address
        bytes32 targetContract = getRegisteredContract(targetChain);
        require(
            targetContract != bytes32(0),
            "CIRCLE-RELAYER: target not registered"
        );

        // transfer the tokens to this contract
        uint256 amountReceived = custodyTokens(token, amount);
        uint256 targetRelayerFee = relayerFee(targetChain, address(token));
        require(
            amountReceived > targetRelayerFee + toNativeTokenAmount,
            "insufficient amountReceived"
        );

        // Construct additional instructions to tell the receiving contract
        // how to handle the token redemption.
        TransferTokensWithRelay memory transferMessage = TransferTokensWithRelay({
            payloadId: 1,
            targetRelayerFee: targetRelayerFee,
            toNativeTokenAmount: toNativeTokenAmount,
            targetRecipientWallet: targetRecipientWallet
        });

        // cache circle integration instance
        ICircleIntegration integration = circleIntegration();

        // approve the circle integration contract to spend tokens
        SafeERC20.safeApprove(
            token,
            address(integration),
            amountReceived
        );

        // transfer the tokens with instructions via the circle integration contract
        messageSequence = integration.transferTokensWithPayload(
            ICircleIntegration.TransferParameters({
                token: address(token),
                amount: amount,
                targetChain: targetChain,
                mintRecipient: targetContract
            }),
            0, // batchId = 0 to opt out of batching
            encodeTransferTokensWithRelay(transferMessage)
        );
    }

    /**
     * @notice Calls Wormhole's Circle Integration contract to complete the token transfer. Takes
     * custody of the minted tokens and sends the tokens to the target recipient.
     * It pays the relayer in the minted token denomination. If requested by the user,
     * it will perform a swap with the off-chain relayer to provide the user with native assets.
     * @param redeemParams Struct containing an attested Wormhole message, Circle Bridge message,
     * and Circle transfer attestation.
     */
    function redeemTokens(
        ICircleIntegration.RedeemParameters calldata redeemParams
    ) public payable {
        // cache circle integration instance
        ICircleIntegration integration = circleIntegration();

        /**
         * Mint tokens to this contract. Serves as a reentrancy protection,
         * since the circle integration contract will not allow the wormhole
         * message in the redeemParams to be replayed.
         */
        ICircleIntegration.DepositWithPayload memory deposit =
            integration.redeemTokensWithPayload(redeemParams);

        // parse the additional instructions from the deposit message
        TransferTokensWithRelay memory transferMessage = decodeTransferTokensWithRelay(
            deposit.payload
        );

        // verify that the sender is a registered contract
        require(
            deposit.fromAddress == getRegisteredContract(
                integration.getChainIdFromDomain(deposit.sourceDomain)
            ),
            "fromAddress is not a registered contract"
        );

        // cache the token and recipient addresses
        IERC20Metadata token = IERC20Metadata(bytes32ToAddress(deposit.token));
        address recipient = bytes32ToAddress(transferMessage.targetRecipientWallet);

        // If the recipient is self redeeming, send the full token amount to
        // the recipient. Revert if they attempt to send ether to this contract.
        if (msg.sender == recipient) {
            require(msg.value == 0, "recipient cannot swap native assets");

            // transfer the full token amount to the recipient
            SafeERC20.safeTransfer(
                token,
                recipient,
                deposit.amount
            );

            // bail out
            return;
        }

        // handle native asset payments and refunds
        if (transferMessage.toNativeTokenAmount > 0) {
            /**
             * Compute the maximum amount of tokens that the user is allowed
             * to swap for native assets. Override the toNativeTokenAmount in
             * the transferMessage if the toNativeTokenAmount is greater than
             * the maxToNativeAllowed.
             */
            uint256 maxToNativeAllowed = calculateMaxSwapAmountIn(token);
            if (transferMessage.toNativeTokenAmount > maxToNativeAllowed) {
                transferMessage.toNativeTokenAmount = maxToNativeAllowed;
            }

            // compute amount of native asset to pay the recipient
            uint256 nativeAmountForRecipient = calculateNativeSwapAmountOut(
                token,
                transferMessage.toNativeTokenAmount
            );

            /**
             * The nativeAmountForRecipient can be zero if the user specifed a
             * toNativeTokenAmount that is too little to convert to native asset.
             * We need to override the toNativeTokenAmount to be zero if that is
             * the case, that way the user receives the full amount of minted USDC.
             */
            if (nativeAmountForRecipient > 0) {
                // check to see if the relayer sent enough value
                require(
                    msg.value >= nativeAmountForRecipient,
                    "insufficient native asset amount"
                );

                // refund excess native asset to relayer if applicable
                uint256 relayerRefund = msg.value - nativeAmountForRecipient;
                if (relayerRefund > 0) {
                    payable(msg.sender).transfer(relayerRefund);
                }

                // send requested native asset to target recipient
                payable(recipient).transfer(nativeAmountForRecipient);

                // emit swap event
                emit SwapExecuted(
                    recipient,
                    msg.sender,
                    address(token),
                    transferMessage.toNativeTokenAmount,
                    nativeAmountForRecipient
                );
            } else {
                // override the toNativeTokenAmount in the transferMessage
                transferMessage.toNativeTokenAmount = 0;

                // refund the relayer any native asset sent to this contract
                if (msg.value > 0) {
                    payable(msg.sender).transfer(msg.value);
                }
            }
        }

        // add the token swap amount to the relayer fee
        uint256 amountForRelayer =
            transferMessage.targetRelayerFee + transferMessage.toNativeTokenAmount;

        // pay the relayer if relayerFee > 0 and the caller is not the recipient
        if (amountForRelayer > 0) {
            SafeERC20.safeTransfer(
                IERC20Metadata(token),
                msg.sender,
                amountForRelayer
            );
        }

        // pay the target recipient the remaining minted tokens
        SafeERC20.safeTransfer(
            IERC20Metadata(token),
            recipient,
            deposit.amount - amountForRelayer
        );
    }

    /**
     * @notice Calculates the max amount of tokens the user can convert to
     * native assets on this chain.
     * @dev The max amount of native assets the contract will swap with the user
     * is governed by the `maxNativeSwapAmount` state variable.
     * @param token Address of token being transferred.
     * @return maxAllowed The maximum number of tokens the user is allowed to
     * swap for native assets.
     */
    function calculateMaxSwapAmountIn(
        IERC20Metadata token
    ) public view returns (uint256 maxAllowed) {
        // cache swap rate
        uint256 swapRate = nativeSwapRate(address(token));
        require(swapRate > 0, "swap rate not set");

        // cache token decimals
        uint8 tokenDecimals = token.decimals();
        uint8 nativeDecimals = nativeTokenDecimals();

        if (tokenDecimals > nativeDecimals) {
            maxAllowed =
                maxNativeSwapAmount(address(token)) * swapRate *
                10 ** (tokenDecimals - nativeDecimals) / nativeSwapRatePrecision();
        } else {
            maxAllowed =
                (maxNativeSwapAmount(address(token)) * swapRate) /
                (10 ** (nativeDecimals - tokenDecimals) * nativeSwapRatePrecision());
        }
    }

    /**
     * @notice Calculates the amount of native assets that a user will receive
     * when swapping transferred tokens for native assets.
     * @dev The swap rate is governed by the `nativeSwapRate` state variable.
     * @param token Address of token being transferred.
     * @param toNativeAmount Quantity of tokens to be converted to native assets.
     * @return nativeAmount The amount of native tokens that a user receives.
     */
    function calculateNativeSwapAmountOut(
        IERC20Metadata token,
        uint256 toNativeAmount
    ) public view returns (uint256 nativeAmount) {
        // cache swap rate
        uint256 swapRate = nativeSwapRate(address(token));
        require(swapRate > 0, "swap rate not set");

        // cache token decimals
        uint8 tokenDecimals = token.decimals();
        uint8 nativeDecimals = nativeTokenDecimals();

        if (tokenDecimals > nativeDecimals) {
            nativeAmount =
                nativeSwapRatePrecision() * toNativeAmount /
                (swapRate * 10 ** (tokenDecimals - nativeDecimals));
        } else {
            nativeAmount =
                nativeSwapRatePrecision() * toNativeAmount *
                10 ** (nativeDecimals - tokenDecimals) / swapRate;
        }
    }

    function custodyTokens(IERC20Metadata token, uint256 amount) internal returns (uint256) {
        // query own token balance before transfer
        uint256 balanceBefore = token.balanceOf(address(this));

        // deposit USDC
        SafeERC20.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            amount
        );

        // query own token balance after transfer
        uint256 balanceAfter = token.balanceOf(address(this));

        // this check is necessary since Circle's token contracts are upgradeable
        return balanceAfter - balanceBefore;
    }

    function bytes32ToAddress(bytes32 address_) public pure returns (address) {
        return address(uint160(uint256(address_)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface IWormhole {
    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;

        uint32 guardianSetIndex;
        Signature[] signatures;

        bytes32 hash;
    }

    struct ContractUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        address newContract;
    }

    struct GuardianSetUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        GuardianSet newGuardianSet;
        uint32 newGuardianSetIndex;
    }

    struct SetMessageFee {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 messageFee;
    }

    struct TransferFees {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 amount;
        bytes32 recipient;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;

        uint256 evmChainId;
        uint16 newChainId;
    }

    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);
    event ContractUpgraded(address indexed oldContract, address indexed newContract);
    event GuardianSetAdded(uint32 indexed index);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function initialize() external;

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (VM memory vm, bool valid, string memory reason);

    function verifyVM(VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Signature[] memory signatures, GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason);

    function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);

    function quorum(uint numGuardians) external pure returns (uint numSignaturesRequiredForQuorum);

    function getGuardianSet(uint32 index) external view returns (GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);

    function evmChainId() external view returns (uint256);

    function nextSequence(address emitter) external view returns (uint64);

    function parseContractUpgrade(bytes memory encodedUpgrade) external pure returns (ContractUpgrade memory cu);

    function parseGuardianSetUpgrade(bytes memory encodedUpgrade) external pure returns (GuardianSetUpgrade memory gsu);

    function parseSetMessageFee(bytes memory encodedSetMessageFee) external pure returns (SetMessageFee memory smf);

    function parseTransferFees(bytes memory encodedTransferFees) external pure returns (TransferFees memory tf);

    function parseRecoverChainId(bytes memory encodedRecoverChainId) external pure returns (RecoverChainId memory rci);

    function submitContractUpgrade(bytes memory _vm) external;

    function submitSetMessageFee(bytes memory _vm) external;

    function submitNewGuardianSet(bytes memory _vm) external;

    function submitTransferFees(bytes memory _vm) external;

    function submitRecoverChainId(bytes memory _vm) external;
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

import "./CircleRelayerSetters.sol";
import "./CircleRelayerGetters.sol";
import "./CircleRelayerState.sol";

contract CircleRelayerGovernance is CircleRelayerGetters, ERC1967Upgrade {
    event OwnershipTransfered(address indexed oldOwner, address indexed newOwner);
    event SwapRateUpdated(address indexed token, uint256 indexed swapRate);

    /**
     * @notice Starts the ownership transfer process of the contracts. It saves
     * an address in the pending owner state variable.
     * @param chainId_ Wormhole chain ID
     * @param newOwner Address of the pending owner
     */
    function submitOwnershipTransferRequest(
        uint16 chainId_,
        address newOwner
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(newOwner != address(0), "newOwner cannot equal address(0)");

        setPendingOwner(newOwner);
    }

    /**
     * @notice Cancels the ownership transfer process.
     * @dev Sets the pending owner state variable to the zero address.
     */
    function cancelOwnershipTransferRequest(
        uint16 chainId_
    ) public onlyOwner onlyCurrentChain(chainId_) {
        setPendingOwner(address(0));
    }

    /**
     * @notice Finalizes the ownership transfer to the pending owner
     * @dev It checks that the caller is the pendingOwner to validate the wallet
     * address. It updates the owner state variable with the pendingOwner state
     * variable.
     */
    function confirmOwnershipTransferRequest() public {
        // cache the new owner address
        address newOwner = pendingOwner();

        require(msg.sender == newOwner, "caller must be pendingOwner");

        // cache currentOwner for Event
        address currentOwner = owner();

        // update the owner in the contract state and reset the pending owner
        setOwner(newOwner);
        setPendingOwner(address(0));

        emit OwnershipTransfered(currentOwner, newOwner);
    }

    /**
     * @notice Registers foreign Circle Relayer contracts
     * @param chainId_ Wormhole chain ID of the foreign contract
     * @param contractAddress Address of the foreign contract in bytes32 format
     * (zero-left-padded address).
     */
    function registerContract(
        uint16 chainId_,
        bytes32 contractAddress
    ) public onlyOwner {
        // sanity check both input arguments
        require(
            contractAddress != bytes32(0),
            "contractAddress cannot equal bytes32(0)"
        );
        require(
            chainId_ != 0 && chainId_ != chainId(),
            "chainId_ cannot equal 0 or this chainId"
        );

        // update the registeredContracts state variable
        _registerContract(chainId_, contractAddress);
    }

    /**
     * @notice Update the fee for relaying transfers to foreign contracts
     * @dev This function can update the source contract's record of the relayer
     * fee.
     * @param chainId_ Wormhole chain ID
     * @param token Address of the token to update the relayer fee for
     * @param amount Quantity of tokens to pay the relayer upon redemption
     */
    function updateRelayerFee(
        uint16 chainId_,
        address token,
        uint256 amount
    ) public onlyOwner {
        require(chainId_ != chainId(), "invalid chain");
        require(
            getRegisteredContract(chainId_) != bytes32(0),
            "contract doesn't exist"
        );
        require(
            circleIntegration().isAcceptedToken(token),
            "token not accepted"
        );
        setRelayerFee(chainId_, token, amount);
    }

    /**
     * @notice Updates the conversion rate between the native asset of this chain
     * and the specified token.
     * @param chainId_ Wormhole chain ID
     * @param token Address of the token to update the conversion rate for
     * @param swapRate The native -> token conversion rate.
     * @dev The swapRate is the conversion rate using asset prices denominated in
     * USD multiplied by the nativeSwapRatePrecision. For example, if the conversion
     * rate is $15 and the nativeSwapRatePrecision is 1000000, the swapRate should be set
     * to 15000000.
     */
    function updateNativeSwapRate(
        uint16 chainId_,
        address token,
        uint256 swapRate
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(circleIntegration().isAcceptedToken(token), "token not accepted");
        require(swapRate > 0, "swap rate must be nonzero");

        setNativeSwapRate(token, swapRate);

        emit SwapRateUpdated(token, swapRate);
    }

    /**
     * @notice Updates the precision of the native swap rate
     * @param chainId_ Wormhole chain ID
     * @param nativeSwapRatePrecision_ Precision of native swap rate
     */
    function updateNativeSwapRatePrecision(
        uint16 chainId_,
        uint256 nativeSwapRatePrecision_
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(nativeSwapRatePrecision_ > 0, "precision must be > 0");

        setNativeSwapRatePrecision(nativeSwapRatePrecision_);
    }

    /**
     * @notice Updates the max amount of native assets the contract will pay
     * to the target recipient.
     * @param chainId_ Wormhole chain ID
     * @param token Address of the token to update the max native swap amount for
     * @param maxAmount Max amount of native assets
     */
    function updateMaxNativeSwapAmount(
        uint16 chainId_,
        address token,
        uint256 maxAmount
    ) public onlyOwner onlyCurrentChain(chainId_) {
        require(circleIntegration().isAcceptedToken(token), "token not accepted");

        setMaxNativeSwapAmount(token, maxAmount);
    }

    /**
     * @notice Sets the pause state of the relayer. If paused, token transfer requests are blocked.
     * In flight transfers, i.e. those that have a VAA emitted, can still be processed if paused.
     * @param chainId_ Wormhole chain ID
     * @param paused If true, requests for token transfers will be blocked and no circle transfer VAAs will be generated.
     */
    function setPauseForTransfers(
        uint16 chainId_,
        bool paused
    ) public onlyOwner onlyCurrentChain(chainId_) {
        setPaused(paused);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "caller not the owner");
        _;
    }

    modifier onlyCurrentChain(uint16 chainId_) {
        require(chainId() == chainId_, "wrong chain");
        _;
    }

    modifier notPaused() {
        require(!getPaused(), "relayer is paused");
        _;
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import "../libraries/BytesLib.sol";

import "./CircleRelayerStructs.sol";

contract CircleRelayerMessages is CircleRelayerStructs {
    using BytesLib for bytes;

    /**
     * @notice Serializes the `TransferTokensWithRelay` struct
     * @param transfer `TransferTokensWithRelay` struct
     * @return encoded Serialized `TransferTokensWithRelay` struct
     */
    function encodeTransferTokensWithRelay(
        TransferTokensWithRelay memory transfer
    ) public pure returns (bytes memory encoded) {
        require(transfer.payloadId == 1, "invalid payloadId");
        encoded = abi.encodePacked(
            transfer.payloadId,
            transfer.targetRelayerFee,
            transfer.toNativeTokenAmount,
            transfer.targetRecipientWallet
        );
    }

    /**
     * @notice Decodes an encoded `TransferTokensWithRelay` struct
     * @dev reverts if:
     * - the first byte (payloadId) does not equal 1
     * - the length of the payload has an unexpected length
     * @param encoded Encoded `TransferTokensWithRelay` struct
     * @return transfer `TransferTokensWithRelay` struct
     */
    function decodeTransferTokensWithRelay(
        bytes memory encoded
    ) public pure returns (TransferTokensWithRelay memory transfer) {
        uint256 index = 0;

        // parse the payloadId
        transfer.payloadId = encoded.toUint8(index);
        index += 1;

        require(transfer.payloadId == 1, "CIRCLE_RELAYER: invalid message payloadId");

        // target relayer fee
        transfer.targetRelayerFee = encoded.toUint256(index);
        index += 32;

        // amount of tokens to convert to native assets
        transfer.toNativeTokenAmount = encoded.toUint256(index);
        index += 32;

        // recipient of the transfered tokens and native assets
        transfer.targetRecipientWallet = encoded.toBytes32(index);
        index += 32;

        require(index == encoded.length, "CIRCLE_RELAYER: invalid message length");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import "./CircleRelayerState.sol";

contract CircleRelayerSetters is CircleRelayerState {
    function setOwner(address owner_) internal {
        _state.owner = owner_;
    }

    function setPendingOwner(address pendingOwner_) internal {
        _state.pendingOwner = pendingOwner_;
    }

    function setPaused(bool paused) internal {
        _state.paused = paused;
    }

    function setWormhole(address wormhole_) internal {
        _state.wormhole = payable(wormhole_);
    }

    function setChainId(uint16 chainId_) internal {
        _state.chainId = chainId_;
    }

    function setNativeTokenDecimals(uint8 decimals_) internal {
        _state.nativeTokenDecimals = decimals_;
    }

    function setCircleIntegration(address circleIntegration_) internal {
        _state.circleIntegration = circleIntegration_;
    }

    function setRelayerFee(uint16 chainId_, address token, uint256 fee) internal {
        _state.relayerFees[chainId_][token] = fee;
    }

    function setNativeSwapRatePrecision(uint256 precision) internal {
        _state.nativeSwapRatePrecision = precision;
    }

    function setNativeSwapRate(address token, uint256 swapRate) internal {
        _state.nativeSwapRates[token] = swapRate;
    }

    function setMaxNativeSwapAmount(address token, uint256 maximum) internal {
        _state.maxNativeSwapAmount[token] = maximum;
    }

    function _registerContract(uint16 chainId_, bytes32 contract_) internal {
        _state.registeredContracts[chainId_] = contract_;
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import {IWormhole} from "../interfaces/IWormhole.sol";
import {ICircleIntegration} from "../interfaces/ICircleIntegration.sol";

import "./CircleRelayerSetters.sol";

contract CircleRelayerGetters is CircleRelayerSetters {
    function owner() public view returns (address) {
        return _state.owner;
    }

    function pendingOwner() public view returns (address) {
        return _state.pendingOwner;
    }

    function wormhole() public view returns (IWormhole) {
        return IWormhole(_state.wormhole);
    }

    /**
     * @return paused If true, requests for token transfers will be blocked and no circle transfer VAAs will be generated.
     */
    function getPaused() public view returns (bool paused) {
        paused = _state.paused;
    }

    function chainId() public view returns (uint16) {
        return _state.chainId;
    }

    function nativeTokenDecimals() public view returns (uint8) {
        return _state.nativeTokenDecimals;
    }

    function circleIntegration() public view returns (ICircleIntegration) {
        return ICircleIntegration(_state.circleIntegration);
    }

    function relayerFee(uint16 chainId_, address token) public view returns (uint256) {
        return _state.relayerFees[chainId_][token];
    }

    function nativeSwapRatePrecision() public view returns (uint256) {
        return _state.nativeSwapRatePrecision;
    }

    function nativeSwapRate(address token) public view returns (uint256) {
        return _state.nativeSwapRates[token];
    }

    function maxNativeSwapAmount(address token) public view returns (uint256) {
        return _state.maxNativeSwapAmount[token];
    }

    function getRegisteredContract(uint16 emitterChainId) public view returns (bytes32) {
        return _state.registeredContracts[emitterChainId];
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import {IWormhole} from "../interfaces/IWormhole.sol";

contract CircleRelayerStorage {
    struct State {
        // Wormhole chain ID of this contract
        uint16 chainId;

        // decimals of the native token on this chain
        uint8 nativeTokenDecimals;

        // If true, token transfer requests are blocked.
        bool paused;

        // owner of this contract
        address owner;

        // intermediate state when transfering contract ownership
        address pendingOwner;

        // address of the Wormhole contract on this chain
        address wormhole;

        // address of the trusted Circle Integration contract on this chain
        address circleIntegration;

        // precision of the nativeSwapRates, this value should NEVER be set to zero
        uint256 nativeSwapRatePrecision;

        // mapping of chainId to source token address to relayerFee
        mapping(uint16 => mapping(address => uint256)) relayerFees;

        /**
         * Mapping of source token address to native asset swap rate
         * (nativePriceUSD/tokenPriceUSD).
         */
        mapping(address => uint256) nativeSwapRates;

        /**
         * Mapping of source token address to maximum native asset swap amount
         * allowed.
         */
        mapping(address => uint256) maxNativeSwapAmount;

        // Wormhole chain ID to registered contract address mapping
        mapping(uint16 => bytes32) registeredContracts;
    }
}

contract CircleRelayerState {
    CircleRelayerStorage.State _state;
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

contract CircleRelayerStructs {
    struct TransferTokensWithRelay {
        uint8 payloadId; // == 1
        uint256 targetRelayerFee;
        uint256 toNativeTokenAmount;
        bytes32 targetRecipientWallet;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.13;

import {IWormhole} from "../interfaces/IWormhole.sol";
import {ICircleBridge} from "../interfaces/ICircleBridge.sol";
import {IMessageTransmitter} from "../interfaces/IMessageTransmitter.sol";

interface ICircleIntegration {
    struct TransferParameters {
        address token;
        uint256 amount;
        uint16 targetChain;
        bytes32 mintRecipient;
    }

    struct RedeemParameters {
        bytes encodedWormholeMessage;
        bytes circleBridgeMessage;
        bytes circleAttestation;
    }

    struct DepositWithPayload {
        bytes32 token;
        uint256 amount;
        uint32 sourceDomain;
        uint32 targetDomain;
        uint64 nonce;
        bytes32 fromAddress;
        bytes32 mintRecipient;
        bytes payload;
    }

    function transferTokensWithPayload(
        TransferParameters memory transferParams,
        uint32 batchId,
        bytes memory payload
    ) external payable returns (uint64 messageSequence);

    function redeemTokensWithPayload(
        RedeemParameters memory params
    ) external returns (DepositWithPayload memory depositWithPayload);

    function fetchLocalTokenAddress(
        uint32 sourceDomain,
        bytes32 sourceToken
    ) external view returns (bytes32);

    function encodeDepositWithPayload(DepositWithPayload memory message) external pure returns (bytes memory);

    function decodeDepositWithPayload(bytes memory encoded) external pure returns (DepositWithPayload memory message);

    function isInitialized(address impl) external view returns (bool);

    function wormhole() external view returns (IWormhole);

    function chainId() external view returns (uint16);

    function wormholeFinality() external view returns (uint8);

    function circleBridge() external view returns (ICircleBridge);

    function circleTransmitter() external view returns (IMessageTransmitter);

    function getRegisteredEmitter(uint16 emitterChainId) external view returns (bytes32);

    function isAcceptedToken(address token) external view returns (bool);

    function getDomainFromChainId(uint16 chainId_) external view returns (uint32);

    function getChainIdFromDomain(uint32 domain) external view returns (uint16);

    function isMessageConsumed(bytes32 hash) external view returns (bool);

    function localDomain() external view returns (uint32);

    function targetAcceptedToken(address sourceToken, uint16 chainId_) external view returns (bytes32);

    function verifyGovernanceMessage(bytes memory encodedMessage, uint8 action)
        external
        view
        returns (bytes32 messageHash, bytes memory payload);

    function evmChain() external view returns (uint256);

    // guardian governance only
    function updateWormholeFinality(bytes memory encodedMessage) external;

    function registerEmitterAndDomain(bytes memory encodedMessage) external;

    function registerAcceptedToken(bytes memory encodedMessage) external;

    function registerTargetChainToken(bytes memory encodedMessage) external;

    function upgradeContract(bytes memory encodedMessage) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IMessageTransmitter} from "./IMessageTransmitter.sol";

interface ICircleBridge {
    event MessageSent(bytes message);

    /**
     * @notice Deposits and burns tokens from sender to be minted on destination domain.
     * Emits a `DepositForBurn` event.
     * @dev reverts if:
     * - given burnToken is not supported
     * - given destinationDomain has no CircleBridge registered
     * - transferFrom() reverts. For example, if sender's burnToken balance or approved allowance
     * to this contract is less than `amount`.
     * - burn() reverts. For example, if `amount` is 0.
     * - MessageTransmitter returns false or reverts.
     * @param _amount amount of tokens to burn
     * @param _destinationDomain destination domain (ETH = 0, AVAX = 1)
     * @param _mintRecipient address of mint recipient on destination domain
     * @param _burnToken address of contract to burn deposited tokens, on local domain
     * @return _nonce unique nonce reserved by message
     */
    function depositForBurn(uint256 _amount, uint32 _destinationDomain, bytes32 _mintRecipient, address _burnToken)
        external
        returns (uint64 _nonce);

    /**
     * @notice Deposits and burns tokens from sender to be minted on destination domain. The mint
     * on the destination domain must be called by `_destinationCaller`.
     * WARNING: if the `_destinationCaller` does not represent a valid address as bytes32, then it will not be possible
     * to broadcast the message on the destination domain. This is an advanced feature, and the standard
     * depositForBurn() should be preferred for use cases where a specific destination caller is not required.
     * Emits a `DepositForBurn` event.
     * @dev reverts if:
     * - given destinationCaller is zero address
     * - given burnToken is not supported
     * - given destinationDomain has no CircleBridge registered
     * - transferFrom() reverts. For example, if sender's burnToken balance or approved allowance
     * to this contract is less than `amount`.
     * - burn() reverts. For example, if `amount` is 0.
     * - MessageTransmitter returns false or reverts.
     * @param _amount amount of tokens to burn
     * @param _destinationDomain destination domain
     * @param _mintRecipient address of mint recipient on destination domain
     * @param _burnToken address of contract to burn deposited tokens, on local domain
     * @param _destinationCaller caller on the destination domain, as bytes32
     * @return _nonce unique nonce reserved by message
     */
    function depositForBurnWithCaller(
        uint256 _amount,
        uint32 _destinationDomain,
        bytes32 _mintRecipient,
        address _burnToken,
        bytes32 _destinationCaller
    ) external returns (uint64 _nonce);

    function owner() external view returns (address);

    function handleReceiveMessage(uint32 _remoteDomain, bytes32 _sender, bytes memory messageBody)
        external
        view
        returns (bool);

    function localMessageTransmitter() external view returns (IMessageTransmitter);

    function remoteCircleBridges(uint32 domain) external view returns (bytes32);

    // owner only methods
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMessageTransmitter {
    /**
     * @notice Emitted when tokens are minted
     * @param _mintRecipient recipient address of minted tokens
     * @param _amount amount of minted tokens
     * @param _mintToken contract address of minted token
     */
    event MintAndWithdraw(address _mintRecipient, uint256 _amount, address _mintToken);

    /**
     * @notice Receive a message. Messages with a given nonce
     * can only be broadcast once for a (sourceDomain, destinationDomain)
     * pair. The message body of a valid message is passed to the
     * specified recipient for further processing.
     *
     * @dev Attestation format:
     * A valid attestation is the concatenated 65-byte signature(s) of exactly
     * `thresholdSignature` signatures, in increasing order of attester address.
     * ***If the attester addresses recovered from signatures are not in
     * increasing order, signature verification will fail.***
     * If incorrect number of signatures or duplicate signatures are supplied,
     * signature verification will fail.
     *
     * Message format:
     * Field Bytes Type Index
     * version 4 uint32 0
     * sourceDomain 4 uint32 4
     * destinationDomain 4 uint32 8
     * nonce 8 uint64 12
     * sender 32 bytes32 20
     * recipient 32 bytes32 52
     * messageBody dynamic bytes 84
     * @param _message Message bytes
     * @param _attestation Concatenated 65-byte signature(s) of `_message`, in increasing order
     * of the attester address recovered from signatures.
     * @return success bool, true if successful
     */
    function receiveMessage(bytes memory _message, bytes calldata _attestation) external returns (bool success);

    function attesterManager() external view returns (address);

    function availableNonces(uint32 domain) external view returns (uint64);

    function getNumEnabledAttesters() external view returns (uint256);

    function isEnabledAttester(address _attester) external view returns (bool);

    function localDomain() external view returns (uint32);

    function maxMessageBodySize() external view returns (uint256);

    function owner() external view returns (address);

    function paused() external view returns (bool);

    function pauser() external view returns (address);

    function rescuer() external view returns (address);

    function version() external view returns (uint32);

    // owner only methods
    function transferOwnership(address newOwner) external;

    function updateAttesterManager(address _newAttesterManager) external;

    // attester manager only methods
    function getEnabledAttester(uint256 _index) external view returns (address);

    function disableAttester(address _attester) external;

    function enableAttester(address _attester) external;

    function setSignatureThreshold(uint256 newSignatureThreshold) external;
}