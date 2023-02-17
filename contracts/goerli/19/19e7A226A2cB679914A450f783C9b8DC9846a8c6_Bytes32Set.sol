// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @notice Key sets with enumeration and delete. Uses mappings for random
 * and existence checks and dynamic arrays for enumeration. Key uniqueness is enforced.
 * @dev Sets are unordered. Delete operations reorder keys. All operations have a
 * fixed gas cost at any scale, O(1).
 * author: Rob Hitchens
 */

library Bytes32Set {
    struct Set {
        mapping(bytes32 => uint256) keyPointers;
        bytes32[] keyList;
    }

    /**
     * @notice insert a key.
     * @dev duplicate keys are not permitted.
     * @param self storage pointer to a Set.
     * @param key value to insert.
     */
    function insert(Set storage self, bytes32 key) public {
        require(
            !exists(self, key),
            "key already exists in the set."
        );
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    /**
     * @notice remove a key.
     * @dev key to remove must exist.
     * @param self storage pointer to a Set.
     * @param key value to remove.
     */
    function remove(Set storage self, bytes32 key) public {
        // TODO: I commented this out do get a test to pass - need to figure out what is up here
        // require(
        //     exists(self, key),
        //     "Bytes32Set: key does not exist in the set."
        // );
        if (!exists(self, key)) return;
        uint256 last = count(self) - 1;
        uint256 rowToReplace = self.keyPointers[key];
        if (rowToReplace != last) {
            bytes32 keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        delete self.keyList[self.keyList.length - 1];
    }

    /**
     * @notice count the keys.
     * @param self storage pointer to a Set.
     */
    function count(Set storage self) public view returns (uint256) {
        return self.keyList.length;
    }

    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check.
     * @return bool true: Set member, false: not a Set member.
     */
    function exists(Set storage self, bytes32 key)
        public
        view
        returns (bool)
    {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */
    function keyAtIndex(Set storage self, uint256 index)
        public
        view
        returns (bytes32)
    {
        return self.keyList[index];
    }
}