// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../state/Value.sol";
import "../state/Machine.sol";
import "../state/Module.sol";
import "../state/Deserialize.sol";
import "./IOneStepProver.sol";

contract OneStepProverMath is IOneStepProver {
    using ValueLib for Value;
    using ValueStackLib for ValueStack;

    function executeEqz(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        Value memory v = mach.valueStack.pop();
        if (inst.opcode == Instructions.I32_EQZ) {
            require(v.valueType == ValueType.I32, "NOT_I32");
        } else if (inst.opcode == Instructions.I64_EQZ) {
            require(v.valueType == ValueType.I64, "NOT_I64");
        } else {
            revert("BAD_EQZ");
        }

        uint32 output;
        if (v.contents == 0) {
            output = 1;
        } else {
            output = 0;
        }

        mach.valueStack.push(ValueLib.newI32(output));
    }

    function signExtend(uint32 a) internal pure returns (uint64) {
        if (a & (1 << 31) != 0) {
            return uint64(a) | uint64(0xffffffff00000000);
        }
        return uint64(a);
    }

    function i64RelOp(
        uint64 a,
        uint64 b,
        uint16 relop
    ) internal pure returns (bool) {
        if (relop == Instructions.IRELOP_EQ) {
            return (a == b);
        } else if (relop == Instructions.IRELOP_NE) {
            return (a != b);
        } else if (relop == Instructions.IRELOP_LT_S) {
            return (int64(a) < int64(b));
        } else if (relop == Instructions.IRELOP_LT_U) {
            return (a < b);
        } else if (relop == Instructions.IRELOP_GT_S) {
            return (int64(a) > int64(b));
        } else if (relop == Instructions.IRELOP_GT_U) {
            return (a > b);
        } else if (relop == Instructions.IRELOP_LE_S) {
            return (int64(a) <= int64(b));
        } else if (relop == Instructions.IRELOP_LE_U) {
            return (a <= b);
        } else if (relop == Instructions.IRELOP_GE_S) {
            return (int64(a) >= int64(b));
        } else if (relop == Instructions.IRELOP_GE_U) {
            return (a >= b);
        } else {
            revert("BAD IRELOP");
        }
    }

    function executeI32RelOp(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        uint32 b = mach.valueStack.pop().assumeI32();
        uint32 a = mach.valueStack.pop().assumeI32();

        uint16 relop = inst.opcode - Instructions.I32_RELOP_BASE;
        uint64 a64;
        uint64 b64;

        if (
            relop == Instructions.IRELOP_LT_S ||
            relop == Instructions.IRELOP_GT_S ||
            relop == Instructions.IRELOP_LE_S ||
            relop == Instructions.IRELOP_GE_S
        ) {
            a64 = signExtend(a);
            b64 = signExtend(b);
        } else {
            a64 = uint64(a);
            b64 = uint64(b);
        }

        bool res = i64RelOp(a64, b64, relop);

        mach.valueStack.push(ValueLib.newBoolean(res));
    }

    function executeI64RelOp(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        uint64 b = mach.valueStack.pop().assumeI64();
        uint64 a = mach.valueStack.pop().assumeI64();

        uint16 relop = inst.opcode - Instructions.I64_RELOP_BASE;

        bool res = i64RelOp(a, b, relop);

        mach.valueStack.push(ValueLib.newBoolean(res));
    }

    function genericIUnOp(
        uint64 a,
        uint16 unop,
        uint16 bits
    ) internal pure returns (uint32) {
        require(bits == 32 || bits == 64, "WRONG USE OF genericUnOp");
        if (unop == Instructions.IUNOP_CLZ) {
            /* curbits is one-based to keep with unsigned mathematics */
            uint32 curbit = bits;
            while (curbit > 0 && (a & (1 << (curbit - 1)) == 0)) {
                curbit -= 1;
            }
            return (bits - curbit);
        } else if (unop == Instructions.IUNOP_CTZ) {
            uint32 curbit = 0;
            while (curbit < bits && ((a & (1 << curbit)) == 0)) {
                curbit += 1;
            }
            return curbit;
        } else if (unop == Instructions.IUNOP_POPCNT) {
            uint32 curbit = 0;
            uint32 res = 0;
            while (curbit < bits) {
                if ((a & (1 << curbit)) != 0) {
                    res += 1;
                }
                curbit++;
            }
            return res;
        }
        revert("BAD IUnOp");
    }

    function executeI32UnOp(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        uint32 a = mach.valueStack.pop().assumeI32();

        uint16 unop = inst.opcode - Instructions.I32_UNOP_BASE;

        uint32 res = genericIUnOp(a, unop, 32);

        mach.valueStack.push(ValueLib.newI32(res));
    }

    function executeI64UnOp(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        uint64 a = mach.valueStack.pop().assumeI64();

        uint16 unop = inst.opcode - Instructions.I64_UNOP_BASE;

        uint64 res = uint64(genericIUnOp(a, unop, 64));

        mach.valueStack.push(ValueLib.newI64(res));
    }

    function rotl32(uint32 a, uint32 b) internal pure returns (uint32) {
        b %= 32;
        return (a << b) | (a >> (32 - b));
    }

    function rotl64(uint64 a, uint64 b) internal pure returns (uint64) {
        b %= 64;
        return (a << b) | (a >> (64 - b));
    }

    function rotr32(uint32 a, uint32 b) internal pure returns (uint32) {
        b %= 32;
        return (a >> b) | (a << (32 - b));
    }

    function rotr64(uint64 a, uint64 b) internal pure returns (uint64) {
        b %= 64;
        return (a >> b) | (a << (64 - b));
    }

    function genericBinOp(
        uint64 a,
        uint64 b,
        uint16 opcodeOffset
    ) internal pure returns (uint64) {
        unchecked {
            if (opcodeOffset == 0) {
                // add
                return a + b;
            } else if (opcodeOffset == 1) {
                // sub
                return a - b;
            } else if (opcodeOffset == 2) {
                // mul
                return a * b;
            } else if (opcodeOffset == 4) {
                // div_u
                if (b == 0) {
                    return 0;
                }
                return a / b;
            } else if (opcodeOffset == 6) {
                // rem_u
                if (b == 0) {
                    return 0;
                }
                return a % b;
            } else if (opcodeOffset == 7) {
                // and
                return a & b;
            } else if (opcodeOffset == 8) {
                // or
                return a | b;
            } else if (opcodeOffset == 9) {
                // xor
                return a ^ b;
            } else {
                revert("INVALID_GENERIC_BIN_OP");
            }
        }
    }

    function executeI32BinOp(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        uint32 b = mach.valueStack.pop().assumeI32();
        uint32 a = mach.valueStack.pop().assumeI32();
        uint32 res;

        uint16 opcodeOffset = inst.opcode - Instructions.I32_ADD;

        unchecked {
            if (opcodeOffset == 3) {
                // div_s
                if (b == 0) {
                    res = 0;
                } else {
                    res = uint32(int32(a) / int32(b));
                }
            } else if (opcodeOffset == 5) {
                // rem_s
                if (b == 0) {
                    res = 0;
                } else {
                    res = uint32(int32(a) % int32(b));
                }
            } else if (opcodeOffset == 10) {
                // shl
                res = a << (b % 32);
            } else if (opcodeOffset == 12) {
                // shr_u
                res = a >> (b % 32);
            } else if (opcodeOffset == 11) {
                // shr_s
                res = uint32(int32(a) >> b);
            } else if (opcodeOffset == 13) {
                // rotl
                res = rotl32(a, b);
            } else if (opcodeOffset == 14) {
                // rotr
                res = rotr32(a, b);
            } else {
                res = uint32(genericBinOp(a, b, opcodeOffset));
            }
        }

        mach.valueStack.push(ValueLib.newI32(res));
    }

    function executeI64BinOp(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        uint64 b = mach.valueStack.pop().assumeI64();
        uint64 a = mach.valueStack.pop().assumeI64();
        uint64 res;

        uint16 opcodeOffset = inst.opcode - Instructions.I64_ADD;

        unchecked {
            if (opcodeOffset == 3) {
                // div_s
                if (b == 0) {
                    res = 0;
                } else {
                    res = uint64(int64(a) / int64(b));
                }
            } else if (opcodeOffset == 5) {
                // rem_s
                if (b == 0) {
                    res = 0;
                } else {
                    res = uint64(int64(a) % int64(b));
                }
            } else if (opcodeOffset == 10) {
                // shl
                res = a << (b % 64);
            } else if (opcodeOffset == 12) {
                // shr_u
                res = a >> (b % 64);
            } else if (opcodeOffset == 11) {
                // shr_s
                res = uint64(int64(a) >> b);
            } else if (opcodeOffset == 13) {
                // rotl
                res = rotl64(a, b);
            } else if (opcodeOffset == 14) {
                // rotr
                res = rotr64(a, b);
            } else {
                res = genericBinOp(a, b, opcodeOffset);
            }
        }

        mach.valueStack.push(ValueLib.newI64(res));
    }

    function executeI32WrapI64(
        Machine memory mach,
        Module memory,
        Instruction calldata,
        bytes calldata
    ) internal pure {
        uint64 a = mach.valueStack.pop().assumeI64();

        uint32 a32 = uint32(a);

        mach.valueStack.push(ValueLib.newI32(a32));
    }

    function executeI64ExtendI32(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        uint32 a = mach.valueStack.pop().assumeI32();

        uint64 a64;

        if (inst.opcode == Instructions.I64_EXTEND_I32_S) {
            a64 = signExtend(a);
        } else {
            a64 = uint64(a);
        }

        mach.valueStack.push(ValueLib.newI64(a64));
    }

    function executeExtendSameType(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        ValueType ty;
        uint8 sourceBits;
        if (inst.opcode == Instructions.I32_EXTEND_8S) {
            ty = ValueType.I32;
            sourceBits = 8;
        } else if (inst.opcode == Instructions.I32_EXTEND_16S) {
            ty = ValueType.I32;
            sourceBits = 16;
        } else if (inst.opcode == Instructions.I64_EXTEND_8S) {
            ty = ValueType.I64;
            sourceBits = 8;
        } else if (inst.opcode == Instructions.I64_EXTEND_16S) {
            ty = ValueType.I64;
            sourceBits = 16;
        } else if (inst.opcode == Instructions.I64_EXTEND_32S) {
            ty = ValueType.I64;
            sourceBits = 32;
        } else {
            revert("INVALID_EXTEND_SAME_TYPE");
        }
        uint256 resultMask;
        if (ty == ValueType.I32) {
            resultMask = (1 << 32) - 1;
        } else {
            resultMask = (1 << 64) - 1;
        }
        Value memory val = mach.valueStack.pop();
        require(val.valueType == ty, "BAD_EXTEND_SAME_TYPE_TYPE");
        uint256 sourceMask = (1 << sourceBits) - 1;
        val.contents &= sourceMask;
        if (val.contents & (1 << (sourceBits - 1)) != 0) {
            // Extend sign flag
            val.contents |= resultMask & ~sourceMask;
        }
        mach.valueStack.push(val);
    }

    function executeReinterpret(
        Machine memory mach,
        Module memory,
        Instruction calldata inst,
        bytes calldata
    ) internal pure {
        ValueType destTy;
        ValueType sourceTy;
        if (inst.opcode == Instructions.I32_REINTERPRET_F32) {
            destTy = ValueType.I32;
            sourceTy = ValueType.F32;
        } else if (inst.opcode == Instructions.I64_REINTERPRET_F64) {
            destTy = ValueType.I64;
            sourceTy = ValueType.F64;
        } else if (inst.opcode == Instructions.F32_REINTERPRET_I32) {
            destTy = ValueType.F32;
            sourceTy = ValueType.I32;
        } else if (inst.opcode == Instructions.F64_REINTERPRET_I64) {
            destTy = ValueType.F64;
            sourceTy = ValueType.I64;
        } else {
            revert("INVALID_REINTERPRET");
        }
        Value memory val = mach.valueStack.pop();
        require(val.valueType == sourceTy, "INVALID_REINTERPRET_TYPE");
        val.valueType = destTy;
        mach.valueStack.push(val);
    }

    function executeOneStep(
        ExecutionContext calldata,
        Machine calldata startMach,
        Module calldata startMod,
        Instruction calldata inst,
        bytes calldata proof
    ) external pure override returns (Machine memory mach, Module memory mod) {
        mach = startMach;
        mod = startMod;

        uint16 opcode = inst.opcode;

        function(Machine memory, Module memory, Instruction calldata, bytes calldata)
            internal
            pure impl;
        if (opcode == Instructions.I32_EQZ || opcode == Instructions.I64_EQZ) {
            impl = executeEqz;
        } else if (
            opcode >= Instructions.I32_RELOP_BASE &&
            opcode <= Instructions.I32_RELOP_BASE + Instructions.IRELOP_LAST
        ) {
            impl = executeI32RelOp;
        } else if (
            opcode >= Instructions.I32_UNOP_BASE &&
            opcode <= Instructions.I32_UNOP_BASE + Instructions.IUNOP_LAST
        ) {
            impl = executeI32UnOp;
        } else if (opcode >= Instructions.I32_ADD && opcode <= Instructions.I32_ROTR) {
            impl = executeI32BinOp;
        } else if (
            opcode >= Instructions.I64_RELOP_BASE &&
            opcode <= Instructions.I64_RELOP_BASE + Instructions.IRELOP_LAST
        ) {
            impl = executeI64RelOp;
        } else if (
            opcode >= Instructions.I64_UNOP_BASE &&
            opcode <= Instructions.I64_UNOP_BASE + Instructions.IUNOP_LAST
        ) {
            impl = executeI64UnOp;
        } else if (opcode >= Instructions.I64_ADD && opcode <= Instructions.I64_ROTR) {
            impl = executeI64BinOp;
        } else if (opcode == Instructions.I32_WRAP_I64) {
            impl = executeI32WrapI64;
        } else if (
            opcode == Instructions.I64_EXTEND_I32_S || opcode == Instructions.I64_EXTEND_I32_U
        ) {
            impl = executeI64ExtendI32;
        } else if (opcode >= Instructions.I32_EXTEND_8S && opcode <= Instructions.I64_EXTEND_32S) {
            impl = executeExtendSameType;
        } else if (
            opcode >= Instructions.I32_REINTERPRET_F32 && opcode <= Instructions.F64_REINTERPRET_I64
        ) {
            impl = executeReinterpret;
        } else {
            revert("INVALID_OPCODE");
        }

        impl(mach, mod, inst, proof);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

enum ValueType {
    I32,
    I64,
    F32,
    F64,
    REF_NULL,
    FUNC_REF,
    INTERNAL_REF,
    STACK_BOUNDARY
}

struct Value {
    ValueType valueType;
    uint256 contents;
}

library ValueLib {
    function hash(Value memory val) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("Value:", val.valueType, val.contents));
    }

    function maxValueType() internal pure returns (ValueType) {
        return ValueType.STACK_BOUNDARY;
    }

    function assumeI32(Value memory val) internal pure returns (uint32) {
        uint256 uintval = uint256(val.contents);
        require(val.valueType == ValueType.I32, "NOT_I32");
        require(uintval < (1 << 32), "BAD_I32");
        return uint32(uintval);
    }

    function assumeI64(Value memory val) internal pure returns (uint64) {
        uint256 uintval = uint256(val.contents);
        require(val.valueType == ValueType.I64, "NOT_I64");
        require(uintval < (1 << 64), "BAD_I64");
        return uint64(uintval);
    }

    function newRefNull() internal pure returns (Value memory) {
        return Value({valueType: ValueType.REF_NULL, contents: 0});
    }

    function newI32(uint32 x) internal pure returns (Value memory) {
        return Value({valueType: ValueType.I32, contents: uint256(x)});
    }

    function newI64(uint64 x) internal pure returns (Value memory) {
        return Value({valueType: ValueType.I64, contents: uint256(x)});
    }

    function newBoolean(bool x) internal pure returns (Value memory) {
        if (x) {
            return newI32(uint32(1));
        } else {
            return newI32(uint32(0));
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ValueStack.sol";
import "./PcStack.sol";
import "./Instructions.sol";
import "./StackFrame.sol";

enum MachineStatus {
    RUNNING,
    FINISHED,
    ERRORED,
    TOO_FAR
}

struct Machine {
    MachineStatus status;
    ValueStack valueStack;
    ValueStack internalStack;
    PcStack blockStack;
    StackFrameWindow frameStack;
    bytes32 globalStateHash;
    uint32 moduleIdx;
    uint32 functionIdx;
    uint32 functionPc;
    bytes32 modulesRoot;
}

library MachineLib {
    using PcStackLib for PcStack;
    using StackFrameLib for StackFrameWindow;
    using ValueStackLib for ValueStack;

    function hash(Machine memory mach) internal pure returns (bytes32) {
        // Warning: the non-running hashes are replicated in Challenge
        if (mach.status == MachineStatus.RUNNING) {
            return
                keccak256(
                    abi.encodePacked(
                        "Machine running:",
                        mach.valueStack.hash(),
                        mach.internalStack.hash(),
                        mach.blockStack.hash(),
                        mach.frameStack.hash(),
                        mach.globalStateHash,
                        mach.moduleIdx,
                        mach.functionIdx,
                        mach.functionPc,
                        mach.modulesRoot
                    )
                );
        } else if (mach.status == MachineStatus.FINISHED) {
            return keccak256(abi.encodePacked("Machine finished:", mach.globalStateHash));
        } else if (mach.status == MachineStatus.ERRORED) {
            return keccak256(abi.encodePacked("Machine errored:"));
        } else if (mach.status == MachineStatus.TOO_FAR) {
            return keccak256(abi.encodePacked("Machine too far:"));
        } else {
            revert("BAD_MACH_STATUS");
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ModuleMemory.sol";

struct Module {
    bytes32 globalsMerkleRoot;
    ModuleMemory moduleMemory;
    bytes32 tablesMerkleRoot;
    bytes32 functionsMerkleRoot;
    uint32 internalsOffset;
}

library ModuleLib {
    using ModuleMemoryLib for ModuleMemory;

    function hash(Module memory mod) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "Module:",
                    mod.globalsMerkleRoot,
                    mod.moduleMemory.hash(),
                    mod.tablesMerkleRoot,
                    mod.functionsMerkleRoot,
                    mod.internalsOffset
                )
            );
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Value.sol";
import "./ValueStack.sol";
import "./PcStack.sol";
import "./Machine.sol";
import "./Instructions.sol";
import "./StackFrame.sol";
import "./MerkleProof.sol";
import "./ModuleMemory.sol";
import "./Module.sol";
import "./GlobalState.sol";

library Deserialize {
    function u8(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (uint8 ret, uint256 offset)
    {
        offset = startOffset;
        ret = uint8(proof[offset]);
        offset++;
    }

    function u16(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (uint16 ret, uint256 offset)
    {
        offset = startOffset;
        for (uint256 i = 0; i < 16 / 8; i++) {
            ret <<= 8;
            ret |= uint8(proof[offset]);
            offset++;
        }
    }

    function u32(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (uint32 ret, uint256 offset)
    {
        offset = startOffset;
        for (uint256 i = 0; i < 32 / 8; i++) {
            ret <<= 8;
            ret |= uint8(proof[offset]);
            offset++;
        }
    }

    function u64(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (uint64 ret, uint256 offset)
    {
        offset = startOffset;
        for (uint256 i = 0; i < 64 / 8; i++) {
            ret <<= 8;
            ret |= uint8(proof[offset]);
            offset++;
        }
    }

    function u256(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (uint256 ret, uint256 offset)
    {
        offset = startOffset;
        for (uint256 i = 0; i < 256 / 8; i++) {
            ret <<= 8;
            ret |= uint8(proof[offset]);
            offset++;
        }
    }

    function b32(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (bytes32 ret, uint256 offset)
    {
        offset = startOffset;
        uint256 retInt;
        (retInt, offset) = u256(proof, offset);
        ret = bytes32(retInt);
    }

    function value(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (Value memory val, uint256 offset)
    {
        offset = startOffset;
        uint8 typeInt = uint8(proof[offset]);
        offset++;
        require(typeInt <= uint8(ValueLib.maxValueType()), "BAD_VALUE_TYPE");
        uint256 contents;
        (contents, offset) = u256(proof, offset);
        val = Value({valueType: ValueType(typeInt), contents: contents});
    }

    function valueStack(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (ValueStack memory stack, uint256 offset)
    {
        offset = startOffset;
        bytes32 remainingHash;
        (remainingHash, offset) = b32(proof, offset);
        uint256 provedLength;
        (provedLength, offset) = u256(proof, offset);
        Value[] memory proved = new Value[](provedLength);
        for (uint256 i = 0; i < proved.length; i++) {
            (proved[i], offset) = value(proof, offset);
        }
        stack = ValueStack({proved: ValueArray(proved), remainingHash: remainingHash});
    }

    function pcStack(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (PcStack memory stack, uint256 offset)
    {
        offset = startOffset;
        bytes32 remainingHash;
        (remainingHash, offset) = b32(proof, offset);
        uint256 provedLength;
        (provedLength, offset) = u256(proof, offset);
        uint32[] memory proved = new uint32[](provedLength);
        for (uint256 i = 0; i < proved.length; i++) {
            (proved[i], offset) = u32(proof, offset);
        }
        stack = PcStack({proved: PcArray(proved), remainingHash: remainingHash});
    }

    function instruction(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (Instruction memory inst, uint256 offset)
    {
        offset = startOffset;
        uint16 opcode;
        uint256 data;
        (opcode, offset) = u16(proof, offset);
        (data, offset) = u256(proof, offset);
        inst = Instruction({opcode: opcode, argumentData: data});
    }

    function stackFrame(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (StackFrame memory window, uint256 offset)
    {
        offset = startOffset;
        Value memory returnPc;
        bytes32 localsMerkleRoot;
        uint32 callerModule;
        uint32 callerModuleInternals;
        (returnPc, offset) = value(proof, offset);
        (localsMerkleRoot, offset) = b32(proof, offset);
        (callerModule, offset) = u32(proof, offset);
        (callerModuleInternals, offset) = u32(proof, offset);
        window = StackFrame({
            returnPc: returnPc,
            localsMerkleRoot: localsMerkleRoot,
            callerModule: callerModule,
            callerModuleInternals: callerModuleInternals
        });
    }

    function stackFrameWindow(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (StackFrameWindow memory window, uint256 offset)
    {
        offset = startOffset;
        bytes32 remainingHash;
        (remainingHash, offset) = b32(proof, offset);
        StackFrame[] memory proved;
        if (proof[offset] != 0) {
            offset++;
            proved = new StackFrame[](1);
            (proved[0], offset) = stackFrame(proof, offset);
        } else {
            offset++;
            proved = new StackFrame[](0);
        }
        window = StackFrameWindow({proved: proved, remainingHash: remainingHash});
    }

    function moduleMemory(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (ModuleMemory memory mem, uint256 offset)
    {
        offset = startOffset;
        uint64 size;
        bytes32 root;
        (size, offset) = u64(proof, offset);
        (root, offset) = b32(proof, offset);
        mem = ModuleMemory({size: size, merkleRoot: root});
    }

    function module(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (Module memory mod, uint256 offset)
    {
        offset = startOffset;
        bytes32 globalsMerkleRoot;
        ModuleMemory memory mem;
        bytes32 tablesMerkleRoot;
        bytes32 functionsMerkleRoot;
        uint32 internalsOffset;
        (globalsMerkleRoot, offset) = b32(proof, offset);
        (mem, offset) = moduleMemory(proof, offset);
        (tablesMerkleRoot, offset) = b32(proof, offset);
        (functionsMerkleRoot, offset) = b32(proof, offset);
        (internalsOffset, offset) = u32(proof, offset);
        mod = Module({
            globalsMerkleRoot: globalsMerkleRoot,
            moduleMemory: mem,
            tablesMerkleRoot: tablesMerkleRoot,
            functionsMerkleRoot: functionsMerkleRoot,
            internalsOffset: internalsOffset
        });
    }

    function globalState(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (GlobalState memory state, uint256 offset)
    {
        offset = startOffset;

        // using constant ints for array size requires newer solidity
        bytes32[2] memory bytes32Vals;
        uint64[2] memory u64Vals;

        for (uint8 i = 0; i < GlobalStateLib.BYTES32_VALS_NUM; i++) {
            (bytes32Vals[i], offset) = b32(proof, offset);
        }
        for (uint8 i = 0; i < GlobalStateLib.U64_VALS_NUM; i++) {
            (u64Vals[i], offset) = u64(proof, offset);
        }
        state = GlobalState({bytes32Vals: bytes32Vals, u64Vals: u64Vals});
    }

    function machine(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (Machine memory mach, uint256 offset)
    {
        offset = startOffset;
        MachineStatus status;
        {
            uint8 statusU8;
            (statusU8, offset) = u8(proof, offset);
            if (statusU8 == 0) {
                status = MachineStatus.RUNNING;
            } else if (statusU8 == 1) {
                status = MachineStatus.FINISHED;
            } else if (statusU8 == 2) {
                status = MachineStatus.ERRORED;
            } else if (statusU8 == 3) {
                status = MachineStatus.TOO_FAR;
            } else {
                revert("UNKNOWN_MACH_STATUS");
            }
        }
        ValueStack memory values;
        ValueStack memory internalStack;
        PcStack memory blocks;
        bytes32 globalStateHash;
        uint32 moduleIdx;
        uint32 functionIdx;
        uint32 functionPc;
        StackFrameWindow memory frameStack;
        bytes32 modulesRoot;
        (values, offset) = valueStack(proof, offset);
        (internalStack, offset) = valueStack(proof, offset);
        (blocks, offset) = pcStack(proof, offset);
        (frameStack, offset) = stackFrameWindow(proof, offset);
        (globalStateHash, offset) = b32(proof, offset);
        (moduleIdx, offset) = u32(proof, offset);
        (functionIdx, offset) = u32(proof, offset);
        (functionPc, offset) = u32(proof, offset);
        (modulesRoot, offset) = b32(proof, offset);
        mach = Machine({
            status: status,
            valueStack: values,
            internalStack: internalStack,
            blockStack: blocks,
            frameStack: frameStack,
            globalStateHash: globalStateHash,
            moduleIdx: moduleIdx,
            functionIdx: functionIdx,
            functionPc: functionPc,
            modulesRoot: modulesRoot
        });
    }

    function merkleProof(bytes calldata proof, uint256 startOffset)
        internal
        pure
        returns (MerkleProof memory merkle, uint256 offset)
    {
        offset = startOffset;
        uint8 length;
        (length, offset) = u8(proof, offset);
        bytes32[] memory counterparts = new bytes32[](length);
        for (uint8 i = 0; i < length; i++) {
            (counterparts[i], offset) = b32(proof, offset);
        }
        merkle = MerkleProof(counterparts);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../state/Machine.sol";
import "../state/Module.sol";
import "../state/Instructions.sol";
import "../bridge/ISequencerInbox.sol";
import "../bridge/IBridge.sol";

struct ExecutionContext {
    uint256 maxInboxMessagesRead;
    ISequencerInbox sequencerInbox;
    IBridge delayedBridge;
}

abstract contract IOneStepProver {
    function executeOneStep(
        ExecutionContext memory execCtx,
        Machine calldata mach,
        Module calldata mod,
        Instruction calldata instruction,
        bytes calldata proof
    ) external view virtual returns (Machine memory result, Module memory resultMod);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Value.sol";
import "./ValueArray.sol";

struct ValueStack {
    ValueArray proved;
    bytes32 remainingHash;
}

library ValueStackLib {
    using ValueLib for Value;
    using ValueArrayLib for ValueArray;

    function hash(ValueStack memory stack) internal pure returns (bytes32 h) {
        h = stack.remainingHash;
        uint256 len = stack.proved.length();
        for (uint256 i = 0; i < len; i++) {
            h = keccak256(abi.encodePacked("Value stack:", stack.proved.get(i).hash(), h));
        }
    }

    function peek(ValueStack memory stack) internal pure returns (Value memory) {
        uint256 len = stack.proved.length();
        return stack.proved.get(len - 1);
    }

    function pop(ValueStack memory stack) internal pure returns (Value memory) {
        return stack.proved.pop();
    }

    function push(ValueStack memory stack, Value memory val) internal pure {
        return stack.proved.push(val);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./PcArray.sol";

struct PcStack {
    PcArray proved;
    bytes32 remainingHash;
}

library PcStackLib {
    using PcArrayLib for PcArray;

    function hash(PcStack memory stack) internal pure returns (bytes32 h) {
        h = stack.remainingHash;
        uint256 len = stack.proved.length();
        for (uint256 i = 0; i < len; i++) {
            h = keccak256(abi.encodePacked("Program counter stack:", stack.proved.get(i), h));
        }
    }

    function pop(PcStack memory stack) internal pure returns (uint32) {
        return stack.proved.pop();
    }

    function push(PcStack memory stack, uint32 val) internal pure {
        return stack.proved.push(val);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

struct Instruction {
    uint16 opcode;
    uint256 argumentData;
}

library Instructions {
    uint16 internal constant UNREACHABLE = 0x00;
    uint16 internal constant NOP = 0x01;
    uint16 internal constant BLOCK = 0x02;
    uint16 internal constant BRANCH = 0x0C;
    uint16 internal constant BRANCH_IF = 0x0D;
    uint16 internal constant RETURN = 0x0F;
    uint16 internal constant CALL = 0x10;
    uint16 internal constant CALL_INDIRECT = 0x11;
    uint16 internal constant LOCAL_GET = 0x20;
    uint16 internal constant LOCAL_SET = 0x21;
    uint16 internal constant GLOBAL_GET = 0x23;
    uint16 internal constant GLOBAL_SET = 0x24;

    uint16 internal constant I32_LOAD = 0x28;
    uint16 internal constant I64_LOAD = 0x29;
    uint16 internal constant F32_LOAD = 0x2A;
    uint16 internal constant F64_LOAD = 0x2B;
    uint16 internal constant I32_LOAD8_S = 0x2C;
    uint16 internal constant I32_LOAD8_U = 0x2D;
    uint16 internal constant I32_LOAD16_S = 0x2E;
    uint16 internal constant I32_LOAD16_U = 0x2F;
    uint16 internal constant I64_LOAD8_S = 0x30;
    uint16 internal constant I64_LOAD8_U = 0x31;
    uint16 internal constant I64_LOAD16_S = 0x32;
    uint16 internal constant I64_LOAD16_U = 0x33;
    uint16 internal constant I64_LOAD32_S = 0x34;
    uint16 internal constant I64_LOAD32_U = 0x35;

    uint16 internal constant I32_STORE = 0x36;
    uint16 internal constant I64_STORE = 0x37;
    uint16 internal constant F32_STORE = 0x38;
    uint16 internal constant F64_STORE = 0x39;
    uint16 internal constant I32_STORE8 = 0x3A;
    uint16 internal constant I32_STORE16 = 0x3B;
    uint16 internal constant I64_STORE8 = 0x3C;
    uint16 internal constant I64_STORE16 = 0x3D;
    uint16 internal constant I64_STORE32 = 0x3E;

    uint16 internal constant MEMORY_SIZE = 0x3F;
    uint16 internal constant MEMORY_GROW = 0x40;

    uint16 internal constant DROP = 0x1A;
    uint16 internal constant SELECT = 0x1B;
    uint16 internal constant I32_CONST = 0x41;
    uint16 internal constant I64_CONST = 0x42;
    uint16 internal constant F32_CONST = 0x43;
    uint16 internal constant F64_CONST = 0x44;
    uint16 internal constant I32_EQZ = 0x45;
    uint16 internal constant I32_RELOP_BASE = 0x46;
    uint16 internal constant IRELOP_EQ = 0;
    uint16 internal constant IRELOP_NE = 1;
    uint16 internal constant IRELOP_LT_S = 2;
    uint16 internal constant IRELOP_LT_U = 3;
    uint16 internal constant IRELOP_GT_S = 4;
    uint16 internal constant IRELOP_GT_U = 5;
    uint16 internal constant IRELOP_LE_S = 6;
    uint16 internal constant IRELOP_LE_U = 7;
    uint16 internal constant IRELOP_GE_S = 8;
    uint16 internal constant IRELOP_GE_U = 9;
    uint16 internal constant IRELOP_LAST = IRELOP_GE_U;

    uint16 internal constant I64_EQZ = 0x50;
    uint16 internal constant I64_RELOP_BASE = 0x51;

    uint16 internal constant I32_UNOP_BASE = 0x67;
    uint16 internal constant IUNOP_CLZ = 0;
    uint16 internal constant IUNOP_CTZ = 1;
    uint16 internal constant IUNOP_POPCNT = 2;
    uint16 internal constant IUNOP_LAST = IUNOP_POPCNT;

    uint16 internal constant I32_ADD = 0x6A;
    uint16 internal constant I32_SUB = 0x6B;
    uint16 internal constant I32_MUL = 0x6C;
    uint16 internal constant I32_DIV_S = 0x6D;
    uint16 internal constant I32_DIV_U = 0x6E;
    uint16 internal constant I32_REM_S = 0x6F;
    uint16 internal constant I32_REM_U = 0x70;
    uint16 internal constant I32_AND = 0x71;
    uint16 internal constant I32_OR = 0x72;
    uint16 internal constant I32_XOR = 0x73;
    uint16 internal constant I32_SHL = 0x74;
    uint16 internal constant I32_SHR_S = 0x75;
    uint16 internal constant I32_SHR_U = 0x76;
    uint16 internal constant I32_ROTL = 0x77;
    uint16 internal constant I32_ROTR = 0x78;

    uint16 internal constant I64_UNOP_BASE = 0x79;

    uint16 internal constant I64_ADD = 0x7C;
    uint16 internal constant I64_SUB = 0x7D;
    uint16 internal constant I64_MUL = 0x7E;
    uint16 internal constant I64_DIV_S = 0x7F;
    uint16 internal constant I64_DIV_U = 0x80;
    uint16 internal constant I64_REM_S = 0x81;
    uint16 internal constant I64_REM_U = 0x82;
    uint16 internal constant I64_AND = 0x83;
    uint16 internal constant I64_OR = 0x84;
    uint16 internal constant I64_XOR = 0x85;
    uint16 internal constant I64_SHL = 0x86;
    uint16 internal constant I64_SHR_S = 0x87;
    uint16 internal constant I64_SHR_U = 0x88;
    uint16 internal constant I64_ROTL = 0x89;
    uint16 internal constant I64_ROTR = 0x8A;

    uint16 internal constant I32_WRAP_I64 = 0xA7;
    uint16 internal constant I64_EXTEND_I32_S = 0xAC;
    uint16 internal constant I64_EXTEND_I32_U = 0xAD;

    uint16 internal constant I32_REINTERPRET_F32 = 0xBC;
    uint16 internal constant I64_REINTERPRET_F64 = 0xBD;
    uint16 internal constant F32_REINTERPRET_I32 = 0xBE;
    uint16 internal constant F64_REINTERPRET_I64 = 0xBF;

    uint16 internal constant I32_EXTEND_8S = 0xC0;
    uint16 internal constant I32_EXTEND_16S = 0xC1;
    uint16 internal constant I64_EXTEND_8S = 0xC2;
    uint16 internal constant I64_EXTEND_16S = 0xC3;
    uint16 internal constant I64_EXTEND_32S = 0xC4;

    uint16 internal constant END_BLOCK = 0x8000;
    uint16 internal constant END_BLOCK_IF = 0x8001;
    uint16 internal constant INIT_FRAME = 0x8002;
    uint16 internal constant ARBITRARY_JUMP_IF = 0x8003;
    uint16 internal constant PUSH_STACK_BOUNDARY = 0x8004;
    uint16 internal constant MOVE_FROM_STACK_TO_INTERNAL = 0x8005;
    uint16 internal constant MOVE_FROM_INTERNAL_TO_STACK = 0x8006;
    uint16 internal constant IS_STACK_BOUNDARY = 0x8007;
    uint16 internal constant DUP = 0x8008;
    uint16 internal constant CROSS_MODULE_CALL = 0x8009;
    uint16 internal constant CALLER_MODULE_INTERNAL_CALL = 0x800A;

    uint16 internal constant GET_GLOBAL_STATE_BYTES32 = 0x8010;
    uint16 internal constant SET_GLOBAL_STATE_BYTES32 = 0x8011;
    uint16 internal constant GET_GLOBAL_STATE_U64 = 0x8012;
    uint16 internal constant SET_GLOBAL_STATE_U64 = 0x8013;

    uint16 internal constant READ_PRE_IMAGE = 0x8020;
    uint16 internal constant READ_INBOX_MESSAGE = 0x8021;
    uint16 internal constant HALT_AND_SET_FINISHED = 0x8022;

    uint256 internal constant INBOX_INDEX_SEQUENCER = 0;
    uint256 internal constant INBOX_INDEX_DELAYED = 1;

    function hash(Instruction memory inst) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("Instruction:", inst.opcode, inst.argumentData));
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Value.sol";

struct StackFrame {
    Value returnPc;
    bytes32 localsMerkleRoot;
    uint32 callerModule;
    uint32 callerModuleInternals;
}

struct StackFrameWindow {
    StackFrame[] proved;
    bytes32 remainingHash;
}

library StackFrameLib {
    using ValueLib for Value;

    function hash(StackFrame memory frame) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "Stack frame:",
                    frame.returnPc.hash(),
                    frame.localsMerkleRoot,
                    frame.callerModule,
                    frame.callerModuleInternals
                )
            );
    }

    function hash(StackFrameWindow memory window) internal pure returns (bytes32 h) {
        h = window.remainingHash;
        for (uint256 i = 0; i < window.proved.length; i++) {
            h = keccak256(abi.encodePacked("Stack frame stack:", hash(window.proved[i]), h));
        }
    }

    function peek(StackFrameWindow memory window) internal pure returns (StackFrame memory) {
        require(window.proved.length == 1, "BAD_WINDOW_LENGTH");
        return window.proved[0];
    }

    function pop(StackFrameWindow memory window) internal pure returns (StackFrame memory frame) {
        require(window.proved.length == 1, "BAD_WINDOW_LENGTH");
        frame = window.proved[0];
        window.proved = new StackFrame[](0);
    }

    function push(StackFrameWindow memory window, StackFrame memory frame) internal pure {
        StackFrame[] memory newProved = new StackFrame[](window.proved.length + 1);
        for (uint256 i = 0; i < window.proved.length; i++) {
            newProved[i] = window.proved[i];
        }
        newProved[window.proved.length] = frame;
        window.proved = newProved;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Value.sol";

struct ValueArray {
    Value[] inner;
}

library ValueArrayLib {
    function get(ValueArray memory arr, uint256 index) internal pure returns (Value memory) {
        return arr.inner[index];
    }

    function set(
        ValueArray memory arr,
        uint256 index,
        Value memory val
    ) internal pure {
        arr.inner[index] = val;
    }

    function length(ValueArray memory arr) internal pure returns (uint256) {
        return arr.inner.length;
    }

    function push(ValueArray memory arr, Value memory val) internal pure {
        Value[] memory newInner = new Value[](arr.inner.length + 1);
        for (uint256 i = 0; i < arr.inner.length; i++) {
            newInner[i] = arr.inner[i];
        }
        newInner[arr.inner.length] = val;
        arr.inner = newInner;
    }

    function pop(ValueArray memory arr) internal pure returns (Value memory popped) {
        popped = arr.inner[arr.inner.length - 1];
        Value[] memory newInner = new Value[](arr.inner.length - 1);
        for (uint256 i = 0; i < newInner.length; i++) {
            newInner[i] = arr.inner[i];
        }
        arr.inner = newInner;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

struct PcArray {
    uint32[] inner;
}

library PcArrayLib {
    function get(PcArray memory arr, uint256 index) internal pure returns (uint32) {
        return arr.inner[index];
    }

    function set(
        PcArray memory arr,
        uint256 index,
        uint32 val
    ) internal pure {
        arr.inner[index] = val;
    }

    function length(PcArray memory arr) internal pure returns (uint256) {
        return arr.inner.length;
    }

    function push(PcArray memory arr, uint32 val) internal pure {
        uint32[] memory newInner = new uint32[](arr.inner.length + 1);
        for (uint256 i = 0; i < arr.inner.length; i++) {
            newInner[i] = arr.inner[i];
        }
        newInner[arr.inner.length] = val;
        arr.inner = newInner;
    }

    function pop(PcArray memory arr) internal pure returns (uint32 popped) {
        popped = arr.inner[arr.inner.length - 1];
        uint32[] memory newInner = new uint32[](arr.inner.length - 1);
        for (uint256 i = 0; i < newInner.length; i++) {
            newInner[i] = arr.inner[i];
        }
        arr.inner = newInner;
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Deserialize.sol";

struct ModuleMemory {
    uint64 size;
    bytes32 merkleRoot;
}

library ModuleMemoryLib {
    using MerkleProofLib for MerkleProof;

    function hash(ModuleMemory memory mem) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("Memory:", mem.size, mem.merkleRoot));
    }

    function proveLeaf(
        ModuleMemory memory mem,
        uint256 leafIdx,
        bytes calldata proof,
        uint256 startOffset
    )
        internal
        pure
        returns (
            bytes32 contents,
            uint256 offset,
            MerkleProof memory merkle
        )
    {
        offset = startOffset;
        (contents, offset) = Deserialize.b32(proof, offset);
        (merkle, offset) = Deserialize.merkleProof(proof, offset);
        bytes32 recomputedRoot = merkle.computeRootFromMemory(leafIdx, contents);
        require(recomputedRoot == mem.merkleRoot, "WRONG_MEM_ROOT");
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Value.sol";
import "./Instructions.sol";
import "./Module.sol";

struct MerkleProof {
    bytes32[] counterparts;
}

library MerkleProofLib {
    using ModuleLib for Module;
    using ValueLib for Value;

    function computeRootFromValue(
        MerkleProof memory proof,
        uint256 index,
        Value memory leaf
    ) internal pure returns (bytes32) {
        return computeRootUnsafe(proof, index, leaf.hash(), "Value merkle tree:");
    }

    function computeRootFromInstruction(
        MerkleProof memory proof,
        uint256 index,
        Instruction memory inst
    ) internal pure returns (bytes32) {
        return computeRootUnsafe(proof, index, Instructions.hash(inst), "Instruction merkle tree:");
    }

    function computeRootFromFunction(
        MerkleProof memory proof,
        uint256 index,
        bytes32 codeRoot
    ) internal pure returns (bytes32) {
        bytes32 h = keccak256(abi.encodePacked("Function:", codeRoot));
        return computeRootUnsafe(proof, index, h, "Function merkle tree:");
    }

    function computeRootFromMemory(
        MerkleProof memory proof,
        uint256 index,
        bytes32 contents
    ) internal pure returns (bytes32) {
        bytes32 h = keccak256(abi.encodePacked("Memory leaf:", contents));
        return computeRootUnsafe(proof, index, h, "Memory merkle tree:");
    }

    function computeRootFromElement(
        MerkleProof memory proof,
        uint256 index,
        bytes32 funcTypeHash,
        Value memory val
    ) internal pure returns (bytes32) {
        bytes32 h = keccak256(abi.encodePacked("Table element:", funcTypeHash, val.hash()));
        return computeRootUnsafe(proof, index, h, "Table element merkle tree:");
    }

    function computeRootFromTable(
        MerkleProof memory proof,
        uint256 index,
        uint8 tableType,
        uint64 tableSize,
        bytes32 elementsRoot
    ) internal pure returns (bytes32) {
        bytes32 h = keccak256(abi.encodePacked("Table:", tableType, tableSize, elementsRoot));
        return computeRootUnsafe(proof, index, h, "Table merkle tree:");
    }

    function computeRootFromModule(
        MerkleProof memory proof,
        uint256 index,
        Module memory mod
    ) internal pure returns (bytes32) {
        return computeRootUnsafe(proof, index, mod.hash(), "Module merkle tree:");
    }

    // WARNING: leafHash must be computed in such a way that it cannot be a non-leaf hash.
    function computeRootUnsafe(
        MerkleProof memory proof,
        uint256 index,
        bytes32 leafHash,
        string memory prefix
    ) internal pure returns (bytes32 h) {
        h = leafHash;
        for (uint256 layer = 0; layer < proof.counterparts.length; layer++) {
            if (index & 1 == 0) {
                h = keccak256(abi.encodePacked(prefix, h, proof.counterparts[layer]));
            } else {
                h = keccak256(abi.encodePacked(prefix, proof.counterparts[layer], h));
            }
            index >>= 1;
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

struct GlobalState {
    bytes32[2] bytes32Vals;
    uint64[2] u64Vals;
}

library GlobalStateLib {
    uint16 internal constant BYTES32_VALS_NUM = 2;
    uint16 internal constant U64_VALS_NUM = 2;

    function hash(GlobalState memory state) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "Global state:",
                    state.bytes32Vals[0],
                    state.bytes32Vals[1],
                    state.u64Vals[0],
                    state.u64Vals[1]
                )
            );
    }

    function getBlockHash(GlobalState memory state) internal pure returns (bytes32) {
        return state.bytes32Vals[0];
    }

    function getSendRoot(GlobalState memory state) internal pure returns (bytes32) {
        return state.bytes32Vals[1];
    }

    function getInboxPosition(GlobalState memory state) internal pure returns (uint64) {
        return state.u64Vals[0];
    }

    function getPositionInMessage(GlobalState memory state) internal pure returns (uint64) {
        return state.u64Vals[1];
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../libraries/IGasRefunder.sol";
import {AlreadyInit, HadZeroInit, NotOrigin, DataTooLarge, NotRollup} from "../libraries/Error.sol";

interface ISequencerInbox {
    struct MaxTimeVariation {
        uint256 delayBlocks;
        uint256 futureBlocks;
        uint256 delaySeconds;
        uint256 futureSeconds;
    }

    struct TimeBounds {
        uint64 minTimestamp;
        uint64 maxTimestamp;
        uint64 minBlockNumber;
        uint64 maxBlockNumber;
    }

    enum BatchDataLocation {
        TxInput,
        SeparateBatchEvent,
        NoData
    }

    event SequencerBatchDelivered(
        uint256 indexed batchSequenceNumber,
        bytes32 indexed beforeAcc,
        bytes32 indexed afterAcc,
        bytes32 delayedAcc,
        uint256 afterDelayedMessagesRead,
        TimeBounds timeBounds,
        BatchDataLocation dataLocation
    );

    /// @dev a separate event that emits batch data when this isn't easily accessible in the tx.input
    event SequencerBatchData(uint256 indexed batchSequenceNumber, bytes data);

    /// @dev Thrown when someone attempts to read fewer messages than have already been read
    error DelayedBackwards();

    /// @dev Thrown when someone attempts to read more messages than exist
    error DelayedTooFar();

    /// @dev Thrown if the length of the header plus the length of the batch overflows
    error DataLengthOverflow();

    /// @dev Force include can only read messages more blocks old than the delay period
    error ForceIncludeBlockTooSoon();

    /// @dev Force include can only read messages more seconds old than the delay period
    error ForceIncludeTimeTooSoon();

    /// @dev The message provided did not match the hash in the delayed inbox
    error IncorrectMessagePreimage();

    /// @dev This can only be called by the batch poster
    error NotBatchPoster();

    /// @dev The sequence number provided to this message was inconsistent with the number of batches already included
    error BadSequencerNumber();

    /// @dev The batch data has the inbox authenticated bit set, but the batch data was not authenticated by the inbox
    error DataNotAuthenticated();

    function inboxAccs(uint256 index) external view returns (bytes32);

    function batchCount() external view returns (uint256);

    function setMaxTimeVariation(MaxTimeVariation memory timeVariation) external;

    function setIsBatchPoster(address addr, bool isBatchPoster_) external;

    function addSequencerL2Batch(
        uint256 sequenceNumber,
        bytes calldata data,
        uint256 afterDelayedMessagesRead,
        IGasRefunder gasRefunder
    ) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import {NotContract} from "../libraries/Error.sol";

/// @dev Thrown when an un-authorized address tries to access an only-inbox function
/// @param sender The un-authorized sender
error NotInbox(address sender);

/// @dev Thrown when an un-authorized address tries to access an only-outbox function
/// @param sender The un-authorized sender
error NotOutbox(address sender);

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash,
        uint256 baseFeeL1,
        uint64 timestamp
    );

    event BridgeCallTriggered(
        address indexed outbox,
        address indexed to,
        uint256 value,
        bytes data
    );

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

    function enqueueDelayedMessage(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    // These are only callable by the admin
    function setInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // View functions

    function activeOutbox() external view returns (address);

    function allowedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.6.11 <0.9.0;

interface IGasRefunder {
    function onGasSpent(
        address payable spender,
        uint256 gasUsed,
        uint256 calldataSize
    ) external returns (bool success);
}

abstract contract GasRefundEnabled {
    modifier refundsGasWithCalldata(IGasRefunder gasRefunder, address payable spender) {
        uint256 startGasLeft = gasleft();
        _;
        if (address(gasRefunder) != address(0)) {
            uint256 calldataSize;
            assembly {
                calldataSize := calldatasize()
            }
            gasRefunder.onGasSpent(spender, startGasLeft - gasleft(), calldataSize);
        }
    }

    modifier refundsGasNoCalldata(IGasRefunder gasRefunder, address payable spender) {
        uint256 startGasLeft = gasleft();
        _;
        if (address(gasRefunder) != address(0)) {
            gasRefunder.onGasSpent(spender, startGasLeft - gasleft(), 0);
        }
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

/// @dev Init was already called
error AlreadyInit();

/// Init was called with param set to zero that must be nonzero
error HadZeroInit();

/// @dev Thrown when non owner tries to access an only-owner function
/// @param sender The msg.sender who is not the owner
/// @param owner The owner address
error NotOwner(address sender, address owner);

/// @dev Thrown when an address that is not the rollup tries to call an only-rollup function
/// @param sender The sender who is not the rollup
/// @param rollup The rollup address authorized to call this function
error NotRollup(address sender, address rollup);

/// @dev Thrown when the contract was not called directly from the origin ie msg.sender != tx.origin
error NotOrigin();

/// @dev Provided data was too large
/// @param dataLength The length of the data that is too large
/// @param maxDataLength The max length the data can be
error DataTooLarge(uint256 dataLength, uint256 maxDataLength);

/// @dev The provided is not a contract and was expected to be
/// @param addr The adddress in question
error NotContract(address addr);

/// @dev The merkle proof provided was too long
/// @param actualLength The length of the merkle proof provided
/// @param maxProofLength The max length a merkle proof can have
error MerkleProofTooLong(uint256 actualLength, uint256 maxProofLength);