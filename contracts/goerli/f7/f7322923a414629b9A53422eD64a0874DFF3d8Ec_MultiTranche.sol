// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IParser } from '../dsl/interfaces/IParser.sol';
import { IProgramContext } from '../dsl/interfaces/IProgramContext.sol';
import { IERC20Mintable } from '../dsl/interfaces/IERC20Mintable.sol';
import { ProgramContext } from '../dsl/ProgramContext.sol';
import { ErrorsAgreement, ErrorsGovernance } from '../dsl/libs/Errors.sol';
import { UnstructuredStorage } from '../dsl/libs/UnstructuredStorage.sol';
import { Executor } from '../dsl/libs/Executor.sol';
import { StringUtils } from '../dsl/libs/StringUtils.sol';
import { ERC20Mintable } from '../dsl/helpers/ERC20Mintable.sol';
import { Agreement } from '../agreement/Agreement.sol';

contract MultiTranche is Agreement {
    using UnstructuredStorage for bytes32;

    uint256 public deadline;
    IERC20Mintable public WUSDC; // WUSDC
    mapping(address => address) public compounds; // token => cToken

    /**
     * Sets parser address, creates new Context instance, and setups Context
     */
    constructor(
        address _parser,
        address _ownerAddr,
        address _dslContext
    ) Agreement(_parser, _ownerAddr, _dslContext) {
        _setBaseRecords();
        WUSDC = new ERC20Mintable('Wrapped USDC', 'WUSDC');
        _setDefaultVariables();
    }

    /**
     * @dev Uploads pre-defined records to Governance contract directly
     */
    function _setBaseRecords() internal {
        _setEnterRecord();
        _setDepositRecord();
        _setWithdrawRecord();
    }

    function _setDefaultVariables() internal {
        // Set WUSDC variable
        setStorageAddress(
            0x1896092e00000000000000000000000000000000000000000000000000000000,
            address(WUSDC)
        );
        // Set MULTI_TRANCHE variable
        setStorageAddress(
            0x0a371cf900000000000000000000000000000000000000000000000000000000,
            address(this)
        );
        // Set cUSDC variable
        address CUSDC_ADDR = 0x73506770799Eb04befb5AaE4734e58C2C624F493;
        setStorageAddress(
            0x48ebcbd300000000000000000000000000000000000000000000000000000000,
            CUSDC_ADDR
        );
        // Set USDC variable
        address USDC_ADDR = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
        setStorageAddress(
            0xd6aca1be00000000000000000000000000000000000000000000000000000000,
            USDC_ADDR
        );
        compounds[USDC_ADDR] = CUSDC_ADDR;

        // TODO: restrict setting DEPOSIT_TIME variable by the user
        // TODO: check that user's cannot modify the DEPOSITS_DEADLINE and LOCK_TIME variables (if they're set)
        // TODO: if DEPOSITS_DEADLINE and LOCK_TIME variable aren't set - don't activate the MultiTranche
    }

    /**
     * @dev Uploads pre-defined records to MultiTranche contract directly.
     * Uses a simple condition string `bool true`.
     * Records still have to be parsed using a preprocessor before execution. Such record becomes
     * non-upgradable. Check `isUpgradableRecord` modifier
     * @param _recordId is the record ID
     * @param _record is a string of the main record for execution
     * @param _condition is a string of the condition that will be checked before record execution
     */
    function _setParameters(
        uint256 _recordId,
        string memory _record,
        string memory _condition
    ) internal {
        address[] memory _signatories = new address[](1);
        string[] memory _conditionStrings = new string[](1);
        uint256[] memory _requiredRecords;
        _conditionStrings[0] = _condition;
        _signatories[0] = IProgramContext(contextProgram).ANYONE();

        update(_recordId, _requiredRecords, _signatories, _record, _conditionStrings);
    }

    /**
     * @dev If DEPOSITS_DEADLINE hasn't passed, then to enter the MultiTranche contract:
     * 1. Understand how much USDC a user wants to deposit
     * 2. Transfer USDC from the user to the MultiTranche
     * 3. Mint WUSDC to the user's wallet in exchange for his/her USDC
     */
    function _setEnterRecord() internal {
        _setParameters(
            1, // record ID
            '(allowance USDC MSG_SENDER MULTI_TRANCHE) setUint256 ALLOWANCE \n'
            'transferFromVar USDC MSG_SENDER MULTI_TRANCHE ALLOWANCE \n'
            'mint WUSDC MSG_SENDER ALLOWANCE', // transaction
            'blockTimestamp < var DEPOSITS_DEADLINE' // condition
        );
    }

    /**
     * @dev If DEPOSITS_DEADLINE is passed to deposit USDC to MultiTranche:
     * 1. Deposit all collected on MultiTranche USDC to Compound.
     *    As a result MultiTranche receives cUSDC tokens from Compound
     * 2. Remember the deposit time in DEPOSIT_TIME variable
     */
    function _setDepositRecord() internal {
        _setParameters(
            2, // record ID
            'compound deposit all USDC \n'
            'blockTimestamp setUint256 DEPOSIT_TIME', // transaction
            'blockTimestamp > var DEPOSITS_DEADLINE' // condition
        );
    }

    /**
     * @dev If USDC lock time is passed:
     * 1. Understand how much WUSDC a user wants to withdraw
     * 2. Withdraw requested amount of USDC from Compound
     * 3. Burn user's WUSDC
     * 4. Send USDC to the user
     */
    function _setWithdrawRecord() internal {
        _setParameters(
            3, // record ID
            '(allowance WUSDC MSG_SENDER MULTI_TRANCHE) setUint256 W_ALLOWANCE \n'
            'burn WUSDC MSG_SENDER W_ALLOWANCE \n'
            'compound withdraw W_ALLOWANCE USDC \n'
            '(W_ALLOWANCE - 1) setUint256 OUT_USDC \n'
            'transferVar USDC MSG_SENDER OUT_USDC', // transaction
            'blockTimestamp > (var DEPOSIT_TIME + var LOCK_TIME)' // condition
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IProgramContext } from './interfaces/IProgramContext.sol';
import { IParser } from './interfaces/IParser.sol';
import { IStorageUniversal } from './interfaces/IStorageUniversal.sol';
import { Stack } from './helpers/Stack.sol';
import { ComparisonOpcodes } from './libs/opcodes/ComparisonOpcodes.sol';
import { BranchingOpcodes } from './libs/opcodes/BranchingOpcodes.sol';
import { LogicalOpcodes } from './libs/opcodes/LogicalOpcodes.sol';
import { OtherOpcodes } from './libs/opcodes/OtherOpcodes.sol';
import { ErrorsContext } from './libs/Errors.sol';

// import 'hardhat/console.sol';

/**
 * @dev Context of DSL code
 *
 * One of the core contracts of the project. It provides additional information about
 * program state and point counter (pc).
 */
contract ProgramContext is IProgramContext {
    // The address that is used to symbolyze any signer inside Conditional Transaction
    address public constant ANYONE = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
    address public appAddr; // address of end application.

    // stack is used by Opcode libraries like `libs/opcodes/*`
    // to store and analyze values and removing after usage
    Stack public stack;
    bytes public program; // the bytecode of a program that is provided by Parser (will be removed)
    uint256 public pc; // point counter shows what the part of command are in proccess now
    uint256 public nextpc;
    address public msgSender;
    uint256 public msgValue;

    mapping(string => bool) public isStructVar;
    mapping(bytes4 => mapping(bytes4 => bytes4)) public structParams;
    mapping(string => uint256) public labelPos; // stores if/ifelse branch positions

    // Counter for the number of iterations for every for-loop in DSL code
    uint256 public forLoopIterationsRemaining;

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), ErrorsContext.CTX1);
        _;
    }

    modifier onlyApp() {
        require(msg.sender == appAddr, ErrorsContext.CTX6);
        _;
    }

    constructor() {
        stack = new Stack();
        appAddr = msg.sender;
    }

    /**
     * @dev Sets the final version of the program.
     * @param _data is the bytecode of the full program
     */
    function setProgram(bytes memory _data) public /*onlyApp */ {
        program = _data;
        setPc(0);
    }

    /**
     * @dev Returns the slice of the program using a step value
     *
     * @param _payload is bytecode of program that will be sliced
     * @param _index is a last byte of the slice
     * @param _step is the step of the slice
     * @return the slice of provided _payload bytecode
     */
    function programSlice(
        bytes calldata _payload,
        uint256 _index,
        uint256 _step
    ) public pure returns (bytes memory) {
        require(_payload.length > _index, ErrorsContext.CTX4);
        return _payload[_index:_index + _step];
    }

    function programAt(uint256 _start, uint256 _size) external view returns (bytes memory) {
        return this.programSlice(program, _start, _size);
    }

    /**
     * @dev Returns the slice of the current program using the index and the step values
     * @return the slice of stored bytecode in the `program` variable
     */
    function currentProgram() public view returns (bytes memory) {
        // program, index, step
        return this.programSlice(program, pc, 1);
    }

    /**
     * @dev Sets the current point counter for the program
     * @param _pc is the new value of the pc
     */
    function setPc(uint256 _pc) public {
        pc = _pc;
    }

    /**
     * @dev Sets the next point counter for the program
     * @param _nextpc is the new value of the nextpc
     */
    function setNextPc(uint256 _nextpc) public {
        nextpc = _nextpc;
    }

    /**
     * @dev Increases the current point counter with the provided value and saves the sum
     * @param _val is the new value that is used for summing it and the current pc value
     */
    function incPc(uint256 _val) public {
        pc += _val;
    }

    /**
     * @dev Sets/Updates msgSender by the provided value
     * @param _msgSender is the new msgSender
     */
    function setMsgSender(address _msgSender) public nonZeroAddress(_msgSender) {
        msgSender = _msgSender;
    }

    /**
     * @dev Sets/Updates msgValue by the provided value
     * @param _msgValue is the new msgValue
     */
    function setMsgValue(uint256 _msgValue) public {
        msgValue = _msgValue;
    }

    /**
     * @dev Sets the full name depends on structure variables
     * @param _structName is the name of the structure
     * @param _varName is the name of the structure variable
     * @param _fullName is the full string of the name of the structure and its variables
     */
    function setStructVars(
        string memory _structName,
        string memory _varName,
        string memory _fullName
    ) public {
        isStructVar[_fullName] = true;
        bytes4 structName = bytes4(keccak256(abi.encodePacked(_structName)));
        bytes4 varName = bytes4(keccak256(abi.encodePacked(_varName)));
        bytes4 fullName = bytes4(keccak256(abi.encodePacked(_fullName)));
        structParams[structName][varName] = fullName;
    }

    /**
     * @dev Sets the number of iterations for the for-loop that is being executed
     * @param _forLoopIterationsRemaining The number of iterations of the loop
     */
    function setForLoopIterationsRemaining(uint256 _forLoopIterationsRemaining) external {
        forLoopIterationsRemaining = _forLoopIterationsRemaining;
    }

    function setLabelPos(string memory _name, uint256 _value) external {
        labelPos[_name] = _value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

import { IERC20 } from './IERC20.sol';

/**
 * @dev Interface of ERC20 token with `mint` and `burn` functions
 */
interface IERC20Mintable is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _to, uint256 _amount) external;
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

