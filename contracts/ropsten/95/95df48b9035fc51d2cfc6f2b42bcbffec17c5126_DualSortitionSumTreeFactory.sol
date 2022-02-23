/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

/**
 *  @authors: [@shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: [ 
 */

pragma solidity ^0.4.24;

library DualSortitionSumTreeFactory {
    /* Structs */

    struct SortitionSumTree {
        uint K; // The maximum number of childs per node.
        // We use this to keep track of vacant positions in the tree after removing a leaf. This is for keeping the tree as balanced as possible without spending gas on moving nodes around.
        uint[] stack;
        uint[] nodes;
        // Two-way mapping of IDs to node indexes. Note that node index 0 is reserved for the root node, and means the ID does not have a node.
        mapping(bytes32 => uint) IDsToNodeIndexes;
        mapping(uint => bytes32) nodeIndexesToIDs;
    }

    /* Storage */

    struct DualSortitionSumTrees {
        mapping(bytes32 => SortitionSumTree) sortitionSumDrawTrees;
        mapping(bytes32 => SortitionSumTree) sortitionSumSetTrees;

        uint threshold;
        uint lastThresholdUpdate;

    }

    /* Public */

    /**
     *  @dev Create a sortition sum tree at the specified key.
     *  @param _key The key of the new tree.
     *  @param _K_draw The number of children each node in the draw tree should have.
     *  @param _K_set The number of children each node in the draw tree should have.
     */
    function createTree(DualSortitionSumTrees storage self, bytes32 _key, uint _K_draw,uint _K_set) public {

        SortitionSumTree storage treeDraw = self.sortitionSumDrawTrees[_key];
        SortitionSumTree storage treeSet = self.sortitionSumSetTrees[_key];

        self.threshold = uint(-1);
        self.lastThresholdUpdate = 0;

        require(treeDraw.K == 0, "Tree already exists.");
        require(treeSet.K == 0, "Tree already exists.");

        require(_K_draw > 1, "K must be greater than one.");
        require(_K_set > 1, "K must be greater than one.");

        treeDraw.K = _K_draw;
        treeDraw.stack.length = 0;
        treeDraw.nodes.length = 0;
        treeDraw.nodes.push(0);

        treeSet.K = _K_set;
        treeSet.stack.length = 0;
        treeSet.nodes.length = 0;
        treeSet.nodes.push(0);
    }

    /**
     *  @dev Set a value of a tree.
     *  @param _key The key of the tree.
     *  @param _value The new value.
     *  @param _ID The ID of the value.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function set(DualSortitionSumTrees storage self, bytes32 _key, uint _value, bytes32 _ID) public {


        SortitionSumTree storage treeSet = self.sortitionSumSetTrees[_key];
        SortitionSumTree storage treeDraw = self.sortitionSumDrawTrees[_key];

        if (self.lastThresholdUpdate > 2*(treeSet.nodes[0]+treeDraw.nodes[0]) || 2*self.lastThresholdUpdate < treeSet.nodes[0]+treeDraw.nodes[0]){
            uint startIndex = 0;
            for (uint i = 0; i < treeSet.nodes.length; i++) {
                if ((treeSet.K * i) + 1 >= treeSet.nodes.length) {
                    startIndex = i;
                    if (i == 0)
                        startIndex = 1;
                    break;
                }
            }
            for (i = 0; i < treeDraw.nodes.length; i++) {
                if ((treeDraw.K * i) + 1 >= treeDraw.nodes.length) {
                    if (i == 0){
                        startIndex = startIndex +1;
                    }
                    else{
                        startIndex = startIndex + i;
                        }
                    break;
                }
            }
            uint numTreeElements = treeDraw.nodes.length + treeSet.nodes.length - startIndex;
            self.threshold = (treeSet.nodes[0]+treeDraw.nodes[0])/numTreeElements;
            if(self.threshold == 0){
                self.threshold = uint(-1);
            }
            self.lastThresholdUpdate = treeSet.nodes[0]+treeDraw.nodes[0];
        }

        uint treeIndex = treeSet.IDsToNodeIndexes[_ID];
        bool plusOrMinus;
        uint plusOrMinusValue;
        if (treeIndex != 0){//set tree
            if (_value == 0) { // Zero value.
                // Remove.
                // Remember value and set to 0.
                remove(treeSet, treeIndex, _value, _ID);

            } else if (_value != treeSet.nodes[treeIndex]) { // New, non zero value.
                // Set.
                if (_value > self.threshold){// SortionSumSetTree -> SortitionSumDrawTree
                    // Remove from SortionSumSetTree
                    // Remember value and set to 0.
                    remove(treeSet, treeIndex, _value, _ID);
                    insert(treeDraw, _value, _ID);
                } else {
                    plusOrMinus = treeSet.nodes[treeIndex] <= _value;
                    plusOrMinusValue = plusOrMinus ? _value - treeSet.nodes[treeIndex] : treeSet.nodes[treeIndex] - _value;
                    treeSet.nodes[treeIndex] = _value;

                    updateParents(treeSet, treeIndex, plusOrMinus, plusOrMinusValue);
                }
            }
        } else { // draw tree or DNE
            treeIndex = treeDraw.IDsToNodeIndexes[_ID];
            if (treeIndex != 0){// draw tree
                if (_value == 0) { // Zero value.
                    // Remove.
                    // Remember value and set to 0.
                    remove(treeDraw, treeIndex, _value, _ID);

                } else if (_value != treeDraw.nodes[treeIndex]) { // New, non zero value.
                    // Set.
                    if (_value < self.threshold){// SortionSumDrawTree -> SortitionSumSetTree
                        // Remove from SortionSumSetTree
                        remove(treeDraw, treeIndex, _value, _ID);
                        insert(treeSet, _value, _ID);
                    } else{
                        plusOrMinus = treeDraw.nodes[treeIndex] <= _value;
                        plusOrMinusValue = plusOrMinus ? _value - treeDraw.nodes[treeIndex] : treeDraw.nodes[treeIndex] - _value;
                        treeDraw.nodes[treeIndex] = _value;

                        updateParents(treeDraw, treeIndex, plusOrMinus, plusOrMinusValue);
                    }
                }
            } else{ // new _ID
                if (_value != 0) { // Non zero value.
                    if (_value < self.threshold){
                        insert(treeSet, _value, _ID);
                    } else {
                        insert(treeDraw, _value, _ID);
                    }
                }
            }
        }
    }

    function insert(SortitionSumTree storage tree, uint _value, bytes32 _ID) private {
        uint treeIndex;
        if (tree.stack.length == 0) { // No vacant spots.
            // Get the index and append the value.
            treeIndex = tree.nodes.length;
            tree.nodes.push(_value);

            // Potentially append a new node and make the parent a sum node.
            if (treeIndex != 1 && (treeIndex - 1) % tree.K == 0) { // Is first child.
                uint parentIndex = treeIndex / tree.K;
                bytes32 parentID = tree.nodeIndexesToIDs[parentIndex];
                uint newIndex = treeIndex + 1;
                tree.nodes.push(tree.nodes[parentIndex]);
                delete tree.nodeIndexesToIDs[parentIndex];
                tree.IDsToNodeIndexes[parentID] = newIndex;
                tree.nodeIndexesToIDs[newIndex] = parentID;
            }
        } else { // Some vacant spot.
            // Pop the stack and append the value.
            treeIndex = tree.stack[tree.stack.length - 1];
            tree.stack.length--;
            tree.nodes[treeIndex] = _value;
        }

        // Add label.
        tree.IDsToNodeIndexes[_ID] = treeIndex;
        tree.nodeIndexesToIDs[treeIndex] = _ID;

        updateParents(tree, treeIndex, true, _value);
    }

    function remove(SortitionSumTree storage tree, uint _treeIndex, uint _value, bytes32 _ID) private {
            tree.nodes[_treeIndex] = 0;

            // Push to stack.
            tree.stack.push(_treeIndex);

            // Clear label.
            delete tree.IDsToNodeIndexes[_ID];
            delete tree.nodeIndexesToIDs[_treeIndex];
            updateParents(tree, _treeIndex, false, _value);
}

    /* Public Views */
// TODO QUERY
    /**
     *  @dev Query the leaves of a tree. Note that if `startIndex == 0`, the tree is empty and the root node will be returned.
     *  @param _key The key of the tree to get the leaves from.
     *  @param _cursor The pagination cursor.
     *  @param _count The number of items to return.
     *  @return startIndex The index at which leaves start.
     *  @return values The values of the returned leaves.
     *  @return hasMore Whether there are more for pagination.
     *  `O(n)` where
     *  `n` is the maximum number of nodes ever appended.
     */
    function queryLeafs(
        DualSortitionSumTrees storage self,
        bytes32 _key,
        uint _cursor,
        uint _count,
        bool isSumTree
    ) public view returns(uint startIndex, uint[] values, bool hasMore) {
        SortitionSumTree storage tree = isSumTree ? self.sortitionSumSetTrees[_key] : self.sortitionSumDrawTrees[_key];

        // Find the start index.
        for (uint i = 0; i < tree.nodes.length; i++) {
            if ((tree.K * i) + 1 >= tree.nodes.length) {
                startIndex = i;
                break;
            }
        }

        // Get the values.
        uint loopStartIndex = startIndex + _cursor;
        values = new uint[](loopStartIndex + _count > tree.nodes.length ? tree.nodes.length - loopStartIndex : _count);
        uint valuesIndex = 0;
        for (uint j = loopStartIndex; j < tree.nodes.length; j++) {
            if (valuesIndex < _count) {
                values[valuesIndex] = tree.nodes[j];
                valuesIndex++;
            } else {
                hasMore = true;
                break;
            }
        }
    }


    
    /**
     *  @dev Draw an ID from a tree using a number. Note that this function reverts if the sum of all values in the tree is 0.
     *  @param _key The key of the tree.
     *  @param _drawnNumber The drawn number.
     *  @return ID The drawn ID.
     *  `O(k * log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function draw(DualSortitionSumTrees storage self, bytes32 _key, uint _drawnNumber) public view returns(bytes32 ID) {
        SortitionSumTree storage tree = self.sortitionSumDrawTrees[_key];
        SortitionSumTree storage treeSet = self.sortitionSumSetTrees[_key];
        uint treeIndex = 0;
        uint currentDrawnNumber = _drawnNumber % (tree.nodes[0]+treeSet.nodes[0]);

        if(currentDrawnNumber > tree.nodes[0]){
            currentDrawnNumber -= tree.nodes[0];
            tree = treeSet;
        }

        while ((tree.K * treeIndex) + 1 < tree.nodes.length)  // While it still has children.
            for (uint i = 1; i <= tree.K; i++) { // Loop over children.
                uint nodeIndex = (tree.K * treeIndex) + i;
                uint nodeValue = tree.nodes[nodeIndex];

                if (currentDrawnNumber >= nodeValue) currentDrawnNumber -= nodeValue; // Go to the next child.
                else { // Pick this child.
                    treeIndex = nodeIndex;
                    break;
                }
            }

        ID = tree.nodeIndexesToIDs[treeIndex];
    }
    /** @dev Gets a specified ID's associated value.
     *  @param _key The key of the tree.
     *  @param _ID The ID of the value.
     *  @return value The associated value.
     */
    function stakeOf(DualSortitionSumTrees storage self, bytes32 _key, bytes32 _ID) public view returns(uint value) {
        // check set first
        SortitionSumTree storage tree = self.sortitionSumSetTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) { // check draw second
            tree = self.sortitionSumDrawTrees[_key];
            treeIndex = tree.IDsToNodeIndexes[_ID];
            if (treeIndex == 0)
                value = 0;
            else 
                value = tree.nodes[treeIndex];
        } else {
            value = tree.nodes[treeIndex];
        }
    }

    /* Private */

    /**
     *  @dev Update all the parents of a node.
     *  @param _treeIndex The index of the node to start from.
     *  @param _plusOrMinus Wether to add (true) or substract (false).
     *  @param _value The value to add or substract.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function updateParents(SortitionSumTree storage tree, uint _treeIndex, bool _plusOrMinus, uint _value) private {

        uint parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus ? tree.nodes[parentIndex] + _value : tree.nodes[parentIndex] - _value;
        }
    }
}