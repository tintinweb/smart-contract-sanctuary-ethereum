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

pragma solidity 0.8.13;

import "../TokenXyz.sol";
import "../features/interfaces/IOwnableFeature.sol";
import "../features/MulticallFeature.sol";
import "../features/TokenFactoryFeature.sol";
import "../features/TokenWithRolesFactoryFeature.sol";
import "../features/MerkleDistributorFactoryFeature.sol";
import "../features/MerkleVestingFactoryFeature.sol";
import "../features/MerkleNFTMinterFactoryFeature.sol";
import "./InitialMigration.sol";

/// @title A contract for deploying and configuring the full TokenXyz contract.
contract FullMigration {
    /// @notice Features to add the the proxy contract.
    struct Features {
        SimpleFunctionRegistryFeature registry;
        OwnableFeature ownable;
        MulticallFeature multicall;
        TokenFactoryFeature tokenFactory;
        TokenWithRolesFactoryFeature tokenWithRolesFactory;
        MerkleDistributorFactoryFeature merkleDistributorFactory;
        MerkleVestingFactoryFeature merkleVestingFactory;
        MerkleNFTMinterFactoryFeature merkleNFTMinterFactory;
    }

    /// @notice The allowed caller of `initializeTokenXyz()`.
    address public immutable initializeCaller;
    /// @notice The initial migration contract.
    InitialMigration private _initialMigration;

    /// @notice Instantiate this contract and set the allowed caller of `initializeTokenXyz()`
    ///      to `initializeCaller`.
    /// @param initializeCaller_ The allowed caller of `initializeTokenXyz()`.
    constructor(address payable initializeCaller_) {
        initializeCaller = initializeCaller_;
        // Create an initial migration contract with this contract set to the
        // allowed `initializeCaller`.
        _initialMigration = new InitialMigration(address(this));
    }

    /// @notice Retrieve the bootstrapper address to use when constructing `TokenXyz`.
    /// @return bootstrapper The bootstrapper address.
    function getBootstrapper() external view returns (address bootstrapper) {
        return address(_initialMigration);
    }

    /// @notice Initialize the `TokenXyz` contract with the full feature set,
    ///      transfer ownership to `owner`, then self-destruct.
    /// @param owner The owner of the contract.
    /// @param tokenXyz The instance of the TokenXyz contract. TokenXyz should
    ///        been constructed with this contract as the bootstrapper.
    /// @param features Features to add to the proxy.
    /// @return _tokenXyz The configured TokenXyz contract. Same as the `tokenXyz` parameter.
    function migrateTokenXyz(
        address payable owner,
        TokenXyz tokenXyz,
        Features memory features
    ) public returns (TokenXyz _tokenXyz) {
        require(msg.sender == initializeCaller, "FullMigration/INVALID_SENDER");

        // Perform the initial migration with the owner set to this contract.
        _initialMigration.initializeTokenXyz(
            payable(address(uint160(address(this)))),
            tokenXyz,
            InitialMigration.BootstrapFeatures({registry: features.registry, ownable: features.ownable})
        );

        // Add features.
        _addFeatures(tokenXyz, features);

        // Transfer ownership to the real owner.
        IOwnableFeature(address(tokenXyz)).transferOwnership(owner);

        // Self-destruct.
        this.die(owner);

        return tokenXyz;
    }

    /// @notice Destroy this contract. Only callable from ourselves (from `initializeTokenXyz()`).
    /// @param ethRecipient Receiver of any ETH in this contract.
    function die(address payable ethRecipient) external virtual {
        require(msg.sender == address(this), "FullMigration/INVALID_SENDER");
        // This contract should not hold any funds but we send
        // them to the ethRecipient just in case.
        selfdestruct(ethRecipient);
    }

    /// @notice Deploy and register features to the TokenXyz contract.
    /// @param tokenXyz The bootstrapped TokenXyz contract.
    /// @param features Features to add to the proxy.
    function _addFeatures(TokenXyz tokenXyz, Features memory features) private {
        IOwnableFeature ownable = IOwnableFeature(address(tokenXyz));
        // MulticallFeature
        {
            // Register the feature.
            ownable.migrate(
                address(features.multicall),
                abi.encodeWithSelector(MulticallFeature.migrate.selector),
                address(this)
            );
        }
        // TokenFactoryFeature
        {
            // Register the feature.
            ownable.migrate(
                address(features.tokenFactory),
                abi.encodeWithSelector(TokenFactoryFeature.migrate.selector),
                address(this)
            );
        }
        // TokenWithRolesFactoryFeature
        {
            // Register the feature.
            ownable.migrate(
                address(features.tokenWithRolesFactory),
                abi.encodeWithSelector(TokenWithRolesFactoryFeature.migrate.selector),
                address(this)
            );
        }
        // MerkleDistributorFactoryFeature
        {
            // Register the feature.
            ownable.migrate(
                address(features.merkleDistributorFactory),
                abi.encodeWithSelector(MerkleDistributorFactoryFeature.migrate.selector),
                address(this)
            );
        }
        // MerkleVestingFactoryFeature
        {
            // Register the feature.
            ownable.migrate(
                address(features.merkleVestingFactory),
                abi.encodeWithSelector(MerkleVestingFactoryFeature.migrate.selector),
                address(this)
            );
        }
        // MerkleNFTMinterFactoryFeature
        {
            // Register the feature.
            ownable.migrate(
                address(features.merkleNFTMinterFactory),
                abi.encodeWithSelector(MerkleNFTMinterFactoryFeature.migrate.selector),
                address(this)
            );
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

pragma solidity 0.8.13;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./LibStorage.sol";
import "../features/interfaces/IFactoryFeature.sol";

/// @title Storage helpers for the `TokenFactory` feature.
library LibTokenFactoryStorage {
    /// @notice Storage bucket for this feature.
    struct Storage {
        // The data of deployments by entities
        mapping(string => IFactoryFeature.DeployData[]) deploys;
    }

    /// @notice Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.TokenFactory);
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.8.13/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
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

pragma solidity 0.8.13;

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
        MerkleVestingFactory,
        MerkleNFTMinterFactory
    }

    /// @notice Get the storage slot given a storage ID. We assign unique, well-spaced
    ///     slots to storage bucket variables to ensure they do not overlap.
    ///     See: https://solidity.readthedocs.io/en/v0.8.13/assembly.html#access-to-external-variables-functions-and-libraries
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

pragma solidity 0.8.13;

import "./LibStorage.sol";

/// @title Storage helpers for the `SimpleFunctionRegistry` feature.
library LibSimpleFunctionRegistryStorage {
    /// @notice Storage bucket for this feature.
    struct Storage {
        // Mapping of function selector -> implementation history.
        mapping(bytes4 => address[]) implHistory;
    }

    /// @notice Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.SimpleFunctionRegistry);
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.8.13/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
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

pragma solidity 0.8.13;

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
        // See https://solidity.readthedocs.io/en/v0.8.13/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
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

pragma solidity 0.8.13;

import "./LibStorage.sol";

/// @title Storage helpers for the `Ownable` feature.
library LibOwnableStorage {
    /// @notice Storage bucket for this feature.
    struct Storage {
        // The owner of this contract.
        address owner;
    }

    /// @notice Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.Ownable);
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.8.13/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor.slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./LibStorage.sol";
import "../features/interfaces/IFactoryFeature.sol";

/// @title Storage helpers for the `MerkleVestingFactory` feature.
library LibMerkleVestingFactoryStorage {
    /// @notice Storage bucket for this feature.
    struct Storage {
        // The data of deployments by entities
        mapping(string => IFactoryFeature.DeployData[]) deploys;
    }

    /// @notice Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.MerkleVestingFactory);
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.8.13/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor.slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./LibStorage.sol";
import "../features/interfaces/IFactoryFeature.sol";

/// @title Storage helpers for the `MerkleNFTMinterFactory` feature.
library LibMerkleNFTMinterFactoryStorage {
    /// @notice Storage bucket for this feature.
    struct Storage {
        // The data of deployments by entities
        mapping(string => IFactoryFeature.DeployData[]) deploys;
    }

    /// @notice Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.MerkleNFTMinterFactory);
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.8.13/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly {
            stor.slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./LibStorage.sol";
import "../features/interfaces/IFactoryFeature.sol";

/// @title Storage helpers for the `MerkleDistributorFactory` feature.
library LibMerkleDistributorFactoryStorage {
    /// @notice Storage bucket for this feature.
    struct Storage {
        // The data of deployments by entities
        mapping(string => IFactoryFeature.DeployData[]) deploys;
    }

    /// @notice Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        uint256 storageSlot = LibStorage.getStorageSlot(LibStorage.StorageId.MerkleDistributorFactory);
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.8.13/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
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

pragma solidity 0.8.13;

library LibMigrate {
    /// @notice Magic bytes returned by a migrator to indicate success.
    ///      This is `keccack('MIGRATE_SUCCESS')`.
    bytes4 internal constant MIGRATE_SUCCESS = 0x2c64c5ef;

    /// @notice Error thrown when a delegatecall to a migrate function failed.
    /// @param target The address that was attempted to be called.
    /// @param resultData The result bytes of the call.
    error MigrateCallFailed(address target, bytes resultData);

    /// @notice Perform a delegatecall and ensure it returns the magic bytes.
    /// @param target The call target.
    /// @param data The call data.
    function delegatecallMigrateFunction(address target, bytes memory data) internal {
        (bool success, bytes memory resultData) = target.delegatecall(data);
        if (!success || resultData.length != 32 || abi.decode(resultData, (bytes4)) != MIGRATE_SUCCESS) {
            revert MigrateCallFailed(target, resultData);
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

pragma solidity 0.8.13;

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

pragma solidity 0.8.13;

import "../TokenXyz.sol";
import "../features/interfaces/IBootstrapFeature.sol";
import "../features/SimpleFunctionRegistryFeature.sol";
import "../features/OwnableFeature.sol";
import "./LibBootstrap.sol";

/// @title A contract for deploying and configuring a minimal TokenXyz contract.
contract InitialMigration {
    /// @notice Features to bootstrap into the the proxy contract.
    struct BootstrapFeatures {
        SimpleFunctionRegistryFeature registry;
        OwnableFeature ownable;
    }

    /// @notice The allowed caller of `initializeTokenXyz()`. In production, this would be
    ///      the governor.
    address public immutable initializeCaller;
    /// @notice The real address of this contract.
    address private immutable _implementation;

    /// @notice Instantiate this contract and set the allowed caller of `initializeTokenXyz()`
    ///      to `initializeCaller_`.
    /// @param initializeCaller_ The allowed caller of `initializeTokenXyz()`.
    constructor(address initializeCaller_) {
        initializeCaller = initializeCaller_;
        _implementation = address(this);
    }

    /// @notice Retrieve the bootstrapper address to use when constructing `TokenXyz`.
    /// @return bootstrapper The bootstrapper address.
    function getBootstrapper() external view returns (address bootstrapper) {
        return _implementation;
    }

    /// @notice Initialize the `TokenXyz` contract with the minimum feature set,
    ///      transfers ownership to `owner`, then self-destructs.
    ///      Only callable by `initializeCaller` set in the contstructor.
    /// @param owner The owner of the contract.
    /// @param tokenXyz The instance of the TokenXyz contract. TokenXyz should
    ///        been constructed with this contract as the bootstrapper.
    /// @param features Features to bootstrap into the proxy.
    /// @return _tokenXyz The configured TokenXyz contract. Same as the `tokenXyz` parameter.
    function initializeTokenXyz(
        address payable owner,
        TokenXyz tokenXyz,
        BootstrapFeatures memory features
    ) public virtual returns (TokenXyz _tokenXyz) {
        // Must be called by the allowed initializeCaller.
        require(msg.sender == initializeCaller, "InitialMigration/INVALID_SENDER");

        // Bootstrap the initial feature set.
        IBootstrapFeature(address(tokenXyz)).bootstrap(
            address(this),
            abi.encodeWithSelector(this.bootstrap.selector, owner, features)
        );

        // Self-destruct. This contract should not hold any funds but we send
        // them to the owner just in case.
        this.die(owner);

        return tokenXyz;
    }

    /// @notice Sets up the initial state of the `TokenXyz` contract.
    ///      The `TokenXyz` contract will delegatecall into this function.
    /// @param owner The new owner of the TokenXyz contract.
    /// @param features Features to bootstrap into the proxy.
    /// @return success Magic bytes if successful.
    function bootstrap(address owner, BootstrapFeatures memory features) public virtual returns (bytes4 success) {
        // Deploy and migrate the initial features.
        // Order matters here.

        // Initialize Registry.
        LibBootstrap.delegatecallBootstrapFunction(
            address(features.registry),
            abi.encodeWithSelector(SimpleFunctionRegistryFeature.bootstrap.selector)
        );

        // Initialize OwnableFeature.
        LibBootstrap.delegatecallBootstrapFunction(
            address(features.ownable),
            abi.encodeWithSelector(OwnableFeature.bootstrap.selector)
        );

        // De-register `SimpleFunctionRegistryFeature._extendSelf`.
        SimpleFunctionRegistryFeature(address(this)).rollback(
            SimpleFunctionRegistryFeature._extendSelf.selector,
            address(0)
        );

        // Transfer ownership to the real owner.
        OwnableFeature(address(this)).transferOwnership(owner);

        success = LibBootstrap.BOOTSTRAP_SUCCESS;
    }

    /// @notice Self-destructs this contract. Only callable by this contract.
    /// @param ethRecipient Who to transfer outstanding ETH to.
    function die(address payable ethRecipient) public virtual {
        require(msg.sender == _implementation, "InitialMigration/INVALID_SENDER");
        selfdestruct(ethRecipient);
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

pragma solidity 0.8.13;

import "../features/interfaces/IOwnableFeature.sol";
import "../features/interfaces/ISimpleFunctionRegistryFeature.sol";

/// @title Common feature utilities.
abstract contract FixinCommon {
    /// @notice The implementation address of this feature.
    address internal immutable _implementation;

    /// @notice Error thrown when a function only callable by self was called by another address.
    /// @param caller The caller of the function.
    error OnlyCallableBySelf(address caller);

    /// @notice Error thrown when a function only callable by the owner was called by another address.
    /// @param caller The caller of the function.
    /// @param owner The owner's address.
    error OnlyOwner(address caller, address owner);

    /// @notice The caller must be this contract.
    modifier onlySelf() virtual {
        if (msg.sender != address(this)) revert OnlyCallableBySelf(msg.sender);
        _;
    }

    /// @notice The caller of this function must be the owner.
    modifier onlyOwner() virtual {
        {
            address owner = IOwnableFeature(address(this)).owner();
            if (msg.sender != owner) revert OnlyOwner(msg.sender, owner);
        }
        _;
    }

    constructor() {
        // Remember this feature's original address.
        _implementation = address(this);
    }

    /// @notice Registers a function implemented by this feature at `_implementation`.
    ///      Can and should only be called within a `migrate()`.
    /// @param selector The selector of the function whose implementation
    ///        is at `_implementation`.
    function _registerFeatureFunction(bytes4 selector) internal {
        ISimpleFunctionRegistryFeature(address(this)).extend(selector, _implementation);
    }

    /// @notice Encode a feature version as a `uint256`.
    /// @param major The major version number of the feature.
    /// @param minor The minor version number of the feature.
    /// @param revision The revision number of the feature.
    /// @return encodedVersion The encoded version number.
    function _encodeVersion(
        uint32 major,
        uint32 minor,
        uint32 revision
    ) internal pure returns (uint96 encodedVersion) {
        return uint96((uint256(major) << 64) | (uint256(minor) << 32) | uint256(revision));
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

import "./IFactoryFeature.sol";

/// @title Common functions and events for a contract that deploys ERC20 token contracts for anyone.
interface ITokenFactoryBase is IFactoryFeature {
    /// @notice Returns all the deployed token addresses by a specific creator.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @return tokenAddresses The requested array of token addresses.
    function getDeployedTokens(string calldata urlName) external view returns (DeployData[] memory tokenAddresses);

    /// @notice Event emitted when creating a token.
    /// @param deployer The address which created the token.
    /// @param urlName The urlName, where the created token is sorted in.
    /// @param token The address of the newly created token.
    /// @param factoryVersion The version number of the factory that was used to deploy the contract.
    event TokenDeployed(address indexed deployer, string urlName, address token, uint96 factoryVersion);

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

import "./IFactoryFeature.sol";

/// @title A contract that deploys token vesting contracts for anyone.
interface IMerkleVestingFactoryFeature is IFactoryFeature {
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
    function getDeployedVestings(string calldata urlName) external view returns (DeployData[] memory vestingAddresses);

    /// @notice Event emitted when creating a new vesting contract.
    /// @param deployer The address which created the vesting.
    /// @param urlName The urlName, where the created vesting contract is sorted in.
    /// @param instance The address of the newly created vesting contract.
    /// @param factoryVersion The version number of the factory that was used to deploy the contract.
    event MerkleVestingDeployed(address indexed deployer, string urlName, address instance, uint96 factoryVersion);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../deployables/interfaces/IMerkleNFTMinter.sol";
import "./IFactoryFeature.sol";

/// @title A contract that deploys NFT minter contracts for anyone.
interface IMerkleNFTMinterFactoryFeature is IFactoryFeature {
    /// @notice Deploys a new NFT Minter contract.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @param merkleRoot The root of the merkle tree generated from the distribution list.
    /// @param distributionDuration The time interval while the distribution lasts in seconds.
    /// @param nftMetadata The basic metadata of the NFT that will be created.
    /// @param specificIds If true: the tokenIds, else: the amount of tokens per user will be specified.
    /// @param owner The owner address of the contract to be deployed. Will have special access to some functions.
    function createNFTMinter(
        string calldata urlName,
        bytes32 merkleRoot,
        uint256 distributionDuration,
        IMerkleNFTMinter.NftMetadata memory nftMetadata,
        bool specificIds,
        address owner
    ) external;

    /// @notice Returns all the deployed contract addresses by a specific creator.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @return minterAddresses The requested array of contract addresses.
    function getDeployedNFTMinters(string calldata urlName) external view returns (DeployData[] memory minterAddresses);

    /// @notice Event emitted when creating a new NFT Minter contract.
    /// @param deployer The address which created the NFT Minter.
    /// @param urlName The urlName, where the created NFT Minter contract is sorted in.
    /// @param instance The address of the newly created NFT Minter contract.
    /// @param factoryVersion The version number of the factory that was used to deploy the contract.
    event MerkleNFTMinterDeployed(address indexed deployer, string urlName, address instance, uint96 factoryVersion);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFactoryFeature.sol";

/// @title A contract that deploys token airdrop contracts for anyone.
interface IMerkleDistributorFactoryFeature is IFactoryFeature {
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
    function getDeployedAirdrops(string calldata urlName) external view returns (DeployData[] memory airdropAddresses);

    /// @notice Event emitted when creating a new airdrop contract.
    /// @param deployer The address which created the airdrop.
    /// @param urlName The urlName, where the created airdrop contract is sorted in.
    /// @param instance The address of the newly created airdrop contract.
    /// @param factoryVersion The version number of the factory that was used to deploy the contract.
    event MerkleDistributorDeployed(address indexed deployer, string urlName, address instance, uint96 factoryVersion);
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

/// @title Basic interface for a feature contract.
interface IFeature {
    // solhint-disable func-name-mixedcase

    /// @notice The name of this feature set.
    function FEATURE_NAME() external view returns (string memory name);

    /// @notice The version of this feature set.
    function FEATURE_VERSION() external view returns (uint96 version);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Basic interface for a factory feature contract.
interface IFactoryFeature {
    /// @notice The data belonging to a specific deployed contract.
    /// @param factoryVersion The version number of the factory that was used to deploy the contract.
    /// @param contractAddress The address of the deployed contract.
    struct DeployData {
        uint96 factoryVersion;
        address contractAddress;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title A mintable NFT with auto-incrementing IDs.
contract ERC721MintableAutoId is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public immutable maxSupply;
    string internal cid;
    Counters.Counter private tokenIdCounter;

    error NonExistentToken(uint256 tokenId);
    error TokenIdOutOfBounds();

    constructor(
        string memory name,
        string memory symbol,
        string memory cid_,
        uint256 maxSupply_
    ) ERC721(name, symbol) {
        cid = cid_;
        maxSupply = maxSupply_;
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = tokenIdCounter.current();
        if (tokenId >= maxSupply) revert TokenIdOutOfBounds();
        tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert NonExistentToken(tokenId);
        return string(abi.encodePacked("ipfs://", cid, "/", tokenId.toString(), ".json"));
    }

    function totalSupply() public view returns (uint256) {
        return tokenIdCounter.current();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A mintable NFT.
contract ERC721Mintable is ERC721, Ownable {
    using Strings for uint256;

    uint256 public immutable maxSupply;
    uint256 public totalSupply;
    string internal cid;

    error NonExistentToken(uint256 tokenId);
    error TokenIdOutOfBounds();

    constructor(
        string memory name,
        string memory symbol,
        string memory cid_,
        uint256 maxSupply_
    ) ERC721(name, symbol) {
        cid = cid_;
        maxSupply = maxSupply_;
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        if (tokenId >= maxSupply) revert TokenIdOutOfBounds();
        totalSupply++;
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert NonExistentToken(tokenId);
        return string(abi.encodePacked("ipfs://", cid, "/", tokenId.toString(), ".json"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC20InitialSupply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A mintable ERC20 token.
contract ERC20MintableOwnedMaxSupply is ERC20InitialSupply, Ownable {
    uint256 public immutable maxSupply;

    /// @notice Error thrown when the max supply is attempted to be set lower than the initial supply.
    /// @param maxSupply The desired max supply.
    /// @param initialSupply The desired initial supply, that cannot be higher than the max.
    error MaxSupplyTooLow(uint256 maxSupply, uint256 initialSupply);

    /// @notice Error thrown when more tokens are attempted to be minted than the max supply.
    /// @param amount The amount of tokens attempted to be minted.
    /// @param currentSupply The current supply of the token.
    /// @param maxSupply The max supply of the token.
    error MaxSupplyExceeded(uint256 amount, uint256 currentSupply, uint256 maxSupply);

    constructor(
        string memory name,
        string memory symbol,
        uint8 tokenDecimals,
        address minter,
        uint256 initialSupply,
        uint256 maxSupply_
    ) ERC20InitialSupply(name, symbol, tokenDecimals, minter, initialSupply) {
        if (maxSupply_ < initialSupply) revert MaxSupplyTooLow(maxSupply_, initialSupply);
        maxSupply = maxSupply_;
        transferOwnership(minter);
    }

    /// @notice Mint an amount of tokens to an account.
    /// @param account The address of the account receiving the tokens.
    /// @param amount The amount of tokens the account receives.
    function mint(address account, uint256 amount) public onlyOwner {
        uint256 total = totalSupply();
        if (total + amount > maxSupply) revert MaxSupplyExceeded(amount, total, maxSupply);
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC20InitialSupply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A mintable ERC20 token.
contract ERC20MintableOwned is ERC20InitialSupply, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        uint8 tokenDecimals,
        address minter,
        uint256 initialSupply
    ) ERC20InitialSupply(name, symbol, tokenDecimals, minter, initialSupply) {
        transferOwnership(minter);
    }

    /// @notice Mint an amount of tokens to an account.
    /// @param account The address of the account receiving the tokens.
    /// @param amount The amount of tokens the account receives.
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC20InitialSupply.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title A mintable ERC20 token.
contract ERC20MintableAccessControlledMaxSupply is ERC20InitialSupply, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public immutable maxSupply;

    /// @notice Error thrown when the max supply is attempted to be set lower than the initial supply.
    /// @param maxSupply The desired max supply.
    /// @param initialSupply The desired initial supply, that cannot be higher than the max.
    error MaxSupplyTooLow(uint256 maxSupply, uint256 initialSupply);

    /// @notice Error thrown when more tokens are attempted to be minted than the max supply.
    /// @param amount The amount of tokens attempted to be minted.
    /// @param currentSupply The current supply of the token.
    /// @param maxSupply The max supply of the token.
    error MaxSupplyExceeded(uint256 amount, uint256 currentSupply, uint256 maxSupply);

    constructor(
        string memory name,
        string memory symbol,
        uint8 tokenDecimals,
        address minter,
        uint256 initialSupply,
        uint256 maxSupply_
    ) ERC20InitialSupply(name, symbol, tokenDecimals, minter, initialSupply) {
        if (maxSupply_ < initialSupply) revert MaxSupplyTooLow(maxSupply_, initialSupply);
        maxSupply = maxSupply_;
        _setRoleAdmin(MINTER_ROLE, MINTER_ROLE);
        _grantRole(MINTER_ROLE, minter);
    }

    /// @notice Mint an amount of tokens to an account.
    /// @param account The address of the account receiving the tokens.
    /// @param amount The amount of tokens the account receives.
    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        uint256 total = totalSupply();
        if (total + amount > maxSupply) revert MaxSupplyExceeded(amount, total, maxSupply);
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC20InitialSupply.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title A mintable ERC20 token.
contract ERC20MintableAccessControlled is ERC20InitialSupply, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        uint8 tokenDecimals,
        address minter,
        uint256 initialSupply
    ) ERC20InitialSupply(name, symbol, tokenDecimals, minter, initialSupply) {
        _setRoleAdmin(MINTER_ROLE, MINTER_ROLE);
        _grantRole(MINTER_ROLE, minter);
    }

    /// @notice Mint an amount of tokens to an account.
    /// @param account The address of the account receiving the tokens.
    /// @param amount The amount of tokens the account receives.
    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title An ERC20 token with initial supply.
contract ERC20InitialSupply is ERC20 {
    uint8 private _tokenDecimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 tokenDecimals,
        address owner,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _tokenDecimals = tokenDecimals;
        if (initialSupply > 0) _mint(owner, initialSupply);
    }

    /// @dev See {ERC20-decimals}
    function decimals() public view override returns (uint8) {
        return _tokenDecimals;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*

    The file was modified by Agora.
    2022 agora.xyz

*/

pragma solidity ^0.8.0;

/// @title Allows anyone to claim a token if they exist in a merkle root, but only over time.
interface IMerkleVesting {
    /// @notice The struct holding a specific cohort's data and the individual claim statuses.
    /// @param data The struct holding a specific cohort's data.
    /// @param claims Stores the amount of claimed funds per address.
    /// @param disabledState A packed array of booleans. If true, the individual user cannot claim anymore.
    struct Cohort {
        CohortData data;
        mapping(address => uint256) claims;
        mapping(uint256 => uint256) disabledState;
    }

    /// @notice The struct holding a specific cohort's data.
    /// @param merkleRoot The merkle root of the merkle tree containing account balances available to claim.
    /// @param distributionEnd The unix timestamp that marks the end of the token distribution.
    /// @param vestingEnd The unix timestamp that marks the end of the vesting period.
    /// @param vestingPeriod The length of the vesting period in seconds.
    /// @param cliffPeriod The length of the cliff period in seconds.
    struct CohortData {
        bytes32 merkleRoot;
        uint64 distributionEnd;
        uint64 vestingEnd;
        uint64 vestingPeriod;
        uint64 cliffPeriod;
    }

    /// @notice Returns the address of the token distributed by this contract.
    function token() external view returns (address);

    /// @notice Returns the id/Merkle root of the cohort ending at the latest.
    function lastEndingCohort() external view returns (bytes32);

    /// @notice Returns the parameters of a specific cohort.
    /// @param cohortId The Merkle root of the cohort.
    function getCohort(bytes32 cohortId) external view returns (CohortData memory);

    /// @notice Returns the amount of funds an account can claim at the moment.
    /// @param cohortId The Merkle root of the cohort.
    /// @param index A value from the generated input list.
    /// @param account The address of the account to query.
    /// @param fullAmount The full amount of funds the account can claim.
    function getClaimableAmount(
        bytes32 cohortId,
        uint256 index,
        address account,
        uint256 fullAmount
    ) external view returns (uint256);

    /// @notice Returns the amount of funds an account has claimed.
    /// @param cohortId The Merkle root of the cohort.
    /// @param account The address of the account to query.
    function getClaimed(bytes32 cohortId, address account) external view returns (uint256);

    /// @notice Check if the address in a cohort at the index is excluded from the vesting.
    /// @param cohortId The Merkle root of the cohort.
    /// @param index A value from the generated input list.
    function isDisabled(bytes32 cohortId, uint256 index) external view returns (bool);

    /// @notice Exclude the address in a cohort at the index from the vesting.
    /// @param cohortId The Merkle root of the cohort.
    /// @param index A value from the generated input list.
    function setDisabled(bytes32 cohortId, uint256 index) external;

    /// @notice Allows the owner to add a new cohort.
    /// @param merkleRoot The Merkle root of the cohort. It will also serve as the cohort's ID.
    /// @param distributionDuration The length of the token distribtion period in seconds.
    /// @param vestingPeriod The length of the vesting period of the tokens in seconds.
    /// @param cliffPeriod The length of the cliff period in seconds.
    function addCohort(
        bytes32 merkleRoot,
        uint256 distributionDuration,
        uint64 vestingPeriod,
        uint64 cliffPeriod
    ) external;

    /// @notice Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    /// @param cohortId The Merkle root of the cohort.
    /// @param index A value from the generated input list.
    /// @param account A value from the generated input list.
    /// @param amount A value from the generated input list (so the full amount).
    /// @param merkleProof A an array of values from the generated input list.
    function claim(
        bytes32 cohortId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    /// @notice Allows the owner to reclaim the tokens after the distribution has ended.
    /// @param recipient The address receiving the tokens.
    function withdraw(address recipient) external;

    /// @notice This event is triggered whenever a call to #addCohort succeeds.
    /// @param cohortId The Merkle root of the cohort.
    event CohortAdded(bytes32 cohortId);

    /// @notice This event is triggered whenever a call to #claim succeeds.
    /// @param cohortId The Merkle root of the cohort.
    /// @param account The address that claimed the tokens.
    /// @param amount The amount of tokens the address received.
    event Claimed(bytes32 cohortId, address account, uint256 amount);

    /// @notice This event is triggered whenever a call to #withdraw succeeds.
    /// @param account The address that received the tokens.
    /// @param amount The amount of tokens the address received.
    event Withdrawn(address account, uint256 amount);

    /// @notice Error thrown when there's nothing to withdraw.
    error AlreadyWithdrawn();

    /// @notice Error thrown when a cohort with the provided id does not exist.
    error CohortDoesNotExist();

    /// @notice Error thrown when the distribution period ended.
    /// @param current The current timestamp.
    /// @param end The time when the distribution ended.
    error DistributionEnded(uint256 current, uint256 end);

    /// @notice Error thrown when the cliff period is not over yet.
    /// @param cliff The time when the cliff period ends.
    /// @param timestamp The current timestamp.
    error CliffNotReached(uint256 cliff, uint256 timestamp);

    /// @notice Error thrown when the distribution period did not end yet.
    /// @param current The current timestamp.
    /// @param end The time when the distribution ends.
    error DistributionOngoing(uint256 current, uint256 end);

    /// @notice Error thrown when the Merkle proof is invalid.
    error InvalidProof();

    /// @notice Error thrown when a transfer failed.
    /// @param token The address of token attempted to be transferred.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    error TransferFailed(address token, address from, address to);

    /// @notice Error thrown when a function receives invalid parameters.
    error InvalidParameters();

    /// @notice Error thrown when a cohort with an already existing merkle tree is attempted to be added.
    error MerkleRootCollision();

    /// @notice Error thrown when the input address has been excluded from the vesting.
    /// @param cohortId The Merkle root of the cohort.
    /// @param account The address that does not satisfy the requirements.
    error NotInVesting(bytes32 cohortId, address account);
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*

    The file was modified by Agora.
    2022 agora.xyz

*/

pragma solidity ^0.8.0;

/// @title Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleNFTMinter {
    /// @notice The metadata of the NFT to be created.
    /// @notice The name of the NFT to be created.
    /// @notice The symbol of the NFT to be created.
    /// @notice The maximum number of the tokens that can be created.
    struct NftMetadata {
        string name;
        string symbol;
        string ipfsHash;
        uint256 maxSupply;
    }

    /// @notice Returns the address of the token distributed by this contract.
    function token() external view returns (address);

    /// @notice Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);

    /// @notice Returns the unix timestamp that marks the end of the token distribution.
    function distributionEnd() external view returns (uint256);

    /// @notice Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    /// @param index A value from the generated input list.
    /// @param account A value from the generated input list.
    /// @param amount A value from the generated input list.
    /// @param merkleProof A an array of values from the generated input list.
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    /// @notice Allows the owner to claim the ownership of the token after the distribution has ended or all tokens are claimed.
    /// @param recipient The address receiving the tokens.
    function withdraw(address recipient) external;

    /// @notice This event is triggered whenever a call to #claim succeeds.
    /// @param index A value from the generated input list.
    /// @param account A value from the generated input list.
    event Claimed(uint256 index, address account);

    /// @notice This event is triggered whenever a call to #withdraw succeeds.
    /// @param token The address of the token the address received.
    /// @param account The address that received the tokens.
    event Withdrawn(address token, address account);

    /// @notice Error thrown when the distribution period ended.
    /// @param current The current timestamp.
    /// @param end The time when the distribution ended.
    error DistributionEnded(uint256 current, uint256 end);

    /// @notice Error thrown when the distribution period did not end yet.
    /// @param current The current timestamp.
    /// @param end The time when the distribution ends.
    /// @param remainingNfts The number of NFTs unclaimed.
    error DistributionOngoing(uint256 current, uint256 end, uint256 remainingNfts);

    /// @notice Error thrown when the drop is already claimed.
    error DropClaimed();

    /// @notice Error thrown when the Merkle proof is invalid.
    error InvalidProof();
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*

    The file was modified by Agora.
    2022 agora.xyz

*/

pragma solidity ^0.8.0;

/// @title Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    /// @notice Returns the address of the token distributed by this contract.
    function token() external view returns (address);

    /// @notice Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);

    /// @notice Returns the unix timestamp that marks the end of the token distribution.
    function distributionEnd() external view returns (uint256);

    /// @notice Returns true if the index has been marked claimed.
    /// @param index A value from the generated input list.
    function isClaimed(uint256 index) external view returns (bool);

    /// @notice Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    /// @param index A value from the generated input list.
    /// @param account A value from the generated input list.
    /// @param amount A value from the generated input list.
    /// @param merkleProof A an array of values from the generated input list.
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    /// @notice Allows the owner to reclaim the tokens after the distribution has ended.
    /// @param recipient The address receiving the tokens.
    function withdraw(address recipient) external;

    /// @notice This event is triggered whenever a call to #claim succeeds.
    /// @param index A value from the generated input list.
    /// @param account A value from the generated input list.
    /// @param amount A value from the generated input list.
    event Claimed(uint256 index, address account, uint256 amount);

    /// @notice This event is triggered whenever a call to #withdraw succeeds.
    /// @param account The address that received the tokens.
    /// @param amount The amount of tokens the address received.
    event Withdrawn(address account, uint256 amount);

    /// @notice Error thrown when there's nothing to withdraw.
    error AlreadyWithdrawn();

    /// @notice Error thrown when the distribution period ended.
    /// @param current The current timestamp.
    /// @param end The time when the distribution ended.
    error DistributionEnded(uint256 current, uint256 end);

    /// @notice Error thrown when the distribution period did not end yet.
    /// @param current The current timestamp.
    /// @param end The time when the distribution ends.
    error DistributionOngoing(uint256 current, uint256 end);

    /// @notice Error thrown when the drop is already claimed.
    error DropClaimed();

    /// @notice Error thrown when the Merkle proof is invalid.
    error InvalidProof();

    /// @notice Error thrown when a transfer failed.
    /// @param token The address of token attempted to be transferred.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    error TransferFailed(address token, address from, address to);
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*

    The file was modified by Agora.
    2022 agora.xyz

*/

pragma solidity 0.8.13;

import "./interfaces/IMerkleVesting.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract MerkleVesting is IMerkleVesting, Multicall, Ownable {
    address public immutable token;
    bytes32 public lastEndingCohort;

    mapping(bytes32 => Cohort) internal cohorts;

    constructor(address token_, address owner) {
        token = token_;
        transferOwnership(owner);
    }

    function getCohort(bytes32 cohortId) external view returns (CohortData memory) {
        return cohorts[cohortId].data;
    }

    function getClaimableAmount(
        bytes32 cohortId,
        uint256 index,
        address account,
        uint256 fullAmount
    ) public view returns (uint256) {
        Cohort storage cohort = cohorts[cohortId];
        uint256 claimedSoFar = cohort.claims[account];
        uint256 vestingEnd = cohort.data.vestingEnd;
        uint256 vestingStart = vestingEnd - cohort.data.vestingPeriod;
        uint256 cliff = vestingStart + cohort.data.cliffPeriod;
        if (isDisabled(cohortId, index)) revert NotInVesting(cohortId, account);
        if (block.timestamp < cliff) revert CliffNotReached(cliff, block.timestamp);
        else if (block.timestamp < vestingEnd)
            return (fullAmount * (block.timestamp - vestingStart)) / cohort.data.vestingPeriod - claimedSoFar;
        else return fullAmount - claimedSoFar;
    }

    function getClaimed(bytes32 cohortId, address account) public view returns (uint256) {
        return cohorts[cohortId].claims[account];
    }

    function isDisabled(bytes32 cohortId, uint256 index) public view returns (bool) {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        uint256 word = cohorts[cohortId].disabledState[wordIndex];
        uint256 mask = (1 << bitIndex);
        return word & mask == mask;
    }

    function setDisabled(bytes32 cohortId, uint256 index) external onlyOwner {
        uint256 wordIndex = index / 256;
        uint256 bitIndex = index % 256;
        cohorts[cohortId].disabledState[wordIndex] = cohorts[cohortId].disabledState[wordIndex] | (1 << bitIndex);
    }

    function addCohort(
        bytes32 merkleRoot,
        uint256 distributionDuration,
        uint64 vestingPeriod,
        uint64 cliffPeriod
    ) external onlyOwner {
        if (
            merkleRoot == bytes32(0) ||
            distributionDuration == 0 ||
            vestingPeriod == 0 ||
            distributionDuration < vestingPeriod ||
            distributionDuration < cliffPeriod ||
            vestingPeriod < cliffPeriod
        ) revert InvalidParameters();
        if (cohorts[merkleRoot].data.merkleRoot != bytes32(0)) revert MerkleRootCollision();

        uint256 distributionEnd = block.timestamp + distributionDuration;
        if (distributionEnd > cohorts[lastEndingCohort].data.distributionEnd) lastEndingCohort = merkleRoot;

        cohorts[merkleRoot].data.merkleRoot = merkleRoot;
        cohorts[merkleRoot].data.distributionEnd = uint64(distributionEnd);
        cohorts[merkleRoot].data.vestingEnd = uint64(block.timestamp + vestingPeriod);
        cohorts[merkleRoot].data.vestingPeriod = vestingPeriod;
        cohorts[merkleRoot].data.cliffPeriod = cliffPeriod;

        emit CohortAdded(merkleRoot);
    }

    function claim(
        bytes32 cohortId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (cohorts[cohortId].data.merkleRoot == bytes32(0)) revert CohortDoesNotExist();
        Cohort storage cohort = cohorts[cohortId];
        uint256 distributionEndLocal = cohort.data.distributionEnd;
        if (block.timestamp > distributionEndLocal) revert DistributionEnded(block.timestamp, distributionEndLocal);

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        if (!MerkleProof.verify(merkleProof, cohort.data.merkleRoot, node)) revert InvalidProof();

        // Calculate the claimable amount and update the claimed amount on storage.
        uint256 claimableAmount = getClaimableAmount(cohortId, index, account, amount);
        cohort.claims[account] += claimableAmount;

        // Send the token.
        if (!IERC20(token).transfer(account, claimableAmount)) revert TransferFailed(token, address(this), account);

        emit Claimed(cohortId, account, claimableAmount);
    }

    function withdraw(address recipient) external onlyOwner {
        uint256 distributionEndLocal = cohorts[lastEndingCohort].data.distributionEnd;
        if (block.timestamp <= distributionEndLocal) revert DistributionOngoing(block.timestamp, distributionEndLocal);
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) revert AlreadyWithdrawn();
        if (!IERC20(token).transfer(recipient, balance)) revert TransferFailed(token, address(this), recipient);
        emit Withdrawn(recipient, balance);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*

    The file was modified by Agora.
    2022 agora.xyz

*/

pragma solidity 0.8.13;

import "./interfaces/IMerkleNFTMinter.sol";
import "./token/ERC721/ERC721MintableAutoId.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleNFTMinterAutoId is IMerkleNFTMinter, Ownable {
    address public immutable token;
    bytes32 public immutable merkleRoot;
    uint256 public immutable distributionEnd;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(
        bytes32 merkleRoot_,
        uint256 distributionDuration,
        NftMetadata memory nftMetadata,
        address owner
    ) {
        merkleRoot = merkleRoot_;
        distributionEnd = block.timestamp + distributionDuration;

        token = address(
            new ERC721MintableAutoId(nftMetadata.name, nftMetadata.symbol, nftMetadata.ipfsHash, nftMetadata.maxSupply)
        );

        transferOwnership(owner);
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (block.timestamp > distributionEnd) revert DistributionEnded(block.timestamp, distributionEnd);
        if (isClaimed(index)) revert DropClaimed();

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) revert InvalidProof();

        // Mark it claimed and mint the token(s).
        _setClaimed(index);
        for (uint256 i = 1; i <= amount; ) {
            ERC721MintableAutoId(token).safeMint(account);
            unchecked {
                ++i;
            }
        }

        emit Claimed(index, account);
    }

    function withdraw(address newOwner) external onlyOwner {
        ERC721MintableAutoId nft = ERC721MintableAutoId(token);
        uint256 remainingNfts = nft.maxSupply() - nft.totalSupply();
        if (block.timestamp <= distributionEnd && remainingNfts > 0)
            revert DistributionOngoing(block.timestamp, distributionEnd, remainingNfts);
        nft.transferOwnership(newOwner);
        emit Withdrawn(token, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*

    The file was modified by Agora.
    2022 agora.xyz

*/

pragma solidity 0.8.13;

import "./interfaces/IMerkleNFTMinter.sol";
import "./token/ERC721/ERC721Mintable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleNFTMinter is IMerkleNFTMinter, Ownable {
    address public immutable token;
    bytes32 public immutable merkleRoot;
    uint256 public immutable distributionEnd;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(
        bytes32 merkleRoot_,
        uint256 distributionDuration,
        NftMetadata memory nftMetadata,
        address owner
    ) {
        merkleRoot = merkleRoot_;
        distributionEnd = block.timestamp + distributionDuration;

        token = address(
            new ERC721Mintable(nftMetadata.name, nftMetadata.symbol, nftMetadata.ipfsHash, nftMetadata.maxSupply)
        );

        transferOwnership(owner);
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 tokenId,
        bytes32[] calldata merkleProof
    ) external {
        if (block.timestamp > distributionEnd) revert DistributionEnded(block.timestamp, distributionEnd);
        if (isClaimed(index)) revert DropClaimed();

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, tokenId));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) revert InvalidProof();

        // Mark it claimed and mint the token.
        _setClaimed(index);
        ERC721Mintable(token).safeMint(account, tokenId);

        emit Claimed(index, account);
    }

    function withdraw(address newOwner) external onlyOwner {
        ERC721Mintable nft = ERC721Mintable(token);
        uint256 remainingNfts = nft.maxSupply() - nft.totalSupply();
        if (block.timestamp <= distributionEnd && remainingNfts > 0)
            revert DistributionOngoing(block.timestamp, distributionEnd, remainingNfts);
        nft.transferOwnership(newOwner);
        emit Withdrawn(token, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*

    The file was modified by Agora.
    2022 agora.xyz

*/

pragma solidity 0.8.13;

import "./interfaces/IMerkleDistributor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleDistributor is IMerkleDistributor, Ownable {
    address public immutable token;
    bytes32 public immutable merkleRoot;
    uint256 public immutable distributionEnd;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(
        address token_,
        bytes32 merkleRoot_,
        uint256 distributionDuration,
        address owner
    ) {
        token = token_;
        merkleRoot = merkleRoot_;
        distributionEnd = block.timestamp + distributionDuration;
        transferOwnership(owner);
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (block.timestamp > distributionEnd) revert DistributionEnded(block.timestamp, distributionEnd);
        if (isClaimed(index)) revert DropClaimed();

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) revert InvalidProof();

        // Mark it claimed and send the token.
        _setClaimed(index);
        if (!IERC20(token).transfer(account, amount)) revert TransferFailed(token, address(this), account);

        emit Claimed(index, account, amount);
    }

    // Allows the owner to reclaim the tokens deposited in this contract.
    function withdraw(address recipient) external onlyOwner {
        if (block.timestamp <= distributionEnd) revert DistributionOngoing(block.timestamp, distributionEnd);
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) revert AlreadyWithdrawn();
        if (!IERC20(token).transfer(recipient, balance)) revert TransferFailed(token, address(this), recipient);
        emit Withdrawn(recipient, balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/ITokenWithRolesFactoryFeature.sol";
import "./deployables/token/ERC20/ERC20MintableAccessControlled.sol";
import "./deployables/token/ERC20/ERC20MintableAccessControlledMaxSupply.sol";
import "../fixins/FixinCommon.sol";
import "../storage/LibTokenFactoryStorage.sol";
import "../migrations/LibMigrate.sol";
import "./interfaces/IFeature.sol";

/// @title A contract that deploys ERC20 token contracts with OpenZeppelin's AccessControl for anyone.
contract TokenWithRolesFactoryFeature is IFeature, ITokenWithRolesFactoryFeature, FixinCommon {
    /// @notice Name of this feature.
    string public constant FEATURE_NAME = "TokenWithRolesFactory";
    /// @notice Version of this feature.
    uint96 public immutable FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @notice Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.createTokenWithRoles.selector);
        _registerFeatureFunction(this.getDeployedTokens.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @notice Deploys a new ERC20 token contract.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @param tokenName The token's name.
    /// @param tokenSymbol The token's symbol.
    /// @param tokenDecimals The token's number of decimals.
    /// @param initialSupply The initial amount of tokens to mint.
    /// @param maxSupply The maximum amount of tokens that can ever be minted. Unlimited if set to zero.
    /// @param firstOwner The first address to assign ownership/minting rights to (if mintable). The recipient of the initial supply.
    // prettier-ignore
    function createTokenWithRoles(
        string calldata urlName,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 tokenDecimals,
        uint256 initialSupply,
        uint256 maxSupply,
        address firstOwner
    ) external {
        address token;

        /*
            mintable: initialSupply < maxSupply or either of them is 0
            non-mintable: initialSupply = maxSupply (i.e. fixed supply)
            otherwise revert
        */
        if (initialSupply == 0 || maxSupply == 0 || initialSupply < maxSupply)
            if (maxSupply > 0)
                token = address(
                    new ERC20MintableAccessControlledMaxSupply(
                        tokenName,
                        tokenSymbol,
                        tokenDecimals,
                        firstOwner,
                        initialSupply,
                        maxSupply
                    )
                );
            else
                token = address(
                    new ERC20MintableAccessControlled(
                        tokenName,
                        tokenSymbol,
                        tokenDecimals,
                        firstOwner,
                        initialSupply
                    )
                );
        else if (initialSupply == maxSupply)
            token = address(
                new ERC20InitialSupply(
                    tokenName,
                    tokenSymbol,
                    tokenDecimals,
                    firstOwner,
                    initialSupply
                )
            );
        else revert MaxSupplyTooLow(maxSupply, initialSupply);
        LibTokenFactoryStorage.getStorage().deploys[urlName].push(
            DeployData({factoryVersion: FEATURE_VERSION, contractAddress: token})
        );
        emit TokenDeployed(msg.sender, urlName, token, FEATURE_VERSION);
    }

    /// @notice Returns all the deployed token addresses by a specific creator.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @return tokenAddresses The requested array of tokens addresses.
    function getDeployedTokens(string calldata urlName) external view returns (DeployData[] memory tokenAddresses) {
        return LibTokenFactoryStorage.getStorage().deploys[urlName];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/ITokenFactoryFeature.sol";
import "./deployables/token/ERC20/ERC20MintableOwned.sol";
import "./deployables/token/ERC20/ERC20MintableOwnedMaxSupply.sol";
import "../fixins/FixinCommon.sol";
import "../storage/LibTokenFactoryStorage.sol";
import "../migrations/LibMigrate.sol";
import "./interfaces/IFeature.sol";

/// @title A contract that deploys ERC20 token contracts for anyone.
contract TokenFactoryFeature is IFeature, ITokenFactoryFeature, FixinCommon {
    /// @notice Name of this feature.
    string public constant FEATURE_NAME = "TokenFactory";
    /// @notice Version of this feature.
    uint96 public immutable FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @notice Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.createToken.selector);
        _registerFeatureFunction(this.getDeployedTokens.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @notice Deploys a new ERC20 token contract.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @param tokenName The token's name.
    /// @param tokenSymbol The token's symbol.
    /// @param tokenDecimals The token's number of decimals.
    /// @param initialSupply The initial amount of tokens to mint.
    /// @param maxSupply The maximum amount of tokens that can ever be minted. Unlimited if set to zero.
    /// @param firstOwner The first address to assign ownership/minting rights to (if mintable). The recipient of the initial supply.
    // prettier-ignore
    function createToken(
        string calldata urlName,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 tokenDecimals,
        uint256 initialSupply,
        uint256 maxSupply,
        address firstOwner
    ) external {
        address token;

        /*
            mintable: initialSupply < maxSupply or either of them is 0
            non-mintable: initialSupply = maxSupply (i.e. fixed supply)
            otherwise revert
        */
        if (initialSupply == 0 || maxSupply == 0 || initialSupply < maxSupply)
            if (maxSupply > 0)
                token = address(
                    new ERC20MintableOwnedMaxSupply(
                        tokenName,
                        tokenSymbol,
                        tokenDecimals,
                        firstOwner,
                        initialSupply,
                        maxSupply
                    )
                );
            else
                token = address(
                    new ERC20MintableOwned(
                        tokenName,
                        tokenSymbol,
                        tokenDecimals,
                        firstOwner,
                        initialSupply
                    )
                );
        else if (initialSupply == maxSupply)
            token = address(
                new ERC20InitialSupply(
                    tokenName,
                    tokenSymbol,
                    tokenDecimals,
                    firstOwner,
                    initialSupply
                )
            );
        else revert MaxSupplyTooLow(maxSupply, initialSupply);
        LibTokenFactoryStorage.getStorage().deploys[urlName].push(
            DeployData({factoryVersion: FEATURE_VERSION, contractAddress: token})
        );
        emit TokenDeployed(msg.sender, urlName, token, FEATURE_VERSION);
    }

    /// @notice Returns all the deployed token addresses by a specific creator.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @return tokenAddresses The requested array of tokens addresses.
    function getDeployedTokens(string calldata urlName) external view returns (DeployData[] memory tokenAddresses) {
        return LibTokenFactoryStorage.getStorage().deploys[urlName];
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

pragma solidity 0.8.13;

import "../fixins/FixinCommon.sol";
import "../storage/LibProxyStorage.sol";
import "../storage/LibSimpleFunctionRegistryStorage.sol";
import "../migrations/LibBootstrap.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/ISimpleFunctionRegistryFeature.sol";

/// @title Basic registry management features.
contract SimpleFunctionRegistryFeature is IFeature, ISimpleFunctionRegistryFeature, FixinCommon {
    /// @notice Name of this feature.
    string public constant FEATURE_NAME = "SimpleFunctionRegistry";
    /// @notice Version of this feature.
    uint96 public immutable FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @notice Initializes this feature, registering its own functions.
    /// @return success Magic bytes if successful.
    function bootstrap() external returns (bytes4 success) {
        // Register the registration functions (inception vibes).
        _extend(this.extend.selector, _implementation);
        _extend(this._extendSelf.selector, _implementation);
        // Register the rollback function.
        _extend(this.rollback.selector, _implementation);
        // Register getters.
        _extend(this.getRollbackLength.selector, _implementation);
        _extend(this.getRollbackEntryAtIndex.selector, _implementation);
        return LibBootstrap.BOOTSTRAP_SUCCESS;
    }

    /// @notice Roll back to a prior implementation of a function.
    ///      Only directly callable by an authority.
    /// @param selector The function selector.
    /// @param targetImpl The address of an older implementation of the function.
    function rollback(bytes4 selector, address targetImpl) external override onlyOwner {
        (
            LibSimpleFunctionRegistryStorage.Storage storage stor,
            LibProxyStorage.Storage storage proxyStor
        ) = _getStorages();

        address currentImpl = proxyStor.impls[selector];
        if (currentImpl == targetImpl) {
            // Do nothing if already at targetImpl.
            return;
        }
        // Walk history backwards until we find the target implementation.
        address[] storage history = stor.implHistory[selector];
        uint256 i = history.length;
        for (; i > 0; --i) {
            address impl = history[i - 1];
            history.pop();
            if (impl == targetImpl) {
                break;
            }
        }
        if (i == 0) revert NotInRollbackHistory(selector, targetImpl);
        proxyStor.impls[selector] = targetImpl;
        emit ProxyFunctionUpdated(selector, currentImpl, targetImpl);
    }

    /// @notice Register or replace a function.
    ///      Only directly callable by an authority.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function extend(bytes4 selector, address impl) external override onlyOwner {
        _extend(selector, impl);
    }

    /// @notice Register or replace a function.
    ///      Only callable from within.
    ///      This function is only used during the bootstrap process and
    ///      should be deregistered by the deployer after bootstrapping is
    ///      complete.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function _extendSelf(bytes4 selector, address impl) external onlySelf {
        _extend(selector, impl);
    }

    /// @notice Retrieve the length of the rollback history for a function.
    /// @param selector The function selector.
    /// @return rollbackLength The number of items in the rollback history for
    ///         the function.
    function getRollbackLength(bytes4 selector) external view override returns (uint256 rollbackLength) {
        return LibSimpleFunctionRegistryStorage.getStorage().implHistory[selector].length;
    }

    /// @notice Retrieve an entry in the rollback history for a function.
    /// @param selector The function selector.
    /// @param idx The index in the rollback history.
    /// @return impl An implementation address for the function at
    ///         index `idx`.
    function getRollbackEntryAtIndex(bytes4 selector, uint256 idx) external view override returns (address impl) {
        return LibSimpleFunctionRegistryStorage.getStorage().implHistory[selector][idx];
    }

    /// @notice Register or replace a function.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function _extend(bytes4 selector, address impl) private {
        (
            LibSimpleFunctionRegistryStorage.Storage storage stor,
            LibProxyStorage.Storage storage proxyStor
        ) = _getStorages();

        address oldImpl = proxyStor.impls[selector];
        address[] storage history = stor.implHistory[selector];
        history.push(oldImpl);
        proxyStor.impls[selector] = impl;
        emit ProxyFunctionUpdated(selector, oldImpl, impl);
    }

    /// @notice Get the storage buckets for this feature and the proxy.
    /// @return stor Storage bucket for this feature.
    /// @return proxyStor age bucket for the proxy.
    function _getStorages()
        private
        pure
        returns (LibSimpleFunctionRegistryStorage.Storage storage stor, LibProxyStorage.Storage storage proxyStor)
    {
        return (LibSimpleFunctionRegistryStorage.getStorage(), LibProxyStorage.getStorage());
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

pragma solidity 0.8.13;

import "../fixins/FixinCommon.sol";
import "../storage/LibOwnableStorage.sol";
import "../migrations/LibBootstrap.sol";
import "../migrations/LibMigrate.sol";
import "./interfaces/IFeature.sol";
import "./interfaces/IOwnableFeature.sol";
import "./SimpleFunctionRegistryFeature.sol";

/// @title Owner management features.
contract OwnableFeature is IFeature, IOwnableFeature, FixinCommon {
    /// @notice Name of this feature.
    string public constant FEATURE_NAME = "Ownable";
    /// @notice Version of this feature.
    uint96 public immutable FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @notice Initializes this feature. The intial owner will be set to this (TokenXyz)
    ///      to allow the bootstrappers to call `extend()`. Ownership should be
    ///      transferred to the real owner by the bootstrapper after
    ///      bootstrapping is complete.
    /// @return success Magic bytes if successful.
    function bootstrap() external returns (bytes4 success) {
        // Set the owner to ourselves to allow bootstrappers to call `extend()`.
        LibOwnableStorage.getStorage().owner = address(this);

        // Register feature functions.
        SimpleFunctionRegistryFeature(address(this))._extendSelf(this.transferOwnership.selector, _implementation);
        SimpleFunctionRegistryFeature(address(this))._extendSelf(this.owner.selector, _implementation);
        SimpleFunctionRegistryFeature(address(this))._extendSelf(this.migrate.selector, _implementation);
        return LibBootstrap.BOOTSTRAP_SUCCESS;
    }

    /// @notice Change the owner of this contract.
    ///      Only directly callable by the owner.
    /// @param newOwner New owner address.
    function transferOwnership(address newOwner) external override onlyOwner {
        LibOwnableStorage.Storage storage proxyStor = LibOwnableStorage.getStorage();

        if (newOwner == address(0)) {
            revert TransferOwnerToZero();
        } else {
            proxyStor.owner = newOwner;
            emit OwnershipTransferred(msg.sender, newOwner);
        }
    }

    /// @notice Execute a migration function in the context of the TokenXyz contract.
    ///      The result of the function being called should be the magic bytes
    ///      0x2c64c5ef (`keccack('MIGRATE_SUCCESS')`). Only callable by the owner.
    ///      Temporarily sets the owner to ourselves so we can perform admin functions.
    ///      Before returning, the owner will be set to `newOwner`.
    /// @param target The migrator contract address.
    /// @param data The call data.
    /// @param newOwner The address of the new owner.
    function migrate(
        address target,
        bytes calldata data,
        address newOwner
    ) external override onlyOwner {
        if (newOwner == address(0)) revert TransferOwnerToZero();

        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        // The owner will be temporarily set to `address(this)` inside the call.
        stor.owner = address(this);

        // Perform the migration.
        LibMigrate.delegatecallMigrateFunction(target, data);

        // Update the owner.
        stor.owner = newOwner;

        emit Migrated(msg.sender, target, newOwner);
    }

    /// @notice Get the owner of this contract.
    /// @return owner_ The owner of this contract.
    function owner() external view override returns (address owner_) {
        return LibOwnableStorage.getStorage().owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../fixins/FixinCommon.sol";
import "../migrations/LibMigrate.sol";
import "./interfaces/IFeature.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/// @title Provides a function to batch together multiple calls in a single external call.
contract MulticallFeature is IFeature, FixinCommon, Multicall {
    /// @notice Name of this feature.
    string public constant FEATURE_NAME = "Multicall";
    /// @notice Version of this feature.
    uint96 public immutable FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @notice Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.multicall.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IMerkleVestingFactoryFeature.sol";
import "./deployables/MerkleVesting.sol";
import "../fixins/FixinCommon.sol";
import "../storage/LibMerkleVestingFactoryStorage.sol";
import "../migrations/LibMigrate.sol";
import "./interfaces/IFeature.sol";

/// @title A contract that deploys token vesting contracts for anyone.
contract MerkleVestingFactoryFeature is IFeature, IMerkleVestingFactoryFeature, FixinCommon {
    /// @notice Name of this feature.
    string public constant FEATURE_NAME = "MerkleVestingFactory";
    /// @notice Version of this feature.
    uint96 public immutable FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @notice Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.createVesting.selector);
        _registerFeatureFunction(this.getDeployedVestings.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @notice Deploys a new Merkle Vesting contract.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @param token The address of the token to distribute.
    /// @param owner The owner address of the contract to be deployed. Will have special access to some functions.
    function createVesting(
        string calldata urlName,
        address token,
        address owner
    ) external {
        address instance = address(new MerkleVesting(token, owner));
        LibMerkleVestingFactoryStorage.getStorage().deploys[urlName].push(
            DeployData({factoryVersion: FEATURE_VERSION, contractAddress: instance})
        );
        emit MerkleVestingDeployed(msg.sender, urlName, instance, FEATURE_VERSION);
    }

    /// @notice Returns all the deployed vesting contract addresses by a specific creator.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @return vestingAddresses The requested array of contract addresses.
    function getDeployedVestings(string calldata urlName) external view returns (DeployData[] memory vestingAddresses) {
        return LibMerkleVestingFactoryStorage.getStorage().deploys[urlName];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IMerkleNFTMinterFactoryFeature.sol";
import "./deployables/MerkleNFTMinter.sol";
import "./deployables/MerkleNFTMinterAutoId.sol";
import "../fixins/FixinCommon.sol";
import "../storage/LibMerkleNFTMinterFactoryStorage.sol";
import "../migrations/LibMigrate.sol";
import "./interfaces/IFeature.sol";

/// @title A contract that deploys NFT Minter contracts for anyone.
contract MerkleNFTMinterFactoryFeature is IFeature, IMerkleNFTMinterFactoryFeature, FixinCommon {
    /// @notice Name of this feature.
    string public constant FEATURE_NAME = "MerkleNFTMinterFactory";
    /// @notice Version of this feature.
    uint96 public immutable FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @notice Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.createNFTMinter.selector);
        _registerFeatureFunction(this.getDeployedNFTMinters.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @notice Deploys a new NFT Minter contract.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @param merkleRoot The root of the merkle tree generated from the distribution list.
    /// @param distributionDuration The time interval while the distribution lasts in seconds.
    /// @param nftMetadata The basic metadata of the NFT that will be created.
    /// @param specificIds If true: the tokenIds, else: the amount of tokens per user will be specified.
    /// @param owner The owner address of the contract to be deployed. Will have special access to some functions.
    function createNFTMinter(
        string calldata urlName,
        bytes32 merkleRoot,
        uint256 distributionDuration,
        IMerkleNFTMinter.NftMetadata memory nftMetadata,
        bool specificIds,
        address owner
    ) external {
        address instance;
        if (specificIds) instance = address(new MerkleNFTMinter(merkleRoot, distributionDuration, nftMetadata, owner));
        else instance = address(new MerkleNFTMinterAutoId(merkleRoot, distributionDuration, nftMetadata, owner));
        LibMerkleNFTMinterFactoryStorage.getStorage().deploys[urlName].push(
            DeployData({factoryVersion: FEATURE_VERSION, contractAddress: instance})
        );
        emit MerkleNFTMinterDeployed(msg.sender, urlName, instance, FEATURE_VERSION);
    }

    /// @notice Returns all the deployed contract addresses by a specific creator.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @return minterAddresses The requested array of contract addresses.
    function getDeployedNFTMinters(string calldata urlName)
        external
        view
        returns (DeployData[] memory minterAddresses)
    {
        return LibMerkleNFTMinterFactoryStorage.getStorage().deploys[urlName];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IMerkleDistributorFactoryFeature.sol";
import "./deployables/MerkleDistributor.sol";
import "../fixins/FixinCommon.sol";
import "../storage/LibMerkleDistributorFactoryStorage.sol";
import "../migrations/LibMigrate.sol";
import "./interfaces/IFeature.sol";

/// @title A contract that deploys token airdrop contracts for anyone.
contract MerkleDistributorFactoryFeature is IFeature, IMerkleDistributorFactoryFeature, FixinCommon {
    /// @notice Name of this feature.
    string public constant FEATURE_NAME = "MerkleDistributorFactory";
    /// @notice Version of this feature.
    uint96 public immutable FEATURE_VERSION = _encodeVersion(1, 0, 0);

    /// @notice Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.createAirdrop.selector);
        _registerFeatureFunction(this.getDeployedAirdrops.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

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
    ) external {
        address instance = address(new MerkleDistributor(token, merkleRoot, distributionDuration, owner));
        LibMerkleDistributorFactoryStorage.getStorage().deploys[urlName].push(
            DeployData({factoryVersion: FEATURE_VERSION, contractAddress: instance})
        );
        emit MerkleDistributorDeployed(msg.sender, urlName, instance, FEATURE_VERSION);
    }

    /// @notice Returns all the deployed airdrop contract addresses by a specific creator.
    /// @param urlName The url name used by the frontend, kind of an id of the creator.
    /// @return airdropAddresses The requested array of contract addresses.
    function getDeployedAirdrops(string calldata urlName) external view returns (DeployData[] memory airdropAddresses) {
        return LibMerkleDistributorFactoryStorage.getStorage().deploys[urlName];
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

pragma solidity 0.8.13;

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

pragma solidity 0.8.13;

import "./utils/LibBytesV06.sol";
import "./migrations/LibBootstrap.sol";
import "./features/BootstrapFeature.sol";
import "./storage/LibProxyStorage.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}