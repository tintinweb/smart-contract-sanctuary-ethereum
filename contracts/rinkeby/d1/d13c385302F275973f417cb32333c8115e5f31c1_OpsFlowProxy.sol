// SPDX-License-Identifier: GPL-2.0-or-later
// Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../../interfaces/IEvaFlowProxy.sol";
import "./OpsFlow.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

contract OpsFlowProxy is IEvaFlowProxy, OpsFlow {
    constructor(address _config, address _evaSafesFactory) OpsFlow(_config, _evaSafesFactory) {} //solhint-disable
    bytes32 private constant _SUB_FLOW_INTERFACE = keccak256("getSubCalls");


    function create(
        IEvaFlowController ser,
        IOpsFlow opsFlow,
        KeepNetWork network,
        uint256 gasFee,
        string memory name,
        Task memory task
    ) external payable {
        require(bytes(name).length > 0, "invalid name");
        require(gasFee == msg.value, "invalid gasFee");
        uint256 flowSize = ser.getFlowMetaSize();
        bytes memory taskId = opsFlow.createTask(task, flowSize);
        uint256 afterFlowId = ser.registerFlow{value: gasFee}(name, network, address(opsFlow), taskId);
        require(flowSize == afterFlowId, "flowId must be equal");
    }

    function closeFlow(IEvaFlowController ser, uint256 flowId) external override {
        ser.closeFlow(flowId);
        IOpsFlow exchange = _getOpsFlow(ser, flowId);
        exchange.cancelTask(flowId);
    }

    function _getOpsFlow(IEvaFlowController ser, uint256 flowId) internal view returns (IOpsFlow opsFlow) {
        (address flow, ) = ser.getFlowCheckInfo(flowId);
        require(flow != address(0), "empty");
        opsFlow = IOpsFlow(flow);
    }

    function enableERC1820() external {
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24).setInterfaceImplementer(
            address(this),
            _SUB_FLOW_INTERFACE,
            address(this)
        );


    }
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

import "./IEvaFlowController.sol";

interface IEvaFlowProxy {
    function closeFlow(IEvaFlowController ctr, uint256 flowId) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../../interfaces/IEvaSubFlow.sol";
import "../../interfaces/EIP712.sol";
import "../../lib/Utils.sol";
import "../../interfaces/IOpsFlow.sol";
import {IEvabaseConfig} from "../../interfaces/IEvabaseConfig.sol";
import {IEvaFlowController} from "../../interfaces/IEvaFlowController.sol";
import {IEvaSafesFactory} from "../../interfaces/IEvaSafesFactory.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OpsFlow is IEvaSubFlow, IOpsFlow, Ownable {
    using Address for address;

    mapping(uint256 => Task) private _tasks;
    IEvaSafesFactory public evaSafesFactory;
    IEvabaseConfig public config;
    uint32 private constant _MIN_INTERAL = 1 seconds;

