/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

pragma solidity ^0.4.24;

/**
 *  @title ExposedSortitionSumTreeFactory
 *  @author Enrique Piqueras - <[email protected]>
 *  @dev Exposed version of SortitionSumTreeFactory for testing.
 */
contract ExposedDualSortitionSumTreeFactory {
    /* Storage */

    using DualSortitionSumTreeFactory for DualSortitionSumTreeFactory.DualSortitionSumTrees;
    DualSortitionSumTreeFactory.DualSortitionSumTrees internal dualSortitionSumTrees;

    /**
     *  @dev Public getter for sortitionSumTrees.
     *  @param _key The key of the tree to get.
     *  @return All of the tree's properties.
     */
    function _sortitionSumTrees(bytes32 _key) public view returns(uint K_draw, uint[] stackDraw, uint[] nodesDraw,uint K_set, uint[] stackSet, uint[] nodesSet) {
        return (
            dualSortitionSumTrees.sortitionSumDrawTrees[_key].K,
            dualSortitionSumTrees.sortitionSumDrawTrees[_key].stack,
            dualSortitionSumTrees.sortitionSumDrawTrees[_key].nodes,
            dualSortitionSumTrees.sortitionSumSetTrees[_key].K,
            dualSortitionSumTrees.sortitionSumSetTrees[_key].stack,
            dualSortitionSumTrees.sortitionSumSetTrees[_key].nodes
        );
    }

    /* Public */

    /**
     *  @dev Create a sortition sum tree at the specified key.
     *  @param _key The key of the new tree.
     *  @param _K_draw The number of children each node in the draw tree should have.
     *  @param _K_set The number of children each node in the set tree should have.
     */
    function _createTree(bytes32 _key, uint _K_draw, uint _K_set) public {
        dualSortitionSumTrees.createTree(_key, _K_draw, _K_set);
    }

    /**
     *  @dev Set a value of a tree.
     *  @param _key The key of the tree.
     *  @param _value The new value.
     *  @param _ID The ID of the value.
     */
    function _set(bytes32 _key, uint _value, bytes32 _ID) public {
        dualSortitionSumTrees.set(_key, _value, _ID);
    }

    /* Public Views */

    /**
     *  @dev Query the leaves of a tree.
     *  @param _key The key of the tree to get the leaves from.
     *  @param _cursor The pagination cursor.
     *  @param _count The number of items to return.
     *  @param _isSetTree true for Set Tree, false for Draw tree
     *  @return The index at which leaves start, the values of the returned leaves, and whether there are more for pagination.
     */
    function _queryLeafs(bytes32 _key, uint _cursor, uint _count, bool _isSetTree) public view returns(uint startIndex, uint[] values, bool hasMore) {
        return dualSortitionSumTrees.queryLeafs(_key, _cursor, _count, _isSetTree);
    }

    /**
     *  @dev Draw an ID from a tree using a number.
     *  @param _key The key of the tree.
     *  @param _drawnNumber The drawn number.
     *  @return The drawn ID.
     */
    function _draw(bytes32 _key, uint _drawnNumber) public view returns(bytes32 ID) {
        return dualSortitionSumTrees.draw(_key, _drawnNumber);
    }

    /**
     *  @dev Draw an ID from a tree using a number.
     *  @param _key The key of the tree.
     *  @param _drawnNumber The drawn number.
     *  @return The drawn ID.
     */
    function _drawAndUpdate(bytes32 _key, uint _drawnNumber, bool _requestUpdate) public returns(bytes32 ID) {
        return dualSortitionSumTrees.drawAndUpdate(_key, _drawnNumber, _requestUpdate);
    }

    /** @dev Gets a specified candidate's associated value.
     *  @param _key The key of the tree.
     *  @param _ID The ID of the value.
     *  @return The associated value.
     */
    function _stakeOf(bytes32 _key, bytes32 _ID) public view returns(uint value) {
        return dualSortitionSumTrees.stakeOf(_key, _ID);
    }
}



