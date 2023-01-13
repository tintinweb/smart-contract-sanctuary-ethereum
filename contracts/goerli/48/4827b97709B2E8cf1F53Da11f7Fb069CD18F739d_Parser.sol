// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC20 } from './interfaces/IERC20.sol';
import { IDSLContext } from './interfaces/IDSLContext.sol';
import { IProgramContext } from './interfaces/IProgramContext.sol';
import { IParser } from './interfaces/IParser.sol';
import { IPreprocessor } from './interfaces/IPreprocessor.sol';
import { StringUtils } from './libs/StringUtils.sol';
import { ByteUtils } from './libs/ByteUtils.sol';
import { Preprocessor } from './Preprocessor.sol';
import { ErrorsParser } from './libs/Errors.sol';

// import 'hardhat/console.sol';

/**
 * @dev Parser of DSL code. This contract is a singleton and should not
 * be deployed more than once
 *
 * One of the core contracts of the project. It parses DSL expression
 * that comes from user. After parsing code in Parser
 * a bytecode of the DSL program is generated as stored in ProgramContext
 *
 * DSL code in postfix notation as string -> Parser -> raw bytecode
 */
contract Parser is IParser {
    using StringUtils for string;
    using ByteUtils for bytes;

    string[] internal cmds; // DSL code in postfix form (output of Preprocessor)
    uint256 internal cmdIdx; // Current parsing index of DSL code

    /**
     * @dev Transform DSL code from array in infix notation to raw bytecode
     * @param _dslCtxAddr DSLContext contract address
     * @param _programCtxAddr ProgramContext contract address
     * @param _codeRaw Input code as a string in infix notation
     */
    function parse(
        address _preprAddr,
        address _dslCtxAddr,
        address _programCtxAddr,
        string memory _codeRaw
    ) external {
        string[] memory _code = IPreprocessor(_preprAddr).transform(_dslCtxAddr, _codeRaw);
        parseCode(_dslCtxAddr, _programCtxAddr, _code);
    }

    /**
     * @dev Сonverts a list of commands to bytecode
     */
    function parseCode(address _dslCtxAddr, address _programCtxAddr, string[] memory _code) public {
        cmdIdx = 0;
        bytes memory b;
        bytes memory program;

        IProgramContext(_programCtxAddr).setProgram(b); // TODO: set to 0 that program in the program context
        _setCmdsArray(_code); // remove empty strings
        IProgramContext(_programCtxAddr).setPc(0);
        IProgramContext(_programCtxAddr).stack().clear();

        while (cmdIdx < cmds.length) {
            program = _parseOpcodeWithParams(_dslCtxAddr, _programCtxAddr, program);
        }
        IProgramContext(_programCtxAddr).setProgram(program);
    }

    /**
     * @dev Asm functions
     * Concatenates the previous program bytecode with the next command
     * that contains in the `cmds` list. `cmdIdx` is helping to follow
     * what exactly the command is in the process
     * Example of code for :
     * ```
     * cmds = ['bool', 'true'] // current cmds
     * cmdIdx = 0 // current parsing index of DSL code
     * program = ''
     * ```
     *
     * So it will be executed the asmSetLocalBool() function where:
     * - `_parseVariable()` internal function will update the previous empty
     * `program` with the bytecode of `bool` opcode
     *
     * Result is `program = '0x18'` (see Context.sol for `addOpcode('bool'..)`
     * to check the code for `bool` opcode)
     * cmdIdx = 0 // current parsing index of DSL code is the same
     *
     * - `asmBool()` function will concatenate previous `program` with the bytecode of `true` value
     * `program` with the bytecode `0x01` (see return values for Parser.sol for `asmBool()` function
     *
     * ```
     * cmdIdx = 1 // parsing index of DSL code was updated
     * program = '0x1801'
     * ```
     */

    /**
     * @dev Updates the program with the bool value
     *
     * Example of a command:
     * ```
     * bool true
     * ```
     */
    function asmSetLocalBool(
        bytes memory _program,
        address,
        address
    ) public returns (bytes memory newProgram) {
        newProgram = _parseVariable(_program);
        newProgram = asmBool(newProgram, address(0), address(0));
    }

    /**
     * @dev Updates the program with the local variable value
     *
     * Example of a command:
     * ```
     * (uint256 5 + uint256 7) setUint256 VARNAME
     * ```
     */
    function asmSetUint256(
        bytes memory _program,
        address,
        address
    ) public returns (bytes memory newProgram) {
        return _parseVariable(_program);
    }

    /**
     * @dev Updates the program with the name(its position) of the array
     *
     * Example of a command:
     * ```
     * declare ARR_NAME
     * ```
     */
    function asmDeclare(
        bytes memory _program,
        address _ctxDSLAddr,
        address
    ) public returns (bytes memory newProgram) {
        newProgram = _parseBranchOf(_program, _ctxDSLAddr, 'declareArr'); // program += bytecode for type of array
        newProgram = _parseVariable(newProgram); // program += bytecode for `ARR_NAME`
    }

    function asmCompound(
        bytes memory _program,
        address _ctxDSLAddr,
        address
    ) public returns (bytes memory newProgram) {
        // program += bytecode for type of transaction for compound contract (deposit/withdraw)
        newProgram = _parseBranchOf(_program, _ctxDSLAddr, 'compound');
        _nextCmd(); // skip `all` keyword
        newProgram = _parseVariable(newProgram); // program += bytecode for `TOKEN`
    }

    /**
     * @dev Updates the program with the element by index from the provived array's name
     *
     * Example of a command:
     * ```
     * get 3 USERS
     * ```
     */
    function asmGet(
        bytes memory _program,
        address,
        address
    ) public returns (bytes memory newProgram) {
        string memory _value = _nextCmd();
        bytes4 _arrName = bytes4(keccak256(abi.encodePacked(_nextCmd())));
        newProgram = bytes.concat(_program, bytes32(_value.toUint256()), _arrName);
    }

    /**
     * @dev Updates the program with the new item for the array, can be `uint256`,
     * `address` and `struct name` types.
     *
     * Example of a command:
     * ```
     * push ITEM ARR_NAME
     * ```
     */
    function asmPush(
        bytes memory _program,
        address,
        address
    ) public returns (bytes memory newProgram) {
        string memory _value = _nextCmd();
        bytes4 _arrName = bytes4(keccak256(abi.encodePacked(_nextCmd())));

        if (_value.mayBeAddress()) {
            bytes memory _sliced = bytes(_value).slice(2, 42); // without first `0x` symbols
            newProgram = bytes.concat(_program, bytes32(_sliced.fromHexBytes()));
        } else if (_value.mayBeNumber()) {
            newProgram = bytes.concat(_program, bytes32(_value.toUint256()));
        } else {
            // only for struct names!
            newProgram = bytes.concat(
                _program,
                bytes32(bytes4(keccak256(abi.encodePacked(_value))))
            );
        }

        newProgram = bytes.concat(newProgram, _arrName);
    }

    /**
     * @dev Updates the program with the loadLocal variable
     *
     * Example of command:
     * ```
     * var NUMBER
     * ```
     */
    function asmVar(
        bytes memory _program,
        address,
        address
    ) public returns (bytes memory newProgram) {
        newProgram = _parseVariable(_program);
    }

    /**
     * @dev Updates the program with the loadRemote variable
     *
     * Example of a command:
     * ```
     * loadRemote bool MARY_ADDRESS 9A676e781A523b5d0C0e43731313A708CB607508
     * ```
     */
    function asmLoadRemote(
        bytes memory _program,
        address _ctxDSLAddr,
        address
    ) public returns (bytes memory newProgram) {
        newProgram = _parseBranchOf(_program, _ctxDSLAddr, 'loadRemote'); // program += bytecode for `loadRemote bool`
        newProgram = _parseVariable(newProgram); // program += bytecode for `MARY_ADDRESS`
        newProgram = _parseAddress(newProgram); // program += bytecode for `9A676e781A523b5...`
    }

    /**
     * @dev Concatenates and updates previous `program` with the `0x01`
     * bytecode of `true` value otherwise `0x00` for `false`
     */
    function asmBool(
        bytes memory _program,
        address,
        address
    ) public returns (bytes memory newProgram) {
        bytes1 value = bytes1(_nextCmd().equal('true') ? 0x01 : 0x00);
        newProgram = bytes.concat(_program, value);
    }

    /**
     * @dev Concatenates and updates previous `program` with the
     * bytecode of uint256 value
     */
    function asmUint256(bytes memory _program, address, address) public returns (bytes memory) {
        uint256 value = _nextCmd().toUint256();
        return bytes.concat(_program, bytes32(value));
    }

    /**
     * @dev Updates previous `program` with the amount that will be send (in wei)
     *
     * Example of a command:
     * ```
     * sendEth RECEIVER 1234
     * ```
     */
    function asmSend(
        bytes memory _program,
        address,
        address
    ) public returns (bytes memory newProgram) {
        newProgram = _parseVariable(_program); // program += bytecode for `sendEth RECEIVER`
        newProgram = asmUint256(newProgram, address(0), address(0)); // program += bytecode for `1234`
    }

    /**
     * @dev Updates previous `program` with the amount of tokens
     * that will be transfer to reciever(in wei). The `TOKEN` and `RECEIVER`
     * parameters should be stored in smart contract
     *
     * Example of a command:
     * ```
     * transfer TOKEN RECEIVER 1234
     * ```
     */
    function asmTransfer(
        bytes memory _program,
        address,
        address
    ) public returns (bytes memory newProgram) {
        newProgram = _parseVariable(_program); // token address
        newProgram = _parseVariable(newProgram); // receiver address
        newProgram = asmUint256(newProgram, address(0), address(0)); // amount
    }

    /**
     * @dev Updates previous `program` with the amount of tokens
     * that will be transfer to reciever(in wei). The `TOKEN`, `RECEIVER`, `AMOUNT`
     * parameters should be stored in smart contract
     *
     * Example of a command:
     * ```
     * transferVar TOKEN RECEIVER AMOUNT
     * ```
     */
    function asmTransferVar(
        bytes memory _program,
        address,
        address
    ) public returns (bytes memory newProgram) {
        newProgram = _parseVariable(_program); // token address
        newProgram = _parseVariable(newProgram); // receiver
        newProgram = _parseVariable(newProgram); // amount
    }

    /**
     * @dev Updates previous `program` with the amount of tokens
     * that will be transfer from the certain address to reciever(in wei).
     * The `TOKEN`, `FROM`, `TO` address parameters should be stored in smart contract
     *
     * Example of a command:
     * ```
     * transferFrom TOKEN FROM TO 1234
     * ```
     */
    function asmTransferFrom(
        bytes memory _program,
        address,
        address
    ) public returns (bytes memory newProgram) {
        newProgram = _parseVariable(_program); // token address
        newProgram = _parseVariable(newProgram); // from
        newProgram = _parseVariable(newProgram); // to
        newProgram = asmUint256(newProgram, address(0), address(0)); // amount
    }

    /**
     * @dev Updates previous `program` with the amount of tokens
     * that will be transfer from the certain address to reciever(in wei).
     * The `TOKEN`, `FROM`, `TO`, `AMOUNT` parameters should be stored in smart contract
     *
     * Example of a command:
     * ```
     * transferFromVar TOKEN FROM TO AMOUNT
     * ```
     */
    function asmTransferFromVar(
        bytes memory _program,
        address,
        address
    ) public returns (bytes memory newProgram) {
        newProgram = _parseVariable(_program); // token address
        newProgram = _parseVariable(newProgram); // from
        newProgram = _parseVariable(newProgram); // to
        newProgram = _parseVariable(newProgram); // amount
    }

    /**
     * @dev Updates previous `program` with getting the amount of tokens
     * The `TOKEN`, `USER` address parameters should be stored in smart contract
     *
     * Example of a command:
     * ```
     * balanceOf TOKEN USER
     * ```
     */
    function asmBalanceOf(
        bytes memory _program,
        address,
        address
    ) public returns (bytes memory newProgram) {
        newProgram = _parseVariable(_program); // token address
        newProgram = _parseVariable(newProgram); // user address
    }

    function asmAllowanceMintBurn(
        bytes memory _program,
        address,
        address
    ) public returns (bytes memory newProgram) {
        newProgram = _parseVariable(_program); // token address, token address, token address
        newProgram = _parseVariable(newProgram); // owner, to, owner
        newProgram = _parseVariable(newProgram); // spender, amount, amount
    }

    /**
     * @dev Updates previous `program` with getting the length of the dsl array by its name
     * The command return non zero value only if the array name was declared and have at least one value.
     * Check: `declareArr` and `push` commands for DSL arrays
     *
     * Example of a command:
     * ```
     * lengthOf ARR_NAME
     * ```
     */
    function asmLengthOf(bytes memory _program, address, address) public returns (bytes memory) {
        return _parseVariable(_program); // array name
    }

    /**
     * @dev Updates previous `program` with the name of the dsl array that will
     * be used to sum uint256 variables
     *
     * Example of a command:
     * ```
     * sumOf ARR_NAME
     * ```
     */
    function asmSumOf(bytes memory _program, address, address) public returns (bytes memory) {
        return _parseVariable(_program); // array name
    }

    /**
     * @dev Updates previous `program` with the name of the dsl array and
     * name of variable in the DSL structure that will
     * be used to sum uint256 variables
     *
     * Example of a command:
     * ```
     * struct BOB {
     *   lastPayment: 3
     * }
     *
     * struct ALISA {
     *   lastPayment: 300
     * }
     *
     * sumThroughStructs USERS.lastPayment
     * or shorter version
     * sumOf USERS.lastPayment
     * ```
     */
    function asmSumThroughStructs(
        bytes memory _program,
        address,
        address
    ) public returns (bytes memory newProgram) {
        newProgram = _parseVariable(_program); // array name
        newProgram = _parseVariable(newProgram); // variable name
    }

    /**
     * @dev Updates previous `program` for positive and negative branch position
     *
     * Example of a command:
     * ```
     * 6 > 5 // condition is here must return true or false
     * ifelse AA BB
     * end
     *
     * branch AA {
     *   // code for `positive` branch
     * }
     *
     * branch BB {
     *   // code for `negative` branch
     * }
     * ```
     */
    function asmIfelse(
        bytes memory _program,
        address,
        address _programCtxAddr
    ) public returns (bytes memory newProgram) {
        string memory _true = _nextCmd(); // "positive" branch name
        string memory _false = _nextCmd(); // "negative" branch name
        // set `positive` branch position
        _setLabelPos(_programCtxAddr, _true, _program.length);
        newProgram = bytes.concat(_program, bytes2(0)); // placeholder for `positive` branch offset
        // set `negative` branch position
        _setLabelPos(_programCtxAddr, _false, newProgram.length);
        newProgram = bytes.concat(newProgram, bytes2(0)); // placeholder for `negative` branch offset
    }

    /**
     * @dev Updates previous `program` for positive branch position
     *
     * Example of a command:
     * ```
     * 6 > 5 // condition is here must return true or false
     * if POSITIVE_ACTION
     * end
     *
     * POSITIVE_ACTION {
     *   // code for `positive` branch
     * }
     * ```
     */
    function asmIf(
        bytes memory _program,
        address,
        address _programCtxAddr
    ) public returns (bytes memory newProgram) {
        _setLabelPos(_programCtxAddr, _nextCmd(), _program.length);
        newProgram = bytes.concat(_program, bytes2(0)); // placeholder for `true` branch offset
    }

    /**
     * @dev Updates previous `program` for function code
     *
     * Example of a command:
     * ```
     * func NAME_OF_FUNCTION
     *
     * NAME_OF_FUNCTION {
     *   // code for the body of function
     * }
     * ```
     */
    function asmFunc(
        bytes memory _program,
        address,
        address _programCtxAddr
    ) public returns (bytes memory newProgram) {
        // set `name of function` position
        _setLabelPos(_programCtxAddr, _nextCmd(), _program.length);
        newProgram = bytes.concat(_program, bytes2(0)); // placeholder for `name of function` offset
    }

    /**
     * @dev Updates previous `program` for DSL struct.
     * This function rebuilds variable parameters using a name of the structure, dot symbol
     * and the name of each parameter in the structure
     *
     * Example of DSL command:
     * ```
     * struct BOB {
     *   account: 0x47f8a90ede3d84c7c0166bd84a4635e4675accfc,
     *   lastPayment: 3
     * }
     * ```
     *
     * Example of commands that uses for this functions:
     * `cmds = ['struct', 'BOB', 'lastPayment', '3', 'account', '0x47f..', 'endStruct']`
     *
     * `endStruct` word is used as an indicator for the ending loop for the structs parameters
     */
    function asmStruct(
        bytes memory _program,
        address,
        address _programCtxAddr
    ) public returns (bytes memory newProgram) {
        // parse the name of structure - `BOB`
        string memory _structName = _nextCmd();
        newProgram = _program;
        // parsing name/value parameters till found the 'endStruct' word
        do {
            // parse the name of variable - `balance`, `account`
            string memory _variable = _nextCmd();
            // create the struct name of variable - `BOB.balance`, `BOB.account`
            string memory _name = _structName.concat('.').concat(_variable);
            // TODO: let's think how not to use setter in Parser here..
            IProgramContext(_programCtxAddr).setStructVars(_structName, _variable, _name);
            // TODO: store sertain bytes for each word separate in bytes string?
            newProgram = bytes.concat(newProgram, bytes4(keccak256(abi.encodePacked(_name))));
            // parse the value of `balance` variable - `456`, `0x345...`
            string memory _value = _nextCmd();
            if (_value.mayBeAddress()) {
                // remove first `0x` symbols
                bytes memory _sliced = bytes(_value).slice(2, 42);
                newProgram = bytes.concat(newProgram, bytes32(_sliced.fromHexBytes()));
            } else if (_value.mayBeNumber()) {
                newProgram = bytes.concat(newProgram, bytes32(_value.toUint256()));
            } else if (_variable.equal('vote') && _value.equal('YES')) {
                // voting process, change stored value in the array 1
                newProgram = bytes.concat(newProgram, bytes32(uint256(1)));
            } else if (_variable.equal('vote') && _value.equal('NO')) {
                // voting process, change stored value in the array to 0
                newProgram = bytes.concat(newProgram, bytes32(0));
            }
            // else {
            //     // if the name of the variable
            //     program = bytes.concat(program, bytes32(keccak256(abi.encodePacked(_value))));
            // }
        } while (!(cmds[cmdIdx].equal('endStruct')));

        newProgram = _parseVariable(newProgram); // parse the 'endStruct' word
    }

    /**
     * @dev Parses variable names in for-loop & skip the unnecessary `in` parameter
     * Ex. ['for', 'LP_INITIAL', 'in', 'LPS_INITIAL']
     */
    function asmForLoop(
        bytes memory _program,
        address,
        address
    ) public returns (bytes memory newProgram) {
        // parse temporary variable name
        newProgram = _parseVariable(_program);
        _nextCmd(); // skip `in` keyword
        newProgram = _parseVariable(newProgram);
    }

    /**
     * @dev Parses the `record id` and the `agreement address` parameters
     * Ex. ['enableRecord', 'RECORD_ID', 'at', 'AGREEMENT_ADDRESS']
     */
    function asmEnableRecord(
        bytes memory _program,
        address,
        address
    ) public returns (bytes memory newProgram) {
        newProgram = _parseVariable(_program);
        _nextCmd(); // skip `at` keyword
        newProgram = _parseVariable(newProgram);
    }

    /**
     * Internal functions
     */

    /**
     * @dev returns `true` if the name of `if/ifelse branch` or `function` exists in the labelPos list
     * otherwise returns `false`
     */
    function _isLabel(address _programCtxAddr, string memory _name) internal view returns (bool) {
        return _getLabelPos(_programCtxAddr, _name) > 0;
    }

    function _getLabelPos(
        address _programCtxAddr,
        string memory _name
    ) internal view returns (uint256) {
        return IProgramContext(_programCtxAddr).labelPos(_name);
    }

    /**
     * @dev Updates the bytecode `program` in dependence on
     * commands that were provided in `cmds` list
     */
    function _parseOpcodeWithParams(
        address _dslCtxAddr,
        address _programCtxAddr,
        bytes memory _program
    ) internal returns (bytes memory newProgram) {
        string storage cmd = _nextCmd();

        bytes1 opcode = IDSLContext(_dslCtxAddr).opCodeByName(cmd);

        // TODO: simplify
        bytes4 _selector = bytes4(keccak256(abi.encodePacked(cmd)));
        bool isStructVar = IProgramContext(_programCtxAddr).isStructVar(cmd);
        if (_isLabel(_programCtxAddr, cmd)) {
            bytes2 _branchLocation = bytes2(uint16(_program.length));
            uint256 labelPos = _getLabelPos(_programCtxAddr, cmd);
            newProgram = bytes.concat(
                _program.slice(0, labelPos), // programBefore
                _branchLocation,
                _program.slice(labelPos + 2, _program.length) // programAfter
            );

            // TODO: move isValidVarName() check to Preprocessor
            //       (it should automatically add `var` before all variable names)
        } else if (cmd.isValidVarName() || isStructVar) {
            opcode = IDSLContext(_dslCtxAddr).opCodeByName('var');
            newProgram = bytes.concat(_program, opcode, _selector);
        } else if (opcode == 0x0) {
            revert(string(abi.encodePacked('Parser: "', cmd, '" command is unknown')));
        } else {
            newProgram = bytes.concat(_program, opcode);

            _selector = IDSLContext(_dslCtxAddr).asmSelectors(cmd);
            if (_selector != 0x0) {
                // TODO: address, address
                (bool success, bytes memory data) = address(this).delegatecall(
                    abi.encodeWithSelector(_selector, newProgram, _dslCtxAddr, _programCtxAddr)
                );
                require(success, ErrorsParser.PRS1);
                newProgram = abi.decode(data, (bytes));
            }
            // if no selector then opcode without params
        }
    }

    /**
     * @dev Returns next commad from the cmds list, increases the
     * command index `cmdIdx` by 1
     * @return nextCmd string
     */
    function _nextCmd() internal returns (string storage) {
        return cmds[cmdIdx++];
    }

    /**
     * @dev Updates previous `program` with the next provided command
     */
    function _parseVariable(bytes memory _program) internal returns (bytes memory newProgram) {
        bytes4 _cmd = bytes4(keccak256(abi.encodePacked(_nextCmd())));
        newProgram = bytes.concat(_program, _cmd);
    }

    /**
     * @dev Updates previous `program` with the branch name, like `loadLocal` or `loadRemote`
     * of command and its additional used type
     */
    function _parseBranchOf(
        bytes memory _program,
        address _ctxDSLAddr,
        string memory baseOpName
    ) internal returns (bytes memory newProgram) {
        newProgram = bytes.concat(
            _program,
            IDSLContext(_ctxDSLAddr).branchCodes(baseOpName, _nextCmd())
        );
    }

    /**
     * @dev Updates previous `program` with the address command that is a value
     */
    function _parseAddress(bytes memory _program) internal returns (bytes memory newProgram) {
        string memory _addr = _nextCmd();
        _addr = _addr.substr(2, _addr.length()); // cut `0x` from the beginning of the address
        newProgram = bytes.concat(_program, _addr.fromHex());
    }

    /**
     * @dev Deletes empty elements from the _input array and sets the result as a `cmds` storage array
     */
    function _setCmdsArray(string[] memory _input) internal {
        uint256 i;
        delete cmds;

        while (i < _input.length && !_input[i].equal('')) {
            cmds.push(_input[i++]);
        }
    }

    function _setLabelPos(address _programCtxAddr, string memory _name, uint256 _value) internal {
        IProgramContext(_programCtxAddr).setLabelPos(_name, _value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../helpers/Stack.sol';

interface IDSLContext {
    enum OpcodeLibNames {
        ComparisonOpcodes,
        BranchingOpcodes,
        LogicalOpcodes,
        OtherOpcodes
    }

    function comparisonOpcodes() external view returns (address);

    function branchingOpcodes() external view returns (address);

    function logicalOpcodes() external view returns (address);

    function otherOpcodes() external view returns (address);

    function opCodeByName(string memory _name) external view returns (bytes1 _opcode);

    function selectorByOpcode(bytes1 _opcode) external view returns (bytes4 _selecotor);

    function numOfArgsByOpcode(string memory _name) external view returns (uint8 _numOfArgs);

    function isCommand(string memory _name) external view returns (bool _isCommand);

    function opcodeLibNameByOpcode(bytes1 _opcode) external view returns (OpcodeLibNames _name);

    function asmSelectors(string memory _name) external view returns (bytes4 _selecotor);

    function opsPriors(string memory _name) external view returns (uint256 _priority);

    function operators(uint256 _index) external view returns (string memory _operator);

    function branchSelectors(
        string memory _baseOpName,
        bytes1 _branchCode
    ) external view returns (bytes4 _selector);

    function branchCodes(
        string memory _baseOpName,
        string memory _branchName
    ) external view returns (bytes1 _branchCode);

    function aliases(string memory _alias) external view returns (string memory _baseCmd);

    // Functions
    function operatorsLen() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IDSLContext } from './IDSLContext.sol';
import { Preprocessor } from '../Preprocessor.sol';

interface IParser {
    // Variables

    event ExecRes(bool result);
    event NewConditionalTx(address txObj);

    // Functions

    function parse(
        address _preprAddr,
        address _dslCtxAddr,
        address _programCtxAddr,
        string memory _codeRaw
    ) external;

    function parseCode(
        address _dslCtxAddr,
        address _programCtxAddr,
        string[] memory _code
    ) external;

    function asmSetLocalBool(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmSetUint256(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmVar(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmLoadRemote(
        bytes memory _program,
        address _ctxDSLAddr,
        address
    ) external returns (bytes memory newProgram);

    function asmDeclare(
        bytes memory _program,
        address _ctxDSLAddr,
        address
    ) external returns (bytes memory newProgram);

    function asmCompound(
        bytes memory _program,
        address _ctxDSLAddr,
        address
    ) external returns (bytes memory newProgram);

    function asmBool(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmUint256(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmSend(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmTransfer(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmTransferVar(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmTransferFrom(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmBalanceOf(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmAllowanceMintBurn(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmLengthOf(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmSumOf(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmSumThroughStructs(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmTransferFromVar(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmIfelse(
        bytes memory _program,
        address _ctxDSLAddr,
        address _programCtxAddr
    ) external returns (bytes memory newProgram);

    function asmIf(
        bytes memory _program,
        address _ctxDSLAddr,
        address _programCtxAddr
    ) external returns (bytes memory newProgram);

    function asmFunc(
        bytes memory _program,
        address _ctxDSLAddr,
        address _programCtxAddr
    ) external returns (bytes memory newProgram);

    function asmGet(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmPush(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmStruct(
        bytes memory _program,
        address _ctxDSLAddr,
        address _programCtxAddr
    ) external returns (bytes memory newProgram);

    function asmForLoop(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);

    function asmEnableRecord(
        bytes memory _program,
        address,
        address
    ) external returns (bytes memory newProgram);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IDSLContext } from './interfaces/IDSLContext.sol';
import { IPreprocessor } from './interfaces/IPreprocessor.sol';
import { StringStack } from './libs/StringStack.sol';
import { StringUtils } from './libs/StringUtils.sol';
import { ErrorsPreprocessor } from './libs/Errors.sol';

/**
 * @dev Preprocessor of DSL code
 * @dev This contract is a singleton and should not be deployed more than once
 *
 * It can remove comments that were created by user in the DSL code string. It
 * transforms the users DSL code string to the list of commands that can be used
 * in a Parser contract.
 *
 * DSL code in postfix notation as
 * user's string code -> Preprocessor -> each command is separated in the commands list
 */
library Preprocessor {
    using StringUtils for string;
    using StringStack for string[];

    /************************
     * == MAIN FUNCTIONS == *
     ***********************/

    /**
     * @dev The main function that transforms the user's DSL code string to the list of commands.
     *
     * Example:
     * The user's DSL code string is
     * ```
     * uint256 6 setUint256 A
     * ```
     * The end result after executing a `transform()` function is
     * ```
     * ['uint256', '6', 'setUint256', 'A']
     * ```
     *
     * @param _ctxAddr is a context contract address
     * @param _program is a user's DSL code string
     * @return code The list of commands that storing `result`
     */
    function transform(
        address _ctxAddr,
        string memory _program
    ) external view returns (string[] memory code) {
        // _program = removeComments(_program);
        code = split(_program, '\n ,:(){}', '(){}');
        code = removeSyntacticSugar(code);
        code = simplifyCode(code, _ctxAddr);
        code = infixToPostfix(_ctxAddr, code);
        return code;
    }

    /**
     * @dev Searches the comments in the program and removes comment lines
     * Example:
     * The user's DSL code string is
     * ```
     *  bool true
     *  // uint256 2 * uint256 5
     * ```
     * The end result after executing a `removeComments()` function is
     * ```
     * bool true
     * ```
     * @param _program is a current program string
     * @return _cleanedProgram new string program that contains only clean code without comments
     */
    function removeComments(
        string memory _program
    ) public pure returns (string memory _cleanedProgram) {
        bool isCommented;

        // searchedSymbolLen is a flag that uses for searching a correct end symbol
        uint256 searchedSymbolLen; // 1 - search \n symbol, 2 - search */ symbol
        uint256 tempIndex; // uses for checking if the index was changed
        uint256 i;
        string memory char;

        while (i < _program.length()) {
            char = _program.char(i);
            tempIndex = i;
            if (isCommented) {
                (tempIndex, isCommented) = _getEndCommentSymbol(
                    searchedSymbolLen,
                    i,
                    _program,
                    char
                );
            } else {
                (searchedSymbolLen, tempIndex, isCommented) = _getCommentSymbol(i, _program, char);
            }

            if (tempIndex > i) {
                i = tempIndex;
                continue;
            }

            if (isCommented) {
                i += 1;
                continue;
            }

            _cleanedProgram = _cleanedProgram.concat(char);
            i += 1;
        }
    }

    /**
     * @dev Splits the user's DSL code string to the list of commands
     * avoiding several symbols:
     * - removes additional and useless symbols as ' ', `\\n`
     * - defines and adding help 'end' symbol for the ifelse condition
     * - defines and cleans the code from `{` and `}` symbols
     *
     * Example:
     * The user's DSL code string is
     * ```
     * (var TIMESTAMP > var INIT)
     * ```
     * The end result after executing a `split()` function is
     * ```
     * ['var', 'TIMESTAMP', '>', 'var', 'INIT']
     * ```
     *
     * @param _program is a user's DSL code string
     * @param _separators Separators that will be used to split the string
     * @param _separatorsToKeep we're using symbols from this string as separators but not removing
     *                          them from the resulting array
     * @return The list of commands that storing in `result`
     */
    function split(
        string memory _program,
        string memory _separators,
        string memory _separatorsToKeep
    ) public pure returns (string[] memory) {
        string[] memory _result = new string[](50);
        uint256 resultCtr;
        string memory buffer; // here we collect DSL commands, var names, etc. symbol by symbol
        string memory char;

        for (uint256 i = 0; i < _program.length(); i++) {
            char = _program.char(i);

            if (char.isIn(_separators)) {
                if (buffer.length() > 0) {
                    _result[resultCtr++] = buffer;
                    buffer = '';
                }
            } else {
                buffer = buffer.concat(char);
            }

            if (char.isIn(_separatorsToKeep)) {
                _result[resultCtr++] = char;
            }
        }

        if (buffer.length() > 0) {
            _result[resultCtr++] = buffer;
            buffer = '';
        }

        return _result;
    }

    /**
     * @dev Removes scientific notation from numbers and removes currency symbols
     * Example
     * 1e3 = 1,000
     * 1 GWEI = 1,000,000,000
     * 1 ETH = 1,000,000,000,000,000,000
     * @param _code Array of DSL commands
     * @return Code without syntactic sugar
     */
    function removeSyntacticSugar(string[] memory _code) public pure returns (string[] memory) {
        string[] memory _result = new string[](50);
        uint256 _resultCtr;
        string memory _chunk;
        string memory _prevChunk;
        uint256 i;

        while (i < _nonEmptyArrLen(_code)) {
            _prevChunk = i == 0 ? '' : _code[i - 1];
            _chunk = _code[i++];

            _chunk = _checkScientificNotation(_chunk);
            if (_isCurrencySymbol(_chunk)) {
                (_resultCtr, _chunk) = _processCurrencySymbol(_resultCtr, _chunk, _prevChunk);
            }

            _result[_resultCtr++] = _chunk;
        }
        return _result;
    }

    /**
     * @dev Depending on the type of the command it gets simplified
     * @param _code Array of DSL commands
     * @param _ctxAddr Context contract address
     * @return Simplified code
     */
    function simplifyCode(
        string[] memory _code,
        address _ctxAddr
    ) public view returns (string[] memory) {
        string[] memory _result = new string[](50);
        uint256 _resultCtr;
        string memory _chunk;
        string memory _prevChunk;
        uint256 i;

        while (i < _nonEmptyArrLen(_code)) {
            _prevChunk = i == 0 ? '' : _code[i - 1];
            _chunk = _code[i++];

            if (IDSLContext(_ctxAddr).isCommand(_chunk)) {
                (_result, _resultCtr, i) = _processCommand(_result, _resultCtr, _code, i, _ctxAddr);
            } else if (_isCurlyBracket(_chunk)) {
                (_result, _resultCtr) = _processCurlyBracket(_result, _resultCtr, _chunk);
            } else if (_isAlias(_chunk, _ctxAddr)) {
                (_result, _resultCtr) = _processAlias(_result, _resultCtr, _ctxAddr, _chunk);
            } else if (_chunk.equal('insert')) {
                (_result, _resultCtr, i) = _processArrayInsert(_result, _resultCtr, _code, i);
            } else {
                (_result, _resultCtr) = _checkIsNumberOrAddress(_result, _resultCtr, _chunk);
                _result[_resultCtr++] = _chunk;
            }
        }
        return _result;
    }

    /**
     * @dev Transforms code in infix format to the postfix format
     * @param _code Array of DSL commands
     * @param _ctxAddr Context contract address
     * @return Code in the postfix format
     */
    function infixToPostfix(
        address _ctxAddr,
        string[] memory _code
    ) public view returns (string[] memory) {
        string[] memory _result = new string[](50);
        string[] memory _stack = new string[](50);
        uint256 _resultCtr;
        string memory _chunk;
        uint256 i;

        while (i < _nonEmptyArrLen(_code)) {
            _chunk = _code[i++];

            if (_isOperator(_chunk, _ctxAddr)) {
                (_result, _resultCtr, _stack) = _processOperator(
                    _stack,
                    _result,
                    _resultCtr,
                    _ctxAddr,
                    _chunk
                );
            } else if (_isParenthesis(_chunk)) {
                (_result, _resultCtr, _stack) = _processParenthesis(
                    _stack,
                    _result,
                    _resultCtr,
                    _chunk
                );
            } else {
                _result[_resultCtr++] = _chunk;
            }
        }

        // Note: now we have a stack with DSL commands and we will pop from it and save to the resulting array to move
        //       from postfix to infix notation
        while (_stack.stackLength() > 0) {
            (_stack, _result[_resultCtr++]) = _stack.popFromStack();
        }
        return _result;
    }

    /***************************
     * == PROCESS FUNCTIONS == *
     **************************/

    /**
     * @dev Process insert into array command
     * @param _result Output array that the function is modifying
     * @param _resultCtr Current pointer to the empty element in the _result param
     * @param _code Current DSL code that we're processing
     * @param i Current pointer to the element in _code array that we're processing
     * @return Modified _result array, mofified _resultCtr, and modified `i`
     */
    function _processArrayInsert(
        string[] memory _result,
        uint256 _resultCtr,
        string[] memory _code,
        uint256 i
    ) internal pure returns (string[] memory, uint256, uint256) {
        // Get the necessary params of `insert` command
        // Notice: `insert 1234 into NUMBERS` -> `push 1234 NUMBERS`
        string memory _insertVal = _code[i];
        string memory _arrName = _code[i + 2];

        _result[_resultCtr++] = 'push';
        _result[_resultCtr++] = _insertVal;
        _result[_resultCtr++] = _arrName;

        return (_result, _resultCtr, i + 3);
    }

    /**
     * @dev Process summing over array comand
     * @param _result Output array that the function is modifying
     * @param _resultCtr Current pointer to the empty element in the _result param
     * @param _code Current DSL code that we're processing
     * @param i Current pointer to the element in _code array that we're processing
     * @return Modified _result array, mofified _resultCtr, and modified `i`
     */
    function _processSumOfCmd(
        string[] memory _result,
        uint256 _resultCtr,
        string[] memory _code,
        uint256 i
    ) internal pure returns (string[] memory, uint256, uint256) {
        // Ex. (sumOf) `USERS.balance` -> ['USERS', 'balance']
        // Ex. (sumOf) `USERS` ->['USERS']
        string[] memory _sumOfArgs = split(_code[i], '.', '');

        // Ex. `sumOf USERS.balance` -> sum over array of structs
        // Ex. `sumOf USERS` -> sum over a regular array
        if (_nonEmptyArrLen(_sumOfArgs) == 2) {
            // process `sumOf` over array of structs
            _result[_resultCtr++] = 'sumThroughStructs';
            _result[_resultCtr++] = _sumOfArgs[0];
            _result[_resultCtr++] = _sumOfArgs[1];
        } else {
            // process `sumOf` over a regular array
            _result[_resultCtr++] = 'sumOf';
            _result[_resultCtr++] = _sumOfArgs[0];
        }

        return (_result, _resultCtr, i + 1);
    }

    /**
     * @dev Process for-loop
     * @param _result Output array that the function is modifying
     * @param _resultCtr Current pointer to the empty element in the _result param
     * @param _code Current DSL code that we're processing
     * @param i Current pointer to the element in _code array that we're processing
     * @return Modified _result array, mofified _resultCtr, and modified `i`
     */
    function _processForCmd(
        string[] memory _result,
        uint256 _resultCtr,
        string[] memory _code,
        uint256 i
    ) internal pure returns (string[] memory, uint256, uint256) {
        // TODO
    }

    /**
     * @dev Process `struct` comand
     * @param _result Output array that the function is modifying
     * @param _resultCtr Current pointer to the empty element in the _result param
     * @param _code Current DSL code that we're processing
     * @param i Current pointer to the element in _code array that we're processing
     * @return Modified _result array, mofified _resultCtr, and modified `i`
     */
    function _processStruct(
        string[] memory _result,
        uint256 _resultCtr,
        string[] memory _code,
        uint256 i
    ) internal pure returns (string[] memory, uint256, uint256) {
        // 'struct', 'BOB', '{', 'balance', '456', '}'
        _result[_resultCtr++] = 'struct';
        _result[_resultCtr++] = _code[i]; // struct name
        // skip `{` (index is i + 1)

        uint256 j = i + 1;
        while (!_code[j + 1].equal('}')) {
            _result[_resultCtr++] = _code[j + 1]; // struct key
            _result[_resultCtr++] = _code[j + 2]; // struct value

            j = j + 2;
        }
        _result[_resultCtr++] = 'endStruct';

        return (_result, _resultCtr, j + 2);
    }

    /**
     * @dev Process `ETH`, `WEI` symbols in the code
     * @param _resultCtr Current pointer to the empty element in the _result param
     * @param _chunk The current piece of code that we're processing (should be the currency symbol)
     * @param _prevChunk The previous piece of code
     * @return Mofified _resultCtr, and modified `_prevChunk`
     */
    function _processCurrencySymbol(
        uint256 _resultCtr,
        string memory _chunk,
        string memory _prevChunk
    ) internal pure returns (uint256, string memory) {
        uint256 _currencyMultiplier = _getCurrencyMultiplier(_chunk);

        try _prevChunk.toUint256() {
            _prevChunk = StringUtils.toString(_prevChunk.toUint256() * _currencyMultiplier);
        } catch {
            _prevChunk = StringUtils.toString(
                _prevChunk.parseScientificNotation().toUint256() * _currencyMultiplier
            );
        }

        // this is to rewrite old number (ex. 100) with an extended number (ex. 100 GWEI = 100000000000)
        if (_resultCtr > 0) {
            --_resultCtr;
        }

        return (_resultCtr, _prevChunk);
    }

    /**
     * @dev Process DSL alias
     * @param _result Output array that the function is modifying
     * @param _resultCtr Current pointer to the empty element in the _result param
     * @param _ctxAddr Context contract address
     * @param _chunk The current piece of code that we're processing
     * @return Modified _result array, mofified _resultCtr, and modified `i`
     */
    function _processAlias(
        string[] memory _result,
        uint256 _resultCtr,
        address _ctxAddr,
        string memory _chunk
    ) internal view returns (string[] memory, uint256) {
        uint256 i;

        // Replace alises with base commands
        _chunk = IDSLContext(_ctxAddr).aliases(_chunk);

        // Process multi-command aliases
        // Ex. `uint256[]` -> `declareArr uint256`
        string[] memory _chunks = split(_chunk, ' ', '');

        // while we've not finished processing all the program - keep going
        while (i < _nonEmptyArrLen(_chunks)) {
            _result[_resultCtr++] = _chunks[i++];
        }

        return (_result, _resultCtr);
    }

    /**
     * @dev Process any DSL command
     * @param _result Output array that the function is modifying
     * @param _resultCtr Current pointer to the empty element in the _result param
     * @param _code Current DSL code that we're processing
     * @param i Current pointer to the element in _code array that we're processing
     * @param _ctxAddr Context contract address
     * @return Modified _result array, mofified _resultCtr, and modified `i`
     */
    function _processCommand(
        string[] memory _result,
        uint256 _resultCtr,
        string[] memory _code,
        uint256 i,
        address _ctxAddr
    ) internal view returns (string[] memory, uint256, uint256) {
        string memory _chunk = _code[i - 1];
        if (_chunk.equal('struct')) {
            (_result, _resultCtr, i) = _processStruct(_result, _resultCtr, _code, i);
        } else if (_chunk.equal('sumOf')) {
            (_result, _resultCtr, i) = _processSumOfCmd(_result, _resultCtr, _code, i);
        } else if (_chunk.equal('for')) {
            (_result, _resultCtr, i) = _processForCmd(_result, _resultCtr, _code, i);
        } else {
            uint256 _skipCtr = IDSLContext(_ctxAddr).numOfArgsByOpcode(_chunk) + 1;

            i--; // this is to include the command name in the loop below
            // add command arguments
            while (_skipCtr > 0) {
                _result[_resultCtr++] = _code[i++];
                _skipCtr--;
            }
        }

        return (_result, _resultCtr, i);
    }

    /**
     * @dev Process open and closed parenthesis
     * @param _stack Stack that is used to process parenthesis
     * @param _result Output array that the function is modifying
     * @param _resultCtr Current pointer to the empty element in the _result param
     * @param _chunk The current piece of code that we're processing
     * @return Modified _result array, mofified _resultCtr, and modified _stack
     */
    function _processParenthesis(
        string[] memory _stack,
        string[] memory _result,
        uint256 _resultCtr,
        string memory _chunk
    ) internal pure returns (string[] memory, uint256, string[] memory) {
        if (_chunk.equal('(')) {
            // opening bracket
            _stack = _stack.pushToStack(_chunk);
        } else if (_chunk.equal(')')) {
            // closing bracket
            (_result, _resultCtr, _stack) = _processClosingParenthesis(_stack, _result, _resultCtr);
        }

        return (_result, _resultCtr, _stack);
    }

    /**
     * @dev Process closing parenthesis
     * @param _stack Stack that is used to process parenthesis
     * @param _result Output array that the function is modifying
     * @param _resultCtr Current pointer to the empty element in the _result param
     * @return Modified _result array, mofified _resultCtr, and modified _stack
     */
    function _processClosingParenthesis(
        string[] memory _stack,
        string[] memory _result,
        uint256 _resultCtr
    ) public pure returns (string[] memory, uint256, string[] memory) {
        while (!_stack.seeLastInStack().equal('(')) {
            (_stack, _result[_resultCtr++]) = _stack.popFromStack();
        }
        (_stack, ) = _stack.popFromStack(); // remove '(' that is left
        return (_result, _resultCtr, _stack);
    }

    /**
     * @dev Process curly brackets
     * @param _result Output array that the function is modifying
     * @param _resultCtr Current pointer to the empty element in the _result param
     * @param _chunk The current piece of code that we're processing
     * @return Modified _result array, mofified _resultCtr
     */
    function _processCurlyBracket(
        string[] memory _result,
        uint256 _resultCtr,
        string memory _chunk
    ) internal pure returns (string[] memory, uint256) {
        // if `_chunk` equal `{` - do nothing
        if (_chunk.equal('}')) {
            _result[_resultCtr++] = 'end';
        }

        return (_result, _resultCtr);
    }

    /**
     * @dev Process any operator in DSL
     * @param _stack Stack that is used to process parenthesis
     * @param _result Output array that the function is modifying
     * @param _resultCtr Current pointer to the empty element in the _result param
     * @param _ctxAddr Context contract address
     * @param _chunk The current piece of code that we're processing
     * @return Modified _result array, mofified _resultCtr, and modified _stack
     */
    function _processOperator(
        string[] memory _stack,
        string[] memory _result,
        uint256 _resultCtr,
        address _ctxAddr,
        string memory _chunk
    ) internal view returns (string[] memory, uint256, string[] memory) {
        while (
            _stack.stackLength() > 0 &&
            IDSLContext(_ctxAddr).opsPriors(_chunk) <=
            IDSLContext(_ctxAddr).opsPriors(_stack.seeLastInStack())
        ) {
            (_stack, _result[_resultCtr++]) = _stack.popFromStack();
        }
        _stack = _stack.pushToStack(_chunk);

        return (_result, _resultCtr, _stack);
    }

    /**************************
     * == HELPER FUNCTIONS == *
     *************************/

    /**
     * @dev Checks if chunk is a currency symbol
     * @param _chunk is a current chunk from the DSL string code
     * @return True or false based on whether chunk is a currency symbol or not
     */
    function _isCurrencySymbol(string memory _chunk) internal pure returns (bool) {
        return _chunk.equal('ETH') || _chunk.equal('GWEI');
    }

    /**
     * @dev Checks if chunk is an operator
     * @param _ctxAddr Context contract address
     * @return True or false based on whether chunk is an operator or not
     */
    function _isOperator(string memory _chunk, address _ctxAddr) internal view returns (bool) {
        for (uint256 i = 0; i < IDSLContext(_ctxAddr).operatorsLen(); i++) {
            if (_chunk.equal(IDSLContext(_ctxAddr).operators(i))) return true;
        }
        return false;
    }

    /**
     * @dev Checks if a string is an alias to a command from DSL
     * @param _ctxAddr Context contract address
     * @return True or false based on whether chunk is an alias or not
     */
    function _isAlias(string memory _chunk, address _ctxAddr) internal view returns (bool) {
        return !IDSLContext(_ctxAddr).aliases(_chunk).equal('');
    }

    /**
     * @dev Checks if chunk is a parenthesis
     * @param _chunk Current piece of code that we're processing
     * @return True or false based on whether chunk is a parenthesis or not
     */
    function _isParenthesis(string memory _chunk) internal pure returns (bool) {
        return _chunk.equal('(') || _chunk.equal(')');
    }

    /**
     * @dev Checks if chunk is a curly bracket
     * @param _chunk Current piece of code that we're processing
     * @return True or false based on whether chunk is a curly bracket or not
     */
    function _isCurlyBracket(string memory _chunk) internal pure returns (bool) {
        return _chunk.equal('{') || _chunk.equal('}');
    }

    /**
     * @dev Parses scientific notation in the chunk if there is any
     * @param _chunk Current piece of code that we're processing
     * @return Chunk without a scientific notation
     */
    function _checkScientificNotation(string memory _chunk) internal pure returns (string memory) {
        if (_chunk.mayBeNumber() && !_chunk.mayBeAddress()) {
            return _parseScientificNotation(_chunk);
        }
        return _chunk;
    }

    /**
     * @dev As the string of values can be simple and complex for DSL this function returns a number in
     * Wei regardless of what type of number parameter was provided by the user.
     * For example:
     * `uint256 1000000` - simple
     * `uint256 1e6 - complex`
     * @param _chunk provided number
     * @return updatedChunk amount in Wei of provided _chunk value
     */
    function _parseScientificNotation(
        string memory _chunk
    ) internal pure returns (string memory updatedChunk) {
        try _chunk.toUint256() {
            updatedChunk = _chunk;
        } catch {
            updatedChunk = _chunk.parseScientificNotation();
        }
    }

    /**
     * @dev Checks if chunk is a number or address and processes it if so
     * @param _result Output array that the function is modifying
     * @param _resultCtr Current pointer to the empty element in the _result param
     * @param _chunk Current piece of code that we're processing
     * @return Modified _result array, mofified _resultCtr
     */
    function _checkIsNumberOrAddress(
        string[] memory _result,
        uint256 _resultCtr,
        string memory _chunk
    ) internal pure returns (string[] memory, uint256) {
        if (_chunk.mayBeAddress()) return (_result, _resultCtr);
        if (_chunk.mayBeNumber()) {
            (_result, _resultCtr) = _addUint256(_result, _resultCtr);
        }

        return (_result, _resultCtr);
    }

    /**
     * @dev Adds `uint256` to a number
     * @param _result Output array that the function is modifying
     * @param _resultCtr Current pointer to the empty element in the _result param
     * @return Modified _result array, mofified _resultCtr
     */
    function _addUint256(
        string[] memory _result,
        uint256 _resultCtr
    ) internal pure returns (string[] memory, uint256) {
        if (_resultCtr == 0 || (!(_result[_resultCtr - 1].equal('uint256')))) {
            _result[_resultCtr++] = 'uint256';
        }
        return (_result, _resultCtr);
    }

    /**
     * @dev checks the value, and returns the corresponding multiplier.
     * If it is Ether, then it returns 1000000000000000000,
     * If it is GWEI, then it returns 1000000000
     * @param _chunk is a command from DSL command list
     * @return returns the corresponding multiplier.
     */
    function _getCurrencyMultiplier(string memory _chunk) internal pure returns (uint256) {
        if (_chunk.equal('ETH')) {
            return 1000000000000000000;
        } else if (_chunk.equal('GWEI')) {
            return 1000000000;
        } else return 0;
    }

    /**
     * @dev Checks if a symbol is a comment, then increases `i` to the next
     * no-comment symbol avoiding an additional iteration
     * @param i is a current index of a char that might be changed
     * @param _program is a current program string
     * @param _char Current character
     * @return Searched symbol length
     * @return New index
     * @return Is code commented or not
     */
    function _getCommentSymbol(
        uint256 i,
        string memory _program,
        string memory _char
    ) internal pure returns (uint256, uint256, bool) {
        if (_canGetSymbol(i + 1, _program)) {
            string memory nextChar = _program.char(i + 1);
            if (_char.equal('/') && nextChar.equal('/')) {
                return (1, i + 2, true);
            } else if (_char.equal('/') && nextChar.equal('*')) {
                return (2, i + 2, true);
            }
        }
        return (0, i, false);
    }

    /**
     * @dev Checks if a symbol is an end symbol of a comment, then increases _index to the next
     * no-comment symbol avoiding an additional iteration
     * @param _ssl is a searched symbol len that might be 0, 1, 2
     * @param i is a current index of a char that might be changed
     * @param _p is a current program string
     * @param _char Current character
     * @return A new index of a char
     * @return Is code commented or not
     */
    function _getEndCommentSymbol(
        uint256 _ssl,
        uint256 i,
        string memory _p,
        string memory _char
    ) internal pure returns (uint256, bool) {
        if (_ssl == 1 && _char.equal('\n')) {
            return (i + 1, false);
        } else if (_ssl == 2 && _char.equal('*') && _canGetSymbol(i + 1, _p)) {
            string memory nextChar = _p.char(i + 1);
            if (nextChar.equal('/')) {
                return (i + 2, false);
            }
        }
        return (i, true);
    }

    /**
     * @dev Checks if it is possible to get next char from a _program
     * @param _index is a current index of a char
     * @param _program is a current program string
     * @return True if program has the next symbol, otherwise is false
     */
    function _canGetSymbol(uint256 _index, string memory _program) internal pure returns (bool) {
        try _program.char(_index) {
            return true;
        } catch Error(string memory) {
            return false;
        }
    }

    /**
     * @dev Returns the length of a string array excluding empty elements
     * Ex. nonEmptyArrLen['h', 'e', 'l', 'l', 'o', '', '', '']) == 5 (not 8)
     * @param _arr Input string array
     * @return i The legth of the array excluding empty elements
     */
    function _nonEmptyArrLen(string[] memory _arr) internal pure returns (uint256 i) {
        while (i < _arr.length && !_arr[i].equal('')) {
            i++;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../helpers/Stack.sol';

interface IProgramContext {
    // Variables
    function ANYONE() external view returns (address);

    function stack() external view returns (Stack);

    function program() external view returns (bytes memory);

    function currentProgram() external view returns (bytes memory);

    function programAt(uint256 _start, uint256 _size) external view returns (bytes memory);

    function pc() external view returns (uint256);

    function nextpc() external view returns (uint256);

    function appAddr() external view returns (address);

    function msgSender() external view returns (address);

    function msgValue() external view returns (uint256);

    function isStructVar(string memory _varName) external view returns (bool);

    function labelPos(string memory _name) external view returns (uint256);

    function setLabelPos(string memory _name, uint256 _value) external;

    function forLoopIterationsRemaining() external view returns (uint256);

    function setProgram(bytes memory _data) external;

    function setPc(uint256 _pc) external;

    function setNextPc(uint256 _nextpc) external;

    function incPc(uint256 _val) external;

    function setMsgSender(address _msgSender) external;

    function setMsgValue(uint256 _msgValue) external;

    function setStructVars(
        string memory _structName,
        string memory _varName,
        string memory _fullName
    ) external;

    function structParams(
        bytes4 _structName,
        bytes4 _varName
    ) external view returns (bytes4 _fullName);

    function setForLoopIterationsRemaining(uint256 _forLoopIterationsRemaining) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ErrorsStringUtils } from './Errors.sol';
import { ByteUtils } from './ByteUtils.sol';

/**
 * @dev Library that simplifies working with strings in Solidity
 */
library StringUtils {
    /**
     * @dev Get character in string by index
     * @param _s Input string
     * @param _index Target index in the string
     * @return Character by index
     */
    function char(string memory _s, uint256 _index) public pure returns (string memory) {
        require(_index < length(_s), ErrorsStringUtils.SUT1);
        bytes memory _sBytes = new bytes(1);
        _sBytes[0] = bytes(_s)[_index];
        return string(_sBytes);
    }

    /**
     * @dev Compares two strings
     * @param _s1 One string
     * @param _s2 Another string
     * @return Are string equal
     */
    function equal(string memory _s1, string memory _s2) internal pure returns (bool) {
        return keccak256(abi.encodePacked(_s1)) == keccak256(abi.encodePacked(_s2));
    }

    /**
     * @dev Gets length of the string
     * @param _s Input string
     * @return The lenght of the string
     */
    function length(string memory _s) internal pure returns (uint256) {
        return bytes(_s).length;
    }

    /**
     * @dev Concats two strings
     * @param _s1 One string
     * @param _s2 Another string
     * @return The concatenation of the strings
     */
    function concat(string memory _s1, string memory _s2) internal pure returns (string memory) {
        return string(abi.encodePacked(_s1, _s2));
    }

    /**
     * @dev Creates a substring from a string
     * Ex. substr('0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE', 2, 42) => '9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE'
     * @param _str Input string
     * @param _start Start index (inclusive)
     * @param _end End index (not inclusive)
     * @return Substring
     */
    function substr(
        string memory _str,
        uint256 _start,
        uint256 _end
    ) public pure returns (string memory) {
        bytes memory strBytes = bytes(_str);
        bytes memory result = new bytes(_end - _start);
        for (uint256 i = _start; i < _end; i++) {
            result[i - _start] = strBytes[i];
        }
        return string(result);
    }

    /**
     * @dev Checks is _char is present in the _string
     * Ex. `_`.in('123_456') => true
     * Ex. `8`.in('123456') => false
     * @param _char Searched character
     * @param _string String to search in
     * @return Is the character presented in the string
     */
    function isIn(string memory _char, string memory _string) public pure returns (bool) {
        for (uint256 i = 0; i < length(_string); i++) {
            if (equal(char(_string, i), _char)) return true;
        }
        return false;
    }

    // Convert an hexadecimal string (without "0x" prefix) to raw bytes
    function fromHex(string memory s) public pure returns (bytes memory) {
        return ByteUtils.fromHexBytes(bytes(s));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation
     * @notice Inspired by OraclizeAPI's implementation - MIT licence
     * https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
     * @param _num Input number
     * @return Number represented as a string
     */
    function toString(uint256 _num) internal pure returns (string memory) {
        if (_num == 0) {
            return '0';
        }
        uint256 _temp = _num;
        uint256 _digits;
        while (_temp != 0) {
            _digits++;
            _temp /= 10;
        }
        bytes memory _buffer = new bytes(_digits);
        while (_num != 0) {
            _digits -= 1;
            _buffer[_digits] = bytes1(uint8(48 + uint256(_num % 10)));
            _num /= 10;
        }
        return string(_buffer);
    }

    /**
     * @dev Converts a decimal number (provided as a string) to uint256
     * @param _s Input decimal number (provided as a string)
     * @return value Unsigned integer from input string
     */
    function toUint256(string memory _s) public pure returns (uint256 value) {
        bytes memory b = bytes(_s);
        uint256 tmp;
        for (uint256 i = 0; i < b.length; i++) {
            tmp = uint8(b[i]);
            require(tmp >= 0x30 && tmp <= 0x39, ErrorsStringUtils.SUT3);
            value = value * 10 + (tmp - 0x30); // 0x30 ascii is '0'
        }
    }

    /**
     * @dev Converts a decimal number (provided as a string) with e symbol (1e18) to number (returned as a string)
     * @param _s Input decimal number (provided as a string)
     * @return result Unsigned integer in a string format
     */
    function parseScientificNotation(string memory _s) public pure returns (string memory result) {
        bool isFound; // was `e` symbol found
        uint256 tmp;
        bytes memory b = bytes(_s);
        string memory base;
        string memory decimals;

        for (uint256 i = 0; i < b.length; i++) {
            tmp = uint8(b[i]);

            if (tmp >= 0x30 && tmp <= 0x39) {
                if (!isFound) {
                    base = concat(base, string(abi.encodePacked(b[i])));
                } else {
                    decimals = concat(decimals, string(abi.encodePacked(b[i])));
                }
            } else if (tmp == 0x65 && !isFound) {
                isFound = true;
            } else {
                // use only one `e` sympol between values without spaces; example: 1e18 or 456e10
                revert(ErrorsStringUtils.SUT5);
            }
        }

        require(!equal(base, ''), ErrorsStringUtils.SUT9);
        require(!equal(decimals, ''), ErrorsStringUtils.SUT6);
        result = toString(toUint256(base) * (10 ** toUint256(decimals)));
    }

    /**
     * @dev If the string starts with a number, so we assume that it's a number.
     * @param _string is a current string for checking
     * @return isNumber that is true if the string starts with a number, otherwise is false
     */
    function mayBeNumber(string memory _string) public pure returns (bool) {
        require(!equal(_string, ''), ErrorsStringUtils.SUT7);
        bytes1 _byte = bytes(_string)[0];
        return uint8(_byte) >= 48 && uint8(_byte) <= 57;
    }

    /**
     * @dev If the string starts with `0x` symbols, so we assume that it's an address.
     * @param _string is a current string for checking
     * @return isAddress that is true if the string starts with `0x` symbols, otherwise is false
     */
    function mayBeAddress(string memory _string) public pure returns (bool) {
        require(!equal(_string, ''), ErrorsStringUtils.SUT7);
        if (bytes(_string).length != 42) return false;

        bytes1 _byte = bytes(_string)[0];
        bytes1 _byte2 = bytes(_string)[1];
        return uint8(_byte) == 48 && uint8(_byte2) == 120;
    }

    /**
     * @dev Checks is string is a valid DSL variable name (matches regexp /^([A-Z_$][A-Z\d_$]*)$/g)
     * @param _s is a current string to check
     * @return isCapital whether the string is a valid DSL variable name or not
     */
    function isValidVarName(string memory _s) public pure returns (bool) {
        require(!equal(_s, ''), ErrorsStringUtils.SUT7);

        uint8 A = 0x41;
        uint8 Z = 0x5a;
        uint8 underscore = 0x5f;
        uint8 dollar = 0x24;
        uint8 zero = 0x30;
        uint8 nine = 0x39;

        uint8 symbol;
        // This is the same as applying regexp /^([A-Z_$][A-Z\d_$]*)$/g
        for (uint256 i = 0; i < length(_s); i++) {
            symbol = uint8(bytes(_s)[i]);
            if (
                (i == 0 &&
                    !((symbol >= A && symbol <= Z) || symbol == underscore || symbol == dollar)) ||
                (i > 0 &&
                    !((symbol >= A && symbol <= Z) ||
                        (symbol >= zero && symbol <= nine) ||
                        symbol == underscore ||
                        symbol == dollar))
            ) {
                return false;
            }
        }
        return true;
    }
}

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

interface IPreprocessor {
    function transform(
        address _ctxAddr,
        string memory _program
    ) external view returns (string[] memory);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ErrorsStack } from '../libs/Errors.sol';

contract Stack {
    uint256[] public stack;

    function length() external view returns (uint256) {
        return _length();
    }

    function seeLast() external view returns (uint256) {
        return _seeLast();
    }

    function push(uint256 data) external {
        stack.push(data);
    }

    function pop() external returns (uint256) {
        uint256 data = _seeLast();
        stack.pop();

        return data;
    }

    function clear() external {
        delete stack;
    }

    function _length() internal view returns (uint256) {
        return stack.length;
    }

    function _seeLast() internal view returns (uint256) {
        require(_length() > 0, ErrorsStack.STK4);
        return stack[_length() - 1];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ErrorsStack } from '../libs/Errors.sol';
import { StringUtils } from './StringUtils.sol';

// TODO: add tests for this file
/**
 * @dev This library has all the functions to use solidity string array as a struct
 */
library StringStack {
    using StringUtils for string;

    /**
     * @dev Push element to array in the first position
     * As the array has fixed size, we drop the last element
     * when addind a new one to the beginning of the array
     * @param _stack String stack
     * @param _element String to be added to the stack
     * @return Modified stack
     */
    function pushToStack(
        string[] memory _stack,
        string memory _element
    ) external pure returns (string[] memory) {
        _stack[stackLength(_stack)] = _element;
        return _stack;
    }

    function popFromStack(
        string[] memory _stack
    ) external pure returns (string[] memory, string memory) {
        string memory _topElement = seeLastInStack(_stack);
        _stack[stackLength(_stack) - 1] = '';
        return (_stack, _topElement);
    }

    function stackLength(string[] memory _stack) public pure returns (uint256) {
        uint256 i;
        while (!_stack[i].equal('')) {
            i++;
        }
        return i;
    }

    function seeLastInStack(string[] memory _stack) public pure returns (string memory) {
        uint256 _len = stackLength(_stack);
        require(_len > 0, ErrorsStack.STK4);
        return _stack[_len - 1];
    }
}