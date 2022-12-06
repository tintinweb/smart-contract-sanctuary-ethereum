// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for Supply target contract
interface ISupply {
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    error MintError(address _account);
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    error BurnError(address _account);

    function mint(address _to, uint256 _value) external;

    function burn(address _from, uint256 _value) external;
}

uint256 constant COST_PER_WORD = 3;

uint256 constant ONE_WORD = 0x20;
uint256 constant ALMOST_ONE_WORD = 0x1f;
uint256 constant TWO_WORDS = 0x40;

uint256 constant FREE_MEMORY_POINTER_SLOT = 0x40;
uint256 constant ZERO_SLOT = 0x60;
uint256 constant DEFAULT_FREE_MEMORY_POINTER_SLOT = 0x80;

uint256 constant SLOT0x80 = 0x80;
uint256 constant SLOT0xA0 = 0xa0;
uint256 constant SLOT0xC0 = 0xc0;

uint256 constant FOUR_BYTES = 0x04;
uint256 constant EXTRA_GAS_BUFFER = 0x20;
uint256 constant MEMORY_EXPANSION_COEFFICIENT = 0x200;

// abi.encodeWithSignature("mint(address,uint256)")
uint256 constant REGISTRY_MINT_SIGNATURE = (
    0x40c10f1900000000000000000000000000000000000000000000000000000000
);
uint256 constant REGISTRY_MINT_SIG_PTR = 0x00;
uint256 constant REGISTRY_MINT_TO_PRT = 0x04;
uint256 constant REGISTRY_MINT_VALUE_PTR = 0x24;
uint256 constant REGISTRY_MINT_LENGTH = 0x44; // 4 + 32 * 2 == 68

// abi.encodeWithSignature("burn(address,uint256)")
uint256 constant REGISTRY_BURN_SIGNATURE = (
    0x9dc29fac00000000000000000000000000000000000000000000000000000000
);
uint256 constant REGISTRY_BURN_SIG_PTR = 0x00;
uint256 constant REGISTRY_BURN_FROM_PTR = 0x04;
uint256 constant REGISTRY_BURN_VALUE_PTR = 0x24;
uint256 constant REGISTRY_BURN_LENGTH = 0x44; // 4 + 32 * 2 == 68

// ERRORS

// abi.encodeWithSignature("MintError(address)")
uint256 constant MINT_ERROR_SIGNATURE = (
    0x9770b48a00000000000000000000000000000000000000000000000000000000
);
uint256 constant MINT_ERROR_SIG_PTR = 0x00;
uint256 constant MINT_ERROR_ACCOUNT_PTR = 0x04;
uint256 constant MINT_ERROR_LENGTH = 0x24; // 4 + 32 == 36

// abi.encodeWithSignature("BurnError(address)")
uint256 constant BURN_ERROR_SIGNATURE = (
    0xb715ffa700000000000000000000000000000000000000000000000000000000
);
uint256 constant BURN_ERROR_SIG_PTR = 0x00;
uint256 constant BURN_ERROR_ACCOUNT_PTR = 0x04;
uint256 constant BURN_ERROR_LENGTH = 0x24; // 4 + 32 == 36

