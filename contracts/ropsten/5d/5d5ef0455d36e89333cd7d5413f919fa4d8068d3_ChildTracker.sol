/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ChildTracker {
    event ChildrenUpdated(address indexed parent, address[] children);

    mapping(address => address[]) public parentToChildren;
    mapping(address => mapping(address => uint256)) public parentChildIndex;

    function addChild(address _parent, address _child) external {
        address[] storage children = parentToChildren[_parent];
        children.push(_child);

        parentChildIndex[_parent][_child] = children.length - 1;

        emit ChildrenUpdated(_parent, children);
    }

    function removeChild(address _parent, address _child) external {
        address[] storage children = parentToChildren[_parent];

        uint256 childIndex = parentChildIndex[_parent][_child];

        require(children[childIndex] == _child, "invalid child");
        
        address lastChild = children[children.length - 1];

        parentChildIndex[_parent][lastChild] = childIndex;
        children[childIndex] = lastChild;
        children.pop();

        emit ChildrenUpdated(_parent, children);
    }
}