/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library SetAddressLib {
    struct SetAddress {
        mapping(address => uint) keyPointers;
        address[] keyList;
    }

    function insert(SetAddress storage self, address key) internal {
        if(key != address(0) && !exists(self, key)) {
            self.keyList.push(key);
            self.keyPointers[key] = self.keyList.length - 1;
        }
    }   

    function exists(SetAddress storage self, address key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    // function remove(SetAddress storage self, address key) internal {
    //     if(exists(self, key)) {
    //         address keyToMove = self.keyList[uint(self.keyList.length)-1];
    //         uint rowToReplace = self.keyPointers[key];
    //         self.keyPointers[keyToMove] = rowToReplace;
    //         self.keyList[rowToReplace] = keyToMove;
    //         delete self.keyPointers[key];
    //         self.keyList.pop();
    //     }
    // }
}

using SetAddressLib for SetAddressLib.SetAddress;

struct ListLink {
    uint32 currentDappletId;
    uint32 nextDappletId;
}

struct LinkedListUint32 {
    mapping(uint32 => uint32) map;
    uint32 size;
}

contract Listings {

    SetAddressLib.SetAddress listers;
    mapping(address => LinkedListUint32) listingByLister;

    // function getMyList() public view returns (uint32[] memory){
    //     return listings[msg.sender].keyList;
    // }

    function getLinkedListSize(address addres) public view returns (uint32){
        return listingByLister[addres].size;
    }

    // used by dapplets store
    function getLinkedList(address addres) public view returns (uint32[] memory dappletIds) {
        LinkedListUint32 storage listing = listingByLister[addres];
        dappletIds = new uint32[](listing.size);
        uint32 currentDappletId = 0;
        for (uint32 i = 0; i < listing.size; ++i) {
            currentDappletId = dappletIds[i] = listing.map[currentDappletId];
        }
    }

    // used by dapplets store
    function getListers() public view returns (address[] memory){
        return listers.keyList;
    }

    // used by dapplets store
    // function getUserList(address addres) public view returns (uint32[] memory){
    //     return listings[addres].keyList;
    // }

    // used by dapplets store
    function changeMyList(ListLink[] memory links) public {
        listers.insert(msg.sender);
        LinkedListUint32 storage listing = listingByLister[msg.sender];

        for (uint32 i = 0; i < links.length; i++) {
            ListLink memory link = links[i];
            
            if (listing.map[link.currentDappletId] == 0 && link.nextDappletId != 0) {
                listing.size += 1;
            } else if (listing.map[link.currentDappletId] != 0 && link.nextDappletId == 0) {
                listing.size -= 1;
            }

            listing.map[link.currentDappletId] = link.nextDappletId;
        }
    }
}