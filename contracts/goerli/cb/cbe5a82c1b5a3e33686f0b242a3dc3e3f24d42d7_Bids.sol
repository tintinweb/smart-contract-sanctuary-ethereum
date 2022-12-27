// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// import "forge-std/console.sol";

library Bids {
    struct Node {
        uint32 domain;
        address bidderAddress;
        uint128 bidAmount;
        uint64 bidTimestamp;
    }

    struct Heap {
        uint32[] array;
        mapping(uint32 => Node) index; // 1-indexed
        uint32 totalBids;
    }

    error BidTooLow();

    function initialize(
        Heap storage self,
        uint32 capacity
        ) external {
        self.array = new uint32[](capacity);
    }

    function insert(
        Heap storage self,
        uint32 domain_,
        address bidderAddress_,
        uint128 bidAmount_,
        uint64 bidTimestamp_
    ) internal returns (uint32) {
        if (self.totalBids == self.array.length
            && bidAmount_ < self.index[self.array[0]].bidAmount) {

            return 0;
        } else if (self.totalBids == self.array.length) {
            uint32 discarded = self.array[0];
            self.array[0] = self.totalBids + 1;
            self.index[self.totalBids + 1] = Node(
                domain_,
                bidderAddress_,
                bidAmount_,
                bidTimestamp_
            );
            heapify(self, 0);
            return discarded;
        } else {
            self.array[self.totalBids] = self.totalBids + 1;
            self.index[self.totalBids + 1] = Node(
                domain_,
                bidderAddress_,
                bidAmount_,
                bidTimestamp_
            );
            self.totalBids++;

            uint32 i = self.totalBids - 1;
            while (i > 0 && getBid(self, i).bidAmount
                                < getBid(self, (i - 1) / 2).bidAmount) {
                swap(self, i, (i - 1) / 2);
                i = (i - 1) / 2;
            }
            return 0;
        }


    }

    function heapify(
        Heap storage self,
        uint32 i
    ) internal {
        uint32 l = 2 * i + 1;
        uint32 r = 2 * i + 2;
        uint32 smallest = i;
        if (
            l < self.totalBids &&
            getBid(self, l).bidAmount < getBid(self, smallest).bidAmount
        ) {
            smallest = l;
        }
        if (
            r < self.totalBids &&
            getBid(self, r).bidAmount < getBid(self, smallest).bidAmount
        ) {
            smallest = r;
        }

        if (smallest != i) {
            swap(self, i, smallest);
            heapify(self, smallest);
        }
    }

    function getBid(
        Heap storage self,
        uint32 bidIndex
    ) internal view returns (Node memory) {
        return self.index[self.array[bidIndex]];
    }

    function getAllBids(
        Heap storage self
    ) internal view returns (Node[] memory) {
        Node[] memory bids = new Node[](self.totalBids);
        for (uint32 i = 0; i < self.totalBids; i++) {
            bids[i] = self.index[self.array[i]];
        }
        return bids;
    }

    function contains(
        Heap storage self,
        uint32 _domain,
        address _bidderAddress
    ) internal view returns (bool) {
        return getBidPosition(self, _domain, _bidderAddress) < self.totalBids;
    }

    function getBidPosition(
        Heap storage self,
        uint32 _domain,
        address _bidderAddress
    ) internal view returns (uint32) {
        for (uint32 i = 0; i < self.totalBids; i++) {
            if (self.index[self.array[i]].domain == _domain
                && self.index[self.array[i]].bidderAddress == _bidderAddress) {
                return i;
            }
        }
        return self.totalBids;
    }

    function swap(
        Heap storage self,
        uint32 i,
        uint32 j
    ) internal {
        (self.array[i], self.array[j])
            = (self.array[j], self.array[i]);
    }
}