/**
 *  @title SortitionSumTreeFactory
 *  @author Enrique Piqueras - <[email protected]>
 *  @dev A factory of trees that keep track of staked values for sortition.
 */
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

        uint threshhold;
        uint lastThreshholdUpdate;

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

        self.threshhold = uint(-1);
        self.lastThreshholdUpdate = 1;

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


        SortitionSumTree storage tree = self.sortitionSumSetTrees[_key];

        uint treeIndex = tree.IDsToNodeIndexes[_ID];
        bool inSetTree = true;
        uint value;
        bool plusOrMinus;
        uint plusOrMinusValue;
        if (treeIndex != 0){//set tree
            if (_value == 0) { // Zero value.
                // Remove.
                // Remember value and set to 0.
                value = tree.nodes[treeIndex];
                tree.nodes[treeIndex] = 0;

                // Push to stack.
                tree.stack.push(treeIndex);

                // Clear label.
                delete tree.IDsToNodeIndexes[_ID];
                delete tree.nodeIndexesToIDs[treeIndex];

                updateParents(self, _key, treeIndex, false, value, inSetTree);
            } else if (_value != tree.nodes[treeIndex]) { // New, non zero value.
                // Set.
                if (_value > self.threshhold){// SortionSumSetTree -> SortitionSumDrawTree
                    // Remove from SortionSumSetTree
                    // Remember value and set to 0.
                    value = tree.nodes[treeIndex];
                    tree.nodes[treeIndex] = 0;

                    // Push to stack.
                    tree.stack.push(treeIndex);

                    // Clear label.
                    delete tree.IDsToNodeIndexes[_ID];
                    delete tree.nodeIndexesToIDs[treeIndex];

                    updateParents(self, _key, treeIndex, false, value, inSetTree);

                    tree = self.sortitionSumDrawTrees[_key];
                    inSetTree = false;
                }
                plusOrMinus = tree.nodes[treeIndex] <= _value;
                plusOrMinusValue = plusOrMinus ? _value - tree.nodes[treeIndex] : tree.nodes[treeIndex] - _value;
                tree.nodes[treeIndex] = _value;

                updateParents(self, _key, treeIndex, plusOrMinus, plusOrMinusValue, inSetTree);
            }
        } else { // draw tree or DNE
            tree = self.sortitionSumDrawTrees[_key];
            treeIndex = tree.IDsToNodeIndexes[_ID];
            if (treeIndex != 0){// draw tree
                inSetTree = false;
                if (_value == 0) { // Zero value.
                    // Remove.
                    // Remember value and set to 0.
                    value = tree.nodes[treeIndex];
                    tree.nodes[treeIndex] = 0;

                    // Push to stack.
                    tree.stack.push(treeIndex);

                    // Clear label.
                    delete tree.IDsToNodeIndexes[_ID];
                    delete tree.nodeIndexesToIDs[treeIndex];

                    updateParents(self, _key, treeIndex, false, value, inSetTree);
                } else if (_value != tree.nodes[treeIndex]) { // New, non zero value.
                    // Set.
                    if (_value < self.threshhold){// SortionSumDrawTree -> SortitionSumSetTree
                        // Remove from SortionSumSetTree
                        // Remember value and set to 0.
                        value = tree.nodes[treeIndex];
                        tree.nodes[treeIndex] = 0;

                        // Push to stack.
                        tree.stack.push(treeIndex);

                        // Clear label.
                        delete tree.IDsToNodeIndexes[_ID];
                        delete tree.nodeIndexesToIDs[treeIndex];

                        updateParents(self, _key, treeIndex, false, value, inSetTree);

                        tree = self.sortitionSumSetTrees[_key];
                        inSetTree = true;
                    }

                    plusOrMinus = tree.nodes[treeIndex] <= _value;
                    plusOrMinusValue = plusOrMinus ? _value - tree.nodes[treeIndex] : tree.nodes[treeIndex] - _value;
                    tree.nodes[treeIndex] = _value;

                    updateParents(self, _key, treeIndex, plusOrMinus, plusOrMinusValue, inSetTree);
                }
            } else{ // new _ID
                if (_value < self.threshhold){
                    tree = self.sortitionSumSetTrees[_key];
                } else {
                    inSetTree = false;
                }
                if (_value != 0) { // Non zero value.
                    // Append.
                    // Add node.
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

                    updateParents(self, _key, treeIndex, true, _value, inSetTree);
                }
            }
        }
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

    function drawAndUpdate(DualSortitionSumTrees storage self, bytes32 _key, uint _drawnNumber, bool requestUpdate) public returns(bytes32 ID) {
        ID = draw(self,  _key,  _drawnNumber);
        uint totalStake = (self.sortitionSumSetTrees[_key].nodes[0]+self.sortitionSumDrawTrees[_key].nodes[0]);
        bool stakeHalved = (self.lastThreshholdUpdate < totalStake) && (totalStake > 2*self.lastThreshholdUpdate);
        bool stakeDoubled = (self.lastThreshholdUpdate > totalStake) && (totalStake < 2*self.lastThreshholdUpdate);
        if (requestUpdate || stakeHalved || stakeDoubled){
            self.lastThreshholdUpdate = totalStake;
            self.threshhold = (self.threshhold + stakeOf(self, _key, ID))/2;
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
     *  @param _key The key of the tree to update.
     *  @param _treeIndex The index of the node to start from.
     *  @param _plusOrMinus Wether to add (true) or substract (false).
     *  @param _value The value to add or substract.
     *  `O(log_k(n))` where
     *  `k` is the maximum number of childs per node in the tree,
     *   and `n` is the maximum number of nodes ever appended.
     */
    function updateParents(DualSortitionSumTrees storage self, bytes32 _key, uint _treeIndex, bool _plusOrMinus, uint _value, bool isSetTree) private {
        SortitionSumTree storage tree = isSetTree ? self.sortitionSumSetTrees[_key] : self.sortitionSumDrawTrees[_key];

        uint parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus ? tree.nodes[parentIndex] + _value : tree.nodes[parentIndex] - _value;
        }
    }
}