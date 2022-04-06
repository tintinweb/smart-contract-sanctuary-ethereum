/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// File: DappletRegistry/SetAddressLib.sol



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

    function remove(SetAddress storage self, address key) internal {
        if(exists(self, key)) {
            address keyToMove = self.keyList[uint(self.keyList.length)-1];
            uint rowToReplace = self.keyPointers[key];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
            delete self.keyPointers[key];
            self.keyList.pop();
        }
    }
}
// File: DappletRegistry/SetUint32Lib.sol



pragma solidity ^0.8.13;

library SetUint32Lib {
    struct SetUint32 {
        mapping(uint32 => uint32) keyPointers;
        uint32[] keyList;
    }

    function insert(SetUint32 storage self, uint32 key) internal {
        if (!exists(self, key)) {
            self.keyList.push(key);
            self.keyPointers[key] = uint32(self.keyList.length) - 1;
        }
    }

    function remove(SetUint32 storage self, uint32 key) internal {
        if (exists(self, key)) {
            uint32 keyToMove = self.keyList[count(self)-1];
            uint32 rowToReplace = self.keyPointers[key];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
            delete self.keyPointers[key];
            self.keyList.pop();
        }
    }

    function count(SetUint32 storage self) internal view returns(uint) {
        return(self.keyList.length);
    }

    function exists(SetUint32 storage self, uint32 key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }
}
// File: DappletRegistry/LinkedListLib.sol



pragma solidity ^0.8.13;

uint256 constant _NULL = 0;
uint256 constant _HEAD = 0;
bool constant _PREV = false;
bool constant _NEXT = true;

library LinkedListLib {

    struct LinkedList {
        uint256 size;
        mapping(uint256 => mapping(bool => uint256)) list;
    }

    function listExists(LinkedList storage self) internal view returns (bool) {
        if (self.list[_HEAD][_PREV] != _HEAD || self.list[_HEAD][_NEXT] != _HEAD) {
            return true;
        } else {
            return false;
        }
    }

    function nodeExists(LinkedList storage self, uint256 _node) internal view returns (bool) {
        if (self.list[_node][_PREV] == _HEAD && self.list[_node][_NEXT] == _HEAD) {
            if (self.list[_HEAD][_NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    function sizeOf(LinkedList storage self) internal view returns (uint256) {
        return self.size;
    }

    function getNode(LinkedList storage self, uint256 _node) internal view returns (bool, uint256, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][_PREV], self.list[_node][_NEXT]);
        }
    }

    function getAdjacent(LinkedList storage self, uint256 _node, bool _direction) internal view returns (bool, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }

    function getNextNode(LinkedList storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _NEXT);
    }

    function getPreviousNode(LinkedList storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _PREV);
    }

    function insertAfter(LinkedList storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _NEXT);
    }

    function insertBefore(LinkedList storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _PREV);
    }

    function remove(LinkedList storage self, uint256 _node) internal returns (uint256) {
        if ((_node == _NULL) || (!nodeExists(self, _node))) {
            return 0;
        }
        _createLink(self, self.list[_node][_PREV], self.list[_node][_NEXT], _NEXT);
        delete self.list[_node][_PREV];
        delete self.list[_node][_NEXT];

        self.size -= 1; 

        return _node;
    }

    function pushFront(LinkedList storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _NEXT);
    }

    function pushBack(LinkedList storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _PREV);
    }

    function popFront(LinkedList storage self) internal returns (uint256) {
        return _pop(self, _NEXT);
    }
    function popBack(LinkedList storage self) internal returns (uint256) {
        return _pop(self, _PREV);
    }

    function _push(LinkedList storage self, uint256 _node, bool _direction) private returns (bool) {
        return _insert(self, _HEAD, _node, _direction);
    }

    function _pop(LinkedList storage self, bool _direction) private returns (uint256) {
        uint256 adj;
        (, adj) = getAdjacent(self, _HEAD, _direction);
        return remove(self, adj);
    }

    function _insert(LinkedList storage self, uint256 _node, uint256 _new, bool _direction) private returns (bool) {
        if (!nodeExists(self, _new) && nodeExists(self, _node)) {
            uint256 c = self.list[_node][_direction];
            _createLink(self, _node, _new, _direction);
            _createLink(self, _new, c, _direction);

            self.size += 1; // NOT: SafeMath library should be used here to increment.

            return true;
        }

        return false;
    }

    function _createLink(LinkedList storage self, uint256 _node, uint256 _link, bool _direction) private {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }

}
// File: DappletRegistry/Listing.sol



pragma solidity ^0.8.13;




using LinkedListLib for LinkedListLib.LinkedList;
using SetUint32Lib for SetUint32Lib.SetUint32;
using SetAddressLib for SetAddressLib.SetAddress;

enum EventType { REMOVE, ADD, REPLACE }

struct Event {
    EventType eventType;
    uint32 dappletId;
    uint32 dappletPrevId;
}

contract UsersListing {

    mapping(address => SetUint32Lib.SetUint32) listings;
    mapping(address => LinkedListLib.LinkedList) linkedList;
    SetAddressLib.SetAddress users;

    function getMyList() public view returns (uint32[] memory){
        return listings[msg.sender].keyList;
    }

    function getLinkedListSize(address addres) public view returns (uint256){
        return linkedList[addres].size;
    }

    function getLinkedList(address addres) public view returns (uint256[] memory){
        uint256[] memory a;
        a = new uint256[](linkedList[addres].size);
        bool b; 
        uint256 y = 0;
        for (uint i = 0; i < linkedList[addres].size; i++) {
            (b, y) = linkedList[addres].getNextNode(y);
            a[i] = y;
            // a.push(x);
        }
        return a;
    }

    function getUsers() public view returns (address[] memory){
        return users.keyList;
    }

    function getUserList(address addres) public view returns (uint32[] memory){
        return listings[addres].keyList;
    }

    function changeDirection(uint256 dappletId, uint256 prevDappletId, address addres) public {
        linkedList[addres].remove(dappletId);
        linkedList[addres].insertAfter(prevDappletId, dappletId);
    }

    function changeMyList(Event[] memory events) public {
        users.insert(msg.sender);

        for( uint32 i = 0; i < events.length; i++) {
            if (events[i].eventType == EventType.ADD) {
                listings[msg.sender].insert(events[i].dappletId);
                linkedList[msg.sender].pushBack(events[i].dappletId);
            }
            if (events[i].eventType == EventType.REMOVE) {
                listings[msg.sender].remove(events[i].dappletId);
                linkedList[msg.sender].remove(events[i].dappletId);
                if(listings[msg.sender].keyList.length == 0) {
                    users.remove(msg.sender);
                }
            }
            if (events[i].eventType == EventType.REPLACE) {
                changeDirection(events[i].dappletId, events[i].dappletPrevId, msg.sender);
            }
        }
    }
}