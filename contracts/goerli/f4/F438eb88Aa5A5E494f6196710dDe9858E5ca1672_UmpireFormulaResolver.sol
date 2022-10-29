// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UmpireModel.sol";
//import "hardhat/console.sol";

// @todo natspec
contract UmpireFormulaResolver {
    function resolve(PostfixNode[] memory _postfixNodes, int[] memory _variables) public pure returns (int) {
        require(_postfixNodes.length > 0, "Provide nodes");

        int[] memory stack = new int[](256);
        uint8 stackHeight;
        for (uint idx = 0; idx < _postfixNodes.length; idx++) {
            if (_postfixNodes[idx].nodeType == PostfixNodeType.VARIABLE) {
                _postfixNodes[idx].nodeType = PostfixNodeType.VALUE;
                _postfixNodes[idx].value = _variables[_postfixNodes[idx].variableIndex];
            }

            if (_postfixNodes[idx].nodeType == PostfixNodeType.VALUE) {
                stack[stackHeight] = _postfixNodes[idx].value;
                stackHeight++;
                continue;
            }

            if (_postfixNodes[idx].nodeType != PostfixNodeType.OPERATOR) {
                // @todo
                revert("Broken node");
            }

            // @todo checked/unchecked flag, try/catch for fallback (negative or 3rd action?)
            if (_postfixNodes[idx].operator == PostfixNodeOperator.ADD) {
                if (stackHeight < 2) {
                    revert("Broken stack");
                }
                int result = stack[stackHeight - 2] + stack[stackHeight - 1];
                stack[stackHeight - 2] = result;
                stackHeight--;
            } else if (_postfixNodes[idx].operator == PostfixNodeOperator.SUB) {
                if (stackHeight < 2) {
                    revert("Broken stack");
                }
                int result = stack[stackHeight - 2] - stack[stackHeight - 1];
                stack[stackHeight - 2] = result;
                stackHeight--;
            } else if (_postfixNodes[idx].operator == PostfixNodeOperator.MUL) {
                if (stackHeight < 2) {
                    revert("Broken stack");
                }
                int result = stack[stackHeight - 2] * stack[stackHeight - 1];
                stack[stackHeight - 2] = result;
                stackHeight--;
            } else {
                revert("Unknown operator");
            }
        }

        if (stackHeight != 1) {
            revert("Broken stack");
        }

        return stack[0];
    }

    // @dev supports up to 10 values and 10 variables
    // @dev formula format is postfix, variable and value indexes prefixed with X and V
    // @dev example formula: V0V1+
    function stringToNodes(string memory _formula, int[] memory _values) public pure returns (PostfixNode[] memory) {
        bytes memory chars = bytes(_formula);
        uint symbolCount = chars.length;
        for (uint idx = 0; idx < chars.length; idx++) {
            if (chars[idx] == 'V' || chars[idx] == 'X') {
                symbolCount--;
            }
        }

        bool isValue = false;
        bool isVariable = false;
        PostfixNode[] memory nodes = new PostfixNode[](symbolCount);
        uint8 nodeIdx = 0;

        for (uint idx = 0; idx < chars.length; idx++) {
            if (chars[idx] == 'V') {
                isValue = true;
                continue;
            }

            if (chars[idx] == 'X') {
                isVariable = true;
                continue;
            }

            if (isValue) {
                isValue = false;
                nodes[nodeIdx] = PostfixNode(_values[uint8(chars[idx]) - 48], PostfixNodeType.VALUE, PostfixNodeOperator.ADD, 0);
                nodeIdx++;
            } else if (isVariable) {
                isVariable = false;
                nodes[nodeIdx] = PostfixNode(0, PostfixNodeType.VARIABLE, PostfixNodeOperator.ADD, uint8(chars[idx]) - 48);
                nodeIdx++;
            } else if (chars[idx] == '+') {
                nodes[nodeIdx] = PostfixNode(0, PostfixNodeType.OPERATOR, PostfixNodeOperator.ADD, 0);
                nodeIdx++;
            } else {
                revert("Not implemented");
            }
        }

        return nodes;
    }

    function resolveFormula(string memory _formula, int[] memory _values, int[] memory _variables) public pure returns (int) {
        return resolve(stringToNodes(_formula, _values), _variables);
    }

    // @dev testing, remove afterwards
    function addTwoNumbers(int _a, int _b) public pure returns (int) {
        PostfixNode[] memory nodes = new PostfixNode[](3);
        nodes[0].nodeType = PostfixNodeType.VALUE;
        nodes[0].value = _a;

        nodes[1].nodeType = PostfixNodeType.VALUE;
        nodes[1].value = _b;

        nodes[2].nodeType = PostfixNodeType.OPERATOR;
        nodes[2].operator = PostfixNodeOperator.ADD;

        int[] memory variables;

        return resolve(nodes, variables);
    }

    // @dev testing, remove afterwards
    function mulTwoNumbers(int _a, int _b) public pure returns (int) {
        PostfixNode[] memory nodes = new PostfixNode[](3);
        nodes[0].nodeType = PostfixNodeType.VALUE;
        nodes[0].value = _a;

        nodes[1].nodeType = PostfixNodeType.VALUE;
        nodes[1].value = _b;

        nodes[2].nodeType = PostfixNodeType.OPERATOR;
        nodes[2].operator = PostfixNodeOperator.MUL;

        int[] memory variables;

        return resolve(nodes, variables);
    }

    // @dev testing, remove afterwards
    function subTwoNumbers(int _a, int _b) public pure returns (int) {
        PostfixNode[] memory nodes = new PostfixNode[](3);
        nodes[0].nodeType = PostfixNodeType.VALUE;
        nodes[0].value = _a;

        nodes[1].nodeType = PostfixNodeType.VALUE;
        nodes[1].value = _b;

        nodes[2].nodeType = PostfixNodeType.OPERATOR;
        nodes[2].operator = PostfixNodeOperator.SUB;

        int[] memory variables;

        return resolve(nodes, variables);
    }

    // @dev testing, remove afterwards
    function addThreeNumbers(int _a, int _b, int _c) public pure returns (int) {
        PostfixNode[] memory nodes = new PostfixNode[](5);
        nodes[0].nodeType = PostfixNodeType.VALUE;
        nodes[0].value = _a;

        nodes[1].nodeType = PostfixNodeType.VALUE;
        nodes[1].value = _b;

        nodes[2].nodeType = PostfixNodeType.OPERATOR;
        nodes[2].operator = PostfixNodeOperator.ADD;

        nodes[3].nodeType = PostfixNodeType.VALUE;
        nodes[3].value = _c;

        nodes[4].nodeType = PostfixNodeType.OPERATOR;
        nodes[4].operator = PostfixNodeOperator.ADD;

        int[] memory variables;

        return resolve(nodes, variables);
    }

    // @dev testing, remove afterwards
    function addThenTimes(int _a, int _b, int _c) public pure returns (int) {
        PostfixNode[] memory nodes = new PostfixNode[](5);
        nodes[0].nodeType = PostfixNodeType.VALUE;
        nodes[0].value = _a;

        nodes[1].nodeType = PostfixNodeType.VALUE;
        nodes[1].value = _b;

        nodes[2].nodeType = PostfixNodeType.VALUE;
        nodes[2].value = _c;

        nodes[3].nodeType = PostfixNodeType.OPERATOR;
        nodes[3].operator = PostfixNodeOperator.MUL;

        nodes[4].nodeType = PostfixNodeType.OPERATOR;
        nodes[4].operator = PostfixNodeOperator.ADD;

        int[] memory variables;

        return resolve(nodes, variables);
    }

    // @dev testing, remove afterwards
    function timesThenAdd(int _a, int _b, int _c) public pure returns (int) {
        PostfixNode[] memory nodes = new PostfixNode[](5);
        nodes[0].nodeType = PostfixNodeType.VALUE;
        nodes[0].value = _a;

        nodes[1].nodeType = PostfixNodeType.VALUE;
        nodes[1].value = _b;

        nodes[2].nodeType = PostfixNodeType.OPERATOR;
        nodes[2].operator = PostfixNodeOperator.MUL;

        nodes[3].nodeType = PostfixNodeType.VALUE;
        nodes[3].value = _c;

        nodes[4].nodeType = PostfixNodeType.OPERATOR;
        nodes[4].operator = PostfixNodeOperator.ADD;

        int[] memory variables;

        return resolve(nodes, variables);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum PostfixNodeType {
    VALUE,
    VARIABLE,
    OPERATOR
}

enum PostfixNodeOperator {
    ADD,
    SUB,
    MUL,
    DIV,
    MOD,
    POW
}

struct PostfixNode {
    int value;
    PostfixNodeType nodeType;
    PostfixNodeOperator operator;
    uint8 variableIndex;
}

enum UmpireJobStatus {
    NEW,
    REVERTED,
    NEGATIVE,
    POSITIVE
}

enum UmpireComparator {
    EQUAL,
    NOT_EQUAL,
    GREATER_THAN,
    GREATER_THAN_EQUAL,
    LESS_THAN,
    LESS_THAN_EQUAL
}

struct UmpireJob {
    uint id;
    address owner;
    UmpireJobStatus jobStatus;
    PostfixNode[] formulaLeft;
    UmpireComparator comparator;
    PostfixNode[] formulaRight;
    address[] dataFeeds;
    uint createdAt;
    uint timeout;
    address action;
}