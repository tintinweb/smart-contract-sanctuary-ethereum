// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ErrorsByteUtils } from './Errors.sol';

// import "hardhat/console.sol";

/**
 * Library to simplify working with bytes
 */
library ByteUtils {
    function slice(
        bytes calldata _data,
        uint256 _start,
        uint256 _end
    ) public pure returns (bytes memory) {
        require(_start < _end, ErrorsByteUtils.BUT1);
        require(_end <= _data.length, ErrorsByteUtils.BUT2);
        return _data[_start:_end];
    }

    /**
     * Convert an hexadecimal string in bytes (without "0x" prefix) to raw bytes
     */
    function fromHexBytes(bytes memory ss) public pure returns (bytes memory) {
        require(ss.length % 2 == 0, ErrorsByteUtils.BUT4); // length must be even
        bytes memory r = new bytes(ss.length / 2);
        for (uint256 i = 0; i < ss.length / 2; ++i) {
            r[i] = bytes1(fromHexChar(ss[2 * i]) * 16 + fromHexChar(ss[2 * i + 1]));
        }
        return r;
    }

    /**
     * @dev Convert an hexadecimal character to their value
     */
    function fromHexChar(bytes1 c) public pure returns (uint8) {
        if (c >= bytes1('0') && c <= bytes1('9')) {
            return uint8(c) - uint8(bytes1('0'));
        }
        if (c >= bytes1('a') && c <= bytes1('f')) {
            return 10 + uint8(c) - uint8(bytes1('a'));
        }
        if (c >= bytes1('A') && c <= bytes1('F')) {
            return 10 + uint8(c) - uint8(bytes1('A'));
        }
        revert(ErrorsByteUtils.BUT3);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// import 'hardhat/console.sol';

/**
 * @title List of Agreement errors
 */
library ErrorsAgreement {
    string constant AGR1 = 'AGR1'; // Agreement: bad record signatory
    string constant AGR2 = 'AGR2'; // Agreement: not all required records are executed
    string constant AGR3 = 'AGR3'; // Agreement: record fulfilment error
    string constant AGR4 = 'AGR4'; // Agreement: signatures are invalid
    string constant AGR5 = 'AGR5'; // Agreement: the transaction should have at least one condition
    string constant AGR6 = 'AGR6'; // Agreement: not all record conditions are satisfied
    string constant AGR7 = 'AGR7'; // Agreement: record already was executed by this signatory
    string constant AGR8 = 'AGR8'; // Agreement: the variable name is reserved
    string constant AGR9 = 'AGR9'; // Agreement: this record does not exist
    string constant AGR10 = 'AGR10'; // Agreement: this record has not yet been archived
    string constant AGR11 = 'AGR11'; // Agreement: not an owner
    string constant AGR12 = 'AGR12'; // Agreement: zero address
    string constant AGR13 = 'AGR13'; // Agreement: the record is not activated
    string constant AGR14 = 'AGR14'; // Agreement: the record is pre-define. can not be changed
    string constant AGR15 = 'AGR15'; // Agreement: time can not be in the past
    string constant AGR16 = 'AGR16'; // Agreement: out of range
}

library ErrorsGovernance {
    string constant GOV1 = 'GOV1'; // Governance: You can not vote YES anymore
    string constant GOV2 = 'GOV2'; // Governance: You can not vote NO anymore
}

/**
 * @title List of Context errors
 */
library ErrorsContext {
    string constant CTX1 = 'CTX1'; // Context: address is zero
    string constant CTX2 = 'CTX2'; // Context: empty opcode selector
    string constant CTX3 = 'CTX3'; // Context: duplicate opcode name or code
    string constant CTX4 = 'CTX4'; // Context: slicing out of range
    string constant CTX5 = 'CTX5'; // Context: duplicate opcode branch
    string constant CTX6 = 'CTX6'; // Context: wrong application address
    string constant CTX7 = 'CTX7'; // Context: the application address has already set
}

/**
 * @title List of Stack errors
 */
library ErrorsStack {
    string constant STK1 = 'STK1'; // Stack: uint256 type mismatch
    string constant STK2 = 'STK2'; // Stack: string type mismatch
    string constant STK3 = 'STK3'; // Stack: address type mismatch
    string constant STK4 = 'STK4'; // Stack: stack is empty
}

/**
 * @title List of OtherOpcodes errors
 */
library ErrorsGeneralOpcodes {
    string constant OP1 = 'OP1'; // Opcodes: opSetLocal call not success
    string constant OP2 = 'OP2'; // Opcodes: tries to get an item from non-existing array
    string constant OP3 = 'OP3'; // Opcodes: opLoadRemote call not success
    string constant OP4 = 'OP4'; // Opcodes: tries to put an item to non-existing array
    string constant OP5 = 'OP5'; // Opcodes: opLoadLocal call not success
    string constant OP6 = 'OP6'; // Opcodes: array is empty
    string constant OP8 = 'OP8'; // Opcodes: wrong type of array
}

/**
 * @title List of BranchingOpcodes errors
 */
library ErrorsBranchingOpcodes {
    string constant BR1 = 'BR1'; // BranchingOpcodes: LinkedList.getType() delegate call error
    string constant BR2 = 'BR2'; // BranchingOpcodes: array doesn't exist
    string constant BR3 = 'BR3'; // BranchingOpcodes: LinkedList.get() delegate call error
}

/**
 * @title List of Parser errors
 */
library ErrorsParser {
    string constant PRS1 = 'PRS1'; // Parser: delegatecall to asmSelector failure
    string constant PRS2 = 'PRS2'; // Parser: the name of variable can not be empty
}

/**
 * @title List of Preprocessor errors
 */
library ErrorsPreprocessor {
    string constant PRP1 = 'PRP1'; // Preprocessor: amount of parameters can not be 0
    string constant PRP2 = 'PRP2'; // Preprocessor: invalid parameters for the function
}

/**
 * @title List of OpcodesHelpers errors
 */
library ErrorsOpcodeHelpers {
    string constant OPH1 = 'OPH1'; // Opcodes: mustCall call not success
    string constant OPH2 = 'OPH2'; // Opcodes: mustDelegateCall call not success
}

/**
 * @title List of ByteUtils errors
 */
library ErrorsByteUtils {
    string constant BUT1 = 'BUT1'; // ByteUtils: 'end' index must be greater than 'start'
    string constant BUT2 = 'BUT2'; // ByteUtils: 'end' is greater than the length of the array
    string constant BUT3 = 'BUT3'; // ByteUtils: a hex value not from the range 0-9, a-f, A-F
    string constant BUT4 = 'BUT4'; // ByteUtils: hex lenght not even
}

/**
 * @title List of Executor errors
 */
library ErrorsExecutor {
    string constant EXC1 = 'EXC1'; // Executor: empty program
    string constant EXC2 = 'EXC2'; // Executor: did not find selector for opcode
    string constant EXC3 = 'EXC3'; // Executor: call not success
    string constant EXC4 = 'EXC4'; // Executor: call to program context not success
}

/**
 * @title List of StringUtils errors
 */
library ErrorsStringUtils {
    string constant SUT1 = 'SUT1'; // StringUtils: index out of range
    string constant SUT3 = 'SUT3'; // StringUtils: non-decimal character
    string constant SUT4 = 'SUT4'; // StringUtils: base was not provided
    string constant SUT5 = 'SUT5'; // StringUtils: invalid format
    string constant SUT6 = 'SUT6'; // StringUtils: decimals were not provided
    string constant SUT7 = 'SUT7'; // StringUtils: a string was not provided
    string constant SUT9 = 'SUT9'; // StringUtils: base was not provided
}