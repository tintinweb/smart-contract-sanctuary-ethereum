// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import "./Topology.sol";

/**
 * @title Integrity, A library that validates condition integrity, and
 * adherence to the expected input structure and rules.
 * @author Cristóvão Honorato - <[email protected]>
 */
library Integrity {
    error UnsuitableRootNode();

    error NotBFS();

    error UnsuitableParameterType(uint256 index);

    error UnsuitableCompValue(uint256 index);

    error UnsupportedOperator(uint256 index);

    error UnsuitableParent(uint256 index);

    error UnsuitableChildCount(uint256 index);

    error UnsuitableChildTypeTree(uint256 index);

    function enforce(ConditionFlat[] memory conditions) external pure {
        _root(conditions);
        for (uint256 i = 0; i < conditions.length; ++i) {
            _node(conditions[i], i);
        }
        _tree(conditions);
    }

    function _root(ConditionFlat[] memory conditions) private pure {
        uint256 count;

        for (uint256 i; i < conditions.length; ++i) {
            if (conditions[i].parent == i) ++count;
        }
        if (count != 1 || conditions[0].parent != 0) {
            revert UnsuitableRootNode();
        }
    }

    function _node(ConditionFlat memory condition, uint256 index) private pure {
        Operator operator = condition.operator;
        ParameterType paramType = condition.paramType;
        bytes memory compValue = condition.compValue;
        if (operator == Operator.Pass) {
            if (condition.compValue.length != 0) {
                revert UnsuitableCompValue(index);
            }
        } else if (operator >= Operator.And && operator <= Operator.Nor) {
            if (paramType != ParameterType.None) {
                revert UnsuitableParameterType(index);
            }
            if (condition.compValue.length != 0) {
                revert UnsuitableCompValue(index);
            }
        } else if (operator == Operator.Matches) {
            if (
                paramType != ParameterType.Tuple &&
                paramType != ParameterType.Array &&
                paramType != ParameterType.AbiEncoded
            ) {
                revert UnsuitableParameterType(index);
            }
            if (compValue.length != 0) {
                revert UnsuitableCompValue(index);
            }
        } else if (
            operator == Operator.ArraySome ||
            operator == Operator.ArrayEvery ||
            operator == Operator.ArraySubset
        ) {
            if (paramType != ParameterType.Array) {
                revert UnsuitableParameterType(index);
            }
            if (compValue.length != 0) {
                revert UnsuitableCompValue(index);
            }
        } else if (operator == Operator.EqualToAvatar) {
            if (paramType != ParameterType.Static) {
                revert UnsuitableParameterType(index);
            }
            if (compValue.length != 0) {
                revert UnsuitableCompValue(index);
            }
        } else if (operator == Operator.EqualTo) {
            if (
                paramType != ParameterType.Static &&
                paramType != ParameterType.Dynamic &&
                paramType != ParameterType.Tuple &&
                paramType != ParameterType.Array
            ) {
                revert UnsuitableParameterType(index);
            }
            if (compValue.length == 0 || compValue.length % 32 != 0) {
                revert UnsuitableCompValue(index);
            }
        } else if (
            operator == Operator.GreaterThan ||
            operator == Operator.LessThan ||
            operator == Operator.SignedIntGreaterThan ||
            operator == Operator.SignedIntLessThan
        ) {
            if (paramType != ParameterType.Static) {
                revert UnsuitableParameterType(index);
            }
            if (compValue.length != 32) {
                revert UnsuitableCompValue(index);
            }
        } else if (operator == Operator.Bitmask) {
            if (
                paramType != ParameterType.Static &&
                paramType != ParameterType.Dynamic
            ) {
                revert UnsuitableParameterType(index);
            }
            if (compValue.length != 32) {
                revert UnsuitableCompValue(index);
            }
        } else if (operator == Operator.Custom) {
            if (compValue.length != 32) {
                revert UnsuitableCompValue(index);
            }
        } else if (operator == Operator.WithinAllowance) {
            if (paramType != ParameterType.Static) {
                revert UnsuitableParameterType(index);
            }
            if (compValue.length != 32) {
                revert UnsuitableCompValue(index);
            }
        } else if (
            operator == Operator.EtherWithinAllowance ||
            operator == Operator.CallWithinAllowance
        ) {
            if (paramType != ParameterType.None) {
                revert UnsuitableParameterType(index);
            }
            if (compValue.length != 32) {
                revert UnsuitableCompValue(index);
            }
        } else {
            revert UnsupportedOperator(index);
        }
    }

    function _tree(ConditionFlat[] memory conditions) private pure {
        uint256 length = conditions.length;
        // check BFS
        for (uint256 i = 1; i < length; ++i) {
            if (conditions[i - 1].parent > conditions[i].parent) {
                revert NotBFS();
            }
        }

        for (uint256 i = 0; i < length; ++i) {
            if (
                (conditions[i].operator == Operator.EtherWithinAllowance ||
                    conditions[i].operator == Operator.CallWithinAllowance) &&
                conditions[conditions[i].parent].paramType !=
                ParameterType.AbiEncoded
            ) {
                revert UnsuitableParent(i);
            }
        }

        Topology.Bounds[] memory childrenBounds = Topology.childrenBounds(
            conditions
        );

        for (uint256 i = 0; i < conditions.length; i++) {
            ConditionFlat memory condition = conditions[i];
            Topology.Bounds memory childBounds = childrenBounds[i];

            if (condition.paramType == ParameterType.None) {
                if (
                    (condition.operator == Operator.EtherWithinAllowance ||
                        condition.operator == Operator.CallWithinAllowance) &&
                    childBounds.length != 0
                ) {
                    revert UnsuitableChildCount(i);
                }
                if (
                    (condition.operator >= Operator.And &&
                        condition.operator <= Operator.Nor)
                ) {
                    if (childBounds.length == 0) {
                        revert UnsuitableChildCount(i);
                    }
                }
            } else if (
                condition.paramType == ParameterType.Static ||
                condition.paramType == ParameterType.Dynamic
            ) {
                if (childBounds.length != 0) {
                    revert UnsuitableChildCount(i);
                }
            } else if (
                condition.paramType == ParameterType.Tuple ||
                condition.paramType == ParameterType.AbiEncoded
            ) {
                if (childBounds.length == 0) {
                    revert UnsuitableChildCount(i);
                }
            } else {
                assert(condition.paramType == ParameterType.Array);

                if (childBounds.length == 0) {
                    revert UnsuitableChildCount(i);
                }

                if (
                    (condition.operator == Operator.ArraySome ||
                        condition.operator == Operator.ArrayEvery) &&
                    childBounds.length != 1
                ) {
                    revert UnsuitableChildCount(i);
                } else if (
                    condition.operator == Operator.ArraySubset &&
                    childBounds.length > 256
                ) {
                    revert UnsuitableChildCount(i);
                }
            }
        }

        for (uint256 i = 0; i < conditions.length; i++) {
            ConditionFlat memory condition = conditions[i];
            if (
                ((condition.operator >= Operator.And &&
                    condition.operator <= Operator.Nor) ||
                    condition.paramType == ParameterType.Array) &&
                childrenBounds[i].length > 1
            ) {
                compatiblechildTypeTree(conditions, i, childrenBounds);
            }
        }

        Topology.TypeTree memory typeTree = Topology.typeTree(
            conditions,
            0,
            childrenBounds
        );

        if (typeTree.paramType != ParameterType.AbiEncoded) {
            revert UnsuitableRootNode();
        }
    }

    function compatiblechildTypeTree(
        ConditionFlat[] memory conditions,
        uint256 index,
        Topology.Bounds[] memory childrenBounds
    ) private pure {
        uint256 start = childrenBounds[index].start;
        uint256 end = childrenBounds[index].end;

        bytes32 id = typeTreeId(
            Topology.typeTree(conditions, start, childrenBounds)
        );
        for (uint256 j = start + 1; j < end; ++j) {
            if (
                id !=
                typeTreeId(Topology.typeTree(conditions, j, childrenBounds))
            ) {
                revert UnsuitableChildTypeTree(index);
            }
        }
    }

    function typeTreeId(
        Topology.TypeTree memory node
    ) private pure returns (bytes32) {
        uint256 childCount = node.children.length;
        if (childCount > 0) {
            bytes32[] memory ids = new bytes32[](node.children.length);
            for (uint256 i = 0; i < childCount; ++i) {
                ids[i] = typeTreeId(node.children[i]);
            }

            return keccak256(abi.encodePacked(node.paramType, "-", ids));
        } else {
            return bytes32(uint256(node.paramType));
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import "./Types.sol";

/**
 * @title Topology - a library that provides helper functions for dealing with
 * the flat representation of conditions.
 * @author Cristóvão Honorato - <[email protected]>
 */
library Topology {
    struct TypeTree {
        ParameterType paramType;
        TypeTree[] children;
    }

    struct Bounds {
        uint256 start;
        uint256 end;
        uint256 length;
    }

    function childrenBounds(
        ConditionFlat[] memory conditions
    ) internal pure returns (Bounds[] memory result) {
        uint256 count = conditions.length;
        assert(count > 0);

        // parents are breadth-first
        result = new Bounds[](count);
        result[0].start = type(uint256).max;

        // first item is the root
        for (uint256 i = 1; i < count; ) {
            result[i].start = type(uint256).max;
            Bounds memory parentBounds = result[conditions[i].parent];
            if (parentBounds.start == type(uint256).max) {
                parentBounds.start = i;
            }
            parentBounds.end = i + 1;
            parentBounds.length = parentBounds.end - parentBounds.start;
            unchecked {
                ++i;
            }
        }
    }

    function isInline(TypeTree memory node) internal pure returns (bool) {
        ParameterType paramType = node.paramType;
        if (paramType == ParameterType.Static) {
            return true;
        } else if (
            paramType == ParameterType.Dynamic ||
            paramType == ParameterType.Array ||
            paramType == ParameterType.AbiEncoded
        ) {
            return false;
        } else {
            uint256 length = node.children.length;

            for (uint256 i; i < length; ) {
                if (!isInline(node.children[i])) {
                    return false;
                }
                unchecked {
                    ++i;
                }
            }
            return true;
        }
    }

    function typeTree(
        Condition memory condition
    ) internal pure returns (TypeTree memory result) {
        if (
            condition.operator >= Operator.And &&
            condition.operator <= Operator.Nor
        ) {
            assert(condition.children.length > 0);
            return typeTree(condition.children[0]);
        }

        result.paramType = condition.paramType;
        if (condition.children.length > 0) {
            uint256 length = condition.paramType == ParameterType.Array
                ? 1
                : condition.children.length;
            result.children = new TypeTree[](length);

            for (uint256 i; i < length; ) {
                result.children[i] = typeTree(condition.children[i]);

                unchecked {
                    ++i;
                }
            }
        }
    }

    function typeTree(
        ConditionFlat[] memory conditions,
        uint256 index,
        Bounds[] memory bounds
    ) internal pure returns (TypeTree memory result) {
        ConditionFlat memory condition = conditions[index];
        if (
            condition.operator >= Operator.And &&
            condition.operator <= Operator.Nor
        ) {
            assert(bounds[index].length > 0);
            return typeTree(conditions, bounds[index].start, bounds);
        }

        result.paramType = condition.paramType;
        if (bounds[index].length > 0) {
            uint256 start = bounds[index].start;
            uint256 end = condition.paramType == ParameterType.Array
                ? bounds[index].start + 1
                : bounds[index].end;
            result.children = new TypeTree[](end - start);
            for (uint256 i = start; i < end; ) {
                result.children[i - start] = typeTree(conditions, i, bounds);
                unchecked {
                    ++i;
                }
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

/**
 * @title Types - a file that contains all of the type definitions used throughout
 * the Zodiac Roles Mod.
 * @author Cristóvão Honorato - <[email protected]>
 * @author Jan-Felix Schwarz  - <[email protected]>
 */
enum ParameterType {
    None,
    Static,
    Dynamic,
    Tuple,
    Array,
    AbiEncoded
}

enum Operator {
    // 00:    EMPTY EXPRESSION (default, always passes)
    //          paramType: Static / Dynamic / Tuple / Array
    //          ❓ children (only for paramType: Tuple / Array to describe their structure)
    //          🚫 compValue
    /* 00: */ Pass,
    // ------------------------------------------------------------
    // 01-04: LOGICAL EXPRESSIONS
    //          paramType: None
    //          ✅ children
    //          🚫 compValue
    /* 01: */ And,
    /* 02: */ Or,
    /* 03: */ Nor,
    /* 04: */ _Placeholder04,
    // ------------------------------------------------------------
    // 05-14: COMPLEX EXPRESSIONS
    //          paramType: AbiEncoded / Tuple / Array,
    //          ✅ children
    //          🚫 compValue
    /* 05: */ Matches,
    /* 06: */ ArraySome,
    /* 07: */ ArrayEvery,
    /* 08: */ ArraySubset,
    /* 09: */ _Placeholder09,
    /* 10: */ _Placeholder10,
    /* 11: */ _Placeholder11,
    /* 12: */ _Placeholder12,
    /* 13: */ _Placeholder13,
    /* 14: */ _Placeholder14,
    // ------------------------------------------------------------
    // 15:    SPECIAL COMPARISON (without compValue)
    //          paramType: Static
    //          🚫 children
    //          🚫 compValue
    /* 15: */ EqualToAvatar,
    // ------------------------------------------------------------
    // 16-31: COMPARISON EXPRESSIONS
    //          paramType: Static / Dynamic / Tuple / Array
    //          ❓ children (only for paramType: Tuple / Array to describe their structure)
    //          ✅ compValue
    /* 16: */ EqualTo, // paramType: Static / Dynamic / Tuple / Array
    /* 17: */ GreaterThan, // paramType: Static
    /* 18: */ LessThan, // paramType: Static
    /* 19: */ SignedIntGreaterThan, // paramType: Static
    /* 20: */ SignedIntLessThan, // paramType: Static
    /* 21: */ Bitmask, // paramType: Static / Dynamic
    /* 22: */ Custom, // paramType: Static / Dynamic / Tuple / Array
    /* 23: */ _Placeholder23,
    /* 24: */ _Placeholder24,
    /* 25: */ _Placeholder25,
    /* 26: */ _Placeholder26,
    /* 27: */ _Placeholder27,
    /* 28: */ WithinAllowance, // paramType: Static
    /* 29: */ EtherWithinAllowance, // paramType: None
    /* 30: */ CallWithinAllowance, // paramType: None
    /* 31: */ _Placeholder31
}

enum ExecutionOptions {
    None,
    Send,
    DelegateCall,
    Both
}

enum Clearance {
    None,
    Target,
    Function
}

// This struct is a flattened version of Condition
// used for ABI encoding a scope config tree
// (ABI does not support recursive types)
struct ConditionFlat {
    uint8 parent;
    ParameterType paramType;
    Operator operator;
    bytes compValue;
}

struct Condition {
    ParameterType paramType;
    Operator operator;
    bytes32 compValue;
    Condition[] children;
}
struct ParameterPayload {
    uint256 location;
    uint256 size;
    ParameterPayload[] children;
}

struct TargetAddress {
    Clearance clearance;
    ExecutionOptions options;
}

struct Role {
    mapping(address => bool) members;
    mapping(address => TargetAddress) targets;
    mapping(bytes32 => bytes32) scopeConfig;
}

struct Allowance {
    // refillInterval - duration of the period in seconds, 0 for one-time allowance
    // refillAmount - amount that will be replenished "at the start of every period" (replace with: per period)
    // refillTimestamp - timestamp of the last interval refilled for;
    // maxBalance - max accrual amount, replenishing stops once the unused allowance hits this value
    // balance - unused allowance;

    // order matters
    uint128 refillAmount;
    uint128 maxBalance;
    uint64 refillInterval;
    // only these these two fields are updated on accrual, should live in the same word
    uint128 balance;
    uint64 refillTimestamp;
}

struct Consumption {
    bytes32 allowanceKey;
    uint128 balance;
    uint128 consumed;
}