import { IAgreement } from '../dsl/interfaces/IAgreement.sol';
import { IParser } from '../dsl/interfaces/IParser.sol';
import { IDSLContext } from '../dsl/interfaces/IDSLContext.sol';
import { IProgramContext } from '../dsl/interfaces/IProgramContext.sol';
import { ProgramContext } from '../dsl/ProgramContext.sol';
import { ErrorsAgreement } from '../dsl/libs/Errors.sol';
import { Executor } from '../dsl/libs/Executor.sol';
import { StringUtils } from '../dsl/libs/StringUtils.sol';
import { AgreementStorage } from './AgreementStorage.sol';
import { LinkedList } from '../dsl/helpers/LinkedList.sol';

// import 'hardhat/console.sol';

// TODO: automatically make sure that no contract exceeds the maximum contract size

/**
 * Financial Agreement written in DSL between two or more users
 *
 * Agreement contract that is used to implement any custom logic of a
 * financial agreement. Ex. lender-borrower agreement
 */
contract Agreement is IAgreement, AgreementStorage, LinkedList {
    using StringUtils for string;

    uint256[] public recordIds; // array of recordId
    address public parser; // TODO: We can get rid of this dependency
    address public contextProgram;
    address public contextDSL;
    address public ownerAddr;
    uint256 public nextParseIndex;
    mapping(uint256 => Record) public records; // recordId => Record struct

    modifier onlyOwner() {
        require(msg.sender == ownerAddr, ErrorsAgreement.AGR11);
        _;
    }

    /**
     * Sets parser address, creates new contextProgram instance, and setups contextProgram
     */
    constructor(address _parser, address _ownerAddr, address _dslContext) {
        _checkZeroAddress(_parser);
        _checkZeroAddress(_ownerAddr);
        _checkZeroAddress(_dslContext);
        ownerAddr = _ownerAddr;
        contextDSL = _dslContext;
        parser = _parser;
        contextProgram = address(new ProgramContext());
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /**
     * @dev archive any of the existing records by recordId.
     * @param _recordId Record ID
     */
    function archiveRecord(uint256 _recordId) external onlyOwner {
        _checkEmptyString(records[_recordId].recordString);
        records[_recordId].isArchived = true;

        emit RecordArchived(_recordId);
    }

    /**
     * @dev unarchive any of the existing records by recordId
     * @param _recordId Record ID
     */
    function unarchiveRecord(uint256 _recordId) external onlyOwner {
        require(records[_recordId].isArchived != false, ErrorsAgreement.AGR10);
        records[_recordId].isArchived = false;

        emit RecordUnarchived(_recordId);
    }

    /**
     * @dev activates the existing records by recordId, only awailable for ownerAddr
     * @param _recordId Record ID
     */
    function activateRecord(uint256 _recordId) external onlyOwner {
        _checkEmptyString(records[_recordId].recordString);
        records[_recordId].isActive = true;

        emit RecordActivated(_recordId);
    }

    /**
     * @dev deactivates the existing records by recordId, only awailable for ownerAddr
     * @param _recordId Record ID
     */
    function deactivateRecord(uint256 _recordId) external onlyOwner {
        require(records[_recordId].isActive != false, ErrorsAgreement.AGR10);
        records[_recordId].isActive = false;

        emit RecordDeactivated(_recordId);
    }

    /**
     * @dev returns true if parsing was finished for the record including
     * conditions otherwise, it returns false
     * The `finished parsing` therm means that all record and conditions
     * already parsed and have got their bytecodes, so all bytecodes
     * already storing in the Agreement smart contract
     */
    function parseFinished() external view returns (bool _result) {
        uint256 i;
        uint256 recordId;
        string memory code;
        for (i; i < recordIds.length; i++) {
            uint256 count = 0;
            recordId = recordIds[i];
            code = records[recordId].recordString;
            // check that the main transaction was set already
            if (records[recordId].isRecordSet[code]) {
                for (uint256 j; j < records[recordId].conditionStrings.length; j++) {
                    code = records[recordId].conditionStrings[j];
                    // check that the conditions were set already
                    if (records[recordId].isConditionSet[code]) {
                        count++;
                    }
                }
            }
            if (count != records[recordId].conditionStrings.length) return false;
        }
        return true;
    }

    /**
     * @dev Parse DSL code from the user and set the program bytecode in Agreement contract
     * @param _preProc Preprocessor address
     */
    function parse(address _preProc) external returns (bool _result) {
        uint256 i;
        uint256 recordId;
        string memory code;
        for (i; i < recordIds.length; i++) {
            recordId = recordIds[i];
            code = records[recordId].recordString;
            if (!records[recordId].isRecordSet[code]) {
                _parse(recordId, _preProc, code, true);
                return true;
            } else {
                for (uint256 j; j < conditionStringsLen(recordId); j++) {
                    code = records[recordId].conditionStrings[j];
                    if (!records[recordId].isConditionSet[code]) {
                        _parse(recordId, _preProc, code, false);
                        return true;
                    }
                }
            }
        }
    }

    /**
     * @dev Parse DSL code and set the program bytecode in Agreement contract
     * @param _recordId Record ID
     * @param _preProc Preprocessor address
     * @param _code DSL code for the record of the condition
     * @param _isRecord a flag that shows if provided _code is a record or
     * not (a condition then)
     */
    function _parse(
        uint256 _recordId,
        address _preProc,
        string memory _code,
        bool _isRecord
    ) internal {
        IParser(parser).parse(_preProc, contextDSL, contextProgram, _code);
        if (_isRecord) {
            records[_recordId].isRecordSet[_code] = true;
            records[_recordId].recordProgram = _getProgram();
        } else {
            records[_recordId].isConditionSet[_code] = true;
            records[_recordId].conditions.push(_getProgram());
        }

        emit Parsed(_preProc, _code);
    }

    /**
     * @dev Updates Agreement contract by DSL code for the record
     * and its conditions. All records that will be updated still
     * need to be parsed. Please, check the `parse` function for more details
     * TODO: rename this function to addRecord
     * @param _recordId Record ID
     * @param _requiredRecords array of required records in the record
     * @param _signatories array of signatories in the record
     * @param _recordString string of record DSL transaction
     * @param _conditionStrings the array of conditions string for the record
     */
    function update(
        uint256 _recordId,
        uint256[] memory _requiredRecords,
        address[] memory _signatories,
        string memory _recordString,
        string[] memory _conditionStrings
    ) public {
        _addRecordBlueprint(_recordId, _requiredRecords, _signatories);
        for (uint256 i = 0; i < _conditionStrings.length; i++) {
            _addRecordCondition(_recordId, _conditionStrings[i]);
        }
        _addRecordTransaction(_recordId, _recordString);
        if (msg.sender == ownerAddr) {
            records[_recordId].isActive = true;
        }

        emit NewRecord(_recordId, _requiredRecords, _signatories, _recordString, _conditionStrings);
    }

    /**
     * @dev Check if the recorcID is executable (validate all conditions before
     * record execution, check signatures).
     * @param _recordId Record ID
     */
    function execute(uint256 _recordId) external payable virtual {
        _verifyRecord(_recordId);
        require(_fulfill(_recordId, msg.value, msg.sender), ErrorsAgreement.AGR3);
        emit RecordExecuted(msg.sender, _recordId, msg.value, records[_recordId].recordString);
    }

    function _verifyRecord(uint256 _recordId) internal {
        require(records[_recordId].isActive, ErrorsAgreement.AGR13);
        require(_verify(_recordId), ErrorsAgreement.AGR1);
        require(_validateRequiredRecords(_recordId), ErrorsAgreement.AGR2);
        require(_validateConditions(_recordId, msg.value), ErrorsAgreement.AGR6);
    }

    /**
     * @dev Returns the condition string for provided recordID
     * and index for the searching condition string
     * @param _recordId Record ID
     */
    function conditionString(uint256 _recordId, uint256 i) external view returns (string memory) {
        require(i < records[_recordId].conditionStrings.length, ErrorsAgreement.AGR16);
        return records[_recordId].conditionStrings[i];
    }

    /**
     * @dev Sorted all records and return array of active records in Agreement
     * @return activeRecords array of active records in Agreement
     */
    function getActiveRecords() external view returns (uint256[] memory) {
        uint256 count = 0;
        uint256[] memory activeRecords = new uint256[](_activeRecordsLen());
        for (uint256 i = 0; i < recordIds.length; i++) {
            if (
                records[recordIds[i]].isActive &&
                !records[recordIds[i]].isArchived &&
                !records[recordIds[i]].isExecuted
            ) {
                activeRecords[count] = recordIds[i];
                count++;
            }
        }
        return activeRecords;
    }

    /**
     * @dev return valuses for preview record before execution
     * @param _recordId Record ID
     * @return _requiredRecords array of required records in the record
     * @return _signatories array of signatories in the record
     * @return _conditions array of conditions in the record
     * @return _record string of record DSL transaction
     * @return _isActive true if the record is active
     */
    function getRecord(
        uint256 _recordId
    )
        external
        view
        returns (
            uint256[] memory _requiredRecords,
            address[] memory _signatories,
            string[] memory _conditions,
            string memory _record,
            bool _isActive
        )
    {
        _requiredRecords = records[_recordId].requiredRecords;
        _signatories = records[_recordId].signatories;
        _conditions = records[_recordId].conditionStrings;
        _record = records[_recordId].recordString;
        _isActive = records[_recordId].isActive;
    }

    /**********************
     * Internal Functions *
     *********************/

    /**
     * @dev Checks input _signatures that only one 'ANYONE' address exists in the
     * list or that 'ANYONE' address does not exist in signatures at all
     * @param _signatories the list of addresses
     */
    function _checkSignatories(address[] memory _signatories) internal view {
        require(_signatories.length != 0, ErrorsAgreement.AGR4);
        _checkZeroAddress(_signatories[0]);
        if (_signatories.length > 1) {
            for (uint256 i = 0; i < _signatories.length; i++) {
                _checkZeroAddress(_signatories[i]);
                require(_signatories[i] != _anyone(), ErrorsAgreement.AGR4);
            }
        }
    }

    /**
     * Verify that the user who wants to execute the record is amoung the signatories for this Record
     * @param _recordId ID of the record
     * @return true if the user is allowed to execute the record, false - otherwise
     */
    function _verify(uint256 _recordId) internal view returns (bool) {
        if (
            records[_recordId].signatories.length == 1 &&
            records[_recordId].signatories[0] == _anyone()
        ) return true;

        for (uint256 i = 0; i < records[_recordId].signatories.length; i++) {
            if (records[_recordId].signatories[i] == msg.sender) return true;
        }
        return false;
    }

    /**
     * @dev Check that all records required by this records were executed
     * @param _recordId ID of the record
     * @return true all the required records were executed, false - otherwise
     */
    function _validateRequiredRecords(uint256 _recordId) internal view returns (bool) {
        uint256[] memory _requiredRecords = records[_recordId].requiredRecords;
        for (uint256 i = 0; i < _requiredRecords.length; i++) {
            if (!records[_requiredRecords[i]].isExecuted) return false;
        }

        return true;
    }

    /**
     * @dev Define some basic values for a new record
     * @param _recordId is the ID of a transaction
     * @param _requiredRecords transactions ids that have to be executed
     * @param _signatories addresses that can execute the chosen transaction
     */
    function _addRecordBlueprint(
        uint256 _recordId,
        uint256[] memory _requiredRecords,
        address[] memory _signatories
    ) internal {
        _checkSignatories(_signatories);
        records[_recordId].requiredRecords = _requiredRecords;
        records[_recordId].signatories = _signatories;
        recordIds.push(_recordId);
    }

    /**
     * @dev Conditional Transaction: Append a condition to already existing conditions
     * inside Record
     * @param _recordId Record ID
     * @param _conditionStr DSL code for condition
     */
    function _addRecordCondition(uint256 _recordId, string memory _conditionStr) internal {
        _checkEmptyString(_conditionStr);
        records[_recordId].conditionStrings.push(_conditionStr);
    }

    /**
     * @dev Adds a transaction that should be executed if all
     * conditions inside Record are met
     * @param _recordId Record ID
     * @param _recordString DSL code for record string
     */
    function _addRecordTransaction(uint256 _recordId, string memory _recordString) internal {
        require(records[_recordId].conditionStrings.length > 0, ErrorsAgreement.AGR5);
        records[_recordId].recordString = _recordString;
    }

    /**
     * @dev Validate all conditions for the certain record ID
     * @param _recordId Record ID to execute
     * @param _msgValue Value that were sent along with function execution // TODO: possibly remove this argument
     */
    function _validateConditions(uint256 _recordId, uint256 _msgValue) internal returns (bool) {
        for (uint256 i = 0; i < records[_recordId].conditions.length; i++) {
            _execute(_msgValue, records[_recordId].conditions[i]);
            if (_seeLast() == 0) return false;
        }
        return true;
    }

    /**
     * @dev Fulfill Record
     * @param _recordId Record ID to execute
     * @param _msgValue Value that were sent along with function execution // TODO: possibly remove this argument
     * @param _signatory The user that is executing the Record
     * @return result Boolean whether the record was successfully executed or not
     */
    function _fulfill(
        uint256 _recordId,
        uint256 _msgValue,
        address _signatory
    ) internal returns (bool result) {
        require(!records[_recordId].isExecutedBySignatory[_signatory], ErrorsAgreement.AGR7);
        _execute(_msgValue, records[_recordId].recordProgram);
        records[_recordId].isExecutedBySignatory[_signatory] = true;

        // Check if record was executed by all signatories
        uint256 executionProgress;
        address[] memory signatoriesOfRecord = records[_recordId].signatories;
        for (uint256 i = 0; i < signatoriesOfRecord.length; i++) {
            if (records[_recordId].isExecutedBySignatory[signatoriesOfRecord[i]])
                executionProgress++;
        }
        // If all signatories have executed the transaction - mark the tx as executed
        if (executionProgress == signatoriesOfRecord.length) {
            records[_recordId].isExecuted = true;
        }
        return _seeLast() == 0 ? false : true;
    }

    /**
     * @dev Execute Record
     * @param _msgValue Value that were sent along with function execution
     // TODO: possibly remove this argument
     * @param _program provided bytcode of the program
     */
    function _execute(uint256 _msgValue, bytes memory _program) private {
        IProgramContext(address(contextProgram)).setMsgValue(_msgValue);
        IProgramContext(address(contextProgram)).setProgram(_program);
        Executor.execute(contextDSL, contextProgram);
    }

    /**
     * @dev return length of active records for getActiveRecords
     * @return count length of active records array
     */
    function _activeRecordsLen() internal view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < recordIds.length; i++) {
            if (
                records[recordIds[i]].isActive &&
                !records[recordIds[i]].isArchived &&
                !records[recordIds[i]].isExecuted
            ) {
                count++;
            }
        }
        return count;
    }

    function conditionStringsLen(uint256 _recordId) public view returns (uint256) {
        return records[_recordId].conditionStrings.length;
    }

    function _seeLast() private view returns (uint256) {
        return IProgramContext(contextProgram).stack().seeLast();
    }

    function _anyone() private view returns (address) {
        return IProgramContext(contextProgram).ANYONE();
    }

    function _checkEmptyString(string memory _string) private pure {
        require(!StringUtils.equal(_string, ''), ErrorsAgreement.AGR5);
    }

    function _checkZeroAddress(address _address) private pure {
        require(_address != address(0), ErrorsAgreement.AGR12);
    }

    function _getProgram() private view returns (bytes memory) {
        return IProgramContext(contextProgram).program();
    }
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

