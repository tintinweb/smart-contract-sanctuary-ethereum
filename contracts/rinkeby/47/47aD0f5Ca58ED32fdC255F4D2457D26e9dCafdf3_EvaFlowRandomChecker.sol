//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import {IEvabaseConfig} from "../interfaces/IEvabaseConfig.sol";
import {IEvaFlow} from "../interfaces/IEvaFlow.sol";
import {IEvaFlowController, EvaFlowMeta} from "../interfaces/IEvaFlowController.sol";
import {KeepNetWork} from "../lib/EvabaseHelper.sol";
import {IEvaFlowChecker} from "../interfaces/IEvaFlowChecker.sol";

contract EvaFlowRandomChecker is IEvaFlowChecker {
    IEvabaseConfig public config;

    uint32 private constant _GAS_SAVE = 60_000;
    uint256 private constant _TIME_SOLT = 12 seconds;

    constructor(address _config) {
        require(_config != address(0), "addess is 0x");
        config = IEvabaseConfig(_config);
    }

    struct Args {
        uint256 flowCount;
        uint256 startIndex;
        uint256 keeperCount;
        uint256 keepbotId;
        uint256 maxCheck;
        IEvaFlowController controller;
        KeepNetWork network;
    }

    function check(
        uint256 keepbotId,
        uint256 lastMoveTime,
        KeepNetWork keepNetWork
    ) external override returns (bool needExec, bytes memory execData) {
        // solhint-disable avoid-tx-origin
        require(tx.origin == address(0), "only for off-chain");
        Args memory args;
        args.controller = IEvaFlowController(config.control());
        args.flowCount = args.controller.getAllVaildFlowSize(keepNetWork);

        if (args.flowCount > 0) {
            args.keepbotId = keepbotId;
            args.network = keepNetWork;
            args.maxCheck = config.batchFlowNum();
            args.keeperCount = config.keepBotSizes(keepNetWork);
            require(args.keeperCount > 0, "keeper is zero");
            require(args.maxCheck > 0, "max check is zero");
            args.startIndex = _selectBeginIndex(args.flowCount, lastMoveTime);

            (uint256[] memory flows, bytes[] memory datas) = _checkFlows(args);

            if (flows.length > 0) {
                needExec = true;
                execData = abi.encode(flows, datas);
            }
        }
    }

    function _selectBeginIndex(uint256 count, uint256 lastMoveTime) internal view returns (uint256) {
        // solhint-disable
        if (block.timestamp - lastMoveTime >= _TIME_SOLT) {
            return uint256(keccak256(abi.encodePacked(block.timestamp))) % count;
        } else {
            return uint256(keccak256(abi.encodePacked(lastMoveTime))) % count;
        }
    }

    /**
       寻找可执行的Flow，
       随机选择一个起始位置，然后开始依次检查Flow，直到 Gas 用尽。
     */
    function _checkFlows(Args memory args) internal returns (uint256[] memory flows, bytes[] memory datas) {
        uint256[] memory flowsAll = new uint256[](args.maxCheck);
        bytes[] memory datasAll = new bytes[](args.maxCheck);

        uint256 needExecCount;
        uint256 next = args.startIndex + (args.keepbotId - 1);
        uint256 firstIndex = next % args.flowCount;
        bool notFirst;
        // 跳表查询，直到找满或Gas耗尽
        for (; needExecCount < args.maxCheck; next += args.keeperCount) {
            uint256 nextIndex = next % args.flowCount;
            // 最多只需转一圈，不重复检查
            if (notFirst && nextIndex == firstIndex) {
                break;
            }
            notFirst = true;
            uint256 flowId = args.controller.getIndexVaildFlow(nextIndex, args.network);

            EvaFlowMeta memory meta = args.controller.getFlowMetas(flowId);
            try IEvaFlow(meta.lastVersionflow).check(meta.checkData) returns (bool needExec, bytes memory executeData) {
                if (needExec) {
                    // 此处属模拟执行
                    (bool success, ) = address(args.controller).call{value: 0}(
                        abi.encodeWithSelector(IEvaFlowController.execFlow.selector, address(this), flowId, executeData)
                    );
                    if (success) {
                        flowsAll[needExecCount] = flowId;
                        datasAll[needExecCount] = executeData;
                        needExecCount++;
                    }
                }
                // solhint-disable
            } catch {} //ignore error

            if (gasleft() <= _GAS_SAVE) {
                break;
            }
        }

        // remove empty item
        flows = new uint256[](needExecCount);
        datas = new bytes[](needExecCount);
        for (uint256 i = 0; i < needExecCount; i++) {
            flows[i] = flowsAll[i];
            datas[i] = datasAll[i];
        }
    }
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;
import {KeepNetWork} from "../lib/EvabaseHelper.sol";

struct KeepInfo {
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

    function isKeeper(address query) external view returns (bool);

    function batchFlowNum() external view returns (uint32);

    function keepBotSizes(KeepNetWork keepNetWork) external view returns (uint32);

    function getKeepBot(address add) external view returns (KeepInfo memory);

    function isActiveControler(address add) external view returns (bool);
}

//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

interface IEvaFlow {
    function check(bytes memory checkData) external view returns (bool needExecute, bytes memory executeData);

    function execute(bytes memory executeData) external returns (bool canDestoryFlow);

    function needClose(bytes memory checkData) external returns (bool yes);

    function close(bytes memory checkData) external;
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
    uint120 gasTokenBal; //keep
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
    event FlowOperatorChanged(address op, bool removed);
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

    function closeFlow(uint256 flowId) external;

    function closeFlowWithGas(uint256 flowId, uint256 before) external;

    function execFlow(
        address keeper,
        uint256 flowId,
        bytes memory inputData
    ) external;

    function depositFund(address flowAdmin) external payable;

    function withdrawFund(address recipient, uint256 amount) external;

    function withdrawPayment(uint256 amount) external;

    function getIndexVaildFlow(uint256 index, KeepNetWork keepNetWork) external view returns (uint256 value);

    function getAllVaildFlowSize(KeepNetWork keepNetWork) external view returns (uint256 size);

    function getFlowMetas(uint256 index) external view returns (EvaFlowMeta memory);

    function getFlowMetaSize() external view returns (uint256);

    function batchExecFlow(address keeper, bytes memory data) external;

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

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.0;
import {KeepNetWork} from "../lib/EvabaseHelper.sol";

interface IEvaFlowChecker {
    function check(
        uint256 keepbotId,
        uint256 lastMoveTime,
        KeepNetWork keepNetWork
    ) external returns (bool needExec, bytes memory execData);
}