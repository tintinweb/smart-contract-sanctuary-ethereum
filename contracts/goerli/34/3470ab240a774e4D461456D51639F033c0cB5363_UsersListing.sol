/**
 *Submitted for verification at Etherscan.io on 2022-01-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract UsersListing {

    enum EventType { REMOVE, ADD }

    struct Event {
        EventType eventType;
        uint32 dappletId;
    }

    struct Set {
        mapping(uint32 => uint32) keyPointers;
        uint32[] keyList;
    }

    mapping(address => Set) listings;

    

    struct UsersSet {
        mapping(address => uint) keyPointers;
        address[] keyList;
    }
    UsersSet users;

    function getMyList() public view returns (uint32[] memory){
        return listings[msg.sender].keyList;
    }

    function getUsers() public view returns (address[] memory){
        return users.keyList;
    }

    function getUserList(address addres) public view returns (uint32[] memory){
        return listings[addres].keyList;
    }


    function insertUser(UsersSet storage self, address key) internal {
        if(key != address(0) && !userExists(self, key)) {
            self.keyList.push(key);
            self.keyPointers[key] = self.keyList.length - 1;
        }
    }   
    
    function userExists(UsersSet storage self, address key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    function userRemove(UsersSet storage self, address key) internal {
        if(userExists(self, key)) {
            address keyToMove = self.keyList[uint(self.keyList.length)-1];
            uint rowToReplace = self.keyPointers[key];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
            delete self.keyPointers[key];
            self.keyList.pop();
        }
    }


    function changeMyList(Event[] memory events) public {
        insertUser(users, msg.sender);
        for( uint32 i = 0; i < events.length; i++) {
            if (events[i].eventType == EventType.ADD) {
                insert(listings[msg.sender], events[i].dappletId);
            }
            if (events[i].eventType == EventType.REMOVE) {
                remove(listings[msg.sender], events[i].dappletId);
                if(listings[msg.sender].keyList.length == 0) {
                    userRemove(users, msg.sender);
                }
            }
        }
    }

    function insert(Set storage self, uint32 key) internal {
        if (!exists(self, key)) {
            self.keyList.push(key);
            self.keyPointers[key] = uint32(self.keyList.length) - 1;
        }
    }

    function remove(Set storage self, uint32 key) internal {
        if (exists(self, key)) {
            uint32 keyToMove = self.keyList[count(self)-1];
            uint32 rowToReplace = self.keyPointers[key];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
            delete self.keyPointers[key];
            self.keyList.pop();
        }
    }

    function count(Set storage self) internal view returns(uint) {
        return(self.keyList.length);
    }

    function exists(Set storage self, uint32 key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }
}