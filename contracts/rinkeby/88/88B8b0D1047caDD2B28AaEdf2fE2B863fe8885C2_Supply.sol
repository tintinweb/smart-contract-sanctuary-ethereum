// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ISupply} from "../interfaces/ISupply.sol";
import {IVaultRegistry} from "../interfaces/IVaultRegistry.sol";
import "../constants/Supply.sol";

/// @title Supply
/// @author Fractional Art
/// @notice Target contract for minting and burning fractional tokens
contract Supply is ISupply {
    /// @notice Address of VaultRegistry contract
    address immutable registry;

    /// @notice Initializes registry contract
    constructor(address _registry) {
        registry = _registry;
    }

    /// @notice Mints fractional tokens
    /// @param _to Target address
    /// @param _value Transfer amount
    function mint(address _to, uint256 _value) external {
        // Utilize assembly to perform an optimized Vault Registry mint
        address _registry = registry;

        assembly {
            // Write calldata to the free memory pointer, but restore it later.
            let memPointer := mload(FreeMemoryPointerSlot)

            // Write calldata into memory, starting with the function selector
            mstore(VaultRegistry_mint_sig_ptr, VaultRegistry_mint_signature)
            mstore(VaultRegistry_mint_to_ptr, _to) // Append the "_to" argument
            mstore(VaultRegistry_mint_value_ptr, _value) // Append the "_value" argument

            let success := call(
                gas(),
                _registry,
                0,
                VaultRegistry_mint_sig_ptr,
                VaultRegistry_mint_length,
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
                    let returnDataWords := div(returndatasize(), OneWord)

                    // Note: use the free memory pointer in place of msize() to
                    // work around a Yul warning that prevents accessing msize
                    // directly when the IR pipeline is activated.
                    let msizeWords := div(memPointer, OneWord)

                    // Next, compute the cost of the returndatacopy.
                    let cost := mul(CostPerWord, returnDataWords)

                    // Then, compute cost of new memory allocation.
                    if gt(returnDataWords, msizeWords) {
                        cost := add(
                            cost,
                            add(
                                mul(
                                    sub(returnDataWords, msizeWords),
                                    CostPerWord
                                ),
                                div(
                                    sub(
                                        mul(returnDataWords, returnDataWords),
                                        mul(msizeWords, msizeWords)
                                    ),
                                    MemoryExpansionCoefficient
                                )
                            )
                        )
                    }

                    // Finally, add a small constant and compare to gas
                    // remaining; bubble up the revert data if enough gas is
                    // still available.
                    if lt(add(cost, ExtraGasBuffer), gas()) {
                        // Copy returndata to memory; overwrite existing memory.
                        returndatacopy(0, 0, returndatasize())

                        // Revert, giving memory region with copied returndata.
                        revert(0, returndatasize())
                    }
                }

                // Otherwise revert with a generic error message
                mstore(MintError_error_sig_ptr, MintError_error_signature)
                mstore(MintError_error_account_ptr, _to)
                revert(MintError_error_sig_ptr, MintError_error_length)
            }

            // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }
    }

    /// @notice Burns fractional tokens
    /// @param _from Source address
    /// @param _value Burn amount
    function burn(address _from, uint256 _value) external {
        // Utilize assembly to perform an optimized Vault Registry burn
        address _registry = registry;

        assembly {
            // Write calldata to the free memory pointer, but restore it later.
            let memPointer := mload(FreeMemoryPointerSlot)

            // Write calldata into memory, starting with the function selector
            mstore(VaultRegistry_burn_sig_ptr, VaultRegistry_burn_signature)
            mstore(VaultRegistry_burn_from_ptr, _from) // Append the "_from" argument
            mstore(VaultRegistry_burn_value_ptr, _value) // Append the "_value" argument

            let success := call(
                gas(),
                _registry,
                0,
                VaultRegistry_burn_sig_ptr,
                VaultRegistry_burn_length,
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
                    let returnDataWords := div(returndatasize(), OneWord)

                    // Note: use the free memory pointer in place of msize() to
                    // work around a Yul warning that prevents accessing msize
                    // directly when the IR pipeline is activated.
                    let msizeWords := div(memPointer, OneWord)

                    // Next, compute the cost of the returndatacopy.
                    let cost := mul(CostPerWord, returnDataWords)

                    // Then, compute cost of new memory allocation.
                    if gt(returnDataWords, msizeWords) {
                        cost := add(
                            cost,
                            add(
                                mul(
                                    sub(returnDataWords, msizeWords),
                                    CostPerWord
                                ),
                                div(
                                    sub(
                                        mul(returnDataWords, returnDataWords),
                                        mul(msizeWords, msizeWords)
                                    ),
                                    MemoryExpansionCoefficient
                                )
                            )
                        )
                    }

                    // Finally, add a small constant and compare to gas
                    // remaining; bubble up the revert data if enough gas is
                    // still available.
                    if lt(add(cost, ExtraGasBuffer), gas()) {
                        // Copy returndata to memory; overwrite existing memory.
                        returndatacopy(0, 0, returndatasize())

                        // Revert, giving memory region with copied returndata.
                        revert(0, returndatasize())
                    }
                }

                // Otherwise revert with a generic error message
                mstore(BurnError_error_sig_ptr, BurnError_error_signature)
                mstore(BurnError_error_account_ptr, _from)
                revert(BurnError_error_sig_ptr, BurnError_error_length)
            }

            // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Vault permissions
struct Permission {
    // Address of module contract
    address module;
    // Address of target contract
    address target;
    // Function selector from target contract
    bytes4 selector;
}

/// @dev Vault information
struct VaultInfo {
    // Address of FERC1155 token contract
    address token;
    // ID of the token type
    uint256 id;
}

/// @dev Interface for VaultRegistry contract
interface IVaultRegistry {
    /// @dev Emitted when the caller is not the controller
    error InvalidController(address _controller, address _sender);
    /// @dev Emitted when the caller is not a registered vault
    error UnregisteredVault(address _sender);

    /// @dev Event log for deploying vault
    /// @param _vault Address of the vault
    /// @param _token Address of the token
    /// @param _id Id of the token
    event VaultDeployed(
        address indexed _vault,
        address indexed _token,
        uint256 _id
    );

    function burn(address _from, uint256 _value) external;

    function create(
        bytes32 _merkleRoot,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) external returns (address vault);

    function createCollection(
        bytes32 _merkleRoot,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) external returns (address vault, address token);

    function createCollectionFor(
        bytes32 _merkleRoot,
        address _controller,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) external returns (address vault, address token);

    function createFor(
        bytes32 _merkleRoot,
        address _owner,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) external returns (address vault);

    function createInCollection(
        bytes32 _merkleRoot,
        address _token,
        address[] memory _plugins,
        bytes4[] memory _selectors
    ) external returns (address vault);

    function factory() external view returns (address);

    function fNFT() external view returns (address);

    function fNFTImplementation() external view returns (address);

    function mint(address _to, uint256 _value) external;

    function nextId(address) external view returns (uint256);

    function totalSupply(address _vault) external view returns (uint256);

    function uri(address _vault) external view returns (string memory);

    function vaultToToken(address)
        external
        view
        returns (address token, uint256 id);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

uint256 constant OneWord = 0x20;
uint256 constant TwoWords = 0x40;
uint256 constant ThreeWords = 0x60;

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant ZeroSlot = 0x60;
uint256 constant DefaultFreeMemoryPointer = 0x80;

uint256 constant Slot0x80 = 0x80;
uint256 constant Slot0xA0 = 0xa0;
uint256 constant Slot0xC0 = 0xc0;

uint256 constant ExtraGasBuffer = 0x20;
uint256 constant CostPerWord = 3;
uint256 constant MemoryExpansionCoefficient = 0x200;

// abi.encodeWithSignature mint(address, uint256)
uint256 constant VaultRegistry_mint_signature = (
    0x40c10f1900000000000000000000000000000000000000000000000000000000
);
uint256 constant VaultRegistry_mint_sig_ptr = 0x0;
uint256 constant VaultRegistry_mint_to_ptr = 0x04;
uint256 constant VaultRegistry_mint_value_ptr = 0x24;
uint256 constant VaultRegistry_mint_length = 0x44;

// abi.encodeWithSignature burn(address, uint256)
uint256 constant VaultRegistry_burn_signature = (
    0x9dc29fac00000000000000000000000000000000000000000000000000000000
);
uint256 constant VaultRegistry_burn_sig_ptr = 0x0;
uint256 constant VaultRegistry_burn_from_ptr = 0x04;
uint256 constant VaultRegistry_burn_value_ptr = 0x24;
uint256 constant VaultRegistry_burn_length = 0x44;

// ERRORS
// abi.encodeWithSignature("MintError(address)")
uint256 constant MintError_error_signature = (
    0x9770b48a00000000000000000000000000000000000000000000000000000000
);
uint256 constant MintError_error_sig_ptr = 0x0;
uint256 constant MintError_error_account_ptr = 0x4;
uint256 constant MintError_error_length = 0x24; // 4 + 32 == 36

// abi.encodeWithSignature("BurnError(address)")
uint256 constant BurnError_error_signature = (
    0xb715ffa700000000000000000000000000000000000000000000000000000000
);

uint256 constant BurnError_error_sig_ptr = 0x0;
uint256 constant BurnError_error_account_ptr = 0x4;
uint256 constant BurnError_error_length = 0x24; // 4 + 32 == 36