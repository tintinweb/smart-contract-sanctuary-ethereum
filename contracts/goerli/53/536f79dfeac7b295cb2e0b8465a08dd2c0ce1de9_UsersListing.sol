/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

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

    uint256 private constant _NULL = 0;
    uint256 private constant _HEAD = 0;

    bool private constant _PREV = false;
    bool private constant _NEXT = true;

    struct List {
        uint256 size;
        mapping(uint256 => mapping(bool => uint256)) list;
    }

    mapping(address => List) linkedList;

    function listExists(List storage self) internal view returns (bool) {
        if (self.list[_HEAD][_PREV] != _HEAD || self.list[_HEAD][_NEXT] != _HEAD) {
            return true;
        } else {
            return false;
        }
    }
    
    function nodeExists(List storage self, uint256 _node) internal view returns (bool) {
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

    function sizeOf(List storage self) internal view returns (uint256) {
        return self.size;
    }

    function getNode(List storage self, uint256 _node) internal view returns (bool, uint256, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][_PREV], self.list[_node][_NEXT]);
        }
    }

    function getAdjacent(List storage self, uint256 _node, bool _direction) internal view returns (bool, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }

    function getNextNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _NEXT);
    }

    function getPreviousNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _PREV);
    }
    
    function insertAfter(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _NEXT);
    }

    function insertBefore(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _PREV);
    }

    function remove(List storage self, uint256 _node) internal returns (uint256) {
        if ((_node == _NULL) || (!nodeExists(self, _node))) {
            return 0;
        }
        _createLink(self, self.list[_node][_PREV], self.list[_node][_NEXT], _NEXT);
        delete self.list[_node][_PREV];
        delete self.list[_node][_NEXT];

        self.size -= 1; 

        return _node;
    }

    function pushFront(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _NEXT);
    }

    function pushBack(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _PREV);
    }

    function popFront(List storage self) internal returns (uint256) {
        return _pop(self, _NEXT);
    }
    function popBack(List storage self) internal returns (uint256) {
        return _pop(self, _PREV);
    }

    function _push(List storage self, uint256 _node, bool _direction) private returns (bool) {
        return _insert(self, _HEAD, _node, _direction);
    }

    function _pop(List storage self, bool _direction) private returns (uint256) {
        uint256 adj;
        (, adj) = getAdjacent(self, _HEAD, _direction);
        return remove(self, adj);
    }

    function _insert(List storage self, uint256 _node, uint256 _new, bool _direction) private returns (bool) {
        if (!nodeExists(self, _new) && nodeExists(self, _node)) {
            uint256 c = self.list[_node][_direction];
            _createLink(self, _node, _new, _direction);
            _createLink(self, _new, c, _direction);

            self.size += 1; // NOT: SafeMath library should be used here to increment.

            return true;
        }

        return false;
    }

    function _createLink(List storage self, uint256 _node, uint256 _link, bool _direction) private {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }

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

    function getLinkedListSize(address addres) public view returns (uint256){
        return linkedList[addres].size;
    }

    function getLinkedList(address addres) public view returns (uint256[] memory){
        uint256[] memory a;
        a = new uint256[](linkedList[addres].size);
        bool b; 
        uint256 y = 0;
        for (uint i = 0; i < linkedList[addres].size; i++) {
            (b, y) = getNextNode(linkedList[addres], y);
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

    function changeDirection(uint256 dappletId, uint256 prevDappletId) public {
        remove(linkedList[msg.sender], dappletId);
        insertAfter(linkedList[msg.sender], prevDappletId, dappletId);
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
                pushBack(linkedList[msg.sender], events[i].dappletId);
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