//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import {KeeperRegistryInterface} from "../keeper/chainlink/KeeperRegistryInterface.sol";
import {KeeperCompatibleInterface} from "../keeper/chainlink/KeeperCompatibleInterface.sol";
import {EvaKeepBotBase} from "../keeper/EvaKeepBotBase.sol";
import {IEvabaseConfig} from "../interfaces/IEvabaseConfig.sol";
import {EvaFlowChecker} from "../EvaFlowChecker.sol";
import {IEvaFlowController} from "../interfaces/IEvaFlowController.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import {KeepNetWork} from "../lib/EvabaseHelper.sol";

contract EvaBaseServerBot is EvaKeepBotBase, KeeperCompatibleInterface, Ownable {
    event SetEBSKeepStatus(address indexed user, bool status);
    uint32 public keepBotId;
    mapping(address => bool) public keeps;
    uint32 private constant _EXEC_GAS_LIMIT = 8_000_000;

    constructor(
        address _config,
        address _evaFlowChecker
    ) {
        // require(_evaFlowControler != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        require(_evaFlowChecker != address(0), "addess is 0x");

        // evaFlowControler = IEvaFlowControler(_evaFlowControler);
        config = IEvabaseConfig(_config);
        evaFlowChecker = EvaFlowChecker(_evaFlowChecker);
        // execAddress = _execAddress;
        config = IEvabaseConfig(_config);
        keeps[msg.sender] = true;
        // config.addKeeper(address(this), keepNetWork);
        // keepBotId = config.keepBotSizes(keepNetWork);
    }

    function checkUpkeep(bytes calldata checkData)
        external
        pure
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        return _check(checkData);
    }

    function _check(bytes memory _checkdata) internal pure override returns (bool needExec, bytes memory execdata) {
        return (true, _checkdata);
    }

    function performUpkeep(bytes calldata performData) external override {
        _exec(performData);
    }

    function _exec(bytes memory _execdata) internal override {
        require(_execdata.length > 0, "exec data should not null");

        // require(keeps[msg.sender], "not active EvaBase bot");

        IEvaFlowController(config.control()).batchExecFlow(msg.sender, _execdata, _EXEC_GAS_LIMIT);
    }

    function setEBSKeepStatus(address keep, bool status) external onlyOwner {
        keeps[keep] = status;
        emit SetEBSKeepStatus(keep, status);
    }

    function encodeTwoArr(uint256[] memory _uint, bytes[] memory _bytes) external pure returns (bytes memory) {
        return (abi.encode(_uint, _bytes));
    }

    function encodeUintAndBytes(bytes memory _bytes, uint256 _value) external pure returns (bytes memory) {
        return (abi.encode(_bytes, _value));
    }

    function encodeUints(uint256[] memory _uint) external pure returns (bytes memory) {
        return (abi.encode(_uint));
    }
}

//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

interface KeeperRegistryBaseInterface {
    function registerUpkeep(
        address target,
        uint32 gasLimit,
        address admin,
        bytes calldata checkData
    ) external returns (uint256 id);

    function performUpkeep(uint256 id, bytes calldata performData) external returns (bool success);

    function cancelUpkeep(uint256 id) external;

    function addFunds(uint256 id, uint96 amount) external;

    function getUpkeep(uint256 id)
        external
        view
        returns (
            address target,
            uint32 executeGas,
            bytes memory checkData,
            uint96 balance,
            address lastKeeper,
            address admin,
            uint64 maxValidBlocknumber
        );

    function getUpkeepCount() external view returns (uint256);

    function getCanceledUpkeepList() external view returns (uint256[] memory);

    function getKeeperList() external view returns (address[] memory);

    function getKeeperInfo(address query)
        external
        view
        returns (
            address payee,
            bool active,
            uint96 balance
        );

    function getConfig()
        external
        view
        returns (
            uint32 paymentPremiumPPB,
            uint24 checkFrequencyBlocks,
            uint32 checkGasLimit,
            uint24 stalenessSeconds,
            uint16 gasCeilingMultiplier,
            uint256 fallbackGasPrice,
            uint256 fallbackLinkPrice
        );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface KeeperRegistryInterface is KeeperRegistryBaseInterface {
    function checkUpkeep(uint256 upkeepId, address from)
        external
        view
        returns (
            bytes memory performData,
            uint256 maxLinkPayment,
            uint256 gasLimit,
            int256 gasWei,
            int256 linkEth
        );
}

interface KeeperRegistryExecutableInterface is KeeperRegistryBaseInterface {
    function checkUpkeep(uint256 upkeepId, address from)
        external
        returns (
            bytes memory performData,
            uint256 maxLinkPayment,
            uint256 gasLimit,
            uint256 adjustedGasWei,
            uint256 linkEth
        );
}

//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does does not actually need to be
     * executable, and since it is only ever simulated it can consume lots of gas.
     * @dev To ensure that it is never called, you may want to add the
     * cannotExecute modifier from KeeperBase to your implementation of this
     * method.
     * @param checkData specified in the upkeep registration so it is always the
     * same for a registered upkeep. This can easily be broken down into specific
     * arguments using `abi.decode`, so multiple upkeeps can be registered on the
     * same contract and easily differentiated by the contract.
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try
     * `abi.encode`.
     */
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external;
}

//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import {IEvabaseConfig} from "../interfaces/IEvabaseConfig.sol";
import {EvaFlowChecker} from "../EvaFlowChecker.sol";

abstract contract EvaKeepBotBase {
    IEvabaseConfig public config;
    EvaFlowChecker public evaFlowChecker;

    function _check(bytes memory checkdata) internal virtual returns (bool needExec, bytes memory execdata);

    function _exec(bytes memory execdata) internal virtual;
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

    // event SetMinGasTokenBal(address indexed user, uint256 amount);
    // event SetMinGasEthBal(address indexed user, uint256 amount);
    // event SetFeeToken(address indexed user, address feeToken);

    // event SetWalletFactory(address indexed user, address factory);
    event SetControl(address indexed user, address control);
    event SetBatchFlowNum(address indexed user, uint32 num);

    function control() external view returns (address);

    function setControl(address control_) external;

    // function getWalletFactory() external view returns (address);

    // function setWalletFactory(address factory) external;

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

    // function getKeepBotSize() external view returns (uint32);

    // function getAllKeepBots() external returns (address[] memory);

    // function setMinGasTokenBal(uint256 amount) external;

    // function setMinGasEthBal(uint256 amount) external;

    // function setFeeToken(address feeToken) external;

    // function getMinGasTokenBal() external view returns (uint256);

    // function getMinGasEthBal() external view returns (uint256);

    // function setFeeRecived(address feeRecived) external;

    // function setPaymentPrePPB(uint256 amount) external;

    // function setBlockCountPerTurn(uint256 count) external;

    // function getFeeToken() external view returns (address);

    // function getFeeRecived() external view returns (address);

    // event SetPaymentPrePPB(address indexed user, uint256 amount);
    // event SetFeeRecived(address indexed user, address feeRecived);
    // event SetBlockCountPerTurn(address indexed user, uint256 count);
}

//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import {IEvabaseConfig} from "./interfaces/IEvabaseConfig.sol";
import {IEvaFlow} from "./interfaces/IEvaFlow.sol";
import {IEvaFlowController, EvaFlowMeta} from "./interfaces/IEvaFlowController.sol";
import {Utils} from "./lib/Utils.sol";
import {KeepNetWork} from "./lib/EvabaseHelper.sol";

contract EvaFlowChecker {
    IEvabaseConfig public config;

    uint32 public constant CHECK_GASLIMIT_MIN = 4_000_0;
    uint32 private constant _GAS_LIMIT = 2_000_000;
    uint256 private constant _TIME_SOLT = 10 seconds;

    constructor(address _config) {
        // require(_evaFlowControler != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        config = IEvabaseConfig(_config);
    }

    function check(
        uint256 keepbotId,
        uint256 lastMoveTime,
        KeepNetWork keepNetWork
    ) external view returns (bool needExec, bytes memory execData) {
        uint32 batch = config.batchFlowNum();
        uint32 keepBotSize = config.keepBotSizes(keepNetWork);
        uint256 allVaildSize = IEvaFlowController(config.control()).getAllVaildFlowSize(keepNetWork);
        if (allVaildSize == 0) {
            return (false, bytes(""));
        }
        uint256 bot1start = _getRandomStart(allVaildSize, lastMoveTime);
        (uint256 start, uint256 end) = _getAvailCircle(allVaildSize, keepBotSize, keepbotId, batch, bot1start);

        return _ring(start, end, allVaildSize, keepNetWork);
    }

    function _ring(
        uint256 _start,
        uint256 _end,
        uint256 _allVaildSize,
        // bytes memory _checkdata,
        KeepNetWork keepNetWork
    ) internal view returns (bool needExec, bytes memory execData) {
        uint256 j = 0;
        uint256 length = 0;
        uint256[] memory tmp;
        bytes[] memory executeDataArray;
        if (_start > _end) {
            // start - allVaildSize
            length = _allVaildSize - _start + _end + 1;
            tmp = new uint256[](length);
            executeDataArray = new bytes[](length);
            // , _executeDataArray
            (tmp, j, executeDataArray) = _addVaildFlowIndex(
                _start,
                _allVaildSize,
                tmp,
                executeDataArray,
                // _checkdata,
                j,
                keepNetWork
            );
            // 0 - end
            (tmp, j, executeDataArray) = _addVaildFlowIndex(
                0,
                _end,
                tmp,
                executeDataArray,
                // _checkdata,
                j,
                keepNetWork
            );
        } else {
            length = _end - _start;
            tmp = new uint256[](length);
            executeDataArray = new bytes[](length);
            _addVaildFlowIndex(_start, _end, tmp, executeDataArray, j, keepNetWork);
        }

        if (tmp.length > 0) {
            needExec = true;
        }

        execData = Utils._encodeTwoArr(tmp, executeDataArray);

        // return (tmp, executeDataArray);
        return (needExec, execData);
    }

    function _addVaildFlowIndex(
        uint256 _start,
        uint256 _end,
        uint256[] memory _tmp,
        bytes[] memory _executeDataArray,
        // bytes memory _checkdata,
        uint256 j,
        KeepNetWork keepNetWork
    )
        internal
        view
        returns (
            uint256[] memory arr,
            uint256 k,
            bytes[] memory _arrayBytes
        )
    {
        uint256 totalGas;
        bytes[] memory datas = _executeDataArray;
        uint256[] memory tmp = _tmp;
        uint256 jj = j;

        IEvaFlowController ctr = IEvaFlowController(config.control());
        for (uint256 i = _start; i < _end; i++) {
            uint256 beforGas = gasleft();
            uint256 index = ctr.getIndexVaildFlow(i, keepNetWork);

            // checkGasLimit/checkdata?
            if (index != uint256(0)) {
                EvaFlowMeta memory meta = ctr.getFlowMetas(index);
                (bool needExec, bytes memory executeData) = IEvaFlow(meta.lastVersionflow).check(meta.checkData);

                uint256 afterGas = gasleft();
                totalGas = totalGas + beforGas - afterGas;
                if (totalGas > _GAS_LIMIT || afterGas < CHECK_GASLIMIT_MIN) {
                    return (tmp, jj, datas);
                }
                if (needExec) {
                    tmp[jj++] = index;
                    datas[jj++] = executeData;
                }
            }
        }

        return (tmp, jj, datas);
    }

    function _getAvailCircle(
        uint256 _allVaildSize,
        uint256 _keepBotSize,
        uint256 _keepbotN,
        uint32 _batch,
        uint256 _bot1start
    ) internal pure returns (uint256 botNIndexS, uint256 botNIndexE) {
        require(_keepBotSize > 0 && _allVaildSize > 0 && _keepbotN > 0, "gt 0");

        uint256 quotient = _allVaildSize / _keepBotSize;
        uint256 remainder = _allVaildSize % _keepBotSize;

        if (remainder != 0) {
            quotient++;
        }

        bool isUseBatch = _batch < quotient;

        if (isUseBatch) {
            quotient = _batch;
        }

        //first find should index
        botNIndexS = _bot1start + (_keepbotN - 1) * quotient;
        botNIndexE = _bot1start + _keepbotN * quotient;

        //Both of these are outside the circle
        if (botNIndexS >= _allVaildSize) {
            botNIndexS = botNIndexS - _allVaildSize;
            botNIndexE = botNIndexE - _allVaildSize;

            if (botNIndexS > _bot1start) {
                botNIndexS = botNIndexS % _allVaildSize;
                botNIndexE = botNIndexE % _allVaildSize;
            }
        } else {
            if (botNIndexE > _allVaildSize) {
                botNIndexE = botNIndexE - _allVaildSize - 1;
                if (botNIndexE >= _bot1start) {
                    botNIndexE = _bot1start;
                }
            }
        }

        return (botNIndexS, botNIndexE);
    }

    function _getRandomStart(uint256 _flowSize, uint256 lastMoveTime) internal view returns (uint256 index) {
        // solhint-disable
        if (block.timestamp - lastMoveTime >= _TIME_SOLT) {
            index = uint256(keccak256(abi.encodePacked(block.timestamp))) % _flowSize;
        } else {
            index = uint256(keccak256(abi.encodePacked(lastMoveTime))) % _flowSize;
        }
    }
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
    event FlowPaused(address indexed user, uint256 flowId);
    event FlowStart(address indexed user, uint256 flowId);
    event FlowDestroyed(address indexed user, uint256 flowId);
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

    function startFlow(uint256 flowId) external;

    function pauseFlow(uint256 flowId) external;

    function destroyFlow(uint256 flowId) external;

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
    Paused,
    Destroyed,
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
        require(value != uint256(0), "LibAddressSet: value can't be 0x0");
        require(!contains(self, value), "LibAddressSet: value already exists in the set.");
        self.values.push(value);
        self.indexMapping[value] = self.values.length;
    }

    function contains(UintSet storage self, uint256 value) internal view returns (bool) {
        return self.indexMapping[value] != 0;
    }

    function remove(UintSet storage self, uint256 value) internal {
        require(contains(self, value), "LibAddressSet: value doesn't exist.");
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

interface IEvaFlow {
    function multicall(address target, bytes memory callData) external;

    function check(bytes memory checkData) external view returns (bool needExecute, bytes memory executeData);

    function execute(bytes memory executeData) external;
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

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }
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