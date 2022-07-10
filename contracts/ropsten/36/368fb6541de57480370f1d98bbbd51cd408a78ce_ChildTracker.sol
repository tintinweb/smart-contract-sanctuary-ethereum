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
        address child = parentToChildren[_parent][childIndex];

        require(child == _child, "invalid child");
        
        children[childIndex] = address(0);
        children[childIndex] = children[children.length - 1];
        children.pop();

        emit ChildrenUpdated(_parent, children);
    }
}