/// @title Supply
/// @author Tessera
/// @notice Target contract for minting and burning Raes
contract Supply is ISupply {
    /// @notice Address of VaultRegistry contract
    address immutable registry;

    /// @notice Initializes registry contract
    constructor(address _registry) {
        registry = _registry;
    }

    /// @notice Mints Raes
    /// @param _to Target address
    /// @param _value Transfer amount
    function mint(address _to, uint256 _value) external {
        // Utilize assembly to perform an optimized Vault Registry mint
        address _registry = registry;

        assembly {
            // Write calldata to the free memory pointer, but restore it later.
            let memPointer := mload(FREE_MEMORY_POINTER_SLOT)

            // Write calldata into memory, starting with the function selector
            mstore(REGISTRY_MINT_SIG_PTR, REGISTRY_MINT_SIGNATURE)
            mstore(REGISTRY_MINT_TO_PRT, _to) // Append the "_to" argument
            mstore(REGISTRY_MINT_VALUE_PTR, _value) // Append the "_value" argument

            let success := call(
                gas(),
                _registry,
                0,
                REGISTRY_MINT_SIG_PTR,
                REGISTRY_MINT_LENGTH,
                0,
                0
            )

            // If the mint reverted
            if iszero(success) {
                // If it returned a message, bubble it up as long as sufficient
                // gas remains to do so:
                if returndatasize() {
                    // Ensure that sufficient gas is available to copy
                    // returndata while expanding memory where necessary. Start
                    // by computing word size of returndata & allocated memory.
                    let returnDataWords := div(returndatasize(), ONE_WORD)

                    // Note: use the free memory pointer in place of msize() to
                    // work around a Yul warning that prevents accessing msize
                    // directly when the IR pipeline is activated.
                    let msizeWords := div(memPointer, ONE_WORD)

                    // Next, compute the cost of the returndatacopy.
                    let cost := mul(COST_PER_WORD, returnDataWords)

                    // Then, compute cost of new memory allocation.
                    if gt(returnDataWords, msizeWords) {
                        cost := add(
                            cost,
                            add(
                                mul(sub(returnDataWords, msizeWords), COST_PER_WORD),
                                div(
                                    sub(
                                        mul(returnDataWords, returnDataWords),
                                        mul(msizeWords, msizeWords)
                                    ),
                                    MEMORY_EXPANSION_COEFFICIENT
                                )
                            )
                        )
                    }

                    // Finally, add a small constant and compare to gas
                    // remaining; bubble up the revert data if enough gas is
                    // still available.
                    if lt(add(cost, EXTRA_GAS_BUFFER), gas()) {
                        // Copy returndata to memory; overwrite existing memory.
                        returndatacopy(0, 0, returndatasize())

                        // Revert, giving memory region with copied returndata.
                        revert(0, returndatasize())
                    }
                }

                // Otherwise revert with a generic error message
                mstore(MINT_ERROR_SIG_PTR, MINT_ERROR_SIGNATURE)
                mstore(MINT_ERROR_ACCOUNT_PTR, _to)
                revert(MINT_ERROR_SIG_PTR, MINT_ERROR_LENGTH)
            }

            // Restore the original free memory pointer.
            mstore(FREE_MEMORY_POINTER_SLOT, memPointer)

            // Restore the zero slot to zero.
            mstore(ZERO_SLOT, 0)
        }
    }

    /// @notice Burns Raes
    /// @param _from Source address
    /// @param _value Burn amount
    function burn(address _from, uint256 _value) external {
        // Utilize assembly to perform an optimized Vault Registry burn
        address _registry = registry;

        assembly {
            // Write calldata to the free memory pointer, but restore it later.
            let memPointer := mload(FREE_MEMORY_POINTER_SLOT)

            // Write calldata into memory, starting with the function selector
            mstore(REGISTRY_BURN_SIG_PTR, REGISTRY_BURN_SIGNATURE)
            mstore(REGISTRY_BURN_FROM_PTR, _from) // Append the "_from" argument
            mstore(REGISTRY_BURN_VALUE_PTR, _value) // Append the "_value" argument

            let success := call(
                gas(),
                _registry,
                0,
                REGISTRY_BURN_SIG_PTR,
                REGISTRY_BURN_LENGTH,
                0,
                0
            )

            // If the mint reverted
            if iszero(success) {
                // If it returned a message, bubble it up as long as sufficient
                // gas remains to do so:
                if returndatasize() {
                    // Ensure that sufficient gas is available to copy
                    // returndata while expanding memory where necessary. Start
                    // by computing word size of returndata & allocated memory.
                    let returnDataWords := div(returndatasize(), ONE_WORD)

                    // Note: use the free memory pointer in place of msize() to
                    // work around a Yul warning that prevents accessing msize
                    // directly when the IR pipeline is activated.
                    let msizeWords := div(memPointer, ONE_WORD)

                    // Next, compute the cost of the returndatacopy.
                    let cost := mul(COST_PER_WORD, returnDataWords)

                    // Then, compute cost of new memory allocation.
                    if gt(returnDataWords, msizeWords) {
                        cost := add(
                            cost,
                            add(
                                mul(sub(returnDataWords, msizeWords), COST_PER_WORD),
                                div(
                                    sub(
                                        mul(returnDataWords, returnDataWords),
                                        mul(msizeWords, msizeWords)
                                    ),
                                    MEMORY_EXPANSION_COEFFICIENT
                                )
                            )
                        )
                    }

                    // Finally, add a small constant and compare to gas
                    // remaining; bubble up the revert data if enough gas is
                    // still available.
                    if lt(add(cost, EXTRA_GAS_BUFFER), gas()) {
                        // Copy returndata to memory; overwrite existing memory.
                        returndatacopy(0, 0, returndatasize())

                        // Revert, giving memory region with copied returndata.
                        revert(0, returndatasize())
                    }
                }

                // Otherwise revert with a generic error message
                mstore(BURN_ERROR_SIG_PTR, BURN_ERROR_SIGNATURE)
                mstore(BURN_ERROR_ACCOUNT_PTR, _from)
                revert(BURN_ERROR_SIG_PTR, BURN_ERROR_LENGTH)
            }

            // Restore the original free memory pointer.
            mstore(FREE_MEMORY_POINTER_SLOT, memPointer)

            // Restore the zero slot to zero.
            mstore(ZERO_SLOT, 0)
        }
    }
}