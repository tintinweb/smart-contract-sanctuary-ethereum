//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import {IEvabaseConfig} from "../interfaces/IEvabaseConfig.sol";
import {IEvaFlow} from "../interfaces/IEvaFlow.sol";
import {IEvaFlowController, EvaFlowMeta} from "../interfaces/IEvaFlowController.sol";
import {Utils} from "../lib/Utils.sol";
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

    function _checkFlows(Args memory args) internal returns (uint256[] memory flows, bytes[] memory datas) {
        uint256 mod = (args.flowCount % args.keeperCount);
        uint256 max = args.flowCount / args.keeperCount;
        max += mod > 0 && args.keepbotId <= mod ? 1 : 0;
        if (max > args.maxCheck) {
            max = args.maxCheck;
        }
        uint256[] memory flowsAll = new uint256[](max);
        bytes[] memory datasAll = new bytes[](max);

        uint256 needExecCount;
        uint256 keepIndex = args.keepbotId - 1;
        for (uint256 i = keepIndex; i < max * args.keeperCount; i += args.keeperCount) {
            uint256 nextIndex = i % args.flowCount;
            uint256 flowId = args.controller.getIndexVaildFlow(nextIndex, args.network);
            EvaFlowMeta memory meta = args.controller.getFlowMetas(flowId);
            try IEvaFlow(meta.lastVersionflow).check(meta.checkData) returns (bool needExec, bytes memory executeData) {
                if (needExec) {
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

interface IEvaFlow {
    function multicall(address target, bytes memory callData) external;

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