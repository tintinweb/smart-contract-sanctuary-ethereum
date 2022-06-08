// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {IDefiBridge} from './interfaces/IDefiBridge.sol';
import {AztecTypes} from './AztecTypes.sol';
import {TokenTransfers} from './libraries/TokenTransfers.sol';

contract DefiBridgeProxy {
    error OUTPUT_A_EXCEEDS_252_BITS(uint256 outputValue);
    error OUTPUT_B_EXCEEDS_252_BITS(uint256 outputValue);
    error ASYNC_NONZERO_OUTPUT_VALUES(uint256 outputValueA, uint256 outputValueB);
    error INSUFFICIENT_ETH_PAYMENT();

    /**
     * @dev Use interaction result data to pull tokens into DefiBridgeProxy
     * @param asset The AztecAsset being targetted
     * @param outputValue The claimed output value provided by the bridge
     * @param interactionNonce The defi interaction nonce of the interaction
     * @param bridgeContract Address of the defi bridge contract
     * @param ethPaymentsSlot The slot value of the `ethPayments` storage mapping in RollupProcessor.sol!
     * More details on ethPaymentsSlot are in the comments for the `convert` function
     */
    function recoverTokens(
        AztecTypes.AztecAsset memory asset,
        uint256 outputValue,
        uint256 interactionNonce,
        address bridgeContract,
        uint256 ethPaymentsSlot
    ) internal {
        if (outputValue == 0) {
            return;
        }
        if (asset.assetType == AztecTypes.AztecAssetType.ETH) {
            uint256 ethPayment;
            uint256 ethPaymentsSlotBase;
            assembly {
                mstore(0x00, interactionNonce)
                mstore(0x20, ethPaymentsSlot)
                ethPaymentsSlotBase := keccak256(0x00, 0x40)
                ethPayment := sload(ethPaymentsSlotBase) // ethPayment = ethPayments[interactionNonce]
            }
            if (outputValue > ethPayment) {
                revert INSUFFICIENT_ETH_PAYMENT();
            }
            assembly {
                sstore(ethPaymentsSlotBase, 0) // ethPayments[interactionNonce] = 0;
            }
        } else if (asset.assetType == AztecTypes.AztecAssetType.ERC20) {
            TokenTransfers.safeTransferFrom(asset.erc20Address, bridgeContract, address(this), outputValue);
        }
    }

    /**
     * @dev Convert input assets into output assets via calling a defi bridge contract
     * @param bridgeAddress Address of the defi bridge contract
     * @param inputAssetA First input asset
     * @param inputAssetB Second input asset. Is either VIRTUAL or NOT_USED (checked by RollupProcessor)
     * @param outputAssetA First output asset
     * @param outputAssetB Second output asset
     * @param totalInputValue The total amount of inputAssetA to be sent to the bridge
     * @param interactionNonce Integer that is unique for a given defi interaction
     * @param auxInputData Optional custom data to be sent to the bridge (defined in the L2 SNARK circuits when creating claim notes)
     * @param ethPaymentsSlot The slot value of the `ethPayments` storage mapping in RollupProcessor.sol!
     * @param rollupBeneficiary The address that should be payed any fees / subsidy for executing this bridge.

     * We assume this contract is called from the RollupProcessor via `delegateCall`,
     * if not... this contract behaviour is undefined! So don't do that.
     * The idea here is that, if the defi bridge has returned native ETH, they will do so via calling
     * `RollupProcessor.receiveEthPayment(uint256 interactionNonce)`.
     * To summarise the issue, we must solve for the following:
     * 1. We need to be able to read the `ethPayments` state variable to determine how much Eth has been sent (and reset it)
     * 2. We must encapsulate the entire defi interaction flow via a 'delegatecall' so that we can safely revert
     *    all token/eth transfers if the defi interaction fails, *without* throwing the entire rollup transaction
     * 3. We don't want to directly call `delegateCall` on RollupProcessor.sol to minimise the attack surface against delegatecall re-entrancy exploits
     *
     * Solution is to pass the ethPayments.slot storage slot in as a param during the delegateCall and update in assembly via `sstore`
     * We could achieve the same effect via getters/setters on the function, but that would be expensive as that would trigger additional `call` opcodes.
     * We could *also* just hard-code the slot value, but that is quite brittle as
     * any re-ordering of storage variables during development would require updating the hardcoded constant
     *
     * @return outputValueA outputvalueB isAsync
     * outputValueA = the number of outputAssetA tokens we must recover from the bridge
     * outputValueB = the number of outputAssetB tokens we must recover from the bridge
     * isAsync describes whether the defi interaction has instantly resolved, or if the interaction must be finalised in a future Eth block
     * if isAsync == true, outputValueA and outputValueB must both equal 0
     */
    function convert(
        address bridgeAddress,
        AztecTypes.AztecAsset memory inputAssetA,
        AztecTypes.AztecAsset memory inputAssetB,
        AztecTypes.AztecAsset memory outputAssetA,
        AztecTypes.AztecAsset memory outputAssetB,
        uint256 totalInputValue,
        uint256 interactionNonce,
        uint256 auxInputData, // (auxData)
        uint256 ethPaymentsSlot,
        address rollupBeneficiary
    )
        external
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        )
    {
        if (inputAssetA.assetType == AztecTypes.AztecAssetType.ERC20) {
            // Transfer totalInputValue to the bridge contract if erc20. ETH is sent on call to convert.
            TokenTransfers.safeTransferTo(inputAssetA.erc20Address, bridgeAddress, totalInputValue);
        }
        if (inputAssetB.assetType == AztecTypes.AztecAssetType.ERC20) {
            // Transfer totalInputValue to the bridge contract if erc20. ETH is sent on call to convert.
            TokenTransfers.safeTransferTo(inputAssetB.erc20Address, bridgeAddress, totalInputValue);
        }
        // Call bridge.convert(), which will return output values for the two output assets.
        // If input is ETH, send it along with call to convert.
        uint256 ethValue = (inputAssetA.assetType == AztecTypes.AztecAssetType.ETH ||
            inputAssetB.assetType == AztecTypes.AztecAssetType.ETH)
            ? totalInputValue
            : 0;
        (outputValueA, outputValueB, isAsync) = IDefiBridge(bridgeAddress).convert{value: ethValue}(
            inputAssetA,
            inputAssetB,
            outputAssetA,
            outputAssetB,
            totalInputValue,
            interactionNonce,
            uint64(auxInputData),
            rollupBeneficiary
        );

        if (isAsync) {
            if (outputValueA > 0 || outputValueB > 0) {
                revert ASYNC_NONZERO_OUTPUT_VALUES(outputValueA, outputValueB);
            }
        } else {
            address bridgeAddressCopy = bridgeAddress; // stack overflow workaround
            if (outputValueA >= (1 << 252)) {
                revert OUTPUT_A_EXCEEDS_252_BITS(outputValueA);
            }
            if (outputValueB >= (1 << 252)) {
                revert OUTPUT_B_EXCEEDS_252_BITS(outputValueB);
            }
            recoverTokens(outputAssetA, outputValueA, interactionNonce, bridgeAddressCopy, ethPaymentsSlot);
            recoverTokens(outputAssetB, outputValueB, interactionNonce, bridgeAddressCopy, ethPaymentsSlot);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

import {AztecTypes} from '../AztecTypes.sol';

interface IDefiBridge {
    function convert(
        AztecTypes.AztecAsset memory inputAssetA,
        AztecTypes.AztecAsset memory inputAssetB,
        AztecTypes.AztecAsset memory outputAssetA,
        AztecTypes.AztecAsset memory outputAssetB,
        uint256 totalInputValue,
        uint256 interactionNonce,
        uint64 auxData,
        address rollupBeneficiary
    )
        external
        payable
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        );

    function canFinalise(uint256 interactionNonce) external view returns (bool);

    function finalise(
        AztecTypes.AztecAsset memory inputAssetA,
        AztecTypes.AztecAsset memory inputAssetB,
        AztecTypes.AztecAsset memory outputAssetA,
        AztecTypes.AztecAsset memory outputAssetB,
        uint256 interactionNonce,
        uint64 auxData
    )
        external
        payable
        returns (
            uint256 outputValueA,
            uint256 outputValueB,
            bool interactionCompleted
        );
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

library AztecTypes {
    enum AztecAssetType {
        NOT_USED,
        ETH,
        ERC20,
        VIRTUAL
    }

    struct AztecAsset {
        uint256 id;
        address erc20Address;
        AztecAssetType assetType;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Aztec
pragma solidity >=0.8.4;

/**
 * @title TokenTransfers
 * @dev Provides functions to safely call `transfer` and `transferFrom` methods on ERC20 tokens,
 * as well as the ability to call `transfer` and `transferFrom` without bubbling up errors
 */
library TokenTransfers {
    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb; // bytes4(keccak256('transfer(address,uint256)'));
    bytes4 private constant TRANSFER_FROM_SELECTOR = 0x23b872dd; // bytes4(keccak256('transferFrom(address,address,uint256)'));

    /**
     * @dev Safely call ERC20.transfer, handles tokens that do not throw on transfer failure or do not return transfer result
     * @param tokenAddress Where does the token live?
     * @param to Who are we sending tokens to?
     * @param amount How many tokens are we transferring?
     */
    function safeTransferTo(
        address tokenAddress,
        address to,
        uint256 amount
    ) internal {
        // The ERC20 token standard states that:
        // 1. failed transfers must throw
        // 2. the result of the transfer (success/fail) is returned as a boolean
        // Some token contracts don't implement the spec correctly and will do one of the following:
        // 1. Contract does not throw if transfer fails, instead returns false
        // 2. Contract throws if transfer fails, but does not return any boolean value
        // We can check for these by evaluating the following:
        // | call succeeds? (c) | return value (v) | returndatasize == 0 (r)| interpreted result |
        // | ---                | ---              | ---                    | ---                |
        // | false              | false            | false                  | transfer fails     |
        // | false              | false            | true                   | transfer fails     |
        // | false              | true             | false                  | transfer fails     |
        // | false              | true             | true                   | transfer fails     |
        // | true               | false            | false                  | transfer fails     |
        // | true               | false            | true                   | transfer succeeds  |
        // | true               | true             | false                  | transfer succeeds  |
        // | true               | true             | true                   | transfer succeeds  |
        //
        // i.e. failure state = !(c && (r || v))
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, TRANSFER_SELECTOR)
            mstore(add(ptr, 0x4), to)
            mstore(add(ptr, 0x24), amount)
            let call_success := call(gas(), tokenAddress, 0, ptr, 0x44, 0x00, 0x20)
            let result_success := or(iszero(returndatasize()), and(mload(0), 1))
            if iszero(and(call_success, result_success)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @dev Safely call ERC20.transferFrom, handles tokens that do not throw on transfer failure or do not return transfer result
     * @param tokenAddress Where does the token live?
     * @param source Who are we transferring tokens from
     * @param target Who are we transferring tokens to?
     * @param amount How many tokens are being transferred?
     */
    function safeTransferFrom(
        address tokenAddress,
        address source,
        address target,
        uint256 amount
    ) internal {
        assembly {
            // call tokenAddress.transferFrom(source, target, value)
            let mPtr := mload(0x40)
            mstore(mPtr, TRANSFER_FROM_SELECTOR)
            mstore(add(mPtr, 0x04), source)
            mstore(add(mPtr, 0x24), target)
            mstore(add(mPtr, 0x44), amount)
            let call_success := call(gas(), tokenAddress, 0, mPtr, 0x64, 0x00, 0x20)
            let result_success := or(iszero(returndatasize()), and(mload(0), 1))
            if iszero(and(call_success, result_success)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @dev Calls ERC(tokenAddress).transfer(to, amount). Errors are ignored! Use with caution!
     * @param tokenAddress Where does the token live?
     * @param to Who are we sending to?
     * @param amount How many tokens are being transferred?
     * @param gasToSend Amount of gas to send the contract. If value is 0, function uses gas() instead
     */
    function transferToDoNotBubbleErrors(
        address tokenAddress,
        address to,
        uint256 amount,
        uint256 gasToSend
    ) internal {
        assembly {
            let callGas := gas()
            if gasToSend {
                callGas := gasToSend
            }
            let ptr := mload(0x40)
            mstore(ptr, TRANSFER_SELECTOR)
            mstore(add(ptr, 0x4), to)
            mstore(add(ptr, 0x24), amount)
            pop(call(callGas, tokenAddress, 0, ptr, 0x44, 0x00, 0x00))
        }
    }

    /**
     * @dev Calls ERC(tokenAddress).transferFrom(source, target, amount). Errors are ignored! Use with caution!
     * @param tokenAddress Where does the token live?
     * @param source Who are we transferring tokens from
     * @param target Who are we transferring tokens to?
     * @param amount How many tokens are being transferred?
     * @param gasToSend Amount of gas to send the contract. If value is 0, function uses gas() instead
     */
    function transferFromDoNotBubbleErrors(
        address tokenAddress,
        address source,
        address target,
        uint256 amount,
        uint256 gasToSend
    ) internal {
        assembly {
            let callGas := gas()
            if gasToSend {
                callGas := gasToSend
            }
            let mPtr := mload(0x40)
            mstore(mPtr, TRANSFER_FROM_SELECTOR)
            mstore(add(mPtr, 0x04), source)
            mstore(add(mPtr, 0x24), target)
            mstore(add(mPtr, 0x44), amount)
            pop(call(callGas, tokenAddress, 0, mPtr, 0x64, 0x00, 0x00))
        }
    }
}