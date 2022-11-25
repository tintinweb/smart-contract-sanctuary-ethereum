// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

library BinarySearchTreeLib {
    uint256 private constant TIME_EXTENSION = 50400;

    struct Node {
        uint256 parent;
        uint256 value;
        uint256 left;
        uint256 right;
    }

    struct Tree {
        uint256 root;
        uint256 rootLast;
        mapping(uint256 => Node) nodes;
        mapping(uint256 => uint256[]) rootToList;
        mapping(uint256 => uint256[]) futureExpiries; //map from last divisible root to a list of exipiries sine that root. not ordered
    }

    // helper function for insert
    function insertHelper(
        Tree storage self,
        uint256 newValue,
        uint256 nodeId
    ) public {
        // current node
        Node memory curNode = self.nodes[nodeId];
        // if value exists, no need to insert
        if (newValue != curNode.value) {
            if (newValue < curNode.value) {
                if (curNode.left == 0) {
                    self.nodes[curNode.value].left = newValue;
                    self.nodes[newValue] = Node(curNode.value, newValue, 0, 0);
                } else {
                    insertHelper(self, newValue, curNode.left);
                }
            } else {
                if (curNode.right == 0) {
                    self.nodes[curNode.value].right = newValue;
                    self.nodes[newValue] = Node(curNode.value, newValue, 0, 0);
                } else {
                    insertHelper(self, newValue, curNode.right);
                }
            }
        }
    }

    function insert(Tree storage self, uint256 newValue) public {
        // no tree exists
        if (self.root == 0) {
            self.root = newValue;
            self.rootLast = newValue;
            self.nodes[newValue] = Node(0, newValue, 0, 0);
            self.futureExpiries[self.root].push(newValue);
        } else {
            insertHelper(self, newValue, self.root);
        }
    }

    function returnListHelperEx(
        Tree storage self,
        uint256 start,
        uint256 end,
        uint256 nodeId,
        uint256 extension
    ) public {
        if (start <= end && end < extension) {
            // current node
            Node memory curNode = self.nodes[nodeId];
            if (curNode.value != 0) {
                if (curNode.value > start) {
                    returnListHelperEx(
                        self,
                        start,
                        end,
                        curNode.left,
                        extension
                    );
                }

                if (curNode.value <= end && curNode.value >= start) {
                    if (
                        self.rootToList[self.root].length == 0 ||
                        (self.rootToList[self.root].length > 0 &&
                            self.rootToList[self.root][
                                self.rootToList[self.root].length - 1
                            ] !=
                            curNode.value)
                    ) {
                        self.rootToList[self.root].push(curNode.value);
                    }
                }

                if (curNode.value <= extension && curNode.value > end) {
                    if (
                        self.futureExpiries[self.root].length == 0 ||
                        (self.futureExpiries[self.root].length > 0 &&
                            self.futureExpiries[self.root][
                                self.futureExpiries[self.root].length - 1
                            ] !=
                            curNode.value)
                    ) {
                        self.futureExpiries[self.root].push(curNode.value);
                    }
                }

                if (curNode.value < extension) {
                    returnListHelperEx(
                        self,
                        start,
                        end,
                        curNode.right,
                        extension
                    );
                }
            }
        }
    }

    function deleteNodeHelper(
        Tree storage self,
        uint256 deleteValue,
        uint256 nodeId
    ) public returns (uint256 newValue) {
        Node memory curNode = self.nodes[nodeId];
        if (curNode.value == deleteValue) {
            newValue = deleteLeaf(self, curNode.value);
        } else if (curNode.value < deleteValue) {
            if (curNode.right == 0) {
                newValue = 0;
            } else {
                newValue = deleteNodeHelper(self, deleteValue, curNode.right);
            }
        } else {
            if (curNode.left == 0) {
                newValue = 0;
            } else {
                newValue = deleteNodeHelper(self, deleteValue, curNode.left);
            }
        }
    }

    function deleteLeaf(
        Tree storage self,
        uint256 nodeId
    ) public returns (uint256 newNodeId) {
        Node memory curNode = self.nodes[nodeId];
        if (curNode.left != 0) {
            uint256 tempValue = curNode.left;
            while (self.nodes[tempValue].right != 0) {
                tempValue = self.nodes[tempValue].right;
            }
            if (tempValue != curNode.left) {
                if (curNode.parent != 0) {
                    if (curNode.value < curNode.parent) {
                        self.nodes[curNode.parent].left = tempValue;
                    } else {
                        self.nodes[curNode.parent].right = tempValue;
                    }
                }

                if (curNode.right != 0) {
                    self.nodes[curNode.right].parent = tempValue;
                }

                self.nodes[curNode.left].parent = tempValue;
                curNode.value = tempValue;

                deleteNodeHelper(self, tempValue, curNode.left);
                self.nodes[tempValue] = curNode;
                self.nodes[nodeId] = Node(0, 0, 0, 0);
            } else {
                if (curNode.parent != 0) {
                    if (curNode.value < curNode.parent) {
                        self.nodes[curNode.parent].left = curNode.left;
                    } else {
                        self.nodes[curNode.parent].right = curNode.left;
                    }
                }

                if (curNode.right != 0) {
                    self.nodes[curNode.right].parent = curNode.left;
                }

                self.nodes[curNode.left].parent = curNode.parent;
                self.nodes[curNode.left].right = curNode.right;
                self.nodes[nodeId] = Node(0, 0, 0, 0);
            }
            newNodeId = tempValue;
        } else if (curNode.left == 0 && curNode.right != 0) {
            uint256 tempValue = curNode.right;
            if (curNode.parent != 0) {
                if (curNode.value < curNode.parent) {
                    self.nodes[curNode.parent].left = tempValue;
                } else {
                    self.nodes[curNode.parent].right = tempValue;
                }
            }

            self.nodes[curNode.right].parent = curNode.parent;
            self.nodes[nodeId] = Node(0, 0, 0, 0);
            newNodeId = tempValue;
        } else {
            if (curNode.parent != 0) {
                if (curNode.value < curNode.parent) {
                    self.nodes[curNode.parent].left = 0;
                } else {
                    self.nodes[curNode.parent].right = 0;
                }
            }
            self.nodes[nodeId] = Node(0, 0, 0, 0);
            newNodeId = 0;
        }
    }

    function deleteNode(
        Tree storage self,
        uint256 deleteValue
    ) public returns (uint256 newRoot) {
        if (deleteValue != self.root) {
            deleteNodeHelper(self, deleteValue, self.root);
            newRoot = self.root;
        } else {
            newRoot = deleteLeaf(self, self.root);
            self.root = newRoot;
        }
    }

    function trimTreeHelper(
        Tree storage self,
        uint256 start,
        uint256 end,
        uint256 nodeId
    ) public {
        if (start <= end) {
            // current node
            Node memory curNode = self.nodes[nodeId];
            if (curNode.value != 0) {
                if (curNode.value < start) {
                    trimTreeHelper(self, start, end, curNode.right);
                } else if (curNode.value >= start && curNode.value <= end) {
                    uint256 newNodeId = deleteLeaf(self, curNode.value);
                    if (newNodeId != 0) {
                        trimTreeHelper(self, start, end, newNodeId);
                    }
                } else {
                    trimTreeHelper(self, start, end, curNode.left);
                }
            }
        }
    }

    function trimTree(
        Tree storage self,
        uint256 start,
        uint256 end
    ) public returns (uint256 newRoot) {
        if (start <= end) {
            // current root
            Node memory rootNode = self.nodes[self.root];
            if (rootNode.value != 0) {
                if (rootNode.value < start) {
                    trimTreeHelper(self, start, end, rootNode.right);
                    newRoot = self.root;
                } else if (rootNode.value >= start && rootNode.value <= end) {
                    newRoot = deleteNode(self, rootNode.value);
                    if (newRoot != 0) {
                        newRoot = trimTree(self, start, end);
                    }
                } else {
                    trimTreeHelper(self, start, end, rootNode.left);
                    newRoot = self.root;
                }
            }
        }
    }

    function processExpiriesListNTrimTree(
        Tree storage self,
        uint256 start,
        uint256 end
    ) public {
        if (self.root != 0) {
            //must have a tree
            delete self.futureExpiries[self.root];
            self.futureExpiries[self.root].push(end);
            if (self.root == self.rootLast) {
                delete self.rootToList[self.root];
            }
            returnListHelperEx(
                self,
                start,
                end,
                self.root,
                end + TIME_EXTENSION
            );
            self.rootLast = self.root;
            trimTree(self, start, end);
        }
    }

    function getExpiriesList(
        Tree storage self
    ) public view returns (uint256[] storage) {
        return self.rootToList[self.rootLast];
    }

    function getFutureExpiriesList(
        Tree storage self
    ) public view returns (uint256[] storage) {
        return self.futureExpiries[self.rootLast];
    }
}