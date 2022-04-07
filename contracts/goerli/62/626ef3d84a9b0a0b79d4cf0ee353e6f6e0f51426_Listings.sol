/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

using LinkedList for LinkedList.LinkedListUint32;

library LinkedList {
    struct LinkedListUint32 {
        mapping(uint32 => uint32) map;
        uint32 size;
        bool initialized;
    }

    function items(LinkedListUint32 storage self) internal view returns(uint32[] memory result) {
        result = new uint32[](self.size);
        uint32 current = 0;
        for (uint32 i = 0; i < self.size; ++i) {
            current = result[i] = self.map[current];
        }
    }

    function linkify(LinkedListUint32 storage self, uint32 a, uint32 b) internal {
        if (b != 0 && self.map[a] == 0) {
            self.size += 1;
        } else if (b == 0 && self.map[a] != 0) {
            self.size -= 1;
        }

        self.map[a] = b;
    }
}

struct ListLink {
    uint32 currentDappletId;
    uint32 nextDappletId;
}

contract Listings {

    address[] listers;
    mapping(address => LinkedList.LinkedListUint32) listingByLister;

    function getLinkedListSize(address addres) public view returns (uint32) {
        return listingByLister[addres].size;
    }

    function getLinkedList(address addres) public view returns (uint32[] memory) {
        return listingByLister[addres].items();
    }

    function getListers() public view returns (address[] memory) {
        return listers;
    }

    function changeMyList(ListLink[] memory links) public {
        LinkedList.LinkedListUint32 storage listing = listingByLister[msg.sender];

        // Save listers existence in the listings map to reduce gas consumption
        if (listing.initialized == false) {
            listing.initialized = true;
            listers.push(msg.sender);
        }

        for (uint32 i = 0; i < links.length; i++) {
            ListLink memory link = links[i];
            listing.linkify(link.currentDappletId, link.nextDappletId);
            // ToDo: check consistency of the linked list
        }
    }
}