/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

pragma solidity ^0.8.0;

contract CalcVM {
    enum Opcode {
        IADD,
        ISUB,
        IMUL,
        IDIV,
        IINC,
        IDEC,
        FDEL,
        SWAP
    }

    function removeLastElements(int8[] memory arr, uint elements) public pure returns (int8[] memory) {
        int8[] memory result = new int8[](arr.length - elements);
        for (uint256 i = 0; i < arr.length - (elements); i++) {
            result[i] = arr[i];
        }
        return result;
    }
    function addElement(int8[] memory arr, int8 element) public pure returns (int8[] memory) {
        int8[] memory result = new int8[](arr.length+1);
        for (uint256 i = 0; i < arr.length; i++) {
            result[i] = arr[i];
        }
        result[arr.length] = element;
        return result;
    }

    function execute(bytes memory bytecode, int8[] memory stack)
        public
        pure
        returns (int8[] memory) 
    {

        for (uint i = 0; i < bytecode.length; i++) {
            uint8 opcode = uint8(bytecode[i]);

            if (opcode == uint8(Opcode.IADD)) {
                int8 x = stack[stack.length - 1];
                int8 y = stack[stack.length - 2];
                stack = removeLastElements(stack, 2);
                int8 result = x + y;
                stack = addElement(stack, result);
            } else if (opcode == uint8(Opcode.ISUB)) {
                int8 x = stack[stack.length - 1];
                int8 y = stack[stack.length - 2];
                stack = removeLastElements(stack, 2);
                int8 result = x - y;
                stack = addElement(stack, result);
            } else if (opcode == uint8(Opcode.IMUL)) {
                int8 x = stack[stack.length - 1];
                int8 y = stack[stack.length - 2];
                stack = removeLastElements(stack, 2);
                int8 result = x * y;
                stack = addElement(stack, result);
            } else if (opcode == uint8(Opcode.IDIV)) {
                int8 x = stack[stack.length - 1];
                int8 y = stack[stack.length - 2];
                stack = removeLastElements(stack, 2);
                int8 result = x / y;
                stack = addElement(stack, result);
            } else if (opcode == uint8(Opcode.IINC)) {
                int8 x = stack[stack.length - 1];
                stack = removeLastElements(stack, 1);
                int8 result = x + 1;
                stack = addElement(stack, result);
            } else if (opcode == uint8(Opcode.IDEC)) {
                int8 x = stack[stack.length - 1];
                stack = removeLastElements(stack, 1);
                int8 result = x - 1;
                stack = addElement(stack, result);
            } else if (opcode == uint8(Opcode.FDEL)) {
                stack = removeLastElements(stack, 1);
            } else if (opcode == uint8(Opcode.SWAP)) {
                int8 x = stack[stack.length - 1];
                int8 y = stack[stack.length - 2];
                stack = removeLastElements(stack, 2);
                stack = addElement(stack, x);
                stack = addElement(stack, y);
            }
        }

        return stack;
    }
}