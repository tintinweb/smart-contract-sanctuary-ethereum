// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

using LinkedList for LinkedList.LinkedListUint32;

library LinkedList {

    uint32 constant _NULL = 0x00000000;
    uint32 constant _HEAD = 0x00000000;
    uint32 constant _TAIL = 0xffffffff;

    struct LinkedListUint32 {
        mapping(uint32 => uint32) map;
        uint32 size;
        bool initialized;
    }

    struct Link {
        uint32 prev;
        uint32 next;
    }

    function items(LinkedListUint32 storage self) internal view returns(uint32[] memory result) {
        result = new uint32[](self.size);
        uint32 current = _HEAD;
        for (uint32 i = 0; i < self.size; ++i) {
            current = result[i] = self.map[current];
        }
    }

    function contains(LinkedListUint32 storage self, uint32 value) internal view returns(bool) {
        if (self.map[value] != _NULL) {
            return true;
        } else {
            return false;
        }
    }

    function linkify(LinkedListUint32 storage self, Link[] memory links) internal returns (bool isNewList) {

        // Save listers existence in the listings map to reduce gas consumption
        if (self.initialized == false) {
            isNewList = self.initialized = true;
            isNewList = true;
        }

        // Count inconsistent changes
        int64 scores = 0;

        for (uint32 i = 0; i < links.length; i++) {
            Link memory link = links[i];

            uint32 prev = link.prev;
            uint32 next = link.next;
            uint32 oldNext = self.map[prev];

            // Skip an existing link
            if (oldNext == next) continue;
            
            // The sum of the values of the elements whose predecessor has changed
            scores += int64(uint64((next == 0) ? prev : next));

            // The diff of the values of the elements whose that have lost their predecessors
            scores -= int64(uint64((oldNext == 0) ? (prev == 0) ? _TAIL : prev : oldNext));

            if (prev != _HEAD && next != _NULL && self.map[prev] == _NULL) {
                self.size += 1;
            } else if (prev != _HEAD && next == _NULL && self.map[prev] != _NULL) {
                self.size -= 1;
            }

            self.map[prev] = next;
        }

        require(scores == 0, "Inconsistent changes");
    }
}

contract Listings {

    address[] listers;
    mapping(address => LinkedList.LinkedListUint32) listingByLister;

    function getLinkedListSize(address lister) public view returns (uint32) {
        return listingByLister[lister].size;
    }

    function getLinkedList(address lister) public view returns (uint32[] memory) {
        return listingByLister[lister].items();
    }

    function getListers() public view returns (address[] memory) {
        return listers;
    }

    function containsModuleInListing(address lister, uint32 moduleIdx) public view returns (bool) {
        return listingByLister[lister].contains(moduleIdx);
    }

    function changeMyList(LinkedList.Link[] memory links) public {
        LinkedList.LinkedListUint32 storage listing = listingByLister[msg.sender];
        bool isNewListing = listing.linkify(links);

        if (isNewListing) {
            listers.push(msg.sender);
        }
    }
}