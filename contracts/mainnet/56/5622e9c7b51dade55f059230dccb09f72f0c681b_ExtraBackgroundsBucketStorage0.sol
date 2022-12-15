// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity ^0.8.16;

/**
 * @notice Generic compressed data.
 * @param uncompressedSize Used for checking correct decompression
 * @param data The compressed data blob.
 */
struct Compressed {
    uint256 uncompressedSize;
    bytes data;
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity 0.8.16;

import {Compressed} from "solidify-contracts/Compressed.sol";

/**
 * @notice BucketStorage is used to store a list of compressed buckets in
 * contract code.
 */
interface IBucketStorage {
    /**
     * @notice Thrown if a non-existant bucket should be accessed.
     */
    error InvalidBucketIndex();

    /**
     * @notice Returns the compressed bucket with given index.
     * @param bucketIndex The index of the bucket in the storage.
     * @dev Reverts if the index is out-of-range.
     */
    function getBucket(uint256 bucketIndex)
        external
        pure
        returns (Compressed memory);

    function numBuckets() external pure returns (uint256);

    function numFields() external pure returns (uint256);

    function numFieldsPerBucket() external pure returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
// GENERATED CODE - DO NOT EDIT
pragma solidity 0.8.16;

import {IBucketStorage, Compressed} from "solidify-contracts/IBucketStorage.sol";

/**
 * @notice Stores a list of compressed buckets in contract code.
 */
contract ExtraBackgroundsBucketStorage0 is IBucketStorage {
    /**
     * @notice Returns number of buckets stored in this contract.
     */
    function numBuckets() external pure returns (uint256) {
        return 2;
    }

    /**
     * @notice Returns the number of fields stored in this contract.
     */
    function numFields() external pure returns (uint256) {
        return 2;
    }

    /**
     * @notice Returns number of fields in each bucket in this storge.
     */
    function numFieldsPerBucket() external pure returns (uint256[] memory) {
        bytes memory num_ = hex"0101";

        uint256[] memory num = new uint[](2);
        for (uint256 i; i < 2;) {
            num[i] = uint8(num_[i]);
            unchecked {
                ++i;
            }
        }
        return num;
    }

    /**
     * @notice Returns the bucket with a given index.
     * @dev Reverts if the index is out-of-bounds.
     */
    function getBucket(uint256 idx) external pure returns (Compressed memory) {
        if (idx == 0) {
            return Compressed({
                uncompressedSize: 5299,
                data: hex"ecd4310a80400c44d1c1ab6cb717d9fb5f26b59d0411d122c9427e2a8903ca109e0e4973aa7ad630ffb086f9cdb58cc8dcdebeff6450a6f0ebe5cdf79ccc9e1f33c917feb793b8cc9ecdf7397b9cc7799cc7799cc7799cc7799cc7799cc7799cc7f92f73060000ffff"
            });
        }

        if (idx == 1) {
            return Compressed({
                uncompressedSize: 5299,
                data: hex"e456c1a9c3300c357f990fb9b6b742d6e82a2533e49015ba542f3d070a3d6502f7600846969f2d39890d01118c919ff5a42739e6cf18d3759fc77f6bf6be5f8fd9778b5a5f1221ebb0df7e23dcab7c4fceddcfc0c1eb46ea5e65dd48ddabd899b9d715de3959b79301913d6f176ce19179ec4508004a01e2cc0e13b88544b8557edc8e1d26fb5dec30f90e479629e4ee1c32132bcd3908c9a78f1144b025ca01c21021fb120207a5ba55588c51b2bedb4618422545bbf6084e23d689540feab9378f3dbed43900a9c4624b7299c7de2e2f872322b81ecc1f086c540481f8e000d839898b95331f14e32839017c9a85b289093e7c1aa4867518ab14e9b8647ad947443d840bdff43d9ecb4c01e318587997cc4f82c6762e696d707ba6d4755dc6fe44650a981d4ad23f04b589aec6f60b0000ffff"
            });
        }

        revert InvalidBucketIndex();
    }
}