    constructor(address _config, address _evaSafesFactory) {
        require(_evaSafesFactory != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        config = IEvabaseConfig(_config);
        evaSafesFactory = IEvaSafesFactory(_evaSafesFactory);
    }

    function check(bytes memory taskIdData) external view override returns (bool, bytes memory) {
        uint256 key = abi.decode(taskIdData, (uint256));

        if (!isActiveTask(key) || taskExpired(key)) {
            return (false, bytes(""));
        }

        return (true, taskIdData);
    }

    function multicall(address target, bytes memory callData) external override onlyOwner {
        require(target != address(this), "FORBIDDEN");
        require(target != owner(), "FORBIDDEN");
        target.functionCall(callData, "ops multicall CallFailed");
        return;
    }

        


    function setFactory(address factory) external onlyOwner {
        evaSafesFactory = IEvaSafesFactory(factory);
    }

    function execute(bytes memory executeData) external override returns (bool canDestoryFlow) {
        uint256 taskId = abi.decode(executeData, (uint256));
        Task memory task = _tasks[taskId];
        require(msg.sender == evaSafesFactory.get(task.owner), "shold be owner");
        require(isActiveTask(taskId), "not active");
        //Can be closed or not
        // solhint-disable not-rely-on-time
        if (block.timestamp > task.deadline) {
            canDestoryFlow = true;
            delete _tasks[taskId];
        } else {
            // solhint-disable not-rely-on-time
            _tasks[taskId].lastExecTime = Utils.toUint64(block.timestamp);
        }
        emit TaskExecuted(taskId);
    }

    function createTask(Task memory task, uint256 taskId) external payable override returns (bytes memory _taskId) {
        require(task.inputs.length > 0, "invalid length");
        require(task.interval >= _MIN_INTERAL, "invalid interval");
        //check
        require(task.deadline > Utils.toUint64(block.timestamp), "invalid time");
        for (uint256 i = 0; i < task.inputs.length; i++) {
            (address contractAdd, , ) = abi.decode(task.inputs[i], (address, uint120, bytes));
            require(contractAdd != address(this) && contractAdd != msg.sender, "FORBIDDEN");
        }

        task.lastExecTime = Utils.toUint64(block.timestamp);
        _tasks[taskId] = task;

        _taskId = abi.encode(taskId);
        emit TaskCreated(msg.sender, taskId, task);
    }

    function cancelTask(uint256 taskId) public override {
        Task storage task = _tasks[taskId];
        require(task.owner != address(0), "task not exist");

        if (msg.sender != evaSafesFactory.get(task.owner)) {
            require(taskExpired(taskId), "task is active");
        }

        delete _tasks[taskId];

        emit TaskCancelled(msg.sender, taskId);
    }

    function getTask(uint256 taskId) external view override returns (Task memory task) {
        task = _tasks[taskId];
    }

    function getSubCalls(bytes memory executeData) external view override returns (CallArgs[] memory subs) {
        uint256 taskId = abi.decode(executeData, (uint256));
        uint256 taskLength = _tasks[taskId].inputs.length;
        subs = new CallArgs[](taskLength);
        for (uint256 i = 0; i < taskLength; i++) {
            (address _contractAdd, uint120 _value, bytes memory _data) = abi.decode(
                _tasks[taskId].inputs[i],
                (address, uint120, bytes)
            );
            subs[i] = CallArgs({target: _contractAdd, valueETH: _value, data: _data});
        }
    }

    function isActiveTask(uint256 taskId) public view returns (bool) {
        uint64 deadline = _tasks[taskId].deadline;
        uint64 interval = _tasks[taskId].interval;
        uint64 startTime = _tasks[taskId].startTime;
        uint64 lastExecTime = _tasks[taskId].lastExecTime;
        return
            Utils.toUint64(block.timestamp) >= startTime &&
            deadline >= lastExecTime + interval &&
            Utils.toUint64(block.timestamp) >= lastExecTime + interval &&
            _tasks[taskId].owner != address(0);
    }

    function needClose(bytes memory taskIdData) external view override returns (bool yes) {
        uint256 taskId = abi.decode(taskIdData, (uint256));
        yes = taskExpired(taskId);
    }

    function close(bytes memory taskIdData) external override {
        uint256 taskId = abi.decode(taskIdData, (uint256));
        cancelTask(taskId);
    }

    function taskExpired(uint256 taskId) public view returns (bool) {
        // solhint-disable
        uint256 deadline = _tasks[taskId].deadline;
        return deadline > 0 && deadline < block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;
import {FlowStatus, KeepNetWork} from "../lib/EvabaseHelper.sol";

//struct
struct EvaFlowMeta {
    FlowStatus flowStatus;
    KeepNetWork keepNetWork;
    address admin;
    address lastKeeper;
    address lastVersionflow;
    uint256 lastExecNumber;
    uint256 maxVaildBlockNumber;
    string flowName;
    bytes checkData;
}

struct EvaUserMeta {
    uint120 ethBal;
    uint120 gasTokenBal;
    uint8 vaildFlowsNum;
}

struct MinConfig {
    address feeRecived;
    address feeToken;
    uint64 minGasFundForUser;
    uint64 minGasFundOneFlow;
    uint16 ppb;
    uint16 blockCountPerTurn;
}

interface IEvaFlowController {
    event FlowCreated(address indexed user, uint256 indexed flowId, address flowAdd, bytes checkData, uint256 fee);
    event FlowUpdated(address indexed user, uint256 flowId, address flowAdd);
    event FlowClosed(address indexed user, uint256 flowId);
    event FlowExecuteSuccess(
        address indexed user,
        uint256 indexed flowId,
        uint120 payAmountByETH,
        uint120 payAmountByFeeToken,
        uint256 gasUsed
    );
    event FlowExecuteFailed(
        address indexed user,
        uint256 indexed flowId,
        uint120 payAmountByETH,
        uint120 payAmountByFeeToken,
        uint256 gasUsed,
        string reason
    );

    event SetMinConfig(
        address indexed user,
        address feeRecived,
        address feeToken,
        uint64 minGasFundForUser,
        uint64 minGasFundOneFlow,
        uint16 ppb,
        uint16 blockCountPerTurn
    );

    function registerFlow(
        string memory name,
        KeepNetWork keepNetWork,
        address flow,
        bytes memory checkdata
    ) external payable returns (uint256 flowId);

    function updateFlow(
        uint256 flowId,
        string memory flowName,
        bytes memory flowCode
    ) external;

    function closeFlow(uint256 flowId) external;

    function execFlow(
        address keeper,
        uint256 flowId,
        bytes memory inputData
    ) external;

    function addFundByUser(
        address tokenAdress,
        uint256 amount,
        address user
    ) external payable;

    function withdrawFundByUser(address tokenAdress, uint256 amount) external;

    function withdrawPayment(address tokenAdress, uint256 amount) external;

    function getVaildFlowRange(
        uint256 fromIndex,
        uint256 endIndex,
        KeepNetWork keepNetWork
    ) external view returns (uint256[] memory arr);

    function getIndexVaildFlow(uint256 index, KeepNetWork keepNetWork) external view returns (uint256 value);

    function getAllVaildFlowSize(KeepNetWork keepNetWork) external view returns (uint256 size);

    function getFlowMetas(uint256 index) external view returns (EvaFlowMeta memory);

    function getFlowMetaSize() external view returns (uint256);

    function batchExecFlow(
        address keeper,
        bytes memory data,
        uint256 gasLimit
    ) external;

    function getSafes(address user) external view returns (address);

    function getFlowCheckInfo(uint256 flowId) external view returns (address flow, bytes memory checkData);
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

enum CompareOperator {
    Eq,
    Ne,
    Ge,
    Gt,
    Le,
    Lt
}

enum FlowStatus {
    Active, //可执行
    Closed,
    Expired,
    Completed,
    Unknown
}

enum KeepNetWork {
    ChainLink,
    Evabase,
    Gelato,
    Others
}

library EvabaseHelper {
    struct UintSet {
        // value ->index value !=0
        mapping(uint256 => uint256) indexMapping;
        uint256[] values;
    }

    function add(UintSet storage self, uint256 value) internal {
        require(value != uint256(0), "value=0");
        require(!contains(self, value), "value exists");
        self.values.push(value);
        self.indexMapping[value] = self.values.length;
    }

    function contains(UintSet storage self, uint256 value) internal view returns (bool) {
        return self.indexMapping[value] != 0;
    }

    function remove(UintSet storage self, uint256 value) internal {
        require(contains(self, value), "value doesn't exist");
        uint256 toDeleteindexMapping = self.indexMapping[value] - 1;
        uint256 lastindexMapping = self.values.length - 1;
        uint256 lastValue = self.values[lastindexMapping];
        self.values[toDeleteindexMapping] = lastValue;
        self.indexMapping[lastValue] = toDeleteindexMapping + 1;
        delete self.indexMapping[value];
        // self.values.length--;
        self.values.pop();
    }

    function getSize(UintSet storage self) internal view returns (uint256) {
        return self.values.length;
    }

    function get(UintSet storage self, uint256 index) internal view returns (uint256) {
        return self.values[index];
    }

    function getAll(UintSet storage self) internal view returns (uint256[] memory) {
        // uint256[] memory output = new uint256[](self.values.length);
        // for (uint256 i; i < self.values.length; i++) {
        //     output[i] = self.values[i];
        // }
        return self.values;
    }

    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        // solhint-disable no-inline-assembly
        assembly {
            mstore(add(b, 32), x)
        }
    }

    function getRange(
        UintSet storage self,
        uint256 fromIndex,
        uint256 endIndex
    ) internal view returns (uint256[] memory) {
        require(fromIndex <= endIndex, "fromIndex gt endIndex");
        require(endIndex <= self.values.length, "endIndex exceed bound");
        uint256[] memory output = new uint256[](endIndex - fromIndex);
        uint256 j = 0;
        for (uint256 i = fromIndex; i < endIndex; i++) {
            output[j++] = self.values[i];
        }
        return output;
    }
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

import "./IEvaFlow.sol";
struct CallArgs {
    address target;
    uint120 valueETH;
    bytes data;
}

interface IEvaSubFlow is IEvaFlow {
    function getSubCalls(bytes memory executeData) external view returns (CallArgs[] memory subs);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private _CACHED_DOMAIN_SEPARATOR;
    uint256 private _CACHED_CHAIN_ID;

    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    /* solhint-disable private-vars-leading-underscore */
    function init(string memory name, string memory version) internal {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 name,
        bytes32 version
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, name, version, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
/* solhint-disable */

pragma solidity ^0.8.0;

library Utils {
    function _decodeUints(bytes memory data) internal pure returns (uint256[] memory _arr) {
        _arr = abi.decode(data, (uint256[]));
    }

    function _decodeTwoArr(bytes memory data) internal pure returns (uint256[] memory _arr, bytes[] memory _bytes) {
        (_arr, _bytes) = abi.decode(data, (uint256[], bytes[]));
    }

    function _decodeUintAndBytes(bytes memory data) internal pure returns (bytes memory _byte, uint256 _arr) {
        (_byte, _arr) = abi.decode(data, (bytes, uint256));
    }

    function _encodeTwoArr(uint256[] memory _uint, bytes[] memory _bytes) internal pure returns (bytes memory) {
        return (abi.encode(_uint, _bytes));
    }

    function hashCompareInternal(bytes memory a, bytes memory b) internal pure returns (bool) {
        return keccak256(a) == keccak256(b);
    }

    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 224 bits");
        return uint120(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }
}

//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

interface IOpsFlow {
    struct Task {
        address owner; //拥有人
        bytes[] inputs; //abi.encode(target+callData+value)
        uint64 startTime; //开始时间
        uint64 deadline; //过期时间
        uint64 lastExecTime; //上次执行时间
        uint64 interval; //至少15秒
    }

    event TaskExecuted(uint256 indexed taskId);

    event TaskCancelled(address indexed user, uint256 taskId);

    event TaskCreated(address indexed user, uint256 indexed flowId, Task task);

    function createTask(Task memory task, uint256 flowId) external payable returns (bytes memory taskId);

    function cancelTask(uint256 taskId) external;

    function getTask(uint256 taskId) external view returns (Task memory task);
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;
import {KeepNetWork} from "../lib/EvabaseHelper.sol";

struct KeepStruct {
    bool isActive;
    KeepNetWork keepNetWork;
}

interface IEvabaseConfig {
    event AddKeeper(address indexed user, address keeper, KeepNetWork keepNetWork);
    event RemoveKeeper(address indexed user, address keeper);
    event AddBatchKeeper(address indexed user, address[] keeper, KeepNetWork[] keepNetWork);
    event RemoveBatchKeeper(address indexed user, address[] keeper);

    event SetControl(address indexed user, address control);
    event SetBatchFlowNum(address indexed user, uint32 num);

    function getBytes32Item(bytes32 key) external view returns (bytes32);

    function getAddressItem(bytes32 key) external view returns (address);

    function control() external view returns (address);

    function setControl(address control_) external;

    function isKeeper(address query) external view returns (bool);

    function addKeeper(address keeper, KeepNetWork keepNetWork) external;

    function removeKeeper(address keeper) external;

    function addBatchKeeper(address[] memory arr, KeepNetWork[] memory keepNetWork) external;

    function removeBatchKeeper(address[] memory arr) external;

    function setBatchFlowNum(uint32 num) external;

    function batchFlowNum() external view returns (uint32);

    function keepBotSizes(KeepNetWork keepNetWork) external view returns (uint32);

    function getKeepBot(address add) external view returns (KeepStruct memory);

    function isActiveControler(address add) external view returns (bool);
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

interface IEvaSafesFactory {
    event ConfigChanged(address indexed newConfig);

    event WalletCreated(address indexed user, address wallet);

    function get(address user) external view returns (address wallet);

    function create(address user) external returns (address wallet);

    function calcSafes(address user) external view returns (address wallet);

    function changeConfig(address _config) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

interface IEvaFlow {
    function multicall(address target, bytes memory callData) external;

    function check(bytes memory checkData) external view returns (bool needExecute, bytes memory executeData);

    function execute(bytes memory executeData) external returns (bool canDestoryFlow);

    function needClose(bytes memory checkData) external returns (bool yes);

    function close(bytes memory checkData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}