import { IDSLContext } from '../interfaces/IDSLContext.sol';
import { IProgramContext } from '../interfaces/IProgramContext.sol';
import { ErrorsExecutor, ErrorsContext } from './Errors.sol';

// import 'hardhat/console.sol';

library Executor {
    function execute(address _dslContext, address _programContext) public {
        bytes memory program = IProgramContext(_programContext).program();
        require(program.length > 0, ErrorsExecutor.EXC1);
        bytes memory opcodeBytes;
        bytes1 opcodeByte;
        bytes4 _selector;
        address _lib;
        bool success;
        IDSLContext.OpcodeLibNames _libName;

        IProgramContext(_programContext).setMsgSender(msg.sender);

        while (IProgramContext(_programContext).pc() < program.length) {
            opcodeBytes = IProgramContext(_programContext).currentProgram();
            opcodeByte = bytes1(uint8(opcodeBytes[0]));
            _selector = IDSLContext(_dslContext).selectorByOpcode(opcodeByte);
            require(_selector != 0x0, ErrorsExecutor.EXC2);

            _libName = IDSLContext(_dslContext).opcodeLibNameByOpcode(opcodeByte);

            IProgramContext(_programContext).incPc(1);

            if (_libName == IDSLContext.OpcodeLibNames.ComparisonOpcodes) {
                _lib = IDSLContext(_dslContext).comparisonOpcodes();
            } else if (_libName == IDSLContext.OpcodeLibNames.BranchingOpcodes) {
                _lib = IDSLContext(_dslContext).branchingOpcodes();
            } else if (_libName == IDSLContext.OpcodeLibNames.LogicalOpcodes) {
                _lib = IDSLContext(_dslContext).logicalOpcodes();
            } else {
                _lib = IDSLContext(_dslContext).otherOpcodes();
            }
            (success, ) = _lib.delegatecall(
                abi.encodeWithSelector(_selector, _programContext, _dslContext)
            );
            require(success, ErrorsExecutor.EXC3);
        }
        IProgramContext(_programContext).setPc(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library UnstructuredStorage {
    function getStorageBool(bytes32 position) internal view returns (bool data) {
        assembly {
            data := sload(position)
        }
    }

    function getStorageAddress(bytes32 position) internal view returns (address data) {
        assembly {
            data := sload(position)
        }
    }

    function getStorageBytes32(bytes32 position) internal view returns (bytes32 data) {
        assembly {
            data := sload(position)
        }
    }

    function getStorageUint256(bytes32 position) internal view returns (uint256 data) {
        assembly {
            data := sload(position)
        }
    }

    function setStorageBool(bytes32 position, bytes32 data) internal {
        bool val = data != bytes32(0);
        assembly {
            sstore(position, val)
        }
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageAddress(bytes32 position, bytes32 data) internal {
        address val = address(bytes20(data));
        assembly {
            sstore(position, val)
        }
    }

    function setStorageAddress(bytes32 position, address data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageBytes32(bytes32 position, bytes32 data) internal {
        assembly {
            sstore(position, data)
        }
    }

    function setStorageUint256(bytes32 position, bytes32 data) internal {
        uint256 val = uint256(bytes32(data));
        assembly {
            sstore(position, val)
        }
    }

    function setStorageUint256(bytes32 position, uint256 data) internal {
        assembly {
            sstore(position, data)
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ERC20 } from './ERC20.sol';
import { IERC20Mintable } from '../interfaces/IERC20Mintable.sol';

contract ERC20Mintable is ERC20, IERC20Mintable {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function burn(address _to, uint256 _amount) external {
        _burn(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStorageUniversal {
    function setStorageBool(bytes32 position, bytes32 data) external;

    function setStorageAddress(bytes32 position, bytes32 data) external;

    function setStorageUint256(bytes32 position, bytes32 data) external;
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

import { IProgramContext } from '../../interfaces/IProgramContext.sol';
import { IERC20 } from '../../interfaces/IERC20.sol';
import { StringUtils } from '../StringUtils.sol';
import { UnstructuredStorage } from '../UnstructuredStorage.sol';
import { OpcodeHelpers } from './OpcodeHelpers.sol';
import { ErrorsGeneralOpcodes } from '../Errors.sol';

// import 'hardhat/console.sol';

/**
 * @title Set operator opcodes
 * @notice Opcodes for set operators such as AND, OR, XOR
 */
library LogicalOpcodes {
    using UnstructuredStorage for bytes32;
    using StringUtils for string;

    /**
     * @dev Compares two values in the stack. Put 1 if both of them are 1, put
     *      0 otherwise
     * @param _ctxProgram Context contract address
     */
    function opAnd(address _ctxProgram, address) public {
        uint256 last = IProgramContext(_ctxProgram).stack().pop();
        uint256 prev = IProgramContext(_ctxProgram).stack().pop();
        OpcodeHelpers.putToStack(_ctxProgram, (prev > 0) && (last > 0) ? 1 : 0);
    }

    /**
     * @dev Compares two values in the stack. Put 1 if either one of them is 1,
     *      put 0 otherwise
     * @param _ctxProgram Context contract address
     */
    function opOr(address _ctxProgram, address) public {
        uint256 last = IProgramContext(_ctxProgram).stack().pop();
        uint256 prev = IProgramContext(_ctxProgram).stack().pop();
        OpcodeHelpers.putToStack(_ctxProgram, (prev > 0) || (last > 0) ? 1 : 0);
    }

    /**
     * @dev Compares two values in the stack. Put 1 if the values ​
     * ​are different and 0 if they are the same
     * @param _ctxProgram Context contract address
     */
    function opXor(address _ctxProgram, address) public {
        uint256 last = IProgramContext(_ctxProgram).stack().pop();
        uint256 prev = IProgramContext(_ctxProgram).stack().pop();
        OpcodeHelpers.putToStack(
            _ctxProgram,
            ((prev > 0) && (last == 0)) || ((prev == 0) && (last > 0)) ? 1 : 0
        );
    }

    /**
     * @dev Add two values and put result in the stack.
     * @param _ctxProgram Context contract address
     */
    function opAdd(address _ctxProgram, address) public {
        uint256 last = IProgramContext(_ctxProgram).stack().pop();
        uint256 prev = IProgramContext(_ctxProgram).stack().pop();
        OpcodeHelpers.putToStack(_ctxProgram, prev + last);
    }

    /**
     * @dev Subtracts one value from enother and put result in the stack.
     * @param _ctxProgram Context contract address
     */
    function opSub(address _ctxProgram, address) public {
        uint256 last = IProgramContext(_ctxProgram).stack().pop();
        uint256 prev = IProgramContext(_ctxProgram).stack().pop();
        OpcodeHelpers.putToStack(_ctxProgram, prev - last);
    }

    /**
     * @dev Multiplies values and put result in the stack.
     * @param _ctxProgram Context contract address
     */
    function opMul(address _ctxProgram, address) public {
        uint256 last = IProgramContext(_ctxProgram).stack().pop();
        uint256 prev = IProgramContext(_ctxProgram).stack().pop();
        OpcodeHelpers.putToStack(_ctxProgram, prev * last);
    }

    /**
     * Divide two numbers from the top of the stack
     * @dev This is an integer division. Example: 5 / 2 = 2
     * @param _ctxProgram Context address
     */
    function opDiv(address _ctxProgram, address) public {
        uint256 last = IProgramContext(_ctxProgram).stack().pop();
        uint256 prev = IProgramContext(_ctxProgram).stack().pop();
        OpcodeHelpers.putToStack(_ctxProgram, prev / last);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IProgramContext } from '../../interfaces/IProgramContext.sol';
import { IERC20 } from '../../interfaces/IERC20.sol';
import { StringUtils } from '../StringUtils.sol';
import { UnstructuredStorage } from '../UnstructuredStorage.sol';
import { OpcodeHelpers } from './OpcodeHelpers.sol';
import { ErrorsGeneralOpcodes } from '../Errors.sol';

// import 'hardhat/console.sol';

/**
 * @title Comparator operator opcodes
 * @notice Opcodes for comparator operators such as >, <, =, !, etc.
 */
library ComparisonOpcodes {
    using UnstructuredStorage for bytes32;
    using StringUtils for string;

    /**
     * @dev Compares two values in the stack. Put 1 to the stack if they are equal.
     * @param _ctxProgram Context contract address
     */
    function opEq(address _ctxProgram, address) public {
        uint256 last = IProgramContext(_ctxProgram).stack().pop();
        uint256 prev = IProgramContext(_ctxProgram).stack().pop();
        IProgramContext(_ctxProgram).stack().push(last == prev ? 1 : 0);
    }

    /**
     * @dev Compares two values in the stack. Put 1 to the stack if they are not equal.
     * @param _ctxProgram Context contract address
     */
    function opNotEq(address _ctxProgram, address) public {
        uint256 last = IProgramContext(_ctxProgram).stack().pop();
        uint256 prev = IProgramContext(_ctxProgram).stack().pop();
        OpcodeHelpers.putToStack(_ctxProgram, last != prev ? 1 : 0);
    }

    /**
     * @dev Compares two values in the stack. Put 1 to the stack if value1 < value2
     * @param _ctxProgram Context contract address
     */
    function opLt(address _ctxProgram, address) public {
        uint256 last = IProgramContext(_ctxProgram).stack().pop();
        uint256 prev = IProgramContext(_ctxProgram).stack().pop();
        OpcodeHelpers.putToStack(_ctxProgram, prev < last ? 1 : 0);
    }

    /**
     * @dev Compares two values in the stack. Put 1 to the stack if value1 > value2
     * @param _ctxProgram Context contract address
     */
    function opGt(address _ctxProgram, address) public {
        opSwap(_ctxProgram, address(0));
        opLt(_ctxProgram, address(0));
    }

    /**
     * @dev Compares two values in the stack. Put 1 to the stack if value1 <= value2
     * @param _ctxProgram Context contract address
     */
    function opLe(address _ctxProgram, address) public {
        opGt(_ctxProgram, address(0));
        opNot(_ctxProgram, address(0));
    }

    /**
     * @dev Compares two values in the stack. Put 1 to the stack if value1 >= value2
     * @param _ctxProgram Context contract address
     */
    function opGe(address _ctxProgram, address) public {
        opLt(_ctxProgram, address(0));
        opNot(_ctxProgram, address(0));
    }

    /**
     * @dev Revert last value in the stack
     * @param _ctxProgram Context contract address
     */
    function opNot(address _ctxProgram, address) public {
        uint256 last = IProgramContext(_ctxProgram).stack().pop();
        OpcodeHelpers.putToStack(_ctxProgram, last == 0 ? 1 : 0);
    }

    /**
     * @dev Swaps two last element in the stack
     * @param _ctxProgram Context contract address
     */
    function opSwap(address _ctxProgram, address) public {
        uint256 last = IProgramContext(_ctxProgram).stack().pop();
        uint256 prev = IProgramContext(_ctxProgram).stack().pop();
        IProgramContext(_ctxProgram).stack().push(last);
        IProgramContext(_ctxProgram).stack().push(prev);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IDSLContext } from '../../interfaces/IDSLContext.sol';
import { IProgramContext } from '../../interfaces/IProgramContext.sol';
import { IERC20 } from '../../interfaces/IERC20.sol';
import { IcToken } from '../../interfaces/IcToken.sol';
import { IERC20Mintable } from '../../interfaces/IERC20Mintable.sol';
import { StringUtils } from '../StringUtils.sol';
import { UnstructuredStorage } from '../UnstructuredStorage.sol';
import { OpcodeHelpers } from './OpcodeHelpers.sol';
import { ErrorsGeneralOpcodes } from '../Errors.sol';

// import 'hardhat/console.sol';

library OtherOpcodes {
    using UnstructuredStorage for bytes32;
    using StringUtils for string;

    function opLoadRemoteAny(address _ctxProgram, address _ctxDSL) public {
        _mustDelegateCall(_ctxProgram, _ctxDSL, 'loadRemote');
    }

    function opCompound(address _ctxProgram, address _ctxDSL) public {
        _mustDelegateCall(_ctxProgram, _ctxDSL, 'compound');
    }

    function _mustDelegateCall(
        address _ctxProgram,
        address _ctxDSL,
        string memory _opcode
    ) internal {
        address libAddr = IDSLContext(_ctxDSL).otherOpcodes();
        bytes4 _selector = OpcodeHelpers.nextBranchSelector(_ctxDSL, _ctxProgram, _opcode);
        OpcodeHelpers.mustDelegateCall(
            libAddr,
            abi.encodeWithSelector(_selector, _ctxProgram, _ctxDSL)
        );
    }

    function opBlockNumber(address _ctxProgram, address) public {
        OpcodeHelpers.putToStack(_ctxProgram, block.number);
    }

    function opBlockTimestamp(address _ctxProgram, address) public {
        OpcodeHelpers.putToStack(_ctxProgram, block.timestamp);
    }

    function opBlockChainId(address _ctxProgram, address) public {
        OpcodeHelpers.putToStack(_ctxProgram, block.chainid);
    }

    function opMsgSender(address _ctxProgram, address) public {
        OpcodeHelpers.putToStack(
            _ctxProgram,
            uint256(uint160(IProgramContext(_ctxProgram).msgSender()))
        );
    }

    function opMsgValue(address _ctxProgram, address) public {
        OpcodeHelpers.putToStack(
            _ctxProgram,
            uint256(uint160(IProgramContext(_ctxProgram).msgValue()))
        );
    }

    /**
     * @dev This is a wrapper function for OpcodeHelpers.getNextBytes() that is returning the slice of the program that
     *      we're working with
     * @param _ctxProgram ProgramContext contract address
     * @param _slice Slice size
     * @return the slice of the program
     */
    function _getParam(address _ctxProgram, uint256 _slice) internal returns (bytes32) {
        return OpcodeHelpers.getNextBytes(_ctxProgram, _slice);
    }

    /**
     * @dev Sets boolean variable in the application contract.
     * The value of bool variable is taken from DSL code itself
     * @param _ctxProgram ProgramContext contract address
     */
    function opSetLocalBool(address _ctxProgram, address) public {
        bytes32 _varNameB32 = _getParam(_ctxProgram, 4);
        bytes memory data = OpcodeHelpers.nextBytes(_ctxProgram, 1);
        bool _boolVal = uint8(data[0]) == 1;
        // Set local variable by it's hex
        OpcodeHelpers.mustCall(
            IProgramContext(_ctxProgram).appAddr(),
            abi.encodeWithSignature('setStorageBool(bytes32,bool)', _varNameB32, _boolVal)
        );
        OpcodeHelpers.putToStack(_ctxProgram, 1);
    }

    /**
     * @dev Sets uint256 variable in the application contract. The value of the variable is taken from stack
     * @param _ctxProgram ProgramContext contract address
     */
    function opSetUint256(address _ctxProgram, address) public {
        bytes32 _varNameB32 = _getParam(_ctxProgram, 4);
        uint256 _val = IProgramContext(_ctxProgram).stack().pop();

        // Set local variable by it's hex
        OpcodeHelpers.mustCall(
            IProgramContext(_ctxProgram).appAddr(),
            abi.encodeWithSignature('setStorageUint256(bytes32,uint256)', _varNameB32, _val)
        );
        OpcodeHelpers.putToStack(_ctxProgram, 1);
    }

    /**
     * @dev Gets an element by its index in the array
     * @param _ctxProgram ProgramContext contract address
     */
    function opGet(address _ctxProgram, address) public {
        uint256 _index = opUint256Get(_ctxProgram, address(0));
        bytes32 _arrNameB32 = _getParam(_ctxProgram, 4);

        // check if the array exists
        bytes memory data = OpcodeHelpers.mustCall(
            IProgramContext(_ctxProgram).appAddr(),
            abi.encodeWithSignature('getType(bytes32)', _arrNameB32)
        );
        require(bytes1(data) != bytes1(0x0), ErrorsGeneralOpcodes.OP2);
        (data) = OpcodeHelpers.mustCall(
            IProgramContext(_ctxProgram).appAddr(),
            abi.encodeWithSignature(
                'get(uint256,bytes32)',
                _index, // index of the searched item
                _arrNameB32 // array name, ex. INDEX_LIST, PARTNERS
            )
        );
        OpcodeHelpers.putToStack(_ctxProgram, uint256(bytes32(data)));
    }

    /**
     * @dev Sums uin256 elements from the array (array name should be provided)
     * @param _ctxDSL DSLContext contract instance address
     * @param _ctxProgram ProgramContext contract address
     */
    function opSumOf(address _ctxProgram, address _ctxDSL) public {
        bytes32 _arrNameB32 = _getParam(_ctxProgram, 4);

        _checkArrType(_ctxDSL, _ctxProgram, _arrNameB32, 'uint256');
        bytes32 _length = _getArrLength(_ctxProgram, _arrNameB32);
        // sum items and store into the stack
        uint256 total = _sumOfVars(_ctxProgram, _arrNameB32, _length);
        OpcodeHelpers.putToStack(_ctxProgram, total);
    }

    /**
     * @dev Sums struct variables values from the `struct type` array
     * @param _ctxDSL DSLContext contract instance address
     * @param _ctxProgram ProgramContext contract address
     */
    function opSumThroughStructs(address _ctxProgram, address _ctxDSL) public {
        bytes32 _arrNameB32 = _getParam(_ctxProgram, 4);
        bytes32 _varNameB32 = _getParam(_ctxProgram, 4);

        _checkArrType(_ctxDSL, _ctxProgram, _arrNameB32, 'struct');
        bytes32 _length = _getArrLength(_ctxProgram, _arrNameB32);
        // sum items and store into the stack
        uint256 total = _sumOfStructVars(_ctxProgram, _arrNameB32, bytes4(_varNameB32), _length);
        OpcodeHelpers.putToStack(_ctxProgram, total);
    }

    /**
     * @dev Inserts items to DSL structures using mixed variable name (ex. `BOB.account`).
     * Struct variable names already contain a name of a DSL structure, `.` dot symbol, the name of
     * variable. `endStruct` word (0xcb398fe1) is used as an indicator for the ending loop for
     * the structs parameters
     * @param _ctxProgram ProgramContext contract address
     */
    function opStruct(address _ctxProgram, address) public {
        // get the first variable name
        bytes32 _varNameB32 = _getParam(_ctxProgram, 4);

        // till found the `endStruct` opcode
        while (bytes4(_varNameB32) != 0xcb398fe1) {
            // get a variable value for current _varNameB32
            bytes32 _value = _getParam(_ctxProgram, 32);
            OpcodeHelpers.mustCall(
                IProgramContext(_ctxProgram).appAddr(),
                abi.encodeWithSignature(
                    'setStorageUint256(bytes32,uint256)',
                    _varNameB32,
                    uint256(_value)
                )
            );
            // get the next variable name in struct
            _varNameB32 = _getParam(_ctxProgram, 4);
        }
    }

    /**
     * @dev Inserts an item to array
     * @param _ctxProgram ProgramContext contract address
     */
    function opPush(address _ctxProgram, address) public {
        bytes32 _varValue = _getParam(_ctxProgram, 32);
        bytes32 _arrNameB32 = _getParam(_ctxProgram, 4);
        // check if the array exists
        bytes memory data = OpcodeHelpers.mustCall(
            IProgramContext(_ctxProgram).appAddr(),
            abi.encodeWithSignature('getType(bytes32)', _arrNameB32)
        );
        require(bytes1(data) != bytes1(0x0), ErrorsGeneralOpcodes.OP4);
        OpcodeHelpers.mustCall(
            IProgramContext(_ctxProgram).appAddr(),
            abi.encodeWithSignature(
                'addItem(bytes32,bytes32)',
                _varValue, // value that pushes to the array
                _arrNameB32 // array name, ex. INDEX_LIST, PARTNERS
            )
        );
    }

    /**
     * @dev Declares an empty array
     * @param _ctxProgram ProgramContext contract address
     */
    function opDeclare(address _ctxProgram, address) public {
        bytes32 _arrType = _getParam(_ctxProgram, 1);
        bytes32 _arrName = _getParam(_ctxProgram, 4);

        OpcodeHelpers.mustCall(
            IProgramContext(_ctxProgram).appAddr(),
            abi.encodeWithSignature(
                'declare(bytes1,bytes32)',
                bytes1(_arrType), // type of the array
                _arrName
            )
        );
    }

    function opLoadLocalUint256(address _ctxProgram, address) public {
        opLoadLocal(_ctxProgram, 'getStorageUint256(bytes32)');
    }

    function opLoadLocalAddress(address _ctxProgram, address) public {
        opLoadLocal(_ctxProgram, 'getStorageAddress(bytes32)');
    }

    function opLoadRemoteUint256(address _ctxProgram, address) public {
        opLoadRemote(_ctxProgram, 'getStorageUint256(bytes32)');
    }

    function opLoadRemoteBytes32(address _ctxProgram, address) public {
        opLoadRemote(_ctxProgram, 'getStorageBytes32(bytes32)');
    }

    function opLoadRemoteBool(address _ctxProgram, address) public {
        opLoadRemote(_ctxProgram, 'getStorageBool(bytes32)');
    }

    function opLoadRemoteAddress(address _ctxProgram, address) public {
        opLoadRemote(_ctxProgram, 'getStorageAddress(bytes32)');
    }

    function opBool(address _ctxProgram, address) public {
        bytes memory data = OpcodeHelpers.nextBytes(_ctxProgram, 1);
        OpcodeHelpers.putToStack(_ctxProgram, uint256(uint8(data[0])));
    }

    function opUint256(address _ctxProgram, address) public {
        OpcodeHelpers.putToStack(_ctxProgram, opUint256Get(_ctxProgram, address(0)));
    }

    function opSendEth(address _ctxProgram, address) public {
        address payable recipient = payable(_getAddress(_ctxProgram));
        uint256 amount = opUint256Get(_ctxProgram, address(0));
        recipient.transfer(amount);
        OpcodeHelpers.putToStack(_ctxProgram, 1);
    }

    /****************
     * ERC20 Tokens *
     ***************/

    /**
     * @dev Calls IER20 transfer() function and puts to stack `1`
     * @param _ctxProgram ProgramContext contract address
     */
    function opTransfer(address _ctxProgram, address) public {
        address payable token = payable(_getAddress(_ctxProgram));
        address payable recipient = payable(_getAddress(_ctxProgram));
        uint256 amount = opUint256Get(_ctxProgram, address(0));
        IERC20(token).transfer(recipient, amount);
        OpcodeHelpers.putToStack(_ctxProgram, 1);
    }

    function opTransferVar(address _ctxProgram, address) public {
        address payable token = payable(_getAddress(_ctxProgram));
        address payable recipient = payable(_getAddress(_ctxProgram));
        uint256 amount = uint256(opLoadLocalGet(_ctxProgram, 'getStorageUint256(bytes32)'));
        IERC20(token).transfer(recipient, amount);
        OpcodeHelpers.putToStack(_ctxProgram, 1);
    }

    function opTransferFrom(address _ctxProgram, address) public {
        address payable token = payable(_getAddress(_ctxProgram));
        address payable from = payable(_getAddress(_ctxProgram));
        address payable to = payable(_getAddress(_ctxProgram));
        uint256 amount = opUint256Get(_ctxProgram, address(0));
        IERC20(token).transferFrom(from, to, amount);
        OpcodeHelpers.putToStack(_ctxProgram, 1);
    }

    function opTransferFromVar(address _ctxProgram, address) public {
        address payable token = payable(_getAddress(_ctxProgram));
        address payable from = payable(_getAddress(_ctxProgram));
        address payable to = payable(_getAddress(_ctxProgram));
        uint256 amount = uint256(opLoadLocalGet(_ctxProgram, 'getStorageUint256(bytes32)'));

        IERC20(token).transferFrom(from, to, amount);
        OpcodeHelpers.putToStack(_ctxProgram, 1);
    }

    function opBalanceOf(address _ctxProgram, address) public {
        address payable token = payable(_getAddress(_ctxProgram));
        address payable user = payable(_getAddress(_ctxProgram));
        OpcodeHelpers.putToStack(_ctxProgram, IERC20(token).balanceOf(user));
    }

    function opAllowance(address _ctxProgram, address) public {
        address payable token = payable(_getAddress(_ctxProgram));
        address payable owner = payable(_getAddress(_ctxProgram));
        address payable spender = payable(_getAddress(_ctxProgram));
        uint256 allowance = IERC20(token).allowance(owner, spender);
        OpcodeHelpers.putToStack(_ctxProgram, allowance);
    }

    function opMint(address _ctxProgram, address) public {
        address payable token = payable(_getAddress(_ctxProgram));
        address payable to = payable(_getAddress(_ctxProgram));
        uint256 amount = uint256(opLoadLocalGet(_ctxProgram, 'getStorageUint256(bytes32)'));
        IERC20Mintable(token).mint(to, amount);
        OpcodeHelpers.putToStack(_ctxProgram, 1);
    }

    function opBurn(address _ctxProgram, address) public {
        address payable token = payable(_getAddress(_ctxProgram));
        address payable to = payable(_getAddress(_ctxProgram));
        uint256 amount = uint256(opLoadLocalGet(_ctxProgram, 'getStorageUint256(bytes32)'));
        IERC20Mintable(token).burn(to, amount);
        OpcodeHelpers.putToStack(_ctxProgram, 1);
    }

    /********************
     * end ERC20 Tokens *
     *******************/

    function opLengthOf(address _ctxProgram, address) public {
        uint256 _length = uint256(opLoadLocalGet(_ctxProgram, 'getLength(bytes32)'));
        OpcodeHelpers.putToStack(_ctxProgram, _length);
    }

    function opUint256Get(address _ctxProgram, address) public returns (uint256) {
        return uint256(_getParam(_ctxProgram, 32));
    }

    function opLoadLocalGet(
        address _ctxProgram,
        string memory funcSignature
    ) public returns (bytes32 result) {
        bytes32 MSG_SENDER = 0x9ddd6a8100000000000000000000000000000000000000000000000000000000;
        bytes memory data;
        bytes32 varNameB32 = _getParam(_ctxProgram, 4);
        if (varNameB32 == MSG_SENDER) {
            data = abi.encode(IProgramContext(_ctxProgram).msgSender());
        } else {
            // Load local variable by it's hex
            data = OpcodeHelpers.mustCall(
                IProgramContext(_ctxProgram).appAddr(),
                abi.encodeWithSignature(funcSignature, varNameB32)
            );
        }

        result = bytes32(data);
    }

    function opAddressGet(address _ctxProgram, address) public returns (address) {
        bytes32 contractAddrB32 = _getParam(_ctxProgram, 20);
        /**
         * Shift bytes to the left so that
         * 0xe7f1725e7734ce288f8367e1bb143e90bb3f0512000000000000000000000000
         * transforms into
         * 0x000000000000000000000000e7f1725e7734ce288f8367e1bb143e90bb3f0512
         * This is needed to later conversion from bytes32 to address
         */
        contractAddrB32 >>= 96;

        return address(uint160(uint256(contractAddrB32)));
    }

    function opLoadLocal(address _ctxProgram, string memory funcSignature) public {
        bytes32 result = opLoadLocalGet(_ctxProgram, funcSignature);

        OpcodeHelpers.putToStack(_ctxProgram, uint256(result));
    }

    function opLoadRemote(address _ctxProgram, string memory funcSignature) public {
        bytes32 varNameB32 = _getParam(_ctxProgram, 4);
        bytes32 contractAddrB32 = _getParam(_ctxProgram, 20);

        /**
         * Shift bytes to the left so that
         * 0xe7f1725e7734ce288f8367e1bb143e90bb3f0512000000000000000000000000
         * transforms into
         * 0x000000000000000000000000e7f1725e7734ce288f8367e1bb143e90bb3f0512
         * This is needed to later conversion from bytes32 to address
         */
        contractAddrB32 >>= 96;

        address contractAddr = address(uint160(uint256(contractAddrB32)));

        // Load local value by it's hex
        bytes memory data = OpcodeHelpers.mustCall(
            contractAddr,
            abi.encodeWithSignature(funcSignature, varNameB32)
        );

        OpcodeHelpers.putToStack(_ctxProgram, uint256(bytes32(data)));
    }

    function opCompoundDeposit(address _ctxProgram) public {
        address payable token = payable(_getAddress(_ctxProgram));
        bytes memory data = OpcodeHelpers.mustCall(
            IProgramContext(_ctxProgram).appAddr(),
            abi.encodeWithSignature('compounds(address)', token)
        );
        address cToken = address(uint160(uint256(bytes32(data))));
        uint256 balance = IcToken(token).balanceOf(address(this));
        // approve simple token to use it into the market
        IERC20(token).approve(cToken, balance);
        // supply assets into the market and receives cTokens in exchange
        IcToken(cToken).mint(balance);

        OpcodeHelpers.putToStack(_ctxProgram, 1);
    }

    function opCompoundWithdraw(address _ctxProgram) public {
        address payable token = payable(_getAddress(_ctxProgram));
        // `token` can be used in the future for more different underluing tokens
        bytes memory data = OpcodeHelpers.mustCall(
            IProgramContext(_ctxProgram).appAddr(),
            abi.encodeWithSignature('compounds(address)', token)
        );
        address cToken = address(uint160(uint256(bytes32(data))));

        // redeems cTokens in exchange for the underlying asset (USDC)
        // amount - amount of cTokens
        IcToken(cToken).redeem(IcToken(cToken).balanceOf(address(this)));

        OpcodeHelpers.putToStack(_ctxProgram, 1);
    }

    function opEnableRecord(address _ctxProgram, address) public {
        uint256 recordId = uint256(opLoadLocalGet(_ctxProgram, 'getStorageUint256(bytes32)'));
        address payable contractAddr = payable(_getAddress(_ctxProgram));

        OpcodeHelpers.mustCall(
            contractAddr,
            abi.encodeWithSignature('activateRecord(uint256)', recordId)
        );
        OpcodeHelpers.putToStack(_ctxProgram, 1);
    }

    /**
     * @dev Reads a variable of type `address`
     * @param _ctxProgram ProgramContext contract address
     * @return result The address value
     */
    function _getAddress(address _ctxProgram) internal returns (address result) {
        result = address(
            uint160(uint256(opLoadLocalGet(_ctxProgram, 'getStorageAddress(bytes32)')))
        );
    }

    /**
     * @dev Sums struct variables values from the `struct type` array
     * @param _ctxProgram ProgramContext contract address
     * @param _arrNameB32 Array's name in bytecode
     * @param _varName Struct's name in bytecode
     * @param _length Array's length in bytecode
     * @return total Total sum of each element in the `struct` type of array
     */
    function _sumOfStructVars(
        address _ctxProgram,
        bytes32 _arrNameB32,
        bytes4 _varName,
        bytes32 _length
    ) internal returns (uint256 total) {
        for (uint256 i = 0; i < uint256(_length); i++) {
            // get the name of a struct
            bytes memory item = _getItem(_ctxProgram, i, _arrNameB32);

            // get struct variable value
            bytes4 _fullName = IProgramContext(_ctxProgram).structParams(bytes4(item), _varName);
            (item) = OpcodeHelpers.mustCall(
                IProgramContext(_ctxProgram).appAddr(),
                abi.encodeWithSignature('getStorageUint256(bytes32)', bytes32(_fullName))
            );
            total += uint256(bytes32(item));
        }
    }

    /**
     * @dev Returns the element from the array
     * @param _ctxProgram ProgramContext contract address
     * @param _index Array's index
     * @param _arrNameB32 Array's name in bytecode
     * @return item Item from the array by its index
     */
    function _getItem(
        address _ctxProgram,
        uint256 _index,
        bytes32 _arrNameB32
    ) internal returns (bytes memory item) {
        item = OpcodeHelpers.mustCall(
            IProgramContext(_ctxProgram).appAddr(),
            abi.encodeWithSignature('get(uint256,bytes32)', _index, _arrNameB32)
        );
    }

    /**
     * @dev Sums uin256 elements from the array (array name should be provided)
     * @param _ctxProgram ProgramContext contract address
     * @param _arrNameB32 Array's name in bytecode
     * @param _length Array's length in bytecode
     * @return total Total sum of each element in the `uint256` type of array
     */
    function _sumOfVars(
        address _ctxProgram,
        bytes32 _arrNameB32,
        bytes32 _length
    ) internal returns (uint256 total) {
        for (uint256 i = 0; i < uint256(_length); i++) {
            bytes memory item = _getItem(_ctxProgram, i, _arrNameB32);
            total += uint256(bytes32(item));
        }
    }

    /**
     * @dev Checks the type for array
     * @param _ctxDSL DSLContext contract address
     * @param _ctxProgram ProgramContext contract address
     * @param _arrNameB32 Array's name in bytecode
     * @param _typeName Type of the array, ex. `uint256`, `address`, `struct`
     */
    function _checkArrType(
        address _ctxDSL,
        address _ctxProgram,
        bytes32 _arrNameB32,
        string memory _typeName
    ) internal {
        bytes memory _type;
        // check if the array exists
        (_type) = OpcodeHelpers.mustCall(
            IProgramContext(_ctxProgram).appAddr(),
            abi.encodeWithSignature('getType(bytes32)', _arrNameB32)
        );
        require(
            bytes1(_type) == IDSLContext(_ctxDSL).branchCodes('declareArr', _typeName),
            ErrorsGeneralOpcodes.OP8
        );
    }

    /**
     * @dev Returns array's length
     * @param _ctxProgram ProgramContext contract address
     * @param _arrNameB32 Array's name in bytecode
     * @return Array's length in bytecode
     */
    function _getArrLength(address _ctxProgram, bytes32 _arrNameB32) internal returns (bytes32) {
        bytes memory data = OpcodeHelpers.mustCall(
            IProgramContext(_ctxProgram).appAddr(),
            abi.encodeWithSignature('getLength(bytes32)', _arrNameB32)
        );
        return bytes32(data);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IDSLContext } from '../../interfaces/IDSLContext.sol';
import { IProgramContext } from '../../interfaces/IProgramContext.sol';
import { IERC20 } from '../../interfaces/IERC20.sol';
import { ILinkedList } from '../../interfaces/ILinkedList.sol';
import { IStorageUniversal } from '../../interfaces/IStorageUniversal.sol';
import { StringUtils } from '../StringUtils.sol';
import { UnstructuredStorage } from '../UnstructuredStorage.sol';
import { OpcodeHelpers } from './OpcodeHelpers.sol';
import { ErrorsBranchingOpcodes } from '../Errors.sol';

// import 'hardhat/console.sol';

/**
 * @title Logical operator opcodes
 * @notice Opcodes for logical operators such as if/esle, switch/case
 */
library BranchingOpcodes {
    using UnstructuredStorage for bytes32;
    using StringUtils for string;

    function opIfelse(address _ctxProgram, address) public {
        if (IProgramContext(_ctxProgram).stack().length() == 0) {
            OpcodeHelpers.putToStack(_ctxProgram, 0); // for if-else condition to work all the time
        }

        uint256 last = IProgramContext(_ctxProgram).stack().pop();
        uint16 _posTrueBranch = getUint16(_ctxProgram);
        uint16 _posFalseBranch = getUint16(_ctxProgram);

        IProgramContext(_ctxProgram).setNextPc(IProgramContext(_ctxProgram).pc());
        IProgramContext(_ctxProgram).setPc(last > 0 ? _posTrueBranch : _posFalseBranch);
    }

    function opIf(address _ctxProgram, address) public {
        if (IProgramContext(_ctxProgram).stack().length() == 0) {
            OpcodeHelpers.putToStack(_ctxProgram, 0); // for if condition to work all the time
        }

        uint256 last = IProgramContext(_ctxProgram).stack().pop();
        uint16 _posTrueBranch = getUint16(_ctxProgram);

        if (last != 0) {
            IProgramContext(_ctxProgram).setNextPc(IProgramContext(_ctxProgram).pc());
            IProgramContext(_ctxProgram).setPc(_posTrueBranch);
        } else {
            IProgramContext(_ctxProgram).setNextPc(IProgramContext(_ctxProgram).program().length);
        }
    }

    function opFunc(address _ctxProgram, address) public {
        if (IProgramContext(_ctxProgram).stack().length() == 0) {
            OpcodeHelpers.putToStack(_ctxProgram, 0);
        }

        uint16 _reference = getUint16(_ctxProgram);

        IProgramContext(_ctxProgram).setNextPc(IProgramContext(_ctxProgram).pc());
        IProgramContext(_ctxProgram).setPc(_reference);
    }

    /**
     * @dev For loop setup. Responsible for checking iterating array existence, set the number of iterations
     * @param _ctxProgram Context contract address
     */
    function opForLoop(address _ctxProgram, address) external {
        IProgramContext(_ctxProgram).incPc(4); // skip loop's temporary variable name. It will be used later in opStartLoop
        bytes32 _arrNameB32 = OpcodeHelpers.getNextBytes(_ctxProgram, 4);

        // check if the array exists
        bytes memory data1 = OpcodeHelpers.mustCall(
            IProgramContext(_ctxProgram).appAddr(),
            abi.encodeWithSignature('getType(bytes32)', _arrNameB32)
        );
        require(bytes1(data1) != bytes1(0x0), ErrorsBranchingOpcodes.BR2);

        // Set loop
        uint256 _arrLen = ILinkedList(IProgramContext(_ctxProgram).appAddr()).getLength(
            _arrNameB32
        );
        IProgramContext(_ctxProgram).setForLoopIterationsRemaining(_arrLen);
    }

    /**
     * @dev Does the real iterating process over the body of the for-loop
     * @param _ctxDSL DSL Context contract address
     * @param _ctxProgram ProgramContext contract address
     */
    function opStartLoop(address _ctxProgram, address _ctxDSL) public {
        // Decrease by 1 the for-loop iterations couter as PC actually points onto the next block of code already
        uint256 _currCtr = IProgramContext(_ctxProgram).forLoopIterationsRemaining();
        uint256 _currPc = IProgramContext(_ctxProgram).pc() - 1;

        // Set the next program counter to the beginning of the loop block
        if (_currCtr > 1) {
            IProgramContext(_ctxProgram).setNextPc(_currPc);
        }

        // Get element from array by index
        bytes32 _arrName = OpcodeHelpers.readBytesSlice(_ctxProgram, _currPc - 4, _currPc);
        uint256 _arrLen = ILinkedList(IProgramContext(_ctxProgram).appAddr()).getLength(_arrName);
        uint256 _index = _arrLen - IProgramContext(_ctxProgram).forLoopIterationsRemaining();
        bytes1 _arrType = ILinkedList(IProgramContext(_ctxProgram).appAddr()).getType(_arrName);
        bytes32 _elem = ILinkedList(IProgramContext(_ctxProgram).appAddr()).get(_index, _arrName);

        // Set the temporary variable value: TMP_VAR = ARR_NAME[i]
        bytes32 _tempVarNameB32 = OpcodeHelpers.readBytesSlice(
            _ctxProgram,
            _currPc - 8,
            _currPc - 4
        );
        bytes4 setFuncSelector = IDSLContext(_ctxDSL).branchSelectors('declareArr', _arrType);
        OpcodeHelpers.mustDelegateCall(
            IProgramContext(_ctxProgram).appAddr(),
            abi.encodeWithSelector(setFuncSelector, _tempVarNameB32, _elem)
        );

        // Reduce the number of iterations remaining
        IProgramContext(_ctxProgram).setForLoopIterationsRemaining(_currCtr - 1);
    }

    /**
     * @dev This function is responsible for getting of the body of the for-loop
     * @param _ctxProgram Context contract address
     */
    function opEndLoop(address _ctxProgram, address) public {
        uint256 _currPc = IProgramContext(_ctxProgram).pc();
        IProgramContext(_ctxProgram).setPc(IProgramContext(_ctxProgram).nextpc());
        IProgramContext(_ctxProgram).setNextPc(_currPc); // sets next PC to the code after this `end` opcode
    }

    function opEnd(address _ctxProgram, address) public {
        IProgramContext(_ctxProgram).setPc(IProgramContext(_ctxProgram).nextpc());
        IProgramContext(_ctxProgram).setNextPc(IProgramContext(_ctxProgram).program().length);
    }

    function getUint16(address _ctxProgram) public returns (uint16) {
        bytes memory data = OpcodeHelpers.nextBytes(_ctxProgram, 2);

        // Convert bytes to bytes8
        bytes2 result;
        assembly {
            result := mload(add(data, 0x20))
        }

        return uint16(result);
    }
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

interface IPreprocessor {
    function transform(
        address _ctxAddr,
        string memory _program
    ) external view returns (string[] memory);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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

import { IDSLContext } from '../../interfaces/IDSLContext.sol';
import { IProgramContext } from '../../interfaces/IProgramContext.sol';
import { StringUtils } from '../StringUtils.sol';
import { UnstructuredStorage } from '../UnstructuredStorage.sol';
import { ErrorsOpcodeHelpers } from '../Errors.sol';

// import 'hardhat/console.sol';

/**
 * @title Opcode helper functions
 * @notice Opcode helper functions that are used in other opcode libraries
 * @dev Opcode libraries are: ComparisonOpcodes, BranchingOpcodes, LogicalOpcodes, and OtherOpcodes
 */
library OpcodeHelpers {
    using UnstructuredStorage for bytes32;
    using StringUtils for string;

    // TODO: get rid of putToStack function
    function putToStack(address _ctxProgram, uint256 _value) public {
        IProgramContext(_ctxProgram).stack().push(_value);
    }

    function nextBytes(address _ctxProgram, uint256 size) public returns (bytes memory out) {
        out = IProgramContext(_ctxProgram).programAt(IProgramContext(_ctxProgram).pc(), size);
        IProgramContext(_ctxProgram).incPc(size);
    }

    function nextBytes1(address _ctxProgram) public returns (bytes1) {
        return nextBytes(_ctxProgram, 1)[0];
    }

    /**
     * @dev Reads the slice of bytes from the raw program
     * @dev Warning! The maximum slice size can only be 32 bytes!
     * @param _ctxProgram Context contract address
     * @param _start Start position to read
     * @param _end End position to read
     * @return res Bytes32 slice of the raw program
     */
    function readBytesSlice(
        address _ctxProgram,
        uint256 _start,
        uint256 _end
    ) public view returns (bytes32 res) {
        bytes memory slice = IProgramContext(_ctxProgram).programAt(_start, _end - _start);
        // Convert bytes to bytes32
        assembly {
            res := mload(add(slice, 0x20))
        }
    }

    function nextBranchSelector(
        address _ctxDSL,
        address _ctxProgram,
        string memory baseOpName
    ) public returns (bytes4) {
        bytes1 branchCode = nextBytes1(_ctxProgram);
        return IDSLContext(_ctxDSL).branchSelectors(baseOpName, branchCode);
    }

    /**
     * @dev Check .call() function and returns data
     * @param addr Context contract address
     * @param data Abi fubction with params
     * @return callData returns data from call
     */
    function mustCall(address addr, bytes memory data) public returns (bytes memory) {
        (bool success, bytes memory callData) = addr.call(data);
        require(success, ErrorsOpcodeHelpers.OPH1);
        return callData;
    }

    /**
     * @dev Check .delegatecall() function and returns data
     * @param addr Context contract address
     * @param data Abi fubction with params
     * @return delegateCallData returns data from call
     */
    function mustDelegateCall(address addr, bytes memory data) public returns (bytes memory) {
        (bool success, bytes memory delegateCallData) = addr.delegatecall(data);
        require(success, ErrorsOpcodeHelpers.OPH2);
        return delegateCallData;
    }

    function getNextBytes(
        address _ctxProgram,
        uint256 _bytesNum
    ) public returns (bytes32 varNameB32) {
        bytes memory varName = nextBytes(_ctxProgram, _bytesNum);

        // Convert bytes to bytes32
        assembly {
            varNameB32 := mload(add(varName, 0x20))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the cToken that defined as asset in https://v2-app.compound.finance/
 */
interface IcToken {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function exchangeRateStored() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint256 mintAmount) external returns (uint);

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint256 redeemTokens) external returns (uint);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (uint256.max means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILinkedList {
    function getType(bytes32 _arrName) external view returns (bytes1);

    function getLength(bytes32 _arrName) external view returns (uint256);

    function get(uint256 _index, bytes32 _arrName) external view returns (bytes32 data);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ErrorsAgreement } from '../dsl/libs/Errors.sol';
import { UnstructuredStorage } from '../dsl/libs/UnstructuredStorage.sol';
import { StringUtils } from '../dsl/libs/StringUtils.sol';

// import 'hardhat/console.sol';

/**
 * AgreementStorage used to manage all variables
 */
contract AgreementStorage {
    using UnstructuredStorage for bytes32;
    using StringUtils for string;

    // struct Variable {
    //     bytes32 varHex; // Name of variable in type of bytes32
    //     address varCreator; // address of owner
    //     string varName; // Name of variable
    //     ValueTypes valueType; // Type of variable
    // }

    // Variable[] public variableInfo; // Info of each variable.
    // mapping(bytes32 => uint256) idByPosition; // position => id of variableInfo object

    // enum ValueTypes {
    //     ADDRESS,
    //     UINT256,
    //     BYTES32,
    //     BOOL
    // }

    modifier isReserved(bytes32 position) {
        // modifier isReserved(string memory varName) {
        // bytes32 position = bytes4(keccak256(abi.encodePacked(varName)));
        bytes32 MSG_SENDER_4_BYTES_HEX = 0x9ddd6a8100000000000000000000000000000000000000000000000000000000;
        bytes32 ETH_4_BYTES_HEX = 0xaaaebeba00000000000000000000000000000000000000000000000000000000;
        bytes32 GWEI_4_BYTES_HEX = 0x0c93a5d800000000000000000000000000000000000000000000000000000000;
        require(position != MSG_SENDER_4_BYTES_HEX, ErrorsAgreement.AGR8); // check that variable is not 'MSG_SENDER'
        require(position != ETH_4_BYTES_HEX, ErrorsAgreement.AGR8); // check that variable name is not 'ETH'
        require(position != GWEI_4_BYTES_HEX, ErrorsAgreement.AGR8); // check that variable name is not 'GWEI'
        _;
    }

    // modifier doesVariableExist(string memory varName, ValueTypes valueType) {
    //     for (uint256 i = 0; i < variableInfo.length; i++) {
    //         // check that value already exist
    //         if (StringUtils.equal(varName, variableInfo[i].varName)) {
    //             // check that msg.sender can rewrite variable
    //             require(
    //                 msg.sender == variableInfo[i].varCreator && valueType == variableInfo[i].valueType,
    //                 ErrorsAgreement.AGR8
    //             );
    //         }
    //     }
    //     _;
    // }

    function getStorageBool(bytes32 position) external view returns (bool data) {
        return position.getStorageBool();
    }

    function getStorageAddress(bytes32 position) external view returns (address data) {
        return position.getStorageAddress();
    }

    function getStorageUint256(bytes32 position) external view returns (uint256 data) {
        return position.getStorageUint256();
    }

    function setStorageUint256(bytes32 position, uint256 data) public isReserved(position) {
        position.setStorageUint256(data);
    }

    function setStorageBytes32(bytes32 position, bytes32 data) public isReserved(position) {
        position.setStorageBytes32(data);
    }

    function setStorageAddress(bytes32 position, address data) public isReserved(position) {
        position.setStorageAddress(data);
    }

    function setStorageBool(bytes32 position, bool data) public isReserved(position) {
        position.setStorageBool(data);
    }

    // TODO: enable `doesVariableExist` check
    // function setStorageBool(
    //     string memory varName,
    //     bool data
    // ) external isReserved(varName) doesVariableExist(varName, ValueTypes.BOOL) {
    //     bytes32 position = _addNewVariable(varName, ValueTypes.BOOL);
    //     position.setStorageBool(data);
    // }

    // function setStorageAddress(
    //     string memory varName,
    //     address data
    // ) external isReserved(varName) doesVariableExist(varName, ValueTypes.ADDRESS) {
    //     bytes32 position = _addNewVariable(varName, ValueTypes.ADDRESS);
    //     position.setStorageAddress(data);
    // }

    // function setStorageUint256(
    //     string memory varName,
    //     uint256 data
    // ) external isReserved(varName) doesVariableExist(varName, ValueTypes.UINT256) {
    //     bytes32 position = _addNewVariable(varName, ValueTypes.UINT256);
    //     position.setStorageUint256(data);
    // }

    // // TODO: do we need both type of fubnctions simple and by positions?
    // function setStorageBoolByPosition(bytes32 position, bool data) public {
    //     position.setStorageBool(data);
    // }
    // // TODO: do we need both type of fubnctions simple and by positions?
    // function setStorageUint256ByPosition(bytes32 position, uint256 data) public {
    //     position.setStorageUint256(data);
    // }

    // /**
    //  * @dev Created and save new Variable of seted Value
    //  * @param _varName seted value name in type of string
    //  * @param _valueType seted value type number
    //  * @return position is a _varName in type of bytes32
    //  */
    // function _addNewVariable(
    //     string memory _varName,
    //     ValueTypes _valueType
    // ) internal returns (bytes32 position) {
    //     position = bytes4(keccak256(abi.encodePacked(_varName)));
    //     idByPosition[position] = variableInfo.length;
    //     variableInfo.push(Variable(position, msg.sender, _varName, _valueType));
    // }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAgreement {
    event Parsed(address indexed preProccessor, string code);

    event RecordArchived(uint256 indexed recordId);
    event RecordUnarchived(uint256 indexed recordId);
    event RecordActivated(uint256 indexed recordId);
    event RecordDeactivated(uint256 indexed recordId);

    event RecordExecuted(
        address indexed signatory,
        uint256 indexed recordId,
        uint256 providedAmount,
        string record
    );

    event NewRecord(
        uint256 recordId,
        uint256[] requiredRecords, // required transactions that have to be executed
        address[] signatories, // addresses that can execute the transaction
        string record, // DSL code string ex. `uint256 5 > uint256 3`
        //  DSL code strings that have to be executed successfully before the `transaction DSL code`
        string[] conditionStrings
    );

    /*
        all mappings were moved to the Record struct as it uses less gas during contract deloyment
    */
    struct Record {
        bool isExecuted;
        bool isArchived;
        bool isActive;
        uint256[] requiredRecords;
        address[] signatories;
        string recordString;
        string[] conditionStrings;
        bytes recordProgram;
        bytes[] conditions; // condition program in bytes
        mapping(address => bool) isExecutedBySignatory;
        mapping(string => bool) isConditionSet;
        mapping(string => bool) isRecordSet;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ILinkedList } from '../interfaces/ILinkedList.sol';

// import 'hardhat/console.sol';

/**
 * TODO:
 * add the possibility to work with arrays on the DSL level
 * variable ARR_NAME -> [type: array,elementType: uint256, linkToNextEl: 0x123]
 * (next element): [data: 0x0001, linkToNextEl: 0x124]
 * (last element): [data: 0x0005, linkToNextEl: 0x000]
 */
contract LinkedList is ILinkedList {
    /* Important!
    As the contract is working directly with storage pointers, so
    there is must not be any additional variables exept mappings.
    In this case the contract uses `type(uint256).max` as parameter that means the
    end of the array.

    TODO: before using next pointer from _getEmptyMemoryPosition for inserting
    `item` to array it needs to check conflicts with mappings hashes
    example of getting output mapping value:
    num, slot are some uin256 values in mapping

        assembly {
            // Store num in memory scratch space
            mstore(0, num)
            // Store slot number in scratch space after num
            mstore(32, slot)
            // Create hash from previously stored num and slot
            let hash := keccak256(0, 64)
            // Load mapping value using the just calculated hash
            result := sload(hash)
        }
    */

    // TODO: move all variables to Context
    bytes32 public constant EMPTY = bytes32(type(uint256).max);

    // arr name => head to array (positions to the first element in arrays)
    mapping(bytes32 => bytes32) private heads;
    mapping(bytes32 => bytes1) private types; // arr name => type to array
    mapping(bytes32 => uint256) private lengths; // arr name => length of array

    /**
     * @dev Returns length of the array
     * @param _arrName is a bytecode of the array name
     */
    function getType(bytes32 _arrName) external view returns (bytes1) {
        return types[_arrName];
    }

    /**
     * @dev Returns length of the array
     * @param _arrName is a bytecode of the array name
     */
    function getLength(bytes32 _arrName) external view returns (uint256) {
        return lengths[_arrName];
    }

    /**
     * @dev Returns the item data from the array by its index
     * @param _index is an index of the item in the array that starts from 0
     * @param _arrName is a bytecode of the array name
     * @return data is a bytecode of the item from the array or empty bytes if no item exists by this index
     */
    function get(uint256 _index, bytes32 _arrName) public view returns (bytes32 data) {
        uint256 count;
        bytes32 currentPosition = heads[_arrName];

        while (count++ < _index) {
            (, currentPosition) = _getData(currentPosition);
        }
        (data, ) = _getData(currentPosition);
    }

    /**
     * @dev Declares the new array in dependence of its type
     * @param _type is a bytecode type of the array. Bytecode of each type can be find in Context contract
     * @param _arrName is a bytecode of the array name
     */
    function declare(bytes1 _type, bytes32 _arrName) external {
        types[_arrName] = _type;
        heads[_arrName] = EMPTY;
    }

    /**
     * @dev Pushed item to the end of the array. Increases the length of the array
     * @param _item is a bytecode type of the array. Bytecode of each type can be find in Context contract
     * @param _arrName is a bytecode of the array name
     */
    function addItem(bytes32 _item, bytes32 _arrName) external {
        bytes32 previousPosition;
        bytes32 nodePtr = _getEmptyMemoryPosition();

        if (heads[_arrName] == EMPTY) {
            // creates the first position in array for the first item
            heads[_arrName] = nodePtr;
            _insertItem(nodePtr, _item);
        } else {
            // add the new data to existing _position in the array
            bytes32 currentPosition = getHead(_arrName);

            while (currentPosition != EMPTY) {
                previousPosition = currentPosition;
                (, currentPosition) = _getData(currentPosition);
            }

            _insertItem(nodePtr, _item);
            // In previous stored item in the array it creates new position(link) to the new item
            _updateLinkToNextItem(previousPosition, nodePtr);
        }
        lengths[_arrName]++;
    }

    /**
     * @dev Returns the head position of the array:
     * - `bytes32(0x0)` value if array has not declared yet,
     * - `bytes32(type(uint256).max` if array was just declared but it is empty
     * - `other bytecode` with a position of the first element of the array
     * @param _arrName is a bytecode of the array name
     */
    function getHead(bytes32 _arrName) public view returns (bytes32) {
        return heads[_arrName];
    }

    /**
     * @dev Insert item in the array by provided position. Updates new storage pointer
     * for the future inserting
     */
    function _insertItem(bytes32 _position, bytes32 _item) internal {
        /*
            TODO:
            - fix empty space between items as additional 0x20
            - check why padding is used in doc for mstore
        */
        uint256 maxUint256 = type(uint256).max;

        assembly {
            sstore(_position, _item) // save _item
            sstore(add(_position, 0x20), maxUint256) // nextPosition
            sstore(0x40, add(_position, 0x60)) // new "storage end"
            // 0x40 = free storage pointer + ((62 + 32) + 31) + 4294967264)
            // sstore(0x40, add(_position, and(add(add(0x40, 0x20), 0x1f), not(0x1f))))
        }
    }

    /**
     * @dev Updates the next position for the provided(current) position
     */
    function _updateLinkToNextItem(bytes32 _position, bytes32 _nextPosition) internal {
        assembly {
            sstore(add(_position, 0x20), _nextPosition)
        }
    }

    /**
     * @dev Uses 0x40 position as free storage pointer that returns value of current free position.
     * In this contract it 0x40 position value updates by _insertItem function anfter
     * adding new item in the array. See: mload - free memory pointer in the doc
     * @return position is a value that stores in the 0x40 position in the storage
     */
    function _getEmptyMemoryPosition() internal view returns (bytes32 position) {
        assembly {
            position := sload(0x40) // free storage pointer, mload - free memory pointer
            // TODO: make it dynamically as  _position := msize() but in the storage.
            // kinda get the highest available block of memory
        }
    }

    /**
     * @dev Returns the value of current position and the position(nextPosition)
     * to the next object in array
     * @param _position is a current item position in the array
     * @return data is a current data stored in the _position
     * @return nextPosition is a next position to the next item in the array
     */
    function _getData(
        bytes32 _position
    ) internal view returns (bytes32 data, bytes32 nextPosition) {
        assembly {
            data := sload(_position)
            nextPosition := sload(add(_position, 0x20)) // 0x20 is the size from data
        }
        return (data, nextPosition);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC20 } from '../interfaces/IERC20.sol';

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, 'ERC20: transfer amount exceeds allowance');
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, 'ERC20: decreased allowance below zero');
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, 'ERC20: transfer amount exceeds balance');
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), 'ERC20: mint to the zero address');

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), 'ERC20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    // solhint-disable no-empty-blocks
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    // solhint-enable no-empty-blocks
}