/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Bucket {
    struct BucketStock {
        uint8[] typeDays;
        uint16[] stockPrefixSum;
        uint16 currentBucketStock;
        mapping(uint16 => uint16) ledgerStockIndex;
        uint256 stockSize;
    }

    mapping(uint256 => BucketStock) public ledgerBucketStock;

    /**
     * @dev set an array of stock for the blind box
     */
    function _setStock(
        uint256 ledgerType,
        uint8[] calldata typeDays,
        uint16[] calldata stock
    ) internal {
        BucketStock storage bucketStock = ledgerBucketStock[ledgerType];
        uint16 itemCount = 0;
        uint16[] storage stockPrefixSum = bucketStock.stockPrefixSum;
        uint8[] storage typeDaysStorage = bucketStock.typeDays;
        uint256 stockLength = stock.length;
        for (uint16 i = 0; i < stockLength; ++i) {
            itemCount += stock[i];
            stockPrefixSum.push(itemCount);
            typeDaysStorage.push(typeDays[i]);
        }
        bucketStock.currentBucketStock = itemCount;
        bucketStock.stockSize = itemCount;
        require(stockPrefixSum.length <= 2e16, "stock length too long");
    }

    /**
     * @dev refill the stock of the bucket
     * @param ledgerType the type of the ledger
     */
    function _refillStock(uint256 ledgerType) internal {
        BucketStock storage bucketStock = ledgerBucketStock[ledgerType];
        bucketStock.currentBucketStock = uint16(bucketStock.stockSize);
    }

    /**
     * @dev Buy only one box
     */
    function _pickDay(uint256 ledgerType, uint256 seed) internal returns (uint16) {
        BucketStock storage bucketStock = ledgerBucketStock[ledgerType];
        uint16 randIndex = _getRandomIndex(seed, bucketStock.currentBucketStock);
        uint16 location = _pickLocation(randIndex, bucketStock);
        uint16 category = binarySearch(bucketStock.stockPrefixSum, location);
        return bucketStock.typeDays[category];
    }

    function _pickLocation(uint16 index, BucketStock storage bucketStock) internal returns (uint16) {
        uint16 location = bucketStock.ledgerStockIndex[index];
        if (location == 0) {
            location = index + 1;
        }
        uint16 lastIndexLocation = bucketStock.ledgerStockIndex[bucketStock.currentBucketStock - 1];

        if (lastIndexLocation == 0) {
            lastIndexLocation = bucketStock.currentBucketStock;
        }
        bucketStock.ledgerStockIndex[index] = lastIndexLocation;
        bucketStock.currentBucketStock--;
        bucketStock.ledgerStockIndex[bucketStock.currentBucketStock] = location;

        // refill the bucket
        if (bucketStock.currentBucketStock == 0) {
            bucketStock.currentBucketStock = uint16(bucketStock.stockSize);
        }
        return location - 1;
    }

    function _getRandomIndex(uint256 seed, uint16 size) internal view returns (uint16) {
        // NOTICE: We do not to prevent miner from front-running the transaction and the contract.
        return
            uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.difficulty,
                            block.timestamp,
                            msg.sender,
                            blockhash(block.number - 1),
                            seed,
                            size
                        )
                    )
                ) % size
            );
    }

    function getBucketInfo(uint256 ledgerType) external view returns (uint8[] memory, uint16[] memory) {
        BucketStock storage bucketStock = ledgerBucketStock[ledgerType];
        return (bucketStock.typeDays, bucketStock.stockPrefixSum);
    }

    function binarySearch(uint16[] storage array, uint16 target) internal view returns (uint16) {
        uint256 left = 0;
        uint256 right = array.length - 1;
        uint256 mid;
        while (left < right - 1) {
            mid = left + (right - left) / 2;
            if (array[mid] > target) {
                right = mid;
            } else {
                left = mid + 1;
            }
        }
        if (target < array[left]) {
            return uint16(left);
        } else {
            return uint16(right);
        }
    }
}