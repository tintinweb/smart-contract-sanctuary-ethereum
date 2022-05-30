// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

contract CyclePreventionRegistry {
    mapping(address => address[]) private childParentRelations;

    function registerChildParentRelation(address parent) external {
        _checkForCircularDependency(msg.sender, parent);
        childParentRelations[msg.sender].push(parent);
    }

    function removeChildParentRelation(address parent) external {
        for (uint256 i = 0; i < childParentRelations[msg.sender].length; i++) {
            if (childParentRelations[msg.sender][i] == parent) {
                childParentRelations[msg.sender][i] = childParentRelations[
                    msg.sender
                ][childParentRelations[msg.sender].length - 1];
                childParentRelations[msg.sender].pop();
            }
        }
    }

    function _checkForCircularDependency(address child, address parent)
        private
        view
    {
        address[] memory grandParents = childParentRelations[parent];
        for (uint256 i = 0; i < grandParents.length; i++) {
            if (grandParents[i] == child) {
                revert("Circular dependency not allowed");
            } else {
                _checkForCircularDependency(child, grandParents[i]);
            }
        }
    }
}