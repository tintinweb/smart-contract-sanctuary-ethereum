// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz
    
*/

/*

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

pragma solidity 0.8.12;

import "./utils/LibBytesV06.sol";
import "./migrations/LibBootstrap.sol";
import "./features/BootstrapFeature.sol";
import "./storage/LibProxyStorage.sol";
import "./ITokenXyz.sol";

/// @title An extensible proxy contract that serves as a universal entry point for
///      interacting with the token.xyz contracts.
contract TokenXyz {
    // solhint-disable separate-by-one-line-in-contract,indent,var-name-mixedcase
    using LibBytesV06 for bytes;

    /// @notice Error thrown when the requested function is not found in any features.
    /// @param selector The function's selector that was attempted to be called.
    error NotImplemented(bytes4 selector);

    /// @notice Construct this contract and register the `BootstrapFeature` feature.
    ///      After constructing this contract, `bootstrap()` should be called
    ///      by `bootstrap()` to seed the initial feature set.
    /// @param bootstrapper Who can call `bootstrap()`.
    constructor(address bootstrapper) {
        // Temporarily create and register the bootstrap feature.
        // It will deregister itself after `bootstrap()` has been called.
        BootstrapFeature bootstrap = new BootstrapFeature(bootstrapper);
        LibProxyStorage.getStorage().impls[bootstrap.bootstrap.selector] = address(bootstrap);
    }

    /// @notice Forwards calls to the appropriate implementation contract.
    fallback() external payable {
        bytes4 selector = msg.data.readBytes4(0);
        address impl = getFunctionImplementation(selector);
        if (impl == address(0)) revert NotImplemented(selector);

        (bool success, bytes memory resultData) = impl.delegatecall(msg.data);
        if (!success) {
            _revertWithData(resultData);
        }
        _returnWithData(resultData);
    }

    /// @notice Fallback for just receiving ether.
    receive() external payable {}

    /// @notice Get the implementation contract of a registered function.
    /// @param selector The function selector.
    /// @return impl The implementation contract address.
    function getFunctionImplementation(bytes4 selector) public view returns (address impl) {
        return LibProxyStorage.getStorage().impls[selector];
    }

    /// @notice Revert with arbitrary bytes.
    /// @param data Revert data.
    function _revertWithData(bytes memory data) private pure {
        assembly {
            revert(add(data, 32), mload(data))
        }
    }

    /// @notice Return with arbitrary bytes.
    /// @param data Return data.
    function _returnWithData(bytes memory data) private pure {
        assembly {
            return(add(data, 32), mload(data))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz
    
*/

/*

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

pragma solidity 0.8.12;

library LibBytesV06 {
    using LibBytesV06 for bytes;

    /// @notice Error thrown on an invalid byte operation.
    error FromLessThanOrEqualsToRequired(uint256 from, uint256 to);

    /// @notice Error thrown on an invalid byte operation.
    error ToLessThanOrEqualsLengthRequired(uint256 to, uint256 length);

    /// @notice Error thrown on an invalid byte operation.
    error LengthGreaterThanZeroRequired(uint256 length);

    /// @notice Error thrown on an invalid byte operation.
    error LengthGreaterThanOrEqualsTwentyRequired(uint256 length, uint256 minimum);

    /// @notice Error thrown on an invalid byte operation.
    error LengthGreaterThanOrEqualsThirtyTwoRequired(uint256 length, uint256 minimum);

    /// @notice Error thrown on an invalid byte operation.
    error LengthGreaterThanOrEqualsFourRequired(uint256 length, uint256 minimum);

    /// @notice Gets the memory address for a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of byte array. This
    ///         points to the header of the byte array which contains
    ///         the length.
    function rawAddress(bytes memory input) internal pure returns (uint256 memoryAddress) {
        assembly {
            memoryAddress := input
        }
        return memoryAddress;
    }

    /// @notice Gets the memory address for the contents of a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of the contents of the byte array.
    function contentAddress(bytes memory input) internal pure returns (uint256 memoryAddress) {
        assembly {
            memoryAddress := add(input, 32)
        }
        return memoryAddress;
    }

    /// @notice Copies `length` bytes from memory location `source` to `dest`.
    /// @param dest memory address to copy bytes to.
    /// @param source memory address to copy bytes from.
    /// @param length number of bytes to copy.
    function memCopy(
        uint256 dest,
        uint256 source,
        uint256 length
    ) internal pure {
        if (length < 32) {
            // Handle a partial word by reading destination and masking
            // off the bits we are interested in.
            // This correctly handles overlap, zero lengths and source == dest
            assembly {
                let mask := sub(exp(256, sub(32, length)), 1)
                let s := and(mload(source), not(mask))
                let d := and(mload(dest), mask)
                mstore(dest, or(s, d))
            }
        } else {
            // Skip the O(length) loop when source == dest.
            if (source == dest) {
                return;
            }

            // For large copies we copy whole words at a time. The final
            // word is aligned to the end of the range (instead of after the
            // previous) to handle partial words. So a copy will look like this:
            //
            //  ####
            //      ####
            //          ####
            //            ####
            //
            // We handle overlap in the source and destination range by
            // changing the copying direction. This prevents us from
            // overwriting parts of source that we still need to copy.
            //
            // This correctly handles source == dest
            //
            if (source > dest) {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because it
                    // is easier to compare with in the loop, and these
                    // are also the addresses we need for copying the
                    // last bytes.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the last 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the last bytes in
                    // source already due to overlap.
                    let last := mload(sEnd)

                    // Copy whole words front to back
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {

                    } lt(source, sEnd) {

                    } {
                        mstore(dest, mload(source))
                        source := add(source, 32)
                        dest := add(dest, 32)
                    }

                    // Write the last 32 bytes
                    mstore(dEnd, last)
                }
            } else {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because those
                    // are the starting points when copying a word at the end.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the first 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the first bytes in
                    // source already due to overlap.
                    let first := mload(source)

                    // Copy whole words back to front
                    // We use a signed comparisson here to allow dEnd to become
                    // negative (happens when source and dest < 32). Valid
                    // addresses in local memory will never be larger than
                    // 2**255, so they can be safely re-interpreted as signed.
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {

                    } slt(dest, dEnd) {

                    } {
                        mstore(dEnd, mload(sEnd))
                        sEnd := sub(sEnd, 32)
                        dEnd := sub(dEnd, 32)
                    }

                    // Write the first 32 bytes
                    mstore(dest, first)
                }
            }
        }
    }

    /// @notice Returns a slices from a byte array.
    /// @param b The byte array to take a slice from.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function slice(
        bytes memory b,
        uint256 from,
        uint256 to
    ) internal pure returns (bytes memory result) {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            revert FromLessThanOrEqualsToRequired(from, to);
        }
        if (to > b.length) {
            revert ToLessThanOrEqualsLengthRequired(to, b.length);
        }

        // Create a new bytes structure and copy contents
        result = new bytes(to - from);
        memCopy(result.contentAddress(), b.contentAddress() + from, result.length);
        return result;
    }

    /// @notice Returns a slice from a byte array without preserving the input.
    ///      When `from == 0`, the original array will match the slice.
    ///      In other cases its state will be corrupted.
    /// @param b The byte array to take a slice from. Will be destroyed in the process.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function sliceDestructive(
        bytes memory b,
        uint256 from,
        uint256 to
    ) internal pure returns (bytes memory result) {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            revert FromLessThanOrEqualsToRequired(from, to);
        }
        if (to > b.length) {
            revert ToLessThanOrEqualsLengthRequired(to, b.length);
        }

        // Create a new bytes structure around [from, to) in-place.
        assembly {
            result := add(b, from)
            mstore(result, sub(to, from))
        }
        return result;
    }

    /// @notice Pops the last byte off of a byte array by modifying its length.
    /// @param b Byte array that will be modified.
    /// @return result The byte that was popped off.
    function popLastByte(bytes memory b) internal pure returns (bytes1 result) {
        if (b.length == 0) {
            revert LengthGreaterThanZeroRequired(b.length);
        }

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @notice Tests equality of two byte arrays.
    /// @param lhs First byte array to compare.
    /// @param rhs Second byte array to compare.
    /// @return equal True if arrays are the same. False otherwise.
    function equals(bytes memory lhs, bytes memory rhs) internal pure returns (bool equal) {
        // Keccak gas cost is 30 + numWords * 6. This is a cheap way to compare.
        // We early exit on unequal lengths, but keccak would also correctly
        // handle this.
        return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
    }

    /// @notice Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(bytes memory b, uint256 index) internal pure returns (address result) {
        if (b.length < index + 20) {
            revert LengthGreaterThanOrEqualsTwentyRequired(
                b.length,
                index + 20 // 20 is length of address
            );
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /// @notice Writes an address into a specific position in a byte array.
    /// @param b Byte array to insert address into.
    /// @param index Index in byte array of address.
    /// @param input Address to put into byte array.
    function writeAddress(
        bytes memory b,
        uint256 index,
        address input
    ) internal pure {
        if (b.length < index + 20) {
            revert LengthGreaterThanOrEqualsTwentyRequired(
                b.length,
                index + 20 // 20 is length of address
            );
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Store address into array memory
        assembly {
            // The address occupies 20 bytes and mstore stores 32 bytes.
            // First fetch the 32-byte word where we'll be storing the address, then
            // apply a mask so we have only the bytes in the word that the address will not occupy.
            // Then combine these bytes with the address and store the 32 bytes back to memory with mstore.

            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 12-byte mask to obtain extra bytes occupying word of memory where we'll store the address
            let neighbors := and(
                mload(add(b, index)),
                0xffffffffffffffffffffffff0000000000000000000000000000000000000000
            )

            // Make sure input address is clean.
            // (Solidity does not guarantee this)
            input := and(input, 0xffffffffffffffffffffffffffffffffffffffff)

            // Store the neighbors and address into memory
            mstore(add(b, index), xor(input, neighbors))
        }
    }

    /// @notice Reads a bytes32 value from a position in a byte array.
    /// @param b Byte array containing a bytes32 value.
    /// @param index Index in byte array of bytes32 value.
    /// @return result bytes32 value from byte array.
    function readBytes32(bytes memory b, uint256 index) internal pure returns (bytes32 result) {
        if (b.length < index + 32) {
            revert LengthGreaterThanOrEqualsThirtyTwoRequired(b.length, index + 32);
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @notice Writes a bytes32 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input bytes32 to put into byte array.
    function writeBytes32(
        bytes memory b,
        uint256 index,
        bytes32 input
    ) internal pure {
        if (b.length < index + 32) {
            revert LengthGreaterThanOrEqualsThirtyTwoRequired(b.length, index + 32);
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(b, index), input)
        }
    }

    /// @notice Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return result uint256 value from byte array.
    function readUint256(bytes memory b, uint256 index) internal pure returns (uint256 result) {
        result = uint256(readBytes32(b, index));
        return result;
    }

    /// @notice Writes a uint256 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input uint256 to put into byte array.
    function writeUint256(
        bytes memory b,
        uint256 index,
        uint256 input
    ) internal pure {
        writeBytes32(b, index, bytes32(input));
    }

    /// @notice Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return result bytes4 value from byte array.
    function readBytes4(bytes memory b, uint256 index) internal pure returns (bytes4 result) {
        if (b.length < index + 4) {
            revert LengthGreaterThanOrEqualsFourRequired(b.length, index + 4);
        }

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    /// @notice Writes a new length to a byte array.
    ///      Decreasing length will lead to removing the corresponding lower order bytes from the byte array.
    ///      Increasing length may lead to appending adjacent in-memory bytes to the end of the byte array.
    /// @param b Bytes array to write new length to.
    /// @param length New length of byte array.
    function writeLength(bytes memory b, uint256 length) internal pure {
        assembly {
            mstore(b, length)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz

*/

/*

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

pragma solidity 0.8.12;

/// @title Common storage helpers
library LibStorage {
    /// @notice What to bit-shift a storage ID by to get its slot.
    ///      This gives us a maximum of 2**128 inline fields in each bucket.
    uint256 private constant STORAGE_SLOT_EXP = 128;

    /// @notice Storage IDs for feature storage buckets.
    ///      WARNING: APPEND-ONLY.
    enum StorageId {
        Proxy,
        SimpleFunctionRegistry,
        Ownable,
        TokenFactory,
        MerkleDistributorFactory,
        MerkleVestingFactory
    }

    /// @notice Get the storage slot given a storage ID. We assign unique, well-spaced
    ///     slots to storage bucket variables to ensure they do not overlap.
    ///     See: https://solidity.readthedocs.io/en/v0.8.12/assembly.html#access-to-external-variables-functions-and-libraries
    /// @param storageId An entry in `StorageId`
    /// @return slot The storage slot.
    function getStorageSlot(StorageId storageId) internal pure returns (uint256 slot) {
        // This should never overflow with a reasonable `STORAGE_SLOT_EXP`
        // because Solidity will do a range check on `storageId` during the cast.
        return (uint256(storageId) + 1) << STORAGE_SLOT_EXP;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz
    
*/

/*

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

pragma solidity 0.8.12;

import "./LibStorage.sol";

/// @title Storage helpers for the proxy contract.
library LibProxyStorage {
    /// @notice Storage bucket for proxy contract.
    struct Storage {
        // Mapping of function selector -> function implementation
        mapping(bytes4 => address) impls;
        // The owner of the proxy contract.
        address owner;
    }

    /// @notice Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.Proxy);
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.8.12/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor.slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz
    
*/

/*

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

pragma solidity 0.8.12;

library LibBootstrap {
    /// @notice Magic bytes returned by the bootstrapper to indicate success.
    ///      This is `keccack('BOOTSTRAP_SUCCESS')`.
    bytes4 internal constant BOOTSTRAP_SUCCESS = 0xd150751b;

    /// @notice Error thrown when a delegatecall to a bootstrap function failed.
    /// @param target The address that was attempted to be called.
    /// @param resultData The result bytes of the call.
    error BootstrapCallFailed(address target, bytes resultData);

    /// @notice Perform a delegatecall and ensure it returns the magic bytes.
    /// @param target The call target.
    /// @param data The call data.
    function delegatecallBootstrapFunction(address target, bytes memory data) internal {
        (bool success, bytes memory resultData) = target.delegatecall(data);
        if (!success || resultData.length != 32 || abi.decode(resultData, (bytes4)) != BOOTSTRAP_SUCCESS) {
            revert BootstrapCallFailed(target, resultData);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokenFactoryBase.sol";

/// @title A contract that deploys ERC20 token contracts with OpenZeppelin's AccessControl for anyone.
interface ITokenWithRolesFactoryFeature is ITokenFactoryBase {
    /// @notice Deploys a new ERC20 token contract.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @param tokenName The token's name.
    /// @param tokenSymbol The token's symbol.
    /// @param tokenDecimals The token's number of decimals.
    /// @param initialSupply The initial amount of tokens to mint.
    /// @param maxSupply The maximum amount of tokens that can ever be minted. Unlimited if set to zero.
    /// @param firstOwner The first address to assign ownership/minting rights to (if mintable). The recipient of the initial supply.
    function createTokenWithRoles(
        string calldata urlName,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 tokenDecimals,
        uint256 initialSupply,
        uint256 maxSupply,
        address firstOwner
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITokenFactoryBase.sol";

/// @title A contract that deploys ERC20 token contracts for anyone.
interface ITokenFactoryFeature is ITokenFactoryBase {
    /// @notice Deploys a new ERC20 token contract.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @param tokenName The token's name.
    /// @param tokenSymbol The token's symbol.
    /// @param tokenDecimals The token's number of decimals.
    /// @param initialSupply The initial amount of tokens to mint.
    /// @param maxSupply The maximum amount of tokens that can ever be minted. Unlimited if set to zero.
    /// @param firstOwner The first address to assign ownership/minting rights to (if mintable). The recipient of the initial supply.
    function createToken(
        string calldata urlName,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 tokenDecimals,
        uint256 initialSupply,
        uint256 maxSupply,
        address firstOwner
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Common functions and events for a contract that deploys ERC20 token contracts for anyone.
interface ITokenFactoryBase {
    /// @notice Returns all the deployed token addresses by a specific creator.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @return tokenAddresses The requested array of token addresses.
    function getDeployedTokens(string calldata urlName) external view returns (address[] memory tokenAddresses);

    /// @notice Event emitted when creating a token.
    /// @param deployer The address which created the token.
    /// @param urlName The urlName, where the created token is sorted in.
    /// @param token The address of the newly created token.
    event TokenDeployed(address indexed deployer, string urlName, address token);

    /// @notice Error thrown when the max supply is attempted to be set lower than the initial supply.
    /// @param maxSupply The desired max supply.
    /// @param initialSupply The desired initial supply, that cannot be higher than the max.
    error MaxSupplyTooLow(uint256 maxSupply, uint256 initialSupply);
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz
    
*/

/*

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

pragma solidity ^0.8.0;

/// @title Basic registry management features.
interface ISimpleFunctionRegistryFeature {
    /// @notice Error thrown when the requested function selector is not in the target implementation.
    /// @param selector The function selector.
    /// @param implementation The address supposed to include an older implementation of the function.
    error NotInRollbackHistory(bytes4 selector, address implementation);

    /// @notice A function implementation was updated via `extend()` or `rollback()`.
    /// @param selector The function selector.
    /// @param oldImpl The implementation contract address being replaced.
    /// @param newImpl The replacement implementation contract address.
    event ProxyFunctionUpdated(bytes4 indexed selector, address oldImpl, address newImpl);

    /// @notice Roll back to a prior implementation of a function.
    /// @param selector The function selector.
    /// @param targetImpl The address of an older implementation of the function.
    function rollback(bytes4 selector, address targetImpl) external;

    /// @notice Register or replace a function.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function extend(bytes4 selector, address impl) external;

    /// @notice Retrieve the length of the rollback history for a function.
    /// @param selector The function selector.
    /// @return rollbackLength The number of items in the rollback history for
    ///         the function.
    function getRollbackLength(bytes4 selector) external view returns (uint256 rollbackLength);

    /// @notice Retrieve an entry in the rollback history for a function.
    /// @param selector The function selector.
    /// @param idx The index in the rollback history.
    /// @return impl An implementation address for the function at
    ///         index `idx`.
    function getRollbackEntryAtIndex(bytes4 selector, uint256 idx) external view returns (address impl);
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz
    
*/

/*

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

pragma solidity ^0.8.0;

interface IOwnableV06 {
    /// @notice Emitted by Ownable when ownership is transferred.
    /// @param previousOwner The previous owner of the contract.
    /// @param newOwner The new owner of the contract.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Transfers ownership of the contract to a new address.
    /// @param newOwner The address that will become the owner.
    function transferOwnership(address newOwner) external;

    /// @notice The owner of this contract.
    /// @return ownerAddress The owner address.
    function owner() external view returns (address ownerAddress);
}

/// @title Owner management and migration features.
interface IOwnableFeature is IOwnableV06 {
    /// @notice Emitted when `migrate()` is called.
    /// @param caller The caller of `migrate()`.
    /// @param migrator The migration contract.
    /// @param newOwner The address of the new owner.
    event Migrated(address caller, address migrator, address newOwner);

    /// @notice Error thrown when attempting to transfer the ownership to the zero address.
    error TransferOwnerToZero();

    /// @notice Execute a migration function in the context of the TokenXyz contract.
    ///      The result of the function being called should be the magic bytes
    ///      0x2c64c5ef (`keccak('MIGRATE_SUCCESS')`). Only callable by the owner.
    ///      The owner will be temporarily set to `address(this)` inside the call.
    ///      Before returning, the owner will be set to `newOwner`.
    /// @param target The migrator contract address.
    /// @param newOwner The address of the new owner.
    /// @param data The call data.
    function migrate(
        address target,
        bytes calldata data,
        address newOwner
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Provides a function to batch together multiple calls in a single external call.
interface IMulticallFeature {
    /// @notice Receives and executes a batch of function calls on this contract.
    /// @param data An array of the encoded function call data.
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title A contract that deploys token vesting contracts for anyone.
interface IMerkleVestingFactoryFeature {
    /// @notice Deploys a new Merkle Vesting contract.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @param token The address of the token to distribute.
    /// @param owner The owner address of the contract to be deployed. Will have special access to some functions.
    function createVesting(
        string calldata urlName,
        address token,
        address owner
    ) external;

    /// @notice Returns all the deployed vesting contract addresses by a specific creator.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @return vestingAddresses The requested array of contract addresses.
    function getDeployedVestings(string calldata urlName) external view returns (address[] memory vestingAddresses);

    /// @notice Event emitted when creating a new vesting contract.
    /// @param deployer The address which created the vesting.
    /// @param urlName The urlName, where the created vesting contract is sorted in.
    /// @param instance The address of the newly created vesting contract.
    event MerkleVestingDeployed(address indexed deployer, string urlName, address instance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title A contract that deploys token airdrop contracts for anyone.
interface IMerkleDistributorFactoryFeature {
    /// @notice Deploys a new Merkle Distributor contract.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @param token The address of the token to distribute.
    /// @param merkleRoot The root of the merkle tree generated from the distribution list.
    /// @param distributionDuration The time interval while the distribution lasts in seconds.
    /// @param owner The owner address of the contract to be deployed. Will have special access to some functions.
    function createAirdrop(
        string calldata urlName,
        address token,
        bytes32 merkleRoot,
        uint256 distributionDuration,
        address owner
    ) external;

    /// @notice Returns all the deployed airdrop contract addresses by a specific creator.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @return airdropAddresses The requested array of contract addresses.
    function getDeployedAirdrops(string calldata urlName) external view returns (address[] memory airdropAddresses);

    /// @notice Event emitted when creating a new airdrop contract.
    /// @param deployer The address which created the airdrop.
    /// @param urlName The urlName, where the created airdrop contract is sorted in.
    /// @param instance The address of the newly created airdrop contract.
    event MerkleDistributorDeployed(address indexed deployer, string urlName, address instance);
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz
    
*/

/*

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

pragma solidity ^0.8.0;

/// @title Detachable `bootstrap()` feature.
interface IBootstrapFeature {
    /// @notice Error thrown when the bootstrap() function is called by the wrong address.
    /// @param actualCaller The caller of the function.
    /// @param allowedCaller The address that is allowed to call the function.
    error InvalidBootstrapCaller(address actualCaller, address allowedCaller);

    /// @notice Error thrown when the die() function is called by the wrong address.
    /// @param actualCaller The caller of the function.
    /// @param deployer The deployer's address, which is allowed to call the function.
    error InvalidDieCaller(address actualCaller, address deployer);

    /// @notice Bootstrap the initial feature set of this contract by delegatecalling
    ///      into `target`. Before exiting the `bootstrap()` function will
    ///      deregister itself from the proxy to prevent being called again.
    /// @param target The bootstrapper contract address.
    /// @param callData The call data to execute on `target`.
    function bootstrap(address target, bytes calldata callData) external;
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz
    
*/

/*

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

pragma solidity 0.8.12;

import "../migrations/LibBootstrap.sol";
import "../storage/LibProxyStorage.sol";
import "./interfaces/IBootstrapFeature.sol";

/// @title Detachable `bootstrap()` feature.
contract BootstrapFeature is IBootstrapFeature {
    // solhint-disable state-visibility,indent
    /// @notice The main proxy contract.
    ///      This has to be immutable to persist across delegatecalls.
    address private immutable _deployer;
    /// @notice The implementation address of this contract.
    ///      This has to be immutable to persist across delegatecalls.
    address private immutable _implementation;
    /// @notice The deployer.
    ///      This has to be immutable to persist across delegatecalls.
    address private immutable _bootstrapCaller;

    // solhint-enable state-visibility,indent

    /// @notice Construct this contract and set the bootstrap migration contract.
    ///      After constructing this contract, `bootstrap()` should be called
    ///      to seed the initial feature set.
    /// @param bootstrapCaller The allowed caller of `bootstrap()`.
    constructor(address bootstrapCaller) {
        _deployer = msg.sender;
        _implementation = address(this);
        _bootstrapCaller = bootstrapCaller;
    }

    /// @notice Bootstrap the initial feature set of this contract by delegatecalling
    ///      into `target`. Before exiting the `bootstrap()` function will
    ///      deregister itself from the proxy to prevent being called again.
    /// @param target The bootstrapper contract address.
    /// @param callData The call data to execute on `target`.
    function bootstrap(address target, bytes calldata callData) external override {
        // Only the bootstrap caller can call this function.
        if (msg.sender != _bootstrapCaller) revert InvalidBootstrapCaller(msg.sender, _bootstrapCaller);

        // Deregister.
        LibProxyStorage.getStorage().impls[this.bootstrap.selector] = address(0);
        // Self-destruct.
        BootstrapFeature(_implementation).die();
        // Call the bootstrapper.
        LibBootstrap.delegatecallBootstrapFunction(target, callData);
    }

    /// @notice Self-destructs this contract.
    ///      Can only be called by the deployer.
    function die() external {
        assert(address(this) == _implementation);
        if (msg.sender != _deployer) revert InvalidDieCaller(msg.sender, _deployer);
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: Apache-2.0

/*

    The file was modified by Agora.

    2022 agora.xyz

*/

/*

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

pragma solidity ^0.8.0;

import "./features/interfaces/IOwnableFeature.sol";
import "./features/interfaces/ISimpleFunctionRegistryFeature.sol";
import "./features/interfaces/IMulticallFeature.sol";
import "./features/interfaces/ITokenFactoryFeature.sol";
import "./features/interfaces/ITokenWithRolesFactoryFeature.sol";
import "./features/interfaces/IMerkleDistributorFactoryFeature.sol";
import "./features/interfaces/IMerkleVestingFactoryFeature.sol";

/// @title Interface for a fully featured token.xyz Proxy.
interface ITokenXyz is
    IOwnableFeature,
    ISimpleFunctionRegistryFeature,
    IMulticallFeature,
    ITokenFactoryFeature,
    ITokenWithRolesFactoryFeature,
    IMerkleDistributorFactoryFeature,
    IMerkleVestingFactoryFeature
{
    /// @notice Error thrown when the requested function is not found in any features.
    /// @param selector The function's selector that was attempted to be called.
    error NotImplemented(bytes4 selector);

    /// @notice Fallback for just receiving ether.
    receive() external